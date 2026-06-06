-----------------------------------
-- roe_gain_exp_always_on.lua
-- Makes RoE timed record 4013 ("Gain Experience") active in EVERY 4-hour
-- slot of EVERY day, replacing the upstream rotation that only ran it
-- 3 times per week. Players still earn it the normal way (gain 5000 EXP
-- within the slot for +1500 EXP / +300 sparks / +300 accolades /
-- 1 Copper Aman Voucher) -- it's just always available.
--
-- The matching on-demand shortcut is modules/custom/commands/gainexp.lua
-- (instant claim for any player). The two work together: timed record
-- is grindable 24/7 AND there's a one-button claim.
--
-- Why a custom module rather than editing scripts/globals/roe.lua:
--   scripts/ is tracked from upstream LandSandBoat. A `git pull` against
--   the upstream remote would revert any edits to roe.lua and silently
--   wipe this customization. modules/custom/ is the documented extension
--   point that survives upstream merges.
--
-- How it works:
--   1. We `require` scripts/globals/roe, which runs xi.roe.initialize()
--      at the bottom of that file (line 164). That call parses the
--      default 14-record rotation via RoeParseTimed(<upstream schedule>).
--   2. Then we call RoeParseTimed(<our always-4013 schedule>) ourselves.
--      The C++ binding (src/map/roe.cpp::ParseTimedSchedule) does
--      `TimedRecords.reset()` and `TimedRecordTable.fill(...)` first, so
--      our call fully replaces the upstream schedule -- no partial merge.
--   3. The ENABLE_ROE / ENABLE_ROE_TIMED settings guard mirrors upstream
--      so we don't install the schedule when RoE itself is disabled.
--
-- To revert: delete this file and restart the map server. Upstream
-- rotation comes back automatically.
--
-- Customization knobs:
--   - To use the original variety of records but with more 4013 slots,
--     copy the upstream `timedSchedule` from scripts/globals/roe.lua:111
--     and swap individual slot IDs to 4013.
--   - To use a different record entirely (eg. 4014 "Spoils"), replace
--     every 4013 below with the desired record ID. See the comment
--     block in this file's sibling roe_records.lua for the full ID list.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/roe')

local m = Module:new('roe_gain_exp_always_on')

-- 7 days x 6 four-hour blocks. Every slot holds record 4013.
local alwaysOnSchedule =
{
--    00-04  04-08  08-12  12-16  16-20  20-00  (JST)
    {  4013,  4013,  4013,  4013,  4013,  4013 }, -- Sunday
    {  4013,  4013,  4013,  4013,  4013,  4013 }, -- Monday
    {  4013,  4013,  4013,  4013,  4013,  4013 }, -- Tuesday
    {  4013,  4013,  4013,  4013,  4013,  4013 }, -- Wednesday
    {  4013,  4013,  4013,  4013,  4013,  4013 }, -- Thursday
    {  4013,  4013,  4013,  4013,  4013,  4013 }, -- Friday
    {  4013,  4013,  4013,  4013,  4013,  4013 }, -- Saturday
}

if xi.settings.main.ENABLE_ROE and xi.settings.main.ENABLE_ROE_TIMED > 0 then
    RoeParseTimed(alwaysOnSchedule)
end

return m
