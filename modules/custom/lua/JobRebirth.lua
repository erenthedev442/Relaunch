-----------------------------------
-- JobRebirth.lua
-- Job Rebirth -- a STANDALONE prestige system (NOT tied to Ascension).
--
-- Once a job is level 99 with its Job Points maxed, the Rebirth NPC at GM Home
-- resets that job to level 1 and FULLY wipes its Job Points (via the C++
-- player:resetJobPoints() binding). In return you earn REBIRTH POINTS -- this
-- system's own currency -- which you spend at the same NPC on permanent stat
-- boosts.
--
-- INDEPENDENCE: own currency (CharVar Rebirth_RP_<job>), own per-job boost
-- levels (Rebirth_Cat_<job>_<id>), own caps, own apply, own NPC. No Ascension
-- Points, no Altar, no Prestige storage -- the two systems are fully separate
-- and STACK. The ONLY thing borrowed from Ascension is the boost CATEGORY LIST
-- (prestige_catalog.categories) so both offer the same stats (single source of
-- truth -> they never drift); everything about HOW they're earned, stored,
-- capped, and applied is this module's own.
--
-- Boosts are PER-JOB (active only on the reborn job) and re-applied on zone-in
-- and job change. Each rebirth also stamps an escalating per-job EXP penalty
-- (a stacking negative EXP_BONUS) so every re-grind to 99 is harder.
--
-- Tunables: job_rebirth_catalog.lua. Zone: GM Home (zone 210).
-----------------------------------
require('modules/module_utils')
require('scripts/zones/RuLude_Gardens/Zone')
local cfg = require('modules/custom/lua/job_rebirth_catalog')
-- Same boost categories Ascension offers (the LIST only -- this system stores,
-- caps, and applies them independently). Each entry:
--   { id, label, mod (or mods), perLevel, cap, apCost, note }
local categories = require('modules/custom/lua/prestige_catalog').categories

local m = Module:new('job_rebirth')
local S = xi.msg.channel.SYSTEM_3

local JOB_ABBR =
{
    [1]  = 'WAR', [2]  = 'MNK', [3]  = 'WHM', [4]  = 'BLM', [5]  = 'RDM', [6]  = 'THF',
    [7]  = 'PLD', [8]  = 'DRK', [9]  = 'BST', [10] = 'BRD', [11] = 'RNG', [12] = 'SAM',
    [13] = 'NIN', [14] = 'DRG', [15] = 'SMN', [16] = 'BLU', [17] = 'COR', [18] = 'PUP',
    [19] = 'DNC', [20] = 'SCH', [21] = 'GEO', [22] = 'RUN',
}
local function jobName(jobId) return JOB_ABBR[jobId] or ('Job ' .. tostring(jobId)) end

-- Storage keys (all rebirth-owned; per main-job).
local function countKey(jobId)   return 'Rebirth_Count_' .. jobId end
local function rpKey(jobId)      return 'Rebirth_RP_' .. jobId end
local function catKey(jobId, id) return string.format('Rebirth_Cat_%d_%s', jobId, id) end

local function getCount(player, jobId)  return player:getCharVar(countKey(jobId)) or 0 end
local function getRP(player, jobId)     return player:getCharVar(rpKey(jobId)) or 0 end
local function getCatLv(player, jobId, id) return player:getCharVar(catKey(jobId, id)) or 0 end

-- exp penalty % for a given rebirth count.
-- Triangular scaling: each new rebirth adds count*rate more than the last,
-- so the penalty accelerates and eventually overwhelms any EXP augment stack.
-- Formula: count*(count+1)/2 * expPenaltyPerRebirth
-- e.g. rate=10 -> R1=10%, R2=30%, R3=60%, R4=100%, R5=150% ...
local function expPenalty(count)
    if count <= 0 then
        return 0
    end
    local pen = count * (count + 1) / 2 * cfg.expPenaltyPerRebirth
    return cfg.expPenaltyCap and math.min(pen, cfg.expPenaltyCap) or pen
end

-- RP granted for the Nth rebirth (1-indexed). Scales +rpPerLevel each time, capped at rpMax.
local function rpForCount(count)
    return math.min(cfg.rpBase + (count - 1) * cfg.rpPerLevel, cfg.rpMax)
end

-----------------------------------
-- PER-JOB MODS: bought category boosts + the escalating exp penalty, applied
-- only while the reborn job is active. A category may carry a single mod or a
-- list (cat.mods); both get the same delta. EXP_BONUS is read live at exp-gain
-- time, so only the category boosts need a stat recompute.
--
-- Invariant: per-job CharVars (cat levels, rebirth count) only change while
-- that job is live, so a later remove reads back exactly what was added --
-- keeping addMod/delMod balanced across job swaps.
-----------------------------------
local function _modAdd(player, cat, delta)
    if cat.mods then
        for _, mod in ipairs(cat.mods) do
            player:addMod(mod, delta)
        end
    elseif cat.mod then
        player:addMod(cat.mod, delta)
    end
end

