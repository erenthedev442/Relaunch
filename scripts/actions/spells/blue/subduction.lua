-----------------------------------
-- Spell: Subduction
-- Deals wind damage to enemies within area of effect. Additional effect: Gravity
-- Spell cost: 27 MP
-- Monster Type: Amorphs
-- Spell Type: Magical (Wind)
-- Blue Magic Points: 2
-- Stat Bonus: STR+1 VIT+1
-- Level: 99
-- Casting Time: 0.5 seconds
-- Recast Time: 5 seconds
-- Combos: Magic Attack Bonus
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params = {}
    params.ecosystem   = xi.ecosystem.AMORPH
    params.attackType  = xi.attackType.MAGICAL
    params.damageType  = xi.damageType.WIND
    params.attribute   = xi.mod.INT
    params.multiplier  = 2.0
    params.tMultiplier = 2.0
    params.duppercap   = 100
    params.str_wsc     = 0.1
    params.dex_wsc     = 0.0
    params.vit_wsc     = 0.1
    params.agi_wsc     = 0.0
    params.int_wsc     = 0.0
    params.mnd_wsc     = 0.0
    params.chr_wsc     = 0.0

    -- Handle damage.
    local damage = xi.spells.blue.useMagicalSpell(caster, target, spell, params)

    if damage <= 0 then
        return damage
    end

    -- Handle status effects.
    local effectTable =
    {
        [1] = { xi.effect.WEIGHT, 75, 0, 90 },
    }

    xi.spells.blue.applyBlueAdditionalEffect(caster, target, params, effectTable)

    return damage
end

return spellObject
