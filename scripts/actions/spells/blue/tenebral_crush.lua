-----------------------------------
-- Spell: Tenebral Crush
-- Deals dark damage to enemies within area of effect. Additional effect: Defense Down
-- Spell cost: 116 MP
-- Monster Type: Elemental
-- Spell Type: Magical (Dark)
-- Blue Magic Points: 8
-- Stat Bonus: MP+30 VIT+4 INT+4 MND+4
-- Level: 99
-- Casting Time: 5 seconds
-- Recast Time: 60 seconds
-- Combos: Magic Accuracy Bonus
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
    params.damageType  = xi.damageType.DARK
    params.attribute   = xi.mod.INT
    params.multiplier  = 6.5
    params.tMultiplier = 3.0
    params.duppercap   = 100
    -- Same INT payload as Spectral Floe. The stock VIT/INT/MND split made this
    -- 8-point dark nuke much weaker than the rest of the suite on an INT BLU.
    params.str_wsc     = 0.0
    params.dex_wsc     = 0.0
    params.vit_wsc     = 0.0
    params.agi_wsc     = 0.0
    params.int_wsc     = 0.8
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
        [1] = { xi.effect.DEFENSE_DOWN, 20, 0, 180 },
    }

    xi.spells.blue.applyBlueAdditionalEffect(caster, target, params, effectTable)

    return damage
end

return spellObject
