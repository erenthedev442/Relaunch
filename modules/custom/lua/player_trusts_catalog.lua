-----------------------------------
-- player_trusts_catalog.lua
-- Config for the Player Trust system (see player_trusts.lua).
--
-- All knobs live here so balance edits don't require touching engine
-- code. Reload the module after editing.
-----------------------------------
local catalog = {}

catalog.npcPos =
{
    zone     = 'GM_Home',
    zoneId   = 210,
    x        =   7.500,
    y        =  0.000,
    z        = -10.000,
    rotation =  128,
}

-- Minutes of shared party-in-zone time before a pair unlocks each other.
-- Bumped every 60 seconds while both characters are online, in the same
-- party, and in the same zone.
catalog.unlockMinutes = 30

-- Tier progression. Tier 1 is granted automatically on unlock; tiers 2-5
-- are bought via the Companion Master NPC.
--
-- Each tier has two halves:
--   (A) Legacy "buff" summon (v1) - kept as a fallback for low-effort
--       summons. Applies flat stat mods to the CASTER for a duration.
--   (B) "Real Trust" summon (v2) - hijacks an unused Trust spell, spawns
--       a real follower with combat AI. Stat scaling lives in `trustMods`
--       and is applied to the spawned mob's modifiers.
--
-- Tier 1 (Bronze) is the baseline; each step up scales the trustMods
-- multiplier linearly. Mythic is roughly 2x Bronze across the board.
catalog.tiers =
{
    -- Gil costs scaled 20x from the original (25k / 75k / 200k / 500k) so
    -- maxing a Trust takes 16M cumulative - a real sink against Legendary's
    -- 100x quest gil / 10x mob gil rates.
    [1] = { label = 'Bronze',  buffDurationMin = 30, statBonus =  3, hpBonus =  20, mpBonus = 10, gilCost =        0, trustMult = 1.0 },
    [2] = { label = 'Silver',  buffDurationMin = 45, statBonus =  6, hpBonus =  50, mpBonus = 25, gilCost =   500000, trustMult = 1.25 },
    [3] = { label = 'Gold',    buffDurationMin = 60, statBonus = 10, hpBonus = 100, mpBonus = 50, gilCost =  1500000, trustMult = 1.5 },
    [4] = { label = 'Plat.',   buffDurationMin = 90, statBonus = 14, hpBonus = 150, mpBonus = 75, gilCost =  4000000, trustMult = 1.75 },
    [5] = { label = 'Mythic',  buffDurationMin = 120,statBonus = 20, hpBonus = 250, mpBonus = 125,gilCost = 10000000, trustMult = 2.0 },
}
catalog.maxTier = 5

-- Base mob mods for the player-Trust at tier 1 (Bronze). Each entry is
-- { xi.mod.X, base_value }. The actual applied value is base_value
-- multiplied by the current tier's `trustMult`. So a Mythic-tier Trust
-- has 2x the base values defined here.
catalog.trustBaseMods =
{
    -- Survivability - HPP is a percentage modifier, value 20 = +20% HP.
    { xi.mod.HPP,    20 },
    { xi.mod.DEF,    50 },
    { xi.mod.MEVA,   30 },
    -- Offense.
    { xi.mod.ATT,    50 },
    { xi.mod.ACC,    30 },
    { xi.mod.MATT,   30 },
    { xi.mod.MACC,   30 },
    { xi.mod.HASTE_GEAR, 150 },  -- 15% haste (1024ths of 1%)
    -- Stat sticks - buff the player via aura-style mods on the Trust.
    { xi.mod.STR,    15 },
    { xi.mod.DEX,    15 },
    { xi.mod.VIT,    15 },
}

-- Hijacked Trust spell pool (Option A - multiple named slots).
--
-- Five obscure Trust spells, one per slot. When a player unlocks any
-- friend, ALL five spells are added to their book - so they can run a
-- full party of friend-Trusts at once. Each slot tracks WHICH friend
-- is currently assigned to it via the PT_Slot_<N> CharVar.
--
-- Picking criteria: each chosen Trust is a Walk of Echoes / Records of
-- Eminence / Voidwatch Trust that's nearly impossible to obtain on a
-- private server through normal means, so repurposing it costs nothing
-- meta-wise. The internal name is what the engine resolves to the spell
-- script file - that's what addOverride keys off.
catalog.trustSlots =
{
    { slot = 1, spellId = 950, name = 'kuyin_hathdenna' }, -- Trust: Kuyin Hathdenna
    { slot = 2, spellId = 985, name = 'rosulatia'       }, -- Trust: Rosulatia
    { slot = 3, spellId = 986, name = 'teodor'          }, -- Trust: Teodor
    { slot = 4, spellId = 989, name = 'king_of_hearts'  }, -- Trust: King of Hearts
    { slot = 5, spellId = 990, name = 'morimar'         }, -- Trust: Morimar
}
catalog.maxSlots = #catalog.trustSlots

-- Race -> player-model-ID map. Used at Trust spawn time so the mob's
-- silhouette matches the friend's race. Face capture (separate field)
-- is for future enhancement (would need a constructed look hex via
-- setLook); for now we use a generic body per race.
--
-- Race numbers come from xi.race in scripts/enum/race.lua:
--   1=Hume M, 2=Hume F, 3=Elvaan M, 4=Elvaan F, 5=Tarutaru M, 6=Tarutaru F,
--   7=Mithra, 8=Galka
catalog.raceModels =
{
    [1] = 32,   -- Hume Male
    [2] = 37,   -- Hume Female
    [3] = 42,   -- Elvaan Male
    [4] = 47,   -- Elvaan Female
    [5] = 30,   -- Tarutaru Male (best-effort)
    [6] = 31,   -- Tarutaru Female (best-effort)
    [7] = 36,   -- Mithra (best-effort)
    [8] = 1,    -- Galka
}
catalog.defaultModelId = 32  -- fallback for unknown races

-- How often (in seconds) we tick each online player's friendship timer.
-- 60s = 1 minute per tick. Lower = more accurate but more work.
catalog.tickIntervalSec = 60

return catalog
