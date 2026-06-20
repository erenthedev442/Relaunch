-----------------------------------
-- !resetjobmerits [player]
-- GM command (permission 1+).
--
-- Clears all job-specific merit ranks (Others, Group 1, Group 2, WS) from
-- the target player and refunds the exact merit points that were spent on
-- them.  Used to fix characters whose Group 1/2 combo totals were consumed
-- by the OLD !automerits command (which had no category filter).
--
-- The ACTIVE automerits.lua is already safe; this command is for targeted
-- one-player fixes on ONLINE characters.  For a bulk repair of ALL chars
-- (including offline ones) run sql/zz_repair_job_merits.sql followed by a
-- map server restart.
--
-- Requires the lowerMerit(meritId, refundPoints) C++ binding from
-- modules/custom/cpp/auto_spend_bindings.cpp (needs a rebuild to activate).
-----------------------------------
require('modules/module_utils')
local m = Module:new('resetjobmerits')

-- Per-rank costs (mirror merit.cpp upgrade[] array).
-- Index = rank being removed (1-based: index 1 = removing rank 0→1).
local G1_PER_RANK = { 1,  2,  3,  4,  5  } -- UpgradeID 5/6 (Others + Group 1)
local G2_PER_RANK = { 3,  4,  5,  5,  5  } -- UpgradeID 7  (Group 2)
local WS_PER_RANK = { 20, 22, 24, 27, 30 } -- UpgradeID 8  (Weapon Skills)

-- WS meritid range: 0x0680..0x06BF (1664..1727)
local WS_MIN = 0x0680
local WS_MAX = 0x06BF
-- Group 2 starts at 0x0800 (2048)
local G2_MIN = 0x0800
-- Generic categories end at 0x0100; job-specific starts at 0x0140
local JOB_MERIT_MIN = 0x0140

local function perRankCost(meritId, rank)
    local tbl
    if meritId >= G2_MIN then
        tbl = G2_PER_RANK
    elseif meritId >= WS_MIN and meritId <= WS_MAX then
        tbl = WS_PER_RANK
    else
        tbl = G1_PER_RANK
    end
    return tbl[math.min(rank, #tbl)] or tbl[#tbl]
end

m:addCommand('resetjobmerits', {
    permission = 1,
    parameters = 'O',
    description = 'Reset job-specific (Group 1/2/WS/Others) merits and refund spent points.',
}, function(player, targetArg)
    local target = targetArg or player

    local removedMerits = 0
    local refundTotal   = 0

    for _, meritId in pairs(xi.merit) do
        local cat = bit.band(meritId, 0xFFC0)
        if cat >= JOB_MERIT_MIN then
            local rank = target:getMerit(meritId)
            -- getMerit returns 0 for other-job merits (engine blocks),
            -- so we only touch this player's own job merits.
            while rank > 0 do
                local cost = perRankCost(meritId, rank)
                target:lowerMerit(meritId, cost)
                refundTotal = refundTotal + cost
                rank = rank - 1
                removedMerits = removedMerits + 1
            end
        end
    end

    local name = target:getName()
    if removedMerits == 0 then
        player:printToPlayer(
            string.format('[resetjobmerits] %s has no job-specific merit ranks to remove.', name),
            xi.msg.channel.SYSTEM_3
        )
    else
        player:printToPlayer(
            string.format('[resetjobmerits] %s: removed %d rank(s), refunded %d merit point(s). Unspent balance: %d.',
                name, removedMerits, refundTotal, target:getMeritCount()),
            xi.msg.channel.SYSTEM_3
        )
    end
end)

return m
