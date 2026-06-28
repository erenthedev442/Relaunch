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
}

return C
