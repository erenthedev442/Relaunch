-----------------------------------
-- Spell: Hysteric Barrage
-- Delivers a fivefold attack. Damage varies with TP
-- Spell cost: 61 MP
-- Monster Type: Beastmen
-- Spell Type: Physical (Hand-to-Hand)
-- Blue Magic Points: 5
-- Stat Bonus: DEX+2, AGI+1
-- Level: 69
-- Casting Time: 0.5 seconds
-- Recast Time: 28.5 seconds
-- Skillchain Element: Detonation
-- Combos: Evasion Bonus
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params = {}
    params.ecosystem = xi.ecosystem.BEASTMEN
    params.tpmod = xi.spells.blue.tpMod.DAMAGE
    params.attackType = xi.attackType.PHYSICAL
    params.damageType = xi.damageType.HTH
    params.scattr = xi.skillchainType.DETONATION
    params.numhits = 5
    params.multiplier = 2.0
    params.tp150 = 2.0
    params.tp300 = 2.0
    params.azuretp = 2.0
    params.duppercap = 100
    params.str_wsc = 0.0
    params.dex_wsc = 0.8
    params.vit_wsc = 0.0
    params.agi_wsc = 0.0
    params.int_wsc = 0.0
    params.mnd_wsc = 0.0
    params.chr_wsc = 0.0

    return xi.spells.blue.usePhysicalSpell(caster, target, spell, params)
end

return spellObject
