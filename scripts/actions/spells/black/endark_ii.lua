-----------------------------------
-- Spell: Endark II
-- Adds dark damage to melee attacks. Stronger variant of Endark.
-- Spell row: sql/spell_list.sql id 856 (SCH, 36 MP, 3s cast, 30s recast).
--
-- NOTE: Upstream LSB shipped the spell_list row but never added the
-- player-side handler. Builds on scripts/actions/spells/black/endark.lua
-- with a bumped potency formula. There is no separate ENDARK_II status
-- effect in scripts/enum/effect.lua — the upgrade reuses xi.effect.ENDARK
-- with a higher power floor.
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local effect = xi.effect.ENDARK
    local magicskill = target:getSkillLevel(xi.skill.DARK_MAGIC)
    -- Endark base formula: (skill / 8) + 12.5 — see endark.lua.
    -- Endark II bumps the floor and slope to keep the upgrade meaningful
    -- across the skill range (mirrors the +Endark II / +Endark gap that
    -- the SCH grimoire stat block implies on retail).
    local potency = (magicskill / 6) + 20

    if target:addStatusEffect(effect, { power = potency, duration = 180, origin = caster }) then
        spell:setMsg(xi.msg.basic.MAGIC_GAIN_EFFECT)
    else
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
    end

    return effect
end

return spellObject
