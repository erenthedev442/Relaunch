-----------------------------------
-- Spell: Army's Paeon VIII
-- Gradually restores target's HP.
-- Spell row: sql/spell_list.sql id 385 (BRD, 8s cast, 24s recast).
--
-- NOTE: Upstream LSB shipped the spell_list row but never added the
-- player-side handler. Matches the dispatch pattern used by
-- Army's Paeon II–VI (thin call into the enhancing-song pipeline).
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
