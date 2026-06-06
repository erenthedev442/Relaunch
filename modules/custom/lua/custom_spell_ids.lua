-----------------------------------
-- custom_spell_ids.lua
--
-- Registers our custom xi.magic.spell.* constants at boot so we DON'T have to
-- edit the tracked core file scripts/enum/magic.lua. Keeping that file pristine
-- means LSB upstream updates never produce a merge conflict on it.
--
-- Single mirror of the entries that used to live in magic.lua:
--
--   SKOLL        =  901  -> repurposed "Nanaa Mihgo" trust slot (pool 5901);
--                           summons Gemma (re-themed; legacy id name "SKOLL"). See trust_skoll.lua + SQL.
--   DIVINE_AEGIS = 1020  -> custom PLD spell; scripts/actions/spells/white/divine_aegis.lua
--   CONVERGENCE  = 1021  -> custom RDM spell; scripts/actions/spells/white/convergence.lua
--                           (NOTE: distinct from stock BLU "Convergence", which
--                            is a job ability/effect, not a spell.)
--
-- These constants are referenced only for readability -- the spells are bound
-- by spell_list.name in modules/custom/sql and their scripts load by name, so
-- registration order does not matter. The guard keeps this safe even if
-- xi.magic.spell were somehow not built yet.
-----------------------------------
require('modules/module_utils')

local m = Module:new('custom_spell_ids')

if xi and xi.magic and xi.magic.spell then
    xi.magic.spell.SKOLL        =  901   -- repurposed Nanaa Mihgo slot (pool 5901)
    xi.magic.spell.DIVINE_AEGIS = 1020   -- custom PLD spell
    xi.magic.spell.CONVERGENCE  = 1021   -- custom RDM spell (not the BLU ability)
end

return m
