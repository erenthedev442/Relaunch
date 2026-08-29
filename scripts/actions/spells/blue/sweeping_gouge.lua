-----------------------------------
-- Spell: Sweeping Gouge
-- Delivers a twofold attack. Additional effect: Defense Down
-- Spell cost: 29 MP
-- Monster Type: Lizards
-- Spell Type: Physical (Blunt)
-- Blue Magic Points: 4
-- Stat Bonus: VIT+2
-- Level: 99
-- Casting Time: 0.5 seconds
-- Recast Time: 120 seconds
-- Combos: Lizard Killer
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params = {}
    params.ecosystem  = xi.ecosystem.LIZARD
    params.tpmod      = xi.spells.blue.tpMod.DURATION
    params.attackType = xi.attackType.PHYSICAL
    params.damageType = xi.damageType.HTH
    params.numhits    = 2
    params.multiplier = 3.25
    params.tp150      = 3.25
    params.tp300      = 3.25
    params.azuretp    = 3.25
    params.duppercap  = 100
    params.str_wsc    = 0.0
    params.dex_wsc    = 0.0
    params.vit_wsc    = 0.8
    params.agi_wsc    = 0.0
    params.int_wsc    = 0.0
    params.mnd_wsc    = 0.0
    params.chr_wsc    = 0.0

    -- Handle damage.
    local damage = xi.spells.blue.usePhysicalSpell(caster, target, spell, params)

    if damage <= 0 then
        return damage
    end

    -- Handle status effects. Duration increases with TP (90s base, 112s at 1500 TP, 135s at 3000 TP).
    local effectTable =
    {
        [1] = { xi.effect.DEFENSE_DOWN, 16, 0, 90 },
    }

    xi.spells.blue.applyBlueAdditionalEffect(caster, target, params, effectTable)

    return damage
end

return spellObject
