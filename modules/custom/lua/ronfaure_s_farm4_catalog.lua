-----------------------------------
-- ronfaure_s_farm4_catalog.lua
-- Capacity Point farm in East Ronfaure [S] (zone 81) -- camp 4.
-- !capacity4 / !capacity 4
--
-- Four player-pinged corners south of camp 3. Random bilinear scatter.
-- Colibri + ladybug inland; pugil + river crab toward the water (east).
-- Same HP/level as Bibiki. Separate DE name so the two camps do not share a pool.
-----------------------------------
local KEY = 'modules/custom/lua/ronfaure_s_farm4_catalog'
local catalog = package.loaded[KEY]
if type(catalog) ~= 'table' then
    catalog = {}
end
package.loaded[KEY] = catalog

catalog.zoneId   = xi.zone.EAST_RONFAURE_S     -- 81
catalog.zonePath = 'xi.zones.East_Ronfaure_[S]'
catalog.logTag   = 'ronfaure_s_farm4'

-- Confirmed standable: east/water-side ping. Keep in sync with
-- commands/capacity.lua and commands/capacity4.lua.
catalog.warpPos = { x = 577.1001, y = -51.1170, z = 149.4120, rot = 116 }

catalog.noSpawnRadius = 15.0

catalog.campCenter = { x = 480.05, y = -38.21, z = 22.30 }
catalog.spreadX    = 50
catalog.spreadZ    = 80
catalog.spawnMinY  = -55
catalog.spawnMaxY  = -15

-- SW / SE / NE / NW from the four !capacity4 pings.
-- C (428,-14)  B (491,-153)  A (577,149 water)  D (424,107)
catalog.spawnQuad =
{
    { x = 427.9336, y = -20.0000, z =  -13.9352 },
    { x = 490.8644, y = -32.5300, z = -153.0765 },
    { x = 577.1001, y = -51.1170, z =  149.4120 },
    { x = 424.2923, y = -49.2046, z =  106.7814 },
}

-- Inland air/ground; water models when X is on the river side.
catalog.groupZoneId = 81
catalog.templates =
{
    { groupId =  9, groupZoneId = 81 }, -- Colibri
    { groupId = 14, groupZoneId = 81 }, -- Ladybug
    { groupId =  9, groupZoneId = 81 }, -- Colibri (weight)
    { groupId = 14, groupZoneId = 81 }, -- Ladybug (weight)
}
catalog.waterTemplates =
{
    { groupId = 12, groupZoneId = 81 }, -- Pugil
    { groupId = 11, groupZoneId = 81 }, -- River Crab
    { groupId = 12, groupZoneId = 81 }, -- Pugil
    { groupId = 11, groupZoneId = 81 }, -- River Crab
    { groupId =  9, groupZoneId = 81 }, -- Colibri
    { groupId = 14, groupZoneId = 81 }, -- Ladybug
}
catalog.waterMinX = 520

-- Distinct DE name so camp 3's 80 are not counted as this pool.
-- Client still shows Capacity Phantom.
catalog.mobName    = 'Capacity Phantom 4'
catalog.packetName = 'Capacity Phantom'
catalog.mobCount   = 80
catalog.minLv      = 120
catalog.maxLv      = 150
catalog.maxHP      = 120000
catalog.respawnSeconds = 5
catalog.cpBonus    = 2000

catalog.debug    = true

catalog.soundAggro = true
catalog.soundRange = 10
catalog.sightRange = 10

return catalog
