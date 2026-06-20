-----------------------------------
-- Cosmetic_Shop.lua
-- "Boutique Moogle" -- GM Home seasonal boutique.
-- Sells one appearance item per server day (UTC), rotating through
-- cosmetic_shop_catalog.lua. Purchased with Allied Notes (from (S) zones). No combat stats on any item.
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

    local menu = { title = '', options = {} }

    local function show(player)
        local snapshot = { title = menu.title, options = menu.options }
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    local openShop   -- forward declaration
    local previewDay -- forward declaration

    openShop = function(player)
        local item = getItem(0)

        menu.title = string.format("Today's item: %s", item.name)
        menu.options =
        {
            { string.format('Buy %s (%s)', item.name, fmtAN(item.price)), function(p)
                if p:getCurrency('allied_notes') < item.price then
                    p:printToPlayer('[Boutique] Not enough allied notes, kupo!', S)
                    openShop(p)
                    return
                end
                if p:getFreeSlotsCount() < 1 then
                    p:printToPlayer('[Boutique] Inventory is full, kupo!', S)
                    openShop(p)
                    return
                end
                p:delCurrency('allied_notes', item.price)
                p:addItem({ id = item.id, quantity = 1 })
                p:printToPlayer(
                    string.format('[Boutique] Enjoy your %s, kupo!', item.name), S)
            end },

            { "Tomorrow's item", function(p)
                previewDay(p, 1)
            end },

            { 'Leave', function(p)
                p:printToPlayer('[Boutique] Come back tomorrow for a new item, kupo!', S)
            end },
        }
        show(player)
    end

    previewDay = function(player, offset)
        local item = getItem(offset)
        local label = (offset == 1) and 'Tomorrow' or string.format('Day +%d', offset)

        menu.title = string.format("%s's item: %s", label, item.name)
        menu.options =
        {
            { string.format('%s (%s)', item.name, fmtAN(item.price)), function(p)
                -- informational -- re-show same preview
                previewDay(p, offset)
            end },

            { 'Back to today',  function(p) openShop(p) end },
            { 'Leave',          function(p)
                p:printToPlayer('[Boutique] See you next time, kupo!', S)
            end },
        }
        show(player)
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
            player:printToPlayer('[Boutique] No trading -- use the menu to browse, kupo!', S)
        end,

        onTrigger = function(player, npc)
            openShop(player)
        end,
    })
    utils.unused(BoutiqueMoogle)
end)

return m
