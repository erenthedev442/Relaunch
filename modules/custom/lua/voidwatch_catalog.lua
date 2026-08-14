-----------------------------------
-- voidwatch_catalog.lua
--
-- Data + scaling for the Voidwatch-flavored rift-battle system (Voidwatch.lua).
-- Spirit-of-retail: Voidstones gate rift opens; opening a rift tears one open
-- where you stand and spawns a tier-scaled Voidwalker NM; killing it pays Cruor
-- + EXP and advances your abyssite tier (the next rift is tougher + pays more).
-- No native client lights/atmacite UI -- everything runs through NPC menu +
-- chat messages, like the server's other custom NM systems.
--
-- All tunables live here, so balance is a hot-reload (no restart). xi.mod is
-- referenced only inside functions (call-time), per the module auto-load rule.
-----------------------------------
local C = {}

-- ── Voidstone economy ──────────────────────────────────────────────────────
C.MAX_STONES    = 10      -- carry cap
C.REGEN_SECONDS = 3600    -- one Voidstone regenerates per hour (real time)
C.START_STONES  = 5       -- granted the first time you use Voidwatch
C.RIFT_COST     = 1       -- Voidstones spent to open a rift
C.STONE_CRUOR   = 400     -- buy one Voidstone for this much cruor

-- ── Battle ─────────────────────────────────────────────────────────────────
C.BATTLE_SECONDS = 1800   -- 30-min battle timer (retail); then the NM voids out
C.PYXIS_LOOK     = 969    -- authentic Riftworn Pyxis model (0x03C9, from npc_list look 0x0000C903)
C.PYXIS_SECONDS  = 180    -- claim window for the physical Riftworn Pyxis chest (3 min)
C.SPAWN_DIST_MIN = 8
C.SPAWN_DIST_MAX = 13

-- ── Stratum scaling ─────────────────────────────────────────────────────────
-- Voidwatch bridges early Lv99 hunts and the Mythic Stage-II roster gate.
-- Combat profiles are explicit per stratum so repeat clears can never make a
-- lower stratum overtake the next one. Each clear adds 4% pressure, capped at
-- five clears / 20%; levels stay fixed so donor-pool formulas remain stable.
C.MAX_EFFECTIVE_TIER = 24
C.MAX_STRATUM_SCALING_CLEARS = 5
C.STRATUM_REPEAT_STEP = 0.04

local STRATUM_COMBAT =
{
    CRIMSON  = { level = 99,  hp =  350000, att = 1200, acc = 600,  def = 450,  eva = 250,  matt = 500,  macc = 450,  mdef = 180, da = 5,  ta = 0, regain = 50,  dmgPhys = -400, damageCap = 2000 },
    INDIGO   = { level = 105, hp =  600000, att = 1700, acc = 700,  def = 600,  eva = 350,  matt = 700,  macc = 550,  mdef = 225, da = 8,  ta = 0, regain = 60,  dmgPhys = -450, damageCap = 2500 },
    JADE     = { level = 110, hp =  900000, att = 2300, acc = 800,  def = 750,  eva = 450,  matt = 900,  macc = 650,  mdef = 275, da = 10, ta = 0, regain = 75,  dmgPhys = -500, damageCap = 3000 },
    WHITE    = { level = 115, hp = 1400000, att = 3000, acc = 900,  def = 950,  eva = 600,  matt = 1200, macc = 775,  mdef = 325, da = 12, ta = 2, regain = 90,  dmgPhys = -550, damageCap = 3500 },
    ASHEN    = { level = 125, hp = 2500000, att = 3900, acc = 1000, def = 1200, eva = 800,  matt = 1500, macc = 900,  mdef = 375, da = 15, ta = 4, regain = 110, dmgPhys = -600, damageCap = 4000 },
    HYACINTH = { level = 135, hp = 4500000, att = 4800, acc = 1125, def = 1450, eva = 1000, matt = 1800, macc = 1025, mdef = 425, da = 20, ta = 6, regain = 140, dmgPhys = -650, damageCap = 4500 },
    AMBER    = { level = 145, hp = 7000000, att = 5800, acc = 1250, def = 1700, eva = 1200, matt = 2200, macc = 1150, mdef = 500, da = 25, ta = 8, regain = 180, dmgPhys = -700, damageCap = 5000 },
}

