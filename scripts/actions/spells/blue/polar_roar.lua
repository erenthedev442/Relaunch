-----------------------------------
-- Spell: Polar Roar
-- Deals ice damage to enemies within area of effect. Additional effect: Bind
-- Spell cost: 126 MP
-- Monster Type: Beasts
-- Spell Type: Magical (Ice)
-- Blue Magic Points: 4
-- Stat Bonus: STR+2 INT+2
-- Level: 99
-- Casting Time: 3 seconds
-- Recast Time: 30 seconds
-- Magic Bursts on: Induration, Distortion, and Darkness
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
    params.ecosystem   = xi.ecosystem.BEAST
    params.attackType  = xi.attackType.MAGICAL
    params.damageType  = xi.damageType.ICE
    params.attribute   = xi.mod.INT
    params.multiplier  = 6.5
    params.tMultiplier = 3.0
    params.duppercap   = 100
    params.str_wsc     = 0.4
    params.dex_wsc     = 0.0
    params.vit_wsc     = 0.0
    params.agi_wsc     = 0.0
    params.int_wsc     = 0.4
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
        [1] = { xi.effect.BIND, 1, 0, 60 },
    }

    xi.spells.blue.applyBlueAdditionalEffect(caster, target, params, effectTable)

    return damage
end

return spellObject
