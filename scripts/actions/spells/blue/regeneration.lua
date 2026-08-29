-----------------------------------
-- Spell: Regeneration
-- Gradually restores HP
-- Spell cost: 36 MP
-- Monster Type: Aquans
-- Spell Type: Magical (Light)
-- Blue Magic Points: 2
-- Stat Bonus: MND+2
-- Level: 78
-- Casting Time: 2 Seconds
-- Recast Time: 60 Seconds
-- Spell Duration: 30 ticks, 90 Seconds
-----------------------------------
-- Combos: None
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local power = 75
    local duration = xi.spells.blue.calculateDurationWithDiffusion(caster, 300)

    if
        target:hasStatusEffect(xi.effect.REGEN) and
        target:getStatusEffect(xi.effect.REGEN):getTier() == 1
    then
        target:delStatusEffect(xi.effect.REGEN)
    end

    if not target:addStatusEffect(xi.effect.REGEN, { power = power, duration = duration, origin = caster, tick = 3 }) then
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
    end

    return xi.effect.REGEN
end

return spellObject
