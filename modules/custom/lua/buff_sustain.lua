-----------------------------------
-- buff_sustain.lua
--
-- Shared sustain math + effect application for !buff and auto-buff hooks.
-- Keep all potency rules here so they cannot drift between call sites.
-----------------------------------
local M = {}

M.DURATION = 18000 -- 5 hours

function M.regionalEffect(region)
    if region <= xi.region.JEUNO then
        return xi.effect.SIGNET, 'Signet'
    elseif region >= xi.region.WEST_AHT_URHGAN and region <= xi.region.ALZADAAL then
        return xi.effect.SANCTION, 'Sanction'
    elseif region >= xi.region.RONFAURE_FRONT and region <= xi.region.VALDEAUNIA_FRONT then
        return xi.effect.SIGIL, 'Sigil'
    elseif region == xi.region.ADOULIN_ISLANDS or region == xi.region.EAST_ULBUKA then
        return xi.effect.IONIS, 'Ionis'
    end
    return xi.effect.SIGNET, 'Signet'
end

function M.powers(maxHP, maxMP, level)
    local refreshPower = level < 99
        and math.max(1, math.floor(maxMP * 0.10))
        or 10

    local regenRate = level < 99 and 0.10 or (0.10 * 0.35)
    local regenPower = math.max(1, math.floor(maxHP * regenRate))

    local regainPower = math.max(1, math.floor(level / 10))

    return refreshPower, regenPower, regainPower
end

function M.apply(player, origin)
    origin = origin or player

    local refreshPower, regenPower, regainPower = M.powers(
        player:getMaxHP(),
        player:getMaxMP(),
        player:getMainLvl())

    local duration = M.DURATION
    local regionalId, regionalName = M.regionalEffect(player:getCurrentRegion())

    player:addStatusEffect(regionalId, { power = 1, duration = duration, origin = origin, tick = 3, subType = 0, subPower = 0 })
    player:addStatusEffect(xi.effect.REGEN, { power = regenPower, duration = duration, origin = origin, tick = 3, subType = 0, subPower = 0 })
    player:addStatusEffect(xi.effect.REFRESH, { power = refreshPower, duration = duration, origin = origin, tick = 3, subType = 0, subPower = 0 })
    player:addStatusEffect(xi.effect.REGAIN, { power = regainPower, duration = duration, origin = origin, tick = 3, subType = 0, subPower = 0 })
    player:addStatusEffect(xi.effect.COMPOSURE, { power = 1, duration = duration, origin = origin, tick = 0, subType = 0, subPower = 0 })
    player:addStatusEffect(xi.effect.RERAISE, { power = 3, duration = duration, origin = origin, tick = 0, subType = 0, subPower = 0 })

    return regionalName, refreshPower, regenPower, regainPower
end

return M
