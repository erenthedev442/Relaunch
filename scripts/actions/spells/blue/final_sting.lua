-----------------------------------
-- Spell: Final Sting
-- Delivers a single attack. Damage proportional to caster's HP. Reduces caster to 1 HP
-- Spell cost: 88 MP
-- Monster Type: Vermin
-- Spell Type: Physical (Piercing)
-- Blue Magic Points: 4
-- Stat Bonus: HP+10
-- Level: 81
-- Casting Time: 5 seconds
-- Recast Time: 11 seconds
-- Combos: Zanshin
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local currentHP = caster:getHP()
    local damage    = currentHP - 1

    -- Reduce caster to 1 HP.
    caster:setHP(1)

    if damage <= 0 then
        return 0
    end

    -- Fixed HP-sacrifice damage uses the shared safe delivery path without
    -- receiving main-hand amplification.
    local params =
    {
        attackType       = xi.attackType.PHYSICAL,
        damageType       = xi.damageType.PIERCING,
        blueDamageExempt = true,
        blueFixedDamage  = true,
    }
    damage = xi.spells.blue.applySpellDamage(caster, target, spell, damage, params)

    return damage
end

return spellObject
