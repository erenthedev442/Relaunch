-----------------------------------
-- Spell: Barrier Tusk
-- Reduces damage taken by 15%
-- Spell cost: 41 MP
-- Monster Type: Beasts
-- Spell Type: Magical (Earth)
-- Blue Magic Points: 4
-- Stat Bonus: Max HP Boost
-- Level: 91
-- Casting Time: 6 seconds
-- Recast Time: 60 seconds
-- Duration: 3 minutes
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local duration = xi.spells.blue.calculateDurationWithDiffusion(caster, 180)

    if not target:addStatusEffect(xi.effect.PHALANX, { power = 15, duration = duration, origin = caster }) then
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
    end

    return xi.effect.PHALANX
end

return spellObject
