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
-- and job change. Each rebirth also stamps an escalating per-job EXP penalty --
-- a MULTIPLICATIVE cut (the [RebirthExpCut] charVar the engine applies after
-- gear/augment EXP_BONUS) so every re-grind to 99 is harder and augments can't
-- buy past it.
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

-- Multiplicative EXP cut % for a given rebirth count. Mirrors the RP award curve:
-- same rpPower exponent and same rpMilestoneEvery trigger so penalty and reward
-- always accelerate in lock-step. Hard-capped at expPenaltyHardCap (engine floors
-- EXP at 5% of base regardless, so 90% cap still lets the player level).
local function expPenalty(count)
    if count <= 0 then return 0 end
    local power = cfg.expPenaltyPower or cfg.rpPower
    local base  = math.floor(cfg.expPenaltyMin + cfg.expPenaltyScale * (count ^ power - 1))
    local bonus = (count % cfg.rpMilestoneEvery == 0) and cfg.expPenaltyMilestoneExtra or 0
    return math.min(base + bonus, cfg.expPenaltyHardCap)
end

-- RP granted for the Nth rebirth (1-indexed). Accelerating curve + milestone bonus.
-- floor(rpMin + rpScale * (count^rpPower - 1)) + rpMilestoneBonus every rpMilestoneEvery.
local function rpForCount(count)
    local base  = math.floor(cfg.rpMin + cfg.rpScale * (count ^ cfg.rpPower - 1))
    local bonus = (count % cfg.rpMilestoneEvery == 0) and cfg.rpMilestoneBonus or 0
    return base + bonus
end

local function cumulativeRP(count)
    local total = 0
    local cappedCount = cfg.maxRebirths and math.min(count, cfg.maxRebirths) or count
    for rebirth = 1, cappedCount do
        total = total + rpForCount(rebirth)
    end
    return total
end

local function categoryCost(cat, nextLevel)
    if cat.totalCost then
        return math.floor(cat.totalCost * nextLevel / cat.cap) -
            math.floor(cat.totalCost * (nextLevel - 1) / cat.cap)
    end

    return cat.apCost or 1
end

local BATCH_SIZES = { 5, 10, 25, 50 }

local function totalCostForLevels(cat, lv, count)
    local total = 0
    for i = 1, count do
        total = total + categoryCost(cat, lv + i)
    end
    return total
end

local function maxBuyable(cat, lv, budget)
    local n     = 0
    local spent = 0
    while lv + n < cat.cap do
        local c = categoryCost(cat, lv + n + 1)
        if spent + c > budget then
            break
        end
        spent = spent + c
        n     = n + 1
    end
    return n, spent
end

local function categorySpent(cat, level)
    if cat.totalCost then
        return math.floor(cat.totalCost * level / cat.cap)
    end

    return level * (cat.apCost or 1)
end

-- Reward-curve v2 migration: the old accelerating curve granted enough RP to
-- finish the entire stat map around R36. Reset allocations once and refund the
-- correctly retuned lifetime total for each job so existing players can respec
-- fairly across the deliberate R1-R50 progression.
local function migrateRewardCurveV2(player)
    if (player:getCharVar('Rebirth_RewardCurveV2') or 0) == 1 then
        return false
    end

    local hadProgress = false
    for jobId = 1, 22 do
        local count = getCount(player, jobId)
        if count > 0 or getRP(player, jobId) > 0 then
            hadProgress = true
        end

        for _, cat in ipairs(categories) do
            player:setCharVar(catKey(jobId, cat.id), 0)
        end

        player:setCharVar(rpKey(jobId), cumulativeRP(count))
    end

    player:setCharVar('Rebirth_RewardCurveV2', 1)
    return hadProgress
end

-- Preserve the RP invested under the former caps. Partial allocations are
-- converted to the highest affordable new level and any remainder is refunded.
local function migrateReducedCaps(player)
    if (player:getCharVar('Rebirth_StatCapsV3') or 0) == 1 then
        return 0
    end

    local refunded = 0
    for jobId = 1, 22 do
        local jobRefund = 0
        for _, cat in ipairs(categories) do
            if cat.legacyCap and cat.legacyCost then
                local oldLevel = math.min(getCatLv(player, jobId, cat.id), cat.legacyCap)
                local oldSpent = oldLevel * cat.legacyCost
                local newLevel = 0

                while newLevel < cat.cap and categorySpent(cat, newLevel + 1) <= oldSpent do
                    newLevel = newLevel + 1
                end

                player:setCharVar(catKey(jobId, cat.id), newLevel)
                jobRefund = jobRefund + oldSpent - categorySpent(cat, newLevel)
            end
        end

        if jobRefund > 0 then
            player:setCharVar(rpKey(jobId), getRP(player, jobId) + jobRefund)
            refunded = refunded + jobRefund
        end
    end

    player:setCharVar('Rebirth_StatCapsV3', 1)
    return refunded
end

local function isMilestone(count)
    return count % cfg.rpMilestoneEvery == 0
end

