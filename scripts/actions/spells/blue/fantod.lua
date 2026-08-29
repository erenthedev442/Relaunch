-----------------------------------
-- Spell: Fantod
-- Enhances attack and magic attack. Effect is stackable (up to 5 times)
-- Spell cost: 12 MP
-- Monster Type: Birds
-- Spell Type: Magical (Fire)
-- Blue Magic Points: 1
-- Stat Bonus: HP-10, DEX+2, AGI+2; creates Store TP
-- Level: 85
-- Casting Time: 0.5 seconds
-- Recast Time: 10 seconds
-- Duration: Unknown (stackable)
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local duration = xi.spells.blue.calculateDurationWithDiffusion(caster, 180)
    local function stackEffect(effect)
        local currentEffect = caster:getStatusEffect(effect)
        local power = currentEffect and math.min(currentEffect:getPower() + 5, 25) or 5

        if currentEffect then
            caster:delStatusEffectSilent(effect)
        end

        caster:addStatusEffect(effect, { power = power, duration = duration, origin = caster })
    end

    stackEffect(xi.effect.ATTACK_BOOST)
    stackEffect(xi.effect.MAGIC_ATK_BOOST)

    return xi.effect.ATTACK_BOOST
end

return spellObject
