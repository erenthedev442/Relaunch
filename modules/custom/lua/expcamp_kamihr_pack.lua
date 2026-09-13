-----------------------------------
-- Clone 40 Ashen Tigers onto !expcamp 22 the same way Bibiki's
-- Capacity Phantom camp works: insertDynamicEntity from the retail
-- Ashen Tiger group. The 12 DAT-correct retail slots stay in SQL.
--
-- If a stock client shows a blank / NPC name plate on the clones,
-- overlay Kamihr's entity DAT in the launcher and copy the Ashen
-- Tiger name into the dynamic targid range (0x700+). The model
-- still comes from pool 4809.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Kamihr_Drifts/Zone')

local catalog = require('modules/custom/lua/expcamp_kamihr_catalog')

local m = Module:new('expcamp_kamihr_pack')

local campZone
local staleRespawnSeconds = math.max(60, (catalog.respawnSeconds or 60) + 45)

local function applyCampFlags(mob, index)
    mob:setLocalVar('ExpCampPack', 1)
    mob:setLocalVar('OWS_EXCLUDE', 1)
    if index then
        mob:setLocalVar('ExpCampIndex', index)
    end

    mob:setMobMod(xi.mobMod.NO_CAPACITY_POINTS, 1)
    mob:setMobMod(xi.mobMod.NO_DROPS, 1)
    if catalog.maxHP and catalog.maxHP > 0 then
        mob:setMaxHP(catalog.maxHP)
        mob:setHP(catalog.maxHP)
    end
end

local function spawnAt(index, point)
    if not campZone or not point then
        return
    end

    local mob = campZone:insertDynamicEntity({
        objtype              = xi.objType.MOB,
        groupId              = catalog.groupId,
        groupZoneId          = catalog.groupZoneId,
        name                 = catalog.mobName,
        x                    = point.x,
        y                    = point.y,
        z                    = point.z,
        rotation             = point.rot,
        minLevel             = catalog.minLv,
        maxLevel             = catalog.maxLv,
        detection            = xi.detects.SIGHT_AND_HEARING,
        isAggroable          = true,
        respawn              = catalog.respawnSeconds,
        releaseIdOnDisappear = false,

        onMobSpawn = function(spawned)
            spawned:setLocalVar('ExpCampDiedAt', 0)
            applyCampFlags(spawned, index)
        end,

        onMobDeath = function(deadMob)
            campZone = deadMob:getZone()
            if deadMob:getLocalVar('ExpCampDiedAt') == 0 then
                deadMob:setLocalVar('ExpCampDiedAt', GetSystemTime())
            end
        end,
    })

    if not mob then
        print(string.format('[expcamp_kamihr_pack] insertDynamicEntity failed at index %d', index))
        return
    end

    mob:setSpawn(point.x, point.y, point.z, point.rot)
    mob:spawn()
end

local function ensurePopulation()
    if not campZone then
        return
    end

    local existing = campZone:queryEntitiesByName(catalog.queryName)
    local used     = {}
    local now      = GetSystemTime()

    for _, mob in ipairs(existing or {}) do
        local index = mob:getLocalVar('ExpCampIndex')
        if index > 0 then
            used[index] = true
        end

        if not mob:isAlive() then
            local diedAt = mob:getLocalVar('ExpCampDiedAt')
            local stale  = not mob:isSpawned() and
                (diedAt == 0 or now - diedAt >= staleRespawnSeconds)

            if stale then
                mob:setRespawnTime(0)
                mob:spawn()
                mob:setRespawnTime(catalog.respawnSeconds)
            end
        end
    end

    if existing and #existing >= catalog.dynamicCount then
        return
    end

    for index, point in ipairs(catalog.dynamicPoints) do
        if not used[index] then
            spawnAt(index, point)
        end
    end
end

m:addOverride(catalog.zonePath .. '.Zone.onInitialize', function(zone)
    super(zone)
    campZone = zone
    ensurePopulation()
end)

m:addOverride(catalog.zonePath .. '.Zone.onZoneIn', function(player, prevZone)
    local cs = super(player, prevZone)
    campZone = player:getZone()
    ensurePopulation()
    return cs
end)

pcall(function()
    local zone = GetZone(catalog.zoneId)
    if zone then
        campZone = zone
        ensurePopulation()
    end
end)

return m
