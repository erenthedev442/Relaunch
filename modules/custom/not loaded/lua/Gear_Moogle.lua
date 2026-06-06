-----------------------------------
-- Gear_Moogle.lua
-- Starter Gear NPC via Dynamic Entity
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Southern_San_dOria/Zone')
-----------------------------------
local m = Module:new('gear_moogle')

m:addOverride('xi.zones.Southern_San_dOria.Zone.onInitialize', function(zone)
    super(zone)

    zone:insertDynamicEntity({
        objtype   = xi.objType.NPC,
        name      = 'Gear Moogle',
        look      = 2431,
        x         = -1.2,
        y         = -9.4,
        z         = 2.0,
        rotation  = 0,
        widescan  = 1,

        onTrigger = function(player, npc)
            if player:getCharVar('StarterGearReceived') == 1 then
                player:printToPlayer('You have already received your starter gear, kupo!')
                return
            end

            if player:getFreeSlotsCount() < 8 then
                player:printToPlayer('You don\'t have enough inventory space, kupo! Please free up at least 8 slots.')
                return
            end

            local gearList = {
                { id = 13470, qty = 1  }, -- Bronze Sword
                { id = 13056, qty = 1  }, -- Butterfly Axe
                { id = 15000, qty = 1  }, -- Leather Vest
                { id = 15361, qty = 1  }, -- Leather Trousers
                { id = 15552, qty = 1  }, -- Leather Gloves
                { id = 15649, qty = 1  }, -- Leather Boots
                { id = 740,   qty = 12 }, -- Hi-Potion x12
                { id = 4107,  qty = 1  }, -- Sleeping Bag
            }

            for _, gear in ipairs(gearList) do
                player:addItem(gear.id, gear.qty)
            end

            player:setCharVar('StarterGearReceived', 1)
            player:printToPlayer('Here\'s your starter gear, kupo! Good luck on your adventure!')
        end,
    })
end)

return m