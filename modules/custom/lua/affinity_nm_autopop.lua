-----------------------------------
-- affinity_nm_autopop.lua
--
-- Keeps the 24 Augment-Sage affinity-hunt NMs always up.
--
-- WHY THIS EXISTS
-- ---------------
-- affinity_nm_spawns.sql places the 24 affinity NMs as 900s timed spawns,
-- but each one REUSES a retail NM's zone + name, so it inherits that retail
-- mob script. Those scripts override our intent:
--   * onMobInitialize calls mob:setRespawnTime(<hours>) -- e.g. Simurgh
--     random(3600,7200) = 1-2h; Behemoth/Fafnir/gods = up to 21-72h. That
--     registers the mob with the spawn handler, so at zone boot it is NOT
--     TrySpawn'd (zoneutils isRegistered check) -- it waits out the retail
--     timer and never appears on the 900s we wanted.
--   * onMobDespawn re-sets that long timer on every death, so a one-time
--     setRespawnTime at zone-init would NOT stick.
-- (Separately, the mobid bug that stopped them instantiating at all was
--  fixed in 689a0a72d7 -- valid ids 0x1000000|(zone<<12)|targid, targid<0x700.)
--
-- FIX
-- ---
-- For each affinity mobid, at its zone's Zone.onInitialize we:
--   1. setRespawnTime(RESPAWN_SECONDS) and SpawnMob() if it's down, so it's
--      up the moment the zone boots after a restart.
--   2. addListener('DESPAWN', ...) that re-applies RESPAWN_SECONDS. The
--      engine fires entity.onMobDespawn FIRST, then DESPAWN listeners
--      (mobentity.cpp OnDespawn: OnMobDespawn -> triggerListener), so our
--      listener is the LAST writer of m_RespawnTime and wins over the
--      retail long-timer reset. Result: short repop that survives deaths.
--
-- Only the 24 affinity mobids are touched -- other NMs in these zones keep
-- their retail behavior (unlike always_popped_nms, which pops EVERY NM in
-- its target zones). See [[always_popped_nms]] for the broader variant.
--
-- NOTE: addOverride patches Zone.onInitialize at module-load, so a server
-- RESTART is required for this to take effect. Use !affinitypop to force
-- the NMs up immediately without a restart.
-----------------------------------
require('modules/module_utils')

local affinityPop = Module:new('affinity_nm_autopop')
affinityPop:setEnabled(true)

local nmCatalog       = require('modules/custom/lua/affinity_nm_catalog')
local affinityCatalog = require('modules/custom/lua/augment_affinity_catalog')

-----------------------------------
-- Tuning
-----------------------------------
local RESPAWN_SECONDS = 30  -- repop delay after each death (matches always_popped_nms)
local SYS             = xi.msg.channel.SYSTEM_3

-----------------------------------
-- Difficulty: all 24 NMs reuse retail pools and retain their safe retail scripts,
-- but the canonical roster assigns an accessible Intro/Standard/Veteran/Apex
-- profile. Offensive mods overwrite (idempotent); HP scales once per fresh spawn.
--   * Mob combat mods are int16 -- keep each < 31000 or they wrap NEGATIVE.
--   * HP is an absolute band pool (catalog.profiles.hp), not a retail multiplier.
-----------------------------------
-- Docs: the stat block below is quoted on docs/endgame/affinity-nms.md
-- ("Difficulty and notes") -- update that section when retuning here.
-- Death-time trophy grants and 24-target collection rewards.
-- History: 88f443b677 (2026-07-11) removed the hand-synced TROPHY table that
-- used to duplicate a killer-only grant here, and re-homed grants in
-- augment_affinity_grants.lua on an `xi.zones.<Zone>.Zone.onMobDeath` hook.
-- That hook was fictitious -- the engine never calls a zone-level onMobDeath
-- (luautils::OnMobDeath routes to xi.mob.onMobDeathEx, InteractionGlobal, and
-- per-mob entity scripts; grep proved zero callers of any Zone.onMobDeath).
-- Result: for ~24h the entire affinity-hunt trophy path was dead, and no
-- registered NM's trophy dropped. Restored here as a mob DEATH listener
-- (which does fire), catalog-driven and fanned to the whole in-zone alliance.
-- Hand THIS in-zone alliance member the NM's registration trophy. Guarded so
-- repeat kills / the alliance fan-out never stack duplicates.
local function grantTrophyToMember(player, row)
    if affinityCatalog.hasAffinity(player, row.cat) then return end   -- already registered
    if player:hasItem(row.trophy.id) then return end                  -- already holding one
    if player:getFreeSlotsCount() < 1 then
        player:printToPlayer(string.format(
            '[Augment] %s dropped a trophy, but your inventory is full -- make room and defeat it again.',
            row.nm:gsub('_', ' ')), SYS)
        return
    end
    player:addItem(row.trophy.id)
    player:printToPlayer(string.format(
        '[Augment] Obtained %s! Take it to the Augment Sage to register the %s affinity (Hunting League Rank %d + %d Hunt Marks).',
        row.trophy.name, row.label, affinityCatalog.affinityRankReq, affinityCatalog.affinityMarkCost), SYS)
