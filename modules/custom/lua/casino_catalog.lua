-----------------------------------
-- casino_catalog.lua
-- Config + payout tables for the GM Home Casino ("Lady Luck").
--
-- DESIGN: every game has a built-in HOUSE EDGE, so the casino is a net gil
-- SINK over time (the whole point) while still letting lucky players win big.
-- All payouts are TOTAL-RETURN multipliers: a 2x win on a 25k bet returns 50k
-- (net +25k); a 0x is a loss (the bet is kept); a 1x is a push (bet returned).
-- Tune any number here freely -- the module reads it all at runtime.
-----------------------------------
local catalog = {}

catalog.zoneId  = xi.zone.GM_HOME
catalog.npcName = 'Lady Luck'
catalog.npcLook = 3000                                   -- reuse the proven Unlocker model; re-skin freely
catalog.npcPos  = { x = 1.500, y = 0.000, z = -35.000, rot = 128 }  -- gambling corner, east of the Mystery Mog

-- Preset bet sizes. customMenu can't take a typed number, so bets are tiers.
catalog.betTiers = { 5000, 25000, 100000, 500000 }

-- A single win at or above this shouts server-wide (social flex, like the Mystery Mog jackpot).
catalog.jackpotBroadcast = 2000000

-- =====================================================================
-- SLOTS -- 3 reels, identical weighted strip on each. Pays three-of-a-kind.
-- RTP check (P = (weight/total)^3, total weight = 10):
--   7      0.1^3  = 0.001  x150 = 0.150
--   Bell   0.2^3  = 0.008  x30  = 0.240
--   Melon  0.3^3  = 0.027  x10  = 0.270
--   Cherry 0.4^3  = 0.064  x4   = 0.256
--   ----------------------------------- RTP ~= 0.916  (house edge ~8.4%)
-- =====================================================================
catalog.slots =
{
    reel =
    {
        { sym = '7',      weight = 1 },
        { sym = 'Bell',   weight = 2 },
        { sym = 'Melon',  weight = 3 },
        { sym = 'Cherry', weight = 4 },
    },
    three = { ['7'] = 150, ['Bell'] = 30, ['Melon'] = 10, ['Cherry'] = 4 },
}

-- =====================================================================
-- HIGH-LOW -- reveal a rank 1..ranks, bet Higher/Lower on the next draw.
-- Payout is ODDS-BASED so the edge is constant regardless of the card:
--   mult = (ranks / winningRanks) * (1 - houseEdge)
-- => EV = mult * P(win) = (1 - houseEdge) for every anchor. Ties lose.
-- (Safe bets pay barely over 1x; risky bets near the extremes pay big.)
-- =====================================================================
catalog.highlow = { ranks = 13, houseEdge = 0.08 }

-- =====================================================================
-- ROULETTE -- European single-zero wheel (0..36). 0 is green (the house).
--   Even-money bets (Red/Black/Odd/Even) pay 2x, lose on 0  -> edge 1/37 = 2.7%
--   Green (straight 0)                    pays 35x           -> edge 5.4%
-- =====================================================================
catalog.roulette =
{
    slots   = 37,        -- 0..36
    evenPay = 2,
    greenPay = 35,
    red =                -- set of red numbers (rest 1..36 are black)
    {
        [1]=true,[3]=true,[5]=true,[7]=true,[9]=true,[12]=true,[14]=true,[16]=true,[18]=true,
        [19]=true,[21]=true,[23]=true,[25]=true,[27]=true,[30]=true,[32]=true,[34]=true,[36]=true,
    },
}

-- =====================================================================
-- DICE -- roll 2d6 (2..12). Bet the band:
--   High 8-12 / Low 2-6 : P = 15/36, pay 2.25x -> EV 0.9375 (edge ~6%)
--   Lucky 7             : P =  6/36, pay 5x     -> EV 0.833  (edge ~17%, long-shot)
-- =====================================================================
catalog.dice = { highLowPay = 2.25, sevenPay = 5 }

return catalog
