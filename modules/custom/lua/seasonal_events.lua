-----------------------------------
-- seasonal_events.lua
-- Applies seasonal mark multipliers to Hunting League kills.
-- Called from HuntingLeague.lua's kill handler via se.applyBonus().
--
-- Integration:
--   local se = require('modules/custom/lua/seasonal_events')
--   finalMarks = se.applyBonus(killer, finalMarks)
--
-- To schedule an event: edit seasonal_events_catalog.lua (no code change
-- needed here).  Events are evaluated at kill-time against os.time().
-----------------------------------
require('modules/module_utils')
local catalog = require('modules/custom/lua/seasonal_events_catalog')

local M = {}

-----------------------------------
-- Dynamic event cache.
-- !setbonus writes seasonal_events_dynamic.lua at runtime; we poll it
-- via loadfile (bypasses require cache) with a 60-second TTL so the
-- new event propagates within one minute without a server restart.
-----------------------------------
local _dynCache       = nil
local _dynCacheExpiry = 0

local function getDynamicEvents()
    local now = os.time()
    if _dynCache and now < _dynCacheExpiry then
        return _dynCache
    end
    local ok, fn = pcall(loadfile, 'modules/custom/lua/seasonal_events_dynamic.lua')
    if ok and type(fn) == 'function' then
        local ok2, events = pcall(fn)
        _dynCache = (ok2 and type(events) == 'table') and events or {}
    else
        _dynCache = {}
    end
    _dynCacheExpiry = now + 60
    return _dynCache
end

-----------------------------------
-- Returns the active event with the highest priority, or nil if none.
-- Checks both the static catalog and the runtime-written dynamic file.
-----------------------------------
function M.getActiveEvent()
    local now     = os.time()
    local best    = nil
    local bestPri = -math.huge

    local function checkEvent(ev)
        if now >= ev.start and now < ev.finish then
            local pri = ev.priority or 0
            if pri > bestPri then
                best    = ev
                bestPri = pri
            end
        end
    end

    for _, ev in ipairs(catalog.events) do
        checkEvent(ev)
    end
    for _, ev in ipairs(getDynamicEvents()) do
        checkEvent(ev)
    end

    return best
end

-----------------------------------
-- Apply any active seasonal multiplier to a mark amount.
-- Announces the bonus to the player privately.
-- Returns the adjusted amount (same as input when no event is active).
-----------------------------------
function M.applyBonus(player, amount)
    local ev = M.getActiveEvent()
    if not ev then return amount end

    local boosted = math.floor(amount * ev.multiplier)
    local bonus   = boosted - amount
    if bonus > 0 then
        player:printToPlayer(
            string.format('[Event] %s: +%d bonus marks! (%.1fx multiplier)',
                ev.name, bonus, ev.multiplier),
            xi.msg.channel.SYSTEM_3)
    end
    return boosted
end

return M
