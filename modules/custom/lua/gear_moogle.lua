-----------------------------------
-- Gear_Moogle.lua
-- Starter Gear NPC in GM Home for testing
-----------------------------------
require('modules/module_utils')
require('scripts/zones/GM_Home/Zone')
-----------------------------------
local m = Module:new('gear_moogle')

m:addOverride('xi.zones.GM_Home.Zone.onInitialize', function(zone)
    super(zone)

    local GearMoogle = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Gear_Moogle',
        packetName = string.format('%sGear Moogle', xi.icon.STAR_LARGE),
        look       = 2308,
        -- GM Home Progression cluster (z=-7): Gear / Augment Moogle / Augment Sage.
        x          = -3.000,
        y          =  0.000,
        z          =  -7.000,
        rotation   =  128,
        widescan   = 1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('No trades, kupo!', 0, npc:getPacketName())
        end,

        onTrigger = function(player, npc)
            if player:getCharVar('StarterGearReceived') == 1 then
                player:printToPlayer('You have already received your starter gear, kupo!', 0, npc:getPacketName())
                return
            end

            -- A curated Lv1 kit for new characters. Using xi.item constants so
            -- IDs don't drift from comments - DB id changes will become Lua
            -- errors at load time instead of silently giving wrong items.
            local gearList = {
                -- Weapons (cover every skill type so any main job has Lv1 gear)
                { id = xi.item.BRONZE_SWORD,     qty = 1  }, -- swords (WAR/RDM/PLD/THF/DRK/BRD/RNG/SAM/NIN/DRG/RUN)
                { id = xi.item.ONION_DAGGER,     qty = 1  }, -- daggers (MNK/WHM/BLM/BST/BLU/COR/DNC/SCH/GEO/etc.)
                { id = xi.item.ONION_STAFF,      qty = 1  }, -- staves (mages)
                { id = xi.item.BRONZE_KNUCKLES,  qty = 1  }, -- hand-to-hand (MNK/PUP)
                { id = xi.item.POWER_BOW,        qty = 1  }, -- archery (RNG/COR)
                -- Armor - universal Lv1, all picked for stats over flavor
                { id = xi.item.JUSTICE_BADGE,    qty = 1  }, -- head, +1 to all stats (Lv1 GOAT)
                { id = xi.item.JUSTICE_TORQUE,   qty = 1  }, -- neck
                { id = xi.item.POWER_GI,         qty = 1  }, -- body
                { id = xi.item.LEATHER_GLOVES,   qty = 1  }, -- hands
                { id = xi.item.LEATHER_TROUSERS, qty = 1  }, -- legs
                { id = xi.item.POWER_SANDALS,    qty = 1  }, -- feet
                { id = xi.item.RABBIT_MANTLE,    qty = 1  }, -- back
                -- Consumables
                { id = xi.item.HI_POTION,        qty = 12 }, -- HP recovery
                { id = xi.item.ETHER,            qty = 12 }, -- MP recovery (for mages)
            }

            if player:getFreeSlotsCount() < #gearList then
                player:printToPlayer(string.format(
                    'You don\'t have enough inventory space, kupo! Please free up at least %d slots.',
                    #gearList
                ), 0, npc:getPacketName())
                return
            end

            for _, gear in ipairs(gearList) do
                player:addItem(gear.id, gear.qty)
            end

            player:setCharVar('StarterGearReceived', 1)
            player:printToPlayer('Here\'s your starter gear, kupo! Good luck on your adventure!', 0, npc:getPacketName())
        end,
    })
    utils.unused(GearMoogle)
end)

return m