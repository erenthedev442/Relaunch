-----------------------------------
-- Casino.lua
-- "Lady Luck" -- a GM Home gambling den. Menu-driven games of chance, each one
-- a net gil SINK (built-in house edge) while still letting lucky players win big
-- and shout it server-wide. Mirrors the gil_mystery_box pattern: gil in, RNG,
-- payout, customMenu. All odds/payouts live in casino_catalog.lua.
--
-- Games: Slots, High-Low, Roulette, Dice.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Celennia_Memorial_Library/Zone')
local catalog = require('modules/custom/lua/casino_catalog')

local m = Module:new('casino')

local S = xi.msg.channel.SYSTEM_3

-- ---------- module-level helpers ----------

local function fmtGil(n)
    if n >= 1000000 then
        return string.format('%gM', n / 1000000)
    elseif n >= 1000 then
        return string.format('%dk', n / 1000)
    end
    return tostring(n)
end

-- Weighted draw of one slot symbol from a reel strip.
local function rollSym(reel)
    local total = 0
    for _, s in ipairs(reel) do total = total + s.weight end
    local r, cum = math.random(1, total), 0
    for _, s in ipairs(reel) do
        cum = cum + s.weight
        if r <= cum then return s.sym end
    end
    return reel[#reel].sym
end

m:addOverride('xi.zones.Celennia_Memorial_Library.Zone.onInitialize', function(zone)
    super(zone)

    -- One shared scratch menu; each screen sets title+options then snapshots it.
    -- Build+snapshot is synchronous (no yield), so concurrent players don't race.
    local menu = { title = '', options = {} }

    -- forward declarations (closures below reference these before they're assigned)
    local mainScreen, openBets, showRules
    local playSlots, hiloReveal, rouletteChoice, diceChoice
    local games

    -- Per-player in-flight guard: prevents the 30ms timer window between
    -- settle() and the new menu arriving from being exploited via packet
    -- replay (sending the same bet click twice before the menu updates).
    local betting = {}

    -- The menu round-trips title + the clicked label through a 128-byte buffer
    -- (client matches the full string on click) -- keep labels short or a click
    -- silently no-ops. Send is deferred a tick so result messages land first.
    local function show(player)
        local snap = { title = menu.title, options = menu.options }
        player:timer(30, function(p) p:customMenu(snap) end)
    end

    local function header(player)
        return string.format('Lady Luck  (Gil: %s)', fmtGil(player:getGil()))
    end

    -- Debit the wager; false (with a message) if the player can't cover it
    -- or if a previous bet is still resolving (double-click guard).
    local function takeBet(player, bet)
        local pid = player:getID()
        if betting[pid] then
            return false
        end
        if player:getGil() < bet then
            player:printToPlayer(string.format('[Casino] You need %s gil for that bet -- you have %s.',
                fmtGil(bet), fmtGil(player:getGil())), S)
            return false
        end
        betting[pid] = true
        player:delGil(bet)
        return true
    end

    -- mult = total-return multiplier (0 = loss, 1 = push, 2 = double, ...).
    -- Pays out, prints the result line, records a personal best, shouts big wins.
    local function settle(player, bet, mult, line)
        local payout = math.floor(bet * mult)
        if payout > 0 then
            player:addGil(payout)
            if payout > (player:getCharVar('casino_biggest') or 0) then
                player:setCharVar('casino_biggest', math.min(payout, 2000000000))
            end
        end
        local net = payout - bet
        local tag
        if net > 0 then
            tag = string.format('you WIN %s!', fmtGil(net))
        elseif net == 0 then
            tag = 'push -- bet returned.'
        else
            tag = string.format('you lose %s.', fmtGil(bet))
        end
        player:printToPlayer(string.format('[Casino] %s %s', line, tag), S)

        if payout >= catalog.jackpotBroadcast then
            player:printToArea(string.format('[Casino] *** %s just won %s at Lady Luck! ***',
                player:getName(), fmtGil(payout)),
                xi.msg.channel.SYSTEM_3, xi.msg.area.SYSTEM, '', true)
        end
    end

    -- ---------- SLOTS (one-step: bet then spin) ----------
    playSlots = function(player, bet)
        if not takeBet(player, bet) then return end
        local a, b, c = rollSym(catalog.slots.reel), rollSym(catalog.slots.reel), rollSym(catalog.slots.reel)
        local mult = (a == b and b == c) and (catalog.slots.three[a] or 0) or 0
        settle(player, bet, mult, string.format('Slots [ %s | %s | %s ] --', a, b, c))
        openBets(player, games.slots)  -- stay on the slots stake screen to spin again
    end

    -- ---------- HIGH-LOW (reveal anchor, then Higher/Lower) ----------
    -- Odds-based payout keeps the edge constant: mult = (ranks/winning)*(1-edge).
    -- Bet is taken only when the player commits to a side, so backing out is free.
    hiloReveal = function(player, bet)
        local ranks  = catalog.highlow.ranks
        local edge   = catalog.highlow.houseEdge
        local anchor = math.random(1, ranks)
        local hiWin  = ranks - anchor
        local loWin  = anchor - 1
        local hiMult = hiWin > 0 and (ranks / hiWin) * (1 - edge) or 0
        local loMult = loWin > 0 and (ranks / loWin) * (1 - edge) or 0

        local function pick(p, dir, mult)
            if mult <= 0 then
                p:printToPlayer('[Casino] No card can win that way -- take the other side.', S)
                return
            end
            if not takeBet(p, bet) then return end
            local nxt = math.random(1, ranks)
            local won = (dir == 'hi' and nxt > anchor) or (dir == 'lo' and nxt < anchor)
            settle(p, bet, won and mult or 0, string.format('High-Low: %d then %d --', anchor, nxt))
            hiloReveal(p, bet)  -- fresh card, same stake
        end

        menu.title = string.format('The card is %d.  Higher or Lower?  (Bet: %s)', anchor, fmtGil(bet))
        menu.options =
        {
            { string.format('Higher  (x%.2f)', hiMult), function(p) pick(p, 'hi', hiMult) end },
            { string.format('Lower  (x%.2f)',  loMult), function(p) pick(p, 'lo', loMult) end },
            { 'Back', function(p) openBets(p, games.highlow) end },
        }
        show(player)
    end

    -- ---------- ROULETTE (bet a side, then spin) ----------
    rouletteChoice = function(player, bet)
        local function spin(p, kind)
            if not takeBet(p, bet) then return end
            local n = math.random(0, catalog.roulette.slots - 1)  -- 0..36
            local color = (n == 0) and 'green' or (catalog.roulette.red[n] and 'red' or 'black')
            local mult = 0
            if kind == 'green' then
                if n == 0 then mult = catalog.roulette.greenPay end
            elseif n ~= 0 then
                if     kind == 'red'   and color == 'red'   then mult = catalog.roulette.evenPay
                elseif kind == 'black' and color == 'black' then mult = catalog.roulette.evenPay
                elseif kind == 'odd'   and (n % 2) == 1     then mult = catalog.roulette.evenPay
                elseif kind == 'even'  and (n % 2) == 0     then mult = catalog.roulette.evenPay end
            end
            settle(p, bet, mult, string.format('Roulette landed %d %s --', n, color))
            rouletteChoice(p, bet)
        end

        menu.title = string.format('Roulette -- place your bet  (Bet: %s)', fmtGil(bet))
        menu.options =
        {
            { 'Red  (x2)',      function(p) spin(p, 'red')   end },
            { 'Black  (x2)',    function(p) spin(p, 'black') end },
            { 'Odd  (x2)',      function(p) spin(p, 'odd')   end },
            { 'Even  (x2)',     function(p) spin(p, 'even')  end },
            { 'Green 0  (x35)', function(p) spin(p, 'green') end },
            { 'Back', function(p) openBets(p, games.roulette) end },
        }
        show(player)
    end

    -- ---------- DICE (2d6 band bet) ----------
    diceChoice = function(player, bet)
        local function roll(p, kind)
            if not takeBet(p, bet) then return end
            local r = math.random(1, 6) + math.random(1, 6)  -- 2..12
            local mult = 0
            if     kind == 'high'  and r >= 8 then mult = catalog.dice.highLowPay
            elseif kind == 'low'   and r <= 6 then mult = catalog.dice.highLowPay
            elseif kind == 'seven' and r == 7 then mult = catalog.dice.sevenPay end
            settle(p, bet, mult, string.format('Dice rolled %d --', r))
            diceChoice(p, bet)
        end

        menu.title = string.format('Dice 2d6 -- pick the band  (Bet: %s)', fmtGil(bet))
        menu.options =
        {
            { 'High 8-12  (x2.25)', function(p) roll(p, 'high')  end },
            { 'Low 2-6  (x2.25)',   function(p) roll(p, 'low')   end },
            { 'Lucky 7  (x5)',      function(p) roll(p, 'seven') end },
            { 'Back', function(p) openBets(p, games.dice) end },
        }
        show(player)
    end

    -- ---------- stake picker (shared by all games) ----------
    openBets = function(player, game)
        betting[player:getID()] = nil  -- lift the in-flight guard
        menu.title = string.format('%s -- choose your stake  (Gil: %s)', game.label, fmtGil(player:getGil()))
        local opts = {}
        for _, amt in ipairs(catalog.betTiers) do
            local bet = amt  -- fresh capture per option
            table.insert(opts, { string.format('Bet %s', fmtGil(bet)), function(p) game.onBet(p, bet) end })
        end
        table.insert(opts, { 'Back', function(p) mainScreen(p) end })
        menu.options = opts
        show(player)
    end

    -- game registry: display label + what choosing a stake does
    games =
    {
        slots    = { label = 'Slots',    onBet = function(p, bet) playSlots(p, bet)      end },
        highlow  = { label = 'High-Low', onBet = function(p, bet) hiloReveal(p, bet)     end },
        roulette = { label = 'Roulette', onBet = function(p, bet) rouletteChoice(p, bet) end },
        dice     = { label = 'Dice',     onBet = function(p, bet) diceChoice(p, bet)     end },
    }

    showRules = function(player)
        player:printToPlayer('------- Lady Luck: House Rules -------', S)
        player:printToPlayer('  Slots: match 3 -- 7 x150, Bell x30, Melon x10, Cherry x4.', S)
        player:printToPlayer('  High-Low: call the next rank. Safe calls pay a little, risky calls pay a lot.', S)
        player:printToPlayer('  Roulette: Red/Black/Odd/Even pay x2 (lose on 0); Green 0 pays x35.', S)
        player:printToPlayer('  Dice 2d6: High 8-12 / Low 2-6 pay x2.25; Lucky 7 pays x5.', S)
        player:printToPlayer('  The house keeps a small edge -- only bet what you can afford to lose!', S)
        player:printToPlayer('-------------------------------------', S)
        mainScreen(player)
    end

    mainScreen = function(player)
        betting[player:getID()] = nil  -- ensure guard is clear on any return to main
        menu.title = header(player)
        menu.options =
        {
            { 'Slots',     function(p) openBets(p, games.slots)    end },
            { 'High-Low',  function(p) openBets(p, games.highlow)  end },
            { 'Roulette',  function(p) openBets(p, games.roulette) end },
            { 'Dice',      function(p) openBets(p, games.dice)     end },
            { 'House rules / odds', function(p) showRules(p) end },
            { 'Walk away', function(p) p:printToPlayer('[Casino] The house always wins, kupo... come back soon!', S) end },
        }
        show(player)
    end

    -- ---------- NPC ----------
    local LadyLuck = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Casino_LadyLuck',
        packetName = string.format('%s%s', xi.icon.STAR_LARGE, catalog.npcName),
        look       = 109,
        x          = catalog.npcPos.x,
        y          = catalog.npcPos.y,
        z          = catalog.npcPos.z,
        rotation   = catalog.npcPos.rot,
        widescan   = 1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('[Casino] No trading here -- use the menu to play, kupo!', S)
        end,

        onTrigger = function(player, npc)
            mainScreen(player)
        end,
    })
    utils.unused(LadyLuck)
end)

return m
