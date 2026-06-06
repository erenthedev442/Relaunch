-----------------------------------
-- Spell: Banishga V
-- AOE light-element damage.
-- Spell row: sql/spell_list.sql id 42 (WHM, 563 MP, 6s cast, 60s recast).
--
-- NOTE: Upstream LSB shipped the spell_list row but never added the
-- player-side handler. Matches the dispatch pattern used by
-- Banishga II–IV (thin call into the damage-spell pipeline).
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
