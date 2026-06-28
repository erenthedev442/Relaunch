-----------------------------------
-- Ambuscade
-- Gorpa-Masorpa (reward shop)  : !pos -27.584 -15.990 52.565 249
-- Ambuscade Tome  (entry)      : !pos -28.030 -15.500 52.279 249
-- Voucher Clerk   (gear)       : !pos -26.600 -15.990 52.565 249
-- Instance 30000 : zone 287 (Maquette_Abdhaljs-Legion_B), 30-min limit
--
-- Three modes: Intense (1-5), Regular (6-10), Light (11-15).
-- Freely repeatable; no key-item gate.
-- Monthly Hallmark cap: 45,000 HM per calendar month.
-- Time bonus: up to +50% on sub-5-minute clears.
-- Party scaling: +50% Breadwinner HP per extra party member (handled at engage).
-----------------------------------
xi = xi or {}
xi.ambuscade = {}

local SYS = xi.msg.channel.SYSTEM_3

-- ─── Difficulty tables ────────────────────────────────────────────────────────
local DIFF_NAME =
{
    [1]='Intense VD', [2]='Intense D',  [3]='Intense N',  [4]='Intense E',  [5]='Intense VE',
    [6]='Regular VD', [7]='Regular D',  [8]='Regular N',  [9]='Regular E',  [10]='Regular VE',
    [11]='Light VD',  [12]='Light D',   [13]='Light N',   [14]='Light E',   [15]='Light VE',
}

-- Base hallmarks awarded on clear (subject to monthly cap + time bonus).
local HALLMARKS =
{
    [1]=3600, [2]=2400, [3]=1200, [4]=800,  [5]=400,   -- Intense
    [6]=600,  [7]=500,  [8]=400,  [9]=300,  [10]=200,  -- Regular
    [11]=150, [12]=125, [13]=100, [14]=75,  [15]=50,   -- Light
}

-- Gallantry awarded per extra party member beyond solo.
local GALLANTRY_PER_EXTRA =
{
    [1]=300, [2]=240, [3]=180, [4]=80,  [5]=20,
    [6]=30,  [7]=25,  [8]=20,  [9]=15,  [10]=10,
    [11]=5,  [12]=4,  [13]=3,  [14]=2,  [15]=1,
}

local MONTHLY_HM_CAP = 45000  -- resets each calendar month

-- ─── Time bonus ───────────────────────────────────────────────────────────────
-- elapsed = seconds used (from onInstanceTimeUpdate when all mobs die).
local function calcTimeBonus(elapsed)
    elapsed = elapsed or 9999
    if elapsed <= 300  then return 1.5 end  -- ≤ 5 min used  → +50%
    if elapsed <= 600  then return 1.3 end  -- ≤ 10 min used → +30%
    if elapsed <= 900  then return 1.2 end  -- ≤ 15 min used → +20%
    if elapsed <= 1200 then return 1.1 end  -- ≤ 20 min used → +10%
    return 1.0
end

-- ─── Monthly cap helper ───────────────────────────────────────────────────────
local function applyMonthlyCapAndEarn(player, rawHM)
    local now      = os.date('*t')
    local curMonth = now.month
    local curYear  = now.year - 2000  -- store 2-digit year in charVar (fits int)

    local savedMonth = player:getCharVar('Amb_Cap_Month')
    local savedYear  = player:getCharVar('Amb_Cap_Year')
    local earnedSoFar = player:getCharVar('Amb_HM_Earned')

    if savedMonth ~= curMonth or savedYear ~= curYear then
        -- New calendar month: reset counter.
        player:setCharVar('Amb_Cap_Month',  curMonth)
        player:setCharVar('Amb_Cap_Year',   curYear)
        player:setCharVar('Amb_HM_Earned',  0)
        earnedSoFar = 0
    end

    local remaining = math.max(0, MONTHLY_HM_CAP - earnedSoFar)
    local actual    = math.min(rawHM, remaining)
    player:setCharVar('Amb_HM_Earned', earnedSoFar + actual)
    return actual, remaining - actual  -- (earned, remaining_after)
end

-- ─── Hallmark shop ────────────────────────────────────────────────────────────
-- { itemId, shortLabel, hallmarkCost }
local HM_SHOP =
{
    -- Abdhaljs weapon / armor upgrade materials
    { 9270, 'Metal',     100  },
    { 9271, 'Fiber',     100  },
    { 9782, 'Nugget',    300  },
    { 9783, 'Gem',       500  },
    { 9784, 'Anima',     800  },
    { 9785, 'Matter',    1200 },
    -- Cape upgrade materials
    { 9220, 'Thread',    100  },
    { 9221, 'Dust',      100  },
    { 9223, 'Sap',       200  },
    { 9222, 'Dye',       800  },
    { 9224, 'Resin',     1500 },
    -- Gear vouchers
    { 9235, 'Vou.Head',  3000 },
    { 9236, 'Vou.Body',  5000 },
    { 9237, 'Vou.Hands', 3000 },
    { 9238, 'Vou.Legs',  5000 },
    { 9239, 'Vou.Feet',  3000 },
    { 9240, 'Vou.Hd+1',  5000 },
    { 9241, 'Vou.Bd+1',  8000 },
    { 9242, 'Vou.Hnd+1', 5000 },
    { 9243, 'Vou.Lg+1',  8000 },
    { 9244, 'Vou.Ft+1',  5000 },
}

