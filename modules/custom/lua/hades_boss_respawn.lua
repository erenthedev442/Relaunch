-----------------------------------
-- hades_boss_respawn.lua
--
-- Hades daily world bosses are QoL targets, not lottery camps.
-- Same pattern as hunt_nm_respawn_override.lua:
--   * pre-require each mob script so addOverride can attach
--   * last-writer setRespawnTime(1800) on initialize + despawn
--   * zone init: spawn ONE copy if it is down (never a whole table
--     of same-named mobs -- that is how Padfoot's pack would all pop)
-- SQL in hades_boss_respawns.sql flips mob_groups to NORMAL 1800s.
-----------------------------------
require('modules/module_utils')
local catalog = require('modules/custom/lua/hades_catalog')

local m = Module:new('hades_boss_respawn')

local RESPAWN_SECONDS = 1800

local function applyTimer(mob)
    if not mob then
        return
    end
    mob:setRespawnTime(RESPAWN_SECONDS)
    pcall(function()
        mob:setMobMod(xi.mobMod.IDLE_DESPAWN, 0)
    end)
end

local function spawnIfDown(mob)
    if mob and not mob:isSpawned() then
        SpawnMob(mob:getID())
    end
end

-- IDs.lua key: Jaggedy-Eared_Jack -> JAGGEDY_EARED_JACK
local function idKey(boss)
    return boss.idKey or boss.name:upper():gsub('%-', '_')
end

-- One mob id only. Tables (Sophie / Lizzy / Tom Tit Tat twins) yield
-- the first entry so we never force-spawn the whole pack.
local function resolveMobId(boss)
    pcall(require, string.format('scripts/zones/%s/IDs', boss.zone))
    local zoneData = zones[boss.zoneId]
    if not zoneData or not zoneData.mob then
        return nil
    end
    local entry = zoneData.mob[idKey(boss)]
    if type(entry) == 'number' then
        return entry
    end
    if type(entry) == 'table' then
        local first = entry[1] or entry[0]
        if type(first) == 'number' then
            return first
        end
    end
    return nil
end

for _, boss in ipairs(catalog.bosses) do
    local mobPath = string.format('scripts/zones/%s/mobs/%s', boss.zone, boss.name)
    pcall(require, mobPath)
    pcall(require, string.format('scripts/zones/%s/Zone', boss.zone))

    local initHook    = string.format('xi.zones.%s.mobs.%s.onMobInitialize', boss.zone, boss.name)
    local despawnHook = string.format('xi.zones.%s.mobs.%s.onMobDespawn',    boss.zone, boss.name)

    pcall(function()
        m:addOverride(initHook, function(mob)
            super(mob)
            applyTimer(mob)
        end)
    end)

    pcall(function()
        m:addOverride(despawnHook, function(mob)
            super(mob)
            applyTimer(mob)
        end)
    end)
end

local zoneTargets = {}
for _, boss in ipairs(catalog.bosses) do
    zoneTargets[boss.zone] = zoneTargets[boss.zone] or {}
    table.insert(zoneTargets[boss.zone], boss)
end

for zone, bosses in pairs(zoneTargets) do
    pcall(function()
        m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', zone), function(z)
            super(z)
            for _, boss in ipairs(bosses) do
                pcall(function()
                    local mobId = resolveMobId(boss)
                    if mobId then
                        local mob = GetMobByID(mobId)
                        applyTimer(mob)
                        spawnIfDown(mob)
                    end
                end)
            end
        end)
    end)
end

print(string.format(
    '[hades_boss_respawn] 30-min timed spawn armed for %d Hades world bosses',
    #catalog.bosses))

return m
