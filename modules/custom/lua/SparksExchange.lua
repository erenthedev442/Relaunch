-----------------------------------
-- SparksExchange.lua
-- "Eminence Broker" -- a GM Home NPC that buys Sparks of Eminence,
-- Unity Accolades, Job Points, and Hunting League "Hunt Marks" for gil.
-- These all pile up on capped/endgame players; this gives them a gil outlet.
-- Pure Lua, mirrors the gil_mystery_box / Casino menu pattern.
--
-- TUNE: edit xi.sparks_exchange below. All fields are hot-patchable
-- via FileWatcher (just save this file) or live without restart:
--   !exec xi.sparks_exchange.jp_rate = 4000
--
-- Menu callbacks live on xi.sparks_exchange so a FileWatcher re-run
-- updates Convert ALL without a map restart (see bindLiveBroker).
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Abdhaljs_Isle-Purgonorgo/Zone')

local m = Module:new('sparks_exchange')

local S         = xi.msg.channel.SYSTEM_3
local SPARKS    = 'spark_of_eminence'
local ACCOLADES = 'unity_accolades'
-- Hunting League "Hunt Marks" live in this charVar (see HuntingLeague.lua: CV_POINTS).
-- HL_Points_Lifetime is the separate leaderboard total and is intentionally NOT touched.
local HL_POINTS = 'HL_Points'
local GIL_CAP   = 999999999
local ZONE_NAME = 'Abdhaljs_Isle-Purgonorgo'

-- Array index == xi.job numeric ID (WAR=1, MNK=2, …).
local JOB_NAMES = {
    'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK',
    'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'SMN', 'BLU',
    'COR', 'PUP', 'DNC', 'SCH', 'GEO', 'RUN',
}

-- DelJobPoints used to clamp each call to 500 (old retail held-JP cap).
-- This server allows 2100. Convert ALL must chunk AND pay only what was
-- actually removed, or players keep leftover JP and cash out again.
local JP_DEL_CHUNK = 500

-- ===== hot-patchable config =====
-- Closures read xi.sparks_exchange.* at call-time (global lookup), so FileWatcher
-- or !exec changes take effect immediately -- no restart needed.
xi.sparks_exchange = xi.sparks_exchange or {}
xi.sparks_exchange.sp_rate  = 10
xi.sparks_exchange.ac_rate  = 100
xi.sparks_exchange.jp_rate  = 4000
xi.sparks_exchange.hm_rate  = 1000  -- gil per Hunt Mark. Tune live: !exec xi.sparks_exchange.hm_rate = 1500
xi.sparks_exchange.sp_tiers = { 1000, 10000, 50000 }
xi.sparks_exchange.ac_tiers = { 500,  5000,  25000  }
xi.sparks_exchange.jp_tiers = { 1, 5, 20 }
xi.sparks_exchange.hm_tiers = { 100, 1000, 5000 }

-- ===== static NPC config (requires restart to change) =====
local cfg = {
    npcPos = { x = 554.400, y = -3.3322, z = 476.000, rot = 160 },
    name   = 'Currency Exchange',
    look   = 220,
}

local function fmtGil(n)
    if n >= 1000000 then return string.format('%gM', n / 1000000)
    elseif n >= 1000 then return string.format('%dk', n / 1000) end
    return tostring(n)
end

local function show(player, menu)
    local snap = { title = menu.title, options = menu.options }
    player:timer(30, function(p) p:customMenu(snap) end)
end

local function takeJobPoints(player, jobId, want)
    local taken = 0
    while taken < want do
        local before = player:getJobPoints(jobId)
        if before <= 0 then
            break
        end

        local chunk = math.min(want - taken, JP_DEL_CHUNK, before)
        player:delJobPoints(jobId, chunk)
        local after = player:getJobPoints(jobId)
        local got   = before - after
        if got <= 0 then
            break
        end

        taken = taken + got
    end

    return taken
end

function xi.sparks_exchange.convertCurrency(player, currencyKey, amount, rate, label, backFn)
    local have = player:getCurrency(currencyKey)
    if amount == 'all' then amount = have end
    if have <= 0 then
        player:printToPlayer(string.format('[Broker] You have no %s to exchange, kupo.', label), S)
        backFn(player)
        return
    end
    if amount > have then
        player:printToPlayer(string.format('[Broker] You only have %d %s.', have, label), S)
        backFn(player)
        return
    end
    local gil = amount * rate
    if player:getGil() + gil > GIL_CAP then
        player:printToPlayer('[Broker] That would overflow your gil -- spend some first, kupo.', S)
        backFn(player)
        return
    end
    player:delCurrency(currencyKey, amount)
    player:addGil(gil)
    player:printToPlayer(string.format('[Broker] Exchanged %d %s for %s gil. (%s left: %d)',
        amount, label, fmtGil(gil), label, have - amount), S)
    backFn(player)
