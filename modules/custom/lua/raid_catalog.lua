-----------------------------------
-- raid_catalog.lua
-- Config for the weekly raid boss (see RaidBoss.lua).
--
-- THE STAR-DEVOURER: one server-shared, multi-phase scripted raid
-- fight, popped on demand at Escha-RuAun (next to the Voidspire
-- Warden). Anyone may join the brawl; the WEEKLY part is the reward -
-- each character's full payout is once per ISO week (Monday 00:00 UTC,
-- same anchor as the Mythic dungeon key), with a small consolation for
-- repeat kills.
--
-- Mechanics (all data-driven below):
--   * STANCE DANCE - from 90% HP the boss alternates Aegis (physical
--     immunity-ish) and Umbral (magic immunity-ish) stances on a
--     timer. Swap your damage type or watch numbers vanish.
--   * TENDRILS - at 75% and 30% it spawns Starspawn Tendrils and
--     gains heavy regen until they die ("the tendrils feed the maw").
--   * Dispel sweep at 50%, fury at 15%, soft enrage at 12 minutes.
-----------------------------------
local catalog = {}

-- NPC: the Voidgate Sentinel, posted left of the Voidspire Warden.
catalog.npcPos =
{
    zone     = 'Escha_RuAun',
    zoneId   = 289,
    x        = -9.000,
    y        = -34.277,
    z        = -466.980,
    rotation = 192,
}

-- Mob templates come from the Game Master pools (game_master_catalog,
-- groupIds 11400+ registered in zone 289) - no new SQL.
catalog.bossPoolDifficulty = 'Insane'  -- stat template donor for the boss
catalog.addsPoolDifficulty = 'Hard'    -- stat template donor for tendrils

catalog.boss =
{
    name      = 'The Star-Devourer',
    level     = 200,
    hpMult    = 45.0,     -- a long, phase-driven fight - not a burn check
    modelSize = 3,
    mods =
    {
        [xi.mod.ATT]           = 3200,
        [xi.mod.ACC]           = 1050,
        [xi.mod.STR]           = 140,
        [xi.mod.DEX]           = 140,
        [xi.mod.HASTE_GEAR]    = 180,
        [xi.mod.DOUBLE_ATTACK] = 12,
        [xi.mod.REGAIN]        = 30,   -- steady TP pressure
    },
    spawnRingMin = 18.0,
    spawnRingMax = 22.0,
}

-- ============================================================
-- STANCE DANCE
-- ============================================================
-- Starts when HP first drops to startHpp. Stances alternate every
-- periodSec, applied as setMod OVERRIDES on the two damage-taken mods
-- (absolute values - the module sets them, never stacks them).
-- DMGPHYS / DMGMAGIC are the engine's damage-taken mods on a /10000 scale
-- (battleutils divides by 10000): -9000 = take 90% less (near-immune),
-- +3000 = take 30% more (vulnerable).
catalog.stance =
{
    startHpp  = 90,
    periodSec = 45,
    stances =
    {
        {
            id  = 'aegis',
            msg = 'The Star-Devourer hardens into AEGIS STANCE - blades glance off! (Magic rips through.)',
            mods = { [xi.mod.DMGPHYS] = -9000, [xi.mod.DMGMAGIC] = 3000 },
        },
        {
            id  = 'umbral',
            msg = 'The Star-Devourer dissolves into UMBRAL STANCE - spells gutter out! (Steel bites deep.)',
            mods = { [xi.mod.DMGPHYS] = 3000, [xi.mod.DMGMAGIC] = -9000 },
        },
    },
}

-- ============================================================
-- HP PHASES (walked in order, each fires once)
-- ============================================================
-- action 'tendrils': spawn `count` adds; boss gains regenWhileAlive
--                    until every tendril is dead.
-- action 'dispel'  : strips `count` buffs from everyone engaged nearby.
-- action 'fury'    : permanent ATT/haste spike.
catalog.phases =
{
    { hp = 75, action = 'tendrils', count = 2, level = 170, hpMult = 1.5,
      name = 'Starspawn Tendril', regenWhileAlive = 2000,
      message = 'Starspawn Tendrils burst from the void - they FEED the Devourer! Kill them!' },
    { hp = 50, action = 'dispel',   count = 4,
      message = 'A wave of unbeing strips your protections!' },
    { hp = 30, action = 'tendrils', count = 3, level = 180, hpMult = 1.8,
      name = 'Starspawn Tendril', regenWhileAlive = 3500,
      message = 'The Devourer shrieks - more tendrils erupt! Sever them!' },
    { hp = 15, action = 'fury',     att = 2500, haste = 150,
      message = 'THE STAR-DEVOURER UNLEASHES ITS FINAL FURY!' },
}

-- Soft enrage: at this many seconds into the fight, a massive
-- permanent buff lands (the fight becomes a race).
catalog.softEnrage =
{
    sec     = 720,    -- 12 minutes
    att     = 6000,
    haste   = 300,
    message = 'COSMIC ENRAGE - the Star-Devourer ascends beyond mortal reach!',
}

-- Leash/reset: if no living player is within leashRadius of the boss
-- for two consecutive watchdog checks, the fight resets (despawn).
catalog.watchdogSec = 30
catalog.leashRadius = 60.0

-- ============================================================
-- REWARDS
-- ============================================================
catalog.reward =
{
    radius        = 50.0,   -- players this close to the kill get credit
    weeklyMarks   = 2500,   -- full weekly clear
    weeklyInfamy  = 500,
    repeatMarks   = 250,    -- already claimed this week
}

return catalog
