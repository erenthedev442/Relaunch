-----------------------------------
-- Spell: Thunderbolt
-- Deals lightning damage to enemies within area of effect. Additional effect: Stun
-- Spell cost: 138 MP
-- Monster Type: Beasts
-- Spell Type: Magical (Lightning)
-- Blue Magic Points: 4
-- Stat Bonus: INT+2 MND+1
-- Level: 95
-- Casting Time: 8.5 seconds
-- Recast Time: 30 seconds
-- Magic Bursts on: Impaction, Fragmentation, and Light
-- Combos: None
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
    params.damageType  = xi.damageType.THUNDER
    params.attribute   = xi.mod.INT
    params.multiplier  = 6.5
    params.tMultiplier = 3.0
    params.duppercap   = 100
    params.str_wsc     = 0.0
    params.dex_wsc     = 0.0
    params.vit_wsc     = 0.0
    params.agi_wsc     = 0.0
    params.int_wsc     = 0.48
    params.mnd_wsc     = 0.32
    params.chr_wsc     = 0.0

    -- Handle damage.
    local damage = xi.spells.blue.useMagicalSpell(caster, target, spell, params)

    if damage <= 0 then
        return damage
    end

    -- Handle status effects.
    local effectTable =
    {
        [1] = { xi.effect.STUN, 1, 0, 10 },
    }

    xi.spells.blue.applyBlueAdditionalEffect(caster, target, params, effectTable)

    return damage
end

return spellObject
