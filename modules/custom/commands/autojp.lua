-----------------------------------
-- func: autojp
-- desc: Auto-spends all unspent job points on whichever categories of
--       the player's CURRENT MAIN JOB can still be upgraded, distributing
--       breadth-first so every category grows evenly.
--
-- ALGORITHM (breadth-first cycling):
--   1. Snapshot the unspent JP balance for the current job.
--   2. Loop: for each JP id in xi.jp, call player:raiseJobPoint(id).
--      The engine (CJobPoints::RaiseJobPoint) silently no-ops if:
--        * the player can't afford the next rank (cost = 1 + currentRank),
--        * the category is already at rank 20 (the cap),
--        * the jp id doesn't belong to the player's current main job.
--      So we brute-force every id and trust the engine's filter.
--   3. After a pass with at least one successful raise, loop again.
--      First pass adds rank 1 to every category, second pass adds rank 2
--      (which costs 2 JP each), etc. - breadth-first by construction.
--
-- USAGE
--   !autojp             -- spend the caller's JP on their current job
--
-- NOTES
--   - Only spends on the caller's current main job. Switch jobs first to
--     upgrade a different job.
--   - JP is earned at lv 99 cap via capacity points. This command does
--     NOT grant free JP - it only spends what the player already has.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = ''
}

-- Pretty job-id-to-name map for the summary message.
local function jobName(jobId)
    for name, value in pairs(xi.job) do
        if value == jobId then return name end
    end
    return string.format('job#%d', jobId)
end

commandObj.onTrigger = function(player)
    local mainJob = player:getMainJob()
    local before  = player:getJobPoints(mainJob)

    if before == 0 then
        player:printToPlayer(string.format(
            '%s has 0 unspent JP on %s - nothing to do.',
            player:getName(), jobName(mainJob)))
        return
    end

    -- Snapshot just THIS JOB's JP ids. xi.jp ids encode the job in the
    -- upper bits: id >> 5 == jobId. Filtering here matters because the
    -- engine's CJobPoints::RaiseJobPoint has NO current-job guard - if
    -- we passed a non-current-job id and the player had JP in that
    -- other job's pool, it would silently deduct from that pool. The
    -- user expects !autojp to spend on the CURRENT job only, so we
    -- only consider ids whose category index matches mainJob.
    local jpIds = {}
    for _, id in pairs(xi.jp) do
        if math.floor(id / 32) == mainJob then
            table.insert(jpIds, id)
        end
    end

    -- Hard cap to bullet-proof against any future engine change that
    -- could no-op without deducting (would otherwise infinite-loop).
    local MAX_PASSES = 100
    local pass       = 0
    local applied    = 0

    while pass < MAX_PASSES do
        pass = pass + 1
        local anyUpgrade = false

        for _, id in ipairs(jpIds) do
            if player:raiseJobPoint(id) then
                applied    = applied + 1
                anyUpgrade = true
            end
        end

        if not anyUpgrade then break end
        if player:getJobPoints(mainJob) == 0 then break end
    end

    local after = player:getJobPoints(mainJob)
    local spent = before - after

    player:printToPlayer(string.format(
        'Auto-spent %d JP on %s (%s) across %d upgrade(s). Balance: %d -> %d.',
        spent, player:getName(), jobName(mainJob), applied, before, after))

    if after > 0 then
        -- Cost of next rank in any remaining category is > current balance,
        -- OR every category for the current job is at rank 20.
        player:printToPlayer(string.format(
            '  %d unspent left - every category on %s is maxed (rank 20) or the next-rank cost exceeds the remaining balance.',
            after, jobName(mainJob)))
    end
end

return commandObj
