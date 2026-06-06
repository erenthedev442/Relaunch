-----------------------------------
-- Spell: Poison V
-- Spell row: sql/spell_list.sql id 224 (BLM/RDM, 1s cast, 5s recast, 140 MP).
--
-- NOTE: Upstream LSB shipped the spell_list row but never added the
-- player-side handler. Matches the dispatch pattern used by
-- Poison II / Poison III.
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.spells.enfeebling.useEnfeeblingSpell(caster, target, spell)
end

return spellObject
