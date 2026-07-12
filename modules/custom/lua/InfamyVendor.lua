-----------------------------------
-- InfamyVendor.lua
-- Infamy Vendor NPC in GM Home (x=4.5, z=-21).
--
-- The native shop window charges the Infamy CharVar instead of gil via
-- p:setShopCurrencyVar(). Menu structure:
--   Root (accessory slot picker)
--     Accessories  Neck / Ear / Ring / Waist / Back  -> native shop window
--
-- Accessories-only, hand-curated. All item data is in
-- infamy_vendor_catalog.lua (each item carries its own `sub` slot). The old
-- auto-generated sections + build_infamy_*.py generators were retired; weapons
-- and armor moved to the Voidwatch NM loot tables.
-----------------------------------
require('modules/module_utils')
local catalog = require('modules/custom/lua/infamy_vendor_catalog')

require('scripts/zones/Abdhaljs_Isle-Purgonorgo/Zone')

local m = Module:new('infamy_vendor')

--------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------

local function getInfamy(player)
    return player:getCharVar(catalog.currencyCv) or 0
end

local function trunc(s, max)
    if not s or #s <= max then return s or '' end
    return s:sub(1, max - 2) .. '..'
end

local vendorMenu = { title = '', options = {} }

local function dedupeLabels(opts)
    if type(opts) ~= 'table' then return opts end
    local seen = {}
    for _, opt in ipairs(opts) do
        local label = opt[1]
        if type(label) == 'string' then
            if seen[label] then
                local n = 2
                local candidate = label .. ' (' .. n .. ')'
                while seen[candidate] do
                    n = n + 1
                    candidate = label .. ' (' .. n .. ')'
                end
                opt[1] = candidate
                seen[candidate] = true
            else
                seen[label] = true
            end
        end
    end
    return opts
end

local function openMenu(player, menu)
    dedupeLabels(menu.options)
    local snapshot = { title = menu.title, options = menu.options }
    player:timer(30, function(p) p:customMenu(snapshot) end)
end

--------------------------------------------------------------------
-- NATIVE SHOP HELPER
-- Opens the real FFXI shop window; charges Infamy CharVar via
-- setShopCurrencyVar (packets/c2s/0x083_shop_buy.cpp).
--------------------------------------------------------------------
local SHOP_PAGE_SIZE = 16

local function openInfamyShop(player, items, page)
    page = page or 1
    local total = #items
    if total == 0 then
        player:printToPlayer('Nothing available here, kupo!', xi.msg.channel.SYSTEM_3)
        return
    end
    local startIdx = (page - 1) * SHOP_PAGE_SIZE + 1
    local endIdx   = math.min(startIdx + SHOP_PAGE_SIZE - 1, total)
    if endIdx < startIdx then return end

    player:printToPlayer(
        string.format('You have %d Infamy. Hover items to preview; buying spends Infamy, kupo!',
            getInfamy(player)),
        xi.msg.channel.SYSTEM_3)

    player:timer(50, function(p)
        p:createShop(endIdx - startIdx + 1)
        for i = startIdx, endIdx do
            p:addShopItem(items[i].id, items[i].cost)
        end
        p:setShopCurrencyVar(catalog.currencyCv)
        p:sendMenu(xi.menuType.SHOP)
    end)
end

--------------------------------------------------------------------
-- CURATED BROWSER (grouped: Category -> Subtype -> native shop)
--------------------------------------------------------------------

local CAT_ORDER = { 'Weapons', 'Armor', 'Accessories', 'Other' }
local SUB_ORDER =
{
    Weapons     = { 'Hand-to-Hand', 'Dagger', 'Sword', 'Great Sword', 'Axe',
                    'Great Axe', 'Scythe', 'Polearm', 'Katana', 'Great Katana',
                    'Club', 'Staff', 'Archery', 'Marksmanship', 'Ammo', 'Instrument',
                    'Handbell', 'Grip-Shield', 'Other' },
    Armor       = { 'Head', 'Body', 'Hands', 'Legs', 'Feet', 'Other' },
    Accessories = { 'Neck', 'Ear', 'Ring', 'Waist', 'Back', 'Other' },
    Other       = { 'Other' },
}
local SUBTYPE_PAGE_SIZE = 6

local function buildCuratedItems()
    local out = {}
    for _, it in ipairs(catalog.vendorItems or {}) do table.insert(out, it) end
    return out
end

local function groupCurated()
    local items = buildCuratedItems()
    local g     = {}
    for _, it in ipairs(items) do
        -- Each item carries its own slot sub-category; `cat` is optional and
        -- defaults to Accessories (the vendor was accessories-only until the
        -- Volte set moved here 2026-07-12 with cat='Armor').
        local cat, sub = (it.cat or 'Accessories'), (it.sub or 'Other')
        g[cat]      = g[cat] or {}
        g[cat][sub] = g[cat][sub] or {}
        table.insert(g[cat][sub], { item = it })
    end
    return g
