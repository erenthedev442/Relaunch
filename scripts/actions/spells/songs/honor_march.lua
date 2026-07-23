-----------------------------------
-- Spell: Honor March
-- Gives party members Haste, Acc, Ranged Acc, Att, Ranged Att
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    if caster:getEquipID(xi.slot.RANGED) ~= xi.item.MARSYAS then
        return 1
    end

    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    if caster:getEquipID(xi.slot.RANGED) ~= xi.item.MARSYAS then
        return 0
    end

    return xi.spells.enhancing.useEnhancingSong(caster, target, spell)
end

return spellObject
