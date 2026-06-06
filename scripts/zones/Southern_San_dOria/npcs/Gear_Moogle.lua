-----------------------------------
-- Gear_Moogle.lua
-- Starter Gear NPC
-- Gives new players a basic set of gear (one-time only).
-----------------------------------

local ID = require("scripts/zones/Southern_San_dOria/IDs")

-----------------------------------
-- onTrigger: fires when player clicks the NPC
-----------------------------------
local function onTrigger(player, npc)
    -- Check if player has already received the starter gear
    if player:getCharVar("StarterGearReceived") == 1 then
        player:PrintToPlayer("You have already received your starter gear, kupo!")
        return
    end

    -- Check inventory space (we're giving 8 items)
    if player:getFreeSlotsCount() < 8 then
        player:PrintToPlayer("You don't have enough inventory space, kupo! Please free up at least 8 slots.")
        return
    end

    -- Give starter gear
    local gearList = {
        { id = 13470, qty = 1 },  -- Bronze Sword
        { id = 13056, qty = 1 },  -- Butterfly Axe
        { id = 15000, qty = 1 },  -- Leather Vest
        { id = 15361, qty = 1 },  -- Leather Trousers
        { id = 15552, qty = 1 },  -- Leather Gloves
        { id = 15649, qty = 1 },  -- Leather Boots
        { id = 740,   qty = 12 }, -- Hi-Potion x12
        { id = 4107,  qty = 1 },  -- Sleeping Bag
    }

    for _, gear in ipairs(gearList) do
        player:addItem(gear.id, gear.qty)
    end

    -- Mark as received so they can't get it again
    player:setCharVar("StarterGearReceived", 1)

    player:PrintToPlayer("Here's your starter gear, kupo! Good luck on your adventure!")
end

-----------------------------------
return {
    onTrigger = onTrigger,
}