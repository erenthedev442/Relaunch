-----------------------------------
-- Spell: Tearing Gust
-- Deals wind damage to enemies within area of effect. Additional effect: Magic Defense Down
-- Spell cost: 202 MP
-- Monster Type: Beasts
-- Spell Type: Magical (Wind)
-- Blue Magic Points: 5
-- Stat Bonus: AGI+3
-- Level: 99
-- Casting Time: 3 seconds
-- Recast Time: 30 seconds
-- Requires Unbridled Learning
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params = {}
    params.ecosystem   = xi.ecosystem.BEAST
    params.attackType  = xi.attackType.MAGICAL
    params.damageType  = xi.damageType.WIND
    params.attribute   = xi.mod.INT
    params.multiplier  = 3.0
    params.tMultiplier = 2.0
    params.duppercap   = 100
    params.str_wsc     = 0.0
    params.dex_wsc     = 0.0
    params.vit_wsc     = 0.0
    params.agi_wsc     = 0.3
    params.int_wsc     = 0.3
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
        [1] = { xi.effect.MAGIC_DEF_DOWN, 30, 0, 60 },
    }

    xi.spells.blue.applyBlueAdditionalEffect(caster, target, params, effectTable)

    return damage
end

return spellObject
