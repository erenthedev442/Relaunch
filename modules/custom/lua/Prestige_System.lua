-----------------------------------
-- Prestige_System.lua
-- The Ascension (Prestige) endgame layer that sits ABOVE Hunting League's
-- Legend tier. Earn Ascension Points (AP) by re-clearing the Legend NMs
-- (the Trial) and paying an escalating Hunt Marks cost, then spend AP on
-- permanent, stacking stat boosts -- Job-Points style.
--
-- *** PER-JOB ***
-- Every ascension layer is tracked per main job, exactly like Job Points:
-- ascending on WAR earns AP for WAR, spending it boosts WAR, and those mods
-- only apply while WAR is your main job. Switch to BLM and WAR's prestige
-- mods are swapped out for BLM's. The Hunting League gate (Legend) and the
-- Trial are account-wide -- once you are Legend you may ascend ANY job, but
-- each ascension (whichever job) consumes a fresh Trial clear.
--
-- Three override surfaces + one exported hook:
--   1. <zone>.Zone.onInitialize    -- places the Ascension Altar NPC and
--      wires its multi-level customMenu (Status / Ascend / Spend AP / Close).
--   2. xi.player.onGameIn          -- a zone-in wipes in-memory mods, so this
--      re-applies the CURRENT job's purchased boosts every zone-in.
--   3. xi.gear_sets.checkForGearSet -- fires on job change (and gear change),
--      where there is NO re-zone. This swaps the previously-applied job's
--      prestige mods for the current job's so a no-zone job swap stays honest.
--   + M.onLegendKill(player, groupId) -- called from HuntingLeague.lua when a
--      Tier-5 NM dies; stamps the account-wide per-cycle Trial progress.
--
-- ALL tuning lives in prestige_catalog.lua. Do not hard-code numbers here.
--
-- Player CharVars (<job> = numeric main-job id from getMainJob()):
--   Prestige_Level_<job>       -- completed ascensions for that job
--   Prestige_AP_<job>          -- that job's unspent Ascension Points
--   Prestige_AP_Lifetime_<job> -- that job's total AP ever granted (flavour)
--   Prestige_Cat_<job>_<id>    -- purchased levels in a spend category
--   Prestige_Trial_<group>     -- account-wide per-cycle NM stamp; cleared on ascend
--   Prestige_Ascensions_Total  -- account-wide lifetime ascensions (flex/leaderboard)
-- Player LocalVar (per zone session, never persisted):
--   PrestigeModJob             -- which job's mods are currently applied
-----------------------------------
require('modules/module_utils')

local cfg = require('modules/custom/lua/prestige_catalog')

-- Require the altar's zone so the onInitialize override path resolves.
local _zoneName = cfg.zonePath:match('xi%.zones%.(.+)')
require(string.format('scripts/zones/%s/Zone', _zoneName))

-----------------------------------
local m = Module:new('prestige_system')

-----------------------------------
-- Job id -> short label, for menu/title/announce display. Mirrors the table
-- in subjob_exp_share.lua; kept local so this module stays self-contained.
-----------------------------------
local _jobAbbr =
{
    [xi.job.WAR] = 'WAR', [xi.job.MNK] = 'MNK', [xi.job.WHM] = 'WHM',
    [xi.job.BLM] = 'BLM', [xi.job.RDM] = 'RDM', [xi.job.THF] = 'THF',
    [xi.job.PLD] = 'PLD', [xi.job.DRK] = 'DRK', [xi.job.BST] = 'BST',
    [xi.job.BRD] = 'BRD', [xi.job.RNG] = 'RNG', [xi.job.SAM] = 'SAM',
    [xi.job.NIN] = 'NIN', [xi.job.DRG] = 'DRG', [xi.job.SMN] = 'SMN',
    [xi.job.BLU] = 'BLU', [xi.job.COR] = 'COR', [xi.job.PUP] = 'PUP',
    [xi.job.DNC] = 'DNC', [xi.job.SCH] = 'SCH', [xi.job.GEO] = 'GEO',
    [xi.job.RUN] = 'RUN',
}
local function jobTag(jobId)
    return _jobAbbr[jobId] or ('J' .. tostring(jobId))
end

-----------------------------------
-- Per-job CharVar key builders. <job> is the numeric id from getMainJob().
-----------------------------------
local function levelKey(jobId) return string.format('Prestige_Level_%d', jobId) end
local function apKey(jobId)    return string.format('Prestige_AP_%d', jobId) end
local function apLifeKey(jobId) return string.format('Prestige_AP_Lifetime_%d', jobId) end
local function catKey(jobId, id) return string.format('Prestige_Cat_%d_%s', jobId, id) end

-----------------------------------
-- Current-job getters (everything the menu touches is "the job you're on").
-- getCharVar returns 0 for unset keys; the `or 0` is belt-and-braces.
-----------------------------------
local function curJob(player)        return player:getMainJob() end
local function getLevel(player)      return player:getCharVar(levelKey(curJob(player))) or 0 end
local function getAP(player)         return player:getCharVar(apKey(curJob(player)))    or 0 end
local function getCatLevel(p, id)    return p:getCharVar(catKey(curJob(p), id))         or 0 end

-- Account-wide values (shared across all jobs).
local function getMarks(player)      return player:getCharVar(cfg.markVar) or 0 end
local function getTier(player)       return player:getCharVar('HL_Tier')   or 1 end

-- AP granted when ascending to `level` (the level AFTER the ascension).
-- Walks cfg.apTiers in order (ascending minLevel) and returns the ap for
-- the highest bracket the new level satisfies. Falls back to 10 if unconfigured.
local function apForLevel(level)
    local ap = 10
    for _, t in ipairs(cfg.apTiers or {}) do
        if level >= t.minLevel then ap = t.ap end
    end
    return ap
end

-- Hunt Marks needed to perform the next ascension on a job. Escalates with
-- THAT job's prestige level up to markCostCap (if set), so costs plateau
-- rather than scaling forever.
local function markCost(level)
    local cost = cfg.markCostBase * (level + 1)
    if cfg.markCostCap then
        cost = math.min(cost, cfg.markCostCap)
    end
    return cost
