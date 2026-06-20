-----------------------------------
-- Cosmetic_Shop.lua
-- "Boutique Moogle" -- GM Home seasonal boutique.
-- Sells one appearance item per server day (UTC), rotating through
-- cosmetic_shop_catalog.lua.
--
-- Uses the NATIVE shop window (examinable item icons -- so players can SEE the
-- look before buying, instead of just a name) and charges Allied Notes via the
-- FJB named-currency shop hook (player:setShopCurrencyName -> 0x083_shop_buy.cpp).
-- No combat stats on any item.
--
-- NPC position: x=7.5, z=-25 (east end of the z=-25 activities row).
-----------------------------------
require('modules/module_utils')
require('scripts/zones/GM_Home/Zone')
local catalog = require('modules/custom/lua/cosmetic_shop_catalog')

local m = Module:new('cosmetic_shop')

local S = xi.msg.channel.SYSTEM_3

local function fmtAN(n)
    if n >= 1000 then
        return string.format('%dk AN', n / 1000)
    end
    return tostring(n) .. ' AN'
end

local function getItem(offset)
    local dayIdx = math.floor(os.time() / 86400) + (offset or 0)
    return catalog.items[(dayIdx % #catalog.items) + 1]
end

m:addOverride('xi.zones.GM_Home.Zone.onInitialize', function(zone)
    super(zone)

    local function openBoutique(player)
        local today    = getItem(0)
        local tomorrow = getItem(1)

        player:printToPlayer(string.format(
            "[Boutique] Today's cosmetic: %s -- %s. Examine it in the window to see the look, kupo!",
            today.name, fmtAN(today.price)), S)
        player:printToPlayer(string.format(
            '[Boutique] Appearance only (no stats). Buying spends Allied Notes -- you have %d. Tomorrow: %s.',
            player:getCurrency('allied_notes'), tomorrow.name), S)

        -- Native shop window: one examinable item, charged in Allied Notes via
        -- the FJB named-currency hook (setShopCurrencyName -> 0x083_shop_buy.cpp).
        -- The window still shows a gil icon next to the price (client limitation),
        -- which is why the chat lines above spell out the real cost in Allied Notes.
        player:timer(50, function(p)
            p:createShop(1)
            p:addShopItem(today.id, today.price)
            p:setShopCurrencyName('allied_notes')
            p:sendMenu(xi.menuType.SHOP)
        end)
    end

    local BoutiqueMoogle = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Cosmetic_Boutique',
        packetName = string.format('%s%s', xi.icon.STAR_LARGE, catalog.npcName),
        look       = catalog.npcLook,
        x          = catalog.npcPos.x,
        y          = catalog.npcPos.y,
        z          = catalog.npcPos.z,
        rotation   = catalog.npcPos.rot,
        widescan   = 1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('[Boutique] No trading -- browse the shop window, kupo!', S)
        end,

        onTrigger = function(player, npc)
            openBoutique(player)
        end,
    })
    utils.unused(BoutiqueMoogle)
end)

return m
