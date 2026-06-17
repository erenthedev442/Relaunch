-----------------------------------
-- unlimited_visitant.lua
--
-- Gives every player effectively-permanent Abyssea Visitant status on entry,
-- so nobody is ejected for running out of time -- INCLUDING when entering via
-- the !abyssea warp command (a raw setPos).
--
-- 2026-06-17 FIX -- why we hook onZoneIn now:
--   The retail visitant grant for normal players lives ONLY in
--   xi.abyssea.afterZoneIn (abyssea.lua:1176). That deferred hook does NOT
--   reliably fire on a plain setPos warp (how !abyssea enters Abyssea), so
--   players were landing with NO visitant at all and had to use !visitant.
--   xi.abyssea.onZoneIn DOES fire on every entry -- it's where the retail GM
--   grant lives (abyssea.lua:1156) -- so we hook BOTH and grant in each.
--   Whichever fires, the player ends up with permanent visitant.
--
-- Why we NEVER delStatusEffect(VISITANT):
--   Losing VISITANT while in Abyssea fires its onEffectLose -> startEvent(2180),
--   the eject cutscene (scripts/effects/visitant.lua). The old version of this
--   module delStatusEffect'd to "refresh" and could kick the player out. We now
--   extend the effect IN PLACE (setDuration/resetStartTime, the !addabytime
--   pattern) or add a fresh no-duration one -- never remove it.
--   See memory [[reference_abyssea_visitant]].
--
-- This is an onZoneIn/afterZoneIn OVERRIDE module -> it needs a MAP RESTART to
-- take effect (override hooks are applied at module load, not on hot-reload).
-----------------------------------
require('modules/module_utils')
require('scripts/globals/abyssea')

local m = Module:new('unlimited_visitant')
m:setEnabled(true)

-- 14 days (ms). Far longer than any session, so the visitant countdown never
-- reaches its warning window. Only used to promote an already-running timed
-- effect in place; a brand-new grant is a truly permanent no-duration effect.
local PERMA_MS = 1209600000

local function ensurePermanentVisitant(player)
    local effect = player:getStatusEffect(xi.effect.VISITANT)
    if effect then
        -- Promote an existing (possibly timed 304s) visitant. NEVER remove it.
        effect:setDuration(PERMA_MS)
        effect:resetStartTime()
        effect:setIcon(xi.effect.VISITANT)
    else
        -- No visitant present: grant the permanent (no-duration) effect, the
        -- same one retail hands visible GMs.
        player:addStatusEffect(xi.effect.VISITANT, { origin = player })
    end
end

-- Primary: onZoneIn fires on EVERY Abyssea entry, setPos warps included.
-- Intentionally no super() -- the only thing the retail onZoneIn does is the
-- visible-GM visitant grant, which ensurePermanentVisitant already covers for
-- everyone.
m:addOverride('xi.abyssea.onZoneIn', function(player)
    ensurePermanentVisitant(player)
end)

-- Belt-and-suspenders: also cover the deferred hook (normal portal entry).
-- No super() -- skips the retail 304s timed grant + time message; we want
-- permanent. onZoneIn has already granted by the time this runs.
m:addOverride('xi.abyssea.afterZoneIn', function(player)
    ensurePermanentVisitant(player)
end)

return m
