-----------------------------------
-- climactic_flourish_consumer.lua
--
-- Spend one Climactic charge per landed auto-attack. Weaponskill hits
-- spend theirs in scripts/globals/weaponskills.lua (getSingleHitDamage)
-- so a 5-hit WS with 5 finishing moves crits all five swings.
-----------------------------------
require('modules/module_utils')

local m = Module:new('climactic_flourish_consumer')

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)

    player:addListener('MELEE_SWING_HIT', 'CLIMACTIC_FLOURISH_CONSUME',
        function(attacker)
            if attacker and xi.job_utils and xi.job_utils.dancer then
                pcall(xi.job_utils.dancer.consumeClimacticCharge, attacker)
            end
        end)
end)

return m
