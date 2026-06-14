-----------------------------------
-- Spell: Benthic Typhoon
-- Delivers a single attack. Additional effect: Defense Down and Magic Defense Down. Attack varies with TP
-- Spell cost: 56 MP
-- Monster Type: Aquans
-- Spell Type: Physical (Piercing)
-- Blue Magic Points: 4
-- Stat Bonus: AGI+2
-- Level: 83
-- Casting Time: 0.5 seconds
-- Recast Time: 55 seconds
-- Skillchain Element(s): Gravitation/Transfixion
-- Combos: None
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params = {}
    params.ecosystem  = xi.ecosystem.AQUAN
    params.tpmod      = xi.spells.blue.tpMod.DAMAGE
    params.attackType = xi.attackType.PHYSICAL
    params.damageType = xi.damageType.PIERCING
    params.scattr     = xi.skillchainType.GRAVITATION
    params.scattr2    = xi.skillchainType.TRANSFIXION
    params.numhits    = 1
    params.multiplier = 4.0
    params.tp150      = 4.5
    params.tp300      = 5.0
    params.azuretp    = 5.25
    params.duppercap  = 100
    params.str_wsc    = 0.0
    params.dex_wsc    = 0.0
    params.vit_wsc    = 0.0
    params.agi_wsc    = 0.6
    params.int_wsc    = 0.0
    params.mnd_wsc    = 0.0
    params.chr_wsc    = 0.0

    -- Handle damage.
    local damage = xi.spells.blue.usePhysicalSpell(caster, target, spell, params)

    if damage <= 0 then
        return damage
    end

    -- Handle status effects.
    local effectTable =
    {
        [1] = { xi.effect.DEFENSE_DOWN,   10, 0, 60 },
        [2] = { xi.effect.MAGIC_DEF_DOWN, 10, 0, 60 },
    }

    xi.spells.blue.applyBlueAdditionalEffect(caster, target, params, effectTable)

    return damage
end

return spellObject