end

function xi.sparks_exchange.convertJobPoints(player, amount, backFn)
    local jobId   = player:getMainJob()
    local jobName = JOB_NAMES[jobId] or ('Job' .. jobId)
    local have    = player:getJobPoints(jobId)
    if amount == 'all' then amount = have end
    if have <= 0 then
        player:printToPlayer(string.format('[Broker] You have no unspent %s Job Points, kupo.', jobName), S)
        backFn(player)
        return
    end
    if amount > have then
        player:printToPlayer(string.format('[Broker] You only have %d unspent %s Job Points.', have, jobName), S)
        backFn(player)
        return
    end

    local gil = amount * xi.sparks_exchange.jp_rate
    if player:getGil() + gil > GIL_CAP then
        player:printToPlayer('[Broker] That would overflow your gil -- spend some first, kupo.', S)
        backFn(player)
        return
    end

    local taken = takeJobPoints(player, jobId, amount)
    if taken <= 0 then
        player:printToPlayer('[Broker] Could not remove those Job Points, kupo. Try again.', S)
        backFn(player)
        return
    end

    gil = taken * xi.sparks_exchange.jp_rate
    player:addGil(gil)
    player:printToPlayer(string.format('[Broker] Exchanged %d %s JP for %s gil. (%s JP left: %d)',
        taken, jobName, fmtGil(gil), jobName, player:getJobPoints(jobId)), S)
    backFn(player)
end

function xi.sparks_exchange.convertHuntMarks(player, amount, backFn)
    local have = player:getCharVar(HL_POINTS)
    if amount == 'all' then amount = have end
    if have <= 0 then
        player:printToPlayer('[Broker] You have no Hunt Marks to exchange, kupo.', S)
        backFn(player)
        return
    end
    if amount > have then
        player:printToPlayer(string.format('[Broker] You only have %d Hunt Marks.', have), S)
        backFn(player)
        return
    end
    local gil = amount * xi.sparks_exchange.hm_rate
    if player:getGil() + gil > GIL_CAP then
        player:printToPlayer('[Broker] That would overflow your gil -- spend some first, kupo.', S)
        backFn(player)
        return
    end
    player:setCharVar(HL_POINTS, have - amount)
    player:addGil(gil)
    player:printToPlayer(string.format('[Broker] Exchanged %d Hunt Marks for %s gil. (Marks left: %d)',
        amount, fmtGil(gil), have - amount), S)
    backFn(player)
end

function xi.sparks_exchange.sparksScreen(player)
    local have = player:getCurrency(SPARKS)
    local menu = { title = string.format('Sparks of Eminence (%d)', have), options = {} }
    for _, amt in ipairs(xi.sparks_exchange.sp_tiers) do
        local a = amt
        table.insert(menu.options, { string.format('Convert %d (%s gil)', a, fmtGil(a * xi.sparks_exchange.sp_rate)),
            function(p) xi.sparks_exchange.convertCurrency(p, SPARKS, a, xi.sparks_exchange.sp_rate, 'Sparks', xi.sparks_exchange.sparksScreen) end })
    end
    table.insert(menu.options, { 'Convert ALL sparks',
        function(p) xi.sparks_exchange.convertCurrency(p, SPARKS, 'all', xi.sparks_exchange.sp_rate, 'Sparks', xi.sparks_exchange.sparksScreen) end })
    table.insert(menu.options, { 'Back', function(p) xi.sparks_exchange.openMain(p) end })
    show(player, menu)
end

function xi.sparks_exchange.accoladesScreen(player)
    local have = player:getCurrency(ACCOLADES)
    local menu = { title = string.format('Unity Accolades (%d)', have), options = {} }
    for _, amt in ipairs(xi.sparks_exchange.ac_tiers) do
        local a = amt
        table.insert(menu.options, { string.format('Convert %d (%s gil)', a, fmtGil(a * xi.sparks_exchange.ac_rate)),
            function(p) xi.sparks_exchange.convertCurrency(p, ACCOLADES, a, xi.sparks_exchange.ac_rate, 'Accolades', xi.sparks_exchange.accoladesScreen) end })
    end
    table.insert(menu.options, { 'Convert ALL accolades',
        function(p) xi.sparks_exchange.convertCurrency(p, ACCOLADES, 'all', xi.sparks_exchange.ac_rate, 'Accolades', xi.sparks_exchange.accoladesScreen) end })
    table.insert(menu.options, { 'Back', function(p) xi.sparks_exchange.openMain(p) end })
    show(player, menu)
