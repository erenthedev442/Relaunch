-----------------------------------
-- affinity_nm_autopop.lua
--
-- Keeps the 24 Augment-Sage affinity-hunt NMs always up.
--
-- WHY THIS EXISTS
-- ---------------
-- affinity_nm_spawns.sql places the 24 affinity NMs as 900s timed spawns,
-- but each one REUSES a retail NM's zone + name, so it inherits that retail
-- mob script. Those scripts override our intent in two ways:
--   * onMobInitialize calls mob:setRespawnTime(<hours>) -- e.g. Simurgh
--     random(3600,7200) = 1-2h; Behemoth/Fafnir/gods = up to 21-72h. So
--     after a server restart the NM sits on a multi-hour retail timer and
--     never appears on the 900s we wanted.
--   * onMobDespawn re-sets that long timer on every death, so a one-time
--     setRespawnTime at zone-init does NOT stick.
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
--      retail 1-2h reset. Result: short repop that survives deaths.
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

-----------------------------------
-- Tuning
-----------------------------------
local RESPAWN_SECONDS = 30  -- repop delay after each death (matches always_popped_nms)

-----------------------------------
-- The 24 affinity NMs grouped by zone.
-- mobid = (zoneid << 12) | (3840 + nmNumber)  -- from affinity_nm_spawns.sql.
-- Each entry: { Zone.onInitialize override path, { mobid, ... } }.
-- Override path is a STRING, so dashes (Riverne-Site_*) are legal.
-----------------------------------
local ZONES =
{
    { 'xi.zones.Batallia_Downs.Zone.onInitialize',          { 433921 } },                                   -- Behemoth
    { 'xi.zones.Behemoths_Dominion.Zone.onInitialize',      { 524034 } },                                   -- King Behemoth
    { 'xi.zones.Kuftal_Tunnel.Zone.onInitialize',           { 716547 } },                                   -- King Arthro
    { 'xi.zones.Rolanberry_Fields.Zone.onInitialize',       { 454404 } },                                   -- Simurgh
    { 'xi.zones.Valley_of_Sorrows.Zone.onInitialize',       { 528133 } },                                   -- Adamantoise
    { 'xi.zones.The_Shrine_of_RuAvitau.Zone.onInitialize',  { 732934, 732936, 732937, 732942, 732943 } },   -- Genbu/Seiryu/Byakko/Suzaku/Kirin
    { 'xi.zones.Sauromugue_Champaign.Zone.onInitialize',    { 495367 } },                                   -- Roc
    { 'xi.zones.Cape_Teriggan.Zone.onInitialize',           { 466698 } },                                   -- Aspidochelone
    { 'xi.zones.Riverne-Site_B01.Zone.onInitialize',        { 122635 } },                                   -- Ouryu
    { 'xi.zones.The_Boyahda_Tree.Zone.onInitialize',        { 630540 } },                                   -- Bune
    { 'xi.zones.Riverne-Site_A01.Zone.onInitialize',        { 126733 } },                                   -- Phoenix
    { 'xi.zones.Dragons_Aery.Zone.onInitialize',            { 634640, 634641 } },                            -- Fafnir/Nidhogg
    { 'xi.zones.Ifrits_Cauldron.Zone.onInitialize',         { 843538 } },                                   -- Vrtra
    { 'xi.zones.Uleguerand_Range.Zone.onInitialize',        { 24339 } },                                    -- Tiamat
    { 'xi.zones.Western_Altepa_Desert.Zone.onInitialize',   { 515860 } },                                   -- King Vinegarroon
    { 'xi.zones.King_Ranperres_Tomb.Zone.onInitialize',     { 782101, 782102 } },                           -- Khimaira/Cerberus
    { 'xi.zones.RuAun_Gardens.Zone.onInitialize',           { 536343, 536344 } },                           -- Absolute Virtue/Proto-Omega
}

-----------------------------------
-- Force one affinity NM up and keep it on the short timer.
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

    mob:setRespawnTime(RESPAWN_SECONDS)
    if not mob:isSpawned() then
        SpawnMob(mobid)
    end
    return true
end

local function configureZone(mobids, zoneLabel)
    local up = 0
    for _, mobid in ipairs(mobids) do
        local ok = pcall(configureMob, mobid)
        if ok then up = up + 1 end
    end
    printf('[affinity_nm_autopop] %s: %d/%d affinity NM(s) configured', zoneLabel, up, #mobids)
end

-----------------------------------
-- Register a Zone.onInitialize override per affinity zone.
-----------------------------------
for _, info in ipairs(ZONES) do
    local overridePath, mobids = info[1], info[2]
    local zoneLabel = overridePath:match('xi%.zones%.([^.]+)%.') or overridePath
    affinityPop:addOverride(overridePath, function(zone)
        super(zone)
        pcall(configureZone, mobids, zoneLabel)
    end)
end

return affinityPop
