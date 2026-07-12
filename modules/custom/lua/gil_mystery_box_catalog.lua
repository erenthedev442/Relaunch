-----------------------------------
-- gil_mystery_box_catalog.lua
-- Weighted reward pool for the Mystery Mog. Tune the weights freely --
-- the rarer the reward, the lower the weight. Weights are relative;
-- the engine sums them at roll time, so only ratios matter.
--
-- Each entry:
--   tier      : 'common' | 'uncommon' | 'rare' | 'epic' | 'legendary'
--               Used by pity system and multi-pull guarantees.
--   weight    : higher = more common (summed at runtime)
--   label     : shown in result messages
--   item      : (optional) item id to grant
--   itemQty   : (optional) quantity, default 1
--   huntMarks : (optional) HL_Points bump
--   gilRefund : (optional) gil returned to player
--   pardon    : (optional) true = cancel next death penalty in hunt zone
--   ap        : (optional) Ascension Points added to current main job
--   jackpot   : (optional) true = trigger server-wide broadcast
-----------------------------------
local catalog = {}

catalog.zoneId    = xi.zone.ABDHALJS_ISLE_PURGONORGO
catalog.zonePath  = 'xi.zones.Abdhaljs_Isle-Purgonorgo'
catalog.npcName   = 'Mystery Mog'
catalog.npcLook   = 2401
catalog.npcPos    = { x = 583.000, y = -3.360, z = 521.500, rot = 192 }

-- Pull costs
catalog.pullCost    = 100000  -- 100k  standard single pull
catalog.tripleCost  = 270000  -- 270k  3x pull (10% off 300k)
catalog.decaCost    = 900000  -- 900k  10x pull (10% off 1M) + 1 guaranteed uncommon+
catalog.premiumCost = 500000  -- 500k  premium pull (no commons, AP possible)

catalog.huntCv   = 'HL_Points'    -- Hunt Marks charvar (shared with HuntingLeague)
catalog.pityVar  = 'MysteryMog_Pity'    -- tracks consecutive non-epic+ pulls per player
catalog.pardonVar = 'MysteryMog_Pardon' -- 1 = next hunt-zone death waives the mark penalty

-- Pity: after this many pulls without hitting Epic+, the next pull is forced Epic+
catalog.pityThreshold = 50

-- Tier rank table (used for pity and guarantee comparisons)
catalog.tierRank = { common = 1, uncommon = 2, rare = 3, epic = 4, legendary = 5 }

-- =========================================================
-- Standard pull pool (100k per pull)
-- Approximate odds: Common 50% | Uncommon 25% | Rare 18% | Epic 5% | Legendary 0.5%
-- =========================================================
catalog.pool =
{
    -- Common (~50%)
    { tier = 'common',   weight = 200, label = 'a Hi-Potion (3x)',
      item = xi.item.HI_POTION,           itemQty = 3 },
    { tier = 'common',   weight = 150, label = 'a Hi-Ether (3x)',
      item = xi.item.HI_ETHER,            itemQty = 3 },
    { tier = 'common',   weight = 100, label = 'an Antidote (5x)',
      item = xi.item.ANTIDOTE,            itemQty = 5 },
    { tier = 'common',   weight =  50, label = 'Echo Drops (5x)',
      item = xi.item.FLASK_OF_ECHO_DROPS, itemQty = 5 },

    -- Uncommon (~25%)
    { tier = 'uncommon', weight = 100, label = 'an X-Potion (3x)',
      item = xi.item.X_POTION,            itemQty = 3 },
    { tier = 'uncommon', weight =  80, label = 'a Vile Elixir +1',
      item = xi.item.VILE_ELIXIR_P1,      itemQty = 1 },
    { tier = 'uncommon', weight =  70, label = 'an Elixir (2x)',
      item = xi.item.ELIXIR,              itemQty = 2 },

    -- Pupil set pieces (starter gear; collect the set across pulls)
    { tier = 'uncommon', weight =  25, label = "a Pupil's Shirt",
      item = 26946 },
    { tier = 'uncommon', weight =  25, label = "a Pupil's Camisa",
      item = 26964 },
    { tier = 'uncommon', weight =  25, label = "a Pupil's Trousers",
      item = 27281 },
    { tier = 'uncommon', weight =  25, label = "a Pupil's Shoes",
      item = 27455 },

    -- Rare (~18%)
    { tier = 'rare',     weight =  80, label = 'a fistful of 5 Hunt Marks',
      huntMarks =   5 },
    { tier = 'rare',     weight =  60, label = 'a satchel of 10 Hunt Marks',
      huntMarks =  10 },
    { tier = 'rare',     weight =  40, label = 'a bag of 20 Hunt Marks',
      huntMarks =  20 },

    -- Epic (~5%)
    { tier = 'epic',     weight =  30, label = 'a chest of 50 Hunt Marks',
      huntMarks =  50 },
    { tier = 'epic',     weight =  15, label = 'a TREASURE of 100 Hunt Marks',
      huntMarks = 100 },
    { tier = 'epic',     weight =   8, label = "a Death's Pardon (next hunt-zone death waived)",
      pardon = true },

    -- Legendary (~0.5%)
    { tier = 'legendary', weight =  4, label = 'an Aman Voucher + 200 Hunt Marks',
      item = xi.item.COPPER_AMAN_VOUCHER, itemQty = 1, huntMarks = 200 },
    { tier = 'legendary', weight =  1, label = 'a JACKPOT! Full refund + 500 Hunt Marks',
      huntMarks = 500, gilRefund = 100000, jackpot = true },
}

-- =========================================================
-- Premium pull pool (500k per pull)
-- No commons. Approximate odds: Uncommon 31% | Rare 37% | Epic 24% | Legendary 8%
-- Exclusive prizes: Ascension Points (current main job).
-- =========================================================
catalog.premiumPool =
{
    -- Uncommon (~31%)
    { tier = 'uncommon', weight = 100, label = 'X-Potions (5x)',
      item = xi.item.X_POTION,       itemQty = 5 },
    { tier = 'uncommon', weight =  70, label = 'Vile Elixirs +1 (2x)',
      item = xi.item.VILE_ELIXIR_P1, itemQty = 2 },

    -- Rare (~37%)
    { tier = 'rare',     weight = 120, label = '20 Hunt Marks',
      huntMarks =  20 },
    { tier = 'rare',     weight =  80, label = '35 Hunt Marks',
      huntMarks =  35 },

    -- Epic (~24%)
    { tier = 'epic',     weight =  60, label = '75 Hunt Marks',
      huntMarks =  75 },
    { tier = 'epic',     weight =  40, label = '150 Hunt Marks',
      huntMarks = 150 },
    { tier = 'epic',     weight =  20, label = "a Death's Pardon (next hunt-zone death waived)",
      pardon = true },
    { tier = 'epic',     weight =  10, label = '+1 Ascension Point (current job)',
      ap = 1 },

    -- Legendary (~8%)
    { tier = 'legendary', weight =  30, label = 'an Aman Voucher + 250 Hunt Marks',
      item = xi.item.COPPER_AMAN_VOUCHER, itemQty = 1, huntMarks = 250 },
    { tier = 'legendary', weight =  10, label = '+3 Ascension Points (current job)',
      ap = 3 },
    { tier = 'legendary', weight =   5, label = 'a JACKPOT! Full refund + 500 Hunt Marks',
      huntMarks = 500, gilRefund = 500000, jackpot = true },
}

return catalog
