-----------------------------------
-- Spell: Barbed Crescent
-- Delivers a single attack. Additional effect: Accuracy Down
-- Spell cost: 52 MP
-- Monster Type: Vermin
-- Spell Type: Physical (Slashing)
-- Blue Magic Points: 4
-- Stat Bonus: DEX+2
-- Level: 99
-- Casting Time: 0.5 seconds
-- Recast Time: 22 seconds
-- Skillchain Element(s): Distortion/Liquefaction
-- Combos: None
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params = {}
    params.ecosystem  = xi.ecosystem.VERMIN
    params.tpmod      = xi.spells.blue.tpMod.DAMAGE
    params.attackType = xi.attackType.PHYSICAL
    params.damageType = xi.damageType.SLASHING
    params.scattr     = xi.skillchainType.DISTORTION
    params.scattr2    = xi.skillchainType.LIQUEFACTION
    params.numhits    = 1
    params.multiplier = 2.0
    params.tp150      = 2.0
    params.tp300      = 2.0
    params.azuretp    = 2.0
    params.duppercap  = 100
    params.str_wsc    = 0.0
    params.dex_wsc    = 0.5
    params.vit_wsc    = 0.0
    params.agi_wsc    = 0.0
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
        [1] = { xi.effect.ACCURACY_DOWN, 30, 0, 120 },
    }

    xi.spells.blue.applyBlueAdditionalEffect(caster, target, params, effectTable)

    return damage
end

return spellObject
