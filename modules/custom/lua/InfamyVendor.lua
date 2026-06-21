-----------------------------------
-- InfamyVendor.lua
-- Infamy Vendor NPC in GM Home (x=4.5, z=-21).
--
-- The native shop window charges the Infamy CharVar instead of gil via
-- p:setShopCurrencyVar(). Menu structure:
--   Root (category picker)
--     Weapons / Armor / Accessories / Other  -> native shop window (16 per page)
--     +4 Reforge   Job -> [Set ->] Slot      -> native shop window (5 slots)
--
-- All item data is in infamy_vendor_catalog.lua.
-- Run tools/build_infamy_top_picks.py to refresh vendorItemsAuto.
-- Run tools/build_infamy_plus4_catalog.py to refresh plus4Sets.
-- Run tools/build_infamy_typemap.py to refresh itemTypeMap.
-----------------------------------
require('modules/module_utils')
local catalog = require('modules/custom/lua/infamy_vendor_catalog')

require('scripts/zones/GM_Home/Zone')

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
    for _, it in ipairs(catalog.vendorItems     or {}) do table.insert(out, it) end
    for _, it in ipairs(catalog.vendorItemsAuto or {}) do table.insert(out, it) end
    return out
end

local function groupCurated()
    local items = buildCuratedItems()
    local map   = catalog.itemTypeMap or {}
    local g     = {}
    for _, it in ipairs(items) do
        local cs       = map[it.id] or 'Other/Other'
        local cat, sub = cs:match('^(.-)/(.+)$')
        cat = cat or 'Other'
        sub = sub or 'Other'
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
local showPlus4JobMenu
local showPlus4SetMenu
local showPlus4SlotMenu

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
    table.insert(opts, { '+4 Reforge',    function(p) showPlus4JobMenu(p, 1) end })
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
-- +4 REFORGE BROWSER  (Job -> [Set ->] Slot -> native shop)
--------------------------------------------------------------------
local plus4Jobs = {}
for job, _ in pairs(catalog.plus4Sets or {}) do
    table.insert(plus4Jobs, job)
end
table.sort(plus4Jobs)

local JOB_PAGE_SIZE = 6

showPlus4JobMenu = function(player, page)
    page = page or 1
    local total = #plus4Jobs
    local pages = math.max(1, math.ceil(total / JOB_PAGE_SIZE))
    page = math.max(1, math.min(page, pages))

    local opts     = {}
    local startIdx = (page - 1) * JOB_PAGE_SIZE + 1
    local endIdx   = math.min(startIdx + JOB_PAGE_SIZE - 1, total)

    for idx = startIdx, endIdx do
        local job  = plus4Jobs[idx]
        local sets = catalog.plus4Sets[job] or {}
        if #sets == 1 then
            table.insert(opts, {
                string.format('%s  (5 pc)', job),
                function(p) showPlus4SlotMenu(p, job, 1, page) end,
            })
        else
            table.insert(opts, {
                string.format('%s  (%d sets)', job, #sets),
                function(p) showPlus4SetMenu(p, job, page) end,
            })
        end
    end

    if pages > 1 then
        if page > 1 then
            table.insert(opts, { '<< Prev', function(p) showPlus4JobMenu(p, page - 1) end })
        end
        if page < pages then
            table.insert(opts, { 'Next >>', function(p) showPlus4JobMenu(p, page + 1) end })
        end
    end
    table.insert(opts, { '<< Back', function(p) showVendorRoot(p) end })

    vendorMenu.title   = string.format('+4 Reforge  [%d Infamy]', getInfamy(player))
    vendorMenu.options = opts
    openMenu(player, vendorMenu)
end

showPlus4SetMenu = function(player, job, jobPage)
    local sets = catalog.plus4Sets[job] or {}
    local opts = {}
    for setIdx, setEntry in ipairs(sets) do
        local pieceCount = 0
        for _ in pairs(setEntry.pieces or {}) do pieceCount = pieceCount + 1 end
        table.insert(opts, {
            string.format('%s  (%d pc)', setEntry.set, pieceCount),
            function(p) showPlus4SlotMenu(p, job, setIdx, jobPage) end,
        })
    end
    table.insert(opts, { '<< Back', function(p) showPlus4JobMenu(p, jobPage) end })

    vendorMenu.title   = string.format('%s Sets  [%d Infamy]', job, getInfamy(player))
    vendorMenu.options = opts
    openMenu(player, vendorMenu)
end

local PLUS4_SLOT_ORDER = { 'head', 'body', 'hands', 'legs', 'feet' }

showPlus4SlotMenu = function(player, job, setIdx, jobPage)
    local setEntry = (catalog.plus4Sets[job] or {})[setIdx]
    if not setEntry then
        showPlus4SetMenu(player, job, jobPage)
        return
    end
    local cost  = catalog.plus4Cost or 200
    local items = {}
    for _, slot in ipairs(PLUS4_SLOT_ORDER) do
        local piece = (setEntry.pieces or {})[slot]
        if piece then
            items[#items + 1] = { id = piece.id, cost = cost }
        end
    end
    openInfamyShop(player, items, 1)
end

--------------------------------------------------------------------
-- NPC PLACEMENT
--------------------------------------------------------------------
m:addOverride('xi.zones.GM_Home.Zone.onInitialize', function(zone)
    super(zone)

    local p = catalog.npcPos
    local InfamyVendor = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Infamy_Vendor',
        packetName = string.format('%sInfamy Vendor', xi.icon.STAR_LARGE),
        look       = 2419,
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
