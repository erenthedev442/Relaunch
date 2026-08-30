-----------------------------------
-- Spell: Water Bomb
-- Deals water damage to an enemy. Additional effect: Silence
-- Spell cost: 67 MP
-- Monster Type: Aquans
-- Spell Type: Magical (Water)
-- Blue Magic Points: 4
-- Stat Bonus: INT+1 MND+1
-- Level: 92
-- Casting Time: 3 seconds
-- Recast Time: 32 seconds
-- Magic Bursts on: Reverberation, Distortion, and Darkness
-- Combos: Conserve MP
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
    params.multiplier  = 5.0
    params.tMultiplier = 3.0
    params.duppercap   = 100
    params.str_wsc     = 0.0
    params.dex_wsc     = 0.0
    params.vit_wsc     = 0.0
    params.agi_wsc     = 0.0
    params.int_wsc     = 0.53
    params.mnd_wsc     = 0.27
    params.chr_wsc     = 0.0

    -- Handle damage.
    local damage = xi.spells.blue.useMagicalSpell(caster, target, spell, params)

    if damage <= 0 then
        return damage
    end

    -- Handle status effects.
    local effectTable =
    {
        [1] = { xi.effect.SILENCE, 1, 0, 60 },
    }

    xi.spells.blue.applyBlueAdditionalEffect(caster, target, params, effectTable)

    return damage
end

return spellObject
