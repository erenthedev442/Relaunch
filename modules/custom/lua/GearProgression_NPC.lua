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

    -- Browse CATEGORY-first (owner request 2026-07-13): pick a weapon type, then
    -- a tier (Bronze/Silver/Gold), then buy. Each (category, tier) list is small,
    -- so the native shop opens directly -- no more per-tier page pickers.
    local TIER_ORDER     = { 'bronze', 'silver', 'gold' }
    local CATEGORY_ORDER =
    {
        'Hand-to-Hand', 'Daggers', 'Swords', 'Great Swords', 'Axes', 'Great Axes',
        'Scythes', 'Polearms', 'Katana', 'Great Katana', 'Clubs', 'Staves',
        'Archery', 'Marksmanship', 'Instruments', 'Grips',
    }
    local CAT_PER_PAGE = 6  -- 6 categories + "More" + "Close" = the 8-option client cap

    -- Weapons of one (category, tier): Ambuscade-excluded, alphabetical by name.
    local function weaponsFor(category, tierKey)
        local out = {}
        for _, it in ipairs((catalog[tierKey] or {}).weapons or {}) do
            if it.cat == category and not AMBU_WPN_IDS[it.id] then
                out[#out + 1] = it
            end
        end
        table.sort(out, function(a, b) return (a.name or ''):lower() < (b.name or ''):lower() end)
        return out
    end

    -- Categories that actually have at least one buyable weapon, in display order.
    local function availableCategories()
        local present = {}
        for _, tierKey in ipairs(TIER_ORDER) do
            for _, it in ipairs((catalog[tierKey] or {}).weapons or {}) do
                if it.cat and not AMBU_WPN_IDS[it.id] then present[it.cat] = true end
            end
        end
        local ordered = {}
        for _, c in ipairs(CATEGORY_ORDER) do
            if present[c] then ordered[#ordered + 1] = c end
        end
        return ordered
    end

    local buildCategoryMenu  -- forward decl (buildTierMenu's Back returns to it)

    -- Step 2: pick the tier for the chosen category (only tiers that have one).
    local function buildTierMenu(player, category)
        local options = {}
        for _, tierKey in ipairs(TIER_ORDER) do
            local items = weaponsFor(category, tierKey)
            if #items > 0 then
                local sealDef       = catalog.seals[tierKey]
                local tierName      = tierKey:sub(1, 1):upper() .. tierKey:sub(2)
                local capturedItems = items
                local capturedSeal  = sealDef
                options[#options + 1] = {
                    string.format('[%s] %s (%d)', tierName, sealDef.name:match('^(%S+)') or '', #items),
                    function(p) openShop(p, capturedSeal, capturedItems) end,
                }
            end
        end
        options[#options + 1] = { '<< Categories', function(p) buildCategoryMenu(p, 1) end }
        player:timer(30, function(p) p:customMenu({ title = category, options = options }) end)
    end

    -- Step 1: pick the weapon category. Paged with a wrapping "More" (there are
    -- more categories than the 8-option client menu holds).
    buildCategoryMenu = function(player, page)
        local cats  = availableCategories()
        local pages = math.max(1, math.ceil(#cats / CAT_PER_PAGE))
        page = ((page - 1) % pages) + 1
        local first = (page - 1) * CAT_PER_PAGE + 1
        local last  = math.min(page * CAT_PER_PAGE, #cats)

        local options = {}
        for i = first, last do
            local category = cats[i]
            options[#options + 1] = { category, function(p) buildTierMenu(p, category) end }
        end
        if pages > 1 then
            options[#options + 1] = {
                string.format('More >> (%d/%d)', page, pages),
                function(p) buildCategoryMenu(p, page + 1) end,
            }
        end
        options[#options + 1] = {
            'Close',
            function(p) p:printToPlayer('Come back when you have more seals!', xi.msg.channel.SYSTEM_3) end,
        }
        player:timer(30, function(p) p:customMenu({ title = 'Weapon Category', options = options }) end)
    end

    -- Entry point: category picker first, then tier, then the shop.
    local function buildMainMenu(player)
        buildCategoryMenu(player, 1)
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