end

-- Ascension Trial difficulty tier for a given (current-job) prestige level.
-- Discrete: returns the HIGHEST cfg.trialScaling.tiers entry whose minLevel the
-- level meets (tiers are authored in ascending minLevel order). Returns nil when
-- scaling is disabled or unconfigured, in which case bosses spawn at baseline.
local function trialTier(level)
    local ts = cfg.trialScaling
    if not (ts and ts.enabled and ts.tiers) then
        return nil
    end
    local chosen = nil
    for _, t in ipairs(ts.tiers) do
        if level >= t.minLevel then
            chosen = t
        end
    end
    return chosen
end

-----------------------------------
-- Trial ROSTER resolution (the boss line-up changes by difficulty tier).
-- The tier-0 / fallback roster is the top-level Nightmare Court; tiers 1+ each
-- carry their own roster in cfg.trialScaling.tiers[N].roster.
-----------------------------------
local baseRoster = { order = cfg.trialBossOrder, bosses = cfg.trialBosses }

-- Highest tier whose minLevel is met AND that defines a roster; else the base
-- (tier-0) roster. Pairs with trialTier() -- the matching tier.name is the
-- Court's display name.
local function currentRoster(level)
    local ts     = cfg.trialScaling
    local roster = baseRoster
    if ts and ts.enabled and ts.tiers then
        for _, t in ipairs(ts.tiers) do
            if level >= t.minLevel and t.roster then
                roster = t.roster
            end
        end
    end
    return roster
end

-- {groupId, label} pairs for a roster, in summon order -- the shape the trial
-- bookkeeping expects.
local function rosterNms(roster)
    local nms = {}
    for _, gid in ipairs(roster.order or {}) do
        local def = roster.bosses and roster.bosses[gid]
        table.insert(nms, { groupId = gid, label = (def and def.label) or ('Trial Boss ' .. gid) })
    end
    return nms
end

-- Flat index of EVERY trial boss groupId (all tiers) -> its def. onLegendKill
-- uses this so a kill stamps the right gid even if the player swapped main job
-- (hence tier/roster) between summoning a boss and killing it.
local allTrialBosses = {}
for gid, def in pairs(cfg.trialBosses or {}) do
    allTrialBosses[gid] = def
end
if cfg.trialScaling and cfg.trialScaling.tiers then
    for _, t in ipairs(cfg.trialScaling.tiers) do
        if t.roster and t.roster.bosses then
            for gid, def in pairs(t.roster.bosses) do
                allTrialBosses[gid] = def
            end
        end
    end
end

-----------------------------------
-- Trial bookkeeping (account-wide). Counts how many of the CURRENT tier's
-- roster NMs have been (re)killed since the last ascension, and whether that
-- meets the gate. The roster is resolved from the current job's prestige level.
-----------------------------------
local function trialStatus(player)
    local nms = rosterNms(currentRoster(getLevel(player)))
    local done, total = 0, #nms
    local missing = {}
    for _, nm in ipairs(nms) do
        if (player:getCharVar('Prestige_Trial_' .. nm.groupId) or 0) ~= 0 then
            done = done + 1
        else
            table.insert(missing, nm.label)
        end
    end
    local need = cfg.trial.requireAll and total or cfg.trial.requireCount
    return done, total, need, missing
end

local function trialMet(player)
    local done, _, need = trialStatus(player)
    return done >= need
end

-----------------------------------
-- Next uncleared Trial boss for this cycle, in the CURRENT tier's roster order.
-- Returns groupId, bossDef -- or nil, nil when the whole Court is down and the
-- player may ascend.
-----------------------------------
local function nextTrialBoss(player)
    local roster = currentRoster(getLevel(player))
    for _, gid in ipairs(roster.order or {}) do
        if (player:getCharVar('Prestige_Trial_' .. gid) or 0) == 0 then
            return gid, (roster.bosses and roster.bosses[gid]) or nil
        end
    end
    return nil, nil
end

-----------------------------------
-- PER-JOB MOD APPLICATION
-- addMod/delMod live in the entity's in-memory modifier map. A zone-in wipes
-- it; a no-zone job change does NOT. So we track which job's mods are live in
-- a LocalVar (PrestigeModJob) and swap them whenever the active job differs.
--
-- Invariant that keeps add/remove balanced: a job's category CharVars only
-- ever change (via tryBuy) while that job is the live one, so reading them
-- back at removal time yields exactly what was added.
--
-- Categories support two forms:
--   cat.mod  = xi.mod.X          -- single mod (most categories)
--   cat.mods = { xi.mod.X, ... } -- multiple mods, each gets the same delta
--     (used for ELRES / SKILL which must update many mod slots at once)
-----------------------------------
-- Overflow-proof additive grant (ported from Legendary e605736222): clamp a
-- mod's running TOTAL to +/-31000 so a raw addMod can never wrap the int16
-- mod store (m_modStat). SIGN-AWARE by construction: positive amounts clamp
-- toward +cap, negative amounts (Phys.DT-/Mag.DT-, perLevel -100) toward
-- -cap. NOTE: Legendary's first version floored adds at 0 and silently
-- discarded negative grants -- do not reintroduce a positive-only clamp.
local function safeClampAdd(cur, amount, cap)
    if amount >= 0 then
        return math.max(0, math.min(amount, cap - cur))   -- never push above +cap
    end
    return math.min(0, math.max(amount, -cap - cur))      -- never push below -cap
end

local function safeAddMod(entity, modId, amount, cap)
    cap = cap or 31000
    local add = safeClampAdd(entity:getMod(modId), amount, cap)
    if add ~= 0 then entity:addMod(modId, add) end
end

-- Clamp removal to this system's own contribution, sign-aware: never strip
-- past 0 in either direction (a strip of a negative grant must not ADD).
local function _delClamp(cur, delta)
    if delta >= 0 then
        return math.min(delta, math.max(0, cur))
    end
    return math.max(delta, math.min(0, cur))
end

local function _modAdd(player, cat, delta)
    if cat.mods then
        for _, mod in ipairs(cat.mods) do
            safeAddMod(player, mod, delta)
        end
    elseif cat.mod then
        safeAddMod(player, cat.mod, delta)
    end
