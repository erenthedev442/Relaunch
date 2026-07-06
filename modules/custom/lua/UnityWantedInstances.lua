-----------------------------------
-- Parallel private-instance Unity Wanted board
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Celennia_Memorial_Library/Zone')

local m = Module:new('unity_wanted_instances')

local catalog = require('modules/custom/lua/unity_wanted_catalog')
local runtime = require('modules/custom/lua/unity_wanted_instance_runtime')
local S       = xi.msg.channel.SYSTEM_3
local ICON    = xi.icon and xi.icon.STAR_LARGE or ''
local PAGE    = 4  -- keep long NM names safely below customMenu's packet limit

local function showMenu(player, menu)
    local snapshot = { title = menu.title, options = menu.options }
    player:timer(30, function(p) p:customMenu(snapshot) end)
end

local function dismissTrusts(player)
    for _, member in ipairs(player:getPartyWithTrusts()) do
        if member:isTrust() then
            member:setHP(0)
        end
    end
end

local function collectParty(player)
    local members = {}
    for _, member in ipairs(player:getParty()) do
        if member:getObjType() == xi.objType.PC then
            table.insert(members, member)
        end
    end

    return members
end

local function validateParty(player, nm)
    local leader = player:getPartyLeader()
    if leader and leader:getID() ~= player:getID() then
        return nil, 'Only the party leader can open a private trial.'
    end

    local members = collectParty(player)
    local cost = catalog.costs[nm.tier]
    for _, member in ipairs(members) do
        if member:getZoneID() ~= runtime.config.entranceId then
            return nil, string.format('%s must be in the Library.', member:getName())
        elseif member:checkDistance(player) > 50 then
            return nil, string.format('%s is too far from the board.', member:getName())
        elseif member:getInstance() then
            return nil, string.format('%s is already inside an instance.', member:getName())
        end

        runtime.recoverAtBoard(member)
        if member:getCurrency('unity_accolades') < cost then
            return nil, string.format('%s needs %d accolades.', member:getName(), cost)
        end
    end

    return members
end

local function startTrial(player, nm)
    local members, err = validateParty(player, nm)
    if not members then
        player:printToPlayer('[Unity Instance] ' .. err, S)
        return
    end

    local cost = catalog.costs[nm.tier]
    local paidNames = {}
    for _, member in ipairs(members) do
        member:delCurrency('unity_accolades', cost)
        member:setCharVar(runtime.vars.nm, nm.id)
        member:setCharVar(runtime.vars.paid, cost)
        member:setCharVar(runtime.vars.active, 0)
        member:setLocalVar(runtime.vars.pending, runtime.config.instanceId)
        table.insert(paidNames, member:getName())
        dismissTrusts(member)
    end

    player:printToPlayer(
        string.format('[Unity Instance] Opening a private %s trial for %d player(s)...',
            nm.label, #members), S)
    player:createInstance(runtime.config.instanceId)

    -- Failed loaders do not always leave a live instance to run failure hooks.
    -- Refund every character still marked as paid and pending.
    player:timer(15000, function()
        for _, name in ipairs(paidNames) do
            local member = GetPlayerByName(name)
            if
                member and
                not member:getInstance() and
                member:getCharVar(runtime.vars.active) == 0 and
                member:getCharVar(runtime.vars.nm) == nm.id
            then
                runtime.refundPlayer(member,
                    '[Unity Instance] The trial failed to open; your accolades were refunded.')
            end
        end
    end)
end

m:addOverride('xi.zones.Celennia_Memorial_Library.Zone.onInitialize', function(zone)
    super(zone)

    local menu = { title = '', options = {} }
    local mainScreen, tierScreen, confirmScreen

    local function show(player)
        showMenu(player, menu)
    end

    mainScreen = function(player)
        runtime.recoverAtBoard(player)
        local featured = runtime.getNm(runtime.weeklyFeaturedId())

        menu.title = 'Private Unity Trials'
        menu.options =
        {
            {
                string.format('Weekly: %s (2x)', featured and featured.label or '?'),
                function(p) if featured then confirmScreen(p, featured) end end,
            },
            { 'Tier 1  Lv 75-80',  function(p) tierScreen(p, 1, 1) end },
            { 'Tier 2  Lv 99-119', function(p) tierScreen(p, 2, 1) end },
            { 'Tier 3  Lv 120+',   function(p) tierScreen(p, 3, 1) end },
            {
                'Party rules',
                function(p)
                    p:printToPlayer(
                        '[Unity Instance] Every nearby PC pays the tier cost and every entrant earns the kill reward.', S)
                    mainScreen(p)
                end,
            },
            { 'Leave', function() end },
        }
        show(player)
    end

    tierScreen = function(player, tier, page)
        local tierNms = {}
        for _, nm in ipairs(catalog.nms) do
            if nm.tier == tier then
                table.insert(tierNms, nm)
            end
        end

        local first = (page - 1) * PAGE + 1
        local last  = math.min(first + PAGE - 1, #tierNms)
        local opts  = {}
        for index = first, last do
            local selected = tierNms[index]
            local marker = selected.id == runtime.weeklyFeaturedId() and '*' or ''
            table.insert(opts,
            {
                selected.label .. marker,
                function(p) confirmScreen(p, selected) end,
            })
        end

        if page > 1 then
            table.insert(opts, { '<< Prev', function(p) tierScreen(p, tier, page - 1) end })
        end
        if last < #tierNms then
            table.insert(opts, { 'Next >>', function(p) tierScreen(p, tier, page + 1) end })
        end
        table.insert(opts, { '<< Back', function(p) mainScreen(p) end })

        menu.title = string.format('Private T%d | %d acc each', tier, catalog.costs[tier])
        menu.options = opts
        show(player)
    end

    confirmScreen = function(player, nm)
        local cost = catalog.costs[nm.tier]
        local reward = catalog.rewards[nm.tier]
        if nm.id == runtime.weeklyFeaturedId() then
            reward = reward * 2
        end

        menu.title = string.format('%s | Lv %d', nm.label, nm.minLv)
        menu.options =
        {
            {
                string.format('Enter [%d -> +%d each]', cost, reward),
                function(p) startTrial(p, nm) end,
            },
            { '<< Back', function(p) tierScreen(p, nm.tier, 1) end },
        }
        show(player)
    end

    local pos = runtime.config.boardPos
    local board = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Unity_Instance_Board',
        packetName = string.format('%sUnity Instances', ICON),
        look       = 233,
        x          = pos.x,
        y          = pos.y,
        z          = pos.z,
        rotation   = pos.rot,
        widescan   = 1,

        onTrade = function(player)
            player:printToPlayer('[Unity Instance] Use the board menu, kupo!', S)
        end,

        onTrigger = function(player)
            mainScreen(player)
        end,
    })
    utils.unused(board)
end)

return m
