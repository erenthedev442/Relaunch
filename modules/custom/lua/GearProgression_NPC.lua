-----------------------------------
-- GearProgression_NPC.lua
-- Weapons-only vendor: spend seals to purchase tiered weapons.
-- Zone: Reisenjima_Henge (zone 292).
--
-- Seal currencies (loaded from catalog.seals at runtime).
--
-- Menu flow:
--   Main menu (tier picker)                   [customMenu - service navigation]
--     -> Native shop window                   [setShopCurrency - full item previews]
--
-- The native shop window charges sealDef.id items automatically via the
-- C++ packet handler (setShopCurrency). No Lua purchase helper needed.
--
-- To add weapons: edit gear_progression_catalog.lua only.
-----------------------------------
require('modules/module_utils')
local catalog = require('modules/custom/lua/gear_progression_catalog')

local _zoneName = catalog.zonePath:match('xi%.zones%.(.+)')
require(string.format('scripts/zones/%s/Zone', _zoneName))

local m = Module:new('gear_progression_npc')

m:addOverride(catalog.zonePath .. '.Zone.onInitialize', function(zone)
    super(zone)

    local function openShop(player, sealDef, items)
        if #items == 0 then
            player:printToPlayer('No weapons available here.', xi.msg.channel.SYSTEM_3)
            return
        end
        local count = math.min(#items, 16)
        player:printToPlayer(
            string.format('Browsing %s weapons. Currency: %s (you have %d). Hover items to preview.',
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

    local function openTierShop(player, tierKey)
        local tierData  = catalog[tierKey]
        local sealDef   = catalog.seals[tierKey]
        openShop(player, sealDef, tierData.weapons or {})
    end

    local menu = { title = 'Gear Progression', options = {} }

    local function buildMainMenu(player)
        menu.title   = 'Weapons - Choose Tier'
        menu.options =
        {
            {
                string.format('[Bronze] Entry  (%d %s)',
                    player:getItemCount(catalog.seals.bronze.id),
                    catalog.seals.bronze.name:match('^(%S+)') or 'seals'),
                function(playerArg)
                    openTierShop(playerArg, 'bronze')
                end,
            },
            {
                string.format('[Silver] Mid  (%d %s)',
                    player:getItemCount(catalog.seals.silver.id),
                    catalog.seals.silver.name:match('^(%S+)') or 'seals'),
                function(playerArg)
                    openTierShop(playerArg, 'silver')
                end,
            },
            {
                string.format('[Gold] Endgame  (%d %s)',
                    player:getItemCount(catalog.seals.gold.id),
                    catalog.seals.gold.name:match('^(%S+)') or 'seals'),
                function(playerArg)
                    openTierShop(playerArg, 'gold')
                end,
            },
            {
                'Close',
                function(playerArg)
                    playerArg:printToPlayer('Come back when you have more seals!', xi.msg.channel.SYSTEM_3)
                end,
            },
        }
        local snapshot = { title = menu.title, options = menu.options }
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    local _p = catalog.vendorPos
    local GearProgressionNPC = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Weapons_NPC',
        packetName = string.format('%sWeapons', xi.icon.STAR_LARGE),
        look       = 2430,
        x          = _p.x,
        y          = _p.y,
        z          = _p.z,
        rotation   = _p.rot,
        widescan   =  1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('No trades - use the menu to browse weapons!', xi.msg.channel.SYSTEM_3)
        end,

        onTrigger = function(player, npc)
            player:timer(50, function(playerArg)
                buildMainMenu(playerArg)
            end)
        end,
    })
    utils.unused(GearProgressionNPC)
end)

return m
