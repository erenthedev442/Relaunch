-----------------------------------
-- Spell: Gates of Hades
-- Deals fire damage to enemies within area of effect. Additional effect: Burn
-- Spell cost: 156 MP
-- Monster Type: Demons
-- Spell Type: Magical (Fire)
-- Blue Magic Points: 5
-- Stat Bonus: STR+3 DEX+2
-- Level: 97
-- Casting Time: 3.5 seconds
-- Recast Time: 30 seconds
-- Combos: None
-- Requires Unbridled Learning
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params = {}
    params.ecosystem   = xi.ecosystem.DEMON
    params.attackType  = xi.attackType.MAGICAL
    params.damageType  = xi.damageType.FIRE
    params.attribute   = xi.mod.INT
    params.multiplier  = 6.5
    params.tMultiplier = 3.0
    params.duppercap   = 100
    params.str_wsc     = 0.4
    params.dex_wsc     = 0.4
    params.vit_wsc     = 0.0
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
        [1] = { xi.effect.BURN, 30, 3, 90 },
    }

    xi.spells.blue.applyBlueAdditionalEffect(caster, target, params, effectTable)

    return damage
end

return spellObject
