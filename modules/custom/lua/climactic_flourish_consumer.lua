-----------------------------------
-- climactic_flourish_consumer.lua
--
-- Removes EFFECT_CLIMACTIC_FLOURISH after the next weaponskill, matching
-- retail's "next weaponskill is a forced crit" semantic.
--
-- Why this lives in a custom module: LSB's engine doesn't consume the
-- effect on hits. Rather than patching C++, we hook the WEAPONSKILL_USE
-- listener at login and clear the effect the moment the player fires any
-- weaponskill while it's up. Auto-attacks during the 60s window are still
-- crits (slightly stronger than retail's per-hit consumption), but for
-- Rudra's Storm / Evisceration / etc. burst usage the practical result
-- matches retail: one guaranteed crit-boosted WS.
-----------------------------------
require('modules/module_utils')

local m = Module:new('climactic_flourish_consumer')

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)

    player:addListener('WEAPONSKILL_USE', 'CLIMACTIC_FLOURISH_CONSUME',
        function(attacker, defender, wsSpell, tp, action, damage)
            if attacker and attacker:hasStatusEffect(xi.effect.CLIMACTIC_FLOURISH) then
                pcall(function() attacker:delStatusEffect(xi.effect.CLIMACTIC_FLOURISH) end)
            end
        end)
end)

return m
