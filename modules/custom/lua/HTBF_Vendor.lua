-----------------------------------
-- HTBF_Vendor.lua  -- "Phantom Gems" vendor (relaunch, Leafallia hub)
--
-- Sells the High-Tier Mission Battlefield entry Phantom Gems (key items) for
-- gil. The player buys a gem here, travels to the battlefield's zone, trades the
-- gem at the entrance, and picks a difficulty tier (I/II/III). See htbf_catalog
-- + htbf.lua for the battlefield side.
--
-- Gems are key items (binary: one at a time), so the menu blocks a re-buy while
-- you already hold one. Needs a map restart to load (addOverride NPC).
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Abdhaljs_Isle-Purgonorgo/Zone')

local catalog = require('modules/custom/lua/htbf_catalog')
local m       = Module:new('htbf_vendor')
local SYS     = xi.msg.channel.SYSTEM_3
local NPCPOS  = { x = 566.971, y = -3.360, z = 544.586, rot = 64 }

local function commafy(n)
    local s = tostring(math.floor(n))
    return (s:reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', ''))
end

-- Short forms keep each customMenu under the client's 150-byte (title+labels)
-- cap: drop the "Phantom Gem" boilerplate and abbreviate the price as "150k".
local function shortName(name)
    return (name:gsub(' Phantom Gem$', ''):gsub('^Phantom Gem of ', ''))
end

local function kPrice(n)
    return string.format('%dk', math.floor(n / 1000))
end

local function gemOf(id)
    return { id = id, price = catalog.gemPrice[id], name = catalog.gemName[id] or ('Phantom Gem ' .. id) }
end

local showMenu, showCategory, showBuy

-- Top level: one button per expansion category. A flat 16-gem list would exceed
-- both client caps (8 options / 150 bytes) and hide gems, so we drill down.
showMenu = function(p)
    local options = {}
    for _, cat in ipairs(catalog.gemCategories) do
        local cc = cat
        options[#options + 1] = { cc.label, function(pp) showCategory(pp, cc) end }
    end
    options[#options + 1] = { 'Close', function(pp) end }
    p:timer(30, function(pp) pp:customMenu({ title = 'Phantom Gems', options = options }) end)
end

-- One category's gems (<= 8). "* " marks a gem already held. Short labels + kPrice
-- keep the menu under the byte cap; the full name + exact price show on buy.
showCategory = function(p, cat)
    local options = {}
    for _, id in ipairs(cat.gems) do
        local g     = gemOf(id)
        local owned = p:hasKeyItem(id)
        options[#options + 1] = {
            string.format('%s (%s)%s', shortName(g.name), kPrice(g.price), owned and ' *' or ''),
            function(pp) showBuy(pp, g) end,
        }
    end
    options[#options + 1] = { 'Back', function(pp) showMenu(pp) end }
    p:timer(30, function(pp) pp:customMenu({ title = cat.label, options = options }) end)
end

showBuy = function(p, g)
    if p:hasKeyItem(g.id) then
        p:printToPlayer(string.format('[HTBF] You already hold the %s -- use it before buying another.', g.name), SYS)
        showMenu(p)
        return
    end
    p:printToPlayer(string.format('[HTBF] %s -- %s gil. Trade it at the battlefield entrance and pick a tier (I/II/III).',
        g.name, commafy(g.price)), SYS)
    p:timer(30, function(pp)
        pp:customMenu({
            title   = string.format('Buy %s?', g.name),
            options =
            {
                {
                    string.format('Yes (%s gil)', commafy(g.price)),
                    function(q)
                        if q:hasKeyItem(g.id) then showMenu(q); return end
                        if q:getGil() < g.price then
                            q:printToPlayer(string.format('[HTBF] You need %s gil.', commafy(g.price)), SYS)
                            showMenu(q)
                            return
                        end
                        q:delGil(g.price)
                        npcUtil.giveKeyItem(q, g.id)
                        q:printToPlayer(string.format('[HTBF] Purchased the %s.', g.name), SYS)
                        showMenu(q)
                    end,
                },
                { 'No', function(q) showMenu(q) end },
            },
        })
    end)
end

m:addOverride('xi.zones.Abdhaljs_Isle-Purgonorgo.Zone.onInitialize', function(zone)
    super(zone)
    zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'HTBF_Gem_Vendor',
        packetName = string.format('%sPhantom Gems', xi.icon.STAR_LARGE),
        look       = 200,
        x          = NPCPOS.x,
        y          = NPCPOS.y,
        z          = NPCPOS.z,
        rotation   = NPCPOS.rot,
        widescan   = 1,
        onTrigger  = function(player, npc)
            player:printToPlayer('[HTBF] Phantom Gems for High-Tier Mission Battlefields -- buy with gil, trade at the battlefield entrance.', SYS)
            showMenu(player)
        end,
    })
end)

return m
