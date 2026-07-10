-----------------------------------
-- happy_hour.lua
--
-- Scheduled server-wide "Happy Hour": during the daily window(s) below, every
-- online player gets +50% EXP (Dedication) and +50% Capacity Points
-- (Commitment) for the remainder of the window. Announced to each player as
-- their tick first lands inside the window.
--
-- Mechanism (same carrier pattern as world_boss/Invasion -- there is no global
-- scheduler): every zone-in arms a re-arming 60s player timer (player timers
-- die on zone transfer, so re-arming from onGameIn keeps a session covered).
-- Ticks are idempotent: buffs are only (re)applied when missing or weaker, so
-- a stronger EXP/CP ring buff is never downgraded, and re-zoning inside the
-- window simply re-applies for the time left.
--
-- The player portal mirrors WINDOWS for its Live Events card -- keep
-- tools/player_portal app.py HH_WINDOWS in sync when editing.
--
-- New module -> map RESTART to activate.
-----------------------------------
require('modules/module_utils')

local m = Module:new('happy_hour')

-- UTC windows. hour/min = start, durationMin = length.
local WINDOWS =
{
    { hour = 20, min = 0, durationMin = 60 },   -- 20:00-21:00 UTC daily
}

local EXP_BONUS   = 50      -- Dedication power (+% EXP)
local CP_BONUS    = 50      -- Commitment power (+% capacity points)
local BONUS_CAP   = 500000  -- subPower: total bonus points the effect may pay out
local TICK_MS     = 60000   -- re-arming player tick

-- Returns windowStart, windowEnd (epoch) when `now` is inside a window.
local function activeWindow(now)
    local dayStart = math.floor(now / 86400) * 86400
    for _, w in ipairs(WINDOWS) do
        -- check today's and yesterday's instance (a window may span midnight)
        for _, base in ipairs({ dayStart, dayStart - 86400 }) do
            local s = base + w.hour * 3600 + w.min * 60
            local e = s + w.durationMin * 60
            if now >= s and now < e then
                return s, e
            end
        end
    end
    return nil
end

-- Apply one buff without ever downgrading a stronger existing one (rings).
local function applyBuff(player, effect, power, seconds)
    local cur = player:getStatusEffect(effect)
    if cur and cur:getPower() >= power then
        return
    end
    if cur then
        player:delStatusEffectSilent(effect)
    end
    player:addStatusEffect(effect, {
        power    = power,
        duration = seconds,
        origin   = player,
        subPower = BONUS_CAP,
    })
end

local function onTick(player)
    if not player or not player:getID() then
        return
    end

    local s, e = activeWindow(os.time())
    if s then
        local left = e - os.time()
        if left > 45 then -- don't bother (re)applying for the final sliver
            applyBuff(player, xi.effect.DEDICATION, EXP_BONUS, left)
            applyBuff(player, xi.effect.COMMITMENT, CP_BONUS, left)
        end
        if player:getLocalVar('HH_Announced') ~= s then
            player:setLocalVar('HH_Announced', s)
            player:printToPlayer(string.format(
                '[Happy Hour] The tavern is open! +%d%% EXP and +%d%% Capacity Points for the next %d minutes!',
                EXP_BONUS, CP_BONUS, math.ceil(left / 60)), xi.msg.channel.SYSTEM_3)
        end
    end

    -- Re-arm. Dies with the zone entity; onGameIn re-arms on the next zone-in.
    player:timer(TICK_MS, function(p) onTick(p) end)
end

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    -- Arm on EVERY zone-in (player timers do not survive zoning). First tick
    -- runs shortly after arrival so mid-window zoners get buffed fast.
    player:timer(5000, function(p) onTick(p) end)
end)

return m
