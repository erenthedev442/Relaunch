-----------------------------------
-- daily_board.lua
--
-- Daily Board system. Gives players 3 objectives per calendar day
-- (UTC midnight reset). Objectives auto-rotate deterministically
-- so everyone sees the same 3 each day.
--
-- Architecture (snapshot-based, no event hooks):
--   * On first NPC visit of the day, baselines are snapped from
--     other systems' lifetime CharVars (Custom_NM_Kills, etc.).
--   * Progress = current value − baseline. Players complete objectives
--     by doing activities, then returning to claim the reward.
--   * Requires zero modifications to HuntingLeague or any other module.
--
-- CharVar layout per player:
--   DB_Day              Julian day (YYYYDDD) of last reset
--   DB_Kills_Base       snapshot of Custom_NM_Kills at day start
--   DB_Infamy_Base      snapshot of Infamy_Lifetime at day start
--   DB_S1_ObjIdx        pool index (1-based) of today's slot-1 objective
--   DB_S2_ObjIdx        pool index of slot-2
--   DB_S3_ObjIdx        pool index of slot-3
--   DB_S1_Done          1 if slot-1 reward claimed today, else 0
--   DB_S2_Done          1 if slot-2 reward claimed today, else 0
--   DB_S3_Done          1 if slot-3 reward claimed today, else 0
--   DB_AllCleared_Lifetime   count of days the player cleared all 3
-----------------------------------
require('modules/module_utils')
local catalog = require('modules/custom/lua/daily_board_catalog')
require(string.format('scripts/zones/%s/Zone', catalog.npcPos.zone))

local m = Module:new('daily_board')

local DAILY_HL_CAP = 750 -- max Hunt Marks the board pays per UTC day
local DAILY_RF_CAP = 750 -- max combined AF/Relic/Empy Marks per UTC day
local CV_HL_TODAY  = 'DB_HL_Today'
local CV_RF_TODAY  = 'DB_RF_Today'

-----------------------------------
-- Day helpers
-----------------------------------

-- Julian day number: YYYYDDD. Unique per UTC calendar day, fits a
-- CharVar int without overflow until year 9999.
local function currentDayId()
    return tonumber(os.date('!%Y%j'))
end

-----------------------------------
-- Objective rotation
-----------------------------------

