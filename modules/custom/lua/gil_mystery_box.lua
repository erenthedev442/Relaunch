-----------------------------------
-- gil_mystery_box.lua
-- Mystery Mog: pay gil per pull, roll a weighted random reward.
-- Edit the prize pool in gil_mystery_box_catalog.lua.
--
-- Features:
--   Standard pull  100k  -- weighted random from catalog.pool
--   Triple Pull    270k  -- 3x standard rolls (10% off)
--   Deca Pull      900k  -- 10x standard rolls (10% off) + 1 guaranteed uncommon+
--   Premium Roll   500k  -- rolls catalog.premiumPool (no commons, AP prizes possible)
--   Pity system    --    -- after 50 non-epic+ pulls, next roll guaranteed epic+
--   Jackpot shout  --    -- legendary jackpot prize broadcasts server-wide
--   Prize manifest --    -- "What can I win?" shows tier odds in chat
-----------------------------------
require('modules/module_utils')
require('scripts/zones/GM_Home/Zone')
local catalog = require('modules/custom/lua/gil_mystery_box_catalog')

local m = Module:new('gil_mystery_box')

-- =====================================================
-- Roll helpers
-- =====================================================

local function totalWeight(pool)
    local n = 0
    for _, p in ipairs(pool) do n = n + p.weight end
    return n
end

