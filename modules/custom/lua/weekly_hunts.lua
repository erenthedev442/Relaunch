-----------------------------------
-- weekly_hunts.lua
--
-- Weekly Hunt Board system. Maintains a per-player set of 5 random
-- objectives that reset every Monday at 00:00 UTC. Objectives
-- auto-complete on the kill / event that pushes them to their target,
-- pay the reward in chat, and contribute to a "clear-all-5" meta-bonus.
--
-- Public API:
--   wh.fire(player, eventType, metadata)
--       Pushed by other modules (Reforge, HL, GameMaster, Augment Moogle,
--       hunters_guild) when relevant events happen. Walks active
--       objective slots, increments matching ones, auto-completes when
--       any slot hits target, and fires the all-cleared bonus when the
--       last slot completes.
--
-- CharVar layout per player:
--   WH_Week          - int YYYYWW; bumped on first interaction of new week
--   WH_S1_Idx..S5_Idx - int 1..#pool; objective index for that slot
--   WH_S1_Prog..      - int; current progress count
--   WH_S1_Done..      - int 0/1; reward already claimed
--   WH_AllCleared_Lifetime - int; count of weeks player has cleared all 5
-----------------------------------
require('modules/module_utils')
local catalog = require('modules/custom/lua/weekly_hunts_catalog')
require(string.format('scripts/zones/%s/Zone', catalog.npcPos.zone))

local m = Module:new('weekly_hunts')
local wh = {}

local SLOT_COUNT = catalog.slotsPerWeek

-----------------------------------
-- Week-ID helpers
-----------------------------------

-- ISO-week-based identifier. Uses %G (ISO week-year) and %V (ISO week
-- number) to avoid the week-00 edge case on Jan 1. Stored as an integer
-- (YYYYWW) so it fits naturally as a CharVar int.
-- e.g. 202621 = 21st ISO week of 2026.
local function currentWeekId()
    return tonumber(os.date('!%G%V'))
end

-----------------------------------
-- Slot CharVar helpers (centralized to avoid stringly-typed bugs)
-----------------------------------

local function cvSlot(slot, field)
    return string.format('WH_S%d_%s', slot, field)
end

local function getSlotObjIdx(player, slot)
    return player:getCharVar(cvSlot(slot, 'Idx')) or 0
end

local function getSlotProgress(player, slot)
    return player:getCharVar(cvSlot(slot, 'Prog')) or 0
end

local function isSlotDone(player, slot)
    return (player:getCharVar(cvSlot(slot, 'Done')) or 0) == 1
end

local function setSlot(player, slot, objIdx, progress, done)
    player:setCharVar(cvSlot(slot, 'Idx'),  objIdx)
    player:setCharVar(cvSlot(slot, 'Prog'), progress)
    player:setCharVar(cvSlot(slot, 'Done'), done and 1 or 0)
end

-----------------------------------
-- Objective rolling
-----------------------------------

