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
C.SPAWN_DIST_MIN = 8
C.SPAWN_DIST_MAX = 13

-- ── Tier scaling (infinite; tier >= 1) ─────────────────────────────────────
-- Placeholder curves -- tune in playtest.
function C.nmLevel(tier) return 78 + tier * 4 end
function C.nmHp(tier)    return 180000 + tier * 110000 end
function C.nmMods(tier)
    return {
        [xi.mod.ATT]     = 700 + tier * 200,
        [xi.mod.ACC]     = 550 + tier * 110,
        [xi.mod.DEF]     = 280 + tier * 70,
        [xi.mod.EVA]     = 180 + tier * 55,
        [xi.mod.MATT]    = 280 + tier * 85,
        [xi.mod.MACC]    = 220 + tier * 60,
        [xi.mod.MDEF]    = 120 + tier * 30,
        [xi.mod.DMGPHYS] = -800,             -- slightly tanky (engine caps at -50%)
        [xi.mod.REGEN]   = 50 + tier * 30,
    }
end

-- ── Rewards (the "Riftworn Pyxis") ─────────────────────────────────────────
function C.cruorReward(tier) return 800 + tier * 350 end
function C.expReward(tier)   return 1500 + tier * 600 end

-- ── NM roster: real Voidwalker NM templates {name, group, zone}. The dynamic
-- entity borrows the group's pool (the void-creature model/family); it spawns at
-- the player's location regardless of the template zone. Pulled from xi_relaunch
-- mob_groups; add more for variety.
C.ROSTER =
{
    { name = 'Erebus',       group = 35, zone = 136 },
    { name = 'Gorehound',    group = 37, zone = 136 },
    { name = 'Gjenganger',   group = 36, zone = 136 },
    { name = 'Feuerunke',    group = 34, zone = 136 },
    { name = 'Lord_Ruthven', group = 33, zone = 136 },
    { name = 'Yilbegan',     group = 32, zone = 136 },
    { name = 'Capricornus',  group = 48, zone = 101 },
    { name = 'Aglaophotis',  group = 39, zone = 288 },
}

-- ── charVars ───────────────────────────────────────────────────────────────
C.V =
{
    born    = 'Voidwatch_Born',
    tier    = 'Voidwatch_Tier',     -- highest tier cleared (your abyssite rank); next rift = tier+1
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

-- ── Hardcore mechanics (mob_mechanics_library mechCfg, scales by tier) ──────
-- Stance dance (phys/mag immunity windows) does NOT block Lights -- the weakness
-- listeners fire on USE, not on damage, so you can keep probing through a stance.
function C.mechCfg(tier)
    local cfg =
    {
        name            = 'Voidwalker',
        targetPartyOnly = true,
        drain           = { periodSec = 12, healPct = 2 },   -- mild anti-turtle
    }
    if tier >= 2 then
        cfg.stance =
        {
            startHpp = 100, periodSec = 22,
            stances =
            {
                { mods = { [xi.mod.DMGPHYS] = -10000, [xi.mod.DMGMAGIC] = 0 },     msg = 'hardens -- weapons glance off!' },
                { mods = { [xi.mod.DMGPHYS] = 0,      [xi.mod.DMGMAGIC] = -10000 }, msg = 'shimmers -- magic warps aside!' },
            },
        }
    end
    if tier >= 3 then cfg.aoe    = { periodSec = 14, dmgPct = 16, msg = 'unleashes a void shockwave!' } end
    if tier >= 4 then cfg.cc     = { periodSec = 28, effect = xi.effect.TERROR, power = 1, dur = 4, msg = 'voids your courage!' } end
    if tier >= 5 then cfg.enrage = { sec = 300, att = 3500, haste = 150, msg = 'the void begins to devour all!' } end
    if tier >= 6 then cfg.doom   = { startHpp = 12, dur = 30, msg = 'marks you for the void!' } end
    if tier >= 7 then
        cfg.phases =
        {
            { hp = 50, action = 'fury', att = 2500, haste = 100, msg = 'enters a void frenzy!' },
            { hp = 20, action = 'nuke', dmgPct = 35, msg = 'erupts with annihilating force!' },
        }
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
for _, s in ipairs(C.STRATA) do
    C.STRATUM_BY_KEY[s.key] = s
    for _, z in ipairs(s.zones) do C.ZONE_STRATUM[z] = s.key end
end

return C
