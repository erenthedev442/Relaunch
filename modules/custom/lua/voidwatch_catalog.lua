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
    cruor   = 'Voidwatch_Cruor',
    shards  = 'Voidwatch_Shards', -- atmacite shards (banked from Pearl lights; spend at the Refiner, Phase 2b)
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

return C
