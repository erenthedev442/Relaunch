-----------------------------------
-- Spell: Restoral
-- Restores the caster's HP
-- Spell cost: 127 MP
-- Monster Type: Aquans
-- Spell Type: Magical (Light)
-- Blue Magic Points: 5
-- Stat Bonus: HP+15 MP+15
-- Level: 99
-- Casting Time: 2 seconds
-- Recast Time: 10 seconds
-- Combos: Max HP Boost
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    -- Formula: base ~640 HP, soft cap ~1040 HP
    -- BLU skill/2 additional HP, MND * 1.5, VIT * 0.5
    local blueSkill = caster:getSkillLevel(xi.skill.BLUE_MAGIC)
    local healing   = 320 + math.floor(blueSkill / 2) + math.floor(caster:getStat(xi.mod.MND) * 1.5) + math.floor(caster:getStat(xi.mod.VIT) * 0.5)
    healing = math.min(healing, 1040)

    local diff = caster:getMaxHP() - caster:getHP()
    if healing > diff then
        healing = diff
    end

    caster:addHP(healing)
    return healing
end

return spellObject
