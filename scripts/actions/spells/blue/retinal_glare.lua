-----------------------------------
-- Spell: Retinal Glare
-- Deals light damage to enemies within a fan-shaped area originating from the caster. Additional effect: Flash
-- Spell cost: 26 MP
-- Monster Type: Arcana
-- Spell Type: Magical (Light)
-- Blue Magic Points: 3
-- Stat Bonus: MND+1
-- Level: 99
-- Casting Time: 1 second
-- Recast Time: 45 seconds
-- Combos: Conserve MP
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
    params.damageType  = xi.damageType.LIGHT
    params.attribute   = xi.mod.INT
    params.multiplier  = 5.0
    params.tMultiplier = 3.0
    params.duppercap   = 100
    params.str_wsc     = 0.0
    params.dex_wsc     = 0.0
    params.vit_wsc     = 0.0
    params.agi_wsc     = 0.0
    params.int_wsc     = 0.0
    params.mnd_wsc     = 0.8
    params.chr_wsc     = 0.0

    -- Handle damage.
    local damage = xi.spells.blue.useMagicalSpell(caster, target, spell, params)

    -- Handle status effects (Flash).
    local effectTable =
    {
        [1] = { xi.effect.FLASH, 1, 0, 15 },
    }

    xi.spells.blue.applyBlueAdditionalEffect(caster, target, params, effectTable)

    return damage
end

return spellObject
