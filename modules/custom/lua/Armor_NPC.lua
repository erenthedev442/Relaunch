-----------------------------------
-- Armor_NPC.lua
-- Endgame armor vendor: spend medals to purchase BiS armor for the 5
-- main slots.
-- Zone: Reisenjima_Henge.
--
-- Seal currencies (loaded from catalog.seals at runtime).
--
-- Menu flow:
--   Main menu (tier picker)           [customMenu - service navigation]
--     -> Slot picker (Head/Body/...)  [customMenu - service navigation]
--        -> Native shop window        [setShopCurrency - full item previews]
--
-- The native shop window charges sealDef.id items automatically via the
-- C++ packet handler (0x083_shop_buy.cpp / setShopCurrency). No Lua
-- purchase helper is needed; the engine handles multi-container deduction.
--
-- Gold extra-drop requirements (catalog.goldExtraDrop / item.drop) are
-- NOT enforced in the shop window -- the engine only deducts the seal
-- currency. An "Info" row in the slot menu reminds players what's needed,
-- but enforcement is on the honor system. Add a pre-shop customMenu gate
-- here if hard enforcement is ever required.
--
-- To add gear: edit armor_catalog.lua only.
-----------------------------------
require('modules/module_utils')
local catalog = require('modules/custom/lua/armor_catalog')

local _zoneName = catalog.zonePath:match('xi%.zones%.(.+)')
require(string.format('scripts/zones/%s/Zone', _zoneName))

local m = Module:new('armor_npc')

m:addOverride(catalog.zonePath .. '.Zone.onInitialize', function(zone)
    super(zone)

    -- Open the native FFXI shop window for a list of items.
    -- setShopCurrency causes the engine to charge sealDef.id units instead
    -- of gil when the player clicks "Buy." Max 16 items per window.
    local function openShop(player, sealDef, items)
        if #items == 0 then
            player:printToPlayer('No items available here.', xi.msg.channel.SYSTEM_3)
            return
        end
        local count = math.min(#items, 16)
        player:printToPlayer(
            string.format('Browsing %s gear. Currency: %s (you have %d). Hover items to preview.',
                sealDef.name, sealDef.name, player:getItemCount(sealDef.id)),
            xi.msg.channel.SYSTEM_3)
        player:timer(50, function(p)
            p:createShop(count)
            for i = 1, count do
                p:addShopItem(items[i].id, items[i].cost)
            end
            p:setShopCurrency(sealDef.id)
            p:sendMenu(xi.menuType.SHOP)
        end)
    end

    local SLOT_ORDER = { 'head', 'body', 'hands', 'legs', 'feet', 'shields' }
    local SLOT_LABEL = { head = 'Head', body = 'Body', hands = 'Hands', legs = 'Legs', feet = 'Feet', shields = 'Shields' }

    local function buildSlotMenu(player, menu, tierKey, returnFunc)
        local tierData  = catalog[tierKey]
        local sealDef   = catalog.seals[tierKey]
        local sealCount = player:getItemCount(sealDef.id)
        local options   = {}

        for _, slotKey in ipairs(SLOT_ORDER) do
            local items = tierData[slotKey] or {}
            if #items > 0 then
                local capturedItems   = items
                local capturedSealDef = sealDef
                table.insert(options, {
                    string.format('%s (%d)', SLOT_LABEL[slotKey], #items),
                    function(playerArg)
                        openShop(playerArg, capturedSealDef, capturedItems)
                    end,
                })
            end
        end

        if tierKey == 'gold' and catalog.goldExtraDrop then
            local extra = catalog.goldExtraDrop
            table.insert(options, {
                string.format('Info: needs %s', extra.name or 'extra drop'),
                function(p)
                    p:printToPlayer(
                        string.format('Gold items also require %d x %s.',
                            extra.qty, extra.name or 'extra drop'),
                        xi.msg.channel.SYSTEM_3)
                    buildSlotMenu(p, menu, tierKey, returnFunc)
                end,
            })
        end

        table.insert(options, { '<< Back', function(playerArg) returnFunc(playerArg) end })

        menu.title   = string.format('[%s] %d %s',
            tierKey:sub(1,1):upper() .. tierKey:sub(2),
            sealCount,
            sealDef.name)
        menu.options = options
        local snapshot = { title = menu.title, options = menu.options }
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    local menu = { title = 'Armor', options = {} }

    local function buildMainMenu(player)
        menu.title   = 'Armor - Choose Tier'
        menu.options =
        {
            {
                string.format('[Bronze] Entry  (%d %s)',
                    player:getItemCount(catalog.seals.bronze.id),
                    catalog.seals.bronze.name:match('^(%S+)') or 'seals'),
                function(playerArg) buildSlotMenu(playerArg, menu, 'bronze', buildMainMenu) end,
            },
            {
                string.format('[Silver] Mid  (%d %s)',
                    player:getItemCount(catalog.seals.silver.id),
                    catalog.seals.silver.name:match('^(%S+)') or 'seals'),
                function(playerArg) buildSlotMenu(playerArg, menu, 'silver', buildMainMenu) end,
            },
            {
                string.format('[Gold] BiS  (%d %s)',
                    player:getItemCount(catalog.seals.gold.id),
                    catalog.seals.gold.name:match('^(%S+)') or 'seals'),
                function(playerArg) buildSlotMenu(playerArg, menu, 'gold', buildMainMenu) end,
            },
            {
                'Close',
                function(playerArg)
                    playerArg:printToPlayer('Come back for more gear!', xi.msg.channel.SYSTEM_3)
                end,
            },
        }
        local snapshot = { title = menu.title, options = menu.options }
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    local _p = catalog.vendorPos
    local ArmorNPC = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Armor_NPC',
        packetName = string.format('%sArmor', xi.icon.STAR_LARGE),
        look       = 2430,
        x          = _p.x,
        y          = _p.y,
        z          = _p.z,
        rotation   = _p.rot,
        widescan   =  1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('No trades - use the menu to browse armor!', xi.msg.channel.SYSTEM_3)
        end,

        onTrigger = function(player, npc)
            player:timer(50, function(playerArg)
                buildMainMenu(playerArg)
            end)
        end,
    })
    utils.unused(ArmorNPC)
end)

return m
