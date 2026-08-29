-----------------------------------
-- Spell: Bloodrake
-- Delivers a threefold attack. Drains HP. Damage varies with TP
-- Spell cost: 99 MP
-- Monster Type: Beasts
-- Spell Type: Physical (Slashing)
-- Blue Magic Points: 5
-- Stat Bonus: STR+3 MND+2
-- Level: 99
-- Casting Time: 0.5 seconds
-- Recast Time: 30 seconds
-- Skillchain Element(s): Darkness/Distortion
-- Combos: None
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params = {}
    params.ecosystem  = xi.ecosystem.BEAST
    params.tpmod      = xi.spells.blue.tpMod.DAMAGE
    params.attackType = xi.attackType.PHYSICAL
    params.damageType = xi.damageType.SLASHING
    params.scattr     = xi.skillchainType.DARKNESS
    params.scattr2    = xi.skillchainType.DISTORTION
    params.numhits    = 3
    params.multiplier = 2.5
    params.tp150      = 2.5
    params.tp300      = 2.5
    params.azuretp    = 2.5
    params.duppercap  = 100
    params.str_wsc    = 0.4
    params.dex_wsc    = 0.0
    params.vit_wsc    = 0.0
    params.agi_wsc    = 0.0
    params.int_wsc    = 0.0
    params.mnd_wsc    = 0.4
    params.chr_wsc    = 0.0

    -- Handle damage and drain HP.
    local damage = xi.spells.blue.usePhysicalSpell(caster, target, spell, params)

    if damage > 0 then
        caster:addHP(math.floor(damage / 2))
    end

    return damage
end

return spellObject
