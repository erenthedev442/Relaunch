-----------------------------------
-- Spell: Dark Orb
-- Deals dark damage to an enemy
-- Spell cost: 124 MP
-- Monster Type: Arcana
-- Spell Type: Magical (Dark)
-- Blue Magic Points: 4
-- Stat Bonus: INT+2
-- Level: 93
-- Casting Time: 9 seconds
-- Recast Time: 72 seconds
-- Magic Bursts on: Compression, Gravitation, and Darkness
-- Combos: Counter
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params = {}
    params.ecosystem   = xi.ecosystem.ARCANA
    params.attackType  = xi.attackType.MAGICAL
    params.damageType  = xi.damageType.DARK
    params.attribute   = xi.mod.INT
    params.multiplier  = 4.5
    params.tMultiplier = 2.0
    params.duppercap   = 100
    params.str_wsc     = 0.0
    params.dex_wsc     = 0.0
    params.vit_wsc     = 0.0
    params.agi_wsc     = 0.0
    params.int_wsc     = 0.4
    params.mnd_wsc     = 0.0
    params.chr_wsc     = 0.0

    return xi.spells.blue.useMagicalSpell(caster, target, spell, params)
end

return spellObject
