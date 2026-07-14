-----------------------------------
-- Persists NM time of deaths to the database. They must be added to the list here
-- to get this extra behavior.
-- This is useful if you don't want players rushing to NM spawns after a server
-- restart or a crash (or trying to force crashes/restarts to get NM pops)
-----------------------------------
require('modules/module_utils')
-----------------------------------
local m = Module:new('persist_nm_time_of_deaths')

-- NOTE: These names are as they are as filenames.
-- Example: Behemoth's Dominion => Behemoths_Dominion
-- Example: King Behemoth       => King_Behemoth
-- { zone name, mob name, function to generate respawn time}
-- Format:
local nmsToPersist =
{
    -- Behemoth (Behemoths_Dominion) entry removed 2026-07-13. The onMobDespawn
    -- addOverride below targets xi.zones.<Z>.mobs.<M>.onMobDespawn, which is
    -- lazy-loaded (C++ CacheLuaObjectFromFile only fires when the mob first
    -- spawns). Behemoth never pre-cached pre-boot -> override silently failed
    -- for 8+ days per the map-server log. The Zone.onInitialize half worked
    -- (that hook target IS eagerly loaded) but the ToD-save half never fired,
    -- so restored ToDs came from an eternally-stale server var.
    -- To re-enable: hook via xi.mob.onMobDeathEx (real engine hook) or attach
    -- a DEATH listener from Zone.onInitialize -- both actually fire.
}

-- NOTE: At the time we iterate over these entries, the Lua zone and mob objects won't be ready,
--     : so we deal with everything as strings for now.
for _, entry in pairs(nmsToPersist) do
    local zoneName    = entry[1]
    local mobName     = entry[2]
    local varName     = '[Respawn]' .. mobName
    local respawnFunc = entry[3]

    m:addOverride(string.format('xi.zones.%s.mobs.%s.onMobDespawn', zoneName, mobName),
    function(mob)
        super(mob)

        local respawn = respawnFunc()
        mob:setRespawnTime(respawn)
        SetServerVariable(varName, (GetSystemTime() + respawn))
        print(string.format('Writing respawn time to server vars: %s %i', mob:getName(), respawn))
    end)

    m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', zoneName),
    function(zone)
        super(zone)

        local mob = zone:queryEntitiesByName(mobName)[1]
        if mob == nil then
            print(string.format('[persist_nm] %s not found in %s on init', mobName, zoneName))
            return
        end
        local respawn = GetServerVariable(varName)
        print(string.format('Getting respawn time from server vars: %s %i', mob:getName(), respawn))

        if GetSystemTime() < respawn then
            xi.mob.updateNMSpawnPoint(mob)
            mob:setRespawnTime(respawn - GetSystemTime())
        else
            SpawnMob(mob:getID())
        end
    end)
end

return m
