-----------------------------------
-- Spell: Sinker Drill
-- Delivers a fivefold attack
-- Spell cost: 91 MP
-- Monster Type: Vermin
-- Spell Type: Physical (Piercing)
-- Blue Magic Points: 5
-- Stat Bonus: STR+4 DEX+4 VIT+4
-- Level: 99
-- Casting Time: 1 second
-- Recast Time: 20 seconds
-- Skillchain Element(s): Gravitation/Reverberation
-- Combos: Critical Attack Bonus
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
    params.damageType = xi.damageType.PIERCING
    params.scattr     = xi.skillchainType.GRAVITATION
    params.scattr2    = xi.skillchainType.REVERBERATION
    params.numhits    = 5
    params.multiplier = 1.0
    params.tp150      = 1.0
    params.tp300      = 1.0
    params.azuretp    = 1.0
    params.duppercap  = 100
    params.str_wsc    = 0.5
    params.dex_wsc    = 0.0
    params.vit_wsc    = 0.5
    params.agi_wsc    = 0.0
    params.int_wsc    = 0.0
    params.mnd_wsc    = 0.0
    params.chr_wsc    = 0.0

    return xi.spells.blue.usePhysicalSpell(caster, target, spell, params)
end

return spellObject
