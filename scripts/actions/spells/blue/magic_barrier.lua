-----------------------------------
-- Spell: Magic Barrier
-- Creates a barrier that absorbs magic damage
-- Spell cost: 29 MP
-- Monster Type: Arcana
-- Spell Type: Magical (Dark)
-- Blue Magic Points: 3
-- Stat Bonus: MND+1
-- Level: 82
-- Casting Time: 5 seconds
-- Recast Time: 60 seconds
-- Duration: 5 minutes
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local blueSkill = caster:getSkillLevel(xi.skill.BLUE_MAGIC)
    local power     = blueSkill
    local duration  = xi.spells.blue.calculateDurationWithDiffusion(caster, 300)

    if not caster:addStatusEffect(xi.effect.MAGIC_SHIELD, { power = power, duration = duration, origin = caster }) then
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
    end

    return xi.effect.MAGIC_SHIELD
end

return spellObject
