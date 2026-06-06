-----------------------------------
-- auto_unstick.lua
--
-- Server-side watchdog that clears stuck event state from any player on
-- zone-in. Lets a wedged character self-rescue just by logging back in.
--
-- The two things this fixes:
--
--   1. If `isInEvent()` is still true a brief moment after zone-in
--      finished (zone change should have cleared it, so any residual
--      true value is stuck state), force a release().
--
--   2. If the player is in their home-nation Mog House and has all 3
--      flower-quest flags set but the 2F-unlock flag is missing, the
--      vanilla code auto-triggers the 2F unlock cutscene (CS 3535 in
--      S.S.d.) on every zone-in. If that cutscene gets interrupted,
--      the player relogs straight back into the same stuck state.
--      To break the loop, we pre-set the unlock flag so the CS won't
--      auto-trigger. The cutscene is purely cosmetic - losing it is
--      a fair trade for being able to log in.
--
-- The module overrides the standard Zone.onZoneIn for every starting-
-- city Mog House zone. The override runs the original logic first
-- (so legitimate cutscenes still play on first-ever zone-in), then
-- applies the watchdog with a small timer to give zone-load packets
-- time to settle.
-----------------------------------
require('modules/module_utils')

local m = Module:new('auto_unstick')

-- How long after zone-in we wait before checking for stuck event state.
-- Long enough for legit cutscenes to start; short enough that a stuck
-- player gets released quickly.
local UNSTICK_DELAY_MS = 3000

-- Bitflag for "2F unlocked" in the moghouse-flag field. Pre-setting it
-- prevents the auto-trigger cutscene from re-firing on every zone-in.
local MH_FLAG_UNLOCKED_2F = 0x0020

-- Zones we watch. These are the home-nation Mog House zones that can
-- auto-trigger the 2F unlock CS.
local MH_ZONES = {
    'Southern_San_dOria',
    'Northern_San_dOria',
    'Port_San_dOria',
    'Bastok_Mines',
    'Bastok_Markets',
    'Port_Bastok',
    'Windurst_Waters',
    'Windurst_Walls',
    'Port_Windurst',
    'Windurst_Woods',
}

-- Require every zone script we override.
for _, zoneName in ipairs(MH_ZONES) do
    require(string.format('scripts/zones/%s/Zone', zoneName))
end

local function unstickWatchdog(player)
    -- Don't fight a legit event that's actively progressing - only
    -- intervene if the player is wedged with no apparent way out.
    if not player:isInEvent() then
        return
    end

    -- Force-release. Equivalent to !releaseme on themselves but no
    -- chat input required.
    player:release()

    -- Pre-set the 2F unlock flag so the auto-CS won't fire next time.
    -- The vanilla code does this AFTER the CS triggers; we do it
    -- preemptively so the loop can't restart.
    local mhFlag = player:getMoghouseFlag()
    if bit.band(mhFlag, MH_FLAG_UNLOCKED_2F) == 0 then
        player:setMoghouseFlag(bit.bor(mhFlag, MH_FLAG_UNLOCKED_2F))
    end

    player:printToPlayer('[auto_unstick] Cleared stuck event state on zone-in.')
end

local function installZoneInHook(zoneName)
    m:addOverride(string.format('xi.zones.%s.Zone.onZoneIn', zoneName), function(player, prevZone)
        -- Run the original onZoneIn first. If it returns a cutscene id
        -- the engine will start that cutscene. We then schedule the
        -- watchdog to check on stuck state after a delay.
        local result = super(player, prevZone)

        player:timer(UNSTICK_DELAY_MS, unstickWatchdog)

        return result
    end)
end

for _, zoneName in ipairs(MH_ZONES) do
    installZoneInHook(zoneName)
end

return m
