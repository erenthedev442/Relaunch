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
require('scripts/zones/Southern_San_dOria/Zone')
require('scripts/zones/Bastok_Mines/Zone')
require('scripts/zones/Windurst_Walls/Zone')
require('scripts/zones/RuLude_Gardens/Zone')

local m = Module:new('dynamis_divergence_portals')

-- Relaunch-friendly toll: one Dynamis currency item. Tunable.
--   1455 One Byne Bill, 1453 M. Silverpiece, 1450 L. Jadeshell, 1456 100 Byne Bill
local ENTRY_COST = { id = 1455, qty = 1, name = 'One Byne Bill' }

-- One portal per city. pos = {x, y, z, rot} near each Dynamis entrance.
local PORTALS =
{
    { zone = 'Southern_San_dOria', instanceId = 29400, label = "San d'Oria [D]", pos = {  158.0,  -2.0,   160.0,  64 } },
    { zone = 'Bastok_Mines',       instanceId = 29500, label = 'Bastok [D]',     pos = {  112.0,   0.994, -70.0, 128 } },
    { zone = 'Windurst_Walls',     instanceId = 29600, label = 'Windurst [D]',   pos = { -217.0,   1.0,  -117.0,   0 } },
    { zone = 'RuLude_Gardens',     instanceId = 29700, label = 'Jeuno [D]',       pos = {   48.93, 10.0,  -69.0, 195 } },
}

-- delItem only debits the first MAIN-inventory stack; measure the delta and refund
-- a satchel/split shortfall.
local function consume(player, id, qty)
    local before = player:getItemCount(id)
    if before < qty then
        return false
    end
    player:delItem(id, qty)
    local removed = before - player:getItemCount(id)
    if removed < qty then
        if removed > 0 then
            player:addItem({ id = id, quantity = removed })
        end
        return false
    end
    return true
end

local function enter(player, instanceId, label)
    if player:getInstance() ~= nil then
        player:printToPlayer('[Divergence] You are already bound to a rift, kupo!', xi.msg.channel.SYSTEM_3)
        return
    end
    if player:getItemCount(ENTRY_COST.id) < ENTRY_COST.qty then
        player:printToPlayer(string.format('[Divergence] You need %d %s to open the rift, kupo!',
            ENTRY_COST.qty, ENTRY_COST.name), xi.msg.channel.SYSTEM_3)
        return
    end
    if not consume(player, ENTRY_COST.id, ENTRY_COST.qty) then
        player:printToPlayer('[Divergence] Keep the toll as a single stack in your MAIN inventory and try again, kupo!', xi.msg.channel.SYSTEM_3)
        return
    end
    player:printToPlayer(string.format('[Divergence] The rift to %s opens. Good luck, kupo!', label), xi.msg.channel.SYSTEM_3)
    player:createInstance(instanceId)
end

local function sendMenu(player, portal)
    local options =
    {
        { string.format('Enter %s  (%d %s)', portal.label, ENTRY_COST.qty, ENTRY_COST.name),
            function(p) enter(p, portal.instanceId, portal.label) end },
        { 'Not yet.', function() end },
    }
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
            look       = 3000,
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
