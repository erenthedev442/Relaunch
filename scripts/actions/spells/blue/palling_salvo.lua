-----------------------------------
-- Spell: Palling Salvo
-- Deals dark damage to enemies within area of effect. Additional effect: Bio
-- Spell cost: 175 MP
-- Monster Type: Demons
-- Spell Type: Magical (Dark)
-- Blue Magic Points: 6
-- Stat Bonus: AGI+4
-- Level: 99
-- Casting Time: 2 seconds
-- Recast Time: 45 seconds
-- Combos: Tenacity
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
    params.damageType  = xi.damageType.DARK
    params.attribute   = xi.mod.INT
    params.multiplier  = 5.0
    params.tMultiplier = 2.0
    params.duppercap   = 100
    params.str_wsc     = 0.0
    params.dex_wsc     = 0.0
    params.vit_wsc     = 0.0
    params.agi_wsc     = 0.6
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
        [1] = { xi.effect.BIO, 3, 3, 60 },
    }

    xi.spells.blue.applyBlueAdditionalEffect(caster, target, params, effectTable)

    return damage
end

return spellObject
