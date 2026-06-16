-----------------------------------
-- SparksExchange.lua
-- "Eminence Broker" -- a GM Home NPC that buys Sparks of Eminence,
-- Unity Accolades, and Job Points for gil. All three cap easily;
-- this gives capped players a gil outlet.
-- Pure Lua, mirrors the gil_mystery_box / Casino menu pattern.
--
-- TUNE: edit xi.sparks_exchange below. All fields are hot-patchable
-- via FileWatcher (just save this file) or live without restart:
--   !exec xi.sparks_exchange.jp_rate = 4000
-----------------------------------
require('modules/module_utils')
require('scripts/zones/GM_Home/Zone')

local m = Module:new('sparks_exchange')

local S         = xi.msg.channel.SYSTEM_3
local SPARKS    = 'spark_of_eminence'
local ACCOLADES = 'unity_accolades'
local GIL_CAP   = 999999999

-- Array index == xi.job numeric ID (WAR=1, MNK=2, …).
local JOB_NAMES = {
    'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK',
    'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'SMN', 'BLU',
    'COR', 'PUP', 'DNC', 'SCH', 'GEO', 'RUN',
}

-- ===== hot-patchable config =====
-- Closures read xi.sparks_exchange.* at call-time (global lookup), so FileWatcher
-- or !exec changes take effect immediately -- no restart needed.
xi.sparks_exchange = {
    sp_rate  = 10,
    ac_rate  = 100,
    jp_rate  = 4000,
    sp_tiers = { 1000, 10000, 50000 },
    ac_tiers = { 500,  5000,  25000  },
    jp_tiers = { 1, 5, 20 },
}

-- ===== static NPC config (requires restart to change) =====
local cfg = {
    npcPos = { x = -7.500, y = 0.000, z = -35.000, rot = 128 },
    name   = 'Sparks Cash',
    look   = 3000,
}

local function fmtGil(n)
    if n >= 1000000 then return string.format('%gM', n / 1000000)
    elseif n >= 1000 then return string.format('%dk', n / 1000) end
    return tostring(n)
end

m:addOverride('xi.zones.GM_Home.Zone.onInitialize', function(zone)
    super(zone)

    local menu = { title = '', options = {} }
    local mainScreen, sparksScreen, accoladesScreen, jobPointsScreen

    local function show(player)
        local snap = { title = menu.title, options = menu.options }
        player:timer(30, function(p) p:customMenu(snap) end)
    end

    local function convertCurrency(player, currencyKey, amount, rate, label, backFn)
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

    sparksScreen = function(player)
        local have = player:getCurrency(SPARKS)
        menu.title = string.format('Sparks of Eminence (%d)', have)
        local opts = {}
        for _, amt in ipairs(xi.sparks_exchange.sp_tiers) do
            local a = amt
            table.insert(opts, { string.format('Convert %d (%s gil)', a, fmtGil(a * xi.sparks_exchange.sp_rate)),
                function(p) convertCurrency(p, SPARKS, a, xi.sparks_exchange.sp_rate, 'Sparks', sparksScreen) end })
        end
        table.insert(opts, { 'Convert ALL sparks',
            function(p) convertCurrency(p, SPARKS, 'all', xi.sparks_exchange.sp_rate, 'Sparks', sparksScreen) end })
        table.insert(opts, { 'Back', function(p) mainScreen(p) end })
        menu.options = opts
        show(player)
    end

    accoladesScreen = function(player)
        local have = player:getCurrency(ACCOLADES)
        menu.title = string.format('Unity Accolades (%d)', have)
        local opts = {}
        for _, amt in ipairs(xi.sparks_exchange.ac_tiers) do
            local a = amt
            table.insert(opts, { string.format('Convert %d (%s gil)', a, fmtGil(a * xi.sparks_exchange.ac_rate)),
                function(p) convertCurrency(p, ACCOLADES, a, xi.sparks_exchange.ac_rate, 'Accolades', accoladesScreen) end })
        end
        table.insert(opts, { 'Convert ALL accolades',
            function(p) convertCurrency(p, ACCOLADES, 'all', xi.sparks_exchange.ac_rate, 'Accolades', accoladesScreen) end })
        table.insert(opts, { 'Back', function(p) mainScreen(p) end })
        menu.options = opts
        show(player)
    end

    local function convertJobPoints(player, amount, backFn)
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
        player:delJobPoints(jobId, amount)
        player:addGil(gil)
        player:printToPlayer(string.format('[Broker] Exchanged %d %s JP for %s gil. (%s JP left: %d)',
            amount, jobName, fmtGil(gil), jobName, have - amount), S)
        backFn(player)
    end

    jobPointsScreen = function(player)
        local jobId   = player:getMainJob()
        local jobName = JOB_NAMES[jobId] or ('Job' .. jobId)
        local have    = player:getJobPoints(jobId)
        menu.title = string.format('Job Points - %s (%d JP)', jobName, have)
        local opts = {}
        for _, amt in ipairs(xi.sparks_exchange.jp_tiers) do
            local a = amt
            table.insert(opts, { string.format('Convert %d JP (%s gil)', a, fmtGil(a * xi.sparks_exchange.jp_rate)),
                function(p) convertJobPoints(p, a, jobPointsScreen) end })
        end
        table.insert(opts, { 'Convert ALL Job Points',
            function(p) convertJobPoints(p, 'all', jobPointsScreen) end })
        table.insert(opts, { 'Back', function(p) mainScreen(p) end })
        menu.options = opts
        show(player)
    end

    mainScreen = function(player)
        local jobId   = player:getMainJob()
        local jobName = JOB_NAMES[jobId] or ('Job' .. jobId)
        menu.title = string.format('Eminence Broker (Sparks: %d | Accolades: %d | %s JP: %d)',
            player:getCurrency(SPARKS), player:getCurrency(ACCOLADES),
            jobName, player:getJobPoints(jobId))
        menu.options = {
            { 'Exchange Sparks of Eminence',  function(p) sparksScreen(p) end },
            { 'Exchange Unity Accolades',      function(p) accoladesScreen(p) end },
            { 'Exchange Job Points',           function(p) jobPointsScreen(p) end },
            { 'Walk away',                     function(p) p:printToPlayer('[Broker] Safe travels, kupo!', S) end },
        }
        show(player)
    end

    local Broker = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Sparks_Exchange',
        packetName = string.format('%s%s', xi.icon.STAR_LARGE, cfg.name),
        look       = cfg.look,
        x          = cfg.npcPos.x,
        y          = cfg.npcPos.y,
        z          = cfg.npcPos.z,
        rotation   = cfg.npcPos.rot,
        widescan   = 1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('[Sparks] Just use the menu, kupo!', S)
        end,

        onTrigger = function(player, npc)
            mainScreen(player)
        end,
    })
    utils.unused(Broker)
end)

return m
