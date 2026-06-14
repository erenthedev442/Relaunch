-----------------------------------
-- Spell: Crashing Thunder
-- Deals lightning damage to enemies within area of effect
-- Spell cost: 172 MP
-- Monster Type: Birds
-- Spell Type: Magical (Lightning)
-- Blue Magic Points: 5
-- Stat Bonus: AGI+4
-- Level: 99
-- Casting Time: 3 seconds
-- Recast Time: 30 seconds
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
    params.ecosystem   = xi.ecosystem.BIRD
    params.attackType  = xi.attackType.MAGICAL
    params.damageType  = xi.damageType.THUNDER
    params.attribute   = xi.mod.INT
    params.multiplier  = 6.5
    params.tMultiplier = 2.0
    params.duppercap   = 100
    params.str_wsc     = 0.0
    params.dex_wsc     = 0.0
    params.vit_wsc     = 0.0
    params.agi_wsc     = 0.3
    params.int_wsc     = 0.0
    params.mnd_wsc     = 0.0
    params.chr_wsc     = 0.0

    return xi.spells.blue.useMagicalSpell(caster, target, spell, params)
end

return spellObject