-- ─── Gallantry shop ───────────────────────────────────────────────────────────
local GAL_SHOP =
{
    { 739,  'Hi-Potion',   200  },
    { 771,  'Hi-Ether',    300  },
    { 833,  'Vile Elixir', 2000 },
    { 4327, 'Echo Drops',  50   },
    { 4312, 'Antidote',    50   },
}

local SHOP_PER_PAGE = 6

local function buildShopMenu(player, items, currency, page, backFn)
    page = page or 0
    local pages = math.max(1, math.ceil(#items / SHOP_PER_PAGE))
    page = page % pages
    local bal   = player:getCurrency(currency)
    local options = {}

    for i = page * SHOP_PER_PAGE + 1, math.min((page + 1) * SHOP_PER_PAGE, #items) do
        local idx  = i
        local item = items[idx]
        local cost = item[3]
        options[#options + 1] =
        {
            string.format('%s (%d)', item[2], cost),
            function(pp)
                local b = pp:getCurrency(currency)
                if b < cost then
                    pp:printToPlayer(string.format('[Ambuscade] Need %d (have %d).', cost, b), SYS)
                    buildShopMenu(pp, items, currency, page, backFn)
                    return
                end
                if pp:getFreeSlotsCount() < 1 then
                    pp:printToPlayer('[Ambuscade] Inventory full.', SYS)
                    buildShopMenu(pp, items, currency, page, backFn)
                    return
                end
                pp:delCurrency(currency, cost)
                pp:addItem(item[1], 1)
                pp:printToPlayer(string.format('[Ambuscade] Received %s. Balance: %d.',
                    item[2], pp:getCurrency(currency)), SYS)
                buildShopMenu(pp, items, currency, page, backFn)
            end,
        }
    end

    if pages > 1 then
        options[#options + 1] = { 'More >>', function(pp) buildShopMenu(pp, items, currency, page + 1, backFn) end }
    end
    options[#options + 1] = { 'Back', backFn }

    local title = string.format('Bal: %d', bal)
    local snapshot = { title = title, options = options }
    player:timer(30, function(pp) pp:customMenu(snapshot) end)
end

local function showGorpaMain(player)
    local hm  = player:getCurrency('current_hallmarks')
    local gal = player:getCurrency('gallantry')
    local options =
    {
        {
            string.format('HM Shop [%dHM]', hm),
            function(pp) buildShopMenu(pp, HM_SHOP, 'current_hallmarks', 0, function(p) showGorpaMain(p) end) end,
        },
        {
            string.format('Gal Shop [%dG]', gal),
            function(pp) buildShopMenu(pp, GAL_SHOP, 'gallantry', 0, function(p) showGorpaMain(p) end) end,
        },
        { 'Leave', function(pp) end },
    }
    local snapshot = { title = 'Gorpa-Masorpa', options = options }
    player:timer(30, function(pp) pp:customMenu(snapshot) end)
end

-- ─── Gorpa-Masorpa ────────────────────────────────────────────────────────────
xi.ambuscade.onTradeGorpaMasorpa = function(player, npc, trade)
end

xi.ambuscade.onTriggerGorpaMasorpa = function(player, npc)
    if not player:getEminenceCompleted(499) then
        xi.roe.onRecordTrigger(player, 499)
    end
    local hm  = player:getCurrency('current_hallmarks')
    local gal = player:getCurrency('gallantry')
    local cap = player:getCharVar('Amb_HM_Earned')
    player:printToPlayer(string.format(
        '[Ambuscade] Hallmarks: %d  |  Gallantry: %d  |  This month: %d/%d HM',
        hm, gal, cap, MONTHLY_HM_CAP), SYS)
    showGorpaMain(player)
end

xi.ambuscade.onEventUpdateGorpaMasorpa = function(player, csid, option, npc)
end

xi.ambuscade.onEventFinishGorpaMasorpa = function(player, csid, option, npc)
end

-- ─── Ambuscade Tome ───────────────────────────────────────────────────────────
local function enterAmbuscade(player, diffOption)
    player:setCharVar('Ambuscade_Difficulty', diffOption)
    player:createInstance(30000)
    player:printToPlayer(string.format('[Ambuscade] Entering %s. Good luck!', DIFF_NAME[diffOption]), SYS)
end

local INTENSE_DIFFS =
{
    { 1,  'VD (+3600HM)' }, { 2,  'D  (+2400HM)' }, { 3,  'N  (+1200HM)' },
    { 4,  'E  (+800HM)'  }, { 5,  'VE (+400HM)'  },
}
local REGULAR_DIFFS =
{
    { 6,  'VD (+600HM)'  }, { 7,  'D  (+500HM)'  }, { 8,  'N  (+400HM)'  },
    { 9,  'E  (+300HM)'  }, { 10, 'VE (+200HM)'  },
}
local LIGHT_DIFFS =
{
    { 11, 'VD (+150HM)'  }, { 12, 'D  (+125HM)'  }, { 13, 'N  (+100HM)'  },
    { 14, 'E  (+75HM)'   }, { 15, 'VE (+50HM)'   },
}

local function showDiffMenu(player, list, title, backFn)
    local options = {}
    for _, d in ipairs(list) do
        local opt   = d[1]
        local label = d[2]
        options[#options + 1] = { label, function(pp) enterAmbuscade(pp, opt) end }
    end
    options[#options + 1] = { 'Back', backFn }
    local snapshot = { title = title, options = options }
    player:timer(30, function(pp) pp:customMenu(snapshot) end)
end

local function showTomeMenu(player)
    local options =
    {
        {
            'Intense Ambuscade',
            function(pp) showDiffMenu(pp, INTENSE_DIFFS, 'Intense', function(p) showTomeMenu(p) end) end,
        },
        {
            'Regular Ambuscade',
            function(pp) showDiffMenu(pp, REGULAR_DIFFS, 'Regular', function(p) showTomeMenu(p) end) end,
        },
        {
            'Light Ambuscade',
            function(pp) showDiffMenu(pp, LIGHT_DIFFS, 'Light', function(p) showTomeMenu(p) end) end,
        },
        { 'Leave', function(pp) end },
    }
    local snapshot = { title = 'Ambuscade Tome', options = options }
    player:timer(30, function(pp) pp:customMenu(snapshot) end)
end

xi.ambuscade.onTradeTome = function(player, npc, trade)
end

xi.ambuscade.onTriggerTome = function(player, npc)
    showTomeMenu(player)
end

xi.ambuscade.onEventUpdateTome = function(player, csid, option, npc)
end

xi.ambuscade.onEventFinishTome = function(player, csid, option, npc)
end

-- ─── Instance rewards ─────────────────────────────────────────────────────────
xi.ambuscade.onInstanceComplete = function(instance)
    local chars      = instance:getChars()
    local numChars   = math.max(1, #chars)
    local difficulty = instance:getProgress()
    if not HALLMARKS[difficulty] then difficulty = 10 end

    local baseHM    = HALLMARKS[difficulty]
    local galBase   = GALLANTRY_PER_EXTRA[difficulty]
    -- Gallantry: 1× per extra party member (solo = 0 gallantry bonus)
    local galEarned = galBase * math.max(0, numChars - 1)

    for _, player in pairs(chars) do
        -- Time bonus (stored in charVar by onInstanceTimeUpdate).
        local elapsed    = player:getCharVar('Ambuscade_Clear_Time')
        local timeMult   = calcTimeBonus(elapsed)
        local rawHM      = math.floor(baseHM * timeMult)
        local actualHM, remaining = applyMonthlyCapAndEarn(player, rawHM)

        player:addCurrency('current_hallmarks', actualHM)
        player:addCurrency('total_hallmarks',   actualHM)
        if galEarned > 0 then
            player:addCurrency('gallantry', galEarned)
        end

        -- Increment RoE clear record.
        xi.roe.onRecordTrigger(player, 499)

        local bonusStr = timeMult > 1.0 and string.format(' (×%.1f time bonus)', timeMult) or ''
        if actualHM < rawHM then
            player:printToPlayer(string.format(
                '[Ambuscade] Victory! +%d HM%s (monthly cap: %d/%d). +%d Gallantry.',
                actualHM, bonusStr, MONTHLY_HM_CAP - remaining, MONTHLY_HM_CAP, galEarned), SYS)
        else
            player:printToPlayer(string.format(
                '[Ambuscade] Victory! +%d HM%s. Total: %d HM. +%d Gallantry.',
                actualHM, bonusStr, player:getCurrency('current_hallmarks'), galEarned), SYS)
        end

        player:startEvent(10001)
    end
end

xi.ambuscade.onInstanceFailure = function(instance)
    local chars = instance:getChars()
    for _, player in pairs(chars) do
        player:printToPlayer('[Ambuscade] Time limit reached. Your effort is not forgotten.', SYS)
        player:startEvent(10001)
    end
end

-- ─── Stats helper (called by !ambuscade command) ───────────────────────────────
xi.ambuscade.printStats = function(player)
    local hm      = player:getCurrency('current_hallmarks')
    local total   = player:getCurrency('total_hallmarks')
    local gal     = player:getCurrency('gallantry')
    local monthly = player:getCharVar('Amb_HM_Earned')
    player:printToPlayer(string.format(
        '[Ambuscade] Current HM: %d  |  Total HM: %d  |  Gallantry: %d  |  This month: %d/%d HM',
        hm, total, gal, monthly, MONTHLY_HM_CAP), SYS)
end
