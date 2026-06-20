-----------------------------------
-- Spell: Fantod
-- Enhances attack and magic attack. Effect is stackable (up to 10 times)
-- Spell cost: 12 MP
-- Monster Type: Lizards
-- Spell Type: Magical (Fire)
-- Blue Magic Points: 2
-- Stat Bonus: Store TP
-- Level: 85
-- Casting Time: 0.5 seconds
-- Recast Time: 10 seconds
-- Duration: Unknown (stackable)
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    -- DISABLED 2026-06-20 (owner request): block every cast of Fantod. Its
    -- stackable Attack+ / Mag.Atk.+ boost (up to 10x) was too strong. Returning a
    -- non-zero message from the casting check aborts the cast cleanly (no MP /
    -- recast spent), same pattern as pyric_bulwark.lua. The spell stays learnable
    -- + in spell_list; it just can't be cast. To re-enable, restore `return 0`.
    -- onSpellCast below is now unreachable, kept for an easy revert.
    return xi.msg.basic.MAGIC_CANNOT_BE_CAST
end

spellObject.onSpellCast = function(caster, target, spell)
    local duration = xi.spells.blue.calculateDurationWithDiffusion(caster, 180)

    caster:addStatusEffect(xi.effect.ATTACK_BOOST,    { power = 5,  duration = duration, origin = caster })
    caster:addStatusEffect(xi.effect.MAGIC_ATK_BOOST, { power = 5,  duration = duration, origin = caster })

    return xi.effect.ATTACK_BOOST
end

return spellObject
