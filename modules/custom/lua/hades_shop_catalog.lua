-----------------------------------
-- hades_shop_catalog.lua
--
-- Weekend ferry stalls. Each live pool sells one ware, the same roll
-- for every player that UTC week. Steel (Relic / Odyssey / Ambuscade /
-- Geas named), Mail (119 armor), Gild (accessories). Later pools plug in here.
-----------------------------------
local CATALOG_KEY = 'modules/custom/lua/hades_shop_catalog'
local C = package.loaded[CATALOG_KEY]
if type(C) ~= 'table' then
    C = {}
end
package.loaded[CATALOG_KEY] = C

C.SYS = xi.msg.channel.SYSTEM_3

C.POOLS =
{
    { key = 'weapon',    label = 'Steel' },
    { key = 'armor',     label = 'Mail'  },
    { key = 'accessory', label = 'Gild'  },
}

local function hasItem(player, itemId)
    if not player or not itemId then
        return false
    end
    local ok, count = pcall(function()
        return player:getItemCount(itemId)
    end)
    return ok and (count or 0) > 0
end

function C.weekOffers(weekId)
    local weapons    = require('modules/custom/lua/relic_voucher_catalog')
    local armor      = require('modules/custom/lua/hades_armor_catalog')
    local accessory  = require('modules/custom/lua/hades_accessory_catalog')
    weekId = weekId or weapons.weekId()

    local steel = weapons.weeklyRelic(weekId)
    local mail  = armor.weeklyPiece(weekId)
    local gild  = accessory.weeklyPiece(weekId)
    return {
        {
            pool  = 1,
            key   = 'weapon',
            label = 'Steel',
            row   = steel,
            price = weapons.weeklyPrice(weekId, steel),
        },
        {
            pool  = 2,
            key   = 'armor',
            label = 'Mail',
            row   = mail,
            price = mail and mail.price or 0,
        },
        {
            pool  = 3,
            key   = 'accessory',
            label = 'Gild',
            row   = gild,
            price = gild and gild.price or 0,
        },
    }
end

function C.shopName(offer)
    if not offer or not offer.row then
        return 'a ware'
    end
    if offer.key == 'weapon' then
        return require('modules/custom/lua/relic_voucher_catalog').shopName(offer.row)
    end
    return offer.row.name
end

function C.owns(player, offer)
    if not offer or not offer.row then
        return false
    end
    if offer.key == 'weapon' then
        local weapons = require('modules/custom/lua/relic_voucher_catalog')
        return weapons.ownsRelic(player, offer.row) or weapons.ownsVoucher(player, offer.row)
    end
    return hasItem(player, offer.row.id)
end

function C.award(player, offer, tag)
    if not player or not offer or not offer.row then
        return false
    end
    if offer.key == 'weapon' then
        return require('modules/custom/lua/relic_voucher_catalog').award(player, offer.row, tag)
    end

    local prefix = (tag and tag ~= '') and string.format('[%s] ', tag) or ''
    if player:getFreeSlotsCount() < 1 then
        player:printToPlayer(prefix .. 'Free an inventory slot first.', C.SYS)
        return false
    end
    if hasItem(player, offer.row.id) then
        player:printToPlayer(prefix .. string.format('You already hold %s.', offer.row.name), C.SYS)
        return false
    end
    if not player:addItem({ id = offer.row.id, quantity = 1 }) then
        player:printToPlayer(prefix .. 'The ware slipped back into the dark. Try again.', C.SYS)
        return false
    end
    return true
end

return C
