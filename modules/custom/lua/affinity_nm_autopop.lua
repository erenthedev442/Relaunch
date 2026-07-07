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

-----------------------------------
-- Tuning
-----------------------------------
local RESPAWN_SECONDS = 30  -- repop delay after each death (matches always_popped_nms)
local SYS             = xi.msg.channel.SYSTEM_3

-----------------------------------
-- Difficulty (2026-06-30): the affinity NMs REUSE retail pools, so at their base
-- level they are trivial for geared relaunch players. Bake in a stat block, applied
-- on every spawn. TUNE HERE. Offensive mods are flat additions (setMod, idempotent);
-- HP is scaled once per fresh spawn via setMaxHP.
--   * Mob combat mods are int16 -- keep each < 31000 or they wrap NEGATIVE.
--   * HP via setMaxHP is int32, so the multiplier is the safe "tankier" lever.
--   * UNIFORM across all 24: the god-tier NMs (Kirin/AV/Proto-Omega/4 gods) may end
--     up over-tuned for the HL-rank-3 audience -- add a per-mobid override if so.
-----------------------------------
-- BIG BUMP 2026-07-06 (Duff test: "fairly easy as thf"; owner: increase difficulty).
-- HP is the primary lever (int32 -> longer fights, not one-shots); the flat combat
-- mods stay well under the int16 mob-mod cap (~31000) even stacked on base, so no
-- overflow/wrap. Uniform across all 24; add a per-mobid override later if the
-- god-tier NMs need to outclass Behemoth etc.
local NM_HP_MULT = 12.0
local NM_MODS =
{
    [xi.mod.ATT]           = 6000,
    [xi.mod.ACC]           = 2400,
    [xi.mod.DEF]           = 1800,
    [xi.mod.EVA]           = 1000,
    [xi.mod.MATT]          = 500,
    [xi.mod.MDEF]          = 60,
    [xi.mod.STR]           = 400,
    [xi.mod.DEX]           = 400,
    [xi.mod.HASTE_GEAR]    = 200,   -- ~20% (engine caps gear haste ~25%)
    [xi.mod.DOUBLE_ATTACK] = 25,
    [xi.mod.CRITHITRATE]   = 12,
    [xi.mod.STORETP]       = 50,    -- more frequent TP moves = more real mechanics
}

