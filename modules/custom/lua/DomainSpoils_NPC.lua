-----------------------------------
-- DomainSpoils_NPC.lua
-- "Domain Quartermaster" NPC at the Purgonorgo hub (zone 44).
--
-- Sells the 86 Zurim / Domain-Points items for HUNT MARKS (HL_Points CharVar)
-- via the native shop window -- a marks-based alternative to grinding the
-- daily-capped Domain Points at Zurim in Norg. Owner request 2026-07-10; item
-- stats implemented in sql/zz_zurim_gear_mods.sql the same day.
--
-- Engine mirrors InfamyVendor.lua (customMenu browse -> native shop charging a
-- CharVar via setShopCurrencyVar), generalized to multi-category: each catalog
-- row carries its own cat + sub. All item data / pricing / placement lives in
-- domain_spoils_catalog.lua.
-- Restart-gated (addOverride onInitialize).
-----------------------------------
require('modules/module_utils')
local catalog = require('modules/custom/lua/domain_spoils_catalog')

require('scripts/zones/Abdhaljs_Isle-Purgonorgo/Zone')

local m = Module:new('domain_spoils_vendor')

--------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------

local function getMarks(player)
    return player:getCharVar(catalog.currencyCv) or 0
end

local function trunc(s, max)
    if not s or #s <= max then return s or '' end
    return s:sub(1, max - 2) .. '..'
end

local vendorMenu = { title = '', options = {} }

local function openMenu(player, menu)
    local snapshot = { title = menu.title, options = menu.options }
    player:timer(30, function(p) p:customMenu(snapshot) end)
end

--------------------------------------------------------------------
-- NATIVE SHOP (charges the HL_Points CharVar; 16 items per window page)
--------------------------------------------------------------------
local SHOP_PAGE_SIZE = 16

local function openMarksShop(player, items, page)
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
        string.format('You have %d Hunt Marks. Buying spends marks, kupo!', getMarks(player)),
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
-- BROWSER (Category -> Subtype -> native shop). Multi-category: each
-- catalog row carries its own cat/sub.
--------------------------------------------------------------------

local CAT_ORDER = { 'Weapons', 'Armor', 'Accessories' }
local SUB_ORDER =
{
    Weapons     = { 'Fete T2', 'Reisenjima', 'Grip-Shield', 'Ammo', 'Other' },
    Armor       = { 'Head', 'Body', 'Hands', 'Legs', 'Feet', 'Other' },
    Accessories = { 'Ear', 'Ring', 'Waist', 'Back', 'Other' },
}
local SUBTYPE_PAGE_SIZE = 6

local function groupItems()
    local g = {}
    for _, it in ipairs(catalog.vendorItems or {}) do
        local cat, sub = (it.cat or 'Other'), (it.sub or 'Other')
        g[cat]      = g[cat] or {}
        g[cat][sub] = g[cat][sub] or {}
        table.insert(g[cat][sub], it)
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
local showCat
local showSub

showVendorRoot = function(player)
    local g    = groupItems()
    local opts = {}
    for _, cat in ipairs(CAT_ORDER) do
        local n = catCount(g, cat)
        if n > 0 then
            local c = cat
            table.insert(opts, { string.format('%s (%d)', cat, n),
                function(p) showCat(p, c, 1) end })
        end
    end
    table.insert(opts, { 'Close', function() end })

    vendorMenu.title   = string.format('Quartermaster [%d Marks]', getMarks(player))
    vendorMenu.options = opts
    openMenu(player, vendorMenu)
end

showCat = function(player, cat, page)
    page = page or 1
    local g     = groupItems()
    local subs  = subsPresent(g, cat)
    local pages = math.max(1, math.ceil(#subs / SUBTYPE_PAGE_SIZE))
    page = math.max(1, math.min(page, pages))
    local startIdx = (page - 1) * SUBTYPE_PAGE_SIZE + 1
    local endIdx   = math.min(startIdx + SUBTYPE_PAGE_SIZE - 1, #subs)

    local opts = {}
    for i = startIdx, endIdx do
        local sub = subs[i]
        local n   = #((g[cat] or {})[sub] or {})
        table.insert(opts, { string.format('%s (%d)', trunc(sub, 12), n),
            function(p) showSub(p, cat, sub) end })
    end
    if pages > 1 then
        if page > 1     then table.insert(opts, { '<< Prev', function(p) showCat(p, cat, page - 1) end }) end
        if page < pages then table.insert(opts, { 'Next >>', function(p) showCat(p, cat, page + 1) end }) end
    end
    table.insert(opts, { '<< Back', function(p) showVendorRoot(p) end })

    vendorMenu.title   = trunc(cat, 24)
    vendorMenu.options = opts
    openMenu(player, vendorMenu)
end

showSub = function(player, cat, sub)
    local g     = groupItems()
    local list  = (g[cat] or {})[sub] or {}
    local items = {}
    for _, it in ipairs(list) do
        items[#items + 1] = { id = it.id, cost = it.cost }
    end

    if #items <= SHOP_PAGE_SIZE then
        openMarksShop(player, items, 1)
        return
    end

    local opts  = {}
    local pages = math.ceil(#items / SHOP_PAGE_SIZE)
    for pg = 1, pages do
        local a = (pg - 1) * SHOP_PAGE_SIZE + 1
        local b = math.min(pg * SHOP_PAGE_SIZE, #items)
        table.insert(opts, { string.format('Items %d-%d', a, b),
            function(p) openMarksShop(p, items, pg) end })
    end
    table.insert(opts, { '<< Back', function(p) showCat(p, cat, 1) end })

    vendorMenu.title   = string.format('%s [%d Marks]', trunc(sub, 10), getMarks(player))
    vendorMenu.options = opts
    openMenu(player, vendorMenu)
end

--------------------------------------------------------------------
-- NPC PLACEMENT
--------------------------------------------------------------------
m:addOverride('xi.zones.Abdhaljs_Isle-Purgonorgo.Zone.onInitialize', function(zone)
    super(zone)

    local p = catalog.npcPos
    local DomainQuartermaster = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Domain_Quartermaster',
        packetName = string.format('%sDomain Quartermaster', xi.icon.STAR_LARGE),
        look       = 2419,   -- moogle (known-valid; same family as Gil Exchange)
        x          = p.x,
        y          = p.y,
        z          = p.z,
        rotation   = p.rotation,
        widescan   = 1,
        onTrigger  = function(player, npc)
            player:printToPlayer(
                '[ Domain Quartermaster ] Spoils of the domains, for Hunt Marks, kupo.',
                xi.msg.channel.SYSTEM_3)
            showVendorRoot(player)
        end,
    })
    utils.unused(DomainQuartermaster)
end)

return m
