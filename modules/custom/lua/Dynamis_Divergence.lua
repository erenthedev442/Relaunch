-----------------------------------
-- Dynamis - Divergence -- entry portal NPCs (relaunch custom)
--
-- A "Divergence Portal" at each city's Dynamis entrance (Southern San d'Oria,
-- Bastok Mines, Windurst Walls, Ru'Lude Gardens). Relaunch-friendly entry: pay a
-- single Dynamis currency, confirm, and you're warped (solo OK) into that city's
-- [D] instance. Instances + waves live in scripts/zones/Dynamis-*_[D]/instances/
-- driven by the shared engine scripts/globals/dynamis_divergence.lua.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/dynamis_divergence')
require('scripts/zones/Southern_San_dOria/Zone')
require('scripts/zones/Bastok_Mines/Zone')
require('scripts/zones/Windurst_Walls/Zone')
require('scripts/zones/RuLude_Gardens/Zone')

local m = Module:new('dynamis_divergence_portals')

-- Relaunch-friendly toll (owner 2026-07-12): 250 Reforge Marks in any of the
-- three families -- AF Marks (Sky Gods), Relic Marks (Unity NMs), or Empyrean
-- Marks (Abyssea NMs). Marks are integer charVars managed by the Reforge System
-- (see modules/custom/lua/reforge_catalog.lua for the sources and rewards).
--
-- The old One-Byne-Bill toll was a stack-based item cost; marks are per-player
-- balances so the entry menu can offer all three and debit the one the player
-- picks. `name` on ENTRY_COST is kept for docgen (parses this section for the
-- entry-toll sentence on docs/endgame/dynamis-divergence.md).
local ENTRY_COST =
{
    qty  = 250,
    name = 'Reforge Marks (AF, Relic, or Empyrean)',
}

local ENTRY_OPTIONS =
{
    { cv = 'RF_AF_Marks',    short = 'AF'    },
    { cv = 'RF_Relic_Marks', short = 'Relic' },
    { cv = 'RF_Empy_Marks',  short = 'Empy'  },
}

-- One portal per city. pos = {x, y, z, rot} near each Dynamis entrance.
-- entryPos matches each city's instances/*.lua CONFIG (warp-in coordinates).
local PORTALS =
{
    { zone = 'Southern_San_dOria', instanceId = 29400, label = "San d'Oria [D]", pos = {  158.0,  -2.0,   160.0,  64 }, entryPos = { 161.838, -2.000, 161.673, 93 } },
    { zone = 'Bastok_Mines',       instanceId = 29500, label = 'Bastok [D]',     pos = {  112.0,   0.994, -70.0, 128 }, entryPos = { 116.482, 0.994, -72.121, 128 } },
    { zone = 'Windurst_Walls',     instanceId = 29600, label = 'Windurst [D]',   pos = { -217.0,   1.0,  -117.0,   0 }, entryPos = { -221.988, 1.000, -120.184, 0 } },
    { zone = 'RuLude_Gardens',     instanceId = 29700, label = 'Jeuno [D]',       pos = {   48.93, 10.0,  -69.0, 195 }, entryPos = { 48.930, 10.002, -71.032, 195 } },
}

-- Debit `qty` marks of the given charVar; returns (ok, remainingBalance).
-- Marks are simple integer charVars (no stack/inventory quirks like items).
local function consumeMarks(player, cv, qty)
    local bal = player:getCharVar(cv)
    if bal < qty then
        return false, bal
    end
    player:setCharVar(cv, bal - qty)
    return true, bal - qty
end

local function enter(player, portal, opt)
    if player:getInstance() ~= nil then
        player:printToPlayer('[Divergence] You are already bound to a rift, kupo!', xi.msg.channel.SYSTEM_3)
        return
    end
    local ok, remaining = consumeMarks(player, opt.cv, ENTRY_COST.qty)
    if not ok then
        player:printToPlayer(string.format('[Divergence] You need %d %s Marks to open the rift, kupo! (you have %d)',
            ENTRY_COST.qty, opt.short, remaining), xi.msg.channel.SYSTEM_3)
        return
    end

    local partyInst = xi.divergence.findPartyInstance(player, portal.instanceId)
    if partyInst then
        player:printToPlayer(string.format(
            '[Divergence] The rift to %s opens (paid %d %s Marks, %d remain). Good luck, kupo!',
            portal.label, ENTRY_COST.qty, opt.short, remaining), xi.msg.channel.SYSTEM_3)
        print(string.format('[Divergence] %s joining existing instance %d (%s)', player:getName(), portal.instanceId, portal.label))
        xi.divergence.joinPlayer(player, partyInst, { entryPos = portal.entryPos })
        return
    end

    player:printToPlayer(string.format('[Divergence] The rift to %s opens (paid %d %s Marks, %d remain). Good luck, kupo!',
        portal.label, ENTRY_COST.qty, opt.short, remaining), xi.msg.channel.SYSTEM_3)
    print(string.format('[Divergence] %s creating instance %d (%s)', player:getName(), portal.instanceId, portal.label))
    player:createInstance(portal.instanceId)
end

local function sendMenu(player, portal)
    local options = {}
    for _, opt in ipairs(ENTRY_OPTIONS) do
        local bal = player:getCharVar(opt.cv)
        -- Label kept tight for the ~150-byte customMenu cap: "Enter (250 X Marks - 999)".
        table.insert(options, {
            string.format('Enter (%d %s Marks - %d)', ENTRY_COST.qty, opt.short, bal),
            function(p) enter(p, portal, opt) end,
        })
    end
    table.insert(options, { 'Not yet.', function() end })
    local snapshot = { title = 'Dynamis - Divergence', options = options }
    player:timer(30, function(p) p:customMenu(snapshot) end)
end

for _, portal in ipairs(PORTALS) do
    m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', portal.zone), function(zone)
        super(zone)
        local pos = portal.pos
        local npc = zone:insertDynamicEntity({
            objtype    = xi.objType.NPC,
            name       = 'Divergence_Portal',
            packetName = string.format('%sDivergence Portal', xi.icon.STAR_LARGE),
            look       = 60,
            x          = pos[1],
            y          = pos[2],
            z          = pos[3],
            rotation   = pos[4],
            widescan   = 1,

            onTrade = function(player, npcArg, trade)
                player:printToPlayer('[Divergence] No trades -- use the menu, kupo!', xi.msg.channel.SYSTEM_3)
            end,

            onTrigger = function(player, npcArg)
                player:printToPlayer(string.format('[Divergence] I tear a rift into %s. Clear the waves, fell the Mega-Boss, and earn the right to reforge your armor, kupo!', portal.label), xi.msg.channel.SYSTEM_3)
                sendMenu(player, portal)
            end,
        })
        utils.unused(npc)
    end)
end

return m
