-----------------------------------
-- Ambuscade
-- Gorpa-Masorpa (reward shop)  : !pos -27.584 -15.990 52.565 249
-- Ambuscade Tome  (entry)      : !pos -28.030 -15.500 52.279 249
-- Voucher Clerk   (gear)       : !pos -26.600 -15.990 52.565 249
-- Instance 30000 : zone 287 (Maquette_Abdhaljs-Legion_B), 30-min limit
--
-- Three modes: Intense (1-5), Regular (6-10), Light (11-15).
-- Freely repeatable; no key-item gate.
-- Monthly Hallmark cap: 200,000 HM per calendar month.
-- Time bonus: up to +50% on sub-5-minute clears.
-- Party scaling: +50% Breadwinner HP per extra party member (handled at engage).
-----------------------------------
xi = xi or {}
xi.ambuscade = {}

local SYS = xi.msg.channel.SYSTEM_3

-- Retail-faithful Ambuscade weapon upgrade chain (Tokko->Ajja->Eletta->Kaja->Final).
-- LAZY-loaded on first "Weapons" menu click (see showGorpaMain), NOT at globals
-- init: this is a cross-tree require of a modules/custom data file, and deferring
-- it means a missing/broken catalog can never fail the whole ambuscade.lua load.
local AMBU_WPN
local AMBU_COSMETICS

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

local MONTHLY_HM_CAP = 200000  -- resets each calendar month (owner rebalance 2026-07-13: was 75000)

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
    -- Ambuscade set rings (retail set-completion rewards; one per armor set).
    -- Added 2026-07-12: the sets' rings had no source anywhere on the server.
    { 26204, "Sulevia's Ring", 4000 },
    { 26205, 'Meghanada Ring', 4000 },
    { 26206, 'Hizamaru Ring',  4000 },
    { 26207, 'Inyanga Ring',   4000 },
    { 26208, 'Jhakri Ring',    4000 },
    { 26209, 'Ayanmo Ring',    4000 },
    { 26210, 'Taliah Ring',    4000 },
    { 26211, 'Flamma Ring',    4000 },
    { 26212, 'Mummu Ring',     4000 },
    { 26213, 'Mallquis Ring',  4000 },
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

-- ─── Ambuscade armor ──────────────────────────────────────────────────────────
-- The two retail Ambuscade armor lines (item IDs verified against
-- sql/item_basic.sql). Each set: { head, body, hands, legs, feet }.
--   Line 1 "Salvage variant"     -- redeemed with Ambuscade Vouchers at the
--                                   Voucher Clerk; upgrades with Abdhaljs METAL.
--   Line 2 "Limbus/Nyzul variant" -- redeemed with the SAME vouchers (this
--                                   server has no second voucher currency);
--                                   upgrades with Abdhaljs FIBER.
-- Upgrades happen by TRADE to Gorpa-Masorpa (onTradeGorpaMasorpa below):
--   NQ piece + 5x material  -> +1
--   +1 piece + 10x material -> +2
local MAT_METAL = 9270  -- Abdhaljs Metal (sold in the Hallmark shop)
local MAT_FIBER = 9271  -- Abdhaljs Fiber (sold in the Hallmark shop)