end

function xi.sparks_exchange.jobPointsScreen(player)
    local jobId   = player:getMainJob()
    local jobName = JOB_NAMES[jobId] or ('Job' .. jobId)
    local have    = player:getJobPoints(jobId)
    local menu    = { title = string.format('Job Points - %s (%d JP)', jobName, have), options = {} }
    for _, amt in ipairs(xi.sparks_exchange.jp_tiers) do
        local a = amt
        table.insert(menu.options, { string.format('Convert %d JP (%s gil)', a, fmtGil(a * xi.sparks_exchange.jp_rate)),
            function(p) xi.sparks_exchange.convertJobPoints(p, a, xi.sparks_exchange.jobPointsScreen) end })
    end
    table.insert(menu.options, { 'Convert ALL Job Points',
        function(p) xi.sparks_exchange.convertJobPoints(p, 'all', xi.sparks_exchange.jobPointsScreen) end })
    table.insert(menu.options, { 'Back', function(p) xi.sparks_exchange.openMain(p) end })
    show(player, menu)
end

function xi.sparks_exchange.huntMarksScreen(player)
    local have = player:getCharVar(HL_POINTS)
    local menu = { title = string.format('Hunting Marks (%d)', have), options = {} }
    for _, amt in ipairs(xi.sparks_exchange.hm_tiers) do
        local a = amt
        table.insert(menu.options, { string.format('Convert %d (%s gil)', a, fmtGil(a * xi.sparks_exchange.hm_rate)),
            function(p) xi.sparks_exchange.convertHuntMarks(p, a, xi.sparks_exchange.huntMarksScreen) end })
    end
    table.insert(menu.options, { 'Convert ALL marks',
        function(p) xi.sparks_exchange.convertHuntMarks(p, 'all', xi.sparks_exchange.huntMarksScreen) end })
    table.insert(menu.options, { 'Back', function(p) xi.sparks_exchange.openMain(p) end })
    show(player, menu)
end

function xi.sparks_exchange.openMain(player)
    -- FJB: keep this title SHORT and fixed. The old title inlined Sparks/Accolades/JP;
    -- for high-balance players (e.g. Gwendin, 978k sparks) the extra digits pushed the
    -- customMenu click echo "...Question(<title>): Result (<option>)" past the 128-byte
    -- inbound Mes[] buffer, truncating the option so the exact-match in HandleCustomMenu
    -- failed -> dead buttons. Per-currency balances are still shown on each sub-screen.
    show(player, {
        title = 'Eminence Broker',
        options = {
            { 'Exchange Sparks of Eminence',  function(p) xi.sparks_exchange.sparksScreen(p) end },
            { 'Exchange Unity Accolades',      function(p) xi.sparks_exchange.accoladesScreen(p) end },
            { 'Exchange Job Points',           function(p) xi.sparks_exchange.jobPointsScreen(p) end },
            { 'Exchange Hunting Marks',        function(p) xi.sparks_exchange.huntMarksScreen(p) end },
            { 'Walk away',                     function(p) p:printToPlayer('[Broker] Safe travels, kupo!', S) end },
        },
    })
end

-- FileWatcher re-runs this file but does not re-call Zone.onInitialize.
-- Dynamic-entity onTrigger lives at xi.zones[<zone>].npcs.DE_<name>, so
-- overwrite that slot and the next click uses the updated Convert ALL.
local function bindLiveBroker()
    local zoneTable = xi.zones and xi.zones[ZONE_NAME]
    local npcTable  = zoneTable and zoneTable.npcs and zoneTable.npcs.DE_Sparks_Exchange
    if not npcTable then
        return
    end

    npcTable.onTrigger = function(player)
        xi.sparks_exchange.openMain(player)
    end
    npcTable.onTrade = function(player)
        player:printToPlayer('[Sparks] Just use the menu, kupo!', S)
    end
end

m:addOverride('xi.zones.Abdhaljs_Isle-Purgonorgo.Zone.onInitialize', function(zone)
    super(zone)

    local Broker = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Sparks_Exchange',
        packetName = string.format('%s%s', xi.icon.STAR_LARGE, cfg.name),
        look       = 221,
        x          = cfg.npcPos.x,
        y          = cfg.npcPos.y,
        z          = cfg.npcPos.z,
        rotation   = cfg.npcPos.rot,
        widescan   = 1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('[Sparks] Just use the menu, kupo!', S)
        end,

        onTrigger = function(player, npc)
            xi.sparks_exchange.openMain(player)
        end,
    })
    utils.unused(Broker)
    bindLiveBroker()
end)

bindLiveBroker()

return m
