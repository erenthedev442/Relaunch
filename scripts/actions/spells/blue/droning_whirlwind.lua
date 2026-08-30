-----------------------------------
-- Spell: Droning Whirlwind
-- Deals wind damage to enemies within area of effect. Dispels one effect
-- Spell cost: 224 MP
-- Monster Type: Birds
-- Spell Type: Magical (Wind)
-- Blue Magic Points: 5
-- Stat Bonus: AGI+2
-- Level: 99
-- Casting Time: 1.5 seconds
-- Recast Time: 22 seconds
-- Combos: None (Unbridled Learning)
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
    params.damageType  = xi.damageType.WIND
    params.attribute   = xi.mod.INT
    params.multiplier  = 6.5
    params.tMultiplier = 3.0
    params.duppercap   = 100
    params.str_wsc     = 0.0
    params.dex_wsc     = 0.0
    params.vit_wsc     = 0.0
    params.agi_wsc     = 0.8
    params.int_wsc     = 0.0
    params.mnd_wsc     = 0.0
    params.chr_wsc     = 0.0

    -- Handle damage.
    local damage = xi.spells.blue.useMagicalSpell(caster, target, spell, params)

    if damage <= 0 then
        return damage
    end

    -- Dispel one beneficial effect.
    target:dispelStatusEffect()

    return damage
end

return spellObject