end

local function _modDel(player, cat, delta)
    if cat.mods then
        for _, mod in ipairs(cat.mods) do
            player:delMod(mod, _delClamp(player:getMod(mod), delta))
        end
    elseif cat.mod then
        player:delMod(cat.mod, _delClamp(player:getMod(cat.mod), delta))
    end
end

-- Multiplicative EXP cut % for a prestige level: linear, caps at expPenaltyMaxCut
-- at expPenaltyMaxLevel (mirrors Job Rebirth). The engine applies it AFTER additive
-- EXP_BONUS via the [PrestigeExpCut] charVar, so +EXP augments can't cancel it.
local function expCut(lv)
    if (lv or 0) <= 0 then return 0 end
    return math.min(math.floor(lv / cfg.expPenaltyMaxLevel * cfg.expPenaltyMaxCut + 0.5), cfg.expPenaltyMaxCut)
end

local function applyJobMods(player, jobId)
    for _, cat in ipairs(cfg.categories) do
        local lv = player:getCharVar(catKey(jobId, cat.id)) or 0
        if lv > 0 then
            _modAdd(player, cat, lv * cat.perLevel)
        end
    end
    -- EXP penalty REMOVED (relaunch, owner request 2026-06-25): Ascension no longer
    -- reduces EXP gain. Always clear [PrestigeExpCut] so the engine applies no prestige
    -- exp malus. (expCut() above is now unused/dead; left in place for history.)
    player:setCharVar('[PrestigeExpCut]', 0)
end

local function removeJobMods(player, jobId)
    for _, cat in ipairs(cfg.categories) do
        local lv = player:getCharVar(catKey(jobId, cat.id)) or 0
        if lv > 0 then
            _modDel(player, cat, lv * cat.perLevel)
        end
    end
    -- Clear the EXP cut; the new main job's applyJobMods re-stamps its own.
    player:setCharVar('[PrestigeExpCut]', 0)
end

-- Make the live mods match the current main job. Cheap no-op when unchanged
-- (the common case on gear-change calls), a swap when the job actually moved.
local function refreshJobMods(player)
    local cur     = player:getMainJob()
    local applied = player:getLocalVar('PrestigeModJob')
    if applied == cur then
        return
    end
    if applied ~= 0 then
        removeJobMods(player, applied)
    end
    applyJobMods(player, cur)
    player:setLocalVar('PrestigeModJob', cur)

    -- The addMod/delMod above update the mod map but do NOT recompute the cached,
    -- derived values (Max HP/MP, skills, the stat display). Without this, a zone-in
    -- or job change would leave Max HP/MP showing the pre-prestige pool until the
    -- next gear change forced a recompute. recalculateStats() rebuilds them from
    -- the now-current mod map (CalculateStats resets the base first, so no
    -- compounding). Run AFTER PrestigeModJob is set so any re-entrant gear-set
    -- check this triggers early-returns at the guard above instead of recursing.
    player:recalculateStats()
end

-----------------------------------
-- EXPORTED: stamp Trial progress for a Tier-5 NM kill (account-wide).
-- HuntingLeague.lua calls this only when td.tier >= cfg.unlockTier, but we
-- still verify the groupId is on the Trial roster so unrelated kills are
-- ignored. First stamp per NM per cycle prints progress.
-----------------------------------
m.onLegendKill = function(player, groupId)
    local def = allTrialBosses[groupId]
    if not def then
        return  -- not an Ascension trial boss (e.g. an unrelated HL NM) -- ignore.
    end

    local stampVar = 'Prestige_Trial_' .. groupId
    if (player:getCharVar(stampVar) or 0) == 0 then
        player:setCharVar(stampVar, os.time())

        local done, _, need = trialStatus(player)
        player:printToPlayer(string.format(
            '[Ascension] Trial: %s defeated (%d/%d).',
            def.label or def.name or ('Boss ' .. groupId), math.min(done, need), need),
            xi.msg.channel.SYSTEM_3)

        if done >= need then
            player:printToPlayer(
                '[Ascension] Trial complete! Commune with the Ascension Altar to ascend.',
                xi.msg.channel.SYSTEM_3)
        end
    end
end

