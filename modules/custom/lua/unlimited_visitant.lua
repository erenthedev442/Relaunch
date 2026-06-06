-----------------------------------
-- unlimited_visitant.lua
--
-- Gives every player permanent Visitant status the moment they zone
-- into any Abyssea area. No timer, no kick to Searing Ward, no need to
-- farm pearls or atmas just to stay alive long enough to fight.
--
-- How it works
-- ------------
--   Overrides the single entry point `xi.abyssea.afterZoneIn`, which is
--   the helper every Abyssea zone's `Zone.afterZoneIn` script calls. By
--   replacing this one function we cover all 10 Abyssea zones without
--   touching the per-zone scripts.
--
--   The override:
--     1. Removes any existing VISITANT effect (could be a stale timed
--        one from before this module was enabled).
--     2. Re-applies VISITANT with no duration - the same pattern the
--        retail code uses for GMs in `xi.abyssea.onZoneIn`. With no
--        duration the engine treats the effect as permanent, so the
--        countdown never reaches zero and the player is never ejected.
--
-- Why this is safe
-- ----------------
--   `scripts/globals/player.lua` ejects players from Abyssea on
--   logon if they don't have the VISITANT effect. Because we apply
--   permanent VISITANT during the zone-in sequence (which runs before
--   the logon eject check), the effect is always present and the
--   eject is bypassed.
--
-- Module enable/disable
-- ---------------------
--   Enabled by default. Set `setEnabled(false)` to fall back to
--   retail's timed visitant behavior.
-----------------------------------
require('modules/module_utils')

local unlimitedVisitant = Module:new('unlimited_visitant')

-----------------------------------
-- Module enable/disable
-----------------------------------
unlimitedVisitant:setEnabled(true)

-----------------------------------
-- Override the shared Abyssea after-zone-in hook
-----------------------------------
unlimitedVisitant:addOverride('xi.abyssea.afterZoneIn', function(player)
    -- Intentionally do NOT call super(): the retail implementation
    -- applies a 304-second timed visitant that we're replacing.

    -- Wipe any pre-existing visitant effect so we don't double-stack
    -- or inherit a near-expiring timer from before this module loaded.
    if player:hasStatusEffect(xi.effect.VISITANT) then
        player:delStatusEffect(xi.effect.VISITANT)
    end

    -- Apply permanent visitant. No `duration` field -> the engine
    -- treats it as a status with no expiry. This matches the
    -- GM-toggle path in xi.abyssea.onZoneIn.
    player:addStatusEffect(xi.effect.VISITANT, { origin = player })
end)

return unlimitedVisitant
