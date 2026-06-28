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
require('scripts/zones/Leafallia/Zone')

local catalog = require('modules/custom/lua/htbf_catalog')
local m       = Module:new('htbf_vendor')
local SYS     = xi.msg.channel.SYSTEM_3
local NPCPOS  = { x = -4.000, y = 0.000, z = 20.000, rot = 128 }

local function commafy(n)
    local s = tostring(math.floor(n))
    return (s:reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', ''))
end

-- Stable list of sellable gems from the catalog.
local gems = {}
for id, price in pairs(catalog.gemPrice) do
    gems[#gems + 1] = { id = id, price = price, name = catalog.gemName[id] or ('Phantom Gem ' .. id) }
end
table.sort(gems, function(a, b) return a.id < b.id end)

local showMenu, showBuy

showMenu = function(p)
    local options = {}
    for _, g in ipairs(gems) do
        local gg    = g
        local owned = p:hasKeyItem(gg.id)
        options[#options + 1] = {
            string.format('%s (%s)%s', gg.name, commafy(gg.price), owned and ' *' or ''),
            function(pp) showBuy(pp, gg) end,
        }
    end
    options[#options + 1] = { 'Close', function(pp) end }
    p:timer(30, function(pp) pp:customMenu({ title = 'Phantom Gems  (* = held)', options = options }) end)
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

m:addOverride('xi.zones.Leafallia.Zone.onInitialize', function(zone)
    super(zone)
    zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'HTBF_Gem_Vendor',
        packetName = string.format('%sPhantom Gems', xi.icon.STAR_LARGE),
        look       = 2419,
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
