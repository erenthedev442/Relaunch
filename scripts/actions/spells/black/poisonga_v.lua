-----------------------------------
-- Spell: Poisonga V
-- AOE poison enfeeble.
-- Spell row: sql/spell_list.sql id 229 (BLM/RDM, 2s cast, 10s recast, 314 MP).
--
-- NOTE: Upstream LSB shipped the spell_list row but never added the
-- player-side handler. Matches the dispatch pattern used by
-- Poisonga II / Poisonga III.
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
