-----------------------------------
-- Legendary Open World Scaling
-----------------------------------
require('modules/module_utils')
require('scripts/globals/mobs')

local catalog = require('modules/custom/lua/open_world_scaling_catalog')
local m       = Module:new('legendary_open_world_scaling')

xi.openWorldScaling = xi.openWorldScaling or {}
local scaling       = xi.openWorldScaling
local reiveIdsByZone = {}

local function isExcluded(exclusions, key, value)
    return exclusions[key] and exclusions[key][value] == true
end

local function isDynamicEntity(mob)
    -- Dynamic entities occupy targids 0x700-0x8FF. Use the entity's actual
    -- targid: the low bits of a static database mob ID are not guaranteed to
    -- match its targid (for example, the Inner Ra'Kaznar 5x spawn rows).
    local targid = mob:getTargID()
    return targid >= 0x700 and targid < 0x900
end

local function isReiveEntity(mob)
    local zoneId   = mob:getZoneID()
    local zoneData = xi.reives and xi.reives.zoneData and xi.reives.zoneData[zoneId]
    if not zoneData then
        return false
    end

    if not reiveIdsByZone[zoneId] then
        local ids = {}
        for _, reive in pairs(zoneData.reive or {}) do
            for _, mobId in pairs(reive.mob or {}) do
                ids[mobId] = true
            end

            for _, mobId in pairs(reive.obstacles or {}) do
                ids[mobId] = true
            end
        end

        reiveIdsByZone[zoneId] = ids
    end

    return reiveIdsByZone[zoneId][mob:getID()] == true
end

local function copyProfile(profile)
    local result =
    {
        name      = profile.name,
        hpFloor   = profile.hpFloor,
        modFloors = {},
    }

    for modId, value in pairs(profile.modFloors or {}) do
        result.modFloors[modId] = value
    end

    return result
end

local function applyPatch(profile, patch)
    if not profile then
        return nil
    end

    if not patch then
        return profile
    end

    if patch.enabled == false then
        return nil
    end

    if patch.name then
        profile.name = patch.name
    end

    if patch.hpFloor then
        profile.hpFloor = patch.hpFloor
    end

    for modId, value in pairs(patch.modFloors or {}) do
        profile.modFloors[modId] = value
    end

    return profile
end

function scaling.getLevelProfile(level)
    for _, profile in ipairs(catalog.levelProfiles) do
        if level >= profile.minLevel and level <= profile.maxLevel then
            return profile
        end
    end

    return nil
end

function scaling.checkEligibility(mob)
    if not catalog.enabled then
        return false, 'disabled'
    end

    if not mob or mob:getObjType() ~= xi.objType.MOB then
        return false, 'not-mob'
    end

    local level = mob:getMainLvl()
    if level < catalog.minLevel then
        return false, 'below-min-level'
    end

    local zoneId = mob:getZoneID()
    if not catalog.eligibleZones[zoneId] then
        return false, 'zone-not-allowlisted'
    end

    if
        mob:isNM() or
        mob:isMobType(xi.mobType.UNUSED) or
        mob:isMobType(xi.mobType.FISHED) or
        mob:isMobType(xi.mobType.CALLED) or
        mob:isMobType(xi.mobType.BATTLEFIELD) or
        mob:isMobType(xi.mobType.EVENT)
    then
        return false, 'special-mob-type'
    end

    if mob:getInstance() or mob:getBattlefield() or mob:getMaster() then
        return false, 'encounter-or-owned'
    end

    if mob:isInDynamis() or isDynamicEntity(mob) or isReiveEntity(mob) then
        return false, 'non-field-entity'
    end

    if
        mob:getMobMod(xi.mobMod.CHECK_AS_NM) > 0 or
        mob:getMobMod(xi.mobMod.NO_CAPACITY_POINTS) > 0 or
        mob:getMobMod(xi.mobMod.NO_DROPS) > 0 or
        mob:getLocalVar('OWS_EXCLUDE') > 0
    then
        return false, 'explicit-runtime-exclusion'
    end

    local exclusions = catalog.exclusions
    if
        isExcluded(exclusions, 'zoneIds', zoneId) or
        isExcluded(exclusions, 'speciesIds', mob:getSpecies()) or
        isExcluded(exclusions, 'poolIds', mob:getPool()) or
        isExcluded(exclusions, 'mobIds', mob:getID())
    then
        return false, 'catalog-exclusion'
    end

    return true, 'eligible'
end

function scaling.resolveProfile(mob)
    local baseProfile = scaling.getLevelProfile(mob:getMainLvl())
    if not baseProfile then
        return nil
    end

    local profile   = copyProfile(baseProfile)
    local zoneId    = mob:getZoneID()
    local speciesId = mob:getSpecies()
    local poolId    = mob:getPool()
    local mobId     = mob:getID()
    local zone      = catalog.zoneOverrides[zoneId]

    profile = applyPatch(profile, zone and zone.default)
    profile = applyPatch(profile, catalog.speciesOverrides[speciesId])
    profile = applyPatch(profile, catalog.poolOverrides[poolId])
    profile = applyPatch(profile, zone and zone.speciesOverrides and zone.speciesOverrides[speciesId])
    profile = applyPatch(profile, zone and zone.poolOverrides and zone.poolOverrides[poolId])
    profile = applyPatch(profile, zone and zone.mobOverrides and zone.mobOverrides[mobId])
    profile = applyPatch(profile, catalog.mobOverrides[mobId])

    return profile
end

function scaling.apply(mob)
    local eligible, reason = scaling.checkEligibility(mob)
    if not eligible then
        if catalog.debug and mob then
            printf('[OpenWorldScaling] skip %s: %s', mob:getName(), reason)
        end

        return false, reason
    end

    local profile = scaling.resolveProfile(mob)
    if not profile then
        return false, 'no-profile'
    end

    local previousMaxHP = mob:getMaxHP()
    if profile.hpFloor and previousMaxHP < profile.hpFloor then
        mob:setMaxHP(profile.hpFloor)
        mob:setHP(profile.hpFloor)
    end

    for modId, floor in pairs(profile.modFloors) do
        if mob:getMod(modId) < floor then
            mob:setMod(modId, floor)
        end
    end

    if catalog.debug then
        printf(
            '[OpenWorldScaling] %s Lv%d profile=%s HP=%d->%d',
            mob:getName(),
            mob:getMainLvl(),
            profile.name or 'unnamed',
            previousMaxHP,
            mob:getMaxHP())
    end

    return true, profile
end

-- Stable, reload-safe assignment: reloading replaces one function reference
-- rather than registering another listener or stacking another wrapper.
xi.mob.openWorldScalingHook = function(mob)
    scaling.apply(mob)
end

return m
