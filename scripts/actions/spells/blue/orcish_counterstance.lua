-----------------------------------
-- Spell: Ochre Counterstance
-- Enhances counter rate and counter damage
-- Spell cost: 18 MP
-- Monster Type: Lizards
-- Spell Type: Magical (Fire)
-- Blue Magic Points: 3
-- Stat Bonus: VIT+2
-- Level: 98
-- Casting Time: 4.5 seconds
-- Recast Time: 120 seconds
-- Duration: 3 minutes
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local duration = xi.spells.blue.calculateDurationWithDiffusion(caster, 180)

    if not caster:addStatusEffect(xi.effect.COUNTER_BOOST, { power = 50, duration = duration, origin = caster }) then
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
    end

    return xi.effect.COUNTER_BOOST
end

return spellObject