-----------------------------------
-- ALTAR NPC + MENUS
-----------------------------------
m:addOverride(cfg.zonePath .. '.Zone.onInitialize', function(zone)
    super(zone)

    -- Menu state shared across rebuilds (mirrors the Augment Sage pattern).
    local menu = { title = '', options = {} }

    -- Forward decls so the build/try functions can reference one another.
    local buildMainMenu, buildStatusMenu, buildAscendMenu, buildSpendMenu

    -- "Face the Trial" support. summonNextTrial is assigned below (forward
    -- decl here so buildMainMenu's option can capture it as an upvalue).
    -- summonedTrial tracks the one live Trial boss per player (keyed by char
    -- id) so the option can't stack adds; cleared in the boss's onMobDeath.
    local summonNextTrial
    local summonedTrial = {}
    -- Spawn anchors for secondary altars (index matches PrestigeAltIdx localVar).
    -- 0 = primary (near player), 1 = Altar II, 2 = Altar III.
    local ALTAR_ANCHORS =
    {
        [1] = { x = -161.7446, y =  -0.0117, z = -685.5436 },  -- Altar II
        [2] = { x = -279.2352, y =   0.2092, z = -790.8884 },  -- Altar III
    }
    xi._prestige_summonedTrial = summonedTrial  -- exposed for !resettrial to clear stale/stuck entries (modules/custom/commands/resettrial.lua)

    -----------------------------------
    -- Ascension. Validates gate -> level cap -> trial -> mark cost, then
    -- spends marks, clears the trial stamps, bumps THIS JOB's level, grants
    -- AP to this job, and announces server-wide.
    -----------------------------------
    local function tryAscend(player)
        local jobId = curJob(player)

        local tier = getTier(player)
        if tier < cfg.unlockTier then
            player:printToPlayer(string.format(
                '[Ascension] The Altar is dormant. Reach Hunting League tier %d to ascend.',
                cfg.unlockTier), xi.msg.channel.SYSTEM_3)
            buildMainMenu(player)
            return
        end

        local level = getLevel(player)
        if cfg.maxLevel and level >= cfg.maxLevel then
            player:printToPlayer(string.format(
                '[Ascension] %s has reached the maximum Prestige Level (%d).',
                jobTag(jobId), cfg.maxLevel), xi.msg.channel.SYSTEM_3)
            buildMainMenu(player)
            return
        end

        if not trialMet(player) then
            local done, _, need, missing = trialStatus(player)
            player:printToPlayer(string.format(
                '[Ascension] Trial incomplete (%d/%d). Slay: %s',
                done, need, table.concat(missing, ', ')),
                xi.msg.channel.SYSTEM_3)
            buildMainMenu(player)
            return
        end

        local cost  = markCost(level)
        local marks = getMarks(player)
        if marks < cost then
            player:printToPlayer(string.format(
                '[Ascension] You need %d %s to ascend %s (you have %d).',
                cost, cfg.markName, jobTag(jobId), marks), xi.msg.channel.SYSTEM_3)
            buildMainMenu(player)
            return
        end

        -- All requirements met -- perform the ascension for this job.
        player:setCharVar(cfg.markVar, marks - cost)
        -- Clear the stamps of the roster you just cleared (this job's current
        -- tier). Crossing into a new tier next level naturally starts a fresh
        -- cycle -- the new Court's bosses have their own, still-unstamped gids.
        for _, nm in ipairs(rosterNms(currentRoster(level))) do
            player:setCharVar('Prestige_Trial_' .. nm.groupId, 0)
        end

        local newLevel = level + 1
        local apGrant  = apForLevel(newLevel)
        player:setCharVar(levelKey(jobId), newLevel)
        player:setCharVar(apKey(jobId), getAP(player) + apGrant)
        player:setCharVar(apLifeKey(jobId),
            (player:getCharVar(apLifeKey(jobId)) or 0) + apGrant)
        player:setCharVar('Prestige_Ascensions_Total',
            (player:getCharVar('Prestige_Ascensions_Total') or 0) + 1)

        -- Track lifetime ascensions and fire achievement checks.
        local totalAsc = (player:getCharVar('Prestige_Total_Ascensions') or 0) + 1
        player:setCharVar('Prestige_Total_Ascensions', totalAsc)
        local ach = require('modules/custom/lua/achievements')
        ach.onAscension(player)

        player:printToPlayer(string.format(
            '[Ascension] Your %s ascends to Prestige Level %d!  +%d %s to spend.',
            jobTag(jobId), newLevel, apGrant, cfg.apName),
            xi.msg.channel.SYSTEM_3)
        -- Server-wide ascend broadcast silenced 2026-06-23 (owner request);
        -- the personal "Your %s ascends..." line above is KEPT (reward feedback).
        -- Set ANNOUNCE_ASCEND = true to restore the server-wide announcement.
        local ANNOUNCE_ASCEND = false
        if ANNOUNCE_ASCEND then
            player:printToArea(string.format(
                '[Ascension] %s has ascended their %s to Prestige Level %d!',
                player:getName(), jobTag(jobId), newLevel),
                xi.msg.channel.SYSTEM_3, xi.msg.area.SYSTEM, '', false)
        end

        -- Warn the player when THIS ascension pushes the Trial into a harder
        -- difficulty tier (cfg.trialScaling). Compare the old level's bracket to
        -- the new one's; announce only on an actual step up, so a deadlier Court
        -- is never a silent surprise at the next summon.
        local oldTier = trialTier(level)
        local newTier = trialTier(newLevel)
        if newTier and (not oldTier or newTier.minLevel > oldTier.minLevel) then
            player:printToPlayer(string.format(
                '[Ascension] The Trial changes -- a new Court rises to bar your path: %s. Steel yourself before you next Face the Trial.',
                newTier.name or 'a deadlier Court'),
                xi.msg.channel.SYSTEM_3)
        end

        buildMainMenu(player)
    end

    -----------------------------------
    -- Buy one level in a spend category for the current job. Charges this
    -- job's AP, bumps the per-job CharVar, and applies the per-level delta
    -- immediately IF this job's mods are the live ones (they are, at the
    -- altar) so it takes effect without a zone change.
    -----------------------------------
    local function tryBuy(player, cat, page)
        local jobId = curJob(player)
        local lv    = getCatLevel(player, cat.id)
        if lv >= cat.cap then
            player:printToPlayer(string.format(
                '[Ascension] %s is already maxed (%d/%d).',
                cat.label, lv, cat.cap), xi.msg.channel.SYSTEM_3)
            buildSpendMenu(player, page)
            return
        end

        local ap = getAP(player)
        if ap < cat.apCost then
            player:printToPlayer(string.format(
                '[Ascension] Not enough %s: need %d, have %d.',
                cfg.apName, cat.apCost, ap), xi.msg.channel.SYSTEM_3)
            buildSpendMenu(player, page)
            return
        end

        player:setCharVar(apKey(jobId), ap - cat.apCost)
        player:setCharVar(catKey(jobId, cat.id), lv + 1)

        -- Only nudge the live mod map if this job's mods are the applied set
        -- (always true at the altar). Otherwise the next refresh applies it.
        if player:getLocalVar('PrestigeModJob') == jobId then
            _modAdd(player, cat, cat.perLevel)
            -- Most mods (STR, ACC, ATT...) are read live from the mod map by the
            -- combat formulas, so they bite the instant they're added. But the
            -- CACHED, derived values are NOT refreshed by addMod alone:
            --   * Max HP / Max MP  -- Mod::HP/HPP feed UpdateHealth; the health
            --                         POOL is recomputed, not read live.
            --   * skill levels     -- the Skills menu / effective hit rate.
            --   * the stat NUMBERS the client shows.
            -- recalculateStats() rebuilds skills + stats + health from the (now
            -- updated) mod map AND pushes the new values to the client, so a Max
            -- HP / Max MP / All Skills buy SHOWS and WORKS immediately -- no zoning.
            -- CalculateStats resets the base before re-applying mods, so repeat
            -- calls never compound; it only READS the mod map, so it never double-
            -- applies or wipes the prestige mods. (This was the Max HP bug -- the
            -- buy added Mod::HP but never recomputed the cached health pool.)
            player:recalculateStats()
        end

        player:printToPlayer(string.format(
            '[Ascension] %s -> %d/%d (%s).  %s left: %d.',
            cat.label, lv + 1, cat.cap, cat.note, cfg.apName, ap - cat.apCost),
            xi.msg.channel.SYSTEM_3)

        buildSpendMenu(player, page)
    end

    -----------------------------------
    -- Spend-AP submenu (paginated). 16 categories at 4/page keeps the row
    -- count (4 + up to 2 nav + Back = 7) under the customMenu visible cap.
    -----------------------------------
    local SPEND_PAGE_SZ = 4

    buildSpendMenu = function(player, page)
        page = page or 1
        local totalPages = math.max(1, math.ceil(#cfg.categories / SPEND_PAGE_SZ))
        page = math.max(1, math.min(page, totalPages))

        local startIdx = (page - 1) * SPEND_PAGE_SZ + 1
        local endIdx   = math.min(startIdx + SPEND_PAGE_SZ - 1, #cfg.categories)

        local options = {}
        for i = startIdx, endIdx do
            local cat = cfg.categories[i]
            local lv  = getCatLevel(player, cat.id)
            local costTag = (cat.apCost or 1) > 1 and string.format(' [%dAP]', cat.apCost or 1) or ''
            local menuLabel = cat.label .. costTag
            -- e.g. "STR 3/15 1A"  (kept short for the 150-byte menu cap)
            local label = string.format('%s %d/%d',
                menuLabel, lv, cat.cap)
            table.insert(options, {
                label,
                function(p) tryBuy(p, cat, page) end,
            })
        end

        if totalPages > 1 then
            if page > 1 then
                table.insert(options, {
                    string.format('<< %d/%d', page - 1, totalPages),
                    function(p) buildSpendMenu(p, page - 1) end,
                })
            end
            if page < totalPages then
                table.insert(options, {
                    string.format('%d/%d >>', page + 1, totalPages),
                    function(p) buildSpendMenu(p, page + 1) end,
                })
            end
        end

        table.insert(options, { '<< Back', function(p) buildMainMenu(p) end })

        -- Title carries the job so the player always knows whose AP they spend.
        menu.title   = string.format('%s %s: %d',
            jobTag(curJob(player)), cfg.apName:sub(1, 2), getAP(player))
        menu.options = options
        local snapshot = { title = menu.title, options = menu.options }  -- shared table + deferred send
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    -----------------------------------
    -- Ascend submenu -- shows the three requirements + a confirm row.
    -- The readout rows simply re-render the menu when clicked.
    -----------------------------------
    buildAscendMenu = function(player)
        local jobId = curJob(player)
        local level = getLevel(player)
        local cost  = markCost(level)
        local marks = getMarks(player)
        local tier  = getTier(player)
        local done, _, need = trialStatus(player)

        local options =
        {
            {
                string.format('Tier %d/%d', tier, cfg.unlockTier),
                function(p) buildAscendMenu(p) end,
            },
            {
                string.format('Trial %d/%d', math.min(done, need), need),
                function(p) buildAscendMenu(p) end,
            },
            {
                string.format('Cost %d (have %d)', cost, marks),
                function(p) buildAscendMenu(p) end,
            },
            {
                string.format('>> Ascend %s to Lv %d', jobTag(jobId), level + 1),
                function(p) tryAscend(p) end,
            },
            {
                '<< Back',
                function(p) buildMainMenu(p) end,
            },
        }

        menu.title   = string.format('Ascend %s (P%d)', jobTag(jobId), level)
        menu.options = options
        local snapshot = { title = menu.title, options = menu.options }  -- shared table + deferred send
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    -----------------------------------
    -- Status readout (chat), then back to the main menu.
    -----------------------------------
    buildStatusMenu = function(player)
        local jobId = curJob(player)
        local level = getLevel(player)
        local ap    = getAP(player)
        local cost  = markCost(level)
        local marks = getMarks(player)
        local done, _, need = trialStatus(player)

        player:printToPlayer(string.format(
            '[Ascension] %s Prestige Level: %d  |  %s: %d',
            jobTag(jobId), level, cfg.apName, ap), xi.msg.channel.SYSTEM_3)
        player:printToPlayer(string.format(
            '  Trial: %d/%d  |  Next ascension: %d %s (have %d)',
            math.min(done, need), need, cost, cfg.markName, marks),
            xi.msg.channel.SYSTEM_3)

        -- Current Trial difficulty tier + the next step-up, so the player can
        -- always check from the Altar how hard the Court is now and what level
        -- raises it next. Skipped silently when scaling is disabled.
        local curTier = trialTier(level)
        if curTier then
            local line = string.format('  Trial Court: %s', curTier.name or '??')
            local nextTier
            for _, t in ipairs(cfg.trialScaling.tiers) do
                if t.minLevel > level and (not nextTier or t.minLevel < nextTier.minLevel) then
                    nextTier = t
                end
            end
            if nextTier then
                line = line .. string.format('  ->  %s at Prestige Lv.%d', nextTier.name or '??', nextTier.minLevel)
            else
                line = line .. '  (final Court reached)'
            end
            player:printToPlayer(line, xi.msg.channel.SYSTEM_3)
        end

        local parts = {}
        for _, cat in ipairs(cfg.categories) do
            local lv = getCatLevel(player, cat.id)
            if lv > 0 then
                table.insert(parts, string.format('%s %d', cat.id, lv))
            end
        end
        if #parts > 0 then
            player:printToPlayer('  ' .. jobTag(jobId) .. ' Boosts: ' .. table.concat(parts, ', '),
                xi.msg.channel.SYSTEM_3)
        else
            player:printToPlayer('  No boosts purchased on ' .. jobTag(jobId) .. ' yet -- choose Spend AP.',
                xi.msg.channel.SYSTEM_3)
        end

        buildMainMenu(player)
    end

    -----------------------------------
    -- "Face the Trial": summon the next uncleared Nightmare Court boss right
    -- where the summoner stands (at the Altar). One live boss per player at a
    -- time. Uses the EXACT Hunting
    -- League insertDynamicEntity pattern -- minLevel/maxLevel + detection are
    -- REQUIRED (else lv255/unhittable, no aggro), and mods + hpBoost are
    -- applied AFTER spawn() (spawn recalculates stats from the pool). The
    -- boss's onMobDeath frees the slot and stamps Trial progress via the same
    -- m.onLegendKill hook the Hunting League uses, so the existing
    -- ascend/clear bookkeeping just works.
    -----------------------------------
    summonNextTrial = function(player)
        if getTier(player) < cfg.unlockTier then
            player:printToPlayer(string.format(
                '[Ascension] The Trial is sealed until Hunting League tier %d (Legend).',
                cfg.unlockTier), xi.msg.channel.SYSTEM_3)
            return
        end

        local pid    = player:getID()
        local active = summonedTrial[pid]
        if active and active.alive then
            player:printToPlayer(string.format(
                '[Ascension] %s already stalks the void -- face what you have summoned.',
                active.label), xi.msg.channel.SYSTEM_3)
            return
        end

        local gid, boss = nextTrialBoss(player)
        if not gid or not boss then
            player:printToPlayer(
                '[Ascension] The Nightmare Court is vanquished. Commune with the Altar to ascend.',
                xi.msg.channel.SYSTEM_3)
            return
        end

        -- [LEGENDARY] Spawn the boss next to the summoner ("the game master"), not
        -- at a fixed arena point. The old hardcoded cfg.trialSpawnPos (-624, -20,
        -- -519.999) dropped the boss below the arena floor / off the platform, so
        -- it kept appearing "off map" (under the platform, down in the void). The
        -- summoner is provably on valid floor at the Altar, so we anchor to their
        -- LIVE position and use the EXACT working GameMaster-wave pattern: a small
        -- ring around the player (random angle, cfg.trialSpawnGap yalms out) at the
        -- player's OWN Y -- which sits on the floor, never below it. trialSpawnPos
        -- stays as a fallback if the position read ever fails.
        -- PrestigeAltIdx > 0 means a secondary altar triggered; anchor spawn
        -- at that altar's fixed position. Clear the flag immediately.
        local altIdx = player:getLocalVar('PrestigeAltIdx')
        player:setLocalVar('PrestigeAltIdx', 0)

        local sp     = cfg.trialSpawnPos
        local anchor = ALTAR_ANCHORS[altIdx]
        local px     = anchor and anchor.x or player:getXPos()
        if px then
            local py    = anchor and anchor.y or player:getYPos()
            local pz    = anchor and anchor.z or player:getZPos()
            local angle = math.random() * math.pi * 2
            local dist  = cfg.trialSpawnGap or 2.5
            sp = {
                x   = px + math.cos(angle) * dist,
                y   = py,
                z   = pz + math.sin(angle) * dist,
                rot = math.random(0, 255),
            }
        end

        -- idleDespawned: set before calling setHP(0) in the idle watcher so
        -- onMobDeath skips kill credit even if C++ resolves a non-nil killer
        -- from prior enmity on the programmatic kill.
        local idleDespawned = false

        -- Hardcore NM mechanics engine (stance dance / AoE / adds / drain / doom /
        -- enrage / phases). Cached require; the per-Court config is attached below.
        local mechanics = require('modules/custom/lua/mob_mechanics_library')

        local mob = zone:insertDynamicEntity({
            objtype              = xi.objType.MOB,
            groupId              = gid,
            groupZoneId          = cfg.trialBossZoneId,
            name                 = boss.name,
            x                    = sp.x,
            y                    = sp.y,
            z                    = sp.z,
            rotation             = sp.rot,
            minLevel             = boss.level,
            maxLevel             = boss.level,
            detection            = xi.detects.SIGHT_AND_HEARING,
            isAggroable          = true,
            releaseIdOnDisappear = true,

            onMobDeath = function(deadMob, killer, optParams)
                mechanics.cleanup(deadMob)
                summonedTrial[pid] = nil
                if killer and not idleDespawned then
                    m.onLegendKill(killer, gid)
                    -- Tier-gated augment catalyst (soft gating): Prestige trial
                    -- bosses (the Tier-3 augment gate is Prestige Lv15) drop
                    -- Tier-3 catalysts. See augment_catalyst_pools.lua.
                    require('modules/custom/lua/augment_catalyst_pools').roll(killer, 3)
                end
            end,

            -- Mechanics ride the combat tick (all pcall-guarded in the library).
            onMobFight = function(mfMob, mfTarget)
                mechanics.tick(mfMob, mfTarget)
            end,
        })

        if not mob then
            player:printToPlayer(string.format(
                '[Ascension] The void rejects %s (groupId %d missing from mob_groups?).',
                boss.label, gid), xi.msg.channel.SYSTEM_3)
            return
        end

        mob:setSpawn(sp.x, sp.y, sp.z, sp.rot)
        mob:spawn()
        -- Capacity/Job Points INTENTIONALLY enabled (2026-06-14): single-target
        -- trial boss -> a deliberate, difficulty-scaled JP source. (Was
        -- NO_CAPACITY_POINTS=1; multi-mob wave/add systems still set the flag.)

        -- Difficulty scaling: the Court rises with the prestige LEVEL of the job
        -- being ascended (discrete tiers in cfg.trialScaling). The tier `mult`
        -- multiplies HP + the offensive mod set; raw DEF scales gentler (defFactor)
        -- so the fight is deadlier, not spongier. tier/mult stay in scope for the
        -- summon announce below. mult 1 (tier nil) = untouched baseline.
        local ts      = cfg.trialScaling
        local tier    = trialTier(getLevel(player))
        local mult    = (tier and tier.mult) or 1
        local defMult = 1 + (mult - 1) * ((ts and ts.defFactor) or 1)

        local scaleSet = {}
        if ts and ts.scaleMods then
            for _, mId in ipairs(ts.scaleMods) do
                scaleSet[mId] = true
            end
        end

        if boss.mods then
            for modId, value in pairs(boss.mods) do
                local v = value
                if ts and ts.defMod and modId == ts.defMod then
                    v = math.floor(value * defMult)
                elseif scaleSet[modId] then
                    v = math.floor(value * mult)
                end
                -- Mods are int16: a value >32767 wraps NEGATIVE (boss spawns weaker,
                -- not harder -- Tier 4/5 ATT 36k-47k was hitting for ~0). Clamp <=31000,
                -- leaving headroom for buffs/mechanics that addMod on top. Catches both
                -- too-high catalog bases and scaled values.
                mob:setMod(modId, math.min(v, 31000))
            end
        end
        if boss.hpBoost then
            local newMax = math.floor(mob:getMaxHP() * boss.hpBoost * mult)
            mob:setMaxHP(newMax)
            mob:setHP(newMax)
        end

        -- Attach the highest mechanics package at or below the current level.
        -- Empowerment-only tiers (P80/P90) inherit the P60 Wardens mechanics
        -- just as they inherit that roster, rather than silently becoming vanilla.
        local tierMech = ts and ts.tierMechanics
        if tierMech then
            local level = getLevel(player)
            local mechMinLevel = -1
            local mechCfg
            for minLevel, candidate in pairs(tierMech) do
                if type(minLevel) == 'number' and minLevel <= level and minLevel > mechMinLevel then
                    mechMinLevel = minLevel
                    mechCfg = candidate
                end
            end

            mechanics.attach(mob, mechCfg)
        end

        summonedTrial[pid] = { alive = true, label = boss.label, gid = gid }

        -- Summon announcements: the summoner flavor ("You have summoned X.
        -- Survive." + the boss cry + the Court line) AND the server-wide
        -- "%s has summoned %s within Provenance!" broadcast. Silenced
        -- 2026-06-23 by owner request (chat clutter). Set true to restore.
        local ANNOUNCE_SUMMON = false
        if ANNOUNCE_SUMMON then
            player:printToPlayer(string.format(
                '[Ascension] You have summoned %s. Survive.', boss.label),
                xi.msg.channel.SYSTEM_3)
            if boss.cry then
                player:printToPlayer('  ' .. boss.cry, xi.msg.channel.SYSTEM_3)
            end
            if tier then
                local courtLine = string.format('  This Court: %s.', tier.name or '??')
                if mult > 1 then
                    courtLine = courtLine .. string.format('  (Empowered x%.2f.)', mult)
                end
                player:printToPlayer(courtLine, xi.msg.channel.SYSTEM_3)
            end
            player:printToArea(string.format(
                '[Ascension] %s has summoned %s within Provenance!',
                player:getName(), boss.label),
                xi.msg.channel.SYSTEM_3, xi.msg.area.SYSTEM, '', false)
        end

        -- Idle-despawn: if the boss stands UNENGAGED with no damage dealt for
        -- 20 seconds it retreats without awarding kill credit, and the player's
        -- summon slot is freed so they can try again. Engaged counts as
        -- challenged: Medusa petrifies pets for 60-180s (Gorgon Dance /
        -- Calcifying Deluge), so a pet-only player deals no damage for well
        -- over 20s mid-fight -- the boss must not retreat out of an active fight.
        local IDLE_SECONDS = 20
        local lastHp       = mob:getMaxHP()
        local idleSecs     = 0

        local function watchIdle()
            if summonedTrial[pid] == nil then return end  -- already dead or cleared

            -- Zone guard: if the player has left Provenance the dynamic mob entity may
            -- have been freed from C++ memory when the zone went to sleep. pcall cannot
            -- catch a C++ SIGSEGV from a dangling pointer -- bail before touching mob.
            local inZone = false
            pcall(function() inZone = player:getZone():getID() == 222 end)
            if not inZone then
                summonedTrial[pid] = nil
                return
            end

            -- Player KO check: if the player died to the boss, despawn without
            -- awarding kill credit and free the slot so they can re-summon after a raise.
            local playerHP = 0
            local phOk     = pcall(function() playerHP = player:getHP() end)
            if phOk and playerHP == 0 then
                idleDespawned      = true
                summonedTrial[pid] = nil
                player:printToPlayer(string.format(
                    '[Ascension] %s withdraws as you fall. Rise again and face the Trial.',
                    boss.label), xi.msg.channel.SYSTEM_3)
                pcall(function() mob:setHP(0) end)
                return
            end

            local curHp   = 0
            local engaged = false
            local ok      = pcall(function()
                curHp   = mob:getHP()
                engaged = mob:isEngaged()
            end)
            if not ok or curHp <= 0 then return end      -- mob gone

            if curHp < lastHp or engaged then
                lastHp   = curHp
                idleSecs = 0
            else
                idleSecs = idleSecs + 5
            end

            if idleSecs >= IDLE_SECONDS then
                idleDespawned      = true
                summonedTrial[pid] = nil
                player:printToPlayer(string.format(
                    '[Ascension] %s retreats into the void unchallenged. You may summon it again when ready.',
                    boss.label), xi.msg.channel.SYSTEM_3)
                pcall(function() mob:setHP(0) end)
                return
            end

            player:timer(5000, watchIdle)
        end

        player:timer(5000, watchIdle)
    end

    -----------------------------------
    -- Main menu (Status / [Face the Trial] / Ascend / Spend AP / Close)
    -- The Trial row only appears while you are Legend AND the cycle's Court is
    -- still standing, so it self-hides once you've cleared it for the cycle.
    -----------------------------------
    buildMainMenu = function(player)
        local jobId = curJob(player)
        local level = getLevel(player)
        local ap    = getAP(player)

        local options =
        {
            {
                string.format('Check Status (%s %d)', cfg.apName:sub(1, 2), ap),
                function(p) buildStatusMenu(p) end,
            },
        }

        if getTier(player) >= cfg.unlockTier and not trialMet(player) then
            local _, boss = nextTrialBoss(player)
            local bossName = (boss and boss.name) or 'the Court'
            table.insert(options, {
                string.format('Face the Trial (%s)', bossName),
                function(p) summonNextTrial(p) end,
            })
        end

        table.insert(options, {
            'Ascend',
            function(p) buildAscendMenu(p) end,
        })
        table.insert(options, {
            'Spend AP',
            function(p) buildSpendMenu(p, 1) end,
        })
        table.insert(options, {
            'Close',
            function(p) p:printToPlayer('The Altar grows quiet, ascendant.', xi.msg.channel.SYSTEM_3) end,
        })

        menu.title   = string.format('Ascension Altar [%s P%d]', jobTag(jobId), level)
        menu.options = options
        local snapshot = { title = menu.title, options = menu.options }  -- shared table + deferred send
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    -----------------------------------
    -- ALTAR ENTITY
    --   Continues the existing Hunt NPC row in Reisenjima Henge: same
    --   look (2430) + STAR_LARGE marker as the Seals / Spawner NPCs, placed
    --   just left of them (catalog altarPos.x = -9.5139).
    -----------------------------------
    local _p = cfg.altarPos
    local Altar = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Ascension_Altar',
        packetName = string.format('%sAscension Altar', xi.icon.STAR_LARGE),
        look       = 70,
        x          = _p.x,
        y          = _p.y,
        z          = _p.z,
        rotation   = _p.rot,
        widescan   = 1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('The Altar accepts no offerings -- use the menu to ascend.',
                xi.msg.channel.SYSTEM_3)
        end,

        onTrigger = function(player, npc)
            player:setLocalVar('PrestigeAltIdx', 0)  -- clear secondary-spawn flag
            -- Hard gate: the Altar only awakens at Hunting League Legend.
            local tier = getTier(player)
            if tier < cfg.unlockTier then
                player:printToPlayer(string.format(
                    '[Ascension] The Altar lies dormant. Reach Hunting League tier %d (Legend) to awaken it. You are tier %d.',
                    cfg.unlockTier, tier), xi.msg.channel.SYSTEM_3)
                return
            end
            player:timer(50, function(p) buildMainMenu(p) end)
        end,
    })
    utils.unused(Altar)

    -----------------------------------
    -- SECONDARY ALTAR (Altar II)
    -- Overflow/crowded-area spawn anchor at (-161.7446, -0.0117, -685.5436).
    -- Identical menu to the primary Altar; sets PrestigeAltIdx=1 so summonNextTrial
    -- anchors the boss spawn at this location instead of near the player.
    -----------------------------------
    local Altar2 = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Ascension_Altar_2',
        packetName = string.format('%sAscension Altar II', xi.icon.STAR_LARGE),
        look       = 71,
        x          = -161.7446,
        y          =   -0.0117,
        z          = -685.5436,
        rotation   =  88,
        widescan   =  1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('The Altar accepts no offerings -- use the menu to ascend.',
                xi.msg.channel.SYSTEM_3)
        end,

        onTrigger = function(player, npc)
            local tier = getTier(player)
            if tier < cfg.unlockTier then
                player:printToPlayer(string.format(
                    '[Ascension] The Altar lies dormant. Reach Hunting League tier %d (Legend) to awaken it. You are tier %d.',
                    cfg.unlockTier, tier), xi.msg.channel.SYSTEM_3)
                return
            end
            player:setLocalVar('PrestigeAltIdx', 1)
            player:timer(50, function(p) buildMainMenu(p) end)
        end,
    })
    utils.unused(Altar2)

    -----------------------------------
    -- TERTIARY ALTAR (Altar III)
    -- Second overflow anchor at (-279.2352, 0.2092, -790.8884).
    -----------------------------------
    local Altar3 = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Ascension_Altar_3',
        packetName = string.format('%sAscension Altar III', xi.icon.STAR_LARGE),
        look       = 81,
        x          = -279.2352,
        y          =    0.2092,
        z          = -790.8884,
        rotation   =  223,
        widescan   =  1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('The Altar accepts no offerings -- use the menu to ascend.',
                xi.msg.channel.SYSTEM_3)
        end,

        onTrigger = function(player, npc)
            local tier = getTier(player)
            if tier < cfg.unlockTier then
                player:printToPlayer(string.format(
                    '[Ascension] The Altar lies dormant. Reach Hunting League tier %d (Legend) to awaken it. You are tier %d.',
                    cfg.unlockTier, tier), xi.msg.channel.SYSTEM_3)
                return
            end
            player:setLocalVar('PrestigeAltIdx', 2)
            player:timer(50, function(p) buildMainMenu(p) end)
        end,
    })
    utils.unused(Altar3)
