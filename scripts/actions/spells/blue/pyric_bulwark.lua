-----------------------------------
-- Spell: Pyric Bulwark
-- Creates a barrier that absorbs physical damage (one hit)
-- Spell cost: 50 MP
-- Monster Type: Dragons
-- Spell Type: Magical (Ice)
-- Blue Magic Points: 4
-- Stat Bonus: VIT+3
-- Level: 98
-- Casting Time: 1.5 seconds
-- Recast Time: 30 seconds
-- Duration: 5 minutes
-- Requires Unbridled Learning
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    -- DISABLED 2026-06-20 (owner request): block every cast of Pyric Bulwark.
    -- Its absorb-physical-hits barrier trivialized melee content. Returning a
    -- non-zero message from the casting check aborts the cast cleanly (no MP /
    -- recast spent), same pattern as arise.lua's living-target block. The spell
    -- stays learnable + in spell_list; it just can't be cast. To re-enable,
    -- restore `return 0`. onSpellCast below is now unreachable, kept for an easy
    -- revert.
    return xi.msg.basic.MAGIC_CANNOT_BE_CAST
end

spellObject.onSpellCast = function(caster, target, spell)
    local duration = xi.spells.blue.calculateDurationWithDiffusion(caster, 300)

    if not caster:addStatusEffect(xi.effect.PHYSICAL_SHIELD, { power = 1, duration = duration, origin = caster }) then
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
    end

    return xi.effect.PHYSICAL_SHIELD
end

return spellObject
