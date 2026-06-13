-----------------------------------
-- Auto-unlock the two Seekers of Adoulin advanced jobs -- Rune Fencer (RUN)
-- and Geomancer (GEO) -- for every player, so they appear in the Mog House
-- "Change Jobs" menu with no unlock quest and no GM command.
--
-- Mechanism: jobs are gated by the char_jobs.unlocked bitmask. A character
-- starts with only the 6 base jobs; every advanced job (RUN/GEO included)
-- must be unlocked before the Moogle lists it. unlockJob() sets the bit,
-- seeds the job at Lv1, persists to char_jobs, and pushes a JOB_INFO packet
-- so the menu refreshes live.
--
-- Coverage: the onGameIn hook fires for every login, so existing characters
-- are unlocked on their next login and new characters on first login. The
-- hasJob() guard makes it a one-time, idempotent action per character -- once
-- both are unlocked the hook returns early and never writes again.
--
-- NOTE: unlocking only makes GEO *selectable*. GEO only *works* once the
-- retail-Geomancer restore (restore_geo_retail.sql + the grades.cpp/
-- job_points.cpp reverts) is live on the box -- otherwise a player who picks
-- GEO gets 0 MP. Deploy that restore before (or with) enabling this.
-----------------------------------
require('modules/module_utils')
-----------------------------------
local m = Module:new('unlock_adoulin_jobs')

-- Jobs auto-granted to every player. Add more here if ever desired.
local autoUnlockJobs =
{
    xi.job.RUN,
    xi.job.GEO,
}

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)

    -- Cheap pre-check: if everything is already unlocked, do nothing further
    -- (no timer scheduled, no packets) for the rest of this character's life.
    local needsUnlock = false
    for _, jobId in ipairs(autoUnlockJobs) do
        if not player:hasJob(jobId) then
            needsUnlock = true
            break
        end
    end

    if not needsUnlock then
        return
    end

    -- Delay so the client has finished loading and will apply the JOB_INFO
    -- packet unlockJob() pushes, refreshing the Change Jobs menu this session.
    player:timer(2000, function(playerArg)
        for _, jobId in ipairs(autoUnlockJobs) do
            if not playerArg:hasJob(jobId) then
                playerArg:unlockJob(jobId)
            end
        end
    end)
end)

return m
