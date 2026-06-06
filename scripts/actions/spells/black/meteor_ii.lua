-----------------------------------
-- Spell: Meteor II
-- Heavy single-target nuke. Spell row: sql/spell_list.sql id 244
-- (BLM, 666 MP, 5s cast, 10s recast, @ELEMENT_LIGHT).
--
-- NOTE: Upstream LSB shipped the spell_list row but never added the
-- player-side handler — players hit "no Lua file" when casting.
--
-- Unlike Meteor I (which has bespoke non-elemental damage in
-- scripts/actions/spells/black/meteor.lua), Meteor II's DB row uses
-- ELEMENT_LIGHT and we have no authoritative retail formula. We route
-- through the standard damage-spell pipeline so MAB / MDB / Light
-- resistances all interact as expected; tune the damage by adjusting
-- the spell_list base/multiplier columns if needed.
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
