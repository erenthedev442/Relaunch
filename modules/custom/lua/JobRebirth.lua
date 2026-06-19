-----------------------------------
-- JobRebirth.lua
-- Job Rebirth: once a job is level 99 with its Job Points maxed, rebirth it --
-- the job's level resets to 1 and its Job Points are FULLY wiped (categories,
-- gifts, capacity, DB) via the C++ player:resetJobPoints() binding. In return
-- you bank Ascension Points into that job's Ascension pool, spent at the
-- Ascension Altar on the SAME category tree Ascension uses (prestige_catalog).
--
-- Each rebirth also stamps an escalating PER-JOB EXP penalty (a stacking
-- negative EXP_BONUS applied only while that job is active), so every cycle's
-- re-grind to 99 is harder than the last, up to expPenaltyCap.
--
-- Reuses the Ascension (Prestige) economy entirely: AP -> CharVar
-- Prestige_AP_<job>; categories + their apply (zone-in + job change) live in
-- Prestige_System.lua. This module adds ONLY the rebirth NPC/action and the
-- per-job exp penalty.
--
-- Zone: GM Home (zone 210)
-----------------------------------
require('modules/module_utils')
require('scripts/zones/GM_Home/Zone')
local cfg = require('modules/custom/lua/job_rebirth_catalog')

local m = Module:new('job_rebirth')

local S = xi.msg.channel.SYSTEM_3

local JOB_ABBR =
{
    [1]  = 'WAR', [2]  = 'MNK', [3]  = 'WHM', [4]  = 'BLM', [5]  = 'RDM', [6]  = 'THF',
    [7]  = 'PLD', [8]  = 'DRK', [9]  = 'BST', [10] = 'BRD', [11] = 'RNG', [12] = 'SAM',
    [13] = 'NIN', [14] = 'DRG', [15] = 'SMN', [16] = 'BLU', [17] = 'COR', [18] = 'PUP',
    [19] = 'DNC', [20] = 'SCH', [21] = 'GEO', [22] = 'RUN',
}
local function jobName(jobId)  return JOB_ABBR[jobId] or ('Job ' .. tostring(jobId)) end

local function countKey(jobId)  return 'Rebirth_Count_' .. jobId end
local function apKey(jobId)     return string.format('Prestige_AP_%d', jobId) end
local function apLifeKey(jobId) return string.format('Prestige_AP_Lifetime_%d', jobId) end
local function getCount(player, jobId) return player:getCharVar(countKey(jobId)) or 0 end

-- exp penalty % for a given rebirth count (capped)
local function expPenalty(count)
    if count <= 0 then
        return 0
    end
    return math.min(count * cfg.expPenaltyPerRebirth, cfg.expPenaltyCap)
end

-----------------------------------
-- PER-JOB EXP PENALTY (negative EXP_BONUS, active only on the reborn job).
-- Mirrors the Prestige per-job mod swap: track the applied job in a LocalVar,
-- swap on job change, force re-apply after a zone wipe. EXP_BONUS is read live
-- at exp-gain time (charutils.cpp), so no stat recompute is needed.
-- Invariant: a job's Rebirth_Count only changes while that job is live (rebirth
-- acts on the current main job), so reading it back at removal yields what was
-- added -- keeping addMod/delMod balanced.
-----------------------------------
local function applyExp(player, jobId)
    local pen = expPenalty(getCount(player, jobId))
    if pen > 0 then
        player:addMod(xi.mod.EXP_BONUS, -pen)
    end
end

local function removeExp(player, jobId)
    local pen = expPenalty(getCount(player, jobId))
    if pen > 0 then
        player:delMod(xi.mod.EXP_BONUS, -pen)
    end
end

local function refreshExpPenalty(player)
    local cur     = player:getMainJob()
    local applied = player:getLocalVar('RebirthExpJob')
    if applied == cur then
        return
    end
    if applied ~= 0 then
        removeExp(player, applied)
    end
    applyExp(player, cur)
    player:setLocalVar('RebirthExpJob', cur)
end

-----------------------------------
-- Eligibility: current main job's Job Points fully spent (implies level 99).
-----------------------------------
local function atRebirthCap(player, jobId)
    return cfg.maxRebirths ~= nil and getCount(player, jobId) >= cfg.maxRebirths
end

local function isEligible(player, jobId)
    if atRebirthCap(player, jobId) then
        return false
    end
    return player:getSpentJobPoints() >= cfg.jpRequired
end

