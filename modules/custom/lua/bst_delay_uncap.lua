-----------------------------------
-- bst_delay_uncap.lua
--
-- Makes BST "Call Beast ability delay" gear + augments actually scale Sic
-- recast (since Call Beast / Bestial Loyalty are already at 0 recast on this
-- server, that augment slot is wasted unless we redirect it).
--
-- THE PROBLEM: CALL_BEAST_DELAY (mod 273) is defined in modifier.h but is
-- NEVER consumed anywhere in C++ or Lua. Call Beast and Bestial Loyalty
-- are already at 0 recast (bst_callbeast_recast_0.sql), so the "Call Beast
-- ability delay" augment (augId 324, mod 273) does absolutely nothing.
--
-- In contrast, SIC_READY_RECAST (mod 1052) IS consumed by the C++ handler
-- (charentity.cpp:1904) for Sic and Ready — no cap, already correct.
--
-- THE FIX: Override checkSic to also read CALL_BEAST_DELAY and apply it
-- to the Sic recast via ability:setRecast() (which feeds the C++ flow at
-- charentity.cpp:1820 before the C++ then adds its SIC_READY_RECAST
-- reduction at line 1904 — no double-counting).
--
-- Combined effect: max(floor, base - CALL_BEAST_DELAY) - SIC_READY_RECAST
-- ≈ max(0, base - (CALL_BEAST_DELAY + SIC_READY_RECAST))
--
-- Pure Lua override module → needs ONE map restart to load. No C++ rebuild.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/job_utils/beastmaster')

local m = Module:new('bst_delay_uncap')

local CONFIG =
{
    floor = 0, -- Sic can recast as fast as 0s (fully uncapped). Raise to keep a minimum cooldown.
}

m:addOverride('xi.job_utils.beastmaster.checkSic', function(player, target, ability)
    local result, param = super(player, target, ability)

    -- Only apply when Sic passes its normal checks.
    -- C++ will apply SIC_READY_RECAST (mod 1052) itself after this returns.
    -- We only add CALL_BEAST_DELAY (mod 273), which is otherwise never consumed.
    if result == 0 then
        local callDelay = player:getMod(xi.mod.CALL_BEAST_DELAY)
        if callDelay > 0 then
            ability:setRecast(math.max(CONFIG.floor, ability:getRecast() - callDelay))
        end
    end

    return result, param
end)

return m
