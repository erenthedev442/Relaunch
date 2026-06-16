-----------------------------------
-- DungeonSystem.lua
--
-- 2026-05-30: progression gate rail + NM mini-bosses. Waypoint packs and
-- catalog `nms` spawn AGGRESSIVE and become un-bypassable gates (a 500ms
-- patrol slides the player back to the threshold until the guarding mobs
-- are dead). See spawnAllMobs / spawnDungeonMob / gatePatrol.
--
-- Talk-to-NPC dungeon system. Pick a dungeon -> warped to a normally-
-- empty zone -> mob population spawns around you -> fight to the boss
-- -> kill boss within time limit -> Infamy reward -> auto-warped back.
--
-- Failure modes (all clean up the session + despawn mobs):
--   * Boss killed within time limit  -> SUCCESS, infamy awarded
--   * Time limit expires              -> ABORT, no reward
--   * Player dies                     -> ABORT, no reward
--   * Player zones out manually       -> ABORT, no reward
--   * Player runs !dungeon abort      -> ABORT, no reward
--
-- Architecture mirrors the established patterns:
--   * Catalog-driven (dungeon_catalog.lua)
--   * insertDynamicEntity for spawns (no SQL needed; uses HL groupIds)
--   * NPCs at GM Home (Dungeon Master + Infamy Vendor)
--   * CharVar-tracked progress (no DB schema changes)
-----------------------------------
require('modules/module_utils')
local catalog = require('modules/custom/lua/dungeon_catalog')
local ach     = require('modules/custom/lua/achievements')
require(string.format('scripts/zones/%s/Zone', catalog.dungeonMasterPos.zone))

-- ============================================================
-- SAFETY RAIL #1: Zone-warpability validation at module load
-- ============================================================
-- During the v1 launch we shipped with Outer_Ra'Kaznar_[U2] and
-- [U3] as dungeon zones. Both were "empty" (no native mob_groups)
-- AND in the LSB zone enum, so they looked fine. But their Zone.lua
-- scripts ONLY have onInstanceZoneIn - they require the LSB instance
-- system to be entered. A plain setPos to them stranded the player
-- in a black screen + perpetual "already logged in" loop.
--
-- This check runs at module-load: for each dungeon, require the
-- zone script and confirm it has onZoneIn. Dungeons backed by
-- instance-only zones are marked _disabled and removed from the
-- player-facing menu (with a clear server-log warning).
--
-- This means a future catalog edit can't accidentally select an
-- instance-only zone without a screaming server-log warning.
for _, d in ipairs(catalog.dungeons) do
    local ok, zoneScript = pcall(require, string.format('scripts/zones/%s/Zone', d.zoneName))
    if not ok then
        d._disabled = string.format(
            'zone script not found at scripts/zones/%s/Zone.lua', d.zoneName)
        print(string.format(
            "[dungeon] WARNING: dungeon '%s' DISABLED - %s",
            d.id, d._disabled))
    elseif type(zoneScript) == 'table' and zoneScript.onZoneIn == nil then
        -- No onZoneIn - check if the zone uses onInstanceZoneIn instead.
        -- Dynamis [D] zones (e.g. Dynamis-San_dOria_[D]) have zonetype=128
        -- and are entered via setPos like normal zones, but the engine fires
        -- onInstanceZoneIn rather than onZoneIn on arrival.  We hook that
        -- instead and prevent the default zone-72 eject for dungeon runners.
        if type(zoneScript.onInstanceZoneIn) == 'function' then
            d._useInstanceZoneIn = true
            print(string.format(
                "[dungeon] zone %s has onInstanceZoneIn only - will hook that for dungeon arrivals",
                d.zoneName))
        else
            d._disabled = string.format(
                'zone %s has neither onZoneIn nor onInstanceZoneIn; ' ..
                'cannot hook player arrival', d.zoneName)
            print(string.format(
                "[dungeon] WARNING: dungeon '%s' DISABLED - %s",
                d.id, d._disabled))
        end
    end
end

local m = Module:new('dungeon_system')

-- Per-player session state. Keyed by player name (charname is stable;
-- the player entity ref isn't safe across zones / re-logs).
--   sessions[name] = {
--       dungeon       = <catalog dungeon table>
--       startedAt     = os.time()
--       mobs          = { mobEntity, ... }   (every live mob in this run)
--       bossEntity    = the boss mob ref
--       timer         = handle so we can cancel on early-end paths
--       cleared       = bool; flipped on boss death
--   }
local sessions = {}

-- Mob refs deferred from a zone-exit abort (player left the dungeon zone).
-- setHP(0) on mobs in an empty/sleeping zone triggers the LSB destructor
-- crash. Instead we park them here and flush at the START of the next
-- session for that zone (when a player IS present and the zone is alive).
local pendingCleanup = {}  -- zoneId -> { mob, mob, ... }

local function getSession(player)
    return sessions[player:getName()]
end

-----------------------------------
-- PHASE 8 - Public-launch serialization: one group per dungeon ZONE.
-----------------------------------
-- The dungeon zones are real shared zones, not instances - two groups
-- in the same dungeon would fight interleaved spawns and could kill
-- each other's boss (completing the other group's run). This lock
-- serializes entry per zoneId; different dungeons live in different
-- zones and run concurrently without contact.
--
-- Self-healing: a lock whose leader has no live session for the zone
-- is stale and freed on the next entry attempt. A lock whose run blew
-- far past its clock means the leader disconnected (their PAI timers
-- died, so endDungeon never ran) - its leftovers are despawned and
-- the orphaned session dropped before the lock frees.
local zoneOccupancy = {}   -- zoneId -> { leaderName, startedAt }

local OCC_GRACE_SEC = 300  -- slack past the effective time limit

local function dungeonLockHolder(dungeon)
    local occ = zoneOccupancy[dungeon.zoneId]
    if not occ then return nil end

    local occSess = sessions[occ.leaderName]
    if occSess and occSess.dungeon and occSess.dungeon.zoneId == dungeon.zoneId then
        local limit = occSess.timeLimitOverride or occSess.dungeon.timeLimit or 1800
        if os.time() <= occ.startedAt + limit + OCC_GRACE_SEC then
            return occ   -- genuinely occupied
        end
        -- Expired with a live session table: orphaned run (leader DC).
        for _, mob in ipairs(occSess.mobs or {}) do
            if mob then
                pcall(function() mob:setHP(0) end)
            end
        end
        for _, mname in ipairs(occSess.members or {}) do
            sessions[mname] = nil
        end
        sessions[occ.leaderName] = nil
    end

    zoneOccupancy[dungeon.zoneId] = nil
    return nil
end

-- Lazy-loaded weekly_hunts for the dungeon_clear event. Same defensive
-- pattern hunters_guild uses - protect-call so a missing module
-- doesn't bring down the dungeon flow.
local _wh = nil
local function whFire(player, eventType, metadata)
    if _wh == nil then
        local ok, mod = pcall(require, 'modules/custom/lua/weekly_hunts')
        _wh = ok and mod or false
    end
    if _wh and _wh.fire then _wh.fire(player, eventType, metadata) end
end

-----------------------------------
-- Currency helpers
-----------------------------------
local function getInfamy(player)
    return player:getCharVar(catalog.currencyCv) or 0
end
local function addInfamy(player, amount)
    if amount and amount > 0 then
        player:setCharVar(catalog.currencyCv, getInfamy(player) + amount)
    end
end

-----------------------------------
-- PHASE 6 - Party / alliance helpers
-----------------------------------
-- Encapsulate every party-related operation behind these helpers so
-- the main startDungeon / armDungeonAfterArrival / endDungeon flow
-- can opt into party support with a single call per phase. Solo runs
-- still work - when the helpers find no eligible members the session
-- behaves exactly like the pre-Phase-6 solo path.

-- Returns the list of party-member CBaseEntity refs eligible to join
-- the leader's dungeon run. Caller can iterate; member objects are
-- guaranteed to be PC entities, alive, in the same zone (if config
-- requires it), and NOT already in a session of their own.
local function detectPartyMembers(leader)
    local list = {}
    if not (catalog.party and catalog.party.enabled) then
        return list
    end
    -- :getParty() returns the full party (including leader) on LSB.
    -- If the engine returns nil on a solo player, fall back gracefully.
    local party = leader:getParty() or {}
    local leaderId = leader:getID()
    local leaderZone = leader:getZoneID()
    local maxMembers = catalog.party.maxMembers or 5
    for _, mem in ipairs(party) do
        if mem and mem:getID() ~= leaderId
           and mem:getObjType() == xi.objType.PC
           and mem:getHP() > 0
           and not sessions[mem:getName()] then
            local sameZone = not catalog.party.requireSameZone
                          or mem:getZoneID() == leaderZone
            if sameZone then
                table.insert(list, mem)
                if #list >= maxMembers then break end
            end
        end
    end
    return list
end

-- Wires shadow session references for each member. After this call,
-- sessions[<memberName>] resolves to the same table as
-- sessions[<leaderName>] - so getSession(member) returns the leader's
-- session and the whole codebase sees them as "in dungeon" transparently.
local function attachMembersToSession(session, members)
    session.leaderName = session.leaderName or session.dungeon and nil  -- set by caller
    session.members    = session.members    or {}
    for _, mem in ipairs(members) do
        local mname = mem:getName()
        table.insert(session.members, mname)
        sessions[mname] = session  -- shadow ref
    end
end

-- Remove a single member from the session cleanly. Used when a member
-- dies mid-run (they warp out, the run continues for others).
local function detachMember(session, memberName)
    sessions[memberName] = nil
    if not session.members then return end
    for i, n in ipairs(session.members) do
        if n == memberName then
            table.remove(session.members, i)
            break
        end
    end
end

-- Resolve a member name to a live CBaseEntity if they're still in the
-- dungeon zone. Returns nil if they're absent (logged out, zoned out,
-- already detached, etc.). Used by the end-of-run distribution + warp
-- paths to avoid touching ghost references.
local function liveMemberInZone(memberName, zoneId)
    local mem = GetPlayerByName(memberName)
    if not mem then return nil end
    if zoneId and mem:getZoneID() ~= zoneId then return nil end
    return mem
end

-----------------------------------
-- PHASE 2 - Difficulty tiers
-----------------------------------
-- Catalog: dungeon_catalog.lua -> catalog.tiers (normal/hard/mythic).
-- Each tier scales HP/ATT/time/reward and (for Mythic) gates on a
-- weekly key. Tier picker lives between dungeon selection and entry.
--
-- ISO-week computation for the Mythic key. UTC-anchored so the reset
-- happens at the same instant for every player regardless of timezone.
-- A new ISO week starts each Monday at 00:00 UTC. We compute the week
-- number as floor(epoch_with_monday_anchor / 604800). January 1, 1970
-- was a Thursday, so we shift by +259200 (3 days = Mon->Thu offset) so
-- the bucket boundary lands on Monday 00:00 UTC.
local SECONDS_PER_WEEK = 604800
local MONDAY_ANCHOR    = 259200

local function currentIsoWeek()
    return math.floor((os.time() + MONDAY_ANCHOR) / SECONDS_PER_WEEK)
end

-- Resolve a tier id ('normal'/'hard'/'mythic') to its catalog row,
-- with a forgiving fallback when the catalog lacks tiers (e.g. older
-- dungeon_catalog.lua shipped without Phase 2 data). In that case we
-- return a neutral identity tier so downstream multipliers behave.
local IDENTITY_TIER = {
    id = 'normal', label = 'Normal',
    hpMult = 1.0, attMult = 1.0, timeMult = 1.0, infamyMult = 1.0,
    affixCountMin = catalog.affixCountMin or 1,
    affixCountMax = catalog.affixCountMax or 2,
    mythicAffixPool = false,
    weekly = false,
}

local function getTier(tierId)
    if not catalog.tiers then return IDENTITY_TIER end
    return catalog.tiers[tierId or 'normal'] or IDENTITY_TIER
end

-- Per-tier clear counter charvar. Separate from Dungeon_Clears_<id>
-- (which counts ALL tiers - kept for back-compat with existing
-- weekly-hunts hooks and the docs leaderboard).
local function tierClearsCv(dungeon, tierId)
    return string.format('Dungeon_Clears_%s_%s', dungeon.id, tierId)
end

-- Get clears for a specific tier of a specific dungeon.
local function getTierClears(player, dungeon, tierId)
    return player:getCharVar(tierClearsCv(dungeon, tierId)) or 0
end

-- Tier-unlock predicate. Normal is always unlocked. Hard/Mythic check
-- catalog.tiers[tier].unlockRequires { tier = X, clears = N } against
-- the player's per-tier clear counter.
local function isTierUnlocked(player, dungeon, tierId)
    local tier = getTier(tierId)
    if not tier.unlockRequires then return true end
    local req = tier.unlockRequires
    return getTierClears(player, dungeon, req.tier) >= (req.clears or 0)
end

-- Mythic weekly key: each player gets ONE Mythic clear per dungeon
-- per ISO week. The charvar stores the week stamp of the last Mythic
-- clear (NOT a counter). If it matches currentIsoWeek(), the key is
-- already burned for this week.
local function mythicKeyCv(dungeon)
    return string.format('Dungeon_MythicWeek_%s', dungeon.id)
end

local function hasMythicKey(player, dungeon)
    return (player:getCharVar(mythicKeyCv(dungeon)) or 0) ~= currentIsoWeek()
end

local function burnMythicKey(player, dungeon)
    player:setCharVar(mythicKeyCv(dungeon), currentIsoWeek())
end

