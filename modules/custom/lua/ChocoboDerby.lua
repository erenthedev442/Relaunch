-----------------------------------
-- ChocoboDerby.lua
-- THE CHOCOBO DERBY: simulated chocobo racing with betting, run by
-- the Race Caller at GM Home. Pick a bet, study the odds board, back
-- a runner, and watch the call. House keeps a cut of fair odds - the
-- Derby is a gil sink that occasionally makes someone rich.
--
-- Raised a chocobo? Field it: its hidden weight comes from its REAL
-- raising stats (strength/endurance/affection), and winning on your
-- own bird pays a home-stable bonus. Closing the chocobo-raising loop
-- is the whole point.
--
-- EXPLOIT-PROOFING: the winner is drawn and the payout SETTLED the
-- moment the race starts - the commentary ticks that follow are pure
-- theater on player timers. Zoning or logging mid-race can silence
-- the show but can never dodge a loss or eat a win.
-----------------------------------
require('modules/module_utils')
local catalog = require('modules/custom/lua/chocobo_derby_catalog')
require(string.format('scripts/zones/%s/Zone', catalog.npcPos.zone))

local m = Module:new('chocobo_derby')

-----------------------------------
-- Field assembly
-----------------------------------
local function shuffled(list)
    local out = {}
    for i, v in ipairs(list) do out[i] = v end
    for i = #out, 2, -1 do
        local j = math.random(i)
        out[i], out[j] = out[j], out[i]
    end
    return out
end

-- Reads the player's raised chocobo, or nil if they have none / it's
-- too young. Returns { name, weight, own = true }.
local function ownBirdRunner(player)
    local ok, info = pcall(function() return player:getChocoboRaisingInfo() end)
    if not ok or not info then return nil end
    if (info.stage or 0) < catalog.ownBird.minStage then return nil end

    local cfg = catalog.ownBird
    local weight = cfg.base
        + math.floor(((info.strength or 0) + (info.endurance or 0)) / cfg.statDiv)
        + math.floor((info.affection or 0) / cfg.affectionDiv)
    weight = math.max(cfg.weightMin, math.min(weight, cfg.weightMax))

    local name = info.first_name or 'My Chocobo'
    return { name = name, weight = weight, own = true }
end

