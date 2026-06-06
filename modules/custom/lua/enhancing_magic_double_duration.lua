-----------------------------------
-- enhancing_magic_double_duration.lua
-- Doubles the final duration of EVERY Enhancing Magic spell.
--
-- HOW IT WORKS
-- ============
-- xi.spells.enhancing.calculateEnhancingDuration (in
-- scripts/globals/spells/enhancing_spell.lua) is the single choke-point
-- where the final duration for ALL enhancing spells is computed and
-- returned. It is defined once (line ~387) and called from exactly one
-- place: useEnhancingSpell (line ~578). We wrap it and multiply the
-- AFTER-everything return value by DURATION_MULTIPLIER.
--
-- Because we scale the already-finished result, the 2x stacks cleanly on
-- top of every vanilla modifier the base function folds in first:
--   * gear  "Enhancing Magic Duration" %  (xi.mod.ENH_MAGIC_DURATION)
--   * RDM   merits + job points
--   * Composure   (x3, self-cast)
--   * Perpetuance (x2, white magic)
--   * Embolden    (~x0.5+)
--   * sub-target level penalty
-- Examples (default x2):
--   5-min Protect           -> 10 min
--   Composure'd 5-min buff  -> 30 min  (5 * 3 * 2)
--
-- WHY A MODULE (not a direct edit)
-- ================================
-- enhancing_spell.lua is upstream-tracked (LSB). Editing it would create
-- merge conflicts on every pull. This module override touches no tracked
-- file, so it survives upstream merges. It auto-loads via the
-- 'custom/lua/' folder entry already present in modules/init.txt.
--
-- TUNING: change DURATION_MULTIPLIER (2 = double, 3 = triple, 1.5 = +50%).
-----------------------------------
require('modules/module_utils')

local m = Module:new('enhancing_magic_double_duration')

-- The only knob: how much to scale every enhancing spell's duration.
local DURATION_MULTIPLIER = 2

m:addOverride('xi.spells.enhancing.calculateEnhancingDuration',
    function(caster, target, spell, spellId, spellGroup, spellEffect)
        -- `super` = the original calculateEnhancingDuration, bound by the
        -- module loader. Run all the vanilla math, then double the result.
        return super(caster, target, spell, spellId, spellGroup, spellEffect) * DURATION_MULTIPLIER
    end)

return m