-- ---------------------------------------------------------------
-- Per-dungeon re-entry cooldowns (anti-farm + anti-spam)
-- ---------------------------------------------------------------
-- One CharVar per dungeon stores the unix time at which the player may
-- re-enter THAT dungeon. Armed when a run ENDS (endDungeon): the full
-- clearCooldownSec after a CLEAR (stops reward farming), the short
-- abortCooldownSec after any non-clear exit (closes the rapid
-- enter/leave/re-enter loop). Checked at startDungeon, GM-exempt at the
-- call site. Reads 0 (ready) when unset. Storing an absolute ready-at
-- timestamp (not the engine's expiry feature) keeps it deploy-portable
-- and lets the menu show the remaining time.
local function reentryCooldownCv(dungeon)
    return string.format('Dungeon_CD_%s', dungeon.id)
end

-- Cooldown length (seconds) for a given exit kind. Per-dungeon override
-- -> catalog default -> hard-coded fallback. 'cleared' draws the long
-- farm gate; every other reason draws the short anti-spam gate.
local function cooldownSecFor(dungeon, reason)
    if reason == 'cleared' then
        return dungeon.clearCooldownSec or catalog.clearCooldownSec or (30 * 60)
    end
    return dungeon.abortCooldownSec or catalog.abortCooldownSec or 90
end

-- Seconds left before the player may re-enter this dungeon (0 = ready).
local function reentryCooldownRemaining(player, dungeon)
    local readyAt = player:getCharVar(reentryCooldownCv(dungeon)) or 0
    return math.max(0, readyAt - os.time())
end

-- Stamp the cooldown for a player on a dungeon, given the exit reason.
-- A longer pending cooldown is never shortened: a quick abort moments
-- after a clear must NOT wipe the 30-min farm gate down to 90 s.
local function armReentryCooldown(player, dungeon, reason)
    local sec = cooldownSecFor(dungeon, reason)
    if sec <= 0 then return end
    local cv      = reentryCooldownCv(dungeon)
    local readyAt = os.time() + sec
    if (player:getCharVar(cv) or 0) < readyAt then
        player:setCharVar(cv, readyAt)
    end
end

-- "29m 50s" / "1m 30s" / "45s" - compact remaining-time formatter.
local function fmtCooldown(sec)
    sec = math.max(0, math.floor(sec))
    local mins = math.floor(sec / 60)
    local secs = sec % 60
    if mins > 0 then
        return string.format('%dm %02ds', mins, secs)
    end
    return string.format('%ds', secs)
end

-- Player-facing reason a tier is currently locked. Returns nil when
-- the tier is fully available, else a short string for the menu.
local function tierLockReason(player, dungeon, tierId)
    local tier = getTier(tierId)
    if not isTierUnlocked(player, dungeon, tierId) then
        local req = tier.unlockRequires
        local have = getTierClears(player, dungeon, req.tier)
        local label = (catalog.tiers and catalog.tiers[req.tier]
            and catalog.tiers[req.tier].label) or req.tier
        return string.format('locked - needs %d %s clears (have %d)',
            req.clears, label, have)
    end
    if tier.weekly and not hasMythicKey(player, dungeon) then
        return 'weekly key consumed - resets Monday 00:00 UTC'
    end
    return nil
end

-----------------------------------
-- PHASE 7 - Mythic+ keystones
-----------------------------------
-- Open-ended key levels above Mythic. Catalog: dungeon_catalog.lua ->
-- catalog.keystone. A keystone run is an ordinary dungeon session whose
-- tier table is SYNTHESIZED per run (synthKeystoneTier) from the
-- player's current key level - the existing spawn / reward / affix
-- plumbing needs no special cases beyond tierId == 'keystone' at the
-- three integration points (startDungeon, endDungeon, menus).

-- id -> affix row lookup across BOTH pools, built lazily on first use
-- so catalog load order doesn't matter.
local AFFIXES_BY_ID = nil
local function affixById(id)
    if not AFFIXES_BY_ID then
        AFFIXES_BY_ID = {}
        for _, a in ipairs(catalog.affixes or {}) do AFFIXES_BY_ID[a.id] = a end
        for _, a in ipairs(catalog.mythicAffixes or {}) do AFFIXES_BY_ID[a.id] = a end
    end
    return AFFIXES_BY_ID[id]
end

local function keystoneEnabled()
    return catalog.keystone and catalog.keystone.enabled or false
end

local function keyLevelCv(dungeon)
    return string.format(catalog.keystone.keyLevelCvFmt, dungeon.id)
end

local function keyBestCv(dungeon)
    return string.format(catalog.keystone.keyBestCvFmt, dungeon.id)
end

-- Current key level for a dungeon. Unset charvar (0) reads as minLevel,
-- so a fresh unlock starts at M+1 without any initialization step.
local function getKeyLevel(player, dungeon)
    return math.max(catalog.keystone.minLevel or 1,
        player:getCharVar(keyLevelCv(dungeon)) or 0)
end

local function setKeyLevel(player, dungeon, level)
    player:setCharVar(keyLevelCv(dungeon),
        math.max(catalog.keystone.minLevel or 1, level))
end

-- Highest key level ever cleared for this dungeon (0 = none yet).
local function getKeyBest(player, dungeon)
    return player:getCharVar(keyBestCv(dungeon)) or 0
end

local function isKeystoneUnlocked(player, dungeon)
    if not keystoneEnabled() then return false end
    local req = catalog.keystone.unlockRequires
    if not req then return true end
    return getTierClears(player, dungeon, req.tier) >= (req.clears or 0)
end

-- Player-facing reason Mythic+ is locked for this dungeon, or nil.
local function keystoneLockReason(player, dungeon)
    if not keystoneEnabled() then return 'disabled' end
    local req = catalog.keystone.unlockRequires
    if not req then return nil end
    local have = getTierClears(player, dungeon, req.tier)
    if have >= (req.clears or 0) then return nil end
    local label = (catalog.tiers and catalog.tiers[req.tier]
        and catalog.tiers[req.tier].label) or req.tier
    return string.format('locked - needs %d %s clear%s of this dungeon (have %d)',
        req.clears, label, req.clears == 1 and '' or 's', have)
end

-- This ISO week's affix id list (rotates Monday 00:00 UTC, same anchor
-- as the Mythic weekly key).
local function keystoneWeekSet()
    local rot = (catalog.keystone and catalog.keystone.rotation) or {}
    if #rot == 0 then return {} end
    return rot[(currentIsoWeek() % #rot) + 1]
end

-- How many of the week's affixes are active at a given key level.
local function keystoneAffixCount(level)
    local n = 0
    for _, t in ipairs(catalog.keystone.affixThresholds or {}) do
        if level >= t.level then n = math.max(n, t.count) end
    end
    return n
end

-- Resolve this week's ACTIVE affix rows for a key level: the first N
-- ids of the week set, N from the level thresholds. Unknown ids are
-- skipped (catalog typo shouldn't break the run).
local function keystoneAffixesFor(level)
    local ids = keystoneWeekSet()
    local out = {}
    for i = 1, math.min(keystoneAffixCount(level), #ids) do
        local row = affixById(ids[i])
        if row then table.insert(out, row) end
    end
    return out
end

-- Synthesize the tier table for a keystone run at a given level. Shaped
-- exactly like a catalog.tiers row so every downstream consumer (spawn
-- scaling, time limit, reward math, banners) works unchanged. weekly is
-- ALWAYS false - keystone runs never burn the Mythic weekly key.
local function synthKeystoneTier(level)
    local ks  = catalog.keystone
    local b   = ks.base
    local per = ks.perLevel
    local up  = level - 1

    local att = b.attMult * (1 + (per.att or 0) * up)
    if ks.attMultCap then att = math.min(att, ks.attMultCap) end

    local infamy = b.infamyMult * (1 + (per.infamy or 0) * up)
    if ks.infamyMultCap then infamy = math.min(infamy, ks.infamyMultCap) end

    return {
        id            = 'keystone',
        label         = string.format('%s%d', ks.labelShort or 'M+', level),
        description   = ks.description or 'Endless keystone push.',
        hpMult        = b.hpMult * (1 + (per.hp or 0) * up),
        attMult       = att,
        timeMult      = b.timeMult or 1.0,
        infamyMult    = infamy,
        affixCountMin = 0,      -- affixes come from the weekly rotation,
        affixCountMax = 0,      -- not the random roller
        mythicAffixPool = false,
        unlockRequires  = nil,  -- real gate is isKeystoneUnlocked
        weekly          = false,
        keystoneLevel   = level,
    }
end

-- Key delta for a clear: walk catalog.keystone.upgrade in order, first
-- threshold the elapsed FRACTION fits under wins. Defaults to +1.
local function keystoneUpgradeDelta(elapsed, limit)
    if not limit or limit <= 0 then return 1 end
    local frac = elapsed / limit
    for _, u in ipairs(catalog.keystone.upgrade or {}) do
        if frac <= u.frac then return u.delta end
    end
    return 1
end

-----------------------------------
-- PHASE 4 - Meta-progression (daily featured + streak + key UI)
-----------------------------------
-- Three player-facing systems layered onto the reward path. None of
-- them touch session lifecycle directly - they read at clear time
-- and write small charvars. Daily featured needs zero state at all
-- (purely deterministic from the UTC day stamp).

-- Day index for daily featured rotation. Uses raw UTC days since
-- epoch - Jan 1, 1970 UTC = day 0. Same instant on every server.
local SECONDS_PER_DAY = 86400
local function currentUtcDay()
    return math.floor(os.time() / SECONDS_PER_DAY)
end

-- Today's featured dungeon row (or nil if no enabled dungeons exist).
-- Deterministic: same day -> same dungeon for every player. Skips any
-- dungeons disabled at module load so the feature can't land on a
-- dungeon that would otherwise be hidden from the menu.
local function getFeaturedDungeon()
    local enabled = {}
    for _, d in ipairs(catalog.dungeons or {}) do
        if not d._disabled then table.insert(enabled, d) end
    end
    if #enabled == 0 then return nil end
    local idx = (currentUtcDay() % #enabled) + 1
    return enabled[idx]
end

-- Is THIS dungeon today's featured pick?
local function isFeatured(dungeon)
    if not dungeon then return false end
    local f = getFeaturedDungeon()
    return f and f.id == dungeon.id or false
end

-- ============================================================
-- WEEKLY BONUS DUNGEON
-- ============================================================
-- One dungeon per ISO week awards 2x Infamy on clear. The featured
-- dungeon rotates deterministically using the same weekIdx formula as
-- the Hunting League's weekly featured hunt:
--   weekIdx = math.floor(os.time() / 604800)
-- so every player on the server sees the same bonus dungeon for the
-- full ISO week (Monday 00:00 UTC -> next Monday 00:00 UTC).
--
-- CharVar gating: DB_Bonus_<weekIdx>_<dungeonId> = 1 is written the
-- first time a player earns the bonus. Subsequent clears of the same
-- dungeon in the same week still award normal Infamy - the 2x is a
-- one-time-per-week bonus, not a permanent doubling.

local function getWeeklyBonusDungeon()
    local weekIdx = math.floor(os.time() / 604800)
    local enabled = {}
    for _, d in ipairs(catalog.dungeons or {}) do
        if not d._disabled then table.insert(enabled, d) end
    end
    if #enabled == 0 then return nil, weekIdx end
    local idx = (weekIdx % #enabled) + 1
    return enabled[idx], weekIdx
end

-- Is THIS dungeon this week's bonus dungeon?
local function isWeeklyBonus(dungeon)
    if not dungeon then return false end
    local b, _ = getWeeklyBonusDungeon()
    return b and b.id == dungeon.id or false
end

-- CharVar name for the weekly bonus earned flag.
local function weeklyBonusCv(weekIdx, dungeonId)
    return string.format('DB_Bonus_%d_%s', weekIdx, dungeonId)
end

-- Has the player already earned the weekly bonus for this dungeon?
local function hasEarnedWeeklyBonus(player, weekIdx, dungeonId)
    return (player:getCharVar(weeklyBonusCv(weekIdx, dungeonId)) or 0) == 1
end

-- Mark the weekly bonus as earned.
local function markWeeklyBonusEarned(player, weekIdx, dungeonId)
    player:setCharVar(weeklyBonusCv(weekIdx, dungeonId), 1)
end

-- Streak helpers. The streak charvar is global per player (NOT per
-- dungeon) - clearing any dungeon counts. So you can chain Outer
-- Bastion -> Voidwalker Arena -> Empyreal Paradox for a 3-streak and
-- get +30% on the third clear.
local function getStreak(player)
    return player:getCharVar(catalog.streakCv or 'Dungeon_Streak') or 0
end

local function setStreak(player, n)
    player:setCharVar(catalog.streakCv or 'Dungeon_Streak', n)
end

local function bumpStreak(player)
    local cap = catalog.streakCap or 5
    local n   = math.min(getStreak(player) + 1, cap)
    setStreak(player, n)
    return n
end

local function resetStreak(player)
    setStreak(player, 0)
end

-- Streak multiplier (1.0 .. 1.0 + cap*step). Read at clear time.
local function streakMult(player)
    return 1.0 + getStreak(player) * (catalog.streakStep or 0.10)
end

-- Seconds until the next ISO-week boundary (Monday 00:00 UTC). Used
-- for the "Mythic resets in Xd Yh" UI on the dungeon menu. Reuses
-- the same MONDAY_ANCHOR offset as currentIsoWeek so the displayed
-- countdown agrees exactly with when hasMythicKey() will return true.
local function secondsToNextWeek()
    local weekStart = (currentIsoWeek() + 1) * SECONDS_PER_WEEK - MONDAY_ANCHOR
    return math.max(0, weekStart - os.time())
end

-- Seconds until the next UTC day boundary. Used for the "Featured
-- resets in Xh Ym" UI in the dungeon menu.
local function secondsToNextDay()
    local nextDay = (currentUtcDay() + 1) * SECONDS_PER_DAY
    return math.max(0, nextDay - os.time())
end

-- Short "Xd Yh" / "Xh Ym" / "Xm" formatter for countdowns.
local function fmtCountdown(secs)
    if secs >= 86400 then
        local d = math.floor(secs / 86400)
        local h = math.floor((secs % 86400) / 3600)
        return string.format('%dd %dh', d, h)
    elseif secs >= 3600 then
        local h = math.floor(secs / 3600)
        local mins = math.floor((secs % 3600) / 60)
        return string.format('%dh %dm', h, mins)
    elseif secs >= 60 then
        return string.format('%dm', math.floor(secs / 60))
    end
    return string.format('%ds', secs)
end

-----------------------------------
-- PHASE 1 - Per-run affixes
-----------------------------------
-- An "affix" is a small data-driven mutator that's rolled at session
-- start and applied to the boss / trash / session / reward. Each affix
-- carries a rewardMult; positive affixes (e.g. Fragile) make the run
-- easier and pay less, negative affixes (e.g. Mighty) make the run
-- harder and pay more. Catalog: dungeon_catalog.lua -> catalog.affixes.
--
-- This block stays generic - the per-affix logic lives entirely in the
-- catalog so adding/removing affixes never requires touching the system
-- file. Same pattern as the seal/reforge/augment catalogs.

-- Roll affixes for a tier. The tier controls:
--   * count range (Mythic gets 2-3, lower tiers get 1-2)
--   * pool composition (Mythic also draws from catalog.mythicAffixes)
-- Returns a list of catalog affix rows in the order they were rolled.
-- Mythic affixes are guaranteed at least 1 slot when the tier opts in
-- (so the player always sees something Tyrannical on a Mythic run),
-- but the rest of the slots draw from the combined pool.
local function rollAffixes(tier)
    tier = tier or IDENTITY_TIER
    local basePool = catalog.affixes or {}
    if #basePool == 0 then return {} end

    -- Build the effective pool. Mythic pool entries are tagged so
    -- the seeding logic below can guarantee one of them lands in
    -- the roll without coupling to "the first N entries".
    local pool = {}
    for _, a in ipairs(basePool) do
        table.insert(pool, { row = a, mythic = false })
    end
    if tier.mythicAffixPool and catalog.mythicAffixes then
        for _, a in ipairs(catalog.mythicAffixes) do
            table.insert(pool, { row = a, mythic = true })
        end
    end

    local minN = tier.affixCountMin or catalog.affixCountMin or 1
    local maxN = tier.affixCountMax or catalog.affixCountMax or 2
    local n    = math.random(minN, math.min(maxN, #pool))

    -- Reservoir-style draw without replacement. The pool is small
    -- (~15-20 entries), so an in-place shuffle of indices is fine.
    local indices = {}
    for i = 1, #pool do indices[i] = i end
    for i = #pool, 2, -1 do
        local j = math.random(i)
        indices[i], indices[j] = indices[j], indices[i]
    end

    -- Mythic tier guarantee: ensure at least one mythic affix lands.
    -- If the random shuffle didn't put one in the top-n slots, swap
    -- the first available mythic index into slot 1.
    if tier.mythicAffixPool and n > 0 then
        local hasMythic = false
        for k = 1, n do
            if pool[indices[k]].mythic then hasMythic = true; break end
        end
        if not hasMythic then
            for k = n + 1, #indices do
                if pool[indices[k]].mythic then
                    indices[1], indices[k] = indices[k], indices[1]
                    break
                end
            end
        end
    end

    local out = {}
    for k = 1, n do
        table.insert(out, pool[indices[k]].row)
    end
    return out
end

-- Nightmare tier: one deterministic affix from the mythic pool, rotating
-- each ISO week. Same affix for all players the entire week (Monday-Sunday).
local function weeklyFixedAffix()
    local pool = (catalog.mythicAffixes and #catalog.mythicAffixes > 0)
        and catalog.mythicAffixes
        or  (catalog.affixes or {})
    if #pool == 0 then return {} end
    local idx = (currentIsoWeek() % #pool) + 1
    return { pool[idx] }
end

-- Compute the product of all rolled affixes' rewardMult. Returns 1.0
-- when no affixes were rolled (back-compat with catalogs that ship
-- without affix data - the system stays neutral).
local function affixRewardMult(affixes)
    local m = 1.0
    for _, a in ipairs(affixes or {}) do
        if a.rewardMult then m = m * a.rewardMult end
    end
    return m
end

-- Apply affix effects to a freshly-spawned mob. The session caches
-- whether the affix has any boss/trash hooks so we can no-op fast for
-- runs where every rolled affix is session-/reward-only (e.g. Bountiful
-- + Lengthy - no engine mod work to do).
local function applyAffixesToMob(sess, mob, isBoss)
    if not sess or not sess.affixes then return end
    for _, a in ipairs(sess.affixes) do
        local fn = isBoss and a.applyBoss or a.applyTrash
        if fn then
            pcall(fn, mob)
        end
    end
end

-- Apply session-level affix mutations (timeLimitOverride etc.) once at
-- session start, BEFORE the timer is armed.
local function applyAffixesToSession(sess)
    if not sess or not sess.affixes then return end
    for _, a in ipairs(sess.affixes) do
        if a.applySession then pcall(a.applySession, sess) end
    end
end

-----------------------------------
-- PHASE 3 - Boss mechanics (HP-threshold triggers + enrage timer)
-----------------------------------
-- A "phase" is a data row in dungeon.phases that fires when the boss's
-- HP% drops at or below `hp`. Catalog defines WHAT and WHEN; this
-- block defines HOW each named action behaves. Adding a new action is
-- a single function addition; the catalog doesn't have to change.
--
-- Phase actions get four args:
--   boss    the boss mob entity (caller verified non-nil)
--   sess    the active session (caller verified non-nil)
--   player  the player entity that owns the session
--   p       the catalog phase row (action + params)
--
-- Each action is responsible for ALL of: applying the engine effect,
-- guarding pcalls around any API that can throw, and printing a
-- player-facing message if `p.message` is set.

-- Forward decl - bossActions references spawnDungeonMob, which is
-- defined further down. Resolved lazily inside add_spawn at call time.
local spawnDungeonMobFn
local spawnBoss  -- forward decl; defined after spawnDungeonMob below

local function _say(player, p, fallback)
    if p.message then
        player:printToPlayer('** ' .. p.message .. ' **', xi.msg.channel.SYSTEM_3)
    elseif fallback then
        player:printToPlayer('** ' .. fallback .. ' **', xi.msg.channel.SYSTEM_3)
    end
end

local function _addMod(mob, modId, delta)
    if not delta or delta == 0 then return end
    local current = mob:getMod(modId) or 0
    mob:setMod(modId, current + delta)
end

local bossActions =
{
    -- Apply permanent stat mods. The lightest-weight trigger; combine
    -- with `message` for an early-fight stat bump that feels narrative.
    buff = function(boss, sess, player, p)
        _addMod(boss, xi.mod.ATT,        p.att)
        _addMod(boss, xi.mod.STR,        p.str)
        _addMod(boss, xi.mod.HASTE_GEAR, p.haste)
        if p.dt then
            -- dt is "damage taken reduction" - positive number reduces
            -- incoming damage; subtract from PHYS/MAGIC_DMG_TAKEN.
            _addMod(boss, xi.mod.PHYS_DMG_TAKEN,  -p.dt)
            _addMod(boss, xi.mod.MAGIC_DMG_TAKEN, -p.dt)
        end
        _say(player, p, 'The boss grows in power!')
    end,

    -- Buff + bigger numbers + louder message. Semantically identical
    -- to buff but conventionally used for the BIG late-fight pop.
    enrage = function(boss, sess, player, p)
        _addMod(boss, xi.mod.ATT,        p.att   or 2000)
        _addMod(boss, xi.mod.STR,        p.str   or 100)
        _addMod(boss, xi.mod.HASTE_GEAR, p.haste or 100)
        if p.dt then
            _addMod(boss, xi.mod.PHYS_DMG_TAKEN,  -p.dt)
            _addMod(boss, xi.mod.MAGIC_DMG_TAKEN, -p.dt)
        end
        _say(player, p, 'The boss enters an enraged frenzy!')
    end,

    -- Heal the boss by a percentage of its max HP. Creates a DPS check
    -- - the player has to outrun the heal. Capped at maxHP by addHP().
    heal = function(boss, sess, player, p)
        local pct  = p.pct or 25
        local amt  = math.floor(boss:getMaxHP() * pct / 100)
        boss:addHP(amt)
        _say(player, p, string.format('The boss heals for %d!', amt))
    end,

    -- AoE damage tick to the player. Doesn't kill - clamped to leave
    -- at least 1 HP so the phase trigger never feels like an unfair
    -- one-shot (the boss can still kill you the old-fashioned way).
    aoe = function(boss, sess, player, p)
        local dmg = p.damage or 500
        local hp  = player:getHP()
        local cap = math.max(1, hp - 1)
        player:delHP(math.min(dmg, cap))
        _say(player, p, string.format('Dark energy lashes you for %d damage!', math.min(dmg, cap)))
    end,

    -- Strip N buffs off the player. Each call removes one dispellable
    -- effect; we call it `count` times in a row. pcall in case the
    -- engine API isn't on this LSB version.
    dispel = function(boss, sess, player, p)
        for _ = 1, (p.count or 3) do
            pcall(function() player:dispelStatusEffect() end)
        end
        _say(player, p, 'Your protective magics are torn away!')
    end,

    -- Spawn N adds at the boss's current position, force-aggroed onto
    -- the player. Adds go into sess.mobs so they get cleaned up on
    -- session end; they're spawned via the same spawnDungeonMob
    -- path used for trash (level, mods, etc.). The `forceAggro` opt
    -- skips the usual passive-spawn handshake so the add engages
    -- immediately rather than waiting for detection.
    add_spawn = function(boss, sess, player, p)
        local fn = spawnDungeonMobFn
        if not fn then return end
        local bx, by, bz = boss:getXPos(), boss:getYPos(), boss:getZPos()
        local count = p.count or 1
        for _ = 1, count do
            local angle = math.random() * math.pi * 2
            local r     = 2 + math.random() * 4
            local tx    = bx + math.cos(angle) * r
            local tz    = bz + math.sin(angle) * r
            local add = fn(player, sess.dungeon, {
                groupId    = p.groupId,
                level      = p.level or (sess.dungeon.bossLevel - 30),
                name       = p.name  or 'Phase Add',
                pos        = { x = tx, y = by, z = tz, rot = math.random(0, 255) },
                isBoss     = false,
                forceAggro = true,
            })
            if add then
                table.insert(sess.mobs, add)
            end
        end
        _say(player, p, string.format('%d %s spawns to defend the boss!',
            count, p.name or 'reinforcement'))
    end,
}

-- Fire one phase row (called from the onMobFight HP-watcher and the
-- enrageAfter timer). Validates the action name and falls through
-- silently on unknown actions so a typo in the catalog can't crash
-- the dungeon mid-fight.
local function fireBossAction(boss, sess, player, phase)
    if not phase or not phase.action then return end
    local handler = bossActions[phase.action]
    if not handler then
        print(string.format("[dungeon] WARNING: unknown phase action '%s'", phase.action))
        return
    end
    print(string.format("[dungeon] >> phase trigger: action=%s hp_threshold=%s",
        phase.action, tostring(phase.hp or 'time')))
    pcall(handler, boss, sess, player, phase)
end

-----------------------------------
-- Mob spawn helpers
-----------------------------------

-- Look up the difficulty-scaled mod profile for a given mob level.
-- The catalog defines templates at 150/175/200/225/250 anchors but
-- waypoints can use any level - fall back to the CLOSEST defined
-- template at or below the requested level. Lv130 -> Lv150 template
-- adjusted-by-engine-level; Lv170 -> Lv150 template; Lv180 -> Lv175.
-- The engine still uses the actual level for base stats; this table
-- just adds the offensive package on top.
local function modsForLevel(level)
    if catalog.levelMods[level] then
        return catalog.levelMods[level]
    end
    local best = nil
    for k, _ in pairs(catalog.levelMods) do
        if k <= level and (best == nil or k > best) then
            best = k
        end
    end
    return best and catalog.levelMods[best] or nil
end

-- Spawn one mob in the dungeon zone. Reused for both trash and boss.
-- Applies the level template (stats + HP boost), claim-locks to the
-- player, force-aggros via enmity injection, blocks CP gains, and
-- wires onMobDeath into the session machinery.
--
-- For BOSS: pass `isBoss = true` so:
--   * HP boost gets the bossHpMultiplier on top of the level template
--   * onMobDeath triggers the dungeon-clear path instead of just
--     trimming the session's mob set
local function spawnDungeonMob(player, dungeon, opts)
    local groupId    = opts.groupId
    local level      = opts.level
    local name       = opts.name
    local pos        = opts.pos
    local isBoss     = opts.isBoss or false
    local forceAggro = opts.forceAggro or false  -- Phase 3 add_spawn opt
    -- Gate rail (2026-05-30): aggressive mobs notice + engage the player
    -- on approach; gateId ties this mob to a session gate so its death
    -- decrements that gate's alive count; hpMultExtra is the NM mini-boss
    -- toughness multiplier layered on top of the level template.
    local aggressive  = opts.aggressive or false
    local gateId      = opts.gateId
    local hpMultExtra = opts.hpMultExtra
    local ownerName  = player:getName()

    local zone = player:getZone()
    if not zone then
        print(string.format("[dungeon] ERROR: spawnDungeonMob '%s': player:getZone() returned nil. "
            .. "Player may still be mid-zone-load.", name or '?'))
        return nil
    end

    -- Diagnostic: log every spawn attempt so the server log shows
    -- exactly what's happening. Cheap (3 lines per spawn) and
    -- invaluable when debugging "where did my mobs go?" reports.
    print(string.format(
        "[dungeon] spawn '%s' (groupId=%d, groupZoneId=%d) in zone %d at (%.2f, %.2f, %.2f) Lv%d isBoss=%s",
        name, groupId, catalog.groupZoneId, zone:getID(),
        pos.x, pos.y, pos.z, level, tostring(isBoss)))

    -- Visual size:
    --   modelSize 0 = stock (engine default - trash uses this)
    --   modelSize 1 = small bump
    --   modelSize 2 = noticeably larger (default for bosses)
    --   modelSize 3 = huge - risky against zone geometry
    -- The boss size is per-dungeon (catalog override) so a tight arena
    -- (Diorama Ghelsba) can keep its boss at 2 while an open chamber
    -- like Empyreal Paradox or the Castle Zvahl Baileys main hall can
    -- crank it to 3 without clipping. Trash always renders stock.
    -- Wired to the spawn dict AND re-applied post-spawn since some
    -- CalculateMobStats paths can reset display attributes.
    local modelSize = 0
    if isBoss then
        modelSize = dungeon.bossModelSize or catalog.bossModelSize or 2
    end
    -- Explicit override (NM mini-bosses pass modelSize = 1 so they read as
    -- elites without the full boss bulk).
    if opts.modelSize then
        modelSize = opts.modelSize
    end

    -- FJB: the engine stores mob level in a uint8 (max 255). Catalog apex levels
    -- ABOVE 255 (Eternal Throne / Sunken Spire NMs Lv256-270, boss Lv275) OVERFLOW
    -- the field -- Lv275 wraps to Lv19, Lv262 to Lv6 -- so the boss spawns with a
    -- Lv19 mob's HP and the run insta-clears, paying out for nothing. Cap the
    -- ENGINE level at 255; the un-capped `level` still drives modsForLevel + the
    -- hpBoost below, so the mob keeps its intended apex toughness.
    local engineLevel = (type(level) == 'number') and math.min(level, 255) or level

    local mob = zone:insertDynamicEntity({
        objtype              = xi.objType.MOB,
        groupId              = groupId,
        groupZoneId          = catalog.groupZoneId,
        name                 = name,
        x                    = pos.x,
        y                    = pos.y,
        z                    = pos.z,
        rotation             = pos.rot or 0,
        minLevel             = engineLevel,
        maxLevel             = engineLevel,
        modelSize            = modelSize,
        -- PASSIVE design: both flags set DURING instantiation so the
        -- engine knows the mob is non-aggressive from the very first
        -- tick. detection=NONE clears the sight/hearing bitfield;
        -- isAggroable=false disables the engine's "this mob can attack
        -- unprovoked" boolean at the entity level. Together they prevent
        -- the first-tick aggro race that bit us when these were set
        -- AFTER mob:spawn().
        detection            = aggressive and (xi.detects.SIGHT + xi.detects.HEARING) or xi.detects.NONE,
        isAggroable          = aggressive,
        releaseIdOnDisappear = true,

        onMobDeath = function(deadMob, killer)
            local sess = sessions[ownerName]
            if not sess then return end

            -- Untrack from the mobs list (linear scan; mob counts are
            -- small, ~6-10 per dungeon).
            for i, mref in ipairs(sess.mobs) do
                if mref and mref:getID() == deadMob:getID() then
                    table.remove(sess.mobs, i)
                    break
                end
            end

            -- Phase-5 telemetry: trash kills count toward the "Slayer"
            -- objective (kill every trash mob the dungeon spawned).
            -- Boss death is tracked via sess.cleared below.
            if not isBoss then
                sess.trashKilled = (sess.trashKilled or 0) + 1
                -- All trash/NMs dead and boss hasn't spawned yet → trigger it.
                if not sess.bossEntity and #sess.mobs == 0 and spawnBoss then
                    local resolved = GetPlayerByName(ownerName)
                    if resolved then spawnBoss(resolved) end
                end
            end

            -- Gate accounting: when the last mob guarding a threshold
            -- dies, open the gate (the patrol stops blocking that depth)
            -- and tell the player the way deeper is clear.
            if gateId and sess.gates and sess.gates[gateId] then
                local g = sess.gates[gateId]
                g.alive = (g.alive or 1) - 1
                if g.alive <= 0 and not g.cleared then
                    g.cleared = true
                    local opener = GetPlayerByName(ownerName)
                    if opener then
                        opener:printToPlayer(
                            string.format('[Dungeon] %s falls - the way deeper opens, kupo!',
                                g.label or 'The guardians'),
                            xi.msg.channel.SYSTEM_3)
                    end
                end
            end

            if isBoss then
                sess.cleared = true
                -- Defer the success branch through endDungeon so the
                -- timer-cancel + reward + warp-out path is centralized.
                local resolved = GetPlayerByName(ownerName)
                if resolved then
                    m.endDungeon(resolved, 'cleared')
                end
            end
        end,

        -- PHASE 3 - onMobFight phase-trigger tick. Fires every combat
        -- tick the boss is engaged. We:
        --   1. Check sess + dungeon.phases exist (no-op for non-Phase-3
        --      dungeons and for trash mobs - only bosses get this hook).
        --   2. Read the boss's current HP%.
        --   3. Walk dungeon.phases in catalog order. For each entry not
        --      already fired this session that meets `getHPP() <= hp`,
        --      fire it and mark it fired.
        --
        -- Walked in order even when the HP drop jumps multiple bands -
        -- a single big hit from 90% to 20% legitimately fires the 75%,
        -- 50%, and 25% phases on the same tick, in that sequence, so
        -- compounded effects (buff then enrage then heal) apply in the
        -- author-intended order.
        --
        -- Wrapped in pcall around the action call so a bad data row
        -- in the catalog can't break the boss's AI tick. Per-row
        -- pcall (vs one big pcall) is intentional - if phase[2] errors
        -- we still want phase[3] to run.
        onMobFight = isBoss and function(fightMob, target)
            local sess = sessions[ownerName]
            if not sess or not sess.dungeon then return end
            local phases = sess.dungeon.phases
            if not phases or #phases == 0 then return end

            sess.firedPhases = sess.firedPhases or {}
            local hpp = fightMob:getHPP()
            for idx, phase in ipairs(phases) do
                if not sess.firedPhases[idx]
                   and phase.hp ~= nil
                   and hpp <= phase.hp then
                    sess.firedPhases[idx] = true
                    local resolved = GetPlayerByName(ownerName)
                    if resolved then
                        fireBossAction(fightMob, sess, resolved, phase)
                    end
                end
            end
        end or nil,
    })
    if not mob then
        print(string.format(
            "[dungeon] ERROR: insertDynamicEntity returned nil for '%s' "
            .. "(groupId=%d, groupZoneId=%d). Mob_groups row missing?",
            name, groupId, catalog.groupZoneId))
        return nil
    end

    -- CRITICAL: apply NO_AGGRO + DETECTION=NONE BEFORE spawn().
    -- Once mob:spawn() runs, the engine immediately scans for nearby
    -- targets and can aggro on the same frame. Setting these BEFORE
    -- spawn means they're in place at the first aggro tick.
    -- Passive mobs are born non-aggressive. Gate/NM mobs skip this so the
    -- engine's first aggro tick already sees them as hostile and they can
    -- notice the player on approach.
    if not aggressive then
        mob:setMobMod(xi.mobMod.NO_AGGRO, 1)
        mob:setMobMod(xi.mobMod.DETECTION, xi.detects.NONE)
    end

    mob:setSpawn(pos.x, pos.y, pos.z, pos.rot or 0)
    mob:spawn()
    print(string.format("[dungeon] spawned mob entity id=%d for '%s' (passive)", mob:getID(), name))

    -- Belt-and-suspenders: re-apply after spawn too, in case spawn()
    -- reset anything via CalculateMobStats or a mixin. Aggressive gate/NM
    -- mobs get the OPPOSITE treatment - detection ON so they engage the
    -- player who steps into range (the un-skippable guardian rail).
    if aggressive then
        mob:setMobMod(xi.mobMod.NO_AGGRO, 0)
        mob:setMobMod(xi.mobMod.DETECTION, xi.detects.SIGHT + xi.detects.HEARING)
    else
        mob:setMobMod(xi.mobMod.NO_AGGRO, 1)
        mob:setMobMod(xi.mobMod.DETECTION, xi.detects.NONE)
    end

    -- Block CP - dungeon is a challenge/Infamy farm, not a JP farm.
    mob:setMobMod(xi.mobMod.NO_CAPACITY_POINTS, 1)

    -- Re-apply boss model size post-spawn. The instantiation-time
    -- value usually sticks (it's loaded straight from the spawn dict
    -- into PMob->modelSize before the first packet goes out), but if
    -- any mob_pool default or CalculateMobStats pass overwrites it,
    -- this second call wins. Trash skips this since their size stays
    -- at the stock 0.
    if isBoss and modelSize > 0 then
        pcall(function() mob:setModelSize(modelSize) end)
    end

    -- Apply level-template stat mods + HP boost. Same pattern as
    -- HuntingLeague / Reforge / GameMaster.
    local sess = sessions[ownerName]
    local tier = (sess and sess.tier) or IDENTITY_TIER

    local tpl = modsForLevel(level)
    if tpl then
        if tpl.mods then
            for modId, value in pairs(tpl.mods) do
                -- Phase-2 tier ATT scaling: bonus = base * (attMult - 1)
                -- gets added on top of the level template's ATT value.
                -- Applied additively so we don't surprise existing
                -- mod combinations (e.g. STR boosts).
                if modId == xi.mod.ATT and tier.attMult and tier.attMult ~= 1.0 then
                    value = math.floor(value * tier.attMult)
                end
                mob:setMod(modId, value)
            end
        end
        local hpMult = tpl.hpBoost or 1
        if isBoss then
            hpMult = hpMult * (catalog.bossHpMultiplier or 1)
        end
        -- Phase-2 tier HP scaling: applies to BOTH trash and boss.
        if tier.hpMult and tier.hpMult ~= 1.0 then
            hpMult = hpMult * tier.hpMult
        end
        -- NM mini-boss extra HP - keeps an elite sitting between trash and
        -- the final boss in toughness.
        if hpMultExtra and hpMultExtra > 1 then
            hpMult = hpMult * hpMultExtra
        end
        if hpMult > 1 then
            local newMax = mob:getMaxHP() * hpMult
            mob:setMaxHP(newMax)
            mob:setHP(newMax)
        end
    end

    -- Phase-1 affixes. Applied AFTER the level template AND tier
    -- multipliers, so things like Hardy's HPx1.5 multiplies the
    -- already-tier-boosted total. Trash affixes (Overgrown) and
    -- boss affixes (Mighty / Voracious / Frenzied / Tyrannical /
    -- Titanic / Apex Predator) route through the same helper;
    -- per-row applyBoss vs applyTrash decides which side runs.
    applyAffixesToMob(sess, mob, isBoss)

    -- Passive flags are now set in THREE places:
    --   1. Spawn dict (detection=NONE, isAggroable=false) - engine
    --      reads these during instantiation, so the mob is born passive.
    --   2. Pre-spawn setMobMod - applied to the freshly-created entity
    --      BEFORE mob:spawn() runs the first aggro tick.
    --   3. Post-spawn setMobMod - applied AFTER spawn in case
    --      CalculateMobStats or any mixin reset something.
    -- Triple-set is intentional belt-and-suspenders. The aggro race we
    -- saw before (mob aggros on the same frame as spawn() before the
    -- Lua-side setMobMod can apply) is now closed at every step.
    --
    -- Combat after a manual attack is unaffected - addEnmity still
    -- works, the mob still pursues + swings + uses TP moves normally.
    -- Linking between mobs is also blocked (linking IS detection).

    -- DO NOT pre-claim the mob.
    --
    -- updateClaim() calls battleutils::ClaimMob(), which internally calls
    -- mob->PEnmityContainer->UpdateEnmity(player, 0, 0, true, true) -
    -- that ADDS the player to the mob's enmity list with active=true.
    -- Once the player is in the enmity container, the mob is already
    -- "engaged" regardless of MOBMOD_NO_AGGRO / DETECTION=NONE. The
    -- aggro-check codepath only runs for INITIAL aggro selection; an
    -- enmity-listed target is just attacked outright.
    --
    -- Net result of the old call: every dungeon mob was added to the
    -- player's threat list at spawn time and ran straight at them as
    -- soon as their PAI tick processed enmity. That looked exactly like
    -- "they aggroed me on zone-in" because functionally they had.
    --
    -- Without updateClaim, the natural claim flow kicks in: the moment
    -- the player auto-attacks / casts / uses WS on a mob, the combat
    -- handler calls ClaimMob itself and ownership locks to the player.
    -- Dungeon zones host one session at a time so claim contention
    -- isn't a real risk - and even if a stray player wandered in, the
    -- mob STILL only engages on first-touch, which is the desired
    -- "prep your party before pulling" UX.
    --
    -- (Bug discovered 2026-05-28 after user reported "still getting
    -- instant aggro upon zoning in" even with the triple-redundant
    -- NO_AGGRO + DETECTION=NONE + isAggroable=false defenses.)

    -- NO force-aggro. Progression dungeons rely on detection range -
    -- the player walks deeper into the zone, encounters each tier
    -- of mobs at their own pace. Earlier versions had the boss
    -- force-aggro on spawn (and once had every mob force-aggro);
    -- both led to instant-death problems. Now everyone waits for
    -- the player to engage them either by attacking or by stepping
    -- into the mob's natural detection radius.
    --
    -- EXCEPTION (Phase 3): add_spawn uses forceAggro because the adds
    -- materialise MID-FIGHT and the player has no chance to detect
    -- them before the boss is already swinging. We undo the passive
    -- flags and inject enmity directly onto the player so the add
    -- engages on the next combat tick.
    if forceAggro then
        mob:setMobMod(xi.mobMod.NO_AGGRO, 0)
        mob:setMobMod(xi.mobMod.DETECTION, xi.detects.SIGHT + xi.detects.HEARING)
        pcall(function() mob:updateEnmity(player) end)
        pcall(function() mob:addEnmity(player, 1, 1) end)
    end

    return mob
end

-- Bind the forward-declared reference Phase 3 add_spawn uses. The
-- bossActions table was defined before spawnDungeonMob so the action
-- handler couldn't capture it directly; this line closes that gap.
spawnDungeonMobFn = spawnDungeonMob

-- Spawns the dungeon boss. Called either when all trash/NMs are dead (normal path)
-- or immediately when the dungeon spawns no trash mobs at all (safety fallback).
spawnBoss = function(player)
    local sess = sessions[player:getName()]
    if not sess or not sess.bossPending or sess.bossEntity then return end
    local dungeon = sess.dungeon
    local bp      = sess.bossPending
    sess.bossPending = nil  -- clear first to prevent re-entrant double-spawn

    player:printToPlayer(
        string.format('[Dungeon] All enemies defeated! %s appears!', bp.name or 'The boss'),
        xi.msg.channel.SYSTEM_3)

    local boss = spawnDungeonMob(player, dungeon, {
        groupId = bp.groupId,
        level   = dungeon.bossLevel,
        name    = bp.name,
        pos     = bp.pos,
        isBoss  = true,
    })
    if boss then
        sess.bossEntity = boss
        table.insert(sess.mobs, boss)
    end
end


local function pickFromList(list)
    return list[math.random(#list)]
end


-- Spawn every mob the dungeon needs in one pass.
--
-- LAYOUT MODEL: progression along an axis.
--   1. Read dungeon.progressionAxis (unit vector dx/dz) - the "depth"
--      direction of the dungeon.
--   2. Walk dungeon.waypoints in order. Each waypoint is a tier of
--      mobs at a specific distance along the axis. Each waypoint
--      defines its own count, level, mob pool, names, and scatter
--      radius for jitter around the waypoint center.
--   3. Spawn the boss at dungeon.bossDistance along the same axis.
--
-- All positions are computed RELATIVE TO the player's actual entry
-- position. Y is locked to player Y so spawns are on the same floor
-- the player landed on regardless of zone geometry.
--
-- No mob force-aggros. Every mob gets DETECTION via setMobMod so it
-- aggros normally when the player steps into range. This creates the
-- classic dungeon-crawl feel: walk forward, encounter the first
-- guard pack, fight, continue, encounter the next pack, etc.
local function spawnAllMobs(player, dungeon)
    local sess = sessions[player:getName()]
    if not sess then return end

    -- Anchor everything to the player's actual entry position.
    local px = player:getXPos()
    local py = player:getYPos()
    local pz = player:getZPos()

    local axis = dungeon.progressionAxis or { dx = 0.0, dz = -1.0 }

    -- ============================================================
    -- PROGRESSION GATE RAIL (2026-05-30)
    -- ============================================================
    -- Each waypoint pack and each NM becomes a "gate": the player cannot
    -- advance past its depth until every mob guarding it is dead. Depth is
    -- measured along the entry->boss axis (anchored to the stable warpIn,
    -- NOT the player's wandering position) so kiting a mob sideways or
    -- backward never opens the gate - only killing it does.
    --
    -- gatingOn defaults ON; a dungeon can opt out with `gated = false`.
    --
    -- aggroOn is DECOUPLED from gatingOn: mobs stay aggressive (the
    -- intended "annoyance" that forces you to fight your way through)
    -- even when the gate WALL is off. A dungeon can make mobs passive
    -- with `aggressive = false`. So `gated = false` removes only the
    -- warding-force pushback; mobs still notice and chase you.
    local gatingOn = (dungeon.gated ~= false) and not catalog.disableBoundaries
    local aggroOn  = (dungeon.aggressive ~= false)
    local entryX, entryZ = dungeon.warpIn.x, dungeon.warpIn.z
    local bpx = dungeon.bossPos and dungeon.bossPos.x or (px + axis.dx * (dungeon.bossDistance or 60))
    local bpz = dungeon.bossPos and dungeon.bossPos.z or (pz + axis.dz * (dungeon.bossDistance or 60))
    local adx, adz = bpx - entryX, bpz - entryZ
    local alen = math.sqrt(adx * adx + adz * adz)
    if alen < 0.01 then adx, adz, alen = axis.dx, axis.dz, 1.0 end
    sess.gateAxis  = { dx = adx / alen, dz = adz / alen }
    sess.gateEntry = { x = entryX, z = entryZ }
    sess.gates     = {}
    local function depthOf(x, z)
        return (x - entryX) * sess.gateAxis.dx + (z - entryZ) * sess.gateAxis.dz
    end

    -- Walk waypoints in order - closer-to-entry first.
    for wi, wp in ipairs(dungeon.waypoints or {}) do
        -- Spawn center. Two modes:
        --   (A) Explicit override -- catalog supplies wp.pos = {x,y,z}.
        --       Those EXACT coords are the center. Y is honored, so a
        --       waypoint can sit on a different floor / elevation than
        --       the player. Reliable -- walk to the spot in-game, run
        --       `!pos`, paste the result.
        --   (B) Axis + distance auto-compute (legacy). Y is locked to
        --       player Y, which breaks on multi-elevation maps (mobs
        --       fall through the floor or float above it).
        local cx, cy, cz
        if wp.pos then
            cx, cy, cz = wp.pos.x, wp.pos.y, wp.pos.z
        else
            cx, cy, cz = px + axis.dx * wp.distance, py, pz + axis.dz * wp.distance
        end
        local scatter = wp.scatter or 4.0
        print(string.format(
            "[dungeon] waypoint #%d: %d mobs at (%.2f, %.2f, %.2f) Lv%d  (%s)",
            wi, wp.count, cx, cy, cz, wp.level,
            wp.pos and 'explicit pos' or string.format('depth %d', wp.distance or 0)))

        -- Register this pack as a progression gate (must-kill-to-pass).
        -- alive starts at 0 and is reconciled to the ACTUAL spawn count
        -- after the loop, so a failed spawn can never leave a phantom gate
        -- that blocks the run forever.
        local wpGateId  = nil
        local wpSpawned = 0
        if gatingOn then
            table.insert(sess.gates, {
                depth   = depthOf(cx, cz),
                alive   = 0,
                cleared = false,
                label   = wp.gateLabel or (wp.names and wp.names[1]) or ('Pack #' .. wi),
            })
            wpGateId = #sess.gates
        end

        for i = 1, wp.count do
            -- Random scatter inside a small disc around the waypoint
            -- center so mobs don't perfectly stack. X/Z only -- Y stays
            -- on the waypoint plane so all mobs in a pack share a floor.
            local angle = math.random() * math.pi * 2
            local r     = math.random() * scatter
            local tx    = cx + math.cos(angle) * r
            local tz    = cz + math.sin(angle) * r
            local name  = wp.names[((i - 1) % #wp.names) + 1]
            local trash = spawnDungeonMob(player, dungeon, {
                groupId    = pickFromList(wp.groups),
                level      = wp.level,
                name       = name,
                pos        = { x = tx, y = cy, z = tz, rot = math.random(0, 255) },
                aggressive = aggroOn,
                gateId     = wpGateId,
            })
            if trash then
                table.insert(sess.mobs, trash)
                wpSpawned = wpSpawned + 1
                -- Phase-5 telemetry: total trash count for the "Slayer"
                -- objective (kill every mob the dungeon spawned).
                sess.totalTrashSpawned = (sess.totalTrashSpawned or 0) + 1
            end
        end

        -- Reconcile this gate's alive count to how many mobs ACTUALLY
        -- spawned. If none spawned (bad group id, etc.), open the gate
        -- immediately so a phantom gate can never brick the run.
        if wpGateId and sess.gates[wpGateId] then
            sess.gates[wpGateId].alive = wpSpawned
            if wpSpawned <= 0 then
                sess.gates[wpGateId].cleared = true
            end
        end
    end

    -- ============================================================
    -- NM MINI-BOSSES (pre-final-boss elites)
    -- ============================================================
    -- Each dungeon.nms entry spawns ONE aggressive elite that is its own
    -- gate. Position modes:
    --   (A) nm.pos = { x, y, z }  -- explicit verified coords
    --   (B) nm.frac in [0,1]      -- fraction along the LAST waypoint ->
    --       boss segment (both endpoints are verified walkable, so a
    --       point on that line stays on the final approach corridor).
    -- Tune any NM that lands in geometry by walking to a good spot with
    -- !pos and pasting it as nm.pos.
    if dungeon.nms and #dungeon.nms > 0 then
        local wpts = dungeon.waypoints or {}
        local segAx, segAy, segAz = px, py, pz
        if #wpts > 0 and wpts[#wpts].pos then
            segAx, segAy, segAz = wpts[#wpts].pos.x, wpts[#wpts].pos.y, wpts[#wpts].pos.z
        end
        local segBx = dungeon.bossPos and dungeon.bossPos.x or bpx
        local segBy = dungeon.bossPos and dungeon.bossPos.y or py
        local segBz = dungeon.bossPos and dungeon.bossPos.z or bpz
        for ni, nm in ipairs(dungeon.nms) do
            local f = nm.frac or (ni / (#dungeon.nms + 1))
            local nx, ny, nz
            if nm.pos then
                nx, ny, nz = nm.pos.x, nm.pos.y, nm.pos.z
            else
                nx = segAx + (segBx - segAx) * f
                ny = segAy + (segBy - segAy) * f
                nz = segAz + (segBz - segAz) * f
            end
            print(string.format(
                "[dungeon] NM '%s' (frac %.2f) at (%.2f, %.2f, %.2f) Lv%d",
                nm.name or '?', f, nx, ny, nz, nm.level or 0))

            local nmGateId = nil
            if gatingOn then
                table.insert(sess.gates, {
                    depth   = depthOf(nx, nz),
                    alive   = 1,
                    cleared = false,
                    label   = nm.name or 'Elite guardian',
                })
                nmGateId = #sess.gates
            end

            local nmMob = spawnDungeonMob(player, dungeon, {
                groupId     = nm.group,
                level       = nm.level,
                name        = nm.name,
                pos         = { x = nx, y = ny, z = nz, rot = nm.rot or math.random(0, 255) },
                aggressive  = aggroOn,
                gateId      = nmGateId,
                hpMultExtra = nm.hpMult or 1.5,
                modelSize   = nm.modelSize or 1,
            })
            if nmMob then
                table.insert(sess.mobs, nmMob)
                sess.totalTrashSpawned = (sess.totalTrashSpawned or 0) + 1
            elseif nmGateId and sess.gates[nmGateId] then
                -- NM failed to spawn -- open its gate so it can't brick the run.
                sess.gates[nmGateId].alive   = 0
                sess.gates[nmGateId].cleared = true
            end
        end
    end

    -- Boss spawn point. Same two-mode logic as waypoints:
    --   (A) dungeon.bossPos = { x, y, z, rot? }  -- explicit override
    --   (B) bossDistance along axis (legacy, Y locked to player)
    -- Use (A) on any dungeon where the boss has been spawning off-map
    -- or under the floor -- walk to the desired boss spot in-game,
    -- `!pos`, paste.
    local bx, by, bz, brot
    if dungeon.bossPos then
        bx, by, bz, brot = dungeon.bossPos.x, dungeon.bossPos.y, dungeon.bossPos.z,
                           dungeon.bossPos.rot or 192
    else
        bx, by, bz = px + axis.dx * (dungeon.bossDistance or 60), py,
                     pz + axis.dz * (dungeon.bossDistance or 60)
        brot = 192
    end
    print(string.format(
        "[dungeon] boss at (%.2f, %.2f, %.2f) Lv%d  (%s)",
        bx, by, bz, dungeon.bossLevel,
        dungeon.bossPos and 'explicit pos' or
            string.format('depth %d', dungeon.bossDistance or 60)))

    -- Boss roulette. The catalog can ship EITHER:
    --   bossGroup  / bossName   (singular - old shape, still supported)
    --   bossGroups / bossNames  (plural - new for variety; pick one per run)
    -- When both are present, plural wins. The picked groupId is stashed
    -- on the session so a future "what did I fight?" /stat command can
    -- read it, and so the docs generator can render the full roster.
    local bossGroupId = dungeon.bossGroup
    if dungeon.bossGroups and #dungeon.bossGroups > 0 then
        bossGroupId = pickFromList(dungeon.bossGroups)
    end
    local bossNameForRun = dungeon.bossName
    if dungeon.bossNames and #dungeon.bossNames > 0 then
        bossNameForRun = pickFromList(dungeon.bossNames)
    end
    sess.rolledBossGroup = bossGroupId
    sess.rolledBossName  = bossNameForRun

    -- Defer boss spawn until all trash/NMs are dead.
    sess.bossPending = {
        groupId = bossGroupId,
        name    = bossNameForRun,
        pos     = { x = bx, y = by, z = bz, rot = brot },
    }

    -- Safety: if no trash mobs were configured, spawn boss immediately.
    if #sess.mobs == 0 then
        spawnBoss(player)
    end
end

-----------------------------------
-- Session lifecycle
-----------------------------------

-- Start a dungeon: warp the player, create session, spawn mobs, arm
-- the time-limit timer. Idempotent guard against re-entry while
-- another session is already live.
local function startDungeon(player, dungeon, tierId)
    -- Phase-2: tier defaults to 'normal' so existing callers
    -- (legacy weekly-hunt hooks, abort/restart paths) keep working.
    tierId = tierId or 'normal'

    -- Phase-7: 'keystone' synthesizes a Mythic+<level> tier from the
    -- player's current key for this dungeon. getTier() knows nothing
    -- about it (it's not in catalog.tiers), so resolve it here. The
    -- generic gating below then passes harmlessly (the synthesized
    -- tier has no unlockRequires and weekly=false) - the real gate is
    -- isKeystoneUnlocked.
    local tier
    if tierId == 'keystone' then
        if not keystoneEnabled() then
            player:printToPlayer('[Dungeon Master] Keystones are currently disabled.',
                xi.msg.channel.SYSTEM_3)
            return
        end
        local lock = keystoneLockReason(player, dungeon)
        if lock then
            player:printToPlayer(string.format('[Dungeon Master] Mythic+ is %s', lock),
                xi.msg.channel.SYSTEM_3)
            return
        end
        tier = synthKeystoneTier(getKeyLevel(player, dungeon))
    else
        tier = getTier(tierId)
    end

    -- Entry diagnostic: prints the moment startDungeon is called.
    -- If you see this line in the server log, the code is loaded and
    -- the menu is correctly routing to startDungeon. If you DON'T see
    -- this line after picking a dungeon from the NPC menu, either the
    -- code wasn't reloaded or the menu callback isn't wiring properly.
    print(string.format("[dungeon] >>> startDungeon called: player=%s dungeon=%s tier=%s",
        player:getName(), dungeon.id, tierId))

    -- Tier gating. Belt-and-suspenders - the menu also filters, but
    -- this keeps the path safe against direct Lua calls (e.g. an
    -- admin testing tools that bypass the NPC menu).
    if not isTierUnlocked(player, dungeon, tierId) then
        player:printToPlayer(string.format(
            '[Dungeon Master] %s tier is locked: %s',
            tier.label, tierLockReason(player, dungeon, tierId) or 'requirements not met'),
            xi.msg.channel.SYSTEM_3)
        return
    end
    if tier.weekly and not hasMythicKey(player, dungeon) then
        player:printToPlayer(string.format(
            '[Dungeon Master] Your %s key for %s has already been used this week. Resets Monday 00:00 UTC.',
            tier.label, dungeon.label),
            xi.msg.channel.SYSTEM_3)
        return
    end

    -- Time limit after the tier multiplier (pre-affix). Used both in
    -- the pre-warp banner ("you have N minutes") and as the starting
    -- value seeded onto the session for affix applySession hooks to
    -- further mutate.
    local tierAdjustedTime = math.floor(dungeon.timeLimit * (tier.timeMult or 1.0))

    if getSession(player) then
        player:printToPlayer(
            '[Dungeon Master] You have a dungeon already underway, kupo!',
            xi.msg.channel.SYSTEM_3)
        print("[dungeon] startDungeon aborted: session already exists")
        return
    end

    -- Phase-8 occupancy gate: one group per dungeon zone at a time.
    local occ = dungeonLockHolder(dungeon)
    if occ then
        player:printToPlayer(string.format(
            '[Dungeon Master] %s is currently contested by %s\'s party. Pick another dungeon or wait for their run to end, kupo!',
            dungeon.label, occ.leaderName),
            xi.msg.channel.SYSTEM_3)
        return
    end

    -- SAFETY RAIL #2: refuse warp if module-load validation marked
    -- this dungeon as broken. Belt-and-suspenders - even if the menu
    -- somehow shows a disabled dungeon (catalog hot-edit, etc.) the
    -- start path won't actually warp.
    if dungeon._disabled then
        player:printToPlayer(
            string.format(
                '[Dungeon Master] %s is currently unavailable: %s. Try a different one, kupo!',
                dungeon.label, dungeon._disabled),
            xi.msg.channel.SYSTEM_3)
        return
    end

    -- SAFETY RAIL #5: refuse warp if the player is KO'd.
    --
    -- Discovered the hard way on 2026-05-28: KO'd player picks dungeon
    -- -> warped to dungeon zone with HP=0 -> onPlayerDeath hook fires
    -- the moment the zone-in completes -> endDungeon('death') -> warped
    -- back to GM Home -> player still KO'd -> can do it again forever.
    --
    -- getHP() == 0 covers KO. getStatus() check is belt-and-suspenders
    -- in case the engine has a player in some other non-NORMAL state
    -- (zoning, mounting, etc.) that we shouldn't warp in.
    if player:getHP() <= 0 then
        player:printToPlayer(
            '[Dungeon Master] You must be alive to enter a dungeon. Revive first, kupo!',
            xi.msg.channel.SYSTEM_3)
        return
    end

    -- SAFETY RAIL #6: per-dungeon re-entry cooldown (anti-farm + anti-
    -- spam). Armed when a run ends - 30 min after a clear (stops farming
    -- the same dungeon's rewards), 90 s after any non-clear exit (closes
    -- the "enter -> leave -> enter again -> free reward" loop). It's
    -- PER-DUNGEON, so it never blocks a DIFFERENT dungeon. GMs are exempt
    -- so staff can test without waiting.
    if player:getGMLevel() == 0 then
        local remain = reentryCooldownRemaining(player, dungeon)
        if remain > 0 then
            player:printToPlayer(string.format(
                '[Dungeon Master] You\'ve run %s too recently. Try again in %s, kupo!',
                dungeon.label, fmtCooldown(remain)),
                xi.msg.channel.SYSTEM_3)
            print(string.format(
                "[dungeon] startDungeon blocked: %s on cooldown for %s (%ds left)",
                player:getName(), dungeon.id, remain))
            return
        end
    end

    -- Pre-warp banner. Show the tier label and the effective time
    -- (post tier multiplier, pre affix mutations - affixes have not
    -- been rolled yet at this print).
    player:printToPlayer(
        string.format('[Dungeon Master] Warping you to %s [%s]. You have %d minutes.',
            dungeon.label, tier.label, math.floor(tierAdjustedTime / 60)),
        xi.msg.channel.SYSTEM_3)

    -- Phase-1 per-run state: roll affixes for THIS run, scoped to the
    -- chosen tier (Mythic draws from the Tyrannical pool and gets 2-3
    -- affixes vs 1-2 for Normal/Hard). Stashed on the session so the
    -- spawn path (mob mods), the session arming path (timeLimit), and
    -- the reward path (rewardMult) all read the same set. Roll is
    -- pre-warp so the entry banner can announce the affixes the
    -- moment the player lands.
    -- Phase-7 exception: keystone runs use the DETERMINISTIC weekly
    -- rotation (count grows with key level) instead of the random
    -- roller - the M+ identity is mastering THIS week's combo.
    local rolledAffixes
    if tierId == 'keystone' then
        rolledAffixes = keystoneAffixesFor(tier.keystoneLevel)
    elseif tier.weeklyAffixFixed then
        rolledAffixes = weeklyFixedAffix()
    else
        rolledAffixes = rollAffixes(tier)
    end

    -- Warp first. The session table is set BEFORE the warp because
    -- onZoneIn checks may race; ensureCurrentWeek-style modules want
    -- to see "in dungeon" state immediately.
    -- Phase-6 party detection. Runs BEFORE session creation so the
    -- session table can be initialized with the full member list and
    -- members can be attached to the shadow-ref system in one shot.
    -- Solo runs get an empty members list - same code path, same
    -- session structure, no behavioral change.
    local partyMembers = detectPartyMembers(player)

    sessions[player:getName()] = {
        dungeon   = dungeon,
        tier      = tier,                  -- Phase 2: stash the picked tier
        tierId    = tierId,
        startedAt = os.time(),
        mobs      = {},
        cleared   = false,
        affixes   = rolledAffixes,
        -- Pre-seeded with the tier's time scaling. Affix applySession
        -- hooks (Speedy / Lengthy / Inescapable) may further mutate
        -- this. armDungeonAfterArrival reads it as the authoritative
        -- timeout (no fallback to dungeon.timeLimit at that point).
        timeLimitOverride = tierAdjustedTime,
        -- Bonus-objective telemetry (Phase 5, 2026-05-29). Sampled
        -- by the OOB patrol + mob spawn + onMobDeath hooks; evaluated
        -- in endDungeon('cleared') against catalog.bonusObjectives
        -- to award extra Infamy when the player earned it.
        lowestHpPct       = 100,    -- minimum HP% sample seen
        oobRescues        = 0,      -- count of OOB patrol triggers
        totalTrashSpawned = 0,      -- waypoint mobs spawned (excludes boss)
        trashKilled       = 0,      -- waypoint mobs killed by player
        -- Phase-6 party state. leaderName is the session owner; members
        -- is the list of additional player names that warp in alongside.
        -- spawnDone is flipped by armDungeonAfterArrival after the first
        -- spawn - subsequent arrivals (members) skip the spawn step.
        leaderName        = player:getName(),
        members           = {},
        spawnDone         = false,
    }
    applyAffixesToSession(sessions[player:getName()])
    -- Wire shadow refs for the detected party members so getSession()
    -- works for them too. Has to happen AFTER session creation since
    -- attachMembersToSession needs the session table to point at.
    attachMembersToSession(sessions[player:getName()], partyMembers)

    -- Phase-8: claim the zone for this run. Freed in endDungeon, or by
    -- the stale-lock sweep in dungeonLockHolder if this run orphans.
    zoneOccupancy[dungeon.zoneId] = {
        leaderName = player:getName(),
        startedAt  = os.time(),
    }

    -- Warp the player. The spawn + timeout + countdown warnings are
    -- ALL armed by the dungeon zone's onZoneIn override below - not
    -- here. player:timer uses PAI->QueueAction (lua_baseentity.cpp:12736);
    -- because setPos returns immediately but the zone change takes
    -- ~3 seconds, any timer set here lands on the OLD zone's PAI and
    -- gets garbage-collected when the player actually leaves. The
    -- onZoneIn hook is the engine-guaranteed "player has arrived"
    -- event - only there can timers safely be scheduled.
    -- Dismiss all trusts before warping. Loading 10+ trust entities simultaneously
    -- into the dungeon zone during zone-in corrupts the heap allocator's metadata
    -- (free(): invalid size crash), crashing the server before ARM can even run.
    -- Trusts are dismissed here so the zone-in is clean; players can resummon after
    -- arriving. Pets (wyverns, avatars) are cleared by the engine on zone change.
    pcall(function() player:clearTrusts() end)

    print(string.format("[dungeon] startDungeon: setPos to zone=%d at (%.2f, %.2f, %.2f)",
        dungeon.zoneId, dungeon.warpIn.x, dungeon.warpIn.y, dungeon.warpIn.z))
    player:setPos(dungeon.warpIn.x, dungeon.warpIn.y, dungeon.warpIn.z,
                  dungeon.warpIn.rot, dungeon.zoneId)

    -- Phase-6 party warp. Each member follows the leader to the
    -- dungeon zone. Their onZoneIn override fires armDungeonAfterArrival
    -- on arrival just like the leader's - but the shared session's
    -- spawnDone flag ensures only the FIRST arrival spawns mobs.
    -- Per-player setup (HP/MP restore, grace-unkillable, OOB patrol)
    -- runs for each arrival regardless of who arrived first.
    if #partyMembers > 0 then
        player:printToPlayer(
            string.format('[Dungeon Master] %d party member(s) follow you in.',
                #partyMembers),
            xi.msg.channel.SYSTEM_3)
        for _, mem in ipairs(partyMembers) do
            pcall(function() mem:clearTrusts() end)
            mem:printToPlayer(
                string.format('[Dungeon] Following %s into %s [%s] - %d minutes on the clock.',
                    player:getName(), dungeon.label, tier.label,
                    math.floor(tierAdjustedTime / 60)),
                xi.msg.channel.SYSTEM_3)
            mem:setPos(dungeon.warpIn.x, dungeon.warpIn.y, dungeon.warpIn.z,
                       dungeon.warpIn.rot, dungeon.zoneId)
        end
    end
end


-- Called by each dungeon zone's onZoneIn override the moment a player
-- with an active dungeon session lands in their dungeon zone. By this
-- point the player entity is fully on the destination zone's PAI, so
-- timers set here actually survive and fire.
--
-- Steps:
--   1. Spawn boss + trash (engine-side mob creation)
--   2. Arm the timeout timer for the dungeon's full duration
--   3. Arm the 5m / 1m / 30s / 10s countdown chat warnings
--
-- Module-level so the dungeon-zone overrides at the bottom of this
-- file can call it. m.armDungeonAfterArrival exposes the same.
local function armDungeonAfterArrival(player)
    local sess = getSession(player)
    if not sess then
        print(string.format(
            "[dungeon] armDungeonAfterArrival: %s arrived but no session - likely already aborted",
            player:getName()))
        return
    end
    local dungeon = sess.dungeon

    print(string.format(
        "[dungeon] >>> ARM after arrival: player=%s dungeon=%s zone=%d pos=(%.2f, %.2f, %.2f)",
        player:getName(), dungeon.id, player:getZoneID(),
        player:getXPos() or -1, player:getYPos() or -1, player:getZPos() or -1))

    -- Restore HP / MP / TP on arrival. Dungeons are a paid commitment
    -- (player chose to enter), they should start fresh. Avoids the
    -- "I just barely survived the last fight at 12 HP, now I die to
    -- the first tier of trash because I couldn't /heal first" failure
    -- mode. Also defensively guards against the previous KO-loop bug
    -- where a player who somehow arrived at 0 HP would trigger their
    -- own death hook on entry.
    --
    -- pcall around each call because LSB API names vary slightly
    -- across versions; if one isn't available we still get the others.
    pcall(function() player:setHP(player:getMaxHP()) end)
    pcall(function() player:setMP(player:getMaxMP()) end)
    pcall(function() player:setTP(0) end)
    print(string.format("[dungeon] HP/MP restored: HP=%d/%d MP=%d/%d",
        player:getHP(), player:getMaxHP(),
        player:getMP(), player:getMaxMP()))

    -- ENTRY-GRACE UNKILLABLE (5 SECONDS).
    --
    -- Design history:
    --   v1: 7-second grace, then kill-eligible. Geometry / OOB issues on
    --       launch zones caused immediate deaths inside the grace, so
    --       v2 expanded to whole-run unkillable.
    --   v2: full-duration setUnkillable. SAFE but removed all death
    --       stakes - players just stood in the boss and won by time.
    --       Time limit was the only failure condition.
    --   v3 (current, 2026-05-29 upgrade): 5-second entry grace ONLY,
    --       trusting the OOB patrol + the now-stable zone choices to
    --       prevent geometry deaths. The mob fights are real fights:
    --       lose your HP race, lose the run, lose the Infamy.
    --
    -- The OOB patrol still runs every 500ms and warps the player back
    -- to safe ground if they fall through geometry - that handles the
    -- one remaining "I died for no reason" failure mode. Combined with
    -- the entry-grace setUnkillable on warp-in, the dungeon is now
    -- safe from zone bugs but lethal from bad play.
    pcall(function() player:setUnkillable(true) end)
    player:timer(5000, function(p)
        local s = sessions[p:getName()]
        -- Only release the flag if THIS session is still active.
        -- If they aborted in the first 5 seconds, endDungeon already
        -- released it; this would be a redundant no-op.
        if s and s.dungeon.id == dungeon.id then
            pcall(function() p:setUnkillable(false) end)
            p:printToPlayer(
                '[Dungeon] Combat grace expired. You can now be killed - fight carefully, kupo!',
                xi.msg.channel.SYSTEM_3)
        end
    end)
    player:printToPlayer(
        '[Dungeon] You have 5 seconds to prep. After that, deaths are permanent for this run.',
        xi.msg.channel.SYSTEM_3)

    -- OUT-OF-BOUNDS RESCUE PATROL (defense in depth - still useful
    -- in case the engine's OOB check forces a teleport-to-graveyard
    -- regardless of setUnkillable).
    --
    -- 500ms patrol interval: any fall is caught within half a second.
    -- 3-yalm threshold: a real staircase usually drops 1-2 yalms; a
    -- through-the-floor fall drops 5+. 3 splits the difference.
    local safeY = dungeon.warpIn.y
    local function oobPatrol(p)
        local s = sessions[p:getName()]
        if not s or s.dungeon.id ~= dungeon.id then
            return  -- session ended; stop patrolling
        end
        local py = p:getYPos() or safeY
        if (not catalog.disableBoundaries) and py < safeY - 3 then
            print(string.format(
                "[dungeon] OOB RESCUE: %s fell to Y=%.2f (safe=%.2f); warping to entry",
                p:getName(), py, safeY))
            p:setPos(dungeon.warpIn.x, dungeon.warpIn.y, dungeon.warpIn.z,
                     dungeon.warpIn.rot)
            p:printToPlayer(
                '[Dungeon] You fell off the playable area - warped back to entry, kupo!',
                xi.msg.channel.SYSTEM_3)
            -- Bonus-objective telemetry: each rescue counts against
            -- the "Pathfinder" bonus (zero rescues = +Infamy).
            s.oobRescues = (s.oobRescues or 0) + 1
        end
        -- Cheap HP% sampler (piggy-backs on the patrol that's already
        -- running). The "Untouched" bonus objective rewards keeping
        -- the lowest sampled HP% above its threshold. 500ms cadence
        -- means a single brutal hit could drop you and recover before
        -- we see it - a small grace for the player, not the boss.
        local maxHp = p:getMaxHP() or 1
        local curHp = p:getHP() or 0
        if maxHp > 0 then
            local pct = math.floor((curHp / maxHp) * 100 + 0.5)
            if pct < (s.lowestHpPct or 100) then
                s.lowestHpPct = pct
            end
        end
        -- Re-schedule for the next tick.
        p:timer(500, oobPatrol)
    end
    player:timer(500, oobPatrol)

    -- PROGRESSION GATE PATROL (2026-05-30). Self-rescheduling 500ms tick,
    -- same pattern as oobPatrol. While the lowest-depth uncleared gate
    -- still has living mobs, the player may not travel past its depth +
    -- PASS_MARGIN; overshoot slides them back to the threshold (lateral
    -- position preserved) with a throttled nudge. Armed for EVERY arrival
    -- (leader + members) since each player is gated independently; the
    -- gate 'alive' counts live on the shared session so anyone's kill
    -- opens the gate for the whole party.
    local function gatePatrol(p)
        local s = sessions[p:getName()]
        if not s or s.dungeon.id ~= dungeon.id then
            return  -- session ended; stop patrolling
        end

        -- BOSS-SPAWN SELF-HEAL (2026-06-15). The boss only spawns when the LAST
        -- tracked mob's DEATH registers (#sess.mobs hits 0 in onMobDeath). A mob
        -- that DESPAWNS instead of dying (fell off-mesh, orphaned, cleaned up)
        -- never fires onMobDeath, so it lingers in sess.mobs forever and the run
        -- soft-locks: zone empty, no boss, nothing left to kill. Failsafe: if the
        -- tracker still lists mobs but the dungeon zone is genuinely empty of live
        -- mobs for ~2s, reconcile and spawn the boss. We count the ZONE's live
        -- mobs (valid refs from getMobs) -- NEVER the stale sess.mobs refs, which
        -- may be freed (touching a freed entity ref can segfault; cf. endDungeon's
        -- despawn guard). Gated on `not bossEntity` so it can't double-spawn, and
        -- on `#mobs > 0` so it can't fire during the initial pre-spawn window.
        if not s.bossEntity and #s.mobs > 0 and p:getZoneID() == dungeon.zoneId then
            local live = 0
            for _, mob in pairs(p:getZone():getMobs()) do
                if mob:isSpawned() and mob:getHPP() > 0 then
                    live = live + 1
                end
            end
            if live == 0 then
                s._clearSince = s._clearSince or os.time()
                if os.time() - s._clearSince >= 2 then
                    print(string.format(
                        "[dungeon] SELF-HEAL: %s zone clear with %d stale tracked mob(s) -- spawning boss",
                        p:getName(), #s.mobs))
                    s.mobs        = {}
                    s._clearSince = nil
                    if spawnBoss then spawnBoss(p) end
                end
            else
                s._clearSince = nil
            end
        end

        local gates = s.gates
        if gates and #gates > 0 and s.gateAxis and s.gateEntry then
            -- frontier = lowest-depth gate that still has living mobs
            local frontier = nil
            for _, g in ipairs(gates) do
                if (g.alive or 0) > 0 and (not frontier or g.depth < frontier.depth) then
                    frontier = g
                end
            end
            if frontier then
                -- STUCK-GATE FAILSAFE. Track the frontier gate the player is
                -- being blocked by. If they keep bumping it for STUCK_LIMIT
                -- seconds WITHOUT its alive count dropping (a guardian is
                -- unreachable -- stuck in geometry, off-mesh, etc.), force the
                -- gate open so a bad spawn can never brick a run. ANY real kill
                -- changes frontier.alive and resets the timer, so a legit (if
                -- slow) fight never trips it; only pure can't-touch-it blocking
                -- accrues. Cheap: just two scalars on the session.
                if s._stuckGate ~= frontier or (s._stuckAlive or -1) ~= (frontier.alive or 0) then
                    s._stuckGate  = frontier
                    s._stuckAlive = frontier.alive or 0
                    s._stuckSince = nil
                end

                local relx = (p:getXPos() or s.gateEntry.x) - s.gateEntry.x
                local relz = (p:getZPos() or s.gateEntry.z) - s.gateEntry.z
                local along = relx * s.gateAxis.dx + relz * s.gateAxis.dz
                local PASS_MARGIN = 8.0
                if along > frontier.depth + PASS_MARGIN then
                    local now = os.time()
                    s._stuckSince = s._stuckSince or now
                    local STUCK_LIMIT = 75  -- seconds of pure blocked-no-kill
                    if now - s._stuckSince >= STUCK_LIMIT then
                        -- Unreachable guardian: open the gate rather than trap
                        -- the player behind a mob they physically cannot touch.
                        frontier.alive   = 0
                        frontier.cleared = true
                        s._stuckGate  = nil
                        s._stuckSince = nil
                        print(string.format(
                            "[dungeon] STUCK-GATE FAILSAFE: %s blocked %ds at gate '%s' (depth %.1f) with no kill -- force-opening",
                            p:getName(), STUCK_LIMIT, frontier.label or '?', frontier.depth))
                        p:printToPlayer(
                            string.format('[Dungeon] The ward over %s flickers and dies - the way opens, kupo!',
                                frontier.label or 'the guardians'),
                            xi.msg.channel.SYSTEM_3)
                    else
                        -- Clamp along-axis depth back to the threshold; keep
                        -- the player's perpendicular (lateral) offset so they
                        -- aren't yanked sideways - just stopped going forward.
                        local newAlong = frontier.depth + (PASS_MARGIN * 0.5)
                        local perpx = relx - along * s.gateAxis.dx
                        local perpz = relz - along * s.gateAxis.dz
                        local nx = s.gateEntry.x + s.gateAxis.dx * newAlong + perpx
                        local nz = s.gateEntry.z + s.gateAxis.dz * newAlong + perpz
                        local rot = 0
                        pcall(function() rot = p:getRotation() end)
                        p:setPos(nx, p:getYPos(), nz, rot)
                        if not s.lastGateMsg or (now - s.lastGateMsg) >= 3 then
                            s.lastGateMsg = now
                            p:printToPlayer(
                                string.format('[Dungeon] A warding force bars the way - slay %s to press deeper, kupo!',
                                    frontier.label or 'the guardians'),
                                xi.msg.channel.SYSTEM_3)
                        end
                    end
                end
            end
        end
        p:timer(500, gatePatrol)
    end
    player:timer(500, gatePatrol)

    -- Phase-6 party-aware spawn gate. Only the FIRST arrival (always
    -- the leader in the current warp ordering) triggers mob spawn.
    -- Subsequent arrivals (party members) skip the spawn block but
    -- still got the per-player setup above (HP/MP, grace, OOB patrol).
    -- spawnDone is set on the shared session table - the second arrival
    -- reads true and short-circuits.
    if sess.spawnDone then
        -- Member arrival path: tell them they're caught up.
        player:printToPlayer(
            string.format('[Dungeon] You\'ve joined %s\'s run in progress.',
                sess.leaderName or '?'),
            xi.msg.channel.SYSTEM_3)
        return
    end
    sess.spawnDone = true

    -- Flush any leftover mobs from a prior zone-exit abort on this zone.
    -- Those refs were parked in pendingCleanup to avoid the sleeping-zone
    -- destructor crash. Now a player IS present, so setHP(0) is safe.
    local leftovers = pendingCleanup[dungeon.zoneId]
    if leftovers then
        for _, mob in ipairs(leftovers) do
            pcall(function() mob:setHP(0) end)
        end
        pendingCleanup[dungeon.zoneId] = nil
    end

    -- Spawn (xpcall'd so any individual mob failure gets a real
    -- traceback instead of silently aborting the whole batch).
    local ok, err = xpcall(
        function() spawnAllMobs(player, dungeon) end,
        function(e) return debug.traceback(tostring(e), 2) end
    )
    if not ok then
        print(string.format("[dungeon] ERROR in spawnAllMobs: %s", tostring(err)))
        player:printToPlayer(
            '[Dungeon] Spawn failed - see server log. Use !dungeon home to return.',
            xi.msg.channel.SYSTEM_3)
        return
    end

    player:printToPlayer(
        string.format('[Dungeon] %s - clear the boss within the time limit, kupo!',
            dungeon.label),
        xi.msg.channel.SYSTEM_3)
    local gatesOn = (dungeon.gated ~= false) and not catalog.disableBoundaries
    local aggroOn = (dungeon.aggressive ~= false)
    if gatesOn then
        player:printToPlayer(
            '[Dungeon] Hostile guardians hold each threshold ahead - they aggro on sight and CANNOT be bypassed. Cut a path through them, defeat the elite NMs, then face the final boss, kupo!',
            xi.msg.channel.SYSTEM_3)
    elseif aggroOn then
        player:printToPlayer(
            '[Dungeon] No barriers bar your path - move freely. Mobs aggro on sight, so fight through or rush past them straight to the boss, kupo!',
            xi.msg.channel.SYSTEM_3)
    else
        player:printToPlayer(
            '[Dungeon] All mobs are passive. Buff up, summon Trusts, position, then attack to engage each one at your pace.',
            xi.msg.channel.SYSTEM_3)
    end

    -- Phase-1 affix banner. Print the affix labels + descriptions so
    -- the player can plan around them (Voracious -> bring sustain DPS,
    -- Speedy -> skip the buff phase, etc.). Quiet mode (catalog flag)
    -- suppresses the banner for players who want a clean entry.
    if not catalog.affixesQuiet and sess.affixes and #sess.affixes > 0 then
        local labels = {}
        for _, a in ipairs(sess.affixes) do
            table.insert(labels, a.label)
        end
        player:printToPlayer(
            string.format('[Dungeon] >> Affixes this run: %s <<',
                table.concat(labels, ' + ')),
            xi.msg.channel.SYSTEM_3)
        for _, a in ipairs(sess.affixes) do
            local tag = (a.kind == 'positive') and '+'
                     or (a.kind == 'negative') and '-' or '*'
            player:printToPlayer(
                string.format('  [%s] %s: %s', tag, a.label, a.description),
                xi.msg.channel.SYSTEM_3)
        end
        local mult = affixRewardMult(sess.affixes)
        if mult ~= 1.0 then
            player:printToPlayer(
                string.format('  Reward multiplier from affixes: %.2fx', mult),
                xi.msg.channel.SYSTEM_3)
        end
    end

    -- Effective time-limit honours the affix override (Speedy / Lengthy).
    -- Stash on the session so the reward path's speed-bonus check uses
    -- the same value (otherwise Lengthy would let you trivially earn
    -- the speed bonus and Speedy could lock you out of it).
    local effectiveLimit = sess.timeLimitOverride or dungeon.timeLimit

    -- Timeout timer. Now safely on the dungeon-zone PAI, so it
    -- survives until either the player kills the boss or runs out
    -- of time / aborts / dies.
    sess.timer = player:timer(effectiveLimit * 1000, function(p)
        local s = sessions[p:getName()]
        if not s then return end
        if s.dungeon.id ~= dungeon.id or s.startedAt ~= sess.startedAt then return end
        m.endDungeon(p, 'timeout')
    end)

    -- Countdown chat warnings at 5m / 1m / 30s / 10s remaining.
    -- Each is its own timer scheduled relative to NOW, with session
    -- + dungeon-id + startedAt validation so cancelled runs don't
    -- emit ghost warnings.
    local sessionId = sess.startedAt
    local function scheduleWarning(remainingSecs, label)
        local delay = (effectiveLimit - remainingSecs) * 1000
        if delay <= 0 then return end
        player:timer(delay, function(p)
            local s = sessions[p:getName()]
            if not s then return end
            if s.dungeon.id ~= dungeon.id or s.startedAt ~= sessionId then return end
            if s.cleared then return end
            p:printToPlayer(
                string.format('[Dungeon] %s remaining!', label),
                xi.msg.channel.SYSTEM_3)
        end)
    end
    scheduleWarning(300, '5 minutes')
    scheduleWarning(60,  '1 minute')
    scheduleWarning(30,  '30 seconds')
    scheduleWarning(10,  '10 seconds')

    -- PHASE 3 - enrageAfter timer. A time-based phase trigger that
    -- fires once `enrageAfter.sec` seconds into the fight (separate
    -- from the dungeon's overall timeLimit). Same session-id guard
    -- as the countdown warnings so a re-run on the same dungeon
    -- doesn't fire a ghost enrage from a prior abort. Cancelled on
    -- early-end paths via the session reset.
    if dungeon.enrageAfter and dungeon.enrageAfter.sec then
        local enrage = dungeon.enrageAfter
        player:timer(enrage.sec * 1000, function(p)
            local s = sessions[p:getName()]
            if not s then return end
            if s.dungeon.id ~= dungeon.id or s.startedAt ~= sessionId then return end
            if s.cleared then return end
            local boss = s.bossEntity
            if not boss then return end
            fireBossAction(boss, s, p, enrage)
        end)
    end
end


-- Centralized end-of-session: despawns mobs, awards infamy (only on
-- 'cleared'), prints chat, warps the player out, clears the session.
--
-- reason:
--   'cleared'  boss kill within time limit  -> infamy + speed bonus check
--   'timeout'  time limit expired           -> no reward
--   'death'    player died                  -> no reward
--   'manual'   !dungeon abort               -> no reward
function m.endDungeon(player, reason)
    local sess = getSession(player)
    if not sess then return end
    local dungeon = sess.dungeon

    -- Despawn every live mob. setHP(0) is the canonical "kill it silently"
    -- idiom. BUT: if the player has already left the dungeon zone (zone-exit
    -- abort), the zone is empty/sleeping. Calling setHP(0) on mobs in that
    -- state triggers the LSB destructor-order crash (same crash that hit
    -- Brogurt 2026-06-14 22:47 and again 2026-06-15 04:15). Instead, defer
    -- the despawn to pendingCleanup -- flushed at the start of the next run
    -- for this zone when a player IS present.
    if player:getZoneID() ~= dungeon.zoneId then
        -- Player already outside the dungeon zone. Park refs for later flush.
        local bucket = pendingCleanup[dungeon.zoneId] or {}
        for _, mob in ipairs(sess.mobs) do
            if mob then
                table.insert(bucket, mob)
            end
        end
        pendingCleanup[dungeon.zoneId] = bucket
    else
        -- Player still inside the dungeon zone: safe to kill now.
        for _, mob in ipairs(sess.mobs) do
            if mob then
                pcall(function() mob:setHP(0) end)
            end
        end
    end

    if reason == 'cleared' then
        local elapsed = os.time() - sess.startedAt
        -- Use the effective (affix-adjusted) time limit so the
        -- speed-bonus threshold scales with Speedy / Lengthy. A
        -- Speedy run gets a tighter half-time bar; Lengthy gets a
        -- more generous one.
        local effectiveLimit = sess.timeLimitOverride or dungeon.timeLimit
        local halfTime = effectiveLimit / 2
        local infamy = dungeon.infamyBase
        local bonusApplied = false
        if elapsed <= halfTime and dungeon.infamySpeedBonus then
            infamy = infamy + dungeon.infamySpeedBonus
            bonusApplied = true
        end
        -- Phase-2 tier payout: tier multiplier wraps around the
        -- (base + speed-bonus) total before affixes are applied. So
        -- Mythic (5.0x) + Speed bonus + Tyrannical (1.40x) compounds.
        local tier      = sess.tier or IDENTITY_TIER
        local tierMult  = tier.infamyMult or 1.0
        if tierMult ~= 1.0 then
            infamy = math.max(1, math.floor(infamy * tierMult + 0.5))
        end

        -- Phase-1 affix payout: multiply the (base + speed-bonus + tier)
        -- total by the product of every rolled affix's rewardMult, then
        -- floor. Negative affixes pay more, positive affixes pay less,
        -- Bountiful pays a lot more, etc. Multiplier of exactly 1.0
        -- short-circuits.
        local affixMult = affixRewardMult(sess.affixes)
        if affixMult ~= 1.0 then
            infamy = math.max(1, math.floor(infamy * affixMult + 0.5))
        end

        -- Phase-4 daily featured bonus. Applies a flat +featuredBonus
        -- (default +50%) on top of everything else. Resets at 00:00
        -- UTC; deterministic per-day rotation across dungeons.
        local featuredMult = 1.0
        if isFeatured(dungeon) and catalog.featuredBonus then
            featuredMult = 1.0 + catalog.featuredBonus
            infamy = math.max(1, math.floor(infamy * featuredMult + 0.5))
        end

        -- Phase-4 streak bonus. BUMP first so the bonus on THIS clear
        -- reflects the new streak count (i.e. clearing your first
        -- dungeon counts as streak 1 and pays the +10% bonus on the
        -- same clear). Then multiply by streakMult.
        local newStreak = bumpStreak(player)
        local sMult     = streakMult(player)
        if sMult ~= 1.0 then
            infamy = math.max(1, math.floor(infamy * sMult + 0.5))
        end

        -- Phase-5 bonus objectives. Walk catalog.bonusObjectives,
        -- run each `check(sess)`, sum the bonusMult of those that
        -- pass. Apply a single multiplicative bump at the end so
        -- earning multiple bonuses stacks cleanly. The list of
        -- earned bonuses gets stashed on sess so the clear banner
        -- (below) can announce each one with its descriptive reason.
        --
        -- Why ADD the mults and apply once, instead of multiplying
        -- each in sequence: keeps the math interpretable. Earning
        -- Untouched (+0.75), Pathfinder (+0.10), and Lightning
        -- (+0.30) means the player sees "objective bonuses: +115%"
        -- and infamy goes up by 2.15x - not the cascading 2.50x
        -- you'd get from sequential mults. Sums are easier to
        -- reason about, easier to balance.
        local earnedBonuses = {}
        local objectivesMult = 0
        for _, obj in ipairs(catalog.bonusObjectives or {}) do
            local ok, passed = pcall(obj.check, sess)
            if ok and passed then
                table.insert(earnedBonuses, obj)
                objectivesMult = objectivesMult + (obj.bonusMult or 0)
            end
        end
        if objectivesMult > 0 then
            infamy = math.max(1, math.floor(infamy * (1 + objectivesMult) + 0.5))
        end
        -- Stash for the banner-printing block below. Empty table is
        -- fine (just won't print any bonus lines).
        sess.earnedBonuses = earnedBonuses

        -- Weekly Bonus Dungeon: award 2x Infamy once per week for the
        -- featured dungeon. The bonus is gated per player via a CharVar
        -- so subsequent clears in the same week earn normal Infamy.
        local weekIdx = math.floor(os.time() / 604800)
        local weeklyBonusApplied = false
        local weeklyBonusAmt     = 0
        if isWeeklyBonus(dungeon) and not hasEarnedWeeklyBonus(player, weekIdx, dungeon.id) then
            weeklyBonusAmt     = infamy   -- bonus = one full extra copy of the computed infamy
            infamy             = infamy * 2
            weeklyBonusApplied = true
            markWeeklyBonusEarned(player, weekIdx, dungeon.id)
        end

        -- Nightmare tier skips Infamy entirely (infamyMult = 0) and grants
        -- Shadow Fragments instead. All other tiers award Infamy as normal.
        if (tier.infamyMult or 1) > 0 then
            addInfamy(player, infamy)
        end

        -- Nightmare Shadow Fragment payout.
        local fragReward = (tierId == 'nightmare') and (tier.shadowFrags or 1) or 0
        if fragReward > 0 then
            local fragsBefore = player:getCharVar('PW_Trial1_Frags') or 0
            local fragsNow    = fragsBefore + fragReward
            player:setCharVar('PW_Trial1_Frags', fragsNow)
            sess.fragsEarned = fragReward
            sess.fragsTotal  = fragsNow
            if fragsNow >= 10 and (player:getCharVar('PW_Trial1_Done') or 0) == 0 then
                player:setCharVar('PW_Trial1_Done', 1)
                player:printToPlayer(
                    '[Nightmare] Trial 1 complete! You have collected 10 Shadow Fragments. Visit the Prime Armory.',
                    xi.msg.channel.SYSTEM_3)
            end
        end

        -- Phase-6: stash the final Infamy value on the session so the
        -- party-reward distribution block below (which runs outside
        -- this `if reason == 'cleared' then` scope) can compute the
        -- member discounted payout from it. Without this, `infamy`
        -- would fall out of scope and member rewards would be zero.
        sess.finalInfamy = (tier.infamyMult or 1) > 0 and infamy or 0

        -- Phase-2 per-tier clear counter. Drives the unlock gating for
        -- Hard / Mythic (Hard needs 1 Normal clear, Mythic needs 5 Hard
        -- clears). Separate from Dungeon_Clears_<id> which counts ALL
        -- tiers together (kept for back-compat with weekly_hunts).
        local tierId = sess.tierId or 'normal'
        local tierCv = tierClearsCv(dungeon, tierId)
        player:setCharVar(tierCv, (player:getCharVar(tierCv) or 0) + 1)

        -- Phase-2 Mythic weekly key burn. Only fires when the rolled
        -- tier opted in via catalog.tiers[tier].weekly. The check
        -- against hasMythicKey already happened at startDungeon, so
        -- by this point the player has earned the right to burn it.
        if tier.weekly then
            burnMythicKey(player, dungeon)
        end

        -- Per-dungeon statistics tracking. CharVars:
        --   Dungeon_Clears_<id>     count of clears (already used elsewhere)
        --   Dungeon_TotalTime_<id>  cumulative seconds across all clears (NEW)
        --   Dungeon_BestTime_<id>   fastest clear time, in seconds (NEW)
        -- All three updated at the bottom of this 'cleared' block.
        --
        -- Backward compat: players with prior clears but no total/best
        -- tracking show isNewBest=true on their next clear (since
        -- oldBestTime defaults to 0). Avg time will be slightly off
        -- for the first run after this update; normalizes after a few
        -- more clears.
        local clearCv     = 'Dungeon_Clears_'    .. dungeon.id
        local totalTimeCv = 'Dungeon_TotalTime_' .. dungeon.id
        local bestTimeCv  = 'Dungeon_BestTime_'  .. dungeon.id
        local oldClears    = player:getCharVar(clearCv)     or 0
        local oldTotalTime = player:getCharVar(totalTimeCv) or 0
        local oldBestTime  = player:getCharVar(bestTimeCv)  or 0
        local newClears    = oldClears + 1
        local newTotalTime = oldTotalTime + elapsed
        local isNewBest    = (oldBestTime == 0) or (elapsed < oldBestTime)
        local newBestTime  = isNewBest and elapsed or oldBestTime
        local avgTime      = math.floor(newTotalTime / newClears)

        -- Local time-formatter - turns seconds into "Xm Ys" once over
        -- the minute mark, else just "Xs". Used 3+ times below.
        local function fmtTime(s)
            if s >= 60 then
                local mins = math.floor(s / 60)
                return string.format('%dm %ds', mins, s - mins * 60)
            end
            return string.format('%ds', s)
        end

        local currentBalance  = getInfamy(player)
        local lifetimeBalance = player:getCharVar('Infamy_Lifetime') or 0

        player:printToPlayer(
            '====================================================',
            xi.msg.channel.SYSTEM_3)
        player:printToPlayer(
            string.format('  ** DUNGEON CLEARED: %s **', dungeon.label),
            xi.msg.channel.SYSTEM_3)
        player:printToPlayer(
            string.format('  Cleared in %s', fmtTime(elapsed)),
            xi.msg.channel.SYSTEM_3)
        -- Single Infamy line, then a per-multiplier breakdown so the
        -- math is fully auditable. base -> speed bonus (if any) -> tier
        -- mult -> affix mult -> featured mult -> streak mult -> final.
        if tierId == 'nightmare' then
            -- Nightmare: show Shadow Fragment reward instead of Infamy.
            player:printToPlayer(
                string.format('  +%d Shadow Fragment [%s] (%d/10 total)',
                    sess.fragsEarned or 1, tier.label, sess.fragsTotal or 1),
                xi.msg.channel.SYSTEM_3)
            player:printToPlayer(
                '  Shadow Fragments: 10 required to complete Prime Weapon Trial 1.',
                xi.msg.channel.SYSTEM_3)
        else
            player:printToPlayer(
                string.format('  +%d Infamy earned [%s]', infamy, tier.label),
                xi.msg.channel.SYSTEM_3)
            player:printToPlayer(
                string.format('    base %d%s   tier x%.2f   affixes x%.2f',
                    dungeon.infamyBase,
                    bonusApplied and string.format(' + SPEED %d', dungeon.infamySpeedBonus) or '',
                    tierMult, affixMult),
                xi.msg.channel.SYSTEM_3)
        end
        if featuredMult ~= 1.0 then
            player:printToPlayer(
                string.format('    ** FEATURED dungeon today ** x%.2f bonus', featuredMult),
                xi.msg.channel.SYSTEM_3)
        end
        if weeklyBonusApplied then
            player:printToPlayer(
                string.format('[Dungeon] \xe2\x98\x85 BONUS DUNGEON: +%d extra Infamy! (%s is this week\'s featured dungeon.)',
                    weeklyBonusAmt, dungeon.label),
                xi.msg.channel.SYSTEM_3)
        end
        if sMult ~= 1.0 then
            player:printToPlayer(
                string.format('    streak %d/%d   x%.2f bonus',
                    newStreak, catalog.streakCap or 5, sMult),
                xi.msg.channel.SYSTEM_3)
        elseif newStreak == 0 then
            player:printToPlayer('    streak: building...', xi.msg.channel.SYSTEM_3)
        end

        -- Per-affix line: shows exactly which affixes contributed and
        -- by how much. Skipped when no affixes rolled (legacy run).
        if sess.affixes and #sess.affixes > 0 then
            for _, a in ipairs(sess.affixes) do
                player:printToPlayer(
                    string.format('    affix [%s] x%.2f', a.label, a.rewardMult or 1.0),
                    xi.msg.channel.SYSTEM_3)
            end
        end

        -- Phase-5 bonus objective lines. One per earned objective so
        -- the player sees exactly which skill bonuses they got, plus
        -- a summary line with the total objective uplift. Skipped
        -- entirely when no objectives earned (the average run).
        if sess.earnedBonuses and #sess.earnedBonuses > 0 then
            for _, obj in ipairs(sess.earnedBonuses) do
                player:printToPlayer(
                    string.format('    ** %s ** (%s)   +%d%%',
                        obj.label, obj.reason,
                        math.floor((obj.bonusMult or 0) * 100 + 0.5)),
                    xi.msg.channel.SYSTEM_3)
            end
            player:printToPlayer(
                string.format('    objective bonuses total: +%d%% (x%.2f)',
                    math.floor(objectivesMult * 100 + 0.5),
                    1 + objectivesMult),
                xi.msg.channel.SYSTEM_3)
        end

        -- Phase-2 unlock progress nudge. If this clear unlocks the
        -- next tier (or pushes the player closer), tell them - gives
        -- a sense of progression beyond raw Infamy.
        local function unlockNote(targetTierId)
            local target = catalog.tiers and catalog.tiers[targetTierId]
            if not target or not target.unlockRequires then return nil end
            local req = target.unlockRequires
            local have = getTierClears(player, dungeon, req.tier)
            if have == req.clears then
                return string.format('** %s tier UNLOCKED **', target.label)
            elseif have < req.clears then
                return string.format('  Progress to %s: %d/%d %s clears',
                    target.label, have, req.clears,
                    (catalog.tiers[req.tier] and catalog.tiers[req.tier].label) or req.tier)
            end
            return nil
        end
        if catalog.tierOrder then
            for _, tId in ipairs(catalog.tierOrder) do
                local note = unlockNote(tId)
                if note then
                    player:printToPlayer(note, xi.msg.channel.SYSTEM_3)
                end
            end
        end
        player:printToPlayer(
            string.format('  Current Infamy balance: %d  |  Lifetime earned: %d',
                currentBalance, lifetimeBalance + infamy),  -- +infamy because we bump lifetime below
            xi.msg.channel.SYSTEM_3)

        -- Per-dungeon stats line. Three formats depending on context:
        --   * First clear ever - celebrate the "first" status
        --   * New best time (with prior clears) - highlight the record
        --   * Normal clear - just show the running stats
        if oldClears == 0 then
            player:printToPlayer(
                string.format('  First clear of this dungeon!  Your time to beat: %s',
                    fmtTime(elapsed)),
                xi.msg.channel.SYSTEM_3)
        elseif isNewBest then
            player:printToPlayer(
                string.format('  Clears: %d  |  Avg: %s  |  *** NEW BEST: %s (was %s) ***',
                    newClears, fmtTime(avgTime), fmtTime(newBestTime), fmtTime(oldBestTime)),
                xi.msg.channel.SYSTEM_3)
        else
            player:printToPlayer(
                string.format('  Clears: %d  |  Avg: %s  |  Best: %s',
                    newClears, fmtTime(avgTime), fmtTime(newBestTime)),
                xi.msg.channel.SYSTEM_3)
        end

        player:printToPlayer(
            '====================================================',
            xi.msg.channel.SYSTEM_3)

        -- Persist the new stats so next clear can reference them.
        -- Dungeon_Clears_<id> is also bumped further down (in the
        -- existing block) for the leaderboard side - that bump is
        -- redundant with this one, but both call setCharVar with
        -- the same end value so it's idempotent.
        player:setCharVar(totalTimeCv, newTotalTime)
        player:setCharVar(bestTimeCv,  newBestTime)

        -- Notify the Weekly Hunt Board so "Dungeon Diver"-style
        -- objectives (if added) can credit. dungeon.id is stable.
        whFire(player, 'dungeon_clear', { dungeonId = dungeon.id, elapsed = elapsed })

        -- Bump a per-dungeon clear counter (drives the per-dungeon
        -- leaderboards) plus a global total-clears counter (drives
        -- the "Most Dungeon Clears" board without needing a sum-of-
        -- pattern SQL query in the docgen).
        local clearCv = 'Dungeon_Clears_' .. dungeon.id
        player:setCharVar(clearCv, (player:getCharVar(clearCv) or 0) + 1)
        player:setCharVar('Dungeon_Clears_Total',
            (player:getCharVar('Dungeon_Clears_Total') or 0) + 1)

        -- Also bump the global Infamy-earned counter (separate from
        -- the spendable balance) for a "Most Infamy Earned (Lifetime)"
        -- leaderboard analogous to HL_Points_Lifetime.
        player:setCharVar('Infamy_Lifetime',
            (player:getCharVar('Infamy_Lifetime') or 0) + infamy)

        -- Personal achievement milestones for lifetime Infamy earned.
        -- Called after Infamy_Lifetime is updated so the thresholds see
        -- the current total (500 / 1,000 / 5,000 Infamy).
        ach.onDungeonClear(player)
        ach.onDungeonCount(player)

        -- Phase-7 keystone result: upgrade the key by clear speed,
        -- record bests, pay the one-time personal-best bonus. Only
        -- runs for keystone-tier sessions.
        if sess.tierId == 'keystone' and catalog.keystone
           and sess.tier and sess.tier.keystoneLevel then
            local ks       = catalog.keystone
            local level    = sess.tier.keystoneLevel
            local delta    = keystoneUpgradeDelta(elapsed, effectiveLimit)
            local newLevel = level + delta
            setKeyLevel(player, dungeon, newLevel)

            local clockLeftPct = math.max(0,
                math.floor((1 - elapsed / math.max(effectiveLimit, 1)) * 100))
            player:printToPlayer(string.format(
                '  Keystone upgraded: M+%d -> M+%d  (+%d, %d%% of the clock left)',
                level, newLevel, delta, clockLeftPct),
                xi.msg.channel.SYSTEM_3)

            local oldBest = getKeyBest(player, dungeon)
            if level > oldBest then
                player:setCharVar(keyBestCv(dungeon), level)
                local globalBest = player:getCharVar(ks.keyBestCvGlobal) or 0
                if level > globalBest then
                    player:setCharVar(ks.keyBestCvGlobal, level)
                end
                local pbBonus = math.max(1,
                    math.floor(dungeon.infamyBase * (ks.pbBonusMult or 0)))
                addInfamy(player, pbBonus)
                player:setCharVar('Infamy_Lifetime',
                    (player:getCharVar('Infamy_Lifetime') or 0) + pbBonus)
                player:printToPlayer(string.format(
                    '  *** KEYSTONE BEST: %s M+%d! One-time bonus: +%d Infamy ***',
                    dungeon.label, level, pbBonus),
                    xi.msg.channel.SYSTEM_3)
                -- Guarded: ships in the same change as the hook, but a
                -- partial deploy must not crash the reward path.
                if ach.onKeystoneBest then
                    pcall(ach.onKeystoneBest, player, level)
                end
            end
            whFire(player, 'keystone_clear',
                { dungeonId = dungeon.id, level = level, elapsed = elapsed })
        end
    else
        local reasonText = (reason == 'timeout' and 'Time limit expired')
                        or (reason == 'death'   and 'You fell in combat')
                        or (reason == 'manual'  and 'Aborted')
                        or 'Aborted'
        player:printToPlayer(
            string.format('[Dungeon] %s. No Infamy awarded.', reasonText),
            xi.msg.channel.SYSTEM_3)

        -- Phase-4 streak reset on ANY non-clear exit. If the player
        -- had a streak going, surface the loss so they understand the
        -- cost of aborting / dying / running out the clock.
        local priorStreak = getStreak(player)
        if priorStreak > 0 then
            resetStreak(player)
            player:printToPlayer(
                string.format('[Dungeon] Your %d-clear streak has been broken.', priorStreak),
                xi.msg.channel.SYSTEM_3)
        end

        -- Phase-7 keystone depletion on ANY non-clear exit (death /
        -- timeout / abort / leave). The floor is minLevel, so a fresh
        -- key can't go negative.
        if sess.tierId == 'keystone' and catalog.keystone
           and sess.tier and sess.tier.keystoneLevel then
            local level    = sess.tier.keystoneLevel
            local minLevel = catalog.keystone.minLevel or 1
            local newLevel = math.max(minLevel,
                level - (catalog.keystone.depleteOnFail or 1))
            setKeyLevel(player, dungeon, newLevel)
            if newLevel < level then
                player:printToPlayer(string.format(
                    '[Dungeon] Keystone depleted: M+%d -> M+%d.', level, newLevel),
                    xi.msg.channel.SYSTEM_3)
            else
                player:printToPlayer(string.format(
                    '[Dungeon] Keystone holds at M+%d (the floor).', level),
                    xi.msg.channel.SYSTEM_3)
            end
        end
    end

    -- Arm the leader's per-dungeon re-entry cooldown. ONE call covers
    -- every exit reason: 'cleared' -> 30-min farm gate, anything else ->
    -- 90-s anti-spam gate (see armReentryCooldown / catalog cooldown
    -- config). Stamped here, before the warp-out, so it's set the instant
    -- the run resolves - a DC during the linger can't dodge it.
    armReentryCooldown(player, dungeon, reason)

    -- Warp-out delay. On a CLEAR we linger ~12s so the party can savor
    -- the victory + read the reward banner before being yanked out; on
    -- any non-clear exit (death / timeout / abort) we keep the quick 4s
    -- so a failed run doesn't make anyone sit around. Leader + members
    -- share this value so the whole party warps out together.
    local warpDelayMs  = (reason == 'cleared') and 12000 or 4000
    local warpDelaySec = math.floor(warpDelayMs / 1000)

    -- Phase-6 party reward distribution + cleanup. Walks any remaining
    -- members (those still alive in the dungeon zone) and:
    --   1. On 'cleared' only: awards them memberRewardFactor of the
    --      leader's Infamy + bumps their per-dungeon clear/time CharVars
    --      so they get individual leaderboard credit for the run.
    --   2. Always: prints a short banner so they know the run ended.
    --   3. Always: schedules a warp-out (warpDelayMs; matches leader's).
    --   4. Always: clears their shadow session ref.
    -- This block runs regardless of reason ('cleared' / 'timeout' /
    -- 'death' / 'manual') so members always exit cleanly.
    local memberFactor = (catalog.party and catalog.party.memberRewardFactor) or 0.5
    local memberInfamy = (reason == 'cleared')
        and math.max(1, math.floor((sess.finalInfamy or 0) * memberFactor + 0.5))
        or 0
    if sess.members then
        for _, mname in ipairs(sess.members) do
            local mem = liveMemberInZone(mname, dungeon.zoneId)
            if mem then
                if reason == 'cleared' then
                    -- Award discounted Infamy.
                    mem:setCharVar(catalog.currencyCv,
                        (mem:getCharVar(catalog.currencyCv) or 0) + memberInfamy)
                    -- Per-dungeon clear counter + lifetime trackers so the
                    -- member shows up on leaderboards individually.
                    mem:setCharVar('Dungeon_Clears_' .. dungeon.id,
                        (mem:getCharVar('Dungeon_Clears_' .. dungeon.id) or 0) + 1)
                    mem:setCharVar('Dungeon_Clears_Total',
                        (mem:getCharVar('Dungeon_Clears_Total') or 0) + 1)
                    mem:setCharVar('Infamy_Lifetime',
                        (mem:getCharVar('Infamy_Lifetime') or 0) + memberInfamy)
                    mem:printToPlayer(
                        string.format('[Dungeon] Party reward: +%d Infamy (%.0f%% of leader\'s payout)',
                            memberInfamy, memberFactor * 100),
                        xi.msg.channel.SYSTEM_3)
                else
                    mem:printToPlayer(
                        string.format('[Dungeon] Run ended (%s). No reward.', tostring(reason or '?')),
                        xi.msg.channel.SYSTEM_3)
                end
                -- Members earn the SAME per-dungeon cooldown as the leader
                -- (clear -> 30 min, else -> 90 s), so a carried member can't
                -- immediately re-run the dungeon to farm it either.
                armReentryCooldown(mem, dungeon, reason)
                -- Schedule per-member warp-out (matches leader timing).
                pcall(function() mem:setUnkillable(false) end)
                mem:printToPlayer(
                    string.format('[Dungeon] Warping back to GM Home in %d seconds...', warpDelaySec),
                    xi.msg.channel.SYSTEM_3)
                local exit = catalog.exitWarp
                mem:timer(warpDelayMs, function(p)
                    p:setPos(exit.x, exit.y, exit.z, exit.rotation, exit.zoneId)
                end)
            end
            -- Always clear the shadow session ref so they're no longer
            -- considered "in dungeon" by getSession() - even if they've
            -- left the zone, logged out, etc.
            sessions[mname] = nil
        end
    end

    sessions[player:getName()] = nil

    -- Phase-8: free the dungeon-zone occupancy lock. Keyed to the
    -- session's leader so a member-triggered end still releases the
    -- right lock (and never someone else's fresh claim).
    local occ = zoneOccupancy[dungeon.zoneId]
    if occ and occ.leaderName == (sess.leaderName or player:getName()) then
        zoneOccupancy[dungeon.zoneId] = nil
    end

    -- Always release the entry-grace setUnkillable flag, regardless
    -- of how the dungeon ended. If the player aborted or died within
    -- the 7-second grace window, the post-timer would never fire on
    -- this zone's PAI (they're being warped out), leaving them in a
    -- permanent unkillable state. Resetting here is idempotent - if
    -- the flag was already cleared by the timer, this is a no-op.
    pcall(function() player:setUnkillable(false) end)

    -- WARP-OUT DELAY (warpDelayMs: ~12s on a clear, 4s otherwise).
    --
    -- Player feedback (2026-05-28): "as soon as the last strike kills
    -- the mob, the warp fires. There should be a delay, so i can at
    -- least get a message that I cleared the battlefield". (2026-05-31:
    -- the clear-case delay was stretched to ~12s so the party can
    -- actually savor the win before the warp.)
    --
    -- Acceptable risk tradeoff: a DC during the warp window leaves the
    -- player's saved position in the dungeon zone. BUT by this point
    -- we've already cleared the session and despawned all mobs, so a
    -- reconnect lands them in a quiet, empty zone. Better still, the
    -- dungeon zones are the NORMAL Dynamis zones (185-188) whose real
    -- onZoneIn ejects a sessionless arrival to town -- so a relog during
    -- the linger self-heals to the city instead of stranding anyone. The
    -- OOB patrol also won't fire (they aren't moving), so the worst case
    -- is a harmless extra warp, not a broken state.
    --
    -- The "warping in N seconds..." message tells them the warp is
    -- coming so they don't think the game has frozen.
    player:printToPlayer(
        string.format('[Dungeon] Warping back to GM Home in %d seconds...', warpDelaySec),
        xi.msg.channel.SYSTEM_3)

    local exit = catalog.exitWarp
    player:timer(warpDelayMs, function(p)
        p:setPos(exit.x, exit.y, exit.z, exit.rotation, exit.zoneId)
    end)
end


-----------------------------------
-- Dungeon-zone onZoneIn hooks
-----------------------------------
-- For each dungeon's zone, register an onZoneIn override that:
--   1. Calls super(player, prevZone) so the zone's original onZoneIn
--      behavior (auto-correct, cutscenes, etc.) runs first.
--   2. If the player has an active dungeon session AND that session's
--      target zone matches THIS zone, calls armDungeonAfterArrival
--      to spawn mobs and arm the timeout/warning timers.
--
-- Only registers once per unique zoneName to avoid double-spawning if
-- multiple dungeons share a zone in the future.
--
-- This is the engine-guaranteed "player has arrived" event, replacing
-- the unreliable post-setPos player:timer that was dropped by the PAI
-- swap during zone transition.
local _registeredZoneIn = {}
for _, dungeon in ipairs(catalog.dungeons) do
    if dungeon._disabled then
        -- skip - zone was marked disabled at load; menu already hides it
    elseif not _registeredZoneIn[dungeon.zoneName] then
        _registeredZoneIn[dungeon.zoneName] = true
        local zoneIdToMatch = dungeon.zoneId

        if dungeon._useInstanceZoneIn then
            -- -------------------------------------------------------
            -- Dynamis [D] zones: engine fires onInstanceZoneIn on arrival
            -- (even for plain setPos warps).  The default handler kicks
            -- players without an active instance to zone 72.  We intercept
            -- that and arm the dungeon instead for dungeon runners.
            -- -------------------------------------------------------
            local zoneOverride = string.format('xi.zones.%s.Zone.onInstanceZoneIn', dungeon.zoneName)
            m:addOverride(zoneOverride, function(player, instance)
                local sess = sessions[player:getName()]
                local isDungeonRun = sess and sess.dungeon.zoneId == zoneIdToMatch
                if not isDungeonRun then
                    -- Not a dungeon run - let the original handler decide
                    -- (it will eject playerless-instance arrivals to zone 72).
                    super(player, instance)
                    return
                end
                print(string.format(
                    "[dungeon] onInstanceZoneIn hit for %s in zone %s (session matches)",
                    player:getName(), dungeon.zoneName))
                -- Small delay so zone-in completes before spawning entities.
                player:timer(1000, function(p) armDungeonAfterArrival(p) end)
            end)
            print(string.format(
                "[dungeon] registered onInstanceZoneIn override for %s (zone %d)",
                dungeon.zoneName, dungeon.zoneId))
        else
            -- -------------------------------------------------------
            -- Normal zones: engine fires onZoneIn on arrival.
            -- Skip super() for dungeon sessions to avoid any zone-
            -- specific entry logic (e.g. Dynamis city eject gate).
            -- -------------------------------------------------------
            local zoneOverride = string.format('xi.zones.%s.Zone.onZoneIn', dungeon.zoneName)
            m:addOverride(zoneOverride, function(player, prevZone)
                local sess = sessions[player:getName()]
                local isDungeonRun = sess and sess.dungeon.zoneId == zoneIdToMatch
                local cs = nil
                if not isDungeonRun then
                    cs = super(player, prevZone)
                end
                if isDungeonRun then
                    print(string.format(
                        "[dungeon] onZoneIn hit for %s in zone %s (session matches)",
                        player:getName(), dungeon.zoneName))
                    player:timer(1000, function(p) armDungeonAfterArrival(p) end)
                end
                return cs
            end)
            print(string.format(
                "[dungeon] registered onZoneIn override for %s (zone %d)",
                dungeon.zoneName, dungeon.zoneId))
        end
    end
end


-----------------------------------
-- Death + zone-out hooks
-----------------------------------
m:addOverride('xi.player.onPlayerDeath', function(player, ...)
    super(player, ...)
    local sess = getSession(player)
    if not sess then return end

    local elapsedSinceStart = os.time() - sess.startedAt
    local hp, mp = -1, -1
    pcall(function() hp = player:getHP() end)
    pcall(function() mp = player:getMP() end)
    print(string.format(
        "[dungeon] >>> DEATH: player=%s dungeon=%s zone=%d pos=(%.2f, %.2f, %.2f) HP=%d MP=%d elapsed=%ds",
        player:getName(), sess.dungeon.id, player:getZoneID(),
        player:getXPos() or -1, player:getYPos() or -1, player:getZPos() or -1,
        hp, mp, elapsedSinceStart))

    -- Phase-6 leader-vs-member branch. The legacy solo path (no party,
    -- sess.leaderName == player) falls through to endDungeon('death').
    -- For a true PARTY member (not the leader), only THAT player exits;
    -- the leader + remaining members keep fighting.
    if sess.leaderName and sess.leaderName ~= player:getName() then
        local mname = player:getName()
        detachMember(sess, mname)
        local exit = catalog.exitWarp
        pcall(function() player:setUnkillable(false) end)
        -- Warp the dead member home immediately. No reward - they fell.
        player:setPos(exit.x, exit.y, exit.z, exit.rotation, exit.zoneId)
        player:printToPlayer(
            '[Dungeon] You died. Warping back to GM Home - your party continues without you.',
            xi.msg.channel.SYSTEM_3)
        -- Tell the leader so they know to play around the loss.
        local leader = GetPlayerByName(sess.leaderName)
        if leader then
            leader:printToPlayer(
                string.format('[Dungeon] %s has died. %d member(s) still with you.',
                    mname, #(sess.members or {})),
                xi.msg.channel.SYSTEM_3)
        end
        return
    end

    -- Solo or leader-death path -> end the whole run.
    m.endDungeon(player, 'death')
end)


-----------------------------------
-- Dungeon Master NPC (entry)
-----------------------------------
-----------------------------------
-- customMenu label-collision guard
--
-- luautils.cpp HandleCustomMenu() routes a menu click back to the FIRST
-- option whose label byte-exactly matches the returned string, then
-- stops. So if two options share an identical label, clicking either one
-- fires the first option's callback. trunc() can produce that collision
-- when several names share a long common prefix -- e.g. the five
-- "Caballarius <slot> +4" reforge pieces all trunc to "Caballarius .." --
-- which made the Infamy Vendor sell the head piece on every row.
-- openMenu() runs every menu through dedupeLabels() so a duplicate label
-- can never silently misroute again.
local function dedupeLabels(opts)
    if type(opts) ~= 'table' then return opts end
    local seen = {}
    for _, opt in ipairs(opts) do
        local label = opt[1]
        if type(label) == 'string' then
            if seen[label] then
                local n = 2
                local candidate = label .. ' (' .. n .. ')'
                while seen[candidate] do
                    n = n + 1
                    candidate = label .. ' (' .. n .. ')'
                end
                opt[1] = candidate
                seen[candidate] = true
            else
                seen[label] = true
            end
        end
    end
    return opts
end

-- Single send choke-point: dedupe labels, then defer the customMenu by
-- 50ms (the original timing, preserved so chained menus settle before
-- the next packet).
local function openMenu(player, menu)
    dedupeLabels(menu.options)
    -- Snapshot before the deferred send: dmMenu/vendorMenu are shared
    -- scratch tables, and another player's interaction inside the 50ms
    -- window would otherwise swap their contents mid-flight.
    local snapshot = { title = menu.title, options = menu.options }
    player:timer(30, function(p) p:customMenu(snapshot) end)
end

local dmMenu = { title = 'Dungeon Master', options = {} }

local showDungeonMenu  -- forward decl
local showTierMenu     -- forward decl

-- Phase-2 confirm menu. tierId param flows from showTierMenu so the
-- "Yes" branch passes it to startDungeon. Defaults to 'normal' to
-- keep back-compat with any legacy direct caller.
local function showConfirmMenu(player, dungeon, tierId)
    tierId = tierId or 'normal'
    -- Phase-7: synthesize the keystone tier for display so the title
    -- shows the real M+<level> label and time limit. startDungeon
    -- re-synthesizes at launch (key level can't change in between -
    -- it only moves at run end).
    local tier = (tierId == 'keystone')
        and synthKeystoneTier(getKeyLevel(player, dungeon))
        or  getTier(tierId)
    local effectiveLimit = math.floor(dungeon.timeLimit * (tier.timeMult or 1.0))

    local opts =
    {
        {
            string.format('Yes - Begin %s [%s]', dungeon.label, tier.label),
            function(p) startDungeon(p, dungeon, tierId) end,
        },
        {
            'No - Back',
            function(p) showTierMenu(p, dungeon) end,
        },
    }
    dmMenu.title = string.format('%s [%s] (%dm)',
        dungeon.label, tier.label, math.floor(effectiveLimit / 60))
    dmMenu.options = opts
    openMenu(player, dmMenu)
end

-- Phase-2 tier picker. Shows Normal / Hard / Mythic with lock state
-- + per-tier rewards. Locked tiers are shown with their requirement
-- so the player knows what they're working toward; available tiers
-- route to showConfirmMenu with the chosen tierId.
showTierMenu = function(player, dungeon)
    local opts = {}

    -- Print the dungeon flavour once at the top so the menu can stay
    -- tight (the 150-byte customMenu cap is real, but the row count
    -- is what really matters here - 3 tiers + back + balance fits).
    player:printToPlayer(dungeon.description, xi.msg.channel.SYSTEM_3)

    if catalog.tierOrder and catalog.tiers then
        -- Labels are deliberately TERSE: the customMenu payload caps
        -- at ~150 bytes across title + every label, and the Phase-7
        -- keystone row pushed the old verbose labels over the cap
        -- (which silently truncates the menu). Details print to chat
        -- on click instead.
        for _, tId in ipairs(catalog.tierOrder) do
            local tier = catalog.tiers[tId]
            local lock = tierLockReason(player, dungeon, tId)
            if lock then
                local short = (not isTierUnlocked(player, dungeon, tId))
                    and 'locked' or 'used this wk'
                table.insert(opts, {
                    string.format('[%s] %s', tier.label, short),
                    function(p)
                        p:printToPlayer(string.format(
                            '[Dungeon Master] %s tier: %s',
                            tier.label, lock), xi.msg.channel.SYSTEM_3)
                        showTierMenu(p, dungeon)
                    end,
                })
            else
                table.insert(opts, {
                    string.format('[%s] x%.1f%s',
                        tier.label, tier.infamyMult or 1.0,
                        tier.weekly and ' wkly' or ''),
                    function(p)
                        p:printToPlayer(string.format(
                            '[Dungeon Master] %s: %s', tier.label, tier.description),
                            xi.msg.channel.SYSTEM_3)
                        showConfirmMenu(p, dungeon, tId)
                    end,
                })
            end
        end

        -- Phase-7 keystone row, below Mythic.
        if keystoneEnabled() then
            local lock = keystoneLockReason(player, dungeon)
            if lock then
                table.insert(opts, {
                    '[M+] locked',
                    function(p)
                        p:printToPlayer(string.format(
                            '[Dungeon Master] Mythic+ is %s', lock),
                            xi.msg.channel.SYSTEM_3)
                        showTierMenu(p, dungeon)
                    end,
                })
            else
                local level = getKeyLevel(player, dungeon)
                local kTier = synthKeystoneTier(level)
                table.insert(opts, {
                    string.format('[M+%d] x%.1f', level, kTier.infamyMult),
                    function(p)
                        local names = {}
                        for _, a in ipairs(keystoneAffixesFor(level)) do
                            table.insert(names, a.label)
                        end
                        p:printToPlayer(string.format(
                            '[Dungeon Master] Mythic+%d %s | best M+%d | affixes: %s | fast clears upgrade the key (+1/+2/+3), any failure depletes it by 1.',
                            level, dungeon.label, getKeyBest(player, dungeon),
                            (#names > 0) and table.concat(names, ', ') or 'none'),
                            xi.msg.channel.SYSTEM_3)
                        showConfirmMenu(p, dungeon, 'keystone')
                    end,
                })
            end
        end
    else
        -- No tier catalog -> legacy flow: just go straight to confirm
        -- at Normal. Keeps the system working with older catalogs.
        table.insert(opts, {
            string.format('Begin %s', dungeon.label),
            function(p) showConfirmMenu(p, dungeon, 'normal') end,
        })
    end

    table.insert(opts, { '<< Back', function(p) showDungeonMenu(p) end })

    dmMenu.title = string.format('%s - tier', dungeon.label:sub(1, 22))
    dmMenu.options = opts
    openMenu(player, dmMenu)
end

showDungeonMenu = function(player, page)
    page = page or 1
    local opts = {}

    -- Pagination: the 8 dungeons overflow the customMenu caps (~150 bytes
    -- across the title + every option label, and ~8 options client-side), so
    -- the list is split into pages of DUNGEON_PAGE. Computed up front so the
    -- title below can show the page count. (The menu was unpaginated back when
    -- there were only 4 dungeons -- the comment below predicted this.)
    local DUNGEON_PAGE = 4
    local visibleCount = 0
    for _, dd in ipairs(catalog.dungeons) do
        if not dd._disabled then visibleCount = visibleCount + 1 end
    end
    local dungeonPages = math.max(1, math.ceil(visibleCount / DUNGEON_PAGE))
    if page < 1 then page = 1 end
    if page > dungeonPages then page = dungeonPages end
    local pgFirst, pgLast = (page - 1) * DUNGEON_PAGE + 1, page * DUNGEON_PAGE
    local visIdx = 0

    -- Infamy balance is shown in CHAT, not as a menu row. The customMenu
    -- payload is hard-capped at 150 bytes (GP_SERV_COMMAND_CHAT_STD.Mes,
    -- see SetCustomMenuContext) across the title + EVERY option label.
    -- With all 4 dungeons listed that budget is essentially full; adding a
    -- "balance" row pushed the serialized menu to ~155 bytes, which the
    -- engine silently truncated -- lopping the final "Close" option down to
    -- a stray "C". Printing the balance here keeps it visible without
    -- spending any of the menu's byte budget on a non-action row.
    -- (Ceiling note: title + 4 dungeon rows + Close is ~132 bytes. A 5th
    -- dungeon would need pagination -- see the Infamy Vendor for the pattern.)
    player:printToPlayer(
        string.format('[Dungeon Master] Infamy balance: %d', getInfamy(player)),
        xi.msg.channel.SYSTEM_3)

    if getSession(player) then
        table.insert(opts, {
            'Abort current dungeon',
            function(p) m.endDungeon(p, 'manual') end,
        })
    else
        -- Phase 4 pre-print: surface today's featured dungeon + streak
        -- state + Mythic-key countdown above the dungeon list so the
        -- player sees the meta-progression context BEFORE picking. Chat
        -- prints (vs menu rows) because the menu has a 150-byte budget
        -- and this info would push us against the cap.
        local featured = getFeaturedDungeon()
        if featured then
            player:printToPlayer(
                string.format('[Dungeon Master] Today\'s featured dungeon: %s  (+%.0f%% Infamy, resets in %s)',
                    featured.label,
                    (catalog.featuredBonus or 0) * 100,
                    fmtCountdown(secondsToNextDay())),
                xi.msg.channel.SYSTEM_3)
        end
        local bonusDungeon, bonusWeekIdx = getWeeklyBonusDungeon()
        if bonusDungeon then
            local bonusStatus = hasEarnedWeeklyBonus(player, bonusWeekIdx, bonusDungeon.id)
                                and 'earned' or '2x Infamy on clear!'
            player:printToPlayer(
                string.format('[Dungeon Master] \xe2\x98\x85 This week\'s BONUS dungeon: %s  [%s, resets in %s]',
                    bonusDungeon.label,
                    bonusStatus,
                    fmtCountdown(secondsToNextWeek())),
                xi.msg.channel.SYSTEM_3)
        end
        local streak = getStreak(player)
        if streak > 0 then
            local cap        = catalog.streakCap or 5
            local step       = catalog.streakStep or 0.10
            -- The bonus the player sees on their NEXT clear: streak
            -- bumps by 1 (clamped at cap) before the reward path
            -- reads it, so the projected mult is 1 + min(s+1, cap)*step.
            local nextMult   = 1.0 + math.min(streak + 1, cap) * step
            player:printToPlayer(
                string.format('[Dungeon Master] Streak: %d/%d clears (next clear: x%.2f Infamy)',
                    streak, cap, nextMult),
                xi.msg.channel.SYSTEM_3)
        end

        -- Phase-7 keystone context: this week's affix combo + the
        -- player's key levels. Chat prints - zero menu byte cost -
        -- and only once any dungeon has Mythic+ unlocked.
        if keystoneEnabled() then
            local bits = {}
            for _, d in ipairs(catalog.dungeons) do
                if not d._disabled and isKeystoneUnlocked(player, d) then
                    table.insert(bits, string.format('%s M+%d (best %d)',
                        d.label:sub(1, 14), getKeyLevel(player, d), getKeyBest(player, d)))
                end
            end
            if #bits > 0 then
                local names = {}
                for _, id in ipairs(keystoneWeekSet()) do
                    local a = affixById(id)
                    if a then table.insert(names, a.label) end
                end
                if #names > 0 then
                    player:printToPlayer(
                        string.format('[Dungeon Master] Mythic+ affixes this week: %s  (rotate in %s)',
                            table.concat(names, ', '), fmtCountdown(secondsToNextWeek())),
                        xi.msg.channel.SYSTEM_3)
                end
                player:printToPlayer('[Dungeon Master] Keystones: ' .. table.concat(bits, ' | '),
                    xi.msg.channel.SYSTEM_3)
            end
        end

        -- Only show dungeons that passed module-load validation. A
        -- disabled dungeon would warp the player into a stuck zone,
        -- so hiding it from the menu is the right protection.
        for _, dungeon in ipairs(catalog.dungeons) do
            if not dungeon._disabled then
                visIdx = visIdx + 1
                if visIdx >= pgFirst and visIdx <= pgLast then
                local d = dungeon
                -- Star prefix on the featured dungeon so it's visible
                -- at a glance in the menu (the chat print above gave
                -- the details; this is the quick scan).
                local prefix = (featured and featured.id == d.id) and '* ' or ''
                -- Strip the uniform "The " prefix to keep labels short -- all
                -- dungeon labels start with "The ", and 4 long rows + nav would
                -- otherwise risk the ~150-byte customMenu cap.
                local label  = (d.label:gsub('^The ', ''))
                table.insert(opts, {
                    string.format('%s%s (%dm)', prefix, label, math.floor(d.timeLimit / 60)),
                    function(p)
                        -- Phase-2: route through tier picker. The
                        -- dungeon description is printed inside
                        -- showTierMenu, not here, so we don't double-
                        -- print it.
                        --
                        -- Phase-4 Mythic-key countdown chat print -
                        -- shown when the player taps into a dungeon
                        -- whose key is burned. Saves them a click
                        -- into the tier menu just to see "locked".
                        if catalog.tiers and catalog.tiers.mythic
                           and catalog.tiers.mythic.weekly
                           and isTierUnlocked(p, d, 'mythic')
                           and not hasMythicKey(p, d) then
                            p:printToPlayer(
                                string.format(
                                    '[Dungeon Master] Mythic key for %s resets in %s.',
                                    d.label, fmtCountdown(secondsToNextWeek())),
                                xi.msg.channel.SYSTEM_3)
                        end
                        -- Weekly Bonus Dungeon pick notification.
                        if isWeeklyBonus(d) then
                            p:printToPlayer(
                                '[Dungeon] \xe2\x98\x85 This is this week\'s BONUS dungeon \xe2\x80\x94 clear it for 2\xc3\x97 Infamy!',
                                xi.msg.channel.SYSTEM_3)
                        end
                        showTierMenu(p, d)
                    end,
                })
                end  -- /page slice (if visIdx >= pgFirst and <= pgLast)
            end
        end

        -- Pagination nav (only in the no-session branch, after the list).
        if page > 1 then
            table.insert(opts, {
                string.format('<< Prev (%d/%d)', page - 1, dungeonPages),
                function(p) showDungeonMenu(p, page - 1) end,
            })
        end
        if page < dungeonPages then
            table.insert(opts, {
                string.format('Next >> (%d/%d)', page + 1, dungeonPages),
                function(p) showDungeonMenu(p, page + 1) end,
            })
        end
    end
    table.insert(opts, { 'Close', function(p) end })

    dmMenu.title = (dungeonPages > 1)
        and string.format('Dungeon Master (%d/%d)', page, dungeonPages)
        or 'Dungeon Master'
    dmMenu.options = opts
    openMenu(player, dmMenu)
end


-----------------------------------
-- Infamy Vendor NPC
-----------------------------------
local vendorMenu = { title = '', options = {} }
-- customMenu payload cap: ~150 bytes across title + all option labels.
-- 4 items/page with 14-char truncated names keeps every page safely under
-- the limit. (catalog.vendorPageSize was 6, which overflowed pages 2+
-- with longer names like "Nyame Gauntlets  [400]", silently dropping the
-- Buy option and making purchases impossible.)
local INVENTORY_PAGE_SIZE = 4
local JOB_PAGE_SIZE       = 6   -- pagination for the +4 job picker (22 jobs)

-- Truncate a string to at most `max` visible chars. Appends '..' when
-- shortened so the player knows the name continues.
local function trunc(s, max)
    if not s or #s <= max then return s or '' end
    return s:sub(1, max - 2) .. '..'
end

-- Longest common prefix of a list of names, trimmed back to the last whole
-- word (space) so only complete words are ever stripped. Returns the byte
-- length to drop (0 = nothing safely strippable). Used to strip the
-- redundant set-name prefix from curated-set rows -- the set name is already
-- in the menu title -- so "Nyame Helm"/"Nyame Mail" display as "Helm"/"Mail"
-- instead of all truncating toward an identical "Nyame ..".
local function commonWordPrefixLen(names)
    if type(names) ~= 'table' or #names < 2 then return 0 end
    local first  = names[1] or ''
    local maxLen = #first
    for i = 2, #names do
        local s = names[i] or ''
        local j = 1
        while j <= maxLen and j <= #s and first:byte(j) == s:byte(j) do
            j = j + 1
        end
        maxLen = j - 1
        if maxLen == 0 then return 0 end
    end
    -- Cut back to (and including) the last space inside the common prefix.
    for pos = maxLen, 1, -1 do
        if first:byte(pos) == 32 then return pos end
    end
    return 0
end

-- Forward declarations for mutually-recursive menu functions
local showVendorRoot
local showCuratedMenu
local showCuratedCat
local showCuratedSub
local showCuratedPreview
local showCuratedSetsMenu
local showCuratedSetDetail
local showCuratedSetPiecePreview
local showPlus4JobMenu
local showPlus4SetMenu
local showPlus4SlotMenu
local showPlus4Preview

--------------------------------------------------------------------
-- NATIVE SHOP HELPER  (FJB 2026-06-14)
-- Opens the real FFXI shop window (item icons + stat tooltips) for a slice of
-- items, charging the Infamy CharVar via the setShopCurrencyVar engine hook
-- (packets/c2s/0x083_shop_buy.cpp) instead of gil -- mirrors the Hunting League
-- gear vendors. The window holds 16 items; callers with more pass a page index
-- and surface "Items A-B" page rows themselves. The C++ buy handler does the
-- Infamy debit, so no Lua purchase/deduction code is needed here.
--------------------------------------------------------------------
local SHOP_PAGE_SIZE = 16

local function openInfamyShop(player, items, page)
    page = page or 1
    local total = #items
    if total == 0 then
        player:printToPlayer('Nothing available here, kupo!', xi.msg.channel.SYSTEM_3)
        return
    end
    local startIdx = (page - 1) * SHOP_PAGE_SIZE + 1
    local endIdx   = math.min(startIdx + SHOP_PAGE_SIZE - 1, total)
    if endIdx < startIdx then return end

    player:printToPlayer(
        string.format('You have %d Infamy. Hover items to preview; buying spends Infamy, kupo!',
            getInfamy(player)),
        xi.msg.channel.SYSTEM_3)

    player:timer(50, function(p)
        p:createShop(endIdx - startIdx + 1)
        for i = startIdx, endIdx do
            p:addShopItem(items[i].id, items[i].cost)
        end
        p:setShopCurrencyVar(catalog.currencyCv)
        p:sendMenu(xi.menuType.SHOP)
    end)
end

--------------------------------------------------------------------
-- ROOT MENU - category picker
--------------------------------------------------------------------
showVendorRoot = function(player)
    local opts = {}
    table.insert(opts, { 'Curated Items',    function(p) showCuratedMenu(p) end })
    table.insert(opts, { 'Curated Sets',     function(p) showCuratedSetsMenu(p, 1) end })
    table.insert(opts, { '+4 Reforge Sets',  function(p) showPlus4JobMenu(p, 1) end })
    table.insert(opts, { 'Close',            function(p) end })

    vendorMenu.title = string.format('Infamy Vendor  [%d Infamy]', getInfamy(player))
    vendorMenu.options = opts
    openMenu(player, vendorMenu)
end

--------------------------------------------------------------------
-- CURATED BROWSER - paged list combining BOTH:
--   catalog.vendorItems     (hand-picked curated list)
--   catalog.vendorItemsAuto (auto-promoted Gold-tier BiS from the
--                            armor/accessory/weapons scorers, written
--                            by tools/build_infamy_top_picks.py)
--
-- Concatenated in that order so hand-picked items keep their
-- stable indices regardless of how the auto list rolls over. The
-- combined view is rebuilt fresh on each menu open so a hot-reloaded
-- catalog edit shows up without restarting the NPC.
--------------------------------------------------------------------
local function buildCuratedItems()
    local out = {}
    for _, it in ipairs(catalog.vendorItems     or {}) do table.insert(out, it) end
    for _, it in ipairs(catalog.vendorItemsAuto or {}) do table.insert(out, it) end
    return out
end

-- Display order for the grouped browser (Category -> Subtype).
local CAT_ORDER = { 'Weapons', 'Armor', 'Accessories', 'Other' }
local SUB_ORDER =
{
    Weapons     = { 'Hand-to-Hand', 'Dagger', 'Sword', 'Great Sword', 'Axe',
                    'Great Axe', 'Scythe', 'Polearm', 'Katana', 'Great Katana',
                    'Club', 'Staff', 'Archery', 'Marksmanship', 'Ammo', 'Instrument',
                    'Grip-Shield', 'Other' },
    Armor       = { 'Head', 'Body', 'Hands', 'Legs', 'Feet', 'Other' },
    Accessories = { 'Neck', 'Ear', 'Ring', 'Waist', 'Back', 'Other' },
    Other       = { 'Other' },
}
local SUBTYPE_PAGE_SIZE = 6   -- subtype rows per page (Weapons has ~16 types)

-- Group the combined curated list into g[cat][sub] = { {idx, item}, ... } where
-- idx is the index into buildCuratedItems() (so the buy code can fetch by index
-- unchanged). Rebuilt each open so catalog hot-edits show up. Items missing a
-- catalog.itemTypeMap entry fall to Other/Other so nothing ever disappears.
local function groupCurated()
    local items = buildCuratedItems()
    local map   = catalog.itemTypeMap or {}
    local g     = {}
    for idx, it in ipairs(items) do
        local cs       = map[it.id] or 'Other/Other'
        local cat, sub = cs:match('^(.-)/(.+)$')
        cat = cat or 'Other'
        sub = sub or 'Other'
        g[cat]      = g[cat] or {}
        g[cat][sub] = g[cat][sub] or {}
        table.insert(g[cat][sub], { idx = idx, item = it })
    end
    return g
end

local function catCount(g, cat)
    local n = 0
    for _, list in pairs(g[cat] or {}) do n = n + #list end
    return n
end

-- Subs present in a category, SUB_ORDER first then any unexpected extras.
local function subsPresent(g, cat)
    local present, out, seen = g[cat] or {}, {}, {}
    for _, sub in ipairs(SUB_ORDER[cat] or {}) do
        if present[sub] then table.insert(out, sub); seen[sub] = true end
    end
    for sub in pairs(present) do
        if not seen[sub] then table.insert(out, sub) end
    end
    return out
end

--------------------------------------------------------------------
-- CURATED BROWSER (grouped): Category -> Subtype -> item -> Buy.
-- Replaces the old flat ~60-item paged list (a pain to cycle). Grouping
-- uses catalog.itemTypeMap (regen: tools/build_infamy_typemap.py). Each
-- level honors the ~150-byte customMenu cap: <=4 items/page (item level),
-- <=6 subtypes/page (subtype level), short titles, stats printed to chat.
--------------------------------------------------------------------
showCuratedMenu = function(player)
    local g = groupCurated()
    local opts = {}
    for _, cat in ipairs(CAT_ORDER) do
        local n = catCount(g, cat)
        if n > 0 then
            local c = cat
            table.insert(opts, { string.format('%s (%d)', cat, n),
                function(p) showCuratedCat(p, c, 1) end })
        end
    end
    table.insert(opts, { '<< Back', function(p) showVendorRoot(p) end })

    vendorMenu.title = string.format('Browse  [%d Inf]', getInfamy(player))
    vendorMenu.options = opts
    openMenu(player, vendorMenu)
end

showCuratedCat = function(player, cat, page)
    page = page or 1
    local g     = groupCurated()
    local subs  = subsPresent(g, cat)
    local pages = math.max(1, math.ceil(#subs / SUBTYPE_PAGE_SIZE))
    page = math.max(1, math.min(page, pages))
    local startIdx = (page - 1) * SUBTYPE_PAGE_SIZE + 1
    local endIdx   = math.min(startIdx + SUBTYPE_PAGE_SIZE - 1, #subs)

    local opts = {}
    for i = startIdx, endIdx do
        local sub = subs[i]
        table.insert(opts, { trunc(sub, 16),
            function(p) showCuratedSub(p, cat, sub, 1) end })
    end
    if pages > 1 then
        if page > 1     then table.insert(opts, { '<< Prev', function(p) showCuratedCat(p, cat, page - 1) end }) end
        if page < pages then table.insert(opts, { 'Next >>', function(p) showCuratedCat(p, cat, page + 1) end }) end
    end
    table.insert(opts, { '<< Back', function(p) showCuratedMenu(p) end })

    vendorMenu.title = trunc(cat, 24)
    vendorMenu.options = opts
    openMenu(player, vendorMenu)
end

showCuratedSub = function(player, cat, sub, page)
    local g    = groupCurated()
    local list = (g[cat] or {})[sub] or {}
    local items = {}
    for _, entry in ipairs(list) do
        items[#items + 1] = { id = entry.item.id, cost = entry.item.cost }
    end

    -- <=16 items: straight into the native shop window. >16 (e.g. the Ear slot
    -- once the Sortie earrings are stocked): a tiny page-picker, each row
    -- opening a 16-item shop slice.
    if #items <= SHOP_PAGE_SIZE then
        openInfamyShop(player, items, 1)
        return
    end

    local opts  = {}
    local pages = math.ceil(#items / SHOP_PAGE_SIZE)
    for pg = 1, pages do
        local a = (pg - 1) * SHOP_PAGE_SIZE + 1
        local b = math.min(pg * SHOP_PAGE_SIZE, #items)
        table.insert(opts, { string.format('Items %d-%d', a, b),
            function(p) openInfamyShop(p, items, pg) end })
    end
    table.insert(opts, { '<< Back', function(p) showCuratedCat(p, cat, 1) end })

    vendorMenu.title   = string.format('%s  [%d Inf]', trunc(sub, 12), getInfamy(player))
    vendorMenu.options = opts
    openMenu(player, vendorMenu)
end

showCuratedPreview = function(player, itemIdx, cat, sub, page)
    local items = buildCuratedItems()
    local item  = items[itemIdx]
    if not item then
        showCuratedSub(player, cat, sub, page)
        return
    end

    -- Stats to chat (long lines would blow the 150-byte customMenu cap).
    for _, line in ipairs(item.stats or { '(no description)' }) do
        player:printToPlayer(line, xi.msg.channel.SYSTEM_3)
    end

    local opts = {}
    local bal = getInfamy(player)
    if bal >= item.cost then
        table.insert(opts, {
            string.format('Buy  [%d Infamy]', item.cost),
            function(p)
                if p:getFreeSlotsCount() == 0 then
                    p:printToPlayer('Inventory full! Free a slot first, kupo!',
                        xi.msg.channel.SYSTEM_3)
                    showCuratedPreview(p, itemIdx, cat, sub, page)
                    return
                end
                p:setCharVar(catalog.currencyCv, getInfamy(p) - item.cost)
                p:addItem({ id = item.id, quantity = 1 })
                p:printToPlayer(
                    string.format('[Infamy Vendor] Purchased %s for %d Infamy. (%d remaining), kupo!',
                        item.name, item.cost, getInfamy(p)),
                    xi.msg.channel.SYSTEM_3)
                showCuratedSub(p, cat, sub, page)
            end,
        })
    else
        table.insert(opts, {
            string.format('Need %d  (have %d)', item.cost, bal),
            function(p) showCuratedPreview(p, itemIdx, cat, sub, page) end,
        })
    end
    table.insert(opts, { '<< Back', function(p) showCuratedSub(p, cat, sub, page) end })

    vendorMenu.title = string.format('%s  %d Inf', trunc(item.name, 15), item.cost)
    vendorMenu.options = opts
    openMenu(player, vendorMenu)
end

--------------------------------------------------------------------
-- CURATED SETS BROWSER - Set list -> Piece list -> Preview / Buy
--
-- Stocks catalog.vendorSets: full armor sets (Nyame, Hjarrandi, etc.)
-- broken out piece-by-piece so players can fill whichever slots they
-- still need. Same 150-byte payload cap rules apply:
--   title  "Sets  [XXXX Inf]"      <= 18 bytes
--   4 items "Name trunc  [cost]"   <= 4 x 24 = 96 bytes
--   Prev + Next + Back             <= 21 bytes
--   worst-case middle page total   <= 135 bytes  (safe)
--------------------------------------------------------------------
local SETS_PAGE_SIZE = 4

showCuratedSetsMenu = function(player, page)
    page = page or 1
    local sets  = catalog.vendorSets or {}
    local total = #sets
    local pages = math.max(1, math.ceil(total / SETS_PAGE_SIZE))
    page = math.max(1, math.min(page, pages))

    local opts = {}
    local startIdx = (page - 1) * SETS_PAGE_SIZE + 1
    local endIdx   = math.min(startIdx + SETS_PAGE_SIZE - 1, total)

    for idx = startIdx, endIdx do
        local s      = sets[idx]
        local pcount = s.pieces and #s.pieces or 0
        table.insert(opts, {
            string.format('%s  (%d pc)', trunc(s.set, 16), pcount),
            function(p) showCuratedSetDetail(p, idx, page) end,
        })
    end

    if pages > 1 then
        if page > 1 then
            table.insert(opts, { '<< Prev', function(p) showCuratedSetsMenu(p, page - 1) end })
        end
        if page < pages then
            table.insert(opts, { 'Next >>',  function(p) showCuratedSetsMenu(p, page + 1) end })
        end
    end
    table.insert(opts, { '<< Back', function(p) showVendorRoot(p) end })

    vendorMenu.title   = string.format('Sets  [%d Inf]', getInfamy(player))
    vendorMenu.options = opts
    openMenu(player, vendorMenu)
end

showCuratedSetDetail = function(player, setIdx, fromPage)
    local sets     = catalog.vendorSets or {}
    local setEntry = sets[setIdx]
    if not setEntry then
        showCuratedSetsMenu(player, fromPage)
        return
    end

    -- The set's pieces (<=5) go straight into the native shop window.
    local items = {}
    for _, piece in ipairs(setEntry.pieces or {}) do
        items[#items + 1] = { id = piece.id, cost = piece.cost }
    end
    openInfamyShop(player, items, 1)
end

showCuratedSetPiecePreview = function(player, setIdx, pieceIdx, fromPage)
    local sets     = catalog.vendorSets or {}
    local setEntry = sets[setIdx]
    local piece    = setEntry and (setEntry.pieces or {})[pieceIdx]
    if not piece then
        showCuratedSetDetail(player, setIdx, fromPage)
        return
    end

    -- Print stats to chat before the buy menu - same reason as the other
    -- previews: stat lines overflow the 150-byte customMenu cap.
    for _, line in ipairs(piece.stats or { '(no description)' }) do
        player:printToPlayer(line, xi.msg.channel.SYSTEM_3)
    end

    local opts = {}
    local bal  = getInfamy(player)
    if bal >= piece.cost then
        table.insert(opts, {
            string.format('Buy  [%d Infamy]', piece.cost),
            function(p)
                if p:getFreeSlotsCount() == 0 then
                    p:printToPlayer('Inventory full! Free a slot first, kupo!',
                        xi.msg.channel.SYSTEM_3)
                    showCuratedSetPiecePreview(p, setIdx, pieceIdx, fromPage)
                    return
                end
                p:setCharVar(catalog.currencyCv, getInfamy(p) - piece.cost)
                p:addItem({ id = piece.id, quantity = 1 })
                p:printToPlayer(
                    string.format('[Infamy Vendor] Purchased %s for %d Infamy. (%d remaining), kupo!',
                        piece.name, piece.cost, getInfamy(p)),
                    xi.msg.channel.SYSTEM_3)
                showCuratedSetDetail(p, setIdx, fromPage)
            end,
        })
    else
        table.insert(opts, {
            string.format('Need %d  (have %d)', piece.cost, bal),
            function(p) showCuratedSetPiecePreview(p, setIdx, pieceIdx, fromPage) end,
        })
    end
    table.insert(opts, { '<< Back', function(p) showCuratedSetDetail(p, setIdx, fromPage) end })

    vendorMenu.title   = trunc(piece.name, 22)
    vendorMenu.options = opts
    openMenu(player, vendorMenu)
end

--------------------------------------------------------------------
-- +4 REFORGE BROWSER - Job -> Set -> Slot -> Preview
--------------------------------------------------------------------
-- Pre-compute the sorted job list once (the catalog table has string keys
-- so ipairs won't enumerate it deterministically).
local plus4Jobs = {}
for job, _ in pairs(catalog.plus4Sets or {}) do
    table.insert(plus4Jobs, job)
end
table.sort(plus4Jobs)

showPlus4JobMenu = function(player, page)
    page = page or 1
    local total = #plus4Jobs
    local pages = math.max(1, math.ceil(total / JOB_PAGE_SIZE))
    page = math.max(1, math.min(page, pages))

    local opts = {}
    local startIdx = (page - 1) * JOB_PAGE_SIZE + 1
    local endIdx   = math.min(startIdx + JOB_PAGE_SIZE - 1, total)

    for idx = startIdx, endIdx do
        local job = plus4Jobs[idx]
        local sets = catalog.plus4Sets[job] or {}
        table.insert(opts, {
            string.format('%s  (%d set%s)', job, #sets, #sets == 1 and '' or 's'),
            function(p) showPlus4SetMenu(p, job, page) end,
        })
    end

    if pages > 1 then
        if page > 1 then
            table.insert(opts, { '<< Prev', function(p) showPlus4JobMenu(p, page - 1) end })
        end
        if page < pages then
            table.insert(opts, { 'Next >>', function(p) showPlus4JobMenu(p, page + 1) end })
        end
    end
    table.insert(opts, { '<< Back', function(p) showVendorRoot(p) end })

    vendorMenu.title = string.format('+4 Reforge  [%d Infamy]', getInfamy(player))
    vendorMenu.options = opts
    openMenu(player, vendorMenu)
end

showPlus4SetMenu = function(player, job, jobPage)
    local sets = catalog.plus4Sets[job] or {}
    local opts = {}
    for setIdx, setEntry in ipairs(sets) do
        local pieceCount = 0
        for _ in pairs(setEntry.pieces or {}) do pieceCount = pieceCount + 1 end
        table.insert(opts, {
            string.format('%s  (%d pc)', setEntry.set, pieceCount),
            function(p) showPlus4SlotMenu(p, job, setIdx, jobPage) end,
        })
    end
    table.insert(opts, { '<< Back', function(p) showPlus4JobMenu(p, jobPage) end })

    vendorMenu.title = string.format('%s Sets  [%d Infamy]', job, getInfamy(player))
    vendorMenu.options = opts
    openMenu(player, vendorMenu)
end

local PLUS4_SLOT_ORDER = { 'head', 'body', 'hands', 'legs', 'feet' }

showPlus4SlotMenu = function(player, job, setIdx, jobPage)
    local setEntry = (catalog.plus4Sets[job] or {})[setIdx]
    if not setEntry then
        showPlus4SetMenu(player, job, jobPage)
        return
    end
    -- The set's 5 pieces (all at the flat +4 cost) go into the native shop.
    local cost  = catalog.plus4Cost or 200
    local items = {}
    for _, slot in ipairs(PLUS4_SLOT_ORDER) do
        local piece = (setEntry.pieces or {})[slot]
        if piece then
            items[#items + 1] = { id = piece.id, cost = cost }
        end
    end
    openInfamyShop(player, items, 1)
end

showPlus4Preview = function(player, job, setIdx, slot, jobPage)
    local setEntry = (catalog.plus4Sets[job] or {})[setIdx]
    local piece    = setEntry and (setEntry.pieces or {})[slot]
    if not piece then
        showPlus4SlotMenu(player, job, setIdx, jobPage)
        return
    end
    local cost = catalog.plus4Cost or 200

    -- Print stats to chat - same reason as showCuratedPreview: stat lines
    -- for +4 pieces are 80+ bytes each and would overflow the 150-byte
    -- customMenu cap if used as menu options.
    for _, line in ipairs(piece.stats or { '(stats unavailable)' }) do
        player:printToPlayer(line, xi.msg.channel.SYSTEM_3)
    end

    local opts = {}
    local bal = getInfamy(player)
    if bal >= cost then
        table.insert(opts, {
            string.format('Buy  [%d Infamy]', cost),
            function(p)
                if p:getFreeSlotsCount() == 0 then
                    p:printToPlayer('Inventory full! Free a slot first, kupo!',
                        xi.msg.channel.SYSTEM_3)
                    showPlus4Preview(p, job, setIdx, slot, jobPage)
                    return
                end
                p:setCharVar(catalog.currencyCv, getInfamy(p) - cost)
                p:addItem({ id = piece.id, quantity = 1 })
                p:printToPlayer(
                    string.format('[Infamy Vendor] Purchased %s for %d Infamy. (%d remaining), kupo!',
                        piece.name, cost, getInfamy(p)),
                    xi.msg.channel.SYSTEM_3)
                showPlus4SlotMenu(p, job, setIdx, jobPage)
            end,
        })
    else
        table.insert(opts, {
            string.format('Need %d  (have %d)', cost, bal),
            function(p) showPlus4Preview(p, job, setIdx, slot, jobPage) end,
        })
    end
    table.insert(opts, { '<< Back', function(p) showPlus4SlotMenu(p, job, setIdx, jobPage) end })

    -- Short title: truncated piece name. Full stats are in chat above.
    vendorMenu.title = trunc(piece.name, 22)
    vendorMenu.options = opts
    openMenu(player, vendorMenu)
end


-----------------------------------
-- NPC placement (in GM Home only - both NPCs)
-----------------------------------
m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', catalog.dungeonMasterPos.zone), function(zone)
    super(zone)

    local DungeonMaster = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Dungeon_Master',
        packetName = string.format('%sDungeon Master', xi.icon.STAR_LARGE),
        look       = 3018,
        x          = catalog.dungeonMasterPos.x,
        y          = catalog.dungeonMasterPos.y,
        z          = catalog.dungeonMasterPos.z,
        rotation   = catalog.dungeonMasterPos.rotation,
        widescan   = 1,
        onTrigger  = function(player, npc)
            player:printToPlayer(
                '[ Dungeon Master ] Choose your descent, kupo!',
                xi.msg.channel.SYSTEM_3)
            showDungeonMenu(player)
        end,
    })
    utils.unused(DungeonMaster)

    local InfamyVendor = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Infamy_Vendor',
        packetName = string.format('%sInfamy Vendor', xi.icon.STAR_LARGE),
        look       = 2419,
        x          = catalog.infamyVendorPos.x,
        y          = catalog.infamyVendorPos.y,
        z          = catalog.infamyVendorPos.z,
        rotation   = catalog.infamyVendorPos.rotation,
        widescan   = 1,
        onTrigger  = function(player, npc)
            player:printToPlayer(
                '[ Infamy Vendor ] Trade your notoriety for power, kupo.',
                xi.msg.channel.SYSTEM_3)
            showVendorRoot(player)
        end,
    })
    utils.unused(InfamyVendor)
end)

-- =========================================================================
-- ZONE-OUT GUARD RAIL
-- =========================================================================
-- While a dungeon session is active, any zone-out attempt bounces the player
-- back to the dungeon's warpIn coords. Catches every form of leaving:
--   * Walking through a zone boundary
--   * Warp / Recall-XXX / Tractor spells
--   * Home Point teleports
--   * Mog House warps (Re-Raise, anniversary ring, etc.)
--   * `!warp` / `!gmhome` style commands
--   * GM `!goto*` commands
--
-- The hook only fires when sessions[name] is non-nil. The dungeon's own
-- clear/abort code clears sessions[name] BEFORE the 4s exit-warp timer
-- (see line ~1892), so the legitimate exit warp passes through unimpeded.
--
-- Recursion safety: after the bounce-back setPos, onZoneIn fires again
-- for the dungeon zone. The check `getZoneID() ~= sess.dungeon.zoneId` is
-- now FALSE, so no second bounce. No flag needed.
--
-- This wraps InteractionGlobal.onZoneIn, the C++ engine's dispatcher. We
-- call super() first so all other onZoneIn logic (including the cutscene
-- suppressor in modules/custom/lua/disable_zonein_cutscenes.lua) runs
-- normally, then do the dungeon check, then forward super's return.
require('scripts/globals/interaction/interaction_global')

m:addOverride('InteractionGlobal.onZoneIn', function(player, prevZone, fallbackFn)
    local result = super(player, prevZone, fallbackFn)

    local sess = sessions[player:getName()]
    if sess and sess.dungeon and player:getZoneID() ~= sess.dungeon.zoneId then
        -- Player used !gmhome / !warp / Home Point / etc. to leave the dungeon
        -- zone mid-run. Treat as a voluntary abort: clean up the session and
        -- mobs, but do NOT bounce them back -- they stay wherever they warped to.
        print(string.format(
            "[dungeon] %s left dungeon '%s' (zone %d) for zone %d -- aborting run (no bounce-back)",
            player:getName(), sess.dungeon.id, sess.dungeon.zoneId,
            player:getZoneID()))

        player:printToPlayer(
            '[Dungeon] You left the dungeon mid-run. No Infamy awarded.',
            xi.msg.channel.SYSTEM_3)

        -- DEFER the teardown out of this onZoneIn callback. endDungeon despawns
        -- mobs and fires exit-warp setPos calls; running that synchronously while
        -- the engine is still mid-OnZoneIn (the player is *arriving* at GM Home in
        -- this very call) is a re-entrant zone change that segfaulted the map
        -- (crash 2026-06-14 22:47:37, Brogurt aborting whispering_halls -> GM Home).
        -- A short timer lets OnZoneIn return and the player settle first; the
        -- dungeon zone lingers far longer than this, so the mob refs stay valid.
        -- endDungeon is idempotent (getSession guard) if onZoneIn somehow re-fires.
        player:timer(500, function(p) m.endDungeon(p, 'manual') end)
    end

    return result
end)

return m
