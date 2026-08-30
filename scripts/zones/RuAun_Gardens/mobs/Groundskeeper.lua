-----------------------------------
-- Area: RuAun Gardens
--  Mob: Groundskeeper
-- Note: Despot is a 30-minute Hunt Guild camp, not a lottery NM.
-----------------------------------
---@type TMobEntity
local entity = {}

entity.onMobDeath = function(mob, player, optParams)
    xi.regime.checkRegime(player, mob, 143, 2, xi.regime.type.FIELDS)
    xi.regime.checkRegime(player, mob, 144, 1, xi.regime.type.FIELDS)
end

return entity
