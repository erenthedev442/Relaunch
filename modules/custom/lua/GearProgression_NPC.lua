-----------------------------------
-- GearProgression_NPC.lua
-- Weapons-only vendor: spend seals to purchase tiered weapons.
-- Zone: Reisenjima_Henge (zone 292).
--
-- Seal currencies (loaded from catalog.seals at runtime).
--
-- Menu flow:
--   Main menu (tier picker)                   [customMenu - service navigation]
--     -> Category picker (Swords/Daggers/...)  [customMenu - service navigation]
--        -> Native shop window                 [setShopCurrency - full item previews]
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

    -- Weapon category picker, paginated so catalog growth doesn't overflow
    -- the 150-byte customMenu budget.
    local CAT_PG_SZ = 5

    local function buildTierMenu(player, menu, tierKey, page, returnFunc)
        local tierData  = catalog[tierKey]
        local sealDef   = catalog.seals[tierKey]
        local sealCount = player:getItemCount(sealDef.id)

        local populated = {}
        for _, group in ipairs(tierData.weapons or {}) do
            if #group.items > 0 then
                populated[#populated + 1] = group
            end
        end

        local totalPages = math.max(1, math.ceil(#populated / CAT_PG_SZ))
        page = math.max(1, math.min(page or 1, totalPages))
        local startIdx = (page - 1) * CAT_PG_SZ + 1
        local endIdx   = math.min(startIdx + CAT_PG_SZ - 1, #populated)

        local options = {}

        if #populated == 0 then
            options[#options + 1] = { 'No weapons yet (catalog empty)', function() end }
        else
            for i = startIdx, endIdx do
                local grp = populated[i]
                local capturedItems   = grp.items
                local capturedSealDef = sealDef
                options[#options + 1] = {
                    string.format('%s (%d)', grp.label, #grp.items),
                    function(playerArg)
                        openShop(playerArg, capturedSealDef, capturedItems)
                    end,
                }
            end

            if totalPages > 1 then
                if page > 1 then
                    options[#options + 1] = {
                        string.format('<< %d/%d', page - 1, totalPages),
                        function(playerArg)
                            buildTierMenu(playerArg, menu, tierKey, page - 1, returnFunc)
                        end,
                    }
                end
                if page < totalPages then
                    options[#options + 1] = {
                        string.format('%d/%d >>', page + 1, totalPages),
                        function(playerArg)
                            buildTierMenu(playerArg, menu, tierKey, page + 1, returnFunc)
                        end,
                    }
                end
            end
        end

        options[#options + 1] = { '<< Back', function(playerArg) returnFunc(playerArg) end }

        menu.title   = string.format('[%s] %d %s',
            tierKey:sub(1,1):upper() .. tierKey:sub(2),
            sealCount,
            sealDef.name)
        menu.options = options
        local snapshot = { title = menu.title, options = menu.options }
        player:timer(30, function(p) p:customMenu(snapshot) end)
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
                    buildTierMenu(playerArg, menu, 'bronze', 1, buildMainMenu)
                end,
            },
            {
                string.format('[Silver] Mid  (%d %s)',
                    player:getItemCount(catalog.seals.silver.id),
                    catalog.seals.silver.name:match('^(%S+)') or 'seals'),
                function(playerArg)
                    buildTierMenu(playerArg, menu, 'silver', 1, buildMainMenu)
                end,
            },
            {
                string.format('[Gold] Endgame  (%d %s)',
                    player:getItemCount(catalog.seals.gold.id),
                    catalog.seals.gold.name:match('^(%S+)') or 'seals'),
                function(playerArg)
                    buildTierMenu(playerArg, menu, 'gold', 1, buildMainMenu)
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