local ARMOR_SETS =
{
    -- Line 1 (voucher line) -- upgrades with Metal
    sulevia   = { label = "Sulevia's",  mat = MAT_METAL, nq = { 25659, 25745, 25800, 25858, 25925 }, p1 = { 25660, 25746, 25801, 25859, 25926 }, p2 = { 25574, 25790, 25828, 25879, 25946 } },
    hizamaru  = { label = 'Hizamaru',   mat = MAT_METAL, nq = { 25663, 25749, 25804, 25862, 25929 }, p1 = { 25664, 25750, 25805, 25863, 25930 }, p2 = { 25576, 25792, 25830, 25881, 25948 } },
    inyanga   = { label = 'Inyanga',    mat = MAT_METAL, nq = { 25665, 25751, 25806, 25865, 25931 }, p1 = { 25666, 25752, 25807, 25866, 25932 }, p2 = { 25577, 25793, 25831, 25882, 25949 } },
    meghanada = { label = 'Meghanada',  mat = MAT_METAL, nq = { 25661, 25747, 25802, 25860, 25927 }, p1 = { 25662, 25748, 25803, 25861, 25928 }, p2 = { 25575, 25791, 25829, 25880, 25947 } },
    jhakri    = { label = 'Jhakri',     mat = MAT_METAL, nq = { 25667, 25753, 25808, 25867, 25933 }, p1 = { 25668, 25754, 25809, 25868, 25934 }, p2 = { 25578, 25794, 25832, 25883, 25950 } },
    -- Line 2 (alt line) -- upgrades with Fiber
    flamma    = { label = 'Flamma',     mat = MAT_FIBER, nq = { 25579, 25779, 25818, 25873, 25940 }, p1 = { 25580, 25780, 25819, 25874, 25941 }, p2 = { 25569, 25797, 25835, 25886, 25953 } },
    taliah    = { label = "Tali'ah",    mat = MAT_FIBER, nq = { 25590, 25764, 25812, 25871, 25937 }, p1 = { 25591, 25765, 25813, 25872, 25938 }, p2 = { 25573, 25796, 25834, 25885, 25952 } },
    mummu     = { label = 'Mummu',      mat = MAT_FIBER, nq = { 25581, 25781, 25820, 25875, 25942 }, p1 = { 25582, 25782, 25821, 25876, 25943 }, p2 = { 25570, 25798, 25836, 25887, 25954 } },
    ayanmo    = { label = 'Ayanmo',     mat = MAT_FIBER, nq = { 25588, 25762, 25810, 25869, 25935 }, p1 = { 25589, 25763, 25811, 25870, 25936 }, p2 = { 25572, 25795, 25833, 25884, 25951 } },
    mallquis  = { label = 'Mallquis',   mat = MAT_FIBER, nq = { 25583, 25783, 25822, 25877, 25944 }, p1 = { 25584, 25784, 25823, 25878, 25945 }, p2 = { 25571, 25799, 25837, 25888, 25955 } },
}

-- Which set each job gets, per line (retail job coverage -- every one of the
-- 22 jobs appears exactly once in each line).
local JOB_SETS =
{
    [xi.job.WAR] = { line1 = 'sulevia',   line2 = 'flamma'   },
    [xi.job.MNK] = { line1 = 'hizamaru',  line2 = 'mummu'    },
    [xi.job.WHM] = { line1 = 'inyanga',   line2 = 'ayanmo'   },
    [xi.job.BLM] = { line1 = 'jhakri',    line2 = 'mallquis' },
    [xi.job.RDM] = { line1 = 'jhakri',    line2 = 'ayanmo'   },
    [xi.job.THF] = { line1 = 'meghanada', line2 = 'mummu'    },
    [xi.job.PLD] = { line1 = 'sulevia',   line2 = 'flamma'   },
    [xi.job.DRK] = { line1 = 'sulevia',   line2 = 'flamma'   },
    [xi.job.BST] = { line1 = 'meghanada', line2 = 'taliah'   },
    [xi.job.BRD] = { line1 = 'inyanga',   line2 = 'ayanmo'   },
    [xi.job.RNG] = { line1 = 'meghanada', line2 = 'mummu'    },
    [xi.job.SAM] = { line1 = 'hizamaru',  line2 = 'flamma'   },
    [xi.job.NIN] = { line1 = 'hizamaru',  line2 = 'mummu'    },
    [xi.job.DRG] = { line1 = 'sulevia',   line2 = 'flamma'   },
    [xi.job.SMN] = { line1 = 'inyanga',   line2 = 'taliah'   },
    [xi.job.BLU] = { line1 = 'jhakri',    line2 = 'ayanmo'   },
    [xi.job.COR] = { line1 = 'meghanada', line2 = 'mummu'    },
    [xi.job.PUP] = { line1 = 'hizamaru',  line2 = 'taliah'   },
    [xi.job.DNC] = { line1 = 'meghanada', line2 = 'mummu'    },
    [xi.job.SCH] = { line1 = 'jhakri',    line2 = 'mallquis' },
    [xi.job.GEO] = { line1 = 'jhakri',    line2 = 'mallquis' },
    [xi.job.RUN] = { line1 = 'meghanada', line2 = 'ayanmo'   },
}

-- Exposed for the Voucher Clerk (scripts/zones/Mhaura/npcs/Ambuscade_Voucher_Clerk.lua).
xi.ambuscade.armorSets = ARMOR_SETS
xi.ambuscade.jobSets   = JOB_SETS

-- itemId -> { result, mat, qty } upgrade map, built once at load.
local UPGRADES = {}
for _, set in pairs(ARMOR_SETS) do
    for i = 1, 5 do
        UPGRADES[set.nq[i]] = { result = set.p1[i], mat = set.mat, qty = 5  }
        UPGRADES[set.p1[i]] = { result = set.p2[i], mat = set.mat, qty = 10 }
    end
