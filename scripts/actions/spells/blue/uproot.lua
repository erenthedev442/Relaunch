-----------------------------------
-- Spell: Uproot
-- Deals light damage to enemies within area of effect. Removes all detrimental effects from caster
-- Spell cost: 88 MP
-- Monster Type: Plantoids
-- Spell Type: Magical (Light)
-- Blue Magic Points: 5
-- Stat Bonus: VIT+3
-- Level: 99
-- Casting Time: 3 seconds
-- Recast Time: 30 seconds
-- Requires Unbridled Learning
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params = {}
    params.ecosystem   = xi.ecosystem.PLANTOID
    params.attackType  = xi.attackType.MAGICAL
    params.damageType  = xi.damageType.LIGHT
    params.attribute   = xi.mod.INT
    params.multiplier  = 4.0
    params.tMultiplier = 2.0
    params.duppercap   = 100
    params.str_wsc     = 0.0
    params.dex_wsc     = 0.0
    params.vit_wsc     = 0.4
    params.agi_wsc     = 0.0
    params.int_wsc     = 0.0
    params.mnd_wsc     = 0.0
    params.chr_wsc     = 0.0

    -- Handle damage.
    local damage = xi.spells.blue.useMagicalSpell(caster, target, spell, params)

    -- Remove all detrimental effects from caster (Full Erase).
    caster:eraseAllStatusEffects()

    return damage
end

return spellObject