end)

-----------------------------------
-- PERSISTENT MOD RE-APPLICATION (zone-in)
-- A zone-in wipes the entity's in-memory mods AND we cannot trust the
-- LocalVar to have survived, so we force "nothing applied" (PrestigeModJob=0)
-- BEFORE super runs. super -> player.lua -> checkForGearSet -> refreshJobMods
-- then applies the current job's mods exactly once; the trailing refresh is a
-- no-op safety net if that chain ever changes.
-----------------------------------
m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    -- DEFER the re-apply ~3s -- applying addMods at the bare onGameIn moment is
    -- clobbered by the engine's post-login stat finalization (same reason
    -- RealLevel_Tracker / auto_buff_henge defer; matches the JobRebirth fix).
    -- Synchronous apply silently lost Ascension boosts after a zone (enspell etc.
    -- dropping to ~gear-only). Login/zone wiped the old mods, so this clean
    -- force-reapply is correct, never a double.
    player:timer(3000, function(p)
        p:setLocalVar('PrestigeModJob', 0)
        refreshJobMods(p)
    end)
end)

-----------------------------------
-- JOB-CHANGE MOD SWAP (no re-zone)
-- xi.gear_sets.checkForGearSet fires on zone-in (via onGameIn), on job change
-- (0x100 handler, AFTER the job id is updated), and on gear changes. super()
-- runs the real gear-set logic (a separate mod channel), then we reconcile
-- prestige mods to the active job. The guard in refreshJobMods makes the
-- frequent gear-change calls a cheap no-op.
-----------------------------------
m:addOverride('xi.gear_sets.checkForGearSet', function(player)
    super(player)
    refreshJobMods(player)
end)

return m
