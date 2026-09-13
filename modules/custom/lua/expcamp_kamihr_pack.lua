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
local linkRadius          = catalog.linkRadius or 10
local sightRange          = catalog.sightRange or 15
local facingCone          = catalog.facingCone or 64
-- Bump when the ENGAGE closure changes so FileWatcher can replace it.
local linkHookGen         = 2

local function eachCampTiger(fn)
    for _, id in ipairs(catalog.retailIds) do
        fn(GetMobByID(id))
    end

    if not campZone then
        return
    end

    for _, mob in ipairs(campZone:queryEntitiesByName(catalog.queryName) or {}) do
        fn(mob)
    end
end

-- Dynamic mobs never get superFamilyID, so they never join the retail
-- Ashen Tiger party. Emulate C++ CanLink instead of a radius-only
-- cascade: facing the engaged tiger inside 10y, or facing the player
-- inside sight range.
local function canSee(looker, subject)
    return looker and subject and looker.isFacing and looker:isFacing(subject, facingCone)
end

local function shouldLink(other, engaged, target)
    if canSee(other, engaged) and other:checkDistance(engaged) <= linkRadius then
        return true
    end

    if target and target.isAlive and target:isAlive() and
        canSee(other, target) and other:checkDistance(target) <= sightRange
    then
        return true
    end

    return false
end

local function linkNearby(mob, target)
    if not mob or not target or not target.isAlive or not target:isAlive() then
        return
    end

    eachCampTiger(function(other)
        if not other or other:getID() == mob:getID() then
            return
        end

        if not other:isAlive() or other:isEngaged() then
            return
        end

        if not shouldLink(other, mob, target) then
            return
        end

        pcall(function()
            other:updateEnmity(target)
        end)
    end)
end

local function attachLinkHook(mob)
    if not mob or not mob.addListener then
        return
    end

    if mob:getLocalVar('ExpCampLinkHook') == linkHookGen then
        return
    end

    -- Replace the radius-only v1 hook. This runs from FileWatcher /
    -- zone-in, not from inside ENGAGE.
    pcall(function()
        mob:removeListener('EXPCAMP_KAMIHR_LINK')
    end)
    mob:addListener('ENGAGE', 'EXPCAMP_KAMIHR_LINK', function(engaged, target)
        linkNearby(engaged, target)
    end)
    mob:setLocalVar('ExpCampLinkHook', linkHookGen)
end

local function applyCampFlags(mob, index)
    mob:setLocalVar('ExpCampPack', 1)
    mob:setLocalVar('OWS_EXCLUDE', 1)
    if index then
        mob:setLocalVar('ExpCampIndex', index)
    end

    mob:setLink(1)
    mob:setMobMod(xi.mobMod.NO_CAPACITY_POINTS, 1)
    mob:setMobMod(xi.mobMod.NO_DROPS, 1)
    if catalog.maxHP and catalog.maxHP > 0 then
        mob:setMaxHP(catalog.maxHP)
        mob:setHP(catalog.maxHP)
    end

    attachLinkHook(mob)
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

    for _, id in ipairs(catalog.retailIds) do
        attachLinkHook(GetMobByID(id))
    end

    local existing = campZone:queryEntitiesByName(catalog.queryName)
    local used     = {}
    local now      = GetSystemTime()

    for _, mob in ipairs(existing or {}) do
        local index = mob:getLocalVar('ExpCampIndex')
        if index > 0 then
            used[index] = true
        end

        attachLinkHook(mob)

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
