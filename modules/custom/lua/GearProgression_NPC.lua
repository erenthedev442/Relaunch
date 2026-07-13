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
-- Ambuscade weapons are Ambuscade-exclusive (Gorpa's weapon upgrade chain), so
-- hide them from this seal vendor. Filtered at the consumer to avoid editing
-- Kirin's gear_progression_catalog data. EXCLUSIVE_IDS = ALL Ambuscade stages;
-- ALL FIVE Ambuscade stages scrub now (2026-07-10): the Prime/Aeonic 119I/119II
-- feedstock is earned from Ambuscade, so Tokko/Ajja no longer stay here.
local AMBU_WPN_IDS = require('modules/custom/lua/ambuscade_weapons_catalog').EXCLUSIVE_IDS

local _zoneName = catalog.zonePath:match('xi%.zones%.(.+)')
require(string.format('scripts/zones/%s/Zone', _zoneName))

local m = Module:new('gear_progression_npc')

m:addOverride(catalog.zonePath .. '.Zone.onInitialize', function(zone)
    super(zone)

    -- Native shop windows hold at most 16 items (createShop cap). A tier with
    -- more than that is shown one page at a time (see openTierShop) so nothing
    -- is silently hidden; `offset` is the 0-based index of the page's first item.
    local SHOP_PAGE = 16

    local function openShop(player, sealDef, items, offset)
        offset = offset or 0
        local total = #items
        if total == 0 then
            player:printToPlayer('No weapons available here.', xi.msg.channel.SYSTEM_3)
            return
        end
        local count    = math.min(total - offset, SHOP_PAGE)
        local pageNote = total > SHOP_PAGE
            and string.format(' [items %d-%d of %d]', offset + 1, offset + count, total)
            or ''
        player:printToPlayer(
            string.format('Browsing %s weapons%s. Currency: %s (you have %d). Hover items to preview.',
                sealDef.name, pageNote, sealDef.name, player:getItemCount(sealDef.id)),
            xi.msg.channel.SYSTEM_3)
        player:timer(50, function(p)
            p:createShop(count)
            for i = 1, count do
                p:addShopItem(items[offset + i].id, items[offset + i].cost)
            end
            p:setShopCurrency(sealDef.id)
            p:sendMenu(xi.menuType.SHOP)
        end)
    end

    local function openTierShop(player, tierKey)
        local tierData = catalog[tierKey]
        local sealDef  = catalog.seals[tierKey]
        -- Exclude Ambuscade weapons (now Ambuscade-exclusive) from this vendor.
        local items    = {}
        for _, it in ipairs(tierData.weapons or {}) do
            if not AMBU_WPN_IDS[it.id] then items[#items + 1] = it end
        end

        -- Fits in one shop window -> open it directly (unchanged behaviour).
        if #items <= SHOP_PAGE then
            openShop(player, sealDef, items)
            return
        end

        -- Too many for one window -> offer a page picker so all items are reachable.
        local pages    = math.ceil(#items / SHOP_PAGE)
        -- Title + labels concatenate into a 150-byte chat packet (Mes[150],
        -- truncated hard). Keep the title short so a 6-7 page picker (bronze can
        -- reach ~92 weapons = 6 pages) stays well under 150 bytes.
        local pageMenu =
        {
            title   = string.format('%s Weapons', sealDef.name:match('^(%S+)') or ''),
            options = {},
        }
        for pg = 1, pages do
            local first = (pg - 1) * SHOP_PAGE + 1
            local last  = math.min(pg * SHOP_PAGE, #items)
            pageMenu.options[#pageMenu.options + 1] =
            {
                string.format('Page %d (%d-%d)', pg, first, last),
                function(playerArg)
                    openShop(playerArg, sealDef, items, first - 1)
                end,
            }
        end
        pageMenu.options[#pageMenu.options + 1] =
        {
            'Close',
            function(playerArg)
                playerArg:printToPlayer('Come back when you have more seals!', xi.msg.channel.SYSTEM_3)
            end,
        }
        player:timer(30, function(p) p:customMenu(pageMenu) end)
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
        look       = 170,
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