-----------------------------------
-- The rebirth action.
-----------------------------------
local function doRebirth(player)
    local job = player:getMainJob()

    -- Strip this job's CURRENT exp penalty before bumping the count (reads the
    -- pre-rebirth count) so the new, larger penalty below isn't double-applied.
    removeExp(player, job)

    -- Full wipe: Job Points (categories/gifts/capacity/DB) cleared, level -> 1.
    player:resetJobPoints()
    player:setLevel(1)

    -- Stamp the rebirth (this escalates the job's exp penalty).
    local count = getCount(player, job) + 1
    player:setCharVar(countKey(job), count)

    -- Bank Ascension Points into this job's pool (spent at the Ascension Altar).
    player:setCharVar(apKey(job),     (player:getCharVar(apKey(job))     or 0) + cfg.apPerRebirth)
    player:setCharVar(apLifeKey(job), (player:getCharVar(apLifeKey(job)) or 0) + cfg.apPerRebirth)

    -- Apply the new, harder penalty immediately for this (still-active) job.
    applyExp(player, job)
    player:setLocalVar('RebirthExpJob', job)

    player:printToPlayer(string.format('%s has been REBORN -- back to level 1, Job Points wiped.', jobName(job)), S)
    player:printToPlayer(string.format('  +%d Ascension Points banked (spend at the Ascension Altar). Rebirths: %d.', cfg.apPerRebirth, count), S)
    if expPenalty(count) > 0 then
        player:printToPlayer(string.format('  Trial of Mastery: this job now earns %d%% less EXP. Earn your power again.', expPenalty(count)), S)
    end
end

-----------------------------------
-- Menu.
-----------------------------------
local function showMenu(player)
    local job     = player:getMainJob()
    local count   = getCount(player, job)
    local spent   = player:getSpentJobPoints()
    local options = {}

    if isEligible(player, job) then
        table.insert(options,
        {
            string.format('Rebirth %s  (lv1 + wipe JP, +%d AP)', jobName(job), cfg.apPerRebirth),
            function(p)
                local opts =
                {
                    {
                        'Yes - rebirth this job',
                        function(pp)
                            if not isEligible(pp, pp:getMainJob()) then
                                pp:printToPlayer('This job is no longer eligible, kupo.', S)
                                return
                            end
                            doRebirth(pp)
                        end,
                    },
                    { 'No', function(pp) showMenu(pp) end },
                }
                local title = string.format('Rebirth %s? This is permanent.', jobName(p:getMainJob()))
                p:timer(30, function(pp) pp:customMenu({ title = title, options = opts }) end)
            end,
        })
    end

    table.insert(options,
    {
        'How Rebirth works',
        function(p)
            p:printToPlayer('[ Rebirth ] Max a job (lv99 + Job Points maxed), then rebirth it:', S)
            p:printToPlayer(string.format('  level -> 1, Job Points WIPED, +%d Ascension Points (spend at the Altar).', cfg.apPerRebirth), S)
            p:printToPlayer(string.format('  Each rebirth stacks -%d%% EXP on THIS job (cap -%d%%) -- each grind is harder.', cfg.expPenaltyPerRebirth, cfg.expPenaltyCap), S)
            showMenu(p)
        end,
    })

    local title
    if isEligible(player, job) then
        title = string.format('%s READY to rebirth  (rebirths: %d)', jobName(job), count)
    else
        title = string.format('%s  JP %d/%d  (rebirths: %d)', jobName(job), spent, cfg.jpRequired, count)
    end

    player:timer(30, function(p) p:customMenu({ title = title, options = options }) end)
end

-----------------------------------
-- NPC at GM Home.
-----------------------------------
m:addOverride('xi.zones.GM_Home.Zone.onInitialize', function(zone)
    super(zone)

    local Rebirth = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'JobRebirth_Altar',
        packetName = string.format('%sJob Rebirth', xi.icon.STAR_LARGE),
        look       = 2401, -- GM Home NPC model (same family as the trainers); change freely
        x          = cfg.npcPos.x,
        y          = cfg.npcPos.y,
        z          = cfg.npcPos.z,
        rotation   = cfg.npcPos.rot,
        widescan   = 1,

        onTrigger = function(player, npc)
            player:printToPlayer('[ Job Rebirth ] Restart a maxed job at level 1 for permanent power, kupo.', S)
            showMenu(player)
        end,
    })
    utils.unused(Rebirth)
end)

-----------------------------------
-- Re-apply the per-job exp penalty. onGameIn fires on every zone-in (which
-- wipes in-memory mods); forcing RebirthExpJob=0 makes refreshExpPenalty re-add
-- for the current job. checkForGearSet fires on job change (and gear change).
-----------------------------------
m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    player:setLocalVar('RebirthExpJob', 0)
    super(player, firstLogin, zoning)
    refreshExpPenalty(player)
end)

m:addOverride('xi.gear_sets.checkForGearSet', function(player)
    super(player)
    refreshExpPenalty(player)
end)

return m
