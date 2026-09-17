-----------------------------------
-- ronfaure_s_farm_catalog.lua
-- Capacity Point farm in East Ronfaure [S] (zone 81) -- camp 3.
-- !capacity3 / !capacity ronfaure
--
-- Four player-pinged corners. Random bilinear scatter (not a grid).
-- Models: sheep / goblin / rabbit / beetle. Same HP/level as Bibiki.
-- FileWatcher dofile discards return; mutate the cached table.
-----------------------------------
local KEY = 'modules/custom/lua/ronfaure_s_farm_catalog'
local catalog = package.loaded[KEY]
if type(catalog) ~= 'table' then
    catalog = {}
end
package.loaded[KEY] = catalog

catalog.zoneId   = xi.zone.EAST_RONFAURE_S     -- 81
catalog.zonePath = 'xi.zones.East_Ronfaure_[S]'
catalog.logTag   = 'ronfaure_s_farm'

-- Confirmed standable: north-west corner ping. Keep in sync with
-- commands/capacity.lua and commands/capacity3.lua.
catalog.warpPos = { x = 510.8990, y = -59.5513, z = 471.9462, rot = 92 }

catalog.noSpawnRadius = 15.0

catalog.campCenter = { x = 580.19, y = -54.19, z = 352.29 }
catalog.spreadX    = 40
catalog.spreadZ    = 60
catalog.spawnMinY  = -62
catalog.spawnMaxY  = -47

-- SW / SE / NE / NW from the four !capacity3 pings.
catalog.spawnQuad =
{
    { x = 506.7558, y = -49.5473, z = 285.1306 },
    { x = 636.0772, y = -49.8907, z = 265.0892 },
    { x = 667.0241, y = -57.7777, z = 386.9902 },
    { x = 510.8990, y = -59.5513, z = 471.9462 },
}
catalog.spawnPoints = nil

catalog.resettleOnLoad = false

catalog.groupZoneId = 81
catalog.templates =
{
    { groupId = 13, groupZoneId = 81 }, -- Wild Sheep
    { groupId = 17, groupZoneId = 81 }, -- Goblin Patrolman
    { groupId = 10, groupZoneId = 81 }, -- Forest Hare
    { groupId =  6, groupZoneId = 81 }, -- Scarab Beetle
}

catalog.mobName  = 'Capacity Phantom'
catalog.mobCount = 80
catalog.minLv    = 120
catalog.maxLv    = 150
catalog.maxHP    = 120000
catalog.respawnSeconds = 5
catalog.cpBonus  = 2000

catalog.debug    = true

catalog.soundAggro = true
catalog.soundRange = 10
catalog.sightRange = 10

return catalog
