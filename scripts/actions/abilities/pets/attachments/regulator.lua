-----------------------------------
-- Attachment: Regulator
-- Absorbs one beneficial effect every 60 seconds while a Dark Maneuver is active.
-----------------------------------
---@type TAttachment
local attachmentObject = {}

attachmentObject.onEquip = function(pet)
    if not pet then
        return
    end

    pet:addListener('AUTOMATON_ATTACHMENT_CHECK', 'ATTACHMENT_REGULATOR', function(automaton, target)
        if
            not automaton or
            not target or
            automaton:hasRecast(xi.recast.ABILITY, xi.automaton.abilities.REGULATOR) or
            not target:hasStatusEffectByFlag(xi.effectFlag.DISPELABLE)
        then
            return
        end

        local master = automaton:getMaster()

        if master and master:countEffect(xi.effect.DARK_MANEUVER) > 0 then
            automaton:useMobAbility(xi.automaton.abilities.REGULATOR)
        end
    end)
end

attachmentObject.onUnequip = function(pet)
    if pet then
        pet:removeListener('ATTACHMENT_REGULATOR')
    end
end

return attachmentObject