end

-- ─── Gallantry shop ───────────────────────────────────────────────────────────
local GAL_SHOP =
{
    -- Endgame sink: the Pulse Cell is the extra item consumed by the final
    -- Ambuscade weapon upgrade (Kaja -> Final). Selling it for Gallantry gives
    -- that currency a real purpose and keeps the weapon path self-contained.
    { 3840, 'Pulse Cell',  3000 },
    { 739,  'Hi-Potion',   200  },
    { 771,  'Hi-Ether',    300  },
    { 833,  'Vile Elixir', 2000 },
    { 4327, 'Echo Drops',  50   },
    { 4312, 'Antidote',    50   },
}

-- ─── Abdhaljs Seal ────────────────────────────────────────────────────────────
-- Item 6500 (usable, stacks to 99). Holding one when you clear a PARTY run
-- (which is the only kind that pays Gallantry -- solo pays 0) auto-consumes it
-- and triples that run's Gallantry. Because it only fires when Gallantry > 0 it
-- can never be wasted on a solo clear. Two sources, mirroring retail: buy one
-- per calendar month for Hallmarks, plus claim SEAL_WEEKLY free per week.
local SEAL_ITEM    = 6500
local SEAL_HM_COST = 2000   -- monthly merchant price
local SEAL_WEEKLY  = 2      -- free seals claimable per calendar week

local function sealMonthKey()
    local t = os.date('*t')
    return t.month, t.year - 2000        -- 2-digit year fits an int charVar
end

local function sealWeekKey()
    local t = os.date('*t')
    return (t.year - 2000) * 53 + math.ceil(t.yday / 7)  -- ~7-day bucket, rolls at year end
end

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

-- ─── Ambuscade weapons (Tokko -> Ajja -> Eletta -> Kaja -> Final) ─────────────
local showWeaponMain  -- fwd decl