-- Pick `n` unique random indices from the pool. n is clamped to pool
-- size so smaller pools degrade gracefully (no infinite loop).
local function pickObjectives(n)
    local pool = catalog.objectivePool
    local size = #pool
    if n > size then n = size end
    local picked = {}
    local used = {}
    while #picked < n do
        local idx = math.random(size)
        if not used[idx] then
            used[idx] = true
            picked[#picked + 1] = idx
        end
    end
    return picked
end

local function rollNewWeek(player)
    -- P3: reset kill streak at the start of every new week
    player:setCharVar('WH_KillStreak', 0)

    local picks = pickObjectives(SLOT_COUNT)

    -- C6b: if the player is at max rank in ALL four Hunter's Guild guilds,
    -- replace any guild_rankup slot with a re-rolled objective so they
    -- don't waste a slot on an objective they can never complete.
    local hgCat = require('modules/custom/lua/hunters_guild_catalog')
    local allMax = true
    for _, gKey in ipairs(hgCat.guildOrder) do
        local g = hgCat.guilds[gKey]
        local rankCv = (g.rankCv or ('HG_' .. gKey .. '_Rank'))
        local playerRank = player:getCharVar(rankCv) or 0
        if playerRank < #hgCat.ranks then allMax = false; break end
    end
    if allMax then
        for i, idx in ipairs(picks) do
            if catalog.objectivePool[idx] and catalog.objectivePool[idx].id == 'guild_rankup' then
                local newIdx, tries = idx, 0
                while newIdx == idx and tries < 30 do
                    newIdx = math.random(#catalog.objectivePool)
                    tries = tries + 1
                end
                picks[i] = newIdx
            end
        end
    end

    for slot = 1, SLOT_COUNT do
        setSlot(player, slot, picks[slot] or 0, 0, false)
        -- C6c: reset alternate-event progress for every slot
        player:setCharVar(cvSlot(slot, 'AltProg'), 0)
    end

    -- C6a: reset partial-sweep CharVars so they can fire again this week
    -- (they are week-gated, but clearing them on rollover is clean)
    -- (no action needed — they gate on weekId, so they auto-expire)

    player:setCharVar('WH_Week', currentWeekId())
end

-- Ensure the player's stored week matches the current week. If not,
-- roll a fresh objective set. Called lazily by every public API so
-- there's no need for a periodic server tick.
local function ensureCurrentWeek(player)
    local stored = player:getCharVar('WH_Week') or 0
    if stored ~= currentWeekId() then
        rollNewWeek(player)
        player:printToPlayer(
            '[Hunt Board] New week! 5 fresh objectives are available - talk to the Hunt Board NPC to view.',
            xi.msg.channel.SYSTEM_3)
    end
end

-----------------------------------
-- Reward payout
-----------------------------------

-- Credit a reward to the player's mark balance. The reward.currency
-- code maps to a CharVar via catalog.currencyCv. Unknown codes are
-- ignored with a warning (defensive - catalog typos shouldn't crash
-- a kill credit path).
local function payReward(player, reward)
    if not reward or not reward.currency or not reward.amount then return end
    local curr = catalog.currencyCv[reward.currency]
    if not curr then
        print(string.format('[weekly_hunts] unknown currency code: %s', tostring(reward.currency)))
        return
    end
    local prev = player:getCharVar(curr.cv) or 0
    player:setCharVar(curr.cv, prev + reward.amount)
    player:printToPlayer(
        string.format('[Hunt Board] Reward: +%d %s, kupo!',
            reward.amount, curr.label),
        xi.msg.channel.SYSTEM_3)
end

-- Returns true iff every slot is currently marked done.
local function allSlotsDone(player)
    for slot = 1, SLOT_COUNT do
        if not isSlotDone(player, slot) then return false end
    end
    return true
end

local function completeSlot(player, slot, obj)
    player:setCharVar(cvSlot(slot, 'Done'), 1)
    -- Cap progress at target so the menu doesn't display "37 / 25".
    player:setCharVar(cvSlot(slot, 'Prog'), obj.target)
    player:printToPlayer(
        string.format('[Hunt Board] Objective complete: %s!', obj.label),
        xi.msg.channel.SYSTEM_3)
    payReward(player, obj.reward)

    -- C6a: Partial sweep bonuses — 3/5 = +1000 HL, 4/5 = +2500 HL.
    -- Gated by week ID so they fire at most once per tier per week.
    local doneCount = 0
    for s = 1, SLOT_COUNT do
        if isSlotDone(player, s) then doneCount = doneCount + 1 end
    end
    local weekId = currentWeekId()
    local PARTIAL_REWARDS = {
        [3] = { currency = 'hl', amount = 1000 },
        [4] = { currency = 'hl', amount = 2500 },
    }
    local pr = PARTIAL_REWARDS[doneCount]
    if pr then
        local partialCv = string.format('WH_Partial_%d', doneCount)
        local lastWeekPaid = player:getCharVar(partialCv) or 0
        if lastWeekPaid ~= weekId then
            player:setCharVar(partialCv, weekId)
            payReward(player, pr)
            player:printToPlayer(
                string.format('[Hunt Board] %d/5 cleared — partial sweep bonus!', doneCount),
                xi.msg.channel.SYSTEM_3)
        end
    end

    -- Check for the all-cleared meta-bonus AFTER this slot is marked
    -- done. Fires once per week (the lifetime counter is monotonic, so
    -- subsequent fires for the same week would only happen if a slot
    -- got un-done, which can't happen via the public API).
    if allSlotsDone(player) then
        local meta = catalog.allClearedReward
        local prevCount = player:getCharVar(meta.titleCv) or 0
        player:setCharVar(meta.titleCv, prevCount + 1)
        player:printToPlayer(
            string.format('*** [Hunt Board] WEEKLY SWEEP! All %d objectives cleared! ***',
                SLOT_COUNT),
            xi.msg.channel.SYSTEM_3)
        payReward(player, { currency = meta.currency, amount = meta.amount })
        if prevCount == 0 then
            player:printToPlayer(
                '[Hunt Board] First Weekly Hunter clear, kupo! Title unlocked.',
                xi.msg.channel.SYSTEM_3)
        end
    end
end

-----------------------------------
-- Event dispatch (the public surface)
-----------------------------------

-- Fired by other modules when a relevant event happens. Walks active
-- objective slots and increments matching ones. Auto-completes slots
-- that hit their target.
--
-- eventType : string identifier ('nm_kill', 'guild_rankup', etc.)
-- metadata  : optional table with extra context the objective's
--             `matches` function may inspect (level, system, etc.)
function wh.fire(player, eventType, metadata)
    if player == nil then return end
    ensureCurrentWeek(player)

    -- Augment nm_kill metadata with the player's running kill streak so
    -- streak-based objectives ("Untouchable") can read it. Reset happens
    -- in the onPlayerDeath override below. The CharVar persists across
    -- zones / logouts, which is the right semantics - a streak only
    -- breaks on actual death, not on disconnect or reload.
    if eventType == 'nm_kill' then
        local streak = (player:getCharVar('WH_KillStreak') or 0) + 1
        player:setCharVar('WH_KillStreak', streak)
        metadata = metadata or {}
        metadata.killStreak = streak
    end

    for slot = 1, SLOT_COUNT do
        if not isSlotDone(player, slot) then
            local objIdx = getSlotObjIdx(player, slot)
            local obj    = catalog.objectivePool[objIdx]
            if obj and obj.eventType == eventType then
                local matched = true
                if obj.matches then
                    matched = obj.matches(metadata)
                end
                if matched then
                    -- progressFn lets objectives implement non-count
                    -- aggregation (max for streaks, etc.). Default is
                    -- simple increment for the common "kill N times"
                    -- pattern.
                    local current = getSlotProgress(player, slot)
                    local newProg
                    if obj.progressFn then
                        newProg = obj.progressFn(metadata, current)
                    else
                        newProg = current + 1
                    end
                    player:setCharVar(cvSlot(slot, 'Prog'), newProg)
                    if newProg >= obj.target then
                        completeSlot(player, slot, obj)
                    end
                end
            end
            -- C6c: alternate event type fallback (e.g. wave_clear accepting nm_kills)
            if obj and obj.alternateEventType and eventType == obj.alternateEventType and not isSlotDone(player, slot) then
                local altKey  = cvSlot(slot, 'AltProg')
                local altProg = (player:getCharVar(altKey) or 0) + 1
                player:setCharVar(altKey, altProg)
                if altProg >= (obj.alternateTarget or obj.target) then
                    completeSlot(player, slot, obj)
                end
            end
        end
    end
end

-- Death hook: zero the kill streak whenever a player dies. addOverride
-- composes with other modules' onPlayerDeath handlers (world_first
-- announcements etc.) so we play nice. CharVar reset is idempotent.
m:addOverride('xi.player.onPlayerDeath', function(player, ...)
    super(player, ...)
    if (player:getCharVar('WH_KillStreak') or 0) > 0 then
        player:setCharVar('WH_KillStreak', 0)
        player:printToPlayer(
            '[Hunt Board] Kill streak broken.',
            xi.msg.channel.SYSTEM_3)
    end
end)

-----------------------------------
-- Status reporting (used by NPC + !weekly command)
-----------------------------------

function wh.formatStatus(player)
    ensureCurrentWeek(player)
    local lines = {}
    lines[#lines + 1] = string.format('=== Weekly Hunt Board (Week %d) ===',
        player:getCharVar('WH_Week') or 0)
    local cleared = 0
    for slot = 1, SLOT_COUNT do
        local objIdx = getSlotObjIdx(player, slot)
        local obj    = catalog.objectivePool[objIdx]
        if not obj then
            lines[#lines + 1] = string.format('  %d. <empty>', slot)
        else
            local prog = getSlotProgress(player, slot)
            local done = isSlotDone(player, slot)
            if done then cleared = cleared + 1 end
            local marker = done and '[DONE]' or string.format('[%d / %d]', prog, obj.target)
            lines[#lines + 1] = string.format('  %d. %s %s - %s',
                slot, marker, obj.label, obj.description)
        end
    end
    local lifetimeCleared = player:getCharVar(catalog.allClearedReward.titleCv) or 0
    lines[#lines + 1] = string.format(
        '  All-cleared progress: %d / %d this week  .  Lifetime sweeps: %d',
        cleared, SLOT_COUNT, lifetimeCleared)
    return lines
end

-----------------------------------
-- NPC: Hunt Board at GM Home
-----------------------------------
local hbMenu = { title = 'Weekly Hunt Board', options = {} }

local function showBoardMenu(player)
    ensureCurrentWeek(player)
    local opts = {}
    for slot = 1, SLOT_COUNT do
        local objIdx = getSlotObjIdx(player, slot)
        local obj    = catalog.objectivePool[objIdx]
        if obj then
            local prog = getSlotProgress(player, slot)
            local done = isSlotDone(player, slot)
            local label
            if done then
                label = string.format('[DONE] %s', obj.label)
            else
                label = string.format('[%d/%d] %s', prog, obj.target, obj.label)
            end
            opts[#opts + 1] = {
                label,
                function(p) p:printToPlayer(obj.description, xi.msg.channel.SYSTEM_3) end,
            }
        end
    end
    opts[#opts + 1] = {
        'View status in chat',
        function(p)
            for _, line in ipairs(wh.formatStatus(p)) do
                p:printToPlayer(line, xi.msg.channel.SYSTEM_3)
            end
        end,
    }
    opts[#opts + 1] = { 'Close', function(p) end }

    hbMenu.options = opts
    local snapshot = { title = hbMenu.title, options = hbMenu.options }  -- shared table + deferred send
    player:timer(30, function(p) p:customMenu(snapshot) end)
end

-----------------------------------
-- NPC placement
-----------------------------------
m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', catalog.npcPos.zone), function(zone)
    super(zone)
    local HuntBoard = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Hunt_Board',
        packetName = string.format('%sHunt Board', xi.icon.STAR_LARGE),
        look       = 2418,  -- moogle, generic; distinct from the others
        x          = catalog.npcPos.x,
        y          = catalog.npcPos.y,
        z          = catalog.npcPos.z,
        rotation   = catalog.npcPos.rotation,
        widescan   = 1,
        onTrigger = function(player, npc)
            player:printToPlayer(
                '[Hunt Board] Behold the week\'s objectives, kupo!',
                xi.msg.channel.SYSTEM_3)
            showBoardMenu(player)
        end,
    })
    utils.unused(HuntBoard)
end)

-- Expose the public API on the Module instance so other modules can
-- `require('modules/custom/lua/weekly_hunts').fire(player, ...)`.
-- The same `m` object goes to both the module loader and other
-- modules (require caches the result), so attaching to `m` is the
-- natural place - no proxy/metatable needed.
m.fire         = wh.fire
m.formatStatus = wh.formatStatus

return m
