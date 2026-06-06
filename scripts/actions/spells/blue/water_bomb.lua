-----------------------------------
-- Spell: Water Bomb
-- Deals water damage to enemies within range. Additional effect: Silence.
-- Spell cost: 67 MP                  (from sql/spell_list.sql row 687)
-- Monster Type: Amorph (Poroggo)
-- Spell Type: Magical (Water)
-- Blue Magic Points: 2               (from sql/blue_spell_list.sql)
-- Level: 47-ish (Abyssea content)
-- Casting Time: 2.5 seconds
-- Recast Time: 32.25 seconds
-- Magic Bursts on: Reverberation, Distortion, Darkness
--
-- NOTE: Upstream LSB shipped sql/spell_list + sql/blue_spell_list rows
-- for Water Bomb but never added the player-side spell handler — the
-- engine errors with "no Lua file" when the spell is cast. The mob
-- version exists at scripts/actions/mobskills/water_bomb.lua and is
-- the canonical reference for the Silence additional effect.
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params = {}
    params.ecosystem   = xi.ecosystem.AMORPH      -- Poroggo family
    params.attackType  = xi.attackType.MAGICAL
    params.damageType  = xi.damageType.WATER
    params.attribute   = xi.mod.INT
    -- Damage shape mirrors Maelstrom (water AOE blue magic): high base
    -- multiplier, INT-leaning WSC, modest MND assist.
    params.multiplier  = 2.5
    params.tMultiplier = 1.5
    params.duppercap   = 69
    params.str_wsc     = 0.0
    params.dex_wsc     = 0.0
    params.vit_wsc     = 0.0
    params.agi_wsc     = 0.0
    params.int_wsc     = 0.3
    params.mnd_wsc     = 0.1
    params.chr_wsc     = 0.0

    local damage = xi.spells.blue.useMagicalSpell(caster, target, spell, params)

    if damage <= 0 then
        return damage
    end

    -- Additional effect: Silence (matches the Poroggo mob version).
    -- The proc duration (60s) and odds are governed by
    -- xi.spells.blue.applyBlueAdditionalEffect's stat-roll formula.
    local effectTable =
    {
        [1] = { xi.effect.SILENCE, 1, 0, 60 },
    }

    xi.spells.blue.applyBlueAdditionalEffect(caster, target, params, effectTable)

    return damage
end

return spellObject
