-----------------------------------
-- Spell: Diffusion Ray
-- Deals light damage to enemies within a fan-shaped area originating from the caster
-- Spell cost: 238 MP
-- Monster Type: Arcana
-- Spell Type: Magical (Light)
-- Blue Magic Points: 5
-- Stat Bonus: STR+5 VIT+7
-- Level: 99
-- Casting Time: 4.5 seconds
-- Recast Time: 45 seconds
-- Combos: Store TP
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params = {}
    params.ecosystem   = xi.ecosystem.ARCHAICMACHINE
    params.attackType  = xi.attackType.MAGICAL
    params.damageType  = xi.damageType.LIGHT
    params.attribute   = xi.mod.INT
    params.multiplier  = 5.0
    params.tMultiplier = 2.0
    params.duppercap   = 100
    params.str_wsc     = 0.0
    params.dex_wsc     = 0.0
    params.vit_wsc     = 0.0
    params.agi_wsc     = 0.0
    params.int_wsc     = 0.0
    params.mnd_wsc     = 0.4
    params.chr_wsc     = 0.0

    return xi.spells.blue.useMagicalSpell(caster, target, spell, params)
end

return spellObject