local function rollFromPool(pool)
    local r = math.random(1, totalWeight(pool))
    local cum = 0
    for _, p in ipairs(pool) do
        cum = cum + p.weight
        if r <= cum then return p end
    end
    return pool[#pool]  -- fallback (float rounding safety)
end

local function prizeTierRank(prize)
    return catalog.tierRank[prize.tier] or 0
end

local function isEpicOrBetter(prize)
    return prizeTierRank(prize) >= catalog.tierRank.epic
end

local function isUncommonOrBetter(prize)
    return prizeTierRank(prize) >= catalog.tierRank.uncommon
end

-- Roll from pool restricted to prizes at or above minRank.
local function rollMinTier(pool, minRank)
    local eligible = {}
    for _, p in ipairs(pool) do
        if prizeTierRank(p) >= minRank then
            table.insert(eligible, p)
        end
    end
    if #eligible == 0 then return rollFromPool(pool) end
    return rollFromPool(eligible)
end

-- =====================================================
-- Pity counter
-- =====================================================

local function getPity(player)
    return player:getCharVar(catalog.pityVar) or 0
end

local function updatePity(player, prize)
    if isEpicOrBetter(prize) then
        player:setCharVar(catalog.pityVar, 0)
    else
        player:setCharVar(catalog.pityVar, getPity(player) + 1)
    end
end

-- =====================================================
-- Prize application
-- =====================================================

local function applyPrize(player, prize)
    if prize.item then
        player:addItem({ id = prize.item, quantity = prize.itemQty or 1 })
    end

    if prize.huntMarks and prize.huntMarks > 0 then
        local cur = player:getCharVar(catalog.huntCv) or 0
        player:setCharVar(catalog.huntCv, cur + prize.huntMarks)
    end

    if prize.gilRefund and prize.gilRefund > 0 then
        player:addGil(prize.gilRefund)
    end

    if prize.pardon then
        player:setCharVar(catalog.pardonVar, 1)
    end

    if prize.ap and prize.ap > 0 then
        local jobId  = player:getMainJob() or 1
        local apKey  = string.format('Prestige_AP_%d', jobId)
        local lifeKey = string.format('Prestige_AP_Lifetime_%d', jobId)
        player:setCharVar(apKey,  (player:getCharVar(apKey)   or 0) + prize.ap)
        player:setCharVar(lifeKey, (player:getCharVar(lifeKey) or 0) + prize.ap)
    end
end

-- =====================================================
-- Server-wide jackpot broadcast
-- =====================================================

local function broadcastJackpot(player, prize)
    if not prize.jackpot then return end
    local msg = string.format(
        '[Mystery Mog] *** %s just hit the JACKPOT! *** (%s)',
        player:getName(), prize.label)
    player:printToArea(msg, xi.msg.channel.SYSTEM_3, xi.msg.area.SYSTEM, '', true)
end

-- =====================================================
-- Core pull logic (single roll with pity check)
-- =====================================================

-- Rolls once from pool, applies pity, applies prize, returns the prize.
-- Does NOT deduct gil or check prerequisites - call-site handles those.
local function doSingleRoll(player, pool, rollIndex)
    local pity = getPity(player)
    local prize

    if pity >= catalog.pityThreshold then
        prize = rollMinTier(pool, catalog.tierRank.epic)
        local pitySuffix = rollIndex
            and string.format(' on pull #%d', rollIndex)
            or  ''
        player:printToPlayer(
            string.format('[Mystery Mog] Pity triggered%s - Epic+ guaranteed!', pitySuffix),
            xi.msg.channel.SYSTEM_3)
    else
        prize = rollFromPool(pool)
    end

    updatePity(player, prize)
    applyPrize(player, prize)
    broadcastJackpot(player, prize)
    return prize
end

-- =====================================================
-- Public pull functions
-- =====================================================

local function fmtGil(n)
    if n >= 1000000 then
        return string.format('%gM', n / 1000000)
    elseif n >= 1000 then
        return string.format('%dk', n / 1000)
    end
    return tostring(n)
end

-- Guard: returns false (with an error message) if prerequisites aren't met.
local function checkPrereqs(player, cost)
    if player:getGil() < cost then
        player:printToPlayer(
            string.format('[Mystery Mog] Need %s gil, you have %s.',
                fmtGil(cost), fmtGil(player:getGil())),
            xi.msg.channel.SYSTEM_3)
        return false
    end
    if player:getFreeSlotsCount() < 1 then
        player:printToPlayer(
            '[Mystery Mog] Inventory full! Free a slot before pulling, kupo.',
            xi.msg.channel.SYSTEM_3)
        return false
    end
    return true
end

local function singlePull(player, pool, cost)
    if not checkPrereqs(player, cost) then return end
    player:delGil(cost)
    local prize = doSingleRoll(player, pool)
    player:printToPlayer(
        string.format('[Mystery Mog] You won: %s!', prize.label),
        xi.msg.channel.SYSTEM_3)
end

local function multiPull(player, pool, cost, count, guaranteeUncommon)
    if not checkPrereqs(player, cost) then return end
    player:delGil(cost)

    local results     = {}
    local hasUncommon = false

    for i = 1, count do
        local prize = doSingleRoll(player, pool, i)
        results[i]  = prize
        if isUncommonOrBetter(prize) then hasUncommon = true end
    end

    -- Guarantee: if no uncommon+ result in the batch, award a bonus roll.
    -- All 10 original prizes were already applied; this is an 11th on top.
    if guaranteeUncommon and not hasUncommon then
        local bonus = rollMinTier(pool, catalog.tierRank.uncommon)
        applyPrize(player, bonus)
        broadcastJackpot(player, bonus)
        -- Pity was already updated per-roll above; don't adjust again here.
        player:printToPlayer(
            string.format('[Mystery Mog] Deca guarantee bonus: %s', bonus.label),
            xi.msg.channel.SYSTEM_3)
    end

    -- Print summary
    player:printToPlayer(
        string.format('[Mystery Mog] %d-pull results:', count),
        xi.msg.channel.SYSTEM_3)
    for i, prize in ipairs(results) do
        player:printToPlayer(
            string.format('  [%02d] %s', i, prize.label),
            xi.msg.channel.SYSTEM_3)
    end
end

-- =====================================================
-- Prize manifest
-- =====================================================

local function showManifest(player, pool, poolName)
    local total = totalWeight(pool)
    local tierOrder = { 'common', 'uncommon', 'rare', 'epic', 'legendary' }
    local tierWeights = {}
    for _, t in ipairs(tierOrder) do tierWeights[t] = 0 end
    for _, p in ipairs(pool) do
        if tierWeights[p.tier] then
            tierWeights[p.tier] = tierWeights[p.tier] + p.weight
        end
    end

    local S = xi.msg.channel.SYSTEM_3
    player:printToPlayer(
        string.format('[Mystery Mog] %s odds:', poolName),
        S)
    for _, t in ipairs(tierOrder) do
        local w = tierWeights[t]
        if w > 0 then
            -- Round to one decimal place
            local pct = math.floor(w / total * 1000 + 0.5) / 10
            local tLabel = t:sub(1,1):upper() .. t:sub(2)
            player:printToPlayer(
                string.format('  %-12s %5.1f%%', tLabel, pct),
                S)
        end
    end
end

local function showAllManifests(player)
    local S = xi.msg.channel.SYSTEM_3
    player:printToPlayer('------- Mystery Mog Prize Tiers -------', S)
    showManifest(player, catalog.pool,        'Standard (100k)')
    showManifest(player, catalog.premiumPool, 'Premium  (500k)')
    player:printToPlayer(
        string.format(
            '  Pity: Epic+ guaranteed after %d non-Epic pulls (counter shown in menu title).',
            catalog.pityThreshold),
        S)
    player:printToPlayer(
        '  Deca Pull: 10x standard + 1 uncommon+ guaranteed if all else is common.',
        S)
    player:printToPlayer(
        "  Death's Pardon: cancels your next death penalty in Reisenjima Henge.",
        S)
    player:printToPlayer(
        '  Ascension Points (premium only): added to your current main job AP pool.',
        S)
    player:printToPlayer('---------------------------------------', S)
end

-- =====================================================
-- NPC + Menu
-- =====================================================

m:addOverride('xi.zones.GM_Home.Zone.onInitialize', function(zone)
    super(zone)

    local menu = { title = '', options = {} }

    local function buildMenu(player)
        local pity    = getPity(player)
        local pityStr = pity > 0
            and string.format(' | Pity: %d/%d', pity, catalog.pityThreshold)
            or  ''

        menu.title = string.format(
            'Mystery Mog  (Gil: %s%s)',
            fmtGil(player:getGil()), pityStr)

        menu.options =
        {
            {
                string.format('Roll the dice  (-%s)', fmtGil(catalog.pullCost)),
                function(p) singlePull(p, catalog.pool, catalog.pullCost) end,
            },
            {
                string.format('Triple Pull x3  (-%s)', fmtGil(catalog.tripleCost)),
                function(p) multiPull(p, catalog.pool, catalog.tripleCost, 3, false) end,
            },
            {
                string.format('Deca Pull x10  (-%s, 1+ uncommon)', fmtGil(catalog.decaCost)),
                function(p) multiPull(p, catalog.pool, catalog.decaCost, 10, true) end,
            },
            {
                -- Keep this label short: the menu round-trips title+option through a
                -- 128-byte buffer, and the client matches the full string on click. A
                -- longer label gets truncated and the selection silently no-ops.
                string.format('Premium Roll  (-%s, no commons)', fmtGil(catalog.premiumCost)),
                function(p) singlePull(p, catalog.premiumPool, catalog.premiumCost) end,
            },
            {
                'What can I win?  (view tier odds)',
                function(p) showAllManifests(p) end,
            },
            {
                'Walk away',
                function(p)
                    p:printToPlayer('Maybe next time, kupo!', xi.msg.channel.SYSTEM_3)
                end,
            },
        }

        local snapshot = { title = menu.title, options = menu.options }  -- shared table + deferred send
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    local MysteryMog = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Mystery_Mog',
        packetName = string.format('%s%s', xi.icon.STAR_LARGE, catalog.npcName),
        look       = catalog.npcLook,
        x          = catalog.npcPos.x,
        y          = catalog.npcPos.y,
        z          = catalog.npcPos.z,
        rotation   = catalog.npcPos.rot,
        widescan   = 1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('Use the menu, kupo!', xi.msg.channel.SYSTEM_3)
        end,

        onTrigger = function(player, npc)
            buildMenu(player)
        end,
    })
    utils.unused(MysteryMog)
end)

return m
