-----------------------------------
-- KeyItem_Moogle.lua
-- Grants every key item in the game
-- Zone: GM Home (zone 210)
-----------------------------------
require('modules/module_utils')
require('scripts/zones/GM_Home/Zone')
-----------------------------------
local m = Module:new('keyitem_moogle')

m:addOverride('xi.zones.GM_Home.Zone.onInitialize', function(zone)
    super(zone)

    local menu = { title = 'Key Items', options = {} }

    local KeyItemMoogle = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'KeyItem_Moogle',
        packetName = string.format('%sKeyItem Moogle', xi.icon.STAR_LARGE),
        look       = 2364,
        -- GM Home Utility cluster (z=-14): Unlocker / KeyItem / Mission Skip.
        x          =  0.000,
        y          =  0.000,
        z          = -14.000,
        rotation   =  128,
        widescan   =  1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('No trades, kupo!', 0, npc:getPacketName())
        end,

        onTrigger = function(player, npc)
            if player:getCharVar('KeyItemsReceived') == 1 then
                player:printToPlayer('You have already received all key items, kupo!', 0, npc:getPacketName())
                return
            end

            menu.options = {
                {
                    'Yes - Give me all key items! --- Notice: This takes a bit of time',
                    function(playerArg)
                        local added   = 0
                        local skipped = 0

                        for i = 1, 4000 do
                            if not playerArg:hasKeyItem(i) then
                                local ok = pcall(function()
                                    playerArg:addKeyItem(i)
                                end)
                                if ok then
                                    added = added + 1
                                else
                                    skipped = skipped + 1
                                end
                            end
                        end

                        playerArg:setCharVar('KeyItemsReceived', 1)
                        playerArg:printToPlayer(string.format(
                            'All key items granted, kupo! Added: %d, Skipped: %d',
                            added, skipped
                        ), 0, 'KeyItem_Moogle')
                    end,
                },
                {
                    'No - Maybe later.',
                    function(playerArg)
                        playerArg:printToPlayer('No problem, kupo! Come back anytime!', 0, 'KeyItem_Moogle')
                    end,
                },
            }

            local snapshot = { title = menu.title, options = menu.options }  -- shared table + deferred send
            player:timer(50, function(playerArg)
                playerArg:customMenu(snapshot)
            end)
        end,
    })
    utils.unused(KeyItemMoogle)
end)

return m
