-----------------------------------
-- Spell: Earth Carol II
-- Increases earth resistance for party members within the area of effect.
-- Spell row: sql/spell_list.sql id 449 (BRD, Abyssea).
--
-- NOTE: Upstream LSB shipped the spell_list row but never added the
-- player-side handler. Matches the dispatch pattern used by Earth Carol.
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.spells.enhancing.useEnhancingSong(caster, target, spell)
end

return spellObject