-- Pick today's 3 objectives. Guarantees one per metric group
-- (kills / infamy / waves / augments) so the board has variety every day.
-- Selection within each group rotates deterministically by day number.
local function todaysObjectives()
    local pool = catalog.objectivePool
    local byMetric = {}
    for _, obj in ipairs(pool) do
        if not byMetric[obj.metric] then byMetric[obj.metric] = {} end
        table.insert(byMetric[obj.metric], obj)
    end

    local today       = currentDayId()
    local ALL_METRICS = catalog.activeMetrics or { 'kills', 'infamy', 'waves', 'augments' }

    -- Single active metric (XP-only board, 2026-07-10): the multi-metric ring
    -- below would resolve to the SAME objective in all 3 slots, so instead offer
    -- slotsPerDay DISTINCT tiered objectives from that one group, rotating the
    -- window by day. Requires >= slotsPerDay objectives in the group.
    if #ALL_METRICS == 1 then
        local group  = byMetric[ALL_METRICS[1]] or {}
        local n      = #group
        local result = {}
        if n == 0 then return result end
        for i = 1, catalog.slotsPerDay do
            table.insert(result, group[((today + i - 1) % n) + 1])
        end
        return result
    end

    -- Multi-metric rotating selection: pick slotsPerDay consecutive metrics from
    -- the ring, shifted by (today mod #metrics), one objective per metric.
    local dayMod     = today % #ALL_METRICS
    local metricOrder = {}
    for i = 1, catalog.slotsPerDay do
        table.insert(metricOrder, ALL_METRICS[((dayMod + i - 1) % #ALL_METRICS) + 1])
    end
    local result = {}
    for _, metric in ipairs(metricOrder) do
        local group = byMetric[metric] or {}
        if #group > 0 then
            local idx = (today % #group) + 1
            table.insert(result, group[idx])
        end
    end
    return result
end

-- Builds a lookup: pool index of each objective by its id.
local function objPoolIndex(obj)
    for i, o in ipairs(catalog.objectivePool) do
        if o.id == obj.id then return i end
    end
    return 0
end

-----------------------------------
-- CharVar helpers
-----------------------------------

local function cvSlot(slot, field)
    return string.format('DB_S%d_%s', slot, field)
end

local function getSlotObjIdx(player, slot)
    return player:getCharVar(cvSlot(slot, 'ObjIdx')) or 0
end

local function isSlotDone(player, slot)
    return (player:getCharVar(cvSlot(slot, 'Done')) or 0) == 1
end

-- metric -> its day-start baseline CharVar. Current value comes from
-- catalog.baselines[metric]; progress = current - baseline (clamped >= 0).
local BASE_CV =
{
    kills    = catalog.cvKillsBase,
    infamy   = catalog.cvInfamyBase,
    waves    = catalog.cvWavesBase,
    augments = catalog.cvAugmentsBase,
    xp       = catalog.cvXpBase,
}
local function getProgress(player, metric)
    local baseKey   = BASE_CV[metric]           or catalog.cvKillsBase
    local currentCv = catalog.baselines[metric] or catalog.baselines.kills
    local base    = player:getCharVar(baseKey)   or 0
    local current = player:getCharVar(currentCv) or 0
    return math.max(0, current - base)
end

-----------------------------------
-- Day reset
-----------------------------------

local function resetDay(player)
    local today = currentDayId()
    player:setCharVar(catalog.cvDay, today)

    -- Snap baselines
    player:setCharVar(catalog.cvKillsBase,
        player:getCharVar(catalog.baselines.kills)    or 0)
    player:setCharVar(catalog.cvInfamyBase,
        player:getCharVar(catalog.baselines.infamy)   or 0)
    player:setCharVar(catalog.cvWavesBase,
        player:getCharVar(catalog.baselines.waves)    or 0)
    player:setCharVar(catalog.cvAugmentsBase,
        player:getCharVar(catalog.baselines.augments) or 0)
    player:setCharVar(catalog.cvXpBase,
        player:getCharVar(catalog.baselines.xp) or 0)

    -- Reset daily HL cap counter
    player:setCharVar(CV_HL_TODAY, 0)
    player:setCharVar(CV_RF_TODAY, 0)

    -- Assign today's 3 objectives by pool index
    local objs = todaysObjectives()
    for slot, obj in ipairs(objs) do
        player:setCharVar(cvSlot(slot, 'ObjIdx'), objPoolIndex(obj))
        player:setCharVar(cvSlot(slot, 'Done'),   0)
    end
end

local function ensureDay(player)
    local today = currentDayId()
    if (player:getCharVar(catalog.cvDay) or 0) ~= today then
        resetDay(player)
    end
end

-----------------------------------
-- Currency payout helper
-----------------------------------

local function payCurrency(player, reward)
    local curr = catalog.currencies[reward.currency]
    if not curr then return end
    local amount = reward.amount
    if reward.currency == 'hl' then
        local earned = player:getCharVar(CV_HL_TODAY) or 0
        local remaining = math.max(0, DAILY_HL_CAP - earned)
        if remaining <= 0 then
            player:printToPlayer(
                string.format('[Daily Board] Daily limit reached (%d Hunt Marks). Come back tomorrow!', DAILY_HL_CAP),
                xi.msg.channel.SYSTEM_3)
            return
        end
        amount = math.min(amount, remaining)
        player:setCharVar(CV_HL_TODAY, earned + amount)
    elseif reward.currency == 'af' or reward.currency == 'relic' or reward.currency == 'empy' then
        local earned = player:getCharVar(CV_RF_TODAY) or 0
        local remaining = math.max(0, DAILY_RF_CAP - earned)
        if remaining <= 0 then
            player:printToPlayer(
                string.format('[Daily Board] Daily limit reached (%d Reforge Marks). Come back tomorrow!', DAILY_RF_CAP),
                xi.msg.channel.SYSTEM_3)
            return
        end
        amount = math.min(amount, remaining)
        player:setCharVar(CV_RF_TODAY, earned + amount)
    end
    local current = player:getCharVar(curr.cv) or 0
    player:setCharVar(curr.cv, current + amount)
    player:printToPlayer(
        string.format('[Daily Board] +%d %s awarded!', amount, curr.name),
        xi.msg.channel.SYSTEM_3)
end

-----------------------------------
-- NPC MENU - customMenu-based UI
-----------------------------------

local dbMenu = { title = '', options = {} }

local showDailyRoot
local showSlotDetail

showDailyRoot = function(player)
    ensureDay(player)
    local objs = todaysObjectives()
    local opts = {}

    for slot, obj in ipairs(objs) do
        local done     = isSlotDone(player, slot)
        local progress = getProgress(player, obj.metric)
        local pct      = math.min(progress, obj.target)

        local label
        if done then
            label = string.format('[Done] %s', obj.label:sub(1, 10))
        else
            label = string.format('%s  %d/%d', obj.label:sub(1, 10), pct, obj.target)
        end

        local slotCopy = slot
        local objCopy  = obj
        table.insert(opts, {
            label,
            function(p) showSlotDetail(p, slotCopy, objCopy) end,
        })
    end

    table.insert(opts, { 'Close', function(_) end })

    -- Count done for the title
    local doneCount = 0
    for slot = 1, catalog.slotsPerDay do
        if isSlotDone(player, slot) then doneCount = doneCount + 1 end
    end

    dbMenu.title   = string.format('Daily Board  %d/3', doneCount)
    dbMenu.options = opts
    local snapshot = { title = dbMenu.title, options = dbMenu.options }  -- shared table + deferred send
    player:timer(30, function(p) p:customMenu(snapshot) end)
end

showSlotDetail = function(player, slot, obj)
    local done     = isSlotDone(player, slot)
    local progress = getProgress(player, obj.metric)
    local pct      = math.min(progress, obj.target)

    -- Print description and progress to chat so players have full text
    -- (menu labels are capped at the 150-byte customMenu limit).
    player:printToPlayer(
        string.format('[Daily Board] %s: %s', obj.label, obj.description),
        xi.msg.channel.SYSTEM_3)
    player:printToPlayer(
        string.format('[Daily Board] Progress: %d / %d', pct, obj.target),
        xi.msg.channel.SYSTEM_3)

    local curr   = catalog.currencies[obj.reward.currency] or {}
    local opts   = {}

    if done then
        table.insert(opts, { 'Reward claimed!', function(p) showDailyRoot(p) end })
    elseif progress >= obj.target then
        -- Eligible to claim
        table.insert(opts, {
            string.format('Claim  [%d %s]', obj.reward.amount, curr.name or '?'),
            function(p)
                -- Double-check so rapid clicks can't double-claim
                if isSlotDone(p, slot) then showDailyRoot(p); return end
                p:setCharVar(cvSlot(slot, 'Done'), 1)
                payCurrency(p, obj.reward)

                -- Check all-cleared
                local allDone = true
                for s = 1, catalog.slotsPerDay do
                    if not isSlotDone(p, s) then allDone = false; break end
                end
                if allDone then
                    local r = catalog.allClearedReward
                    if r.rewards then
                        for _, reward in ipairs(r.rewards) do
                            payCurrency(p, reward)
                        end
                    else
                        payCurrency(p, r)
                    end
                    local lifetime = (p:getCharVar(r.titleCv) or 0) + 1
                    p:setCharVar(r.titleCv, lifetime)
                    p:printToPlayer(
                        '[Daily Board] ALL 3 CLEARED! Full sweep bonus awarded! (streak #' .. lifetime .. ')',
                        xi.msg.channel.SYSTEM_3)
                end

                showDailyRoot(p)
            end,
        })
    else
        -- Not yet complete
        local needed = obj.target - progress
        table.insert(opts, {
            string.format('Need %d more', needed),
            function(p) showDailyRoot(p) end,
        })
    end

    table.insert(opts, { '<< Back', function(p) showDailyRoot(p) end })

    dbMenu.title   = obj.label:sub(1, 22)
    dbMenu.options = opts
    local snapshot = { title = dbMenu.title, options = dbMenu.options }  -- shared table + deferred send
    player:timer(30, function(p) p:customMenu(snapshot) end)
end

-----------------------------------
-- NPC placement
-----------------------------------

m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', catalog.npcPos.zone), function(zone)
    super(zone)

    local DailyBoard = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Daily_Board',
        packetName = string.format('%sDaily Board', xi.icon.STAR_LARGE),
        look       = 2883,      -- Moogle model (same family as Hunt Board / Weekly Board)
        x          = catalog.npcPos.x,
        y          = catalog.npcPos.y,
        z          = catalog.npcPos.z,
        rotation   = catalog.npcPos.rotation,
        widescan   = 1,
        onTrigger  = function(player, npc)
            player:printToPlayer(
                '[ Daily Board ] Fresh objectives await - come back after each task to claim your reward, kupo!',
                xi.msg.channel.SYSTEM_3)
            showDailyRoot(player)
        end,
    })
    utils.unused(DailyBoard)
end)

return m
