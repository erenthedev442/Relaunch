-----------------------------------
-- Ambuscade
-- Gorpa-Masorpa (reward shop) : !pos -27.584 -15.990 52.565 249
-- Ambuscade Tome  (entry)     : !pos -28.030 -15.500 52.279 249
-- Instance 30000 : zone 287 (Maquette_Abdhaljs-Legion_B), 30-min limit
--
-- Freely repeatable. No key-item gate. Both Intense and Regular modes.
-- Hallmarks and Gallantry scale with difficulty + party size.
-- Spend Hallmarks at Gorpa-Masorpa for Abdhaljs materials and gear vouchers.
-----------------------------------
xi = xi or {}
xi.ambuscade = {}

local SYS = xi.msg.channel.SYSTEM_3

-- ─── Difficulty tables ────────────────────────────────────────────────────────
-- Options 1-5 = Intense (VD→VE), 6-10 = Regular (VD→VE)
local DIFF_NAME =
{
    [1]  = 'Intense VD', [2]  = 'Intense D',  [3]  = 'Intense N',
    [4]  = 'Intense E',  [5]  = 'Intense VE',
    [6]  = 'Regular VD', [7]  = 'Regular D',  [8]  = 'Regular N',
    [9]  = 'Regular E',  [10] = 'Regular VE',
}

-- Hallmarks earned on clear (flat per player, independent of party size)
local HALLMARKS =
{
    [1]=3600, [2]=2400, [3]=1200, [4]=800,  [5]=400,
    [6]=600,  [7]=500,  [8]=400,  [9]=300,  [10]=200,
}

-- Gallantry per additional party member beyond solo
local GALLANTRY_PER_EXTRA =
{
    [1]=300, [2]=240, [3]=180, [4]=80,  [5]=20,
    [6]=30,  [7]=25,  [8]=20,  [9]=15,  [10]=10,
}

-- Mob HP multiplier applied to the base spawn HP
local HP_SCALE =
{
    [1]=5.0, [2]=3.5, [3]=2.5, [4]=1.8, [5]=1.0,
    [6]=4.0, [7]=2.8, [8]=2.0, [9]=1.5, [10]=1.0,
}

-- ─── Shop catalog ─────────────────────────────────────────────────────────────
-- { itemId, shortLabel, hallmarkCost }
-- Labels must keep total bytes/page (title + all labels + nav) <= 150.
local SHOP_ITEMS =
{
    -- Abdhaljs weapon / armor upgrade materials (Relic/Empyrean paths)
    { 9270, 'Metal',     100  },   -- vial of abdhaljs metal
    { 9271, 'Fiber',     100  },   -- loop of abdhaljs fiber
    { 9782, 'Nugget',    300  },   -- abdhaljs nugget
    { 9783, 'Gem',       500  },   -- abdhaljs gem
    { 9784, 'Anima',     800  },   -- abdhaljs anima
    { 9785, 'Matter',    1200 },   -- chunk of abdhaljs matter
    -- Cape upgrade materials
    { 9220, 'Thread',    100  },   -- spool of abdhaljs thread
    { 9221, 'Dust',      100  },   -- pinch of abdhaljs dust
    { 9223, 'Sap',       200  },   -- bottle of abdhaljs sap
    { 9222, 'Dye',       800  },   -- pot of abdhaljs dye
    { 9224, 'Resin',     1500 },   -- container of abdhaljs resin
    -- Ambuscade gear vouchers (redeem at Gorpa for job-specific armor)
    { 9235, 'Vou.Head',  3000 },
    { 9236, 'Vou.Body',  5000 },
    { 9237, 'Vou.Hands', 3000 },
    { 9238, 'Vou.Legs',  5000 },
    { 9239, 'Vou.Feet',  3000 },
    -- +1 vouchers
    { 9240, 'Vou.Hd+1',  5000 },
    { 9241, 'Vou.Bd+1',  8000 },
    { 9242, 'Vou.Hnd+1', 5000 },
    { 9243, 'Vou.Lg+1',  8000 },
    { 9244, 'Vou.Ft+1',  5000 },
}

local SHOP_PER_PAGE = 6

