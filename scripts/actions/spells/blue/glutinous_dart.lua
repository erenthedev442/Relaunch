-----------------------------------
-- Spell: Glutinous Dart
-- Delivers a single attack. Damage varies with TP
-- Spell cost: 16 MP
-- Monster Type: Amorphs
-- Spell Type: Physical (Piercing)
-- Blue Magic Points: 2
-- Stat Bonus: HP+5
-- Level: 99
-- Casting Time: 1 second
-- Recast Time: 6 seconds
-- Skillchain Element(s): Fragmentation
-- Combos: Max HP Boost
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params = {}
    params.ecosystem  = xi.ecosystem.AMORPH
    params.tpmod      = xi.spells.blue.tpMod.DAMAGE
    params.attackType = xi.attackType.PHYSICAL
    params.damageType = xi.damageType.PIERCING
    params.scattr     = xi.skillchainType.FRAGMENTATION
    params.numhits    = 1
    params.multiplier = 4.5
    params.tp150      = 6.0
    params.tp300      = 7.5
    params.azuretp    = 9.0
    params.duppercap  = 100
    params.str_wsc    = 0.4
    params.dex_wsc    = 0.0
    params.vit_wsc    = 0.4
    params.agi_wsc    = 0.0
    params.int_wsc    = 0.0
    params.mnd_wsc    = 0.0
    params.chr_wsc    = 0.0

    return xi.spells.blue.usePhysicalSpell(caster, target, spell, params)
end

return spellObject
