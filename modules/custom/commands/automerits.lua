-----------------------------------
-- func: automerits <player>
-- desc: Auto-spends all unspent merit points on whichever categories can
--       still be upgraded, distributing breadth-first so every category
--       grows evenly rather than one rank stack getting maxed first.
--
-- ALGORITHM (breadth-first cycling):
--   1. Snapshot the unspent merit balance.
--   2. Loop: for each merit ID in xi.merit, call player:raiseMerit(id).
--      The engine (CMeritPoints::RaiseMerit) silently no-ops if:
--        * the player can't afford the next rank,
--        * the category is already at its cap,
--        * the merit doesn't apply to this player's job (Group 1/2),
--        * the merit_id is invalid for this player.
--      We treat the return value as "did one rank go up?". If false on
--      every ID in a single pass, we're done.
--   3. After a successful pass, repeat - so each category gets +1 rank
--      per pass, then we cycle through again. This is the breadth-first
--      pacing the user picked.
--
-- USAGE
--   !automerits             -- spend the caller's merits
--   !automerits Mythraller  -- spend the named player's merits
--
-- The command lives in modules/custom/commands/ and rides the same
-- module-loader path as other custom commands (see modules/init.txt).
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,  -- GM/admin only by default; lower to 0 if you want
                     -- players to invoke it on themselves.
    parameters = 's' -- single optional string arg = player name
}

local function err(player, msg)
    player:printToPlayer(msg)
    player:printToPlayer('!automerits <player>')
end

commandObj.onTrigger = function(player, target)
    -- Resolve target (defaults to caller).
    local targ
    if target and target ~= '' then
        targ = GetPlayerByName(target)
        if not targ then
            err(player, string.format('Unable to find player named "%s".', target))
            return
        end
    else
        targ = player
    end

    local before = targ:getMeritCount()
    if before == 0 then
        player:printToPlayer(string.format('%s has 0 unspent merits - nothing to do.', targ:getName()))
        return
    end

    -- Snapshot every merit ID once so we don't recompute the pairs() walk
    -- on every pass. Values are uint16 identifiers, not data.
    local meritIds = {}
    for _, id in pairs(xi.merit) do
        table.insert(meritIds, id)
    end

    -- Safety cap on iterations. Theoretical worst case is bounded by the
    -- balance (each successful raise consumes >= 1 point) but we add a
    -- hard cap to bullet-proof against any C++ change that could no-op
    -- without deducting (would otherwise infinite-loop here).
    local MAX_PASSES = 1000
    local pass       = 0
    local applied    = 0

    while pass < MAX_PASSES do
        pass = pass + 1
        local anyUpgrade = false

        for _, id in ipairs(meritIds) do
            if targ:raiseMerit(id) then
                applied    = applied + 1
                anyUpgrade = true
            end
        end

        if not anyUpgrade then break end
        -- Optimisation: stop early if the balance is empty. raiseMerit
        -- already checks afford, but we'd still walk the full list one
        -- last time for no reason.
        if targ:getMeritCount() == 0 then break end
    end

    local after = targ:getMeritCount()
    local spent = before - after

    player:printToPlayer(string.format(
        'Auto-spent %d merit(s) on %s across %d upgrade(s). Balance: %d -> %d.',
        spent, targ:getName(), applied, before, after))

    if targ ~= player then
        targ:printToPlayer(string.format(
            'A sage has auto-spent %d of your merits across %d upgrades. You now have %d unspent.',
            spent, applied, after))
    end

    if after > 0 then
        -- Common reasons: every reachable category is maxed, or remaining
        -- balance is below the cheapest available upgrade cost (some
        -- high-tier merits cost multiple points per rank).
        player:printToPlayer(string.format(
            '  %d unspent left - every reachable category is either maxed or unaffordable at the remaining cost.', after))
    end
end

return commandObj
