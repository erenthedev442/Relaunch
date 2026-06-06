-----------------------------------
-- Spell: Foe Requiem VIII
-- Gradually deals damage to enemies within the area of effect.
-- Spell row: sql/spell_list.sql id 375 (BRD lv ?, 2s cast, 24s recast).
--
-- NOTE: Upstream LSB shipped the spell_list row but never added the
-- player-side handler — the engine errors with "no Lua file" when a
-- player tries to cast it. This handler matches the pattern used by
-- Foe Requiem II–VII (thin dispatch to the enfeebling-song pipeline).
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.spells.enfeebling.useEnfeeblingSong(caster, target, spell)
end

return spellObject