-- Redeem a BASE (Tokko) weapon of your choice for Hallmarks.
-- Page size 4 (not SHOP_PER_PAGE=6): the descriptive labels ("Polearm (Shining
-- One)" etc.) would blow the 150-byte per-menu customMenu cap at 6/page.
local WPN_PER_PAGE = 4
local function buildWeaponBaseMenu(player, page, backFn)
    page = page or 0
    local chains = AMBU_WPN.CHAINS
    local pages  = math.max(1, math.ceil(#chains / WPN_PER_PAGE))
    page = page % pages
    local options = {}
    for i = page * WPN_PER_PAGE + 1, math.min((page + 1) * WPN_PER_PAGE, #chains) do
        local chain = chains[i]
        options[#options + 1] =
        {
            chain.label,
            function(pp)
                local cost   = AMBU_WPN.BASE_HM_COST
                local baseId = chain.stages[1]
                if pp:getCurrency('current_hallmarks') < cost then
                    pp:printToPlayer(string.format('[Ambuscade] Need %d Hallmarks (have %d).',
                        cost, pp:getCurrency('current_hallmarks')), SYS)
                elseif pp:hasItem(baseId) then
                    -- RARE: a copy ANYWHERE (equipment/wardrobes, safe, storage,
                    -- locker, satchel, sack, case) blocks a second -- including a
                    -- Prime forge Stage I weapon of the same type (same item id).
                    pp:printToPlayer('[Ambuscade] You already own that base weapon (RARE) -- check equipment, wardrobes, safe, storage, satchel, sack, and case.', SYS)
                    pp:printToPlayer('[Ambuscade] Note: a Prime forge Stage I weapon of the same type IS this item.', SYS)
                elseif pp:getFreeSlotsCount() < 1 then
                    pp:printToPlayer('[Ambuscade] Inventory full.', SYS)
                elseif pp:addItem(baseId, 1) then  -- Tokko (base)
                    -- Charge only AFTER the item lands: addItem fails on the RARE
                    -- check, and the old charge-first order ate the Hallmarks anyway.
                    pp:delCurrency('current_hallmarks', cost)
                    pp:printToPlayer(string.format('[Ambuscade] Received base %s. Upgrade it with Abdhaljs materials.',
                        chain.label), SYS)
                else
                    pp:printToPlayer('[Ambuscade] Could not hand over the weapon. No Hallmarks were taken.', SYS)
                end
                buildWeaponBaseMenu(pp, page, backFn)
            end,
        }
    end
    if pages > 1 then
        options[#options + 1] = { 'More >>', function(pp) buildWeaponBaseMenu(pp, page + 1, backFn) end }
    end
    options[#options + 1] = { 'Back', backFn }
    local snapshot = { title = string.format('Base Weapon [%dHM]', AMBU_WPN.BASE_HM_COST), options = options }
    player:timer(30, function(pp) pp:customMenu(snapshot) end)
end

-- Upgrade a weapon the player already holds (scan inventory for any Ambuscade
-- weapon at stage 1..4 -> offer the next stage for its material cost).
local function buildWeaponUpgradeMenu(player, backFn)
    local options = {}
    for _, chain in ipairs(AMBU_WPN.CHAINS) do
        for stage = 1, 4 do
            local fromId = chain.stages[stage]
            if player:hasItem(fromId, xi.inv.INVENTORY) then
                local rec     = AMBU_WPN.UPGRADE[stage]
                local toId    = chain.stages[stage + 1]
                local have    = player:getItemCount(rec.mat)
                local extraOk = not rec.extra or player:getItemCount(rec.extra.id) >= rec.extra.qty
                local ready   = have >= rec.qty and extraOk
                options[#options + 1] =
                {
                    -- Short to stay under the 150-byte menu cap with several weapons
                    -- held. e.g. "Naegling->Eletta OK" / "Naegling->Final 3/5 +P".
                    -- (The final step's "+P" flags the extra Pulse Cell; the exact
                    -- material name/qty are stated in the confirm + error messages.)
                    string.format('%s->%s %s%s',
                        chain.label:match('%((.-)%)') or chain.label,
                        AMBU_WPN.STAGE_NAME[stage + 1],
                        ready and 'OK' or string.format('%d/%d', have, rec.qty),
                        rec.extra and ' +P' or ''),
                    function(pp)
                        if not pp:hasItem(fromId, xi.inv.INVENTORY) then
                            pp:printToPlayer('[Ambuscade] Unequip the weapon and keep it in your main inventory.', SYS)
                        elseif pp:hasItem(toId) then
                            -- RARE: owning the next stage anywhere would make addItem
                            -- fail AFTER the materials + weapon were consumed.
                            pp:printToPlayer(string.format('[Ambuscade] You already own a %s-stage %s (RARE) -- it blocks this upgrade.',
                                AMBU_WPN.STAGE_NAME[stage + 1], chain.label:match('%((.-)%)') or chain.label), SYS)
                        elseif pp:getItemCount(rec.mat) < rec.qty then
                            pp:printToPlayer(string.format('[Ambuscade] Need %dx %s (have %d).',
                                rec.qty, AMBU_WPN.MAT_NAME[rec.mat], pp:getItemCount(rec.mat)), SYS)
                        elseif rec.extra and pp:getItemCount(rec.extra.id) < rec.extra.qty then
                            pp:printToPlayer(string.format('[Ambuscade] Final step also needs %dx %s (have %d) -- buy it in the Gal Shop.',
                                rec.extra.qty, rec.extra.name, pp:getItemCount(rec.extra.id)), SYS)
                        else
                            pp:delItem(rec.mat, rec.qty)
                            if rec.extra then pp:delItem(rec.extra.id, rec.extra.qty) end
                            pp:delItem(fromId, 1)
                            if pp:addItem(toId, 1) then
                                pp:printToPlayer(string.format('[Ambuscade] Upgraded to %s %s!',
                                    chain.label:match('%((.-)%)') or chain.label, AMBU_WPN.STAGE_NAME[stage + 1]), SYS)
                            else
                                -- Should be unreachable (RARE pre-checked, slot freed by
                                -- delItem) -- restore the consumed items if it ever isn't.
                                pp:addItem(fromId, 1)
                                pp:addItem(rec.mat, rec.qty)
                                if rec.extra then pp:addItem(rec.extra.id, rec.extra.qty) end
                                pp:printToPlayer('[Ambuscade] Upgrade failed -- your weapon and materials were returned.', SYS)
                            end
                        end
                        buildWeaponUpgradeMenu(pp, backFn)
                    end,
                }
            end
        end
    end
    if #options == 0 then
        options[#options + 1] = { '(no upgradeable weapon in bag)', function(pp) backFn(pp) end }
    end
    options[#options + 1] = { 'Back', backFn }
    -- Cap at 5 weapon rows + Back so the short labels stay under BOTH the 8-option
    -- and 150-byte customMenu caps even if a player holds many Ambuscade weapons.
    while #options > 6 do table.remove(options, 1) end
    local snapshot = { title = 'Upgrade Weapon', options = options }
    player:timer(30, function(pp) pp:customMenu(snapshot) end)
end

showWeaponMain = function(player, backFn)
    local options =
    {
        { string.format('Get Base Weapon [%dHM]', AMBU_WPN.BASE_HM_COST),
          function(pp) buildWeaponBaseMenu(pp, 0, function(p) showWeaponMain(p, backFn) end) end },
        { 'Upgrade a Weapon',
          function(pp) buildWeaponUpgradeMenu(pp, function(p) showWeaponMain(p, backFn) end) end },
        { 'Back', backFn },
    }
    local snapshot = { title = 'Ambuscade Weapons', options = options }
    player:timer(30, function(pp) pp:customMenu(snapshot) end)
end

-- Seal menu: buy one/month for Hallmarks + claim SEAL_WEEKLY free/week.
local function showSealMenu(player, backFn)
    local have    = player:getItemCount(SEAL_ITEM)
    local bMonth, bYear = sealMonthKey()
    local boughtThisMonth = player:getCharVar('Amb_Seal_BuyMonth') == bMonth
                        and player:getCharVar('Amb_Seal_BuyYear')  == bYear
    local claimedThisWeek = player:getCharVar('Amb_Seal_ClaimWeek') == sealWeekKey()

    local options =
    {
        {
            boughtThisMonth and 'Buy Seal (bought this month)'
                            or  string.format('Buy Seal [%dHM]', SEAL_HM_COST),
            function(pp)
                local m, y = sealMonthKey()
                if pp:getCharVar('Amb_Seal_BuyMonth') == m and pp:getCharVar('Amb_Seal_BuyYear') == y then
                    pp:printToPlayer('[Ambuscade] You have already bought your Seal this month.', SYS)
                elseif pp:getCurrency('current_hallmarks') < SEAL_HM_COST then
                    pp:printToPlayer(string.format('[Ambuscade] Need %d Hallmarks (have %d).',
                        SEAL_HM_COST, pp:getCurrency('current_hallmarks')), SYS)
                elseif pp:getItemCount(SEAL_ITEM) == 0 and pp:getFreeSlotsCount() < 1 then
                    pp:printToPlayer('[Ambuscade] Inventory full.', SYS)
                else
                    pp:delCurrency('current_hallmarks', SEAL_HM_COST)
                    pp:addItem(SEAL_ITEM, 1)
                    pp:setCharVar('Amb_Seal_BuyMonth', m)
                    pp:setCharVar('Amb_Seal_BuyYear',  y)
                    pp:printToPlayer('[Ambuscade] Received an Abdhaljs Seal. Hold it into a party clear to triple that run\'s Gallantry.', SYS)
                end
                showSealMenu(pp, backFn)
            end,
        },
        {
            claimedThisWeek and 'Weekly Seals (claimed)'
                            or  string.format('Claim Weekly (%d free)', SEAL_WEEKLY),
            function(pp)
                local wk = sealWeekKey()
                if pp:getCharVar('Amb_Seal_ClaimWeek') == wk then
                    pp:printToPlayer('[Ambuscade] You have already claimed your weekly Seals.', SYS)
                elseif pp:getItemCount(SEAL_ITEM) == 0 and pp:getFreeSlotsCount() < 1 then
                    pp:printToPlayer('[Ambuscade] Inventory full.', SYS)
                else
                    pp:addItem(SEAL_ITEM, SEAL_WEEKLY)
                    pp:setCharVar('Amb_Seal_ClaimWeek', wk)
                    pp:printToPlayer(string.format('[Ambuscade] Claimed %d Abdhaljs Seals for the week.', SEAL_WEEKLY), SYS)
                end
                showSealMenu(pp, backFn)
            end,
        },
        { 'Back', backFn },
    }
    local snapshot = { title = string.format('Seals [have %d]', have), options = options }
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
        {
            string.format('Seals [%d]', player:getItemCount(SEAL_ITEM)),
            function(pp) showSealMenu(pp, function(p) showGorpaMain(p) end) end,
        },
        {
            'Weapons',
            function(pp)
                if not AMBU_WPN then
                    local ok, cat = pcall(require, 'modules/custom/lua/ambuscade_weapons_catalog')
                    if not ok or type(cat) ~= 'table' then
                        pp:printToPlayer('[Ambuscade] Weapon exchange is temporarily unavailable.', SYS)
                        return
                    end
                    AMBU_WPN = cat
                end
                showWeaponMain(pp, function(p) showGorpaMain(p) end)
            end,
        },
        { 'Leave', function(pp) end },
    }
    local snapshot = { title = 'Gorpa-Masorpa', options = options }
    player:timer(30, function(pp) pp:customMenu(snapshot) end)
end

-- ─── Gorpa-Masorpa ────────────────────────────────────────────────────────────
-- Armor upgrade trades (was an empty stub until 2026-07-10 -- player report
-- Jamesta: the documented upgrade trades did nothing):
--   NQ piece + 5x its line's Abdhaljs material  -> +1 piece
--   +1 piece + 10x its line's Abdhaljs material -> +2 piece
-- Line 1 (Sulevia's/Hizamaru/Inyanga/Meghanada/Jhakri) uses Metal (9270);
-- line 2 (Flamma/Tali'ah/Mummu/Ayanmo/Mallquis) uses Fiber (9271). Both
-- materials are sold in the Hallmark shop above.
xi.ambuscade.onTradeGorpaMasorpa = function(player, npc, trade)
    for gearId, up in pairs(UPGRADES) do
        if trade:hasItemQty(gearId, 1) then
            if npcUtil.tradeHasExactly(trade, { gearId, { up.mat, up.qty } }) then
                if npcUtil.giveItem(player, up.result) then
                    player:confirmTrade()
                    player:printToPlayer('[Ambuscade] A fine piece -- wear it with pride!', SYS)
                end
            else
                local matName = up.mat == 9270 and 'Abdhaljs Metal' or 'Abdhaljs Fiber'
                player:printToPlayer(string.format(
                    '[Ambuscade] To upgrade that piece, trade it together with exactly %dx %s (sold here for Hallmarks).',
                    up.qty, matName), SYS)
            end
            return
        end
    end
    player:printToPlayer('[Ambuscade] Trade me an Ambuscade armor piece + its Abdhaljs material (Metal or Fiber) to upgrade it: NQ+5 -> +1, +1+10 -> +2.', SYS)
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

-- If a party member is already inside a live Ambuscade instance, return it so
-- the player JOINS that battle instead of getting a private copy. Without this
-- every party member got their own instance (visible-but-untargetable "ghosts"
-- of each other) and numChars was always 1, making Gallantry unobtainable.
local function findPartyAmbuscade(player)
    for _, member in pairs(player:getParty()) do
        if member:getID() ~= player:getID() then
            local inst = member:getInstance()
            if
                inst and
                inst:getZone():getID() == xi.zone.MAQUETTE_ABDHALJS_LEGION_B and
                not inst:completed() and
                not inst:failed()
            then
                return inst
            end
        end
    end
    return nil
end

-- ENTRY GATE: requires proof of endgame combat readiness before Ambuscade
-- opens. The two thresholds:
--   * >=1 HNM King kill  (any of the 6 Land Kings; tracked in custom_HNM_system.lua)
--   * >=1 HTBF clear at EACH of T1, T2, T3  (tracked in htbf.lua onEventFinishWin)
-- Gate runs on both createInstance (host) AND setInstance (party join), so a
-- qualified host can't smuggle unqualified party members into the fight.
local function checkAmbuscadeEntryReqs(player)
    local kings = player:getCharVar('HNM_King_Kills') or 0
    local t1 = player:getCharVar('HTBF_Cleared_T1') or 0
    local t2 = player:getCharVar('HTBF_Cleared_T2') or 0
    local t3 = player:getCharVar('HTBF_Cleared_T3') or 0
    if kings >= 1 and t1 >= 1 and t2 >= 1 and t3 >= 1 then
        return true
    end
    -- Concise, one-line status so the player knows exactly what's missing.
    local missing = {}
    if kings < 1 then missing[#missing + 1] = 'HNM King kill' end
    if t1 < 1 then missing[#missing + 1] = 'HTBF T1' end
    if t2 < 1 then missing[#missing + 1] = 'HTBF T2' end
    if t3 < 1 then missing[#missing + 1] = 'HTBF T3' end
    player:printToPlayer(
        '[Ambuscade] Entry requires: 1 HNM King kill + 1 HTBF clear at each of T1/T2/T3.',
        SYS)
    player:printToPlayer(
        string.format('[Ambuscade] Still needed: %s.', table.concat(missing, ', ')),
        SYS)
    return false
end

local function enterAmbuscade(player, diffOption)
    if not checkAmbuscadeEntryReqs(player) then
        return
    end

    local partyInst = findPartyAmbuscade(player)
    if partyInst then
        -- setInstance registers the char on the instance (numChars now counts
        -- them for Gallantry); the difficulty picked here is ignored — the
        -- battle already runs at its creator's difficulty.
        player:setInstance(partyInst)
        player:setPos(137, 12.5, -137, 32, xi.zone.MAQUETTE_ABDHALJS_LEGION_B)
        player:printToPlayer('[Ambuscade] Joining your party\'s battle already in progress!', SYS)
        return
    end

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
-- Retail auto-exit position: the walkable dock spot directly opposite the
-- Ambuscade Tome (matching Jamesta's Discord report 2026-07-13: retail
-- "auto exits to Mhaura instantly ... opposite the entry book"). The Tome sits
-- at (-28.030, -15.500, 52.279) facing rot 249; players interact with it from
-- rot 249, so the opposite side of the book is behind it (rot 121). Placing the
-- player 2y behind the Tome and rotating 121 puts them face-to-face with the
-- Tome the instant they arrive back in Mhaura.
local MHAURA_EXIT_X   = -28.030
local MHAURA_EXIT_Y   = -15.500
local MHAURA_EXIT_Z   =  50.279  -- ~2y behind the Tome (on the dock, walkable)
local MHAURA_EXIT_ROT =  121     -- facing the Tome
local MHAURA_ZONE_ID  = 249
local AMBUSCADE_ZONE_ID = xi.zone.MAQUETTE_ABDHALJS_LEGION_B
local PLUTON_CASE_DROP_CHANCE = 5

-- Intense VD has one independent 33% cosmetic roll per player. Selection is
-- direct script RNG followed by addItem, deliberately outside mob treasure
-- pools and xi.combat.treasureHunter so Treasure Hunter cannot affect it.
local function tryAwardIntenseVDCosmetic(player)
    if not AMBU_COSMETICS then
        local ok, catalog = pcall(require, 'modules/custom/lua/ambuscade_cosmetic_pool')
        if not ok or type(catalog) ~= 'table' or type(catalog.items) ~= 'table' or #catalog.items == 0 then
            player:printToPlayer('[Ambuscade] The cosmetic reward pool is temporarily unavailable.', SYS)
            return
        end

        AMBU_COSMETICS = catalog
    end

    if math.random(1, 100) > AMBU_COSMETICS.dropChance then
        return
    end

    local reward = AMBU_COSMETICS.items[math.random(1, #AMBU_COSMETICS.items)]
    if player:getFreeSlotsCount() < 1 then
        player:printToPlayer('[Ambuscade] Your cosmetic roll succeeded, but your inventory is full.', SYS)
    elseif player:addItem(reward.id, 1) then
        player:printToPlayer(string.format(
            '[Ambuscade] Intense VD cosmetic: %s!', reward.name), SYS)
    else
        player:printToPlayer(string.format(
            '[Ambuscade] Cosmetic roll selected %s, but it could not be added (you may already own this Rare item).',
            reward.name), SYS)
    end
end

-- Normal, Difficult, and Very Difficult each have a fixed 5% Pluton Case roll.
-- This direct completion reward deliberately bypasses treasure pools and TH.
local function tryAwardPlutonCase(player, difficulty)
    local difficultyWithinCategory = (difficulty - 1) % 5
    if difficultyWithinCategory > 2 or math.random(1, 100) > PLUTON_CASE_DROP_CHANCE then
        return
    end

    if player:getFreeSlotsCount() < 1 then
        player:printToPlayer('[Ambuscade] Your Pluton Case roll succeeded, but your inventory is full.', SYS)
    elseif player:addItem(xi.item.PLUTON_CASE, 1) then
        player:printToPlayer('[Ambuscade] You receive a Pluton Case!', SYS)
    else
        player:printToPlayer('[Ambuscade] Your Pluton Case could not be added.', SYS)
    end
end

-- Grace period before the auto-warp fires, so the player has time to see the
-- Victory / Time-limit message, look around, and (in case completion mis-fires
-- while more of the fight actually remains) keep swinging. 2026-07-13 report
-- (Jamesta): Intense VD, a few minutes in, "warped out with no message" --
-- the instant zone-out from the prior fix (2bb9ceade8) was too sudden.
local EXIT_GRACE_MS = 20000

local function warpToMhaura(player)
    player:setPos(MHAURA_EXIT_X, MHAURA_EXIT_Y, MHAURA_EXIT_Z, MHAURA_EXIT_ROT, MHAURA_ZONE_ID)
end

-- Delay the warp so the player sees the outcome message and has a moment to
-- react. Guard: only warp if they're still IN the Ambuscade zone at fire time;
-- if they zoned elsewhere during the grace (GM tools, /shutdown, another exit
-- path), the timer becomes a no-op instead of yanking them back to Mhaura.
local function scheduleWarpToMhaura(player)
    player:timer(EXIT_GRACE_MS, function(p)
        if p:getZoneID() == AMBUSCADE_ZONE_ID then
            warpToMhaura(p)
        end
    end)
end

xi.ambuscade.onInstanceComplete = function(instance)
    -- Belt-and-braces idempotency: rewards are paid at most once per instance,
    -- even if complete() somehow fires again (the time-update loop used to
    -- re-trigger it every second and spam +HM to the monthly cap).
    if instance:getLocalVar('Amb_Rewarded') == 1 then
        return
    end
    instance:setLocalVar('Amb_Rewarded', 1)

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

        -- Abdhaljs Seal: a party clear (galEarned > 0) consumes one held Seal to
        -- triple THIS player's Gallantry. Per-player so seals aren't shared, and
        -- only spent when there is Gallantry to triple (never on a solo run).
        local pGal   = galEarned
        local sealed = false
        if pGal > 0 and player:getItemCount(SEAL_ITEM) > 0 then
            player:delItem(SEAL_ITEM, 1)
            pGal   = pGal * 3
            sealed = true
        end

        player:addCurrency('current_hallmarks', actualHM)
        player:addCurrency('total_hallmarks',   actualHM)
        if pGal > 0 then
            player:addCurrency('gallantry', pGal)
        end

        -- Increment RoE clear record.
        xi.roe.onRecordTrigger(player, 499)

        local bonusStr = timeMult > 1.0 and string.format(' (×%.1f time bonus)', timeMult) or ''
        local sealStr  = sealed and ' [Seal ×3!]' or ''
        if actualHM < rawHM then
            player:printToPlayer(string.format(
                '[Ambuscade] Victory! +%d HM%s (monthly cap: %d/%d). +%d Gallantry%s.',
                actualHM, bonusStr, MONTHLY_HM_CAP - remaining, MONTHLY_HM_CAP, pGal, sealStr), SYS)
        else
            player:printToPlayer(string.format(
                '[Ambuscade] Victory! +%d HM%s. Total: %d HM. +%d Gallantry%s.',
                actualHM, bonusStr, player:getCurrency('current_hallmarks'), pGal, sealStr), SYS)
        end

        if difficulty == 1 then
            tryAwardIntenseVDCosmetic(player)
        end
        tryAwardPlutonCase(player, difficulty)

        -- Delayed auto-exit (2026-07-13). Was an INSTANT warpToMhaura since
        -- 2bb9ceade8, but Jamesta reported being warped out mid-fight without
        -- seeing a message; the 20s grace gives the Victory/Time-limit line time
        -- to land in chat and gives the player a beat to look around instead of
        -- yanking them back to Mhaura in the same server tick.
        player:printToPlayer(string.format(
            '[Ambuscade] Auto-exit to Mhaura in %ds.', EXIT_GRACE_MS / 1000), SYS)
        scheduleWarpToMhaura(player)
    end
end

xi.ambuscade.onInstanceFailure = function(instance)
    local chars = instance:getChars()
    for _, player in pairs(chars) do
        player:printToPlayer('[Ambuscade] Time limit reached. Your effort is not forgotten.', SYS)
        player:printToPlayer(string.format(
            '[Ambuscade] Auto-exit to Mhaura in %ds.', EXIT_GRACE_MS / 1000), SYS)
        scheduleWarpToMhaura(player)
    end
end

-- ─── Stats helper (called by !ambuscade command) ───────────────────────────────
xi.ambuscade.printStats = function(player)
    local hm      = player:getCurrency('current_hallmarks')
    local total   = player:getCurrency('total_hallmarks')
    local gal     = player:getCurrency('gallantry')
    local monthly = player:getCharVar('Amb_HM_Earned')
    local seals   = player:getItemCount(SEAL_ITEM)
    player:printToPlayer(string.format(
        '[Ambuscade] Current HM: %d  |  Total HM: %d  |  Gallantry: %d  |  Seals: %d  |  This month: %d/%d HM',
        hm, total, gal, seals, monthly, MONTHLY_HM_CAP), SYS)
end
