-----------------------------------
-- Regulator
-- Absorbs one beneficial effect from the target.
-----------------------------------
---@type TAbilityAutomaton
local abilityObject = {}

abilityObject.onAutomatonAbilityCheck = function(target, automaton, skill)
    return 0
end

abilityObject.onAutomatonAbility = function(target, automaton, skill, master, action)
    automaton:addRecast(xi.recast.ABILITY, skill:getID(), 60)

    local absorbedEffect = automaton:stealStatusEffect(target, xi.effectFlag.DISPELABLE) or 0

    if absorbedEffect ~= 0 then
        skill:setMsg(xi.msg.basic.EFFECT_DRAINED)
        return 1
    end

    skill:setMsg(xi.msg.basic.JA_NO_EFFECT_2)
    return 0
end

return abilityObject
