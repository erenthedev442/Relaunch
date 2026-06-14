-----------------------------------
-- Spell: Foul Waters
-- Deals water damage to enemies within area of effect. Additional effect: Drown
-- Spell cost: 76 MP
-- Monster Type: Aquans
-- Spell Type: Magical (Water)
-- Blue Magic Points: 4
-- Stat Bonus: STR+1 MND+1
-- Level: 99
-- Casting Time: 3.5 seconds
-- Recast Time: 60 seconds
-- Magic Bursts on: Reverberation, Distortion, and Darkness
-- Combos: Clear Mind
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params = {}
    params.ecosystem   = xi.ecosystem.AQUAN
    params.attackType  = xi.attackType.MAGICAL
    params.damageType  = xi.damageType.WATER
    params.attribute   = xi.mod.INT
    params.multiplier  = 2.25
    params.tMultiplier = 2.0
    params.duppercap   = 100
    params.str_wsc     = 0.2
    params.dex_wsc     = 0.0
    params.vit_wsc     = 0.0
    params.agi_wsc     = 0.0
    params.int_wsc     = 0.0
    params.mnd_wsc     = 0.2
    params.chr_wsc     = 0.0

    -- Handle damage.
    local damage = xi.spells.blue.useMagicalSpell(caster, target, spell, params)

    if damage <= 0 then
        return damage
    end

    -- Handle status effects.
    local effectTable =
    {
        [1] = { xi.effect.DROWN, 31, 3, 180 },
    }

    xi.spells.blue.applyBlueAdditionalEffect(caster, target, params, effectTable)

    return damage
end

return spellObject
