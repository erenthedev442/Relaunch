-----------------------------------
-- real_level.lua
-- Shared "Real Level" computation. Used by BOTH the !reallevel command
-- (display) and RealLevel_Tracker (login hook -> RealLevel CharVar that the
-- website leaderboard ranks), so the formula lives in ONE place and the two
-- can never drift apart.
--
-- Real Level = base job level + the sum of four independent bonuses:
--   gear  = getAverageItemLevel() - 99         (weapon-weighted iLvl above 99)
--   asc   = Prestige_Level_<job> CharVar        (completed Ascensions, cur. job)
--   jp    = getSpentJobPoints() / JP_PER_LEVEL  (current-job Job Points)
--   merit = sum(7 attribute merits) / MERIT_ATTR_PER_LEVEL
--
-- This is a plain require()-library (returns a table), NOT a Module. Everything
-- under custom/lua/ is auto-loaded at startup, so NOTHING here may touch xi.* at
-- file scope -- all xi.* lookups happen inside the functions, run only at call
-- time.
-----------------------------------
local M = {}

-- Tunables (the only knobs). Lower divisor = each JP / merit point is worth
-- more real-levels. Gear and Ascension are deliberately 1:1.
M.JP_PER_LEVEL         = 100
M.MERIT_ATTR_PER_LEVEL = 5
-- The 7 base-attribute merits we can read exactly via getMerit(). HP/MP merits
-- are excluded -- their values dwarf the attribute signal.
M.ATTR_MERITS          = { 'STR', 'DEX', 'VIT', 'AGI', 'INT', 'MND', 'CHR' }

-- Compute a player's Real Level. Returns (realLevel, breakdown) for a PC, or
-- nil for a non-PC / nil entity (callers guard, but be safe).
function M.compute(player)
    if player == nil or player:getObjType() ~= xi.objType.PC then
        return nil
    end

    local job  = player:getMainJob()
    local base = player:getMainLvl()

    local ilvl    = player:getAverageItemLevel()
    local gearLv  = math.max(0, ilvl - 99)
    local ascLv   = player:getCharVar('Prestige_Level_' .. job) or 0
    local jpSpent = player:getSpentJobPoints() or 0
    local jpLv    = math.floor(jpSpent / M.JP_PER_LEVEL)

    local meritSum = 0
    for _, mname in ipairs(M.ATTR_MERITS) do
        meritSum = meritSum + (player:getMerit(xi.merit[mname]) or 0)
    end
    local meritLv = math.floor(meritSum / M.MERIT_ATTR_PER_LEVEL)

    local realLevel = base + gearLv + ascLv + jpLv + meritLv
    return realLevel,
    {
        job      = job,
        base     = base,
        gear     = gearLv,
        asc      = ascLv,
        jp       = jpLv,
        merit    = meritLv,
        bonus    = gearLv + ascLv + jpLv + meritLv,
        ilvl     = ilvl,
        jpSpent  = jpSpent,
        meritSum = meritSum,
    }
end

-- Compute + persist to the RealLevel CharVar (drives the website leaderboard).
-- Returns the value, or nil for a non-PC.
function M.refresh(player)
    local rl = M.compute(player)
    if rl ~= nil then
        player:setCharVar('RealLevel', rl)
    end
    return rl
end

return M
