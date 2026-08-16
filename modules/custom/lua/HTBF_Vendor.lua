-----------------------------------
-- HTBF_Vendor.lua  -- "Phantom Gems" vendor (relaunch, Leafallia hub)
--
-- Sells the High-Tier Mission Battlefield entry Phantom Gems (key items) for
-- gil. The player buys a gem here, travels to the battlefield's zone, interacts
-- with the entrance while holding it, and picks a tier. Tier III is hidden until
-- one-time Final Proving is complete. See htbf_catalog + htbf.lua.
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

local showMenu, showCategory, showBuy, showWarpMenu, showWarpCategory, showFinalTest

local function warpToFinalTest(p)
    local dest = catalog.finalTest.warp
    p:printToPlayer(
        '[HTBF] Warping to Final Proving. Use the entrance while holding the Avatar Phantom Gem, then choose the final blank row.',
        SYS)
    p:setPos(dest.x, dest.y, dest.z, dest.rot, dest.zone)
end

-- Top-level labels MUST stay short: SetCustomMenuContext quote-wraps title +
-- every option and the client only keeps Mes[150]. Before Final Proving the
-- menu was already ~155 bytes -- Close was truncated. After completion the
-- longer "Final Test [Done]" label pushed Warp into the truncated tail, so
-- "Warp to a Battlefield" silently no-op'd (player reports 2026-08-13).
local TOP_CAT_SHORT =
{
    ['Avatar Prime Trials']     = 'Avatars',
    ['Chains of Promathia']     = 'CoP',
    ['Treasures of Aht Urhgan'] = 'ToAU',
    ['Rise of the Zilart']      = 'Zilart',
    ['Ark Angels']              = 'Ark Angels',
}

-- Top level: one button per expansion category, plus a warp shortcut. A flat
-- 16-gem list would exceed both client caps (8 options / 150 bytes) and hide
-- gems, so we drill down.
showMenu = function(p)
    local progress = catalog.progress.get(p)
    local finalDone = progress.finalProving
    -- Keep both states tiny ("Final*" vs "Final Test [Done]") so Warp fits.
    local finalLabel = finalDone and 'Final*' or 'Final'
    local options =
    {
        { finalLabel, function(pp) showFinalTest(pp) end },
    }
    for _, cat in ipairs(catalog.gemCategories) do
        local cc = cat
        local lbl = TOP_CAT_SHORT[cc.label] or cc.label
        options[#options + 1] = { lbl, function(pp) showCategory(pp, cc) end }
    end
    options[#options + 1] = { 'Warp to HTBF', function(pp) showWarpMenu(pp) end }
    options[#options + 1] = { 'Close', function(pp) end }
    p:timer(30, function(pp) pp:customMenu({ title = 'Phantom Gems', options = options }) end)
end

-- One-time progression bridge: after T1 and T2, buy/use the normal Avatar
-- Phantom Gem against a half-strength T3 Garuda. Its completion unlocks every
-- real T3 and supplies the T3 clear flag Ambuscade already checks.
showFinalTest = function(p)
    local final      = catalog.finalTest
    local progress  = catalog.progress.get(p)
    local finalDone  = progress.finalProving
    local clearedT1 = progress.tier1
    local clearedT2 = progress.tier2

    if finalDone then
        p:printToPlayer(
            '[HTBF] Final Proving is complete. All real Tier III battlefields are unlocked.',
            SYS)
        p:timer(30, function(pp)
            pp:customMenu({
                title = 'Final Proving: complete',
                options =
                {
                    { 'Warp to Garuda HTBF', function(q) warpToFinalTest(q) end },
                    { 'Back', function(q) showMenu(q) end },
                },
            })
        end)
        return
    end

    if not clearedT1 or not clearedT2 then
        local missing = {}
        if not clearedT1 then missing[#missing + 1] = 'Tier I' end
        if not clearedT2 then missing[#missing + 1] = 'Tier II' end
        p:printToPlayer(
            string.format('[HTBF] Final Proving is locked. Clear any HTBF at %s first.', table.concat(missing, ' and ')),
            SYS)
        p:timer(30, function(pp)
            pp:customMenu({
                title = 'Final Proving: locked',
                options = { { 'Back', function(q) showMenu(q) end } },
            })
        end)
        return
    end

    local gem = gemOf(xi.ki.AVATAR_PHANTOM_GEM)
    p:printToPlayer(
        '[HTBF] Final Proving is a one-time, half-strength Tier III Garuda test. Winning unlocks all real T3 fights and Ambuscade T3 credit.',
        SYS)

    local options = {}
    if p:hasKeyItem(gem.id) then
        options[#options + 1] = { 'Warp to Final Proving', function(pp) warpToFinalTest(pp) end }
    else
        options[#options + 1] =
        {
            string.format('Buy Gem + Warp (%s)', kPrice(gem.price)),
            function(pp)
                if pp:getGil() < gem.price then
                    pp:printToPlayer(string.format('[HTBF] You need %s gil.', commafy(gem.price)), SYS)
                    showFinalTest(pp)
                    return
                end
                pp:delGil(gem.price)
                npcUtil.giveKeyItem(pp, gem.id)
                pp:printToPlayer(string.format('[HTBF] Purchased the %s.', gem.name), SYS)
                warpToFinalTest(pp)
            end,
        }
    end
    options[#options + 1] = { 'Back', function(pp) showMenu(pp) end }
    p:timer(30, function(pp)
        pp:customMenu({ title = 'Final Proving: Garuda', options = options })
    end)
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
    local useHint = catalog.gemUseHint and catalog.gemUseHint[g.id]
    if p:hasKeyItem(g.id) then
        p:printToPlayer(string.format('[HTBF] You already hold the %s -- use it before buying another.', g.name), SYS)
        if useHint then
            p:printToPlayer('[HTBF] ' .. useHint, SYS)
        end
        showMenu(p)
        return
    end
    p:printToPlayer(string.format(
        '[HTBF] %s -- %s gil. Entry requires 2,100 spent JP on your current job and all NM affinities.',
        g.name, commafy(g.price)), SYS)
    if useHint then
        p:printToPlayer('[HTBF] ' .. useHint, SYS)
    end
    local tier3Open = (p:getCharVar(catalog.finalTest.completionVar) or 0) >= 1
        or (p:getCharVar(catalog.finalTest.tierClearVar) or 0) >= 1
    p:printToPlayer(
        tier3Open and
            '[HTBF] Use the battlefield entrance while holding it, then pick Tier I, II, or III.' or
            '[HTBF] Use the battlefield entrance while holding it, then pick Tier I or II. Final Proving unlocks Tier III.',
        SYS)
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
        packetName = string.format('%sHTBF Vendor', xi.icon.STAR_LARGE),
        look       = 200,
        x          = NPCPOS.x,
        y          = NPCPOS.y,
        z          = NPCPOS.z,
        rotation   = NPCPOS.rot,
        widescan   = 1,
        onTrigger  = function(player, npc)
            player:printToPlayer('[HTBF] Phantom Gems for High-Tier Mission Battlefields -- buy with gil, then use the battlefield entrance while holding one.', SYS)
            showMenu(player)
        end,
    })
end)

return m