end

-- Fan the trophy to every in-zone alliance member (matches the "whole alliance"
-- semantic the dead zone-override was trying to provide). Solo players get a
-- one-element alliance table containing just themselves.
local function normalizeKiller(killer)
    if not killer then
        return nil
    end

    if not killer:isPC() and killer:getAllegiance() == 1 then
        killer = killer:getMaster()
    end

    if killer and killer:isPC() then
        return killer
    end

    return nil
end

local function grantTrophy(m, killer)
    killer = normalizeKiller(killer)
    if not killer then return end
    local row = affinityCatalog.byNm(m:getName())
    if not row or not row.trophy then return end
    local zoneId = m:getZoneID()
    local alliance = killer:getAlliance()
    if alliance then
        for _, member in ipairs(alliance) do
            if member and member:getZoneID() == zoneId then
                grantTrophyToMember(member, row)
            end
        end
    else
        grantTrophyToMember(killer, row)
    end
end

local function addMarks(player, amount)
    player:setCharVar('HL_Points', (player:getCharVar('HL_Points') or 0) + amount)
end

local function awardFirstClear(player, entry)
    if nmCatalog.hasClear(player, entry.index) then
        return false
    end

    nmCatalog.grantClear(player, entry.index)
    local profile = nmCatalog.profiles[entry.band]
    addMarks(player, profile.firstMarks)

    local total     = nmCatalog.clearCount(player)
    local milestone = nmCatalog.milestones[total]
    player:printToPlayer(string.format(
        '[Affinity Hunt] FIRST CLEAR: %s! +%d Hunt Marks. Collection: %d/%d.',
        entry.display, profile.firstMarks, total, #nmCatalog.entries), SYS)

    if milestone then
        addMarks(player, milestone.marks)
        if milestone.title then
            player:addTitle(milestone.title)
        end
        player:printToPlayer(string.format(
            '[Affinity Hunt] %s milestone! +%d Hunt Marks%s',
            milestone.label,
            milestone.marks,
            milestone.title and ' and the Master Hunter title!' or '.'), SYS)
    end

    return true
end

local function awardRepeat(player, entry)
    local today = tonumber(os.date('!%Y%j')) or 0
    if (player:getCharVar(nmCatalog.repeatDayVar) or 0) ~= today then
        player:setCharVar(nmCatalog.repeatDayVar, today)
        player:setCharVar(nmCatalog.repeatMarksVar, 0)
    end

    local earned    = player:getCharVar(nmCatalog.repeatMarksVar) or 0
    local remaining = math.max(0, nmCatalog.repeatDailyCap - earned)
    local profile   = nmCatalog.profiles[entry.band]
    local reward    = math.min(profile.repeatMarks, remaining)
    if reward <= 0 then
        return
    end

    addMarks(player, reward)
    player:setCharVar(nmCatalog.repeatMarksVar, earned + reward)
    player:printToPlayer(string.format(
        '[Affinity Hunt] Repeat clear: %s. +%d Hunt Marks (%d/%d daily).',
        entry.display, reward, earned + reward, nmCatalog.repeatDailyCap), SYS)
end

local function grantProgress(m, killer)
    killer = normalizeKiller(killer)
    local entry = nmCatalog.byId(m:getID())
    if not killer or not entry then
        return
    end

    local killerHadClear = nmCatalog.hasClear(killer, entry.index)
    local alliance       = killer:getAlliance()
    local zoneId         = m:getZoneID()

    if alliance then
        for _, member in ipairs(alliance) do
            if member and member:getZoneID() == zoneId then
                awardFirstClear(member, entry)
            end
        end
    else
        awardFirstClear(killer, entry)
    end

    if killerHadClear then
        awardRepeat(killer, entry)
    end
end

xi.affinityAutopop = xi.affinityAutopop or {}
xi.affinityAutopop.grantTrophy  = grantTrophy
xi.affinityAutopop.grantProgress = grantProgress

-- These reused-pool spawns show as "NPC" on the
-- client; renameEntity sets ONLY packetName (+ flags UPDATE_NAME to push it live),
-- it does NOT touch the entity's `name`, so mob:getName() -- which the affinity
-- GRANT matches against -- is unchanged. Purely a display fix.
local function applyName(m)
    local entry = nmCatalog.byId(m:getID())
    if entry then
        m:renameEntity(entry.display, true)  -- silent; sets packetName only
    end
end
xi.affinityAutopop.applyName = applyName  -- reused by the !affinitypop command

-- Sky god mobid -> its island's yellow-portal offset from PORTAL_OFFSET
-- (RuAun_Gardens). The retail god scripts CLOSE that portal in onMobSpawn and
-- reopen it in onMobDespawn -- correct for short-lived pop NMs, but our gods
-- are always up, so the portals stay permanently shut and the god islands
-- become unreachable (player report 2026-07-10: "sky god teleporters off,
-- no teleport symbol on the platforms"). Re-open right after every spawn:
-- the entity script's onMobSpawn runs BEFORE SPAWN listeners (mobentity.cpp
-- Spawn: OnMobSpawn -> triggerListener), so our listener is the last writer.
local GOD_PORTAL =
{
    [17310622] = 2,   -- Seiryu (SE island)
    [17310621] = 5,   -- Genbu  (NE island)
    [17310623] = 8,   -- Byakko (NW island)
    [17310624] = 11,  -- Suzaku (SW island)
}

local function openGodPortal(m)
    local off = GOD_PORTAL[m:getID()]
    if not off then
        return
    end
    local ids    = zones[xi.zone.RUAUN_GARDENS]
    local portal = ids and GetNPCByID(ids.npc.PORTAL_OFFSET + off)
    if portal then
        portal:setAnimation(xi.anim.OPEN_DOOR)
    end
end
xi.affinityAutopop.openGodPortal = openGodPortal  -- reused by the !affinitypop command

local function clampAffinityControl(entity)
    if not entity then
        return
    end

    for effectId, maxSec in pairs(nmCatalog.ccCaps) do
        pcall(function()
            local effect = entity:getStatusEffect(effectId)
            if effect and effect:getTimeRemaining() > maxSec * 1000 then
                effect:setDuration(maxSec * 1000)
            end
        end)
    end
end

-- Apply the difficulty stat block. Offensive mods overwrite (idempotent); HP is
-- assigned ONCE per fresh spawn (guarded by a localVar the SPAWN listener resets),
-- so a re-configure (e.g. !affinitypop) never compounds the pool.
local function applyStats(m)
    local entry   = nmCatalog.byId(m:getID())
    local profile = entry and nmCatalog.profiles[entry.band]
    if not profile then
        return
    end

    -- Stay idle until a player starts the fight. !affinitynm and zone-in
    -- land on top of these NMs, and ALWAYS_AGGRO retail scripts (Simurgh,
    -- Roc) otherwise lock the player out of trusts / fellows / prep.
    m:setAggressive(false)
    m:setMobMod(xi.mobMod.ALWAYS_AGGRO, 0)
    m:setMobMod(xi.mobMod.NO_AGGRO, 1)

    -- false = keep current HP/MP so CalculateMobStats does not refill a
    -- tiny retail body before we write the band pool.
    m:setMobLevel(nmCatalog.level, false)

    for modId, val in pairs(profile.mods) do
        m:setMod(modId, val)
    end
    if profile.hp and profile.hp > 0 and m:getLocalVar('affHpScaled') == 0 then
        m:setMaxHP(profile.hp)
        m:setHP(profile.hp)
        m:setLocalVar('affHpScaled', 1)
    end
end
xi.affinityAutopop.applyStats = applyStats  -- reused by the !affinitypop command

-----------------------------------
-- Force one affinity NM up, keep it on the short timer, and wire the trophy + name.
-----------------------------------
local function configureMob(mobid)
    local mob = GetMobByID(mobid)
    if not mob then
        return false
    end

    -- Beat the retail onMobDespawn's long-timer reset: our DESPAWN listener
    -- runs after it, so it's the last writer of m_RespawnTime.
    mob:addListener('DESPAWN', 'AFFINITY_AUTOPOP', function(m)
        m:setRespawnTime(RESPAWN_SECONDS)
    end)

    -- On death, grant the Sage trophy where applicable and record collection
    -- progress for every one of the 24 NMs.
    mob:addListener('DEATH', 'AFFINITY_TROPHY', function(m, killer)
        grantTrophy(m, killer)
    end)
    mob:addListener('DEATH', 'AFFINITY_PROGRESS', function(m, killer)
        grantProgress(m, killer)
    end)

    -- Keep Absolute Terror / petrify / Doom / charm on the retail kit, but
    -- clamp lockout length so a solo player can keep acting.
    mob:addListener('COMBAT_TICK', 'AFFINITY_CC_CAP', function(m)
        for _, hate in ipairs(m:getEnmityList() or {}) do
            clampAffinityControl(hate.entity)
        end
    end)

    -- Fix the "NPC" display name; re-apply on every spawn (packetName resets are cheap).
    mob:addListener('SPAWN', 'AFFINITY_NAME', function(m)
        applyName(m)
    end)
    if mob:isSpawned() then applyName(mob) end

    -- Sky gods: undo the retail portal-close so the god islands stay reachable
    -- while the gods are permanently up (no-op for the other 20 NMs).
    mob:addListener('SPAWN', 'AFFINITY_PORTAL', function(m)
        openGodPortal(m)
    end)
    if mob:isSpawned() then openGodPortal(mob) end

    -- Difficulty stat block; re-apply on every spawn. Reset the HP-scale guard first
    -- so each fresh spawn re-scales from base HP (SPAWN fires with the mob at base).
    mob:addListener('SPAWN', 'AFFINITY_STATS', function(m)
        -- Mark this as an affinity autopop NM. King Vinegarroon's mob script
        -- self-despawns on roam outside a sandstorm (retail burrow) -- with the
        -- autopop force-repopping every 30s that becomes a spawn/despawn loop you
        -- can never claim. Its onMobRoam reads this flag to skip the burrow.
        m:setLocalVar('affinityNM', 1)
        m:setLocalVar('affHpScaled', 0)
        m:setMobMod(xi.mobMod.IDLE_DESPAWN, 0)
        local camp = nmCatalog.byId(m:getID())
        if camp then
            m:setSpawn(camp.x, camp.y, camp.z, 0)
            m:setPos(camp.x, camp.y, camp.z, 0)
        end
        applyStats(m)
    end)
    if mob:isSpawned() then mob:setLocalVar('affinityNM', 1); applyStats(mob) end

    -- Keep affinity NMs up: the Sky gods (Genbu/Seiryu/Byakko/Suzaku) set a 300s
    -- IDLE_DESPAWN in their retail onMobInitialize, which despawns them whenever
    -- no one is fighting -- churning against this always-up system (Duff test
    -- 2026-07-06: gods self-despawn / ~47s repop delay). Force it off. No-op for
    -- the other 22 NMs, which don't set it.
    mob:setMobMod(xi.mobMod.IDLE_DESPAWN, 0)

    -- Retail HNM scripts (Simurgh, Roc, kings) call updateNMSpawnPoint in
    -- onMobInitialize / onMobDespawn. That shuffles the replica off the
    -- !affinitynm camp. Pin every spawn to the catalog warp.
    local entry = nmCatalog.byId(mobid)
    if entry then
        mob:setSpawn(entry.x, entry.y, entry.z, 0)
        if mob:isSpawned() then
            mob:setPos(entry.x, entry.y, entry.z, 0)
        end
    end

    mob:setRespawnTime(RESPAWN_SECONDS)
    if not mob:isSpawned() then
        SpawnMob(mobid)
    end
    return true
end
xi.affinityAutopop.configureMob = configureMob

local function configureZone(mobids, zoneLabel)
    local up = 0
    for _, mobid in ipairs(mobids) do
        local ok, found = pcall(configureMob, mobid)
        if ok and found then up = up + 1 end
    end
    printf('[affinity_nm_autopop] %s: %d/%d affinity NM(s) configured', zoneLabel, up, #mobids)
end

-----------------------------------
-- Register a Zone.onInitialize override per affinity zone.
-----------------------------------
local zoneMobs = {}
for _, entry in ipairs(nmCatalog.entries) do
    zoneMobs[entry.zoneOverride] = zoneMobs[entry.zoneOverride] or {}
    table.insert(zoneMobs[entry.zoneOverride], entry.mobId)
end

for overridePath, mobids in pairs(zoneMobs) do
    local zoneLabel = overridePath:match('xi%.zones%.([^.]+)%.') or overridePath
    affinityPop:addOverride(overridePath, function(zone)
        super(zone)
        pcall(configureZone, mobids, zoneLabel)
    end)
end

-- Backfill collection stamps from the 11 live Sage affinities. The Mig11 guard
-- prevents interpreting the retired 24-category field before it is remapped.
affinityPop:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    if (player:getCharVar('Augment_Affinities_Mig11') or 0) ~= 0 then
        nmCatalog.migrateRegisteredClears(player)
    end
end)

return affinityPop