-- Build the race field: 5 (or 6) NPC runners + optionally your bird.
local function buildField(player, fieldOwn)
    local field = {}
    local names = shuffled(catalog.stable)
    local npcCount = catalog.fieldSize - (fieldOwn and 1 or 0)
    for i = 1, npcCount do
        field[#field + 1] = {
            name   = names[i],
            weight = math.random(catalog.npcWeightMin, catalog.npcWeightMax),
            own    = false,
        }
    end
    if fieldOwn then
        field[#field + 1] = fieldOwn
    end
    return field
end

local function totalWeight(field)
    local w = 0
    for _, r in ipairs(field) do w = w + r.weight end
    return w
end

-- Payout multiplier for a runner: fair odds x house factor, floored.
local function payoutMult(field, runner)
    local fair = totalWeight(field) / runner.weight
    return math.max(catalog.minPayout, fair * catalog.houseFactor)
end

local function drawWinner(field)
    local roll = math.random() * totalWeight(field)
    for _, r in ipairs(field) do
        roll = roll - r.weight
        if roll <= 0 then return r end
    end
    return field[#field]
end

-----------------------------------
-- The race itself. Settlement is IMMEDIATE; commentary follows.
-----------------------------------
local function runRace(player, field, pick, bet)
    if player:getGil() < bet then
        player:printToPlayer('[Derby] Your purse is too light for that bet, kupo!',
            xi.msg.channel.SYSTEM_3)
        return
    end
    player:delGil(bet)

    local winner = drawWinner(field)
    local won    = (winner == pick)
    local mult   = payoutMult(field, pick)
    local payout = 0

    -- SETTLE NOW (see header). Stats too.
    player:setCharVar('Derby_Races', (player:getCharVar('Derby_Races') or 0) + 1)
    local profitDelta = -bet
    if won then
        payout = math.floor(bet * mult)
        if pick.own then
            payout = math.floor(payout * (1 + catalog.ownBird.winBonusPct / 100))
            player:setCharVar('Derby_OwnWins',
                (player:getCharVar('Derby_OwnWins') or 0) + 1)
        end
        player:addGil(payout)
        profitDelta = payout - bet
        player:setCharVar('Derby_Wins', (player:getCharVar('Derby_Wins') or 0) + 1)
    end
    player:setCharVar('Derby_Profit',
        (player:getCharVar('Derby_Profit') or 0) + profitDelta)

    local okAch, ach = pcall(require, 'modules/custom/lua/achievements')
    if okAch and ach and ach.onDerbyResult then
        pcall(function() ach.onDerbyResult(player, won and pick.own or false) end)
    end

    -- Commentary theater. Leaders before the final tick are drawn
    -- with a bias AWAY from the winner so the finish reads as a surge.
    player:printToPlayer(string.format(
        '[Derby] THEY\'RE OFF! %d runners thunder out of the gate - you backed %s at x%.1f!',
        #field, pick.name, mult), xi.msg.channel.SYSTEM_3)

    local ticks = catalog.race.ticks
    local lines = {
        'takes the early lead down the straight!',
        'holds the rail through the first turn!',
        'surges ahead at the halfway post!',
        'leads into the final turn - the crowd is on its feet!',
    }

    for tick = 1, ticks do
        player:timer(tick * catalog.race.tickSec * 1000, function(p)
            if tick < ticks then
                local leader = field[math.random(#field)]
                if leader == winner and math.random(100) <= 60 then
                    leader = field[math.random(#field)]  -- hide the winner, usually
                end
                p:printToPlayer(string.format('[Derby] %s %s',
                    leader.name, lines[math.min(tick, #lines)]),
                    xi.msg.channel.SYSTEM_3)
            else
                p:printToPlayer(string.format(
                    '[Derby] PHOTO FINISH... %s WINS%s!',
                    winner.name, winner.own and ' - YOUR OWN BIRD' or ''),
                    xi.msg.channel.SYSTEM_3)
                if won then
                    p:printToPlayer(string.format(
                        '[Derby] Your ticket pays %s gil%s! (bet %s at x%.1f)',
                        payout, pick.own and ' with the home-stable bonus' or '',
                        bet, mult), xi.msg.channel.SYSTEM_3)
                else
                    p:printToPlayer(string.format(
                        '[Derby] %s never found the gear. Ticket torn - %s gil to the house.',
                        pick.name, bet), xi.msg.channel.SYSTEM_3)
                end
            end
        end)
    end
end

-----------------------------------
-- Menus
-----------------------------------
local function sendMenu(player, title, options)
    local m = { title = title, options = options }
    player:timer(30, function(p) p:customMenu(m) end)
end

local function showRunnerMenu(player, bet)
    local fieldOwn = ownBirdRunner(player)
    local field    = buildField(player, fieldOwn)

    -- Byte budget: 6 rows of 'name(<=12) x9.9' + '*' own marker + the
    -- short title + 'Walk away' sits ~125 bytes of the 150-byte cap.
    local options = {}
    for _, runner in ipairs(field) do
        local r = runner
        local label = string.format('%s%s x%.1f',
            r.name:sub(1, 12), r.own and '*' or '', payoutMult(field, r))
        options[#options + 1] = {
            label,
            function(p) runRace(p, field, r, bet) end,
        }
    end
    options[#options + 1] = { 'Walk away', function(p) end }

    if fieldOwn then
        player:printToPlayer(
            string.format('[Derby] * marks your own bird, %s - home wins pay +%d%%!',
                fieldOwn.name, catalog.ownBird.winBonusPct),
            xi.msg.channel.SYSTEM_3)
    end

    sendMenu(player, string.format('Field - %dk', math.floor(bet / 1000)), options)
end

m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', catalog.npcPos.zone), function(zone)
    super(zone)
    local caller = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Race_Caller',
        packetName = string.format('%sRace Caller', xi.icon.STAR_LARGE),
        look       = 162,
        x = catalog.npcPos.x, y = catalog.npcPos.y, z = catalog.npcPos.z,
        rotation   = catalog.npcPos.rotation,
        widescan   = 1,
        onTrigger  = function(player, npc)
            local races  = player:getCharVar('Derby_Races')  or 0
            local wins   = player:getCharVar('Derby_Wins')   or 0
            local profit = player:getCharVar('Derby_Profit') or 0
            player:printToPlayer(string.format(
                '[Race Caller] Welcome to the Derby! Your card: %d races, %d wins, %s%d gil lifetime.',
                races, wins, profit >= 0 and '+' or '', profit),
                xi.msg.channel.SYSTEM_3)
            if ownBirdRunner(player) then
                player:printToPlayer(
                    '[Race Caller] Your raised chocobo is fit to race - look for (YOURS) on the card. Home wins pay a bonus!',
                    xi.msg.channel.SYSTEM_3)
            end

            local options = {}
            for _, bet in ipairs(catalog.bets) do
                local b = bet
                options[#options + 1] = {
                    string.format('Race - %dk gil ticket', math.floor(b / 1000)),
                    function(p) showRunnerMenu(p, b) end,
                }
            end
            options[#options + 1] = { 'How does the Derby work?', function(p)
                p:printToPlayer('[Derby] Pick a ticket, back a runner at the listed odds, and the call begins. Raise a chocobo (Chocobo Raising) and field it yourself - its strength and endurance set its odds, and home wins pay +25%. The house always keeps its cut, kupo.',
                    xi.msg.channel.SYSTEM_3)
            end }
            options[#options + 1] = { 'Close', function(p) end }

            sendMenu(player, 'Race Caller', options)
        end,
    })
    utils.unused(caller)
end)

return m
