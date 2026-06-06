-----------------------------------
-- Southern San d'Oria Starter NPCs
-- 1. Gear_Moogle    - Gives starter gear (one-time)
-- 2. Mission_Moogle - Grants clearance for all missions
-- 3. KeyItem_Moogle - Grants every key item in the game
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Southern_San_dOria/Zone')
-----------------------------------
local m = Module:new('mission_moogle')

m:addOverride('xi.zones.Southern_San_dOria.Zone.onInitialize', function(zone)
    super(zone)

 
    -----------------------------------
    -- NPC 2: Mission Moogle
    -- Grants clearance for all missions
    -- Position: offset +3.0 on X axis
    -----------------------------------
    zone:insertDynamicEntity({
        objtype  = xi.objType.NPC,
        name     = 'Mission_Moogle',
        look     = 2430,
        x        =  1.8,
        y        = -9.4,
        z        =  2.0,
        rotation =  0,
        widescan =  1,

        onTrigger = function(player, npc)
            if player:getCharVar('MissionClearanceReceived') == 1 then
                player:printToPlayer('You have already received mission clearance, kupo!')
                return
            end

            -- San d'Oria missions (Rank 1-10)
            player:setMissionStatus(xi.mission.log_id.SANDORIA, 0)
            player:setRank(10, xi.nation.SANDORIA)
            for i = 1, 10 do
                player:setMission(xi.mission.log_id.SANDORIA, i)
            end

            -- Bastok missions (Rank 1-10)
            player:setMissionStatus(xi.mission.log_id.BASTOK, 0)
            player:setRank(10, xi.nation.BASTOK)
            for i = 1, 10 do
                player:setMission(xi.mission.log_id.BASTOK, i)
            end

            -- Windurst missions (Rank 1-10)
            player:setMissionStatus(xi.mission.log_id.WINDURST, 0)
            player:setRank(10, xi.nation.WINDURST)
            for i = 1, 10 do
                player:setMission(xi.mission.log_id.WINDURST, i)
            end

            -- Rise of the Zilart
            for i = 1, 16 do
                player:setMission(xi.mission.log_id.ZILART, i)
            end

            -- Chains of Promathia
            for i = 1, 8 do
                player:setMission(xi.mission.log_id.COP, i)
            end

            -- Treasures of Aht Urhgan
            for i = 1, 49 do
                player:setMission(xi.mission.log_id.TOAU, i)
            end

            -- Wings of the Goddess
            for i = 1, 20 do
                player:setMission(xi.mission.log_id.WOTG, i)
            end

            -- Seekers of Adoulin
            for i = 1, 20 do
                player:setMission(xi.mission.log_id.SOA, i)
            end

            player:setCharVar('MissionClearanceReceived', 1)
            player:printToPlayer('All mission clearances granted, kupo! You\'re ready for anything!')
        end,
    })
end)
return m