-----------------------------------
-- PER-JOB MODS: bought category boosts (real mods) + the escalating exp penalty
-- (the [RebirthExpCut] charVar, NOT a mod), applied only while the reborn job is
-- active. A category may carry a single mod or a list (cat.mods); both get the
-- same delta. The EXP cut is a charVar the engine reads live at exp-gain time, so
-- only the category boosts need a stat recompute.
--
-- Invariant: per-job CharVars (cat levels, rebirth count) only change while
-- that job is live, so a later remove reads back exactly what was added --
-- keeping addMod/delMod balanced across job swaps.
-----------------------------------
-- Overflow-proof additive grant (ported from Legendary e605736222): clamp a
-- mod's running TOTAL to +/-31000 so a raw addMod can never wrap the int16
-- mod store (m_modStat). SIGN-AWARE by construction: positive amounts clamp
-- toward +cap, negative amounts (Phys.DT-/Mag.DT-, perLevel -100) toward
-- -cap. NOTE: Legendary's first version floored adds at 0 and silently
-- discarded negative grants -- do not reintroduce a positive-only clamp.
local function safeClampAdd(cur, amount, cap)
    if amount >= 0 then
        return math.max(0, math.min(amount, cap - cur))   -- never push above +cap
    end
    return math.min(0, math.max(amount, -cap - cur))      -- never push below -cap
end

local function safeAddMod(entity, modId, amount, cap)
    cap = cap or 31000
    local add = safeClampAdd(entity:getMod(modId), amount, cap)
    if add ~= 0 then entity:addMod(modId, add) end
end

-- Clamp removal to this system's own contribution, sign-aware: never strip
-- past 0 in either direction (a strip of a negative grant must not ADD).
local function _delClamp(cur, delta)
    if delta >= 0 then
        return math.min(delta, math.max(0, cur))
    end
    return math.max(delta, math.min(0, cur))
end

local function _modAdd(player, cat, delta)
    if cat.mods then
        for _, mod in ipairs(cat.mods) do
            safeAddMod(player, mod, delta)
        end
    elseif cat.mod then
        safeAddMod(player, cat.mod, delta)
    end
end

local function _modDel(player, cat, delta)
    if cat.mods then
        for _, mod in ipairs(cat.mods) do
            player:delMod(mod, _delClamp(player:getMod(mod), delta))
        end
    elseif cat.mod then
        player:delMod(cat.mod, _delClamp(player:getMod(cat.mod), delta))
    end
end

local function applyJobMods(player, jobId)
    for _, cat in ipairs(categories) do
        local lv = math.min(getCatLv(player, jobId, cat.id), cat.cap)
        if lv > 0 then
            _modAdd(player, cat, lv * cat.perLevel)
        end
    end
    -- Multiplicative EXP cut for THIS job's rebirth count. The engine (AddExpBonus)
    -- reads this charVar and applies it AFTER gear/augment EXP_BONUS, so augments
    -- can't cancel it. Not a mod -> no recalculateStats needed for the cut itself.
    player:setCharVar('[RebirthExpCut]', expPenalty(getCount(player, jobId)))
end

local function removeJobMods(player, jobId)
    for _, cat in ipairs(categories) do
        local lv = math.min(getCatLv(player, jobId, cat.id), cat.cap)
        if lv > 0 then
            _modDel(player, cat, lv * cat.perLevel)
        end
    end
    -- Clear the EXP cut; the new main job's applyJobMods re-stamps its own.
    player:setCharVar('[RebirthExpCut]', 0)
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
    if xi._paragon_applyPerks then
        xi._paragon_applyPerks(player)
    end

    player:printToPlayer(string.format('%s has been REBORN -- level 1, Job Points wiped.', jobName(job)), S)
    player:printToPlayer(string.format('  +%d Rebirth Points earned (spend them here). Rebirths: %d.', rpEarned, count), S)
    if isMilestone(count) then
        player:printToPlayer(string.format('  *** Milestone R%d! +%d bonus RP included above. Keep climbing.', count, cfg.rpMilestoneBonus), S)
    end
    local pen = expPenalty(count)
    if pen > 0 then
        player:printToPlayer(string.format('  Trial of Mastery: EXP cut %d%% -- a TRUE cut taken after gear/augments (hard cap %d%%). Earn your power again.', pen, cfg.expPenaltyHardCap), S)
    end
end

