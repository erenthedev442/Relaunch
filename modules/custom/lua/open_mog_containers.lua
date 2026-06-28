-----------------------------------
-- open_mog_containers.lua
-- Opens the Mog Sack and Mog Locker for EVERY player (new + existing) on
-- login, idempotently. Retail gates these:
--   * Mog Sack   - bought from the Artisan for ~9,980 gil (scripts/globals/artisan.lua).
--   * Mog Locker - rented at Nomad Moogles with Imperial currency; expires.
-- Here both are simply granted at full size, and the Locker is set to never
-- expire with all-areas access (usable at any Nomad Moogle or your own Mog
-- House -- the Locker is inherently location-gated by the engine, even retail).
--
-- Mog Satchel is already opened at character creation (START_INVENTORY), and
-- Mog Case + Wardrobes default to 80, so they are not touched here.
--
-- Pure-Lua override; survives upstream pulls. RESTART-GATED (onGameIn hook).
-- Existing characters get it on their next login -- no SQL backfill needed.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')
require('scripts/globals/moghouse')

local m = Module:new('open_mog_containers')

-- Target capacities (engine max is 80). Tune freely.
local SACK_SIZE   = 80
local LOCKER_SIZE = 80

-- changeContainerSize is a DELTA, not an absolute setter -- grow only the gap
-- so re-running on an already-opened character never overshoots.
local function growTo(player, loc, target)
    local delta = target - player:getContainerSize(loc)
    if delta > 0 then
        player:changeContainerSize(loc, delta)
    end
end

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    -- Capture the real-login signal BEFORE super() runs (super clears gameLogin).
    -- This keeps the work to once per login instead of every zone-in.
    local isLogin = player:getLocalVar('gameLogin') == 1
    super(player, firstLogin, zoning)
    if not isLogin then
        return
    end

    -- INCIDENT 2026-06-28 -- DISABLED for emergency recovery (mirrors live fix d851cf83b4).
    -- Calling changeContainerSize() during onGameIn forces the ITEM_MAX packet to
    -- build mid-LoadChar, which calls C++ hasMogLockerAccess() BEFORE the char is
    -- fully constructed -> hard SEGV. On the relaunch this crash-looped logins after
    -- the affinity-fix map restart activated this restart-gated override (Jbae could
    -- not log in). Short-circuit to stop the outage. TODO: re-enable DEFERRED to
    -- post-login (player:timer) so the ITEM_MAX build happens at a safe point. See
    -- reference_ongamein_mod_defer.
    do return end

    -- Mog Sack: capacity is all it needs (accessible anywhere, like the Satchel).
    growTo(player, xi.inv.MOGSACK, SACK_SIZE)

    -- Mog Locker: never-expire rental + full capacity + all-areas access.
    xi.moghouse.unlockMogLocker(player)           -- expiry = -1 (never), sizes to 30 if 0
    growTo(player, xi.inv.MOGLOCKER, LOCKER_SIZE)  -- bump up to full size
    xi.moghouse.setMogLockerAccessType(player, xi.moghouse.lockerAccessType.ALLAREAS)
end)

return m
