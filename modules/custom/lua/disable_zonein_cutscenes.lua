-----------------------------------
-- disable_zonein_cutscenes.lua
-- Suppresses every auto-cutscene that fires when a player zones into an
-- area and happens to meet the conditions of some mission/quest event.
--
-- How it works
-- ------------
-- The C++ engine calls InteractionGlobal.onZoneIn(player, prevZone, fn)
-- on every zone change. That dispatcher runs:
--   1. All registered interaction handlers (mission / quest progression
--      checks for this zone).
--   2. The zone's own onZoneIn() (the `fn` arg, eg. from
--      scripts/zones/<Zone>/Zone.lua).
-- Whatever it returns becomes PChar->currentEvent->eventId in C++. If
-- that ID is >= 0 the engine immediately starts the matching event ID
-- as a cutscene. If it's -1 nothing plays.
--
-- This override runs the dispatcher first (so SIDE EFFECTS still happen
-- -- position resets, mission-flag updates, key items being granted by
-- interaction handlers, etc.) and then unconditionally returns -1 to
-- suppress only the auto-played cutscene.
--
-- Safety / caveats
-- ----------------
--  * Cutscenes are still reachable by talking to the relevant NPC
--    (mission giver, quest giver, ??? marker). This only blocks the
--    auto-trigger-on-zone-in path.
--  * If a mission/quest REQUIRES viewing a zone-in cutscene to advance
--    and has no NPC fallback, that line will softlock with this module
--    enabled. Most retail FFXI content has an NPC fallback; the original
--    nation 1-99 / RotZ / CoP missions tend to be the most aggressive
--    about gating on zone-in cutscenes.
--  * The interaction framework may keep re-evaluating the same handler
--    every zone-in (because from its perspective the cutscene "never got
--    seen"). That's a small wasted check, not a bug.
--
-- To re-enable cutscenes: delete this file (or comment out the addOverride
-- call below) and restart the map server.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/interaction/interaction_global')

local m = Module:new('disable_zonein_cutscenes')

m:addOverride('InteractionGlobal.onZoneIn', function(player, prevZone, fallbackFn)
    -- Let the framework run normally so every side effect (position
    -- fixups, flag updates, charvar writes performed inside individual
    -- onZoneIn handlers) still applies. Then drop the event ID it
    -- returned -- that's the cutscene we want suppressed.
    super(player, prevZone, fallbackFn)
    return -1
end)

return m