-----------------------------------
-- Spend one level in a category (current main job). The job's mods are live
-- (RebirthModJob == job from login/zone/job-change), so apply just the new
-- level's delta and recompute derived stats.
-----------------------------------
local function tryBuy(player, cat, count)
    count = count or 1
    local job = player:getMainJob()
    local lv  = getCatLv(player, job, cat.id)
    if lv >= cat.cap then
        player:printToPlayer(string.format('%s is already maxed (%d/%d), kupo.', cat.label, lv, cat.cap), S)
        return false
    end

    local remaining = cat.cap - lv
    count = math.min(count, remaining)
    if count <= 0 then
        return false
    end

    local totalCost = totalCostForLevels(cat, lv, count)
    local rp = getRP(player, job)
    if rp < totalCost then
        player:printToPlayer(string.format(
            'Not enough Rebirth Points: %d levels of %s costs %d, you have %d.',
            count, cat.label, totalCost, rp), S)
        return false
    end

    player:setCharVar(rpKey(job), rp - totalCost)
    player:setCharVar(catKey(job, cat.id), lv + count)
    _modAdd(player, cat, cat.perLevel * count)
    player:recalculateStats()

    player:printToPlayer(string.format(
        '%s: %d -> %d / %d   (-%d RP, %d left).',
        cat.label, lv, lv + count, cat.cap, totalCost, rp - totalCost), S)
    return true
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
    local cost = lv < cat.cap and categoryCost(cat, lv + 1) or 0
    local maxN, maxCost = maxBuyable(cat, lv, rp)

    player:printToPlayer(string.format('%s -- %s', cat.label, cat.note or ''), S)
    player:printToPlayer(string.format(
        '  Now %d/%d   --   next level %d RP   --   you have %d RP.',
        lv, cat.cap, cost, rp), S)

    local options = {}
    if lv >= cat.cap then
        table.insert(options, { 'Maxed', function(p) showSpend(p, page) end })
    elseif rp < cost then
        table.insert(options, { 'Not enough RP', function(p) showSpend(p, page) end })
    else
        table.insert(options, {
            string.format('Buy +1  (-%d RP)', cost),
            function(p)
                tryBuy(p, cat, 1)
                showBuy(p, cat, page)
            end,
        })

        for _, qty in ipairs(BATCH_SIZES) do
            if qty <= maxN then
                local batchCost = totalCostForLevels(cat, lv, qty)
                table.insert(options, {
                    string.format('Buy +%d  (-%d RP)', qty, batchCost),
                    function(p)
                        tryBuy(p, cat, qty)
                        showBuy(p, cat, page)
                    end,
                })
            end
        end

        if maxN > 1 then
            table.insert(options, {
                string.format('Buy max (%d, -%d RP)', maxN, maxCost),
                function(p)
                    tryBuy(p, cat, maxN)
                    showBuy(p, cat, page)
                end,
            })
        end
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
            p:printToPlayer(string.format('  level -> 1, Job Points WIPED, Rebirth Points on an accelerating curve: R1=%d, R5=%d, R10=%d, R20=%d, R30=%d.', rpForCount(1), rpForCount(5), rpForCount(10), rpForCount(20), rpForCount(30)), S)
            p:printToPlayer(string.format('  Milestone bonus: +%d RP at R%d, R%d, R%d, ... (included in figures above).', cfg.rpMilestoneBonus, cfg.rpMilestoneEvery, cfg.rpMilestoneEvery * 2, cfg.rpMilestoneEvery * 3), S)
            p:printToPlayer(string.format('  EXP cut (after gear/augments, can\'t be cancelled): R1=-%d%%, R5=-%d%%, R10=-%d%%, R20=-%d%%, hard cap -%d%%.', expPenalty(1), expPenalty(5), expPenalty(10), expPenalty(20), cfg.expPenaltyHardCap), S)
            p:printToPlayer(string.format('  Milestone penalty: +%d%% extra at R%d, R%d, R%d, ... (same trigger as the RP bonus).', cfg.expPenaltyMilestoneExtra, cfg.rpMilestoneEvery, cfg.rpMilestoneEvery * 2, cfg.rpMilestoneEvery * 3), S)
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
-- Accessible through !warp > Activities > Progression Hubs.
-----------------------------------
m:addOverride('xi.zones.RuLude_Gardens.Zone.onInitialize', function(zone)
    super(zone)

    local Rebirth = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'JobRebirth_Altar',
        packetName = string.format('%sJob Rebirth', xi.icon.STAR_LARGE),
        look       = 69,
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
-- Re-apply the per-job mods once after zone-in stat finalization. Suppress the
-- synchronous gear-set hook while the deferred apply is pending; otherwise the
-- hook applies once and the timer's forced refresh applies every Rebirth stat a
-- second time.
-----------------------------------
m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    local migrated = migrateRewardCurveV2(player)
    local refunded = migrateReducedCaps(player)
    player:setLocalVar('RebirthApplyPending', 1)
    super(player, firstLogin, zoning)
    if migrated then
        player:printToPlayer(
            '[ Job Rebirth ] Stat allocations were reset and refunded for the new R1-R50 progression curve.',
            S)
    end
    if refunded > 0 then
        player:printToPlayer(string.format(
            '[ Job Rebirth ] Reduced stat caps applied; %d unspent RP refunded across your jobs.',
            refunded), S)
    end
    player:timer(3000, function(p)
        p:setLocalVar('RebirthApplyPending', 0)
        p:setLocalVar('RebirthModJob', 0)
        refreshJobMods(p)
    end)
end)

m:addOverride('xi.gear_sets.checkForGearSet', function(player)
    super(player)
    if player:getLocalVar('RebirthApplyPending') ~= 1 then
        refreshJobMods(player)
    end
end)

return m