local function showShop(player, page)
    page = page or 0
    local pages = math.max(1, math.ceil(#SHOP_ITEMS / SHOP_PER_PAGE))
    page = page % pages
    local hm  = player:getCurrency('current_hallmarks')
    local options = {}
    for i = page * SHOP_PER_PAGE + 1, math.min((page + 1) * SHOP_PER_PAGE, #SHOP_ITEMS) do
        local idx  = i
        local item = SHOP_ITEMS[idx]
        local cost = item[3]
        local label = string.format('%s (%dHM)', item[2], cost)
        options[#options + 1] =
        {
            label,
            function(pp)
                local bal = pp:getCurrency('current_hallmarks')
                if bal < cost then
                    pp:printToPlayer(string.format('[Ambuscade] Need %d HM (have %d).', cost, bal), SYS)
                    showShop(pp, page)
                    return
                end
                if pp:getFreeSlotsCount() < 1 then
                    pp:printToPlayer('[Ambuscade] Inventory is full.', SYS)
                    showShop(pp, page)
                    return
                end
                pp:delCurrency('current_hallmarks', cost)
                pp:addItem(item[1], 1)
                pp:printToPlayer(string.format('[Ambuscade] Received %s. Balance: %d HM.',
                    item[2], pp:getCurrency('current_hallmarks')), SYS)
                showShop(pp, page)
            end,
        }
    end
    if pages > 1 then
        options[#options + 1] = { 'More >>', function(pp) showShop(pp, page + 1) end }
    end
    options[#options + 1] = { 'Leave', function(pp) end }
    local snapshot = { title = string.format('Shop [%dHM]', hm), options = options }
    player:timer(30, function(pp) pp:customMenu(snapshot) end)
end

-- ─── Gorpa-Masorpa ────────────────────────────────────────────────────────────
xi.ambuscade.onTradeGorpaMasorpa = function(player, npc, trade)
end

xi.ambuscade.onTriggerGorpaMasorpa = function(player, npc)
    -- Auto-complete the RoE intro on first visit so no manual RoE setup is needed.
    if not player:getEminenceCompleted(499) then
        xi.roe.onRecordTrigger(player, 499)
    end
    local hm  = player:getCurrency('current_hallmarks')
    local gal = player:getCurrency('gallantry')
    player:printToPlayer(string.format('[Ambuscade] Hallmarks: %d  |  Gallantry: %d', hm, gal), SYS)
    showShop(player)
end

xi.ambuscade.onEventUpdateGorpaMasorpa = function(player, csid, option, npc)
end

xi.ambuscade.onEventFinishGorpaMasorpa = function(player, csid, option, npc)
end

-- ─── Ambuscade Tome ───────────────────────────────────────────────────────────
local function enterAmbuscade(player, diffOption)
    player:setCharVar('Ambuscade_Difficulty', diffOption)
    player:createInstance(30000)
    player:printToPlayer(string.format('[Ambuscade] Entering %s. The battle begins!', DIFF_NAME[diffOption]), SYS)
end

-- Displayed in the difficulty sub-menus (shows hallmark reward for quick reference)
local INTENSE_DIFFS =
{
    { 1, 'VD  (+3600HM)' }, { 2, 'D   (+2400HM)' }, { 3, 'N   (+1200HM)' },
    { 4, 'E   (+800HM)'  }, { 5, 'VE  (+400HM)'  },
}
local REGULAR_DIFFS =
{
    { 6,  'VD  (+600HM)'  }, { 7,  'D   (+500HM)'  }, { 8,  'N   (+400HM)'  },
    { 9,  'E   (+300HM)'  }, { 10, 'VE  (+200HM)'  },
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
            function(pp)
                showDiffMenu(pp, INTENSE_DIFFS, 'Intense Ambuscade', function(p) showTomeMenu(p) end)
            end,
        },
        {
            'Regular Ambuscade',
            function(pp)
                showDiffMenu(pp, REGULAR_DIFFS, 'Regular Ambuscade', function(p) showTomeMenu(p) end)
            end,
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
    if not HALLMARKS[difficulty] then difficulty = 10 end  -- failsafe: Regular VE

    local hmEarned  = HALLMARKS[difficulty]
    -- Gallantry: solo = 1× base, each extra party member adds another base amount.
    local galBase   = GALLANTRY_PER_EXTRA[difficulty]
    local galEarned = galBase * math.max(1, numChars - 1)

    for _, player in pairs(chars) do
        player:addCurrency('current_hallmarks', hmEarned)
        player:addCurrency('total_hallmarks',   hmEarned)
        player:addCurrency('gallantry',         galEarned)
        player:printToPlayer(string.format(
            '[Ambuscade] Victory! +%d Hallmarks, +%d Gallantry. Total: %d HM.',
            hmEarned, galEarned, player:getCurrency('current_hallmarks')), SYS)
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
