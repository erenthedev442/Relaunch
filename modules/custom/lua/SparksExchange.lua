-----------------------------------
-- SparksExchange.lua
-- "Eminence Broker" -- a GM Home NPC that buys your Sparks of Eminence for gil.
-- Sparks cap easily via Records of Eminence, so capped players have nothing to
-- spend them on; this is their outlet (a sparks sink / modest gil faucet).
-- Pure Lua, mirrors the gil_mystery_box / Casino menu pattern.
--
-- TUNE: `cfg.rate` below is the gil paid per spark (10 -> at the live
-- 999,999-spark cap = ~10M gil). Change that one number to reprice it.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/GM_Home/Zone')

local m = Module:new('sparks_exchange')

local S       = xi.msg.channel.SYSTEM_3
local SPARKS  = 'spark_of_eminence'
local GIL_CAP = 999999999

-- ===== config (tune freely) =====
local cfg =
{
    rate   = 10,                                                 -- gil paid per spark (999,999 cap = ~10M gil)
    tiers  = { 1000, 10000, 50000 },                            -- preset convert amounts (+ "all")
    npcPos = { x = -7.500, y = 0.000, z = -35.000, rot = 128 },  -- GM Home economy corner, west end of the gil-NPC row
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
    local mainScreen

    local function show(player)
        local snap = { title = menu.title, options = menu.options }
        player:timer(30, function(p) p:customMenu(snap) end)
    end

    -- Convert `amount` sparks to gil. amount == 'all' converts the full balance.
    local function convert(player, amount)
        local have = player:getCurrency(SPARKS)
        if amount == 'all' then amount = have end
        if have <= 0 then
            player:printToPlayer('[Sparks] You have no Sparks of Eminence to exchange, kupo.', S)
            mainScreen(player)
            return
        end
        if amount > have then
            player:printToPlayer(string.format('[Sparks] You only have %d sparks.', have), S)
            mainScreen(player)
            return
        end
        local gil = amount * cfg.rate
        if player:getGil() + gil > GIL_CAP then
            player:printToPlayer('[Sparks] That would overflow your gil -- spend some first, kupo.', S)
            mainScreen(player)
            return
        end
        player:delCurrency(SPARKS, amount)
        player:addGil(gil)
        player:printToPlayer(string.format('[Sparks] Exchanged %d sparks for %d gil. (Sparks left: %d)',
            amount, gil, have - amount), S)
        mainScreen(player)
    end

    mainScreen = function(player)
        menu.title = string.format('Eminence Broker (Sparks: %d)', player:getCurrency(SPARKS))
        local opts = {}
        for _, amt in ipairs(cfg.tiers) do
            local a = amt  -- fresh capture per option
            table.insert(opts, { string.format('Convert %d (%s gil)', a, fmtGil(a * cfg.rate)),
                function(p) convert(p, a) end })
        end
        table.insert(opts, { 'Convert ALL sparks', function(p) convert(p, 'all') end })
        table.insert(opts, { 'Walk away',          function(p) p:printToPlayer('[Sparks] Safe travels, kupo!', S) end })
        menu.options = opts
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
