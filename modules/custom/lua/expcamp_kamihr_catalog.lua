-----------------------------------
-- !expcamp 22 Kamihr Ashen Tiger pack.
-- 12 retail slots stay on the north-south path. 40 more are cloned
-- the same way as Bibiki Capacity Phantoms (insertDynamicEntity).
-- Total 52.
-----------------------------------

local catalog = {}

catalog.zoneId   = xi.zone.KAMIHR_DRIFTS
catalog.zonePath = 'xi.zones.Kamihr_Drifts'
catalog.mobName  = 'Ashen_Tiger'
catalog.queryName = 'DE_Ashen_Tiger'

-- Retail group 13 / pool 4809. HP, level, and respawn are overridden
-- at spawn so this still matches the SQL camp pack.
catalog.groupId     = 13
catalog.groupZoneId = 267
catalog.minLv       = 105
catalog.maxLv       = 105
catalog.maxHP       = 30000
catalog.respawnSeconds = 60

-- 12 retail Kamihr Ashen Tiger IDs. Positions live in expcamp_camps.sql
-- and are also relocated by !expcamp.
catalog.retailIds =
{
    17871008, 17871009, 17871010, 17871020, 17871019, 17871021,
    17871013, 17871014, 17871023, 17871024, 17870997, 17870998,
}

local north = { x = 162.8919, y = 20.0000, z = 316.8826 }
local bend  = { x = 155.6881, y = 20.0487, z = 239.8582 }
local west  = { x =  74.8336, y = 20.1391, z = 235.8724 }

local function line(count, a, b, rot, startT, endT)
    local points = {}
    for i = 0, count - 1 do
        local t = startT + (endT - startT) * (count == 1 and 0 or i / (count - 1))
        points[#points + 1] =
        {
            x   = a.x + t * (b.x - a.x),
            y   = a.y + t * (b.y - a.y),
            z   = a.z + t * (b.z - a.z),
            rot = rot,
        }
    end

    return points
end

-- 20 inclusive on the north-south path. 20 more on the west path,
-- starting after the shared bend so two tigers do not stack there.
catalog.northSouthPoints = line(20, north, bend, 64, 0, 1)
catalog.westPoints       = line(20, bend, west, 128, 1 / 20, 1)

catalog.dynamicPoints = {}
for _, point in ipairs(catalog.northSouthPoints) do
    catalog.dynamicPoints[#catalog.dynamicPoints + 1] = point
end
for _, point in ipairs(catalog.westPoints) do
    catalog.dynamicPoints[#catalog.dynamicPoints + 1] = point
end

catalog.dynamicCount = #catalog.dynamicPoints
catalog.totalCount   = #catalog.retailIds + catalog.dynamicCount

-- insertDynamicEntity never copies superFamilyID, so clones do not
-- join the retail tiger party. We emulate family link at this radius.
catalog.linkRadius = 10

catalog.retailIdSet = {}
for _, id in ipairs(catalog.retailIds) do
    catalog.retailIdSet[id] = true
end

return catalog
