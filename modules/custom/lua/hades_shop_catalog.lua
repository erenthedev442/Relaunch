-----------------------------------
-- hades_shop_catalog.lua
--
-- Weekend ferry stalls. Each live pool sells one ware, the same roll
-- for every player that UTC week.
--   Steel / Steel II -- Relic / Odyssey paper or finished Ambuscade / Geas
--   Mail / Mail II   -- 119 armor
--   Gild             -- accessories
--   Crate            -- REMA / Dynamis / Paragon currency (once per week)
--   Trusts           -- grantable alter egos (not Meat / Gemma / Corvus / Cornelia / Matsui-P)
--   Cosmetics        -- event / lockstyle gear
--
-- Pin a future week by setting any of the keys below. Unset keys still roll.
--   C.PINNED[202636] = { weapon = 21722, weapon2 = 21621, crate = 'beitetsu_300', trust = 897, cosmetic = 26955 }
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
    { key = 'weapon',    label = 'Steel'     },
    { key = 'weapon',    label = 'Steel II'  },
    { key = 'armor',     label = 'Mail'      },
    { key = 'armor',     label = 'Mail II'   },
    { key = 'accessory', label = 'Gild'      },
    { key = 'crate',     label = 'Crate'     },
    { key = 'trust',     label = 'Trusts'    },
    { key = 'cosmetic',  label = 'Cosmetics' },
}

-- Optional per-week overrides. See header.
-- First weekend is fully pinned so the board cannot drift, and every
-- stall stays at or under one week of Soul Shards (1050).
C.PINNED = C.PINNED or {}
C.PINNED[202636] =
{
    weapon    = 21722,       -- Dolichenus (finished Ambuscade axe)
    weapon2   = 21621,       -- Naegling
    weapon2Price = 899,
    armor     = 23798,       -- Crepuscular Mail
    armor2    = 27496,       -- Herculean Boots
    accessory = 27555,       -- Warden's Ring
    crate     = '10kbyne_50',
    trust     = 932,         -- Fablinix
    cosmetic  = 11318,       -- Otokoeshi Yukata
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
    local weapons   = require('modules/custom/lua/relic_voucher_catalog')
    local armor     = require('modules/custom/lua/hades_armor_catalog')
    local accessory = require('modules/custom/lua/hades_accessory_catalog')
    local crate     = require('modules/custom/lua/hades_crate_catalog')
    local trusts    = require('modules/custom/lua/hades_trust_catalog')
    local cosmetics = require('modules/custom/lua/hades_cosmetic_catalog')
    weekId = weekId or weapons.weekId()

    local pin    = C.PINNED[weekId] or {}
    local steel  = (pin.weapon and weapons.byWeaponId[pin.weapon]) or weapons.weeklyRelic(weekId, 1)
    local steel2 = (pin.weapon2 and weapons.byWeaponId[pin.weapon2]) or weapons.weeklyRelic(weekId, 2)
    local mail   = (pin.armor and armor.byId[pin.armor]) or armor.weeklyPiece(weekId, 1)
    local mail2  = (pin.armor2 and armor.byId[pin.armor2]) or armor.weeklyPiece(weekId, 2)
    local gild   = (pin.accessory and accessory.byId[pin.accessory]) or accessory.weeklyPiece(weekId)
    local box    = crate.weeklyCrate(weekId, pin.crate)
    local ego    = trusts.weeklyTrust(weekId, pin.trust)
    local look   = cosmetics.weeklyPiece(weekId, pin.cosmetic)

    return {
        {
            pool   = 1,
            key    = 'weapon',
            label  = 'Steel',
            weekId = weekId,
            row    = steel,
            price  = pin.weaponPrice or weapons.weeklyPrice(weekId, steel, 1),
        },
        {
            pool   = 2,
            key    = 'weapon',
            label  = 'Steel II',
            weekId = weekId,
            row    = steel2,
            price  = pin.weapon2Price or weapons.weeklyPrice(weekId, steel2, 2),
        },
        {
            pool   = 3,
            key    = 'armor',
            label  = 'Mail',
            weekId = weekId,
            row    = mail,
            price  = mail and mail.price or 0,
        },
        {
            pool   = 4,
            key    = 'armor',
            label  = 'Mail II',
            weekId = weekId,
            row    = mail2,
            price  = mail2 and mail2.price or 0,
        },
        {
            pool   = 5,
            key    = 'accessory',
            label  = 'Gild',
            weekId = weekId,
            row    = gild,
            price  = gild and gild.price or 0,
        },
        {
            pool   = 6,
            key    = 'crate',
            label  = 'Crate',
            weekId = weekId,
            row    = box,
            price  = box and box.price or 0,
        },
        {
            pool   = 7,
            key    = 'trust',
            label  = 'Trusts',
            weekId = weekId,
            row    = ego,
            price  = ego and ego.price or 0,
        },
        {
            pool   = 8,
            key    = 'cosmetic',
            label  = 'Cosmetics',
            weekId = weekId,
            row    = look,
            price  = look and look.price or 0,
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
    if offer.key == 'crate' then
        return require('modules/custom/lua/hades_crate_catalog').owns(player, offer.weekId)
    end
    if offer.key == 'trust' then
        return require('modules/custom/lua/hades_trust_catalog').owns(player, offer.row)
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
    if offer.key == 'crate' then
        return require('modules/custom/lua/hades_crate_catalog').award(player, offer.row, offer.weekId)
    end
    if offer.key == 'trust' then
        return require('modules/custom/lua/hades_trust_catalog').award(player, offer.row)
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
