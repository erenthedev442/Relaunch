-----------------------------------
-- Spell: Harden Shell
-- Enhances defense by 100%
-- Spell cost: 20 MP
-- Monster Type: Aquans
-- Spell Type: Magical (Earth)
-- Blue Magic Points: 3
-- Stat Bonus: VIT+3
-- Level: 95
-- Casting Time: 1.5 seconds
-- Recast Time: 25 seconds
-- Duration: 90 seconds
-- Requires Unbridled Learning
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local duration = xi.spells.blue.calculateDurationWithDiffusion(caster, 90)

    if not caster:addStatusEffect(xi.effect.DEFENSE_BOOST, { power = 100, duration = duration, origin = caster }) then
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
    end

    return xi.effect.DEFENSE_BOOST
end

return spellObject
