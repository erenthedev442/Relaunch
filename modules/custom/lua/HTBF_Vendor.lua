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
local NPCPOS  = { x = 592.000, y = -3.360, z = 516.500, rot = 135 }

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

local showMenu, showCategory, showBuy, showWarpMenu, showWarpCategory

-- Top level: one button per expansion category, plus a warp shortcut. A flat
-- 16-gem list would exceed both client caps (8 options / 150 bytes) and hide
-- gems, so we drill down.
showMenu = function(p)
    local options = {}
    for _, cat in ipairs(catalog.gemCategories) do
        local cc = cat
        options[#options + 1] = { cc.label, function(pp) showCategory(pp, cc) end }
    end
    options[#options + 1] = { 'Warp to a Battlefield', function(pp) showWarpMenu(pp) end }
    options[#options + 1] = { 'Close', function(pp) end }
    p:timer(30, function(pp) pp:customMenu({ title = 'Phantom Gems', options = options }) end)
end

-- Warp: same expansion grouping as the gems. Free QoL teleport straight to a
-- battlefield entrance (you still need the gem + a clear to enter the fight).
showWarpMenu = function(p)
    local options = {}
    for _, grp in ipairs(catalog.warpDestinations) do
        local gg = grp
        options[#options + 1] = { gg.label, function(pp) showWarpCategory(pp, gg) end }
    end
    options[#options + 1] = { 'Back', function(pp) showMenu(pp) end }
    p:timer(30, function(pp) pp:customMenu({ title = 'Warp -- pick expansion', options = options }) end)
end

-- One expansion's battlefields (<= 6). Selecting one teleports the player to
-- that entrance's zone/coords via cross-zone setPos(x, y, z, rot, zone).
showWarpCategory = function(p, grp)
    local options = {}
    for _, d in ipairs(grp.dests) do
        local dd = d
        options[#options + 1] = {
            dd.name,
            function(pp)
                pp:printToPlayer(string.format('[HTBF] Warping to %s...', dd.name), SYS)
                pp:setPos(dd.x, dd.y, dd.z, dd.rot, dd.zone)
            end,
        }
    end
    options[#options + 1] = { 'Back', function(pp) showWarpMenu(pp) end }
    p:timer(30, function(pp) pp:customMenu({ title = grp.label, options = options }) end)
end

-- One category's gems (<= 8). "* " marks a gem already held. Short labels + kPrice
-- keep the menu under the byte cap; the full name + exact price show on buy.
showCategory = function(p, cat)
    local options = {}
    p:printToPlayer('[HTBF] * means that gem is already in your key-item inventory.', SYS)
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
    p:printToPlayer(string.format(
        '[HTBF] %s -- %s gil. Entry requires 2,100 spent JP on your current job and all NM affinities.',
        g.name, commafy(g.price)), SYS)
    p:printToPlayer('[HTBF] Trade it at the battlefield entrance and pick Tier I, II, or III.', SYS)
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
