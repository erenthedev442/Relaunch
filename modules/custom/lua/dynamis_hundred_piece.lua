-----------------------------------
-- dynamis_hundred_piece.lua
--
-- Extra Dynamis currency: mixin kills drop the zone / family 100-piece
-- (no Treasure Hunter). Flat 5% on trash and NMs. White proc still
-- guarantees one extra 100-piece from dynamis_currency_drops.
--
--   Sandy  -> Montiont Silverpiece
--   Bastok -> One Hundred Byne Bill
--   Windy  -> Lungo-Nango Jadeshell
--   Jeuno  -> one shared pool among those three
--   (Ranperre Goldpiece is the Sandy 10,000-piece, not the 100.)
--   Beauc / Xarc / Dreamland -> match the singles that kill already pays
--   (nightmare packs use dynamis_currency; untagged falls back to Vana hour)
--
-- FileWatcher-safe. Mixins call tryDrop on death.
-----------------------------------
local KEY = 'modules/custom/lua/dynamis_hundred_piece'
local M = package.loaded[KEY]
if type(M) ~= 'table' then
    M = {}
end
package.loaded[KEY] = M

M.CHANCE_PERCENT    = 5
M.NM_CHANCE_PERCENT = 5

-- 10,000-pieces. Never a kill drop. Players only get these by trading 100s
-- at Lootblox / Antiquix / Haggleblix (or relic stage trades).
M.FORBIDDEN_10K =
{
    [xi.item.RIMILALA_STRIPESHELL  ] = true,
    [xi.item.RANPERRE_GOLDPIECE    ] = true,
    [xi.item.TEN_THOUSAND_BYNE_BILL] = true,
}

M.HUNDRED_BY_SINGLE =
{
    [xi.item.TUKUKU_WHITESHELL  ] = xi.item.LUNGO_NANGO_JADESHELL,
    [xi.item.ORDELLE_BRONZEPIECE] = xi.item.MONTIONT_SILVERPIECE,
    [xi.item.ONE_BYNE_BILL      ] = xi.item.ONE_HUNDRED_BYNE_BILL,
}

M.JEUNO_POOL =
{
    xi.item.MONTIONT_SILVERPIECE,
    xi.item.ONE_HUNDRED_BYNE_BILL,
    xi.item.LUNGO_NANGO_JADESHELL,
}

M.CITY_ZONE_HUNDRED =
{
    [xi.zone.DYNAMIS_SAN_DORIA] = xi.item.MONTIONT_SILVERPIECE,
    [xi.zone.DYNAMIS_BASTOK   ] = xi.item.ONE_HUNDRED_BYNE_BILL,
    [xi.zone.DYNAMIS_WINDURST ] = xi.item.LUNGO_NANGO_JADESHELL,
}

M.JEUNO_ZONES =
{
    [xi.zone.DYNAMIS_JEUNO] = true,
}

-- Fallback for untagged nightmare mobs. Pack-tagged kills use
-- dynamis_currency via dynamis_currency_drops.packSingle.
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
    local itemId
    if city then
        itemId = city
    elseif M.JEUNO_ZONES[zoneId] then
        local choose = pick or math.random
        itemId = M.JEUNO_POOL[choose(#M.JEUNO_POOL)]
    else
        itemId = M.HUNDRED_BY_SINGLE[singleCurrency]
    end

    if itemId and M.FORBIDDEN_10K[itemId] then
        return nil
    end

    return itemId
end

function M.tryDrop(mob, killer, singleCurrency)
    if not mob or not killer then
        return false
    end

    local chance = M.CHANCE_PERCENT
    if mob.isNM and mob:isNM() then
        chance = M.NM_CHANCE_PERCENT
    end

    if math.random(1, 100) > chance then
        return false
    end

    local itemId = M.hundredItem(mob:getZoneID(), singleCurrency)
    if not itemId then
        return false
    end

    -- Already won the roll. addTreasure default rate is a guaranteed pool add.
    killer:addTreasure(itemId, mob)
    return true
end

return M
