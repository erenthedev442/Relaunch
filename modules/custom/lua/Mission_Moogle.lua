-----------------------------------
-- Mission_Moogle.lua
-- Skips all missions with Yes/No confirmation
-- Zone: GM Home (zone 210)
-----------------------------------
require('modules/module_utils')
require('scripts/zones/GM_Home/Zone')
-----------------------------------
local m = Module:new('mission_moogle')

m:addOverride('xi.zones.GM_Home.Zone.onInitialize', function(zone)
    super(zone)

    -----------------------------------
    -- Skip all missions helper function
    -----------------------------------
    local function skipAllMissions(player)
        -- San d'Oria (log_id 0)
        for i = 0, 23 do
            player:addMission(0, i)
            player:completeMission(0, i)
        end
        player:setRank(10)

        -- Bastok (log_id 1)
        for i = 0, 23 do
            player:addMission(1, i)
            player:completeMission(1, i)
        end

        -- Windurst (log_id 2)
        for i = 0, 23 do
            player:addMission(2, i)
            player:completeMission(2, i)
        end

        -- Rise of the Zilart (log_id 3)
        for i = 0, 30 do
            player:addMission(3, i)
            player:completeMission(3, i)
        end

        -- Chains of Promathia (log_id 6)
        local missionCoP = {
            101,110,118,128,138,218,228,238,248,257,258,
            318,325,335,341,350,358,368,418,428,438,448,
            518,530,543,552,560,568,578,618,628,638,648,
            718,728,738,748,758,800,818,828,840,850
        }
        for _, id in ipairs(missionCoP) do
            player:addMission(6, id)
            player:completeMission(6, id)
        end

        -- Treasures of Aht Urhgan (log_id 4)
        for i = 0, 47 do
            player:addMission(4, i)
            player:completeMission(4, i)
        end

        -- Wings of the Goddess (log_id 5)
        for i = 0, 53 do
            player:addMission(5, i)
            player:completeMission(5, i)
        end

        -- Seekers of Adoulin (log_id 12)
        local missionSOA = {
            0,1,3,5,6,7,8,9,11,12,13,14,15,16,17,18,19,20,21,23,26,27,29,
            30,31,34,35,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,
            55,56,57,58,59,61,62,63,66,67,69,70,71,72,73,74,75,76,77,78,79,
            80,81,82,84,85,86,87,88,89,90,91,92,93,94,95,96,98,99,100,101,
            102,103,104,105,107,108,109,110,111,112,113,114,116,117,118,120,
            121,123,125,129
        }
        for _, id in ipairs(missionSOA) do
            player:addMission(12, id)
            player:completeMission(12, id)
        end

        -- Rhapsodies of Vana'diel (log_id 13)
        local missionROV = {
            0,2,3,4,6,10,12,18,20,22,26,28,30,32,34,36,40,42,44,46,48,50,
            52,54,56,60,62,64,66,68,70,72,78,80,83,86,92,94,96,98,100,102,
            103,104,106,108,110,114,116,118,120,122,124,126,130,132,136,142,
            144,146,150,152,154,155,156,158,160,161,162,164,166,170,172,174,
            178,180,184,188,190,192,194,196,198,200,202,206,210,212,216,218,
            220,222,224,226
        }
        for _, id in ipairs(missionROV) do
            player:addMission(13, id)
            player:completeMission(13, id)
        end
    end

    -----------------------------------
    -- Mission Moogle NPC
    -----------------------------------
    local menu = { title = 'Mission Skip', options = {} }

    local MissionMoogle = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Mission_Moogle',
        packetName = string.format('%sMission Skip', xi.icon.STAR_LARGE),
        look       = 3017,
        -- GM Home Utility cluster (z=-14): Unlocker / KeyItem / Mission Skip.
        x          =  3.000,
        y          =  0.000,
        z          = -14.000,
        rotation   =  128,
        widescan   =  1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('No trades, kupo!', 0, npc:getPacketName())
        end,

        onTrigger = function(player, npc)
            if player:getCharVar('MissionClearanceReceived') == 1 then
                player:printToPlayer('You have already received all mission clearances, kupo!', 0, npc:getPacketName())
                return
            end

            menu.options = {
                {
                    'Yes - Skip all missions! --- Notice: This takes a bit of time',
                    function(playerArg)
                        skipAllMissions(playerArg)
                        playerArg:setCharVar('MissionClearanceReceived', 1)
                        playerArg:printToPlayer('All missions skipped, kupo! Go get it!', 0, 'Mission Skip')
                    end,
                },
                {
                    'No - Maybe later.',
                    function(playerArg)
                        playerArg:printToPlayer('No problem, kupo! Come back anytime!', 0, 'Mission Skip')
                    end,
                },
            }

            local snapshot = { title = menu.title, options = menu.options }  -- shared table + deferred send
            player:timer(50, function(playerArg)
                playerArg:customMenu(snapshot)
            end)
        end,
    })
    utils.unused(MissionMoogle)
end)

return m
