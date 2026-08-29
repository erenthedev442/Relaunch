-----------------------------------
-- Spell: Saurian Slide
-- Delivers a single attack. Additional effect: Attack Down
-- Spell cost: 109 MP
-- Monster Type: Lizards
-- Spell Type: Physical (Slashing)
-- Blue Magic Points: 4
-- Stat Bonus: HP+50 VIT+6 INT-3
-- Level: 99
-- Casting Time: 0.5 seconds
-- Recast Time: 35 seconds
-- Skillchain Element(s): Fragmentation/Distortion
-- Combos: Inquartata
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params = {}
    params.ecosystem  = xi.ecosystem.LIZARD
    params.tpmod      = xi.spells.blue.tpMod.DAMAGE
    params.attackType = xi.attackType.PHYSICAL
    params.damageType = xi.damageType.SLASHING
    params.scattr     = xi.skillchainType.FRAGMENTATION
    params.scattr2    = xi.skillchainType.DISTORTION
    params.numhits    = 1
    params.multiplier = 4.5
    params.tp150      = 4.5
    params.tp300      = 4.5
    params.azuretp    = 4.5
    params.duppercap  = 100
    params.str_wsc    = 0.8
    params.dex_wsc    = 0.0
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
        [1] = { xi.effect.ATTACK_DOWN, 25, 0, 60 },
    }

    xi.spells.blue.applyBlueAdditionalEffect(caster, target, params, effectTable)

    return damage
end

return spellObject
