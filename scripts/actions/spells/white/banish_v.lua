-----------------------------------
-- Spell: Banish V
-- Single-target light-element damage.
-- Spell row: sql/spell_list.sql id 32 (WHM, 159 MP, 7.5s cast, 60s recast).
--
-- NOTE: Upstream LSB shipped the spell_list row but never added the
-- player-side handler. Matches the dispatch pattern used by
-- Banish II–IV (thin call into the damage-spell pipeline).
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.spells.damage.useDamageSpell(caster, target, spell)
end

return spellObject
