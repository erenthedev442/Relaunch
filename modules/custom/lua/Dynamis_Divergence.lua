-----------------------------------
-- Dynamis - Divergence -- entry portal NPC (relaunch custom)
--
-- Adds a "Divergence Portal" at the San d'Oria Dynamis entrance (Southern
-- San d'Oria). Relaunch-friendly entry: pay a single Dynamis currency, confirm,
-- and you're warped (solo OK) into the San d'Oria [D] instance (29400). The
-- instance + waves live in scripts/zones/Dynamis-San_dOria_[D]/instances/ and
-- the shared engine scripts/globals/dynamis_divergence.lua.
--
-- (Phase 1 slice: San d'Oria only. Bastok/Windurst/Jeuno portals come with the
--  replication phase -- this file is the template.)
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Southern_San_dOria/Zone')

local m = Module:new('dynamis_divergence_portal')

local NPC_POS = { x = 158.0, y = -2.0, z = 160.0, rot = 64 }

-- Relaunch-friendly toll: one Dynamis currency item. Tunable.
--   1455 One Byne Bill, 1453 M. Silverpiece, 1450 L. Jadeshell, 1456 100 Byne Bill
local ENTRY_COST  = { id = 1455, qty = 1, name = 'One Byne Bill' }
local INSTANCE_ID = 29400 -- Dynamis - San d'Oria [D]
-- TODO (relaunch tuning): optional light daily lockout. Disabled for now.

-- delItem only debits the first MAIN-inventory stack, while getItemCount spans all
-- containers -- so measure the real delta and refund a satchel/split shortfall.
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

m:addOverride('xi.zones.Southern_San_dOria.Zone.onInitialize', function(zone)
    super(zone)

    local function enter(player)
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
        player:printToPlayer('[Divergence] The rift to San d\'Oria [D] opens. Good luck, kupo!', xi.msg.channel.SYSTEM_3)
        player:createInstance(INSTANCE_ID)
    end

    local function sendMenu(player)
        local options =
        {
            { string.format('Enter San d\'Oria [D]  (%d %s)', ENTRY_COST.qty, ENTRY_COST.name),
                function(p) enter(p) end },
            { 'Not yet.', function() end },
        }
        local snapshot = { title = 'Dynamis - Divergence', options = options }
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    local portal = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Divergence_Portal',
        packetName = string.format('%sDivergence Portal', xi.icon.STAR_LARGE),
        look       = 3000,
        x          = NPC_POS.x,
        y          = NPC_POS.y,
        z          = NPC_POS.z,
        rotation   = NPC_POS.rot,
        widescan   = 1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('[Divergence] No trades -- use the menu, kupo!', xi.msg.channel.SYSTEM_3)
        end,

        onTrigger = function(player, npc)
            player:printToPlayer('[Divergence] I tear rifts into Dynamis - Divergence. Clear the waves, fell the Mega-Boss, and earn the right to reforge your armor, kupo!', xi.msg.channel.SYSTEM_3)
            sendMenu(player)
        end,
    })
    utils.unused(portal)
end)

return m
