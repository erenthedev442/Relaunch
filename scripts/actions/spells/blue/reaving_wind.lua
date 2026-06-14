-----------------------------------
-- Spell: Reaving Wind
-- Reduces the TP of enemies within area of effect
-- Spell cost: 84 MP
-- Monster Type: Dragons
-- Spell Type: Magical (Wind)
-- Blue Magic Points: 4
-- Stat Bonus: AGI+2
-- Level: 90
-- Casting Time: 4 seconds
-- Recast Time: 90 seconds
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params = {}
    params.ecosystem   = xi.ecosystem.DRAGON
    params.attackType  = xi.attackType.MAGICAL
    params.damageType  = xi.damageType.WIND
    params.attribute   = xi.mod.INT
    params.multiplier  = 0.0
    params.tMultiplier = 0.0
    params.duppercap   = 100
    params.str_wsc     = 0.0
    params.dex_wsc     = 0.0
    params.vit_wsc     = 0.0
    params.agi_wsc     = 0.0
    params.int_wsc     = 0.0
    params.mnd_wsc     = 0.0
    params.chr_wsc     = 0.0

    xi.spells.blue.useMagicalSpell(caster, target, spell, params)

    -- Drain 1000 TP from target.
    local currentTP = target:getTP()
    target:setTP(math.max(0, currentTP - 1000))

    return 0
end

return spellObject
