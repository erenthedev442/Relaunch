require("scripts/globals/npc_util")

-----------------------------------
-- Area: Southern San d'Oria
-- NPC: Legendary Gear Giver
-- Gives new players starting gear (must talk to NPC)
-----------------------------------
local entity = {}

entity.onTrigger = function(player, npc)
    if player:getMainLvl() <= 15 and player:getCharVar("ReceivedLegendaryStarterGear") == 0 then
        
        player:PrintToPlayer("Welcome to LEGENDARY!", xi.msg.channel.SYSTEM)
        player:PrintToPlayer("Here's a strong set of starting gear to help you on your journey.", xi.msg.channel.SYSTEM)

        -- === Customize this gear set as needed ===
        player:addItem(12565)  -- Bronze Harness
        player:addItem(12688)  -- Bronze Mittens
        player:addItem(12816)  -- Bronze Subligar
        player:addItem(12944)  -- Bronze Leggings
        player:addItem(16648)  -- Bronze Axe (or change to sword, etc.)

        -- Accessories & Consumables
        player:addItem(15500, 1)  -- Wing Pendant
        player:addItem(4128, 20)  -- Potion
        player:addItem(4150, 10)  -- Ether

        player:setCharVar("ReceivedLegendaryStarterGear", 1)
        player:messageBasic(xi.msg.basic.OBTAINED_ITEM, 1)
        
    else
        player:PrintToPlayer("You've already received your starting gear set.", xi.msg.channel.SYSTEM)
    end
end

return entity