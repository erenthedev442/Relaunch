-----------------------------------
-- Spell: Blinding Fulgor
-- Deals light damage to enemies within area of effect. Additional effect: Flash
-- Spell cost: 116 MP
-- Monster Type: Elemental
-- Spell Type: Magical (Light)
-- Blue Magic Points: 8
-- Stat Bonus: HP+40 STR+4 DEX+4 AGI+4
-- Level: 99
-- Casting Time: 5 seconds
-- Recast Time: 60 seconds
-- Combos: Magic Evasion Bonus
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params = {}
    params.ecosystem   = xi.ecosystem.ELEMENTAL
    params.attackType  = xi.attackType.MAGICAL
    params.damageType  = xi.damageType.LIGHT
    params.attribute   = xi.mod.INT
    params.multiplier  = 4.0
    params.tMultiplier = 2.0
    params.duppercap   = 100
    params.str_wsc     = 0.3
    params.dex_wsc     = 0.3
    params.vit_wsc     = 0.0
    params.agi_wsc     = 0.3
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
        [1] = { xi.effect.FLASH, 1, 0, 15 },
    }

    xi.spells.blue.applyBlueAdditionalEffect(caster, target, params, effectTable)

    return damage
end

return spellObject
