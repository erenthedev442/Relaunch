-----------------------------------
-- Spell: Tourbillion
-- Delivers a fivefold attack. Additional effect: Defense Down
-- Spell cost: 108 MP
-- Monster Type: Arcana
-- Spell Type: Physical (Blunt)
-- Blue Magic Points: 5
-- Stat Bonus: STR+3 MND+2
-- Level: 97
-- Casting Time: 1 second
-- Recast Time: 30 seconds
-- Skillchain Element(s): Light/Fragmentation
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
    params.ecosystem  = xi.ecosystem.ARCANA
    params.tpmod      = xi.spells.blue.tpMod.DAMAGE
    params.attackType = xi.attackType.PHYSICAL
    params.damageType = xi.damageType.HTH
    params.scattr     = xi.skillchainType.LIGHT
    params.scattr2    = xi.skillchainType.FRAGMENTATION
    params.numhits    = 5
    params.multiplier = 4.0
    params.tp150      = 4.0
    params.tp300      = 4.0
    params.azuretp    = 4.0
    params.duppercap  = 100
    params.str_wsc    = 0.25
    params.dex_wsc    = 0.0
    params.vit_wsc    = 0.0
    params.agi_wsc    = 0.0
    params.int_wsc    = 0.0
    params.mnd_wsc    = 0.25
    params.chr_wsc    = 0.0

    -- Handle damage.
    local damage = xi.spells.blue.usePhysicalSpell(caster, target, spell, params)

    if damage <= 0 then
        return damage
    end

    -- Handle status effects.
    local effectTable =
    {
        [1] = { xi.effect.DEFENSE_DOWN, 33, 0, 60 },
    }

    xi.spells.blue.applyBlueAdditionalEffect(caster, target, params, effectTable)

    return damage
end

return spellObject
