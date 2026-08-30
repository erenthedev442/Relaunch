-----------------------------------
-- Spell: Blazing Bound
-- Deals fire damage to enemies within area of effect
-- Spell cost: 113 MP
-- Monster Type: Beasts
-- Spell Type: Magical (Fire)
-- Blue Magic Points: 4
-- Stat Bonus: STR+2
-- Level: 80
-- Casting Time: 6 seconds
-- Recast Time: 30 seconds
-- Magic Bursts on: Liquefaction, Fusion, and Light
-- Combos: Dual Wield
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params = {}
    params.ecosystem   = xi.ecosystem.BEAST
    params.attackType  = xi.attackType.MAGICAL
    params.damageType  = xi.damageType.FIRE
    params.attribute   = xi.mod.INT
    params.multiplier  = 6.0
    params.tMultiplier = 3.0
    params.duppercap   = 100
    params.str_wsc     = 0.8
    params.dex_wsc     = 0.0
    params.vit_wsc     = 0.0
    params.agi_wsc     = 0.0
    params.int_wsc     = 0.0
    params.mnd_wsc     = 0.0
    params.chr_wsc     = 0.0

    return xi.spells.blue.useMagicalSpell(caster, target, spell, params)
end

return spellObject