local function _modDel(player, cat, delta)
    if cat.mods then
        for _, mod in ipairs(cat.mods) do
            player:delMod(mod, delta)
        end
    elseif cat.mod then
        player:delMod(cat.mod, delta)
    end
end

local function applyJobMods(player, jobId)
    for _, cat in ipairs(categories) do
        local lv = getCatLv(player, jobId, cat.id)
        if lv > 0 then
            _modAdd(player, cat, lv * cat.perLevel)
        end
    end
    local pen = expPenalty(getCount(player, jobId))
    if pen > 0 then
        player:addMod(xi.mod.EXP_BONUS, -pen)
    end
end

local function removeJobMods(player, jobId)
    for _, cat in ipairs(categories) do
        local lv = getCatLv(player, jobId, cat.id)
        if lv > 0 then
            _modDel(player, cat, lv * cat.perLevel)
        end
    end
    local pen = expPenalty(getCount(player, jobId))
    if pen > 0 then
        player:delMod(xi.mod.EXP_BONUS, -pen)
    end
end

-- Make the live mods match the current main job. Cheap no-op when unchanged
-- (the common case on gear-change calls), a swap when the job actually moved.
local function refreshJobMods(player)
    local cur     = player:getMainJob()
    local applied = player:getLocalVar('RebirthModJob')
    if applied == cur then
        return
    end
    if applied ~= 0 then
        removeJobMods(player, applied)
    end
    applyJobMods(player, cur)
    player:setLocalVar('RebirthModJob', cur)
    player:recalculateStats() -- rebuild cached Max HP/MP etc. from the new mod map
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

    -- Strip this job's live mods (categories + current exp penalty) so the
    -- penalty can be re-stamped at the new, higher rebirth count without
    -- double-counting. Categories are unchanged by a rebirth and are re-applied
    -- as-is below; only the penalty actually changes.
    removeJobMods(player, job)

    -- Full wipe: Job Points cleared (C++ resetJobPoints), level -> 1.
    player:resetJobPoints()
    player:setLevel(1)

    -- Stamp the rebirth and grant Rebirth Points (this system's own currency).
    local count    = getCount(player, job) + 1
    local rpEarned = rpForCount(count)
    player:setCharVar(countKey(job), count)
    player:setCharVar(rpKey(job), getRP(player, job) + rpEarned)

    -- Re-apply categories + the new (harder) exp penalty for this live job.
    applyJobMods(player, job)
    player:setLocalVar('RebirthModJob', job)
    player:recalculateStats()

    player:printToPlayer(string.format('%s has been REBORN -- level 1, Job Points wiped.', jobName(job)), S)
    player:printToPlayer(string.format('  +%d Rebirth Points earned (spend them here). Rebirths: %d.', rpEarned, count), S)
    local pen = expPenalty(count)
    if pen > 0 then
        if pen >= 100 then
            player:printToPlayer(string.format('  Trial of Mastery: EXP penalty -%d%% (floor -- grind counts, augs or not). Earn it back.', pen), S)
        else
            player:printToPlayer(string.format('  Trial of Mastery: this job now earns %d%% less EXP. Earn your power again.', pen), S)
        end
    end
end

-----------------------------------
-- Spend one level in a category (current main job). The job's mods are live
-- (RebirthModJob == job from login/zone/job-change), so apply just the new
-- level's delta and recompute derived stats.
-----------------------------------
local function tryBuy(player, cat)
    local job = player:getMainJob()
    local lv  = getCatLv(player, job, cat.id)
    if lv >= cat.cap then
        player:printToPlayer(string.format('%s is already maxed (%d/%d), kupo.', cat.label, lv, cat.cap), S)
        return
    end
    local rp = getRP(player, job)
    if rp < cat.apCost then
        player:printToPlayer(string.format('Not enough Rebirth Points: %s costs %d, you have %d.', cat.label, cat.apCost, rp), S)
        return
    end

    player:setCharVar(rpKey(job), rp - cat.apCost)
    player:setCharVar(catKey(job, cat.id), lv + 1)
    _modAdd(player, cat, cat.perLevel)
    player:recalculateStats()

    player:printToPlayer(string.format('%s: %d -> %d / %d   (-%d RP, %d left).', cat.label, lv, lv + 1, cat.cap, cat.apCost, rp - cat.apCost), S)
end

-----------------------------------
-- Menus (forward-declared for mutual recursion).
-----------------------------------
local showMenu, showSpend, showBuy

local PER_PAGE = 5 -- categories per page (5 + up to 3 nav = within the 8-option client cap)

showBuy = function(player, cat, page)
    local job = player:getMainJob()
    local lv  = getCatLv(player, job, cat.id)
    local rp  = getRP(player, job)

    player:printToPlayer(string.format('%s -- %s', cat.label, cat.note or ''), S)
    player:printToPlayer(string.format('  Now %d/%d   --   %d RP per level   --   you have %d RP.', lv, cat.cap, cat.apCost, rp), S)

    local options = {}
    if lv >= cat.cap then
        table.insert(options, { 'Maxed', function(p) showSpend(p, page) end })
    elseif rp < cat.apCost then
        table.insert(options, { 'Not enough RP', function(p) showSpend(p, page) end })
    else
        table.insert(options, {
            string.format('Buy +1  (-%d RP)', cat.apCost),
            function(p)
                tryBuy(p, cat)
                showBuy(p, cat, page) -- stay here so multiple levels can be bought
            end,
        })
    end
    table.insert(options, { 'Back', function(p) showSpend(p, page) end })

    local title = string.format('%s  %d/%d', cat.label, lv, cat.cap)
    player:timer(30, function(p) p:customMenu({ title = title, options = options }) end)
end

showSpend = function(player, page)
    page = page or 1
    local job   = player:getMainJob()
    local rp    = getRP(player, job)
    local total = #categories
    local pages = math.max(1, math.ceil(total / PER_PAGE))
    if page < 1 then page = 1 end
    if page > pages then page = pages end

    local first = (page - 1) * PER_PAGE + 1
    local last  = math.min(first + PER_PAGE - 1, total)

    local options = {}
    for i = first, last do
        local cat = categories[i]
        local lv  = getCatLv(player, job, cat.id)
        table.insert(options, {
            string.format('%s %d/%d', cat.label, lv, cat.cap),
            function(p) showBuy(p, cat, page) end,
        })
    end
    if page < pages then
        table.insert(options, { 'Next page >>', function(p) showSpend(p, page + 1) end })
    end
    if page > 1 then
        table.insert(options, { '<< Prev page', function(p) showSpend(p, page - 1) end })
    end
    table.insert(options, { 'Back', function(p) showMenu(p) end })

    local title = string.format('Spend RP: %d  (pg %d/%d)', rp, page, pages)
    player:timer(30, function(p) p:customMenu({ title = title, options = options }) end)
end

showMenu = function(player)
    local job     = player:getMainJob()
    local count   = getCount(player, job)
    local spent   = player:getSpentJobPoints()
    local rp      = getRP(player, job)
    local options = {}

    if isEligible(player, job) then
        table.insert(options, {
            string.format('Rebirth %s  (lv1, wipe JP, +%d RP)', jobName(job), rpForCount(count + 1)),
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

    table.insert(options, {
        string.format('Spend Rebirth Points  (%d RP)', rp),
        function(p) showSpend(p, 1) end,
    })

    table.insert(options, {
        'How Rebirth works',
        function(p)
            p:printToPlayer('[ Rebirth ] Max a job (lv99 + Job Points maxed), then rebirth it:', S)
            p:printToPlayer(string.format('  level -> 1, Job Points WIPED, +%d~%d Rebirth Points (starts at %d, +%d each rebirth, cap %d) to spend here.', cfg.rpBase, cfg.rpMax, cfg.rpBase, cfg.rpPerLevel, cfg.rpMax), S)
            p:printToPlayer(string.format('  EXP penalty scales each rebirth: R1=-%d%%, R2=-%d%%, R3=-%d%%, R4=-%d%% ... no ceiling.', expPenalty(1), expPenalty(2), expPenalty(3), expPenalty(4)), S)
            showMenu(p)
        end,
    })

    local title
    if isEligible(player, job) then
        title = string.format('%s READY to rebirth (rebirths: %d)', jobName(job), count)
    else
        title = string.format('%s  JP %d/%d  (rebirths: %d)', jobName(job), spent, cfg.jpRequired, count)
    end
    player:timer(30, function(p) p:customMenu({ title = title, options = options }) end)
end

-----------------------------------
-- NPC hidden underground in RuLude Gardens (zone 243).
-- Accessible only via the !rebirth GM command (warps to cfg.npcPos).
-----------------------------------
m:addOverride('xi.zones.RuLude_Gardens.Zone.onInitialize', function(zone)
    super(zone)

    local Rebirth = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'JobRebirth_Altar',
        packetName = string.format('%sJob Rebirth', xi.icon.STAR_LARGE),
        look       = 2401,
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
-- Re-apply the per-job mods. onGameIn fires on every zone-in (which wipes
-- in-memory mods); forcing RebirthModJob=0 makes refreshJobMods re-add for the
-- current job. checkForGearSet fires on job change (and gear change).
-----------------------------------
m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    -- DEFER the re-apply ~3s. Applying addMods at the bare onGameIn moment gets
    -- clobbered by the engine's post-login stat finalization (the same reason
    -- RealLevel_Tracker and auto_buff_henge defer). Symptom when synchronous:
    -- Ascension/Rebirth boosts silently vanish after a zone (e.g. enspell goes
    -- to ~gear-only). The login/zone already wiped the old mods, so a clean
    -- force-reapply here is correct -- never a double (the bug was MISSING mods).
    player:timer(3000, function(p)
        p:setLocalVar('RebirthModJob', 0)
        refreshJobMods(p)
    end)
end)

m:addOverride('xi.gear_sets.checkForGearSet', function(player)
    super(player)
    refreshJobMods(player)
end)

return m
