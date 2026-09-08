-----------------------------------
-- dynamis_hundred_piece.lua
--
-- Extra Dynamis currency: every mixin kill has a flat 1% chance (no Treasure
-- Hunter) to drop the zone / family 100-piece.
--
--   Sandy  -> Ranperre Goldpiece
--   Bastok -> One Hundred Byne Bill
--   Windy  -> Lungo-Nango Jadeshell
--   Jeuno  -> one shared 1% pool among those three
--   Beauc / Xarc -> match the singles the mob already drops
--   Dreamland nightmares -> current Vana 8-hour window (same blocks as procs)
--
-- FileWatcher-safe. Mixins call tryDrop on death.
-----------------------------------
local KEY = 'modules/custom/lua/dynamis_hundred_piece'
local M = package.loaded[KEY]
if type(M) ~= 'table' then
    M = {}
end
package.loaded[KEY] = M

M.CHANCE_PERCENT = 1

M.HUNDRED_BY_SINGLE =
{
    [xi.item.TUKUKU_WHITESHELL  ] = xi.item.LUNGO_NANGO_JADESHELL,
    [xi.item.ORDELLE_BRONZEPIECE] = xi.item.RANPERRE_GOLDPIECE,
    [xi.item.ONE_BYNE_BILL      ] = xi.item.ONE_HUNDRED_BYNE_BILL,
}

M.JEUNO_POOL =
{
    xi.item.RANPERRE_GOLDPIECE,
    xi.item.ONE_HUNDRED_BYNE_BILL,
    xi.item.LUNGO_NANGO_JADESHELL,
}

M.CITY_ZONE_HUNDRED =
{
    [xi.zone.DYNAMIS_SAN_DORIA] = xi.item.RANPERRE_GOLDPIECE,
    [xi.zone.DYNAMIS_BASTOK   ] = xi.item.ONE_HUNDRED_BYNE_BILL,
    [xi.zone.DYNAMIS_WINDURST ] = xi.item.LUNGO_NANGO_JADESHELL,
}

M.JEUNO_ZONES =
{
    [xi.zone.DYNAMIS_JEUNO] = true,
}

-- Nightmare singles rotate on these windows. Vanguard in the same zones
-- stay on family currency via dynamis_beastmen.
function M.dreamlandSingle(hour)
    hour = hour or 0
    if hour >= 16 then
        return xi.item.ORDELLE_BRONZEPIECE
    end

    if hour >= 8 then
        return xi.item.ONE_BYNE_BILL
    end

    return xi.item.TUKUKU_WHITESHELL
end

function M.hundredItem(zoneId, singleCurrency, pick)
    local city = M.CITY_ZONE_HUNDRED[zoneId]
    if city then
        return city
    end

    if M.JEUNO_ZONES[zoneId] then
        local choose = pick or math.random
        return M.JEUNO_POOL[choose(#M.JEUNO_POOL)]
    end

    return M.HUNDRED_BY_SINGLE[singleCurrency]
end

function M.tryDrop(mob, killer, singleCurrency)
    if not mob or not killer then
        return false
    end

    if math.random(1, 100) > M.CHANCE_PERCENT then
        return false
    end

    local itemId = M.hundredItem(mob:getZoneID(), singleCurrency)
    if not itemId then
        return false
    end

    -- Already won the 1% roll. addTreasure default rate is a guaranteed pool add.
    killer:addTreasure(itemId, mob)
    return true
end

return M