local function combatProfile(stratum, clears)
    local key = type(stratum) == 'table' and stratum.key or stratum
    local base = STRATUM_COMBAT[key] or STRATUM_COMBAT.CRIMSON
    local repeats = math.min(math.max(0, clears or 0), C.MAX_STRATUM_SCALING_CLEARS)
    local scale = 1 + repeats * C.STRATUM_REPEAT_STEP
    return base, scale
end

function C.effectiveTier(stratum, clears)
    local base = (stratum and stratum.base) or 0
    local scaledClears = math.min(math.max(0, clears or 0), C.MAX_STRATUM_SCALING_CLEARS)
    return math.min(C.MAX_EFFECTIVE_TIER, base + scaledClears + 1)
end

function C.nmLevel(stratum)
    local base = combatProfile(stratum, 0)
    return base.level
end

function C.nmHp(stratum, clears)
    local base, scale = combatProfile(stratum, clears)
    return math.floor(base.hp * scale)
end

function C.nmDamageCap(stratum)
    local base = combatProfile(stratum, 0)
    return base.damageCap
end

function C.nmMods(stratum, clears)
    local base, scale = combatProfile(stratum, clears)
    local function scaled(value) return math.floor(value * scale) end
    return {
        [xi.mod.ATT]           = scaled(base.att),
        [xi.mod.ACC]           = scaled(base.acc),
        [xi.mod.DEF]           = scaled(base.def),
        [xi.mod.EVA]           = scaled(base.eva),
        [xi.mod.MATT]          = scaled(base.matt),
        [xi.mod.MACC]          = scaled(base.macc),
        [xi.mod.MDEF]          = scaled(base.mdef),
        [xi.mod.DOUBLE_ATTACK] = scaled(base.da),
        [xi.mod.TRIPLE_ATTACK] = scaled(base.ta),
        [xi.mod.REGAIN]        = scaled(base.regain),
        [xi.mod.DMGPHYS]       = base.dmgPhys,
        [xi.mod.REGEN]         = 0,
    }
end

function C.difficultyName(tier)
    if tier <= 3 then return 'Entry' end
    if tier <= 6 then return 'Seasoned' end
    if tier <= 9 then return 'Veteran' end
    if tier <= 12 then return 'Elite' end
    if tier <= 15 then return 'Master' end
    if tier <= 18 then return 'Nightmare' end
    return 'Mythic'
end

-- ── Rewards (the "Riftworn Pyxis") ─────────────────────────────────────────
function C.cruorReward(tier) return 800 + tier * 350 end
function C.expReward(tier)   return 1500 + tier * 600 end
function C.markReward(tier)  return 10 + math.min(C.MAX_EFFECTIVE_TIER, tier) * 5 end
C.FIRST_NM_MARK_BONUS = 100

