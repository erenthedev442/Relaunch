-----------------------------------
-- AbysseaPermanentVisitant
-- Gives all players permanent Visitant status when entering Abyssea,
-- removing the need to manage Traverser Stones or time limits.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/abyssea')

local m = Module:new('AbysseaPermanentVisitant')

m:addOverride('xi.abyssea.afterZoneIn', function(player)
    if not player:hasStatusEffect(xi.effect.VISITANT) then
        player:addStatusEffect(xi.effect.VISITANT, { origin = player })
    end
end)

return m
