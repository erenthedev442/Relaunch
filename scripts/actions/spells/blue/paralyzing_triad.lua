-----------------------------------
-- Spell: Paralyzing Triad
-- Delivers a threefold attack. Additional effect: Paralysis
-- Spell cost: 33 MP
-- Monster Type: Luminians
-- Spell Type: Physical (Slashing)
-- Blue Magic Points: 4
-- Stat Bonus: DEX+2
-- Level: 99
-- Casting Time: 1 second
-- Recast Time: 15 seconds
-- Skillchain Element(s): Gravitation
-- Combos: None
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params = {}
    params.ecosystem  = xi.ecosystem.LUMINIAN
    params.tpmod      = xi.spells.blue.tpMod.DAMAGE
    params.attackType = xi.attackType.PHYSICAL
    params.damageType = xi.damageType.SLASHING
    params.scattr     = xi.skillchainType.GRAVITATION
    params.numhits    = 3
    params.multiplier = 1.125
    params.tp150      = 1.125
    params.tp300      = 1.125
    params.azuretp    = 1.125
    params.duppercap  = 100
    params.str_wsc    = 0.0
    params.dex_wsc    = 0.3
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
        [1] = { xi.effect.PARALYSIS, 20, 0, 60 },
    }

    xi.spells.blue.applyBlueAdditionalEffect(caster, target, params, effectTable)

    return damage
end

return spellObject
