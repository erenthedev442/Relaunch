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
-- Returns the active event with the highest priority, or nil if none.
-----------------------------------
function M.getActiveEvent()
    local now     = os.time()
    local best    = nil
    local bestPri = -math.huge
    for _, ev in ipairs(catalog.events) do
        if now >= ev.start and now < ev.finish then
            local pri = ev.priority or 0
            if pri > bestPri then
                best    = ev
                bestPri = pri
            end
        end
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