end

local function catCount(g, cat)
    local n = 0
    for _, list in pairs(g[cat] or {}) do n = n + #list end
    return n
end

local function subsPresent(g, cat)
    local present, out, seen = g[cat] or {}, {}, {}
    for _, sub in ipairs(SUB_ORDER[cat] or {}) do
        if present[sub] then table.insert(out, sub); seen[sub] = true end
    end
    for sub in pairs(present) do
        if not seen[sub] then table.insert(out, sub) end
    end
    return out
end

-- Forward declarations
local showVendorRoot
local showCuratedCat
local showCuratedSub

showVendorRoot = function(player)
    local g    = groupCurated()
    local opts = {}
    for _, cat in ipairs(CAT_ORDER) do
        local n = catCount(g, cat)
        if n > 0 then
            local c = cat
            table.insert(opts, { string.format('%s (%d)', cat, n),
                function(p) showCuratedCat(p, c, 1) end })
        end
    end
    -- +4 upgrades live at the Dynamis-D Forge (Dynamis_Plus4_Forge.lua); the
    -- [D] materials are the gate. The old in-vendor +4 browser was removed with
    -- the auto-generated catalog sections.
    table.insert(opts, { 'Close',         function() end })

    vendorMenu.title   = string.format('Infamy Vendor  [%d Infamy]', getInfamy(player))
    vendorMenu.options = opts
    openMenu(player, vendorMenu)
end

showCuratedCat = function(player, cat, page)
    page = page or 1
    local g     = groupCurated()
    local subs  = subsPresent(g, cat)
    local pages = math.max(1, math.ceil(#subs / SUBTYPE_PAGE_SIZE))
    page = math.max(1, math.min(page, pages))
    local startIdx = (page - 1) * SUBTYPE_PAGE_SIZE + 1
    local endIdx   = math.min(startIdx + SUBTYPE_PAGE_SIZE - 1, #subs)

    local opts = {}
    for i = startIdx, endIdx do
        local sub = subs[i]
        table.insert(opts, { trunc(sub, 16),
            function(p) showCuratedSub(p, cat, sub) end })
    end
    if pages > 1 then
        if page > 1     then table.insert(opts, { '<< Prev', function(p) showCuratedCat(p, cat, page - 1) end }) end
        if page < pages then table.insert(opts, { 'Next >>', function(p) showCuratedCat(p, cat, page + 1) end }) end
    end
    table.insert(opts, { '<< Back', function(p) showVendorRoot(p) end })

    vendorMenu.title   = trunc(cat, 24)
    vendorMenu.options = opts
    openMenu(player, vendorMenu)
end

showCuratedSub = function(player, cat, sub)
    local g     = groupCurated()
    local list  = (g[cat] or {})[sub] or {}
    local items = {}
    for _, entry in ipairs(list) do
        items[#items + 1] = { id = entry.item.id, cost = entry.item.cost }
    end

    if #items <= SHOP_PAGE_SIZE then
        openInfamyShop(player, items, 1)
        return
    end

    local opts  = {}
    local pages = math.ceil(#items / SHOP_PAGE_SIZE)
    for pg = 1, pages do
        local a = (pg - 1) * SHOP_PAGE_SIZE + 1
        local b = math.min(pg * SHOP_PAGE_SIZE, #items)
        table.insert(opts, { string.format('Items %d-%d', a, b),
            function(p) openInfamyShop(p, items, pg) end })
    end
    table.insert(opts, { '<< Back', function(p) showCuratedCat(p, cat, 1) end })

    vendorMenu.title   = string.format('%s  [%d Inf]', trunc(sub, 12), getInfamy(player))
    vendorMenu.options = opts
    openMenu(player, vendorMenu)
end

--------------------------------------------------------------------
-- NPC PLACEMENT
--------------------------------------------------------------------
m:addOverride('xi.zones.Abdhaljs_Isle-Purgonorgo.Zone.onInitialize', function(zone)
    super(zone)

    local p = catalog.npcPos
    local InfamyVendor = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Infamy_Vendor',
        packetName = string.format('%sInfamy Vendor', xi.icon.STAR_LARGE),
        look       = 211,
        x          = p.x,
        y          = p.y,
        z          = p.z,
        rotation   = p.rotation,
        widescan   = 1,
        onTrigger  = function(player, npc)
            player:printToPlayer(
                '[ Infamy Vendor ] Trade your notoriety for power, kupo.',
                xi.msg.channel.SYSTEM_3)
            showVendorRoot(player)
        end,
    })
    utils.unused(InfamyVendor)
end)

return m
