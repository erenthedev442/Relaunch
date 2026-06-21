-----------------------------------
-- func: automerits <player>
-- desc: Auto-spends all unspent merit points on whichever categories can
--       still be upgraded, distributing breadth-first so every category
--       grows evenly rather than one rank stack getting maxed first.
--
-- ALGORITHM (breadth-first cycling):
--   1. Snapshot the unspent merit balance.
--   2. Loop: for each merit ID in the GENERIC categories (HP/MP, Attributes,
--      Combat Skills, Magic Skills), call player:raiseMerit(id).
--      Job-specific merits (Group 1/2), Others, and Weaponskills are skipped
--      intentionally — those slots are limited and belong to the player's choice.
--      The engine (CMeritPoints::RaiseMerit) silently no-ops if:
--        * the player can't afford the next rank,
--        * the category is already at its cap.
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

    -- Collect only the four generic merit categories:
    --   HP_MP=0x0040  ATTRIBUTES=0x0080  COMBAT=0x00C0  MAGIC=0x0100
    -- The category is encoded in bits 6-15 of each merit ID (id & 0xFFC0).
    -- Skipped: OTHERS (0x0140), all job-specific groups 1+2 (0x0180+),
    -- and Weaponskills (0x0680) — those are limited/expensive player choices.
    -- EXCLUDE Max Merit (xi.merit.MAX_MERIT, sits in the HP_MP group): it raises
    -- the held-merit CAP, and this server's base cap is already 127 -- the FFXI
    -- client's signed-int8 ceiling. Buying it pushes the cap past 127, so the
    -- merit-point count then renders as a NEGATIVE/garbage number. Never auto-buy it.
    local meritIds = {}
    for _, id in pairs(xi.merit) do
        local cat = bit.band(id, 0xFFC0)
        if cat >= 0x0040 and cat <= 0x0100 and id ~= xi.merit.MAX_MERIT then
            table.insert(meritIds, id)
        end
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
