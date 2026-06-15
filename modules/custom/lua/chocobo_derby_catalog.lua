-----------------------------------
-- chocobo_derby_catalog.lua
-- Config for the Chocobo Derby (see ChocoboDerby.lua) - simulated
-- chocobo racing with parimutuel-style betting. A gil SINK: the house
-- keeps a cut of fair odds, so aggregate play drains gil while big
-- wins stay exciting.
--
-- If the player has a raised chocobo (Chocobo Raising), they can field
-- it as a runner: its hidden weight derives from its real strength /
-- endurance / affection stats, and winning on your own bird pays a
-- home-stable bonus. This is the chocobo-raising loop closer.
-----------------------------------
local catalog = {}

-- The Race Caller, GM Home Activities row (z=-21): ExpCamp / Weekly
-- Hunts / Dungeon Master (1.5) / Infamy Vendor (4.5) / Arena Herald
-- (7.5) / Race Caller (10.5).
catalog.npcPos =
{
    zone     = 'GM_Home',
    zoneId   = 210,
    x        = 4.500,
    y        =  0.000,
    z        = -25.000,
    rotation = 128,
}

-- Bet sizes offered in the menu (gil).
catalog.bets = { 10000, 50000, 250000 }

-- Field size per race and the flavor-name stable. 5 NPC runners are
-- drawn per race (+1 slot for YOUR bird if you field it, else a 6th
-- NPC runner). Names are kept <= 12 chars: the odds-board customMenu
-- must fit 6 runner rows inside the 150-byte packet budget.
catalog.fieldSize = 6
catalog.stable =
{
    'Chocofury',   'Bolt v. Kweh', 'Lady Bolt',
    'Sir Scratch', 'Meteor Mike',  'Yellowcomet',
    'Dust Dan',    'Sandy Sally',  'Gallop Gus',
    'Wark Wonder', 'Featherluck',  'Kwehsar',
}

-- Hidden NPC runner weight range (uniform roll per race).
catalog.npcWeightMin = 40
catalog.npcWeightMax = 100

-- Your raised bird's weight: base + (strength + endurance) / statDiv
-- + affection / affectionDiv, clamped to [min, max]. Raising stats run
-- to the hundreds on a maxed bird, so a pampered racer genuinely
-- out-odds the stable.
catalog.ownBird =
{
    minStage     = 3,     -- adolescent or older may race
    base         = 45,
    statDiv      = 12,
    affectionDiv = 50,
    weightMin    = 45,
    weightMax    = 130,
    winBonusPct  = 25,    -- extra payout % when YOUR bird wins
}

-- House edge: payout = fair odds x this (then floored at minPayout).
catalog.houseFactor = 0.85
catalog.minPayout   = 1.15

-- Commentary pacing: ticks every tickSec, race resolves on the last.
catalog.race =
{
    ticks   = 4,
    tickSec = 5,
}

return catalog