-----------------------------------
-- The 24 affinity NMs grouped by zone (mobids = current affinity_nm_spawns.sql).
-- Each entry: { Zone.onInitialize override path, { mobid, ... } }.
-- Override path is a STRING, so dashes (Riverne-Site_*) are legal.
-----------------------------------
local ZONES =
{
    { 'xi.zones.Batallia_Downs.Zone.onInitialize',          { 17208197 } },                                       -- Behemoth
    { 'xi.zones.Behemoths_Dominion.Zone.onInitialize',      { 17298310 } },                                       -- King Behemoth
    { 'xi.zones.Kuftal_Tunnel.Zone.onInitialize',           { 17490823 } },                                       -- King Arthro
    { 'xi.zones.Rolanberry_Fields.Zone.onInitialize',       { 17228680 } },                                       -- Simurgh
    { 'xi.zones.Valley_of_Sorrows.Zone.onInitialize',       { 17302409 } },                                       -- Adamantoise
    { 'xi.zones.The_Shrine_of_RuAvitau.Zone.onInitialize',  { 17507219 } },                                       -- Kirin (retail Shrine; 4 gods moved to Ru'Aun Gardens)
    { 'xi.zones.Sauromugue_Champaign.Zone.onInitialize',    { 17269643 } },                                       -- Roc
    { 'xi.zones.Cape_Teriggan.Zone.onInitialize',           { 17240974 } },                                       -- Aspidochelone
    { 'xi.zones.Riverne-Site_B01.Zone.onInitialize',        { 16896911 } },                                       -- Ouryu
    { 'xi.zones.The_Boyahda_Tree.Zone.onInitialize',        { 17404816 } },                                       -- Bune
    { 'xi.zones.Riverne-Site_A01.Zone.onInitialize',        { 16901009 } },                                       -- Phoenix
    { 'xi.zones.Dragons_Aery.Zone.onInitialize',            { 17408916, 17408917 } },                             -- Fafnir/Nidhogg
    { 'xi.zones.Ifrits_Cauldron.Zone.onInitialize',         { 17617814 } },                                       -- Vrtra
    { 'xi.zones.Uleguerand_Range.Zone.onInitialize',        { 16798615 } },                                       -- Tiamat
    { 'xi.zones.Western_Altepa_Desert.Zone.onInitialize',   { 17290136 } },                                       -- King Vinegarroon
    { 'xi.zones.King_Ranperres_Tomb.Zone.onInitialize',     { 17556377, 17556378 } },                             -- Khimaira/Cerberus
    { 'xi.zones.RuAun_Gardens.Zone.onInitialize',           { 17310619, 17310620, 17310621, 17310622, 17310623, 17310624 } }, -- AV/Proto-Omega + Genbu/Seiryu/Byakko/Suzaku (Sky god corners)
}

-- mobid -> Augment-Sage registration trophy item id. Granted directly to the
-- killer on death: the intended droplists (21000-21023, dropid in mob_groups)
-- exceed the engine's MAX_DROPID (5000), so GetDropList rejects them ("DropID
-- too big") and no drop ever rolls. This Lua grant is the working substitute.
local TROPHY =
{
    [17208197] = 860,   [17298310] = 883,   [17490823] = 8983,  [17228680] = 843,    -- Behemoth/K.Beh/K.Arthro/Simurgh
    [17302409] = 908,   [17310621] = 1404,  [17269643] = 842,   [17310622] = 1405,   -- Adamantoise/Genbu/Roc/Seiryu
    [17310623] = 1406,  [17240974] = 2421,  [16896911] = 903,   [17404816] = 2229,   -- Byakko/Aspidochelone/Ouryu/Bune
    [16901009] = 844,   [17310624] = 1407,  [17507219] = 10038, [17408916] = 10037,  -- Phoenix/Suzaku/Kirin/Fafnir
    [17408917] = 865,   [17617814] = 1526,  [16798615] = 1816,  [17290136] = 1017,   -- Nidhogg/Vrtra/Tiamat/K.Vinegarroon
    [17556377] = 2372,  [17556378] = 2169,  [17310619] = 1567,  [17310620] = 15800,  -- Khimaira/Cerberus/AV/Proto-Omega
}

-- Grant the killer this NM's registration trophy (shared by the module + !affinitypop).
local function grantTrophy(m, killer)
    local trophy = TROPHY[m:getID()]
    if not trophy or not killer or not killer:isPC() then
        return
    end
    if killer:getFreeSlotsCount() > 0 then
        killer:addItem(trophy, 1)
        killer:printToPlayer('[Affinity] Obtained the affinity registration trophy!', SYS)
    else
        killer:printToPlayer('[Affinity] Inventory full -- affinity trophy NOT awarded. Make room and rekill.', SYS)
    end
end
xi.affinityAutopop = xi.affinityAutopop or {}
xi.affinityAutopop.grantTrophy = grantTrophy  -- reused by the !affinitypop command

-- mobid -> proper display name. These reused-pool spawns show as "NPC" on the
-- client; renameEntity sets ONLY packetName (+ flags UPDATE_NAME to push it live),
-- it does NOT touch the entity's `name`, so mob:getName() -- which the affinity
-- GRANT matches against -- is unchanged. Purely a display fix.
local NAME =
{
    [17208197] = 'Behemoth',      [17298310] = 'King Behemoth',    [17490823] = 'King Arthro',
    [17228680] = 'Simurgh',       [17302409] = 'Adamantoise',      [17310621] = 'Genbu',
    [17269643] = 'Roc',           [17310622] = 'Seiryu',           [17310623] = 'Byakko',
    [17240974] = 'Aspidochelone', [16896911] = 'Ouryu',            [17404816] = 'Bune',
    [16901009] = 'Phoenix',       [17310624] = 'Suzaku',           [17507219] = 'Kirin',
    [17408916] = 'Fafnir',        [17408917] = 'Nidhogg',          [17617814] = 'Vrtra',
    [16798615] = 'Tiamat',        [17290136] = 'King Vinegarroon', [17556377] = 'Khimaira',
    [17556378] = 'Cerberus',      [17310619] = 'Absolute Virtue',  [17310620] = 'Proto-Omega',
}

local function applyName(m)
    local nm = NAME[m:getID()]
    if nm then
        m:renameEntity(nm, true)  -- silent; sets packetName only
    end
end
xi.affinityAutopop.applyName = applyName  -- reused by the !affinitypop command

-- Apply the difficulty stat block. Offensive mods overwrite (idempotent); HP is
-- scaled ONCE per fresh spawn (guarded by a localVar the SPAWN listener resets), so
-- a re-configure (e.g. !affinitypop) never compounds the multiplier.
local function applyStats(m)
    for modId, val in pairs(NM_MODS) do
        m:setMod(modId, val)
    end
    if NM_HP_MULT > 1.0 and m:getLocalVar('affHpScaled') == 0 then
        local hp = math.floor(m:getMaxHP() * NM_HP_MULT)
        if hp > 0 then
            m:setMaxHP(hp)
            m:setHP(hp)
        end
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

    -- Grant the registration trophy on death (droplist is unusable; see TROPHY note).
    mob:addListener('DEATH', 'AFFINITY_TROPHY', function(m, killer)
        grantTrophy(m, killer)
    end)

    -- Fix the "NPC" display name; re-apply on every spawn (packetName resets are cheap).
    mob:addListener('SPAWN', 'AFFINITY_NAME', function(m)
        applyName(m)
    end)
    if mob:isSpawned() then applyName(mob) end

    -- Difficulty stat block; re-apply on every spawn. Reset the HP-scale guard first
    -- so each fresh spawn re-scales from base HP (SPAWN fires with the mob at base).
    mob:addListener('SPAWN', 'AFFINITY_STATS', function(m)
        m:setLocalVar('affHpScaled', 0)
        m:setMobMod(xi.mobMod.IDLE_DESPAWN, 0)
        applyStats(m)
    end)
    if mob:isSpawned() then applyStats(mob) end

    -- Keep affinity NMs up: the Sky gods (Genbu/Seiryu/Byakko/Suzaku) set a 300s
    -- IDLE_DESPAWN in their retail onMobInitialize, which despawns them whenever
    -- no one is fighting -- churning against this always-up system (Duff test
    -- 2026-07-06: gods self-despawn / ~47s repop delay). Force it off. No-op for
    -- the other 22 NMs, which don't set it.
    mob:setMobMod(xi.mobMod.IDLE_DESPAWN, 0)
    mob:setRespawnTime(RESPAWN_SECONDS)
    if not mob:isSpawned() then
        SpawnMob(mobid)
    end
    return true
end

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
for _, info in ipairs(ZONES) do
    local overridePath, mobids = info[1], info[2]
    local zoneLabel = overridePath:match('xi%.zones%.([^.]+)%.') or overridePath
    affinityPop:addOverride(overridePath, function(zone)
        super(zone)
        pcall(configureZone, mobids, zoneLabel)
    end)
end

return affinityPop