-- ── charVars ───────────────────────────────────────────────────────────────
C.V =
{
    born    = 'Voidwatch_Born',
    tier    = 'Voidwatch_Tier',     -- highest effective tier cleared across all strata
    stones  = 'Voidwatch_Stones',
    stoneTs = 'Voidwatch_StoneTs',  -- unix ts the stone count was last reconciled (regen anchor)
    cruor    = 'Voidwatch_Cruor',
    shards   = 'Voidwatch_Shards',   -- atmacite shards (banked from Pearl lights; spent at the Refiner)
    periapts = 'Voidwatch_Periapts', -- Periapts of Emergence (reveal an NM's weaknesses; +1 per clear)
}

-- ── Lights / Spectral Alignment ─────────────────────────────────────────────
-- Each rift hides 5 weaknesses, one per Light colour. Probe the NM with magic
-- elements / weaponskills / ranged attacks to draw the Lights out; the tally at
-- the kill shapes the Riftworn Pyxis (retail's spectral-alignment reward model,
-- surfaced through chat instead of the native on-screen light bar).
C.LIGHTS =
{
    order = { 'RED', 'BLUE', 'GREEN', 'YELLOW', 'WHITE' },
    names = { RED = 'Vermillion', BLUE = 'Cerulean', GREEN = 'Verdant', YELLOW = 'Amber', WHITE = 'Pearl' },
    boon  = { RED = 'reward quality', BLUE = 'reward quantity', GREEN = 'cruor', YELLOW = 'EXP', WHITE = 'atmacite' },
    cap   = 5,    -- max lights per colour
}
C.WEAKNESS_COOLDOWN = 5   -- seconds before the same Light can trigger again
-- Each NM has its OWN fixed weakness set (5-9, deterministic from its name) -- a
-- Periapt of Emergence reveals it. Synchronic Blitz: chain weakness triggers
-- within BLITZ_WINDOW; every BLITZ_BONUS_EVERY in the chain grants a bonus Light.
C.BLITZ_WINDOW      = 8   -- seconds between triggers to keep a Blitz chain alive
C.BLITZ_BONUS_EVERY = 3   -- chain length per bonus Light
C.NM_WEAK_MIN       = 5   -- min weaknesses per NM
C.NM_WEAK_SPAN      = 5   -- + 0..(span-1) more -> 5..9

-- Trigger pool: 5 are chosen at random per rift and mapped to the 5 colours.
-- 'elem:N' matches spell:getElement() (1=Fire, 2=Ice, 3=Wind, 4=Earth,
-- 5=Lightning, 6=Water, 7=Light, 8=Dark). 'ws'/'ranged' let melee + ranged jobs
-- draw Lights too, so every job can build alignment.
C.WEAKNESS_POOL =
{
    { key = 'elem:1', label = 'Fire magic'      },
    { key = 'elem:2', label = 'Ice magic'       },
    { key = 'elem:3', label = 'Wind magic'      },
    { key = 'elem:4', label = 'Earth magic'     },
    { key = 'elem:5', label = 'Lightning magic' },
    { key = 'elem:6', label = 'Water magic'     },
    { key = 'elem:7', label = 'Light magic'     },
    { key = 'elem:8', label = 'Dark magic'      },
    { key = 'ws',     label = 'weaponskills'    },
    { key = 'ranged', label = 'ranged attacks'  },
}

-- Reward weighting per Light (linear).
C.CRUOR_PER_GREEN  = 0.25   -- +25% cruor per Verdant
C.EXP_PER_YELLOW   = 0.25   -- +25% EXP per Amber
C.ROLLS_PER_2_BLUE = 1      -- +1 loot roll per 2 Cerulean
C.QUALITY_PER_RED  = 8      -- +8 to the d100 quality roll per Vermillion
C.SHARD_PER_WHITE  = 1      -- atmacite shards per Pearl

-- ── Loot (authentic Lord Ruthven / Yilbegan Voidwalker drops) ───────────────
C.LOOT =
{
    common =   -- crafting materials (ores / ingots / logs / hides / cloth)
    {
        645, 1262, 1258, 1255, 737, 1256, 1259, 1261, 644, 738, 1260, 1257,
        654, 702, 700, 703, 653, 866, 1116, 895, 859, 1122, 887, 1465, 823, 830,
    },
    uncommon = -- valuable mats + consumables
    {
        4172, 4173, 4174, 844, 942, 745, 746, 2883, 902, 2877, 1132, 2878,
    },
    rare =     -- gear + the good stuff (rings, belt, leggings, elixir+1, lucky coin)
    {
        11633, 11628, 11629, 15953, 14162, 4175, 19248,
    },
}
C.QUALITY_RARE_AT     = 92   -- d100 (+ red bias) >= this -> rare
C.QUALITY_UNCOMMON_AT = 60   -- >= this -> uncommon, else common
C.WHITE_BONUS_RARE_AT = 3    -- Pearl lights >= this -> a guaranteed bonus rare roll

-- ── Per-NM loot (retail-authentic, from the fork's own mob_droplist) ─────────
-- Each Voidwalker rolls its OWN rare (signature GEAR / chase) + uncommon
-- (signature MATERIAL + the shared consumables); the quality tier (d100 shaped by
-- Lights) still picks which of the three tables the Pyxis opens. Item ids verified
-- against the live VNM droplists (dropids 3168-3186). C.nmLoot(name) resolves an
-- NM's table, falling back per-tier to the generic C.LOOT / shared common pool.
--
-- COMMON tier = the shared standard VNM crafting pool (C.NM_COMMON) that every
-- Voidwalker with a material table drops at retail -- authentic, so it is shared.
-- Retail note: the Tier-I trigger NMs (Gorehound, Gjenganger, Raker_Bee) and the
-- fork-stub Aglaophotis have NO retail droplist; they get the shared pools + a
-- modest valuable (Philosopher's Stone / Sattva Ring) so every NM has a full table.
C.NM_COMMON =
{
    703, 700, 887, 702, 895, 902, 653, 644, 737, 745, 746, 866, 645, 654, 738,
    823, 1132, 859, 830, 1116, 1122, 844, 1465, 942,
    1255, 1256, 1257, 1258, 1259, 1260, 1261, 1262,
}
-- Sortie JSE earring families -- 22 jobs x NQ/+1/+2 = 66 items (25420..25548).
-- Earring quality and exact chance follow the Voidwatch stratum, never the
-- donor NM's historical VNM tier. +2 chase rates are intentionally fixed:
-- Ashen 5%, Hyacinth 10%, Amber 20%. Lights shape signature loot instead.
local SORTIE_NQ_EARRINGS =
{
    25420, 25426, 25432, 25438, 25444, 25450, 25456, 25462, 25468, 25474, 25480,
    25486, 25492, 25498, 25504, 25510, 25516, 25522, 25528, 25534, 25540, 25546,
}
local SORTIE_PLUS1_EARRINGS =
{
    25421, 25427, 25433, 25439, 25445, 25451, 25457, 25463, 25469, 25475, 25481,
    25487, 25493, 25499, 25505, 25511, 25517, 25523, 25529, 25535, 25541, 25547,
}
local SORTIE_PLUS2_EARRINGS =
{
    25422, 25428, 25434, 25440, 25446, 25452, 25458, 25464, 25470, 25476, 25482,
    25488, 25494, 25500, 25506, 25512, 25518, 25524, 25530, 25536, 25542, 25548,
}

local STRATUM_EARRINGS =
{
    CRIMSON  = { pool = SORTIE_NQ_EARRINGS,    chance = 20 },
    INDIGO   = { pool = SORTIE_NQ_EARRINGS,    chance = 20 },
    JADE     = { pool = SORTIE_PLUS1_EARRINGS, chance = 15 },
    WHITE    = { pool = SORTIE_PLUS1_EARRINGS, chance = 20 },
    ASHEN    = { pool = SORTIE_PLUS2_EARRINGS, chance = 5  },
    HYACINTH = { pool = SORTIE_PLUS2_EARRINGS, chance = 10 },
    AMBER    = { pool = SORTIE_PLUS2_EARRINGS, chance = 20 },
}

function C.earringReward(stratumKey)
    local reward = STRATUM_EARRINGS[stratumKey]
    if not reward then return nil, 0 end
    return reward.pool, reward.chance
end

C.NM_LOOT =
{
    -- Rich pools (retail Tier-III Voidwalkers): gear + signature material.
    Krabkatoa    = { rare = { 11502, 11632, 26970, 27724, 20827  }, uncommon = { 2884, 2879, 4172, 4174, 4173, 4175 } },
    Blobdingnag  = { rare = { 11631, 11585, 24188, 24131, 26400  }, uncommon = { 2876, 2882, 4172, 4174, 4173, 4175 } },
    Dawon        = { rare = { 15859, 16151, 28015, 20945  }, uncommon = { 2570, 4172, 4174, 4173, 4175 } },
    Lord_Ruthven = { rare = { 11628, 15953, 27775, 20672  }, uncommon = { 2883, 2877, 4172, 4174, 4173, 4175 } },
    Yilbegan     = { rare = { 11629, 11633, 14162, 19248, 25600, 21104  }, uncommon = { 2878, 4172, 4174, 4173, 4175 } },
    -- Single-gear pools (retail Tier-II): the signature equip + shared consumables.
    Yacumama     = { rare = { 11586, 27857, 26721, 21712  }, uncommon = { 4172, 4174, 4173, 4175 } },
    Farruca_Fly  = { rare = { 11635, 28287, 25654, 21221  }, uncommon = { 4172, 4174, 4173, 4175 } },
    Skuld        = { rare = { 11544, 24178, 28152, 21228  }, uncommon = { 4172, 4174, 4173, 4175 } },
    Capricornus  = { rare = { 15954, 28013, 28174, 28649  }, uncommon = { 4172, 4174, 4173, 4175 } },
    Lamprey_Lord = { rare = { 16054, 28016, 28154, 26487  }, uncommon = { 4172, 4174, 4173, 4175 } },
    Jyeshtha     = { rare = { 15955, 24128, 21528, 26403  }, uncommon = { 4172, 4174, 4173, 4175 } },
    Feuerunke    = { rare = { 16056, 27725, 21568  }, uncommon = { 4172, 4174, 4173, 4175 } },
    Tammuz       = { rare = { 16307, 24182, 21570  }, uncommon = { 4172, 4174, 4173, 4175 } },
    Erebus       = { rare = { 11587, 24166, 21569  }, uncommon = { 4172, 4174, 4173, 4175 } },
    Shoggoth     = { rare = { 19245, 27096, 28155, 28648  }, uncommon = { 4172, 4174, 4173, 4175 } },
    -- Retail-empty NMs: seeded so every NM has a full table (see note above).
    Aglaophotis  = { rare = { 15544, 26702, 21071  }, uncommon = { 4172, 4174, 4173, 4175 } },
    Gjenganger   = { rare = { 942, 24274, 21529  }, uncommon = { 4172, 4174, 4173, 4175 } },
    Gorehound    = { rare = { 942, 28280, 25853, 21256  }, uncommon = { 4172, 4174, 4173, 4175 } },
    Raker_Bee    = { rare = { 942, 28296, 27720, 22042  }, uncommon = { 4172, 4174, 4173, 4175 } },
}
function C.nmLoot(name)
    local t = C.NM_LOOT[name]
    if not t then
        return { rare = C.LOOT.rare, uncommon = C.LOOT.uncommon, common = C.NM_COMMON }
    end
    return {
        rare     = (t.rare and #t.rare > 0)         and t.rare     or C.LOOT.rare,
        uncommon = (t.uncommon and #t.uncommon > 0) and t.uncommon or C.LOOT.uncommon,
        common   = t.common or C.NM_COMMON,
    }
end

-- ── Stratum pressure (retail donor abilities remain the fight's identity) ───
-- Avoid generic immunity dances, unavoidable max-HP nukes, terror and doom:
-- those stack unfairly with retail kits in solo/trust content. Upper strata
-- instead gain readable fury phases and a generous 15-minute soft enrage.
function C.mechCfg(stratum)
    local key = type(stratum) == 'table' and stratum.key or stratum
    local cfg =
    {
        name            = 'Voidwatch',
        targetPartyOnly = true,
        forceMessages   = true,
    }
    if key == 'ASHEN' then
        cfg.phases =
        {
            { hp = 40, action = 'fury', att = 500, haste = 75, msg = 'draws deeper strength from the void!' },
        }
        cfg.enrage = { sec = 900, att = 1000, haste = 100, msg = 'the prolonged battle feeds the void!' }
    elseif key == 'HYACINTH' then
        cfg.phases =
        {
            { hp = 45, action = 'fury', att = 750, haste = 100, msg = 'surges with concentrated void energy!' },
        }
        cfg.enrage = { sec = 900, att = 1500, haste = 125, msg = 'the prolonged battle feeds the void!' }
    elseif key == 'AMBER' then
        cfg.phases =
        {
            { hp = 55, action = 'fury', att = 1000, haste = 125, msg = 'enters a controlled void frenzy!' },
            { hp = 25, action = 'enrage', att = 1500, haste = 150, msg = 'tears open the heart of the void!' },
        }
        cfg.enrage = { sec = 900, att = 2000, haste = 175, msg = 'the prolonged battle feeds the void!' }
    end
    return cfg
end

-- ── Planar Rift placements (authentic retail rift coords per zone) ──────────
-- One clickable Planar Rift NPC per zone; examining it opens a rift (this
-- REPLACES the !voidwatch open command). Coords pulled from sql/npc_list.sql
-- (the disabled retail rifts) so they're valid ground. Add/remove freely -- the
-- engine just loops this table (require + onInitialize override per zone).
C.RIFT_LOOK = 2415   -- authentic Planar Rift model (0x096F, from npc_list look 0x00006F09)
C.RIFTS =
{
    { zone = 'West_Ronfaure',          x = -320.0,  y = -10.0,   z = -360.0, rot = 0   },
    { zone = 'East_Ronfaure',          x =  183.0,  y = -20.0,   z = -315.0, rot = 64  },
    { zone = 'La_Theine_Plateau',      x = -440.0,  y =  -8.0,   z =  440.0, rot = 0   },
    { zone = 'Valkurm_Dunes',          x =  -75.0,  y =  -0.312, z =  -45.0, rot = 0   },
    { zone = 'Jugner_Forest',          x = -325.0,  y =   0.0,   z = -124.0, rot = 32  },
    { zone = 'Batallia_Downs',         x = -320.0,  y = -16.0,   z =  -42.0, rot = 0   },
    { zone = 'North_Gustaberg',        x = -322.0,  y =  40.0,   z =  -42.0, rot = 128 },
    { zone = 'South_Gustaberg',        x =  250.0,  y =  -0.018, z = -640.0, rot = 0   },
    { zone = 'Konschtat_Highlands',    x = -125.0,  y =  72.046, z =  720.0, rot = 0   },
    { zone = 'Pashhow_Marshlands',     x = -420.0,  y =  24.14,  z = -230.0, rot = 64  },
    { zone = 'Rolanberry_Fields',      x = -360.0,  y =   8.0,   z =  279.0, rot = 0   },
    { zone = 'Beaucedine_Glacier',     x = -135.0,  y = -60.5,   z = -200.0, rot = 0   },
    { zone = 'West_Sarutabaruta',      x = -441.0,  y =   4.0,   z = -357.0, rot = 0   },
    { zone = 'East_Sarutabaruta',      x = -120.0,  y =  -4.879, z = -415.0, rot = 0   },
    { zone = 'Tahrongi_Canyon',        x =  200.0,  y = -24.0,   z = -160.0, rot = 0   },
    { zone = 'Buburimu_Peninsula',     x = -360.0,  y =  -8.0,   z = -200.0, rot = 0   },
    { zone = 'Meriphataud_Mountains',  x = -282.0,  y =  16.0,   z =  602.0, rot = 0   },
    { zone = 'Sauromugue_Champaign',   x = -245.0,  y =   7.75,  z =  245.0, rot = 0   },
    { zone = 'The_Sanctuary_of_ZiTah', x = -275.0,  y =   0.2,   z =   46.0, rot = 0   },
    { zone = 'RoMaeve',                x = -114.0,  y =  -8.0,   z =   44.0, rot = 0   },
    { zone = 'Yuhtunga_Jungle',        x = -242.0,  y =   0.55,  z =  405.0, rot = 0   },
    { zone = 'Western_Altepa_Desert',  x = -170.0,  y =   0.001, z =  327.0, rot = 0   },
    { zone = 'Qufim_Island',           x = -120.0,  y = -19.304, z =  375.0, rot = 0   },
    { zone = 'Behemoths_Dominion',     x = -210.0,  y = -20.375, z =   70.0, rot = 0   },
    { zone = 'RuAun_Gardens',          x = -117.0,  y = -40.0,   z =  436.0, rot = 0   },
    { zone = 'Lufaise_Meadows',        x = -234.0,  y = -15.0,   z =  125.0, rot = 0   },
    { zone = 'Misareaux_Coast',        x =  267.0,  y = -15.0,   z =  222.0, rot = 0   },
    { zone = 'Attohwa_Chasm',          x =  361.0,  y =  21.0,   z =  222.0, rot = 0   },
    { zone = 'Bibiki_Bay',             x = -120.0,  y =   0.3,   z = -629.0, rot = 0   },
    { zone = 'Uleguerand_Range',       x = -141.0,  y = -19.0,   z = -325.0, rot = 0   },
}

-- ── Atmacite (charVar perks bought with shards at the Refiner) ──────────────
-- All effects are Voidwatch-scoped + read at RUNTIME (no addMod, no login
-- persistence, no stacking) -- atmacite empowers your Voidwatch runs, like retail.
C.ATM_PREFIX = 'Voidwatch_Atm_'
function C.atmCost(nextLevel) return nextLevel * 3 end   -- shards to reach nextLevel (cumulative to max5 = 45)
C.ATMACITE =
{
    { key = 'FORTUNE',    name = 'Fortune',    desc = '+8% cruor per level',                  max = 5 },
    { key = 'FERVOR',     name = 'Fervor',     desc = '+8% EXP per level',                    max = 5 },
    { key = 'GREED',      name = 'Greed',      desc = '+1 loot roll per level',               max = 4 },
    { key = 'INSIGHT',    name = 'Insight',    desc = '+1 max Light per colour per level',    max = 3 },
    { key = 'ATTUNEMENT', name = 'Attunement', desc = '-0.5s weakness cooldown per level',    max = 4 },
    { key = 'FLOW',       name = 'Flow',       desc = '+12% Voidstone regen speed per level', max = 5 },
}
C.ATM =   -- effect magnitudes
{
    FORTUNE_PCT = 0.08,
    FERVOR_PCT  = 0.08,
    GREED_ROLLS = 1,
    INSIGHT_CAP = 1,
    ATTUNE_CD   = 0.5,
    FLOW_PCT    = 0.12,
}

-- ── Abyssite Stratums (retail Voidwatch progression) ───────────────────────
-- Each stratum gates a group of zones + has its own abyssite tier (charVar
-- Voidwatch_Strat_<KEY>, +1 per clear). 'base' makes higher strata start harder;
-- effective NM tier = base + clears + 1. Rosters use authentic Voidwalker NM
-- templates {name, group, zone} -- the dynamic spawn borrows that pool's model.
-- Stratum abyssites exist as real KIs (key_item.lua: CRIMSON..AMBER 366-377 /
-- 1444-1452 / 2060-2063); we track tier via charVars + name them for flavor.
C.STRAT_PREFIX = 'Voidwatch_Strat_'
C.STRATA =
{
    { key = 'CRIMSON', name = 'Crimson Stratum', base = 0,
      zones  = { 'West_Ronfaure', 'East_Ronfaure', 'North_Gustaberg', 'South_Gustaberg', 'West_Sarutabaruta', 'East_Sarutabaruta' },
      roster = { { name = 'Krabkatoa', group = 48, zone = 81 }, { name = 'Yacumama', group = 49, zone = 81 }, { name = 'Raker_Bee', group = 57, zone = 95 } } },
    { key = 'INDIGO', name = 'Indigo Stratum', base = 3,
      zones  = { 'La_Theine_Plateau', 'Konschtat_Highlands', 'Tahrongi_Canyon', 'Valkurm_Dunes', 'Buburimu_Peninsula' },
      roster = { { name = 'Farruca_Fly', group = 54, zone = 95 }, { name = 'Skuld', group = 46, zone = 84 }, { name = 'Gorehound', group = 37, zone = 136 } } },
    { key = 'JADE', name = 'Jade Stratum', base = 6,
      zones  = { 'Jugner_Forest', 'Pashhow_Marshlands', 'Meriphataud_Mountains', 'Bibiki_Bay' },
      roster = { { name = 'Blobdingnag', group = 56, zone = 88 }, { name = 'Shoggoth', group = 58, zone = 88 }, { name = 'Capricornus', group = 48, zone = 101 } } },
    { key = 'WHITE', name = 'White Stratum', base = 9,
      zones  = { 'Batallia_Downs', 'Rolanberry_Fields', 'Sauromugue_Champaign' },
      roster = { { name = 'Lamprey_Lord', group = 59, zone = 88 }, { name = 'Jyeshtha', group = 55, zone = 95 }, { name = 'Dawon', group = 50, zone = 102 } } },
    { key = 'ASHEN', name = 'Ashen Stratum', base = 12,
      zones  = { 'Yuhtunga_Jungle', 'Western_Altepa_Desert', 'Qufim_Island' },
      roster = { { name = 'Gjenganger', group = 36, zone = 136 }, { name = 'Feuerunke', group = 34, zone = 136 }, { name = 'Tammuz', group = 51, zone = 102 } } },
    { key = 'HYACINTH', name = 'Hyacinth Stratum', base = 15,
      zones  = { 'Beaucedine_Glacier', 'The_Sanctuary_of_ZiTah', 'RoMaeve', 'Lufaise_Meadows', 'Misareaux_Coast', 'Attohwa_Chasm' },
      roster = { { name = 'Aglaophotis', group = 39, zone = 288 }, { name = 'Erebus', group = 35, zone = 136 }, { name = 'Gorehound', group = 37, zone = 136 } } },
    { key = 'AMBER', name = 'Amber Stratum', base = 18,
      zones  = { 'Behemoths_Dominion', 'Uleguerand_Range', 'RuAun_Gardens' },
      roster = { { name = 'Yilbegan', group = 32, zone = 136 }, { name = 'Lord_Ruthven', group = 33, zone = 136 }, { name = 'Erebus', group = 35, zone = 136 } } },
}
-- Precomputed lookups.
C.STRATUM_BY_KEY = {}
C.ZONE_STRATUM   = {}
C.UNIQUE_NMS     = {}  -- set: NM name -> true; length = unique roster size
for _, s in ipairs(C.STRATA) do
    C.STRATUM_BY_KEY[s.key] = s
    for _, z in ipairs(s.zones) do C.ZONE_STRATUM[z] = s.key end
    for _, nm in ipairs(s.roster or {}) do C.UNIQUE_NMS[nm.name] = true end
end
-- Cached count of the unique NM roster across all strata (deduped, since
-- Gorehound and Erebus each appear in two strata). Read by the Weapon Forge
-- Mythic Stage II preflight via xi.voidwatch.uniqueNmCount below.
C.UNIQUE_NM_COUNT = 0
for _ in pairs(C.UNIQUE_NMS) do C.UNIQUE_NM_COUNT = C.UNIQUE_NM_COUNT + 1 end


-- REMOVED 2026-07-13 (owner: Voidwatch drops should match the docs page): the
-- tier-gated GEAR_BANDS + gearRoll system fired on top-quality Pyxis rolls and
-- silently injected 53 items (Nyame/Malignance/Sakpata/Agwu/Jhakri +1/+2,
-- Ochain, Daurdabla, Idris/Marsyas/Compensator/Epeolatry, Trust/Prestige/
-- Sworn apex sets) that never appeared on docs/endgame/voidwatch.md -- so a
-- player who got an Epeolatry from a Yacumama pyxis had no way to know it was
-- even possible. Voidwatch drops are now strictly the per-NM rare/uncommon
-- pool + shared common (documented) -- see C.NM_LOOT above. If a future
-- redesign wants to reintroduce tier-gated bonus gear, do it with docgen
-- coverage from the start (a new marker section, item lists parsed by
-- tools/docgen/generators/voidwatch.py) so the site never lags again.
-- The Voidwatch.lua roll loop stops calling C.gearRoll in the same commit,
-- so nothing else references these constants -- safe to hard-delete.

return C
