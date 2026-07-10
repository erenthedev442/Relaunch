-----------------------------------
-- legacy_freejob_grant.lua   (RELAUNCH)
--
-- Grants the "Free Job to 99" Legacy migration reward. On the portal reward page
-- the player claims this and picks a job; the claim writes charVar
-- Legacy_FreeJob99 = <jobId 1-22> on the OFFLINE character. On that character's
-- next REAL login this hook unlocks the job, switches to it, and raises it to
-- level 99, then clears the flag.
--
-- Deferred to login (not applied offline) because job/level changes must run on
-- the live CCharEntity: setLevel() targets the CURRENT main job, so we changeJob
-- to the chosen job first, then setLevel(99). Mirrors legacy_ring_grant.lua.
--
-- CharVar:
--   Legacy_FreeJob99 - jobId 1-22 owed (set by the portal claim); cleared to 0
--                      once applied. 0/unset = nothing owed.
-----------------------------------
require('modules/module_utils')

local m = Module:new('legacy_freejob_grant')

local CV_JOB = 'Legacy_FreeJob99'

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    -- gameLogin == 1 marks a REAL login (not a zone-in, which misfires on
    -- `not zoning`). Capture before super() clears it. Mirrors legacy_ring_grant.
    local isLogin = player:getLocalVar('gameLogin') == 1

    super(player, firstLogin, zoning)

    if not isLogin then
        return
    end

    local job = player:getCharVar(CV_JOB)
    if job < 1 or job > 22 then
        return  -- 0/unset or invalid
    end

    -- Defer to after login settles (same 3.5s window the ring grant uses), then
    -- apply on the fully-loaded character. Re-read the flag inside the timer so a
    -- double-fire can't double-apply.
    player:timer(3500, function(p)
        local j = p:getCharVar(CV_JOB)
        if j < 1 or j > 22 then
            return
        end

        p:unlockJob(j)                 -- ensure the chosen job is available
        if p:getMainJob() ~= j then
            p:changeJob(j)             -- setLevel() only affects the CURRENT job
        end
        p:setLevel(99)                 -- raise the chosen job to 99
        p:setCharVar(CV_JOB, 0)        -- applied -> clear so it never re-runs

        p:timer(500, function(pp)
            pp:printToPlayer('[Legacy] Your chosen job has been raised to 99. Carry your Legendary legacy forward, veteran.',
                xi.msg.channel.SYSTEM_3)
        end)
    end)
end)

return m
