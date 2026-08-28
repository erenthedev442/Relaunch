-----------------------------------
-- hunting_league_catalog.lua
-- Configuration for the Hunting League system.
-- Edit this file only - HuntingLeague.lua reads it automatically.
-----------------------------------

return
{
    -- =========================================================
    -- ZONE CONFIGURATION
    -- =========================================================
    huntZoneId   = xi.zone.ESCHA_ZITAH,
    huntZonePath = 'xi.zones.Escha_ZiTah',
    combatLevel  = 99, -- All ranks use stat overlays for difficulty, not level correction.

    -- Position of the Hunt Seals NPC (tier/rank + seal purchases). This is
    -- also the !hunt warp landing spot, so updates here should sync to
    -- scripts/commands/hunt.lua.
    sealsPos       = { x =  0.0000, y = -0.5000, z = -30.0000, rot = 128 },

    -- Position of the Zone Guide NPC (warps players to a tier cluster area).
    zoneGuidePos   = { x =  3.0000, y = -0.5000, z = -30.0000, rot = 128 },

    -- (accessoriesPos retired 2026-08-04 — Hunt-Marks Accessories NPC removed;
    -- medal Accessory_NPC at accessory_catalog.vendorPos owns that shop.)

    -- Fallback spawner position for tier NPCs that have no spawnerPos defined.
    spawnerPos     = { x =  8.0000, y = -0.5000, z = -30.0000, rot = 128 },

    -- Fallback spawn position used if a mob entry has no spawnPos defined.
    -- Each mob now has its own arena position (spawnPos field in tiers table)
    -- so mobs fan out across the zone instead of piling up in one spot.
    mobSpawnPos = { x = 0.0, y = -0.5, z = 50.0, rot = 0 },

    -- Currency display name
    currencyName = 'Hunt Marks',

    -- =========================================================
    -- SPAWN BEHAVIOUR
    -- =========================================================
    -- Un-engaged despawn: a popped NM that nobody engages within this many
    -- seconds despawns on its own, so an ignored or accidental pop doesn't
    -- clog the arena (and the duplicate-spawn guard frees up again). The
    -- countdown is cancelled the instant a player engages the NM, so an
    -- active fight is never interrupted. Set to 0 to disable.
    unengagedDespawnSecs = 120,  -- 120s - players need time to walk to their arena in the large zone

    -- =========================================================
    -- TIER DEFINITIONS
    -- =========================================================
    --
    -- Power ladder (2026-05 rebalance - "too easy" pass):
    --
    -- RELAUNCH Phase 2 retune (2026-06-24): ATT/DEF/DA/TA/REGEN cut to match
    -- the lower relaunch player power curve (Legendary keeps the values above).
    -- T1 minor DEF bump; T2 minor DA cut; T3 -40% ATT/-25% DEF, DA->12, TA
    -- removed; T4 -45% ATT/-35% DEF, DA->15/TA->5; T5 (AV/PW) -52% ATT/-50%
    -- DEF, DA->20/TA->8; Shinryu -60% ATT/-78% DEF, DA->25/TA->10.
    -- 2026-07-14 damage-ceiling pass: flat REGEN was cut to 12/24/40/70/120
    -- (Shinryu 175), and percentage drain from 2% to 0.25%. This keeps
    -- anti-turtle pressure without erasing typical 200k-300k weaponskills.
    -- 2026-07-16 entry pass: Rank I HP 6x->5x, DEF 600->520,
    -- EVA 180->140, and MEVA 180->150 for fresh Lv99 players.
    --
    --   Every tier now has hpBoost (was T5-only) so fights actually
    --   last. HASTE_GEAR (1024ths of 1%), DOUBLE_ATTACK / TRIPLE_ATTACK
    --   (% chance), and REGEN (HP/tick) are layered on so mobs swing
    --   hard, swing often, and self-heal - players have to commit.
    --   MDEF + MEVA prevent caster groups from one-shotting via nuke.
    --
    --   T1 Initiate   5x HP, mild challenge for a fresh Lv99
    --   T2 Hunter     5x HP, real fight - needs tools/buffs
    --   T3 Elite      8x HP, sustained party fight
    --   T4 Champion  12x HP, brick wall for solo, group content
    --   T5 Legend    20x HP, endgame fights (AV / PW)
    --   T5 Shinryu   40x HP at Lv225-250, server boss
    --
    -- Engine note: xi.mod.HASTE_GEAR is in 1024ths of 1%, so 256 = 25%.
    -- Engine clamps total haste at 25%-ish anyway so going past ~256 in
    -- HASTE_GEAR alone is wasted - Haste II/III JAs / Refresh aside.
    --
    tiers =
    {
        -- TIER 1 - Classic starter HNMs (lv15-35)
        {
            tier       = 1,
            name       = 'Rank I - Initiate',
            unlockCost = 0,
            spawnerPos = { x = -41.5941, y = 0.1103, z = 73.7704, rot = 176 },
            warpPos    = { x = -41.5941, y = 0.1103, z = 73.7704, rot = 176 },
            mobs =
            {
                { name = 'Leaping_Lizzy',    label = 'Leaping Lizzy',    points = 15,  groupId = 11355, minLv = 99, maxLv = 99,
                  spawnPos = { x =  -56.6, y =  0.11, z =  73.8, rot =   0 },  -- T1 cluster: W
                  hpBoost = 5,
                  mods = {
                      [xi.mod.DEF] = 520,
                      [xi.mod.ATT] = 2700,
                      [xi.mod.ACC] = 270,   -- T1 normalized target
                      [xi.mod.EVASION] = 140,
                      [xi.mod.MEVA] = 150,
                      [xi.mod.STR] = 75,    -- + damage on hit
                      [xi.mod.DEX] = 75,    -- DEX feeds ACC formula (~0.75 DEX = 1 ACC)
                      [xi.mod.HASTE_GEAR] = 150,   -- ~10%
                      [xi.mod.DOUBLE_ATTACK] = 8,
                      [xi.mod.REGEN] = 12,
                  },
                },
                { name = 'Valkurm_Emperor',  label = 'Valkurm Emperor',  points = 15,  groupId = 11356, minLv = 99, maxLv = 99,
                  spawnPos = { x =  -41.6, y =  0.11, z =  58.8, rot = 128 },  -- T1 cluster: S
                  drops = { { id = 8983, qty = 5 } },  -- Emperor Arthro's Shell (Augment Affinity: DEX/Accuracy)
                  hpBoost = 5,
                  mods = {
                      [xi.mod.DEF] = 520,
                      [xi.mod.ATT] = 2700,
                      [xi.mod.ACC] = 270,   -- T1 normalized target
                      [xi.mod.EVASION] = 140,
                      [xi.mod.MEVA] = 150,
                      [xi.mod.HASTE_GEAR] = 150,
                      [xi.mod.DOUBLE_ATTACK] = 8,
                      [xi.mod.REGEN] = 12,
                  },
                },
                { name = 'Tom_Tit_Tat',      label = 'Tom Tit Tat',      points = 15,  groupId = 11357, minLv = 99, maxLv = 99,
                  spawnPos = { x =  -26.6, y =  0.11, z =  73.8, rot = 192 },  -- T1 cluster: E
                  hpBoost = 5,
                  mods = {
                      [xi.mod.DEF] = 520,
                      [xi.mod.ATT] = 2700,
                      [xi.mod.ACC] = 270,   -- T1 normalized target
                      [xi.mod.EVASION] = 140,
                      [xi.mod.MEVA] = 150,
                      [xi.mod.HASTE_GEAR] = 150,
                      [xi.mod.DOUBLE_ATTACK] = 8,
                      [xi.mod.REGEN] = 12,
                  },
                },
            },
        },

        -- TIER 2 - Mid-tier HNMs (lv40-60)
        {
            tier       = 2,
            name       = 'Rank II - Hunter',
            unlockCost = 150,
            spawnerPos = { x = 40.9101, y = 0.4831, z = 132.8770, rot = 71 },
            warpPos    = { x = 40.9101, y = 0.4831, z = 132.8770, rot = 71 },
            mobs =
            {
                { name = 'Roc',         label = 'Roc',         points = 28, groupId = 11358, minLv = 99, maxLv = 99,
                  spawnPos = { x =   25.9, y =  0.48, z =  132.9, rot =   0 },  -- T2 cluster: W
                  drops = { { id = 843, qty = 5 } },  -- Giant Bird Plume (Augment Affinity: AGI/Evasion/Haste)
                  hpBoost = 9,
                  mods = {
                      [xi.mod.DEF] = 825,
                      [xi.mod.ATT] = 4500,
                      [xi.mod.ACC] = 900,   -- T2 normalized target
                      [xi.mod.EVASION] = 270,
                      [xi.mod.MEVA] = 360,
                      [xi.mod.MDEF] = 180,
                      [xi.mod.HASTE_GEAR] = 225,   -- ~15%
                      [xi.mod.DOUBLE_ATTACK] = 12,
                      [xi.mod.REGEN] = 24,
                  },
                },
                { name = 'Bomb_Queen',  label = 'Bomb Queen',  points = 28, groupId = 11359, minLv = 99, maxLv = 99,
                  spawnPos = { x =   40.9, y =  0.48, z =  117.9, rot = 128 },  -- T2 cluster: S
                  hpBoost = 9,
                  mods = {
                      [xi.mod.DEF] = 825,
                      [xi.mod.ATT] = 4500,
                      [xi.mod.ACC] = 900,   -- T2 normalized target
                      [xi.mod.EVASION] = 270,
                      [xi.mod.MEVA] = 360,
                      [xi.mod.MDEF] = 180,
                      [xi.mod.STR] = 150,
                      [xi.mod.DEX] = 150,
                      [xi.mod.HASTE_GEAR] = 225,
                      [xi.mod.DOUBLE_ATTACK] = 12,
                      [xi.mod.REGEN] = 24,
                  },
                },
                { name = 'Aquarius',    label = 'Aquarius',    points = 28, groupId = 11360, minLv = 99, maxLv = 99,
                  spawnPos = { x =   55.9, y =  0.48, z =  132.9, rot = 192 },  -- T2 cluster: E
                  drops = { { id = 908, qty = 5 } },  -- Adamantoise Shell (Augment Affinity: VIT/Defense)
                  hpBoost = 9,
                  mods = {
                      [xi.mod.DEF] = 825,
                      [xi.mod.ATT] = 4500,
                      [xi.mod.ACC] = 900,   -- T2 normalized target
                      [xi.mod.EVASION] = 270,
                      [xi.mod.MEVA] = 360,
                      [xi.mod.MDEF] = 180,
                      [xi.mod.STR] = 150,
                      [xi.mod.DEX] = 150,
                      [xi.mod.HASTE_GEAR] = 225,
                      [xi.mod.DOUBLE_ATTACK] = 12,
                      [xi.mod.REGEN] = 24,
                  },
                },
            },
        },

        -- TIER 3 - Classic HNMs (lv60-75)
        {
            tier       = 3,
            name       = 'Rank III - Elite',
            unlockCost = 650,
            spawnerPos = { x = 48.6277, y = 0.8776, z = 18.8663, rot = 215 },
            warpPos    = { x = 48.6277, y = 0.8776, z = 18.8663, rot = 215 },
            mobs =
            {
                { name = 'Serket',    label = 'Serket',    points = 45, groupId = 11361, minLv = 99, maxLv = 99,
                  spawnPos = { x =   33.6, y =  0.88, z =   18.9, rot =  96 },  -- T3 cluster: W
                  drops = { { id = 1015, qty = 5 } },  -- Sand Bat Fang (Augment Affinity: Pet)
                  hpBoost = 15,
                  mods = {
                      [xi.mod.DEF] = 929,
                      [xi.mod.ATT] = 4320,
                      [xi.mod.ACC] = 1260,   -- T3 normalized target
                      [xi.mod.EVASION] = 450,
                      [xi.mod.MEVA] = 540,
                      [xi.mod.MDEF] = 360,
                      [xi.mod.HASTE_GEAR] = 300,   -- ~20%
                      [xi.mod.DOUBLE_ATTACK] = 12,
                      [xi.mod.TRIPLE_ATTACK] = 0,   -- relaunch: TA removed
                      [xi.mod.REGEN] = 40,
                  },
                },
                { name = 'Vrtra',     label = 'Vrtra',     points = 45, groupId = 11362, minLv = 99, maxLv = 99,
                  spawnPos = { x =   48.6, y =  0.88, z =    3.9, rot =  64 },  -- T3 cluster: S
                  drops = { { id = 909, qty = 5 } },  -- Guivre's Skull (Augment Affinity: INT/Magic)
                  hpBoost = 15,
                  mods = {
                      [xi.mod.DEF] = 929,
                      [xi.mod.ATT] = 4320,
                      [xi.mod.ACC] = 1260,   -- T3 normalized target
                      [xi.mod.EVASION] = 450,
                      [xi.mod.MEVA] = 540,
                      [xi.mod.MDEF] = 360,
                      [xi.mod.STR] = 300,
                      [xi.mod.DEX] = 300,
                      [xi.mod.HASTE_GEAR] = 300,
                      [xi.mod.DOUBLE_ATTACK] = 12,
                      [xi.mod.TRIPLE_ATTACK] = 0,   -- relaunch: TA removed
                      [xi.mod.REGEN] = 40,
                  },
                },
                { name = 'Simurgh',   label = 'Simurgh',   points = 45, groupId = 11363, minLv = 99, maxLv = 99,
                  spawnPos = { x =   63.6, y =  0.88, z =   18.9, rot = 128 },  -- T3 cluster: E
                  drops = { { id = 844, qty = 5 } },  -- Phoenix Feather (Augment Affinity: MND/Healing)
                  -- Difficulty bump (2026-06-13, owner request): tuned a notch
                  -- above its T3 tier-mates (Serket/Vrtra) -- +25% HP, harder &
                  -- faster hits (ATT/HASTE/Double+Triple Atk), and stronger Regen
                  -- so a group has to out-DPS the self-heal. Dial up/down here.
                  hpBoost = 18,
                  mods = {
                      [xi.mod.DEF] = 929,
                      [xi.mod.ATT] = 4752,  -- T3+ notch (relaunch -40%, was 7920)
                      [xi.mod.ACC] = 1350,   -- T3+ (was 700)
                      [xi.mod.EVASION] = 450,
                      [xi.mod.MEVA] = 540,
                      [xi.mod.MDEF] = 360,
                      [xi.mod.STR] = 300,
                      [xi.mod.DEX] = 300,
                      [xi.mod.HASTE_GEAR] = 345,   -- ~22% (was 200)
                      [xi.mod.DOUBLE_ATTACK] = 12,    -- relaunch (was 30)
                      [xi.mod.TRIPLE_ATTACK] = 0,     -- relaunch: TA removed
                      [xi.mod.REGEN] = 40,   -- damage-ceiling pass (was 413)
                  },
                },
            },
        },

        -- TIER 4 - Sky / Sea / Wyrm-tier (lv80-90)
        {
            tier       = 4,
            name       = 'Rank IV - Champion',
            unlockCost = 1500,
            spawnerPos = { x = 22.0112, y = 0.8983, z = -121.4367, rot = 126 },
            warpPos    = { x = 22.0112, y = 0.8983, z = -121.4367, rot = 126 },
            mobs =
            {
                { name = 'Nidhogg',       label = 'Nidhogg',       points = 75, groupId = 11364, minLv = 99, maxLv = 99,
                  spawnPos = { x =    7.0, y =  0.90, z = -121.4, rot =  96 },  -- T4 cluster: W
                  drops = { { id = 1122, qty = 5 }, { id = 10037, qty = 5 }, { id = 865, qty = 5 } },  -- Wyvern Skin (Affinity: HP/Regen) + Fafnir's Scale (Augment Sage rank 4) + Handful of Nidhogg's Scales (Augment Sage rank 2)
                  hpBoost = 21,
                  mods = {
                      [xi.mod.DEF] = 1162,
                      [xi.mod.ATT] = 5940,
                      [xi.mod.ACC] = 1620,   -- T4 normalized target
                      [xi.mod.EVASION] = 630,
                      [xi.mod.MEVA] = 720,
                      [xi.mod.MDEF] = 630,
                      [xi.mod.HASTE_GEAR] = 375,   -- ~25%
                      [xi.mod.DOUBLE_ATTACK] = 15,
                      [xi.mod.TRIPLE_ATTACK] = 5,
                      [xi.mod.REGEN] = 70,
                  },
                },
                { name = 'King_Behemoth', label = 'King Behemoth', points = 75, groupId = 11365, minLv = 99, maxLv = 99,
                  spawnPos = { x =   22.0, y =  0.90, z = -136.4, rot =  64 },  -- T4 cluster: S
                  drops = { { id = 893, qty = 5 }, { id = 883, qty = 5 } },  -- Giant Femur (Affinity: STR/Attack) + Behemoth Horn (Augment Sage rank 1)
                  hpBoost = 21,
                  mods = {
                      [xi.mod.DEF] = 1162,
                      [xi.mod.ATT] = 5940,
                      [xi.mod.ACC] = 1620,   -- T4 normalized target
                      [xi.mod.EVASION] = 630,
                      [xi.mod.MEVA] = 720,
                      [xi.mod.MDEF] = 630,
                      [xi.mod.STR] = 450,
                      [xi.mod.DEX] = 450,
                      [xi.mod.HASTE_GEAR] = 375,
                      [xi.mod.DOUBLE_ATTACK] = 15,
                      [xi.mod.TRIPLE_ATTACK] = 5,
                      [xi.mod.REGEN] = 70,
                  },
                },
                { name = 'Kirin',         label = 'Kirin',         points = 75, groupId = 11366, minLv = 99, maxLv = 99,
                  spawnPos = { x =   37.0, y =  0.90, z = -121.4, rot = 128 },  -- T4 cluster: E
                  drops = { { id = 2893, qty = 5 }, { id = 10038, qty = 5 } },  -- Gargantuan Black Tiger Fang (Affinity: Skill+) + Kirin's Mane (Augment Sage rank 5)
                  hpBoost = 21,
                  mods = {
                      [xi.mod.DEF] = 1162,
                      [xi.mod.ATT] = 5940,
                      [xi.mod.ACC] = 1620,   -- T4 normalized target
                      [xi.mod.EVASION] = 630,
                      [xi.mod.MEVA] = 720,
                      [xi.mod.MDEF] = 630,
                      [xi.mod.STR] = 450,
                      [xi.mod.DEX] = 450,
                      [xi.mod.HASTE_GEAR] = 375,
                      [xi.mod.DOUBLE_ATTACK] = 15,
                      [xi.mod.TRIPLE_ATTACK] = 5,
                      [xi.mod.REGEN] = 70,
                  },
                },
            },
        },

        -- TIER 5 - Legend (lv99 superbosses)
        {
            tier       = 5,
            name       = 'Rank V - Legend',
            unlockCost = 3000,
            spawnerPos = { x = 433.8451, y = 0.1066, z = -199.3157, rot = 119 },
            warpPos    = { x = 433.8451, y = 0.1066, z = -199.3157, rot = 119 },
            mobs =
            {
                { name = 'Absolute_Virtue',    label = 'Absolute Virtue',    points = 100, groupId = 11367, minLv = 99, maxLv = 99,
                  spawnPos = { x =  418.8, y =  0.11, z = -199.3, rot =  96 },  -- T5 cluster: W
                  drops = { { id = 1473, qty = 5 } },  -- HQ Scorpion Shell (Augment Affinity: WS DMG+)
                  hpBoost = 36,
                  mods = {
                      [xi.mod.DEF] = 1375,
                      [xi.mod.ATT] = 7776,
                      [xi.mod.ACC] = 3240,  -- unmissable except vs huge EVA stacks
                      [xi.mod.EVASION] = 900,
                      [xi.mod.MEVA] = 1080,
                      [xi.mod.MDEF] = 1080,
                      [xi.mod.STR] = 750,
                      [xi.mod.DEX] = 750,
                      [xi.mod.HASTE_GEAR] = 450,   -- ~30% (capped by engine)
                      [xi.mod.DOUBLE_ATTACK] = 20,
                      [xi.mod.TRIPLE_ATTACK] = 8,
                      [xi.mod.REGEN] = 120,
                  },
                },
                { name = 'Pandemonium_Warden', label = 'Pandemonium Warden', points = 100, groupId = 11368, minLv = 99, maxLv = 99,
                  spawnPos = { x =  433.8, y =  0.11, z = -214.3, rot =  64 },  -- T5 cluster: S
                  drops = { { id = xi.item.KHIMAIRA_HORN, qty = 5 }, { id = 2372, qty = 5 } },  -- Khimaira Horn + Khimaira Mane (Augment Affinity: CHR/Charm)
                  hpBoost = 36,
                  mods = {
                      [xi.mod.DEF] = 1375,
                      [xi.mod.ATT] = 7776,
                      [xi.mod.ACC] = 900,
                      [xi.mod.EVASION] = 900,
                      [xi.mod.MEVA] = 1080,
                      [xi.mod.MDEF] = 1080,
                      [xi.mod.HASTE_GEAR] = 450,
                      [xi.mod.DOUBLE_ATTACK] = 20,
                      [xi.mod.TRIPLE_ATTACK] = 8,
                      [xi.mod.REGEN] = 120,
                  },
                },
                { name = 'Shinryu',            label = 'Shinryu',            points = 120, groupId = 11369, minLv = 150, maxLv = 150,
                  spawnPos = { x =  448.8, y =  0.11, z = -199.3, rot = 128 },  -- T5 cluster: E
                  drops = { { id = 1133, qty = 5 } },  -- Vial of Dragon Blood (Augment Affinity: MP/Refresh)
                  hpBoost = 72,
                  mods = {
                      [xi.mod.DEF] = 2420,
                      [xi.mod.MDEF] = 9000,
                      [xi.mod.ATT] = 10800,
                      [xi.mod.ACC] = 4500,  -- guaranteed hit even on full EVA stacks
                      [xi.mod.EVASION] = 7200,
                      [xi.mod.MEVA] = 3600,
                      [xi.mod.STR] = 1200,
                      [xi.mod.DEX] = 1200,
                      [xi.mod.HASTE_GEAR] = 600,
                      [xi.mod.DOUBLE_ATTACK] = 25,
                      [xi.mod.TRIPLE_ATTACK] = 10,
                      [xi.mod.REGEN] = 175,
                  },
                },
            },
        },
    },

    -- =========================================================
    -- REWARD SHOP - organized by equipment slot.
    -- Each category: { label = 'Name', items = { ... } }
    -- Items:   name (display), id (item DB id), cost (Hunt Marks),
    --          stats = { } (lines shown in preview, <=22 chars each)
    -- =========================================================
    rewardCategories =
    {
        -- ---------------------------------------------------------
        -- 1. Seals / Currency
        -- ---------------------------------------------------------
        {
            label = 'Seals',   -- kept as the category label so the Seals NPC's
                               -- direct-jump (findCategoryIdx('Seals')) still works
            items =
            {
                -- Medal trio: orphan currency items, exclusive to Hunting League.
                -- Bronze/Silver/Gold tier currencies used by the Weapons + Armor
                -- vendors. Raw IDs because xi.item.* enum entries don't exist.
                -- Demons Medal (9543) had stack=1 upstream; bumped to 99 via
                -- modules/custom/sql/stackable_medals.sql.
                { name = "Beastmens Medal",  id = 9539, cost = 5,
                  stats = { 'Bronze tier currency', 'Buys entry ilvl 119 gear' } },
                { name = "Kindreds Medal",   id = 9541, cost = 15,
                  stats = { 'Silver tier currency', 'Buys HQ +1 / +2 gear' } },
                { name = "Demons Medal",     id = 9543, cost = 40,
                  stats = { 'Gold tier currency', 'Buys BiS endgame gear' } },
            },
        },

        -- ---------------------------------------------------------
        -- (Decommissioned: Neck / Earrings non-Sortie / Rings / Back /
        -- Waist categories were moved to the medal-paid Accessory NPC at
        -- Reisenjima Henge x=8.49. The new vendor uses Bronze/Silver/Gold
        -- medals (same currency loop as Armor / Weapons NPCs) and is
        -- catalog-driven by tools/score_accessories.py - top picks per
        -- role are auto-selected from the live item DB.
        --
        -- The Sortie JSE earrings (all 22 jobs, NQ/+1/+2) that this
        -- Hunt-Marks vendor used to sell were REMOVED from every custom
        -- vendor 2026-07-13 (owner) -- pulled from here, the Accessory NPC,
        -- and the Dungeon Infamy Vendor alike. Reserved for a future Sortie
        -- implementation; no vendor sells them now.
        -- ---------------------------------------------------------

        -- (Rings / Back / Waist categories decommissioned - see top of
        -- rewardCategories. Those slots are now served by the medal-paid
        -- Accessory NPC at Escha - Zi'Tah, x=-9.0, next to Armor/Weapons.)

        -- (The custom-spell "Spells" shop category was removed 2026-06-25 along
        -- with the custom spells themselves -- !aegis/!convergence/!silencega and
        -- spell ids 1020/1021 are gone, and the custom scroll items 29696-29698
        -- were purged from the DB. Players already receive every spell free from
        -- Character_Upgrader on first login, so the category was redundant.)
    },

    -- =========================================================
    -- HARDCORE NM MECHANICS  (mob_mechanics_library.lua)
    -- Keyed by groupId. Each NM gets a DISTINCT mechanic identity that
    -- escalates with rank: Rank I = light; Rank V = the full kit.
    -- Stance DMGPHYS/DMGMAGIC values cap at -5000 (=-50% damage taken,
    -- a heavy resist -- not literal immunity). Only ATT/REGEN go through
    -- safeAddMod inside the library; never set them here directly.
    -- addGroupId values for "adds" reuse T1 groupIds (11355-11357) which
    -- are real mob_groups rows in zone xi.zone.ESCHA_ZITAH (huntZoneId=210).
    -- =========================================================
    mechCfgs =
    {
        -- =========================================================
        -- RANK I - INITIATE (light):  drain only -- they self-heal;
        -- don't turtle.  A taste of what's coming.
        -- =========================================================
        [11355] = {  -- Leaping Lizzy
            name   = 'Leaping Lizzy',
            drain  = { periodSec = 10, healPct = 0.25 },
            enrage = { sec = 240, att = 2000, haste = 80, msg = 'Leaping Lizzy quickens -- finish it fast!' },
        },
        [11356] = {  -- Valkurm Emperor
            name   = 'Valkurm Emperor',
            drain  = { periodSec = 10, healPct = 0.25 },
            enrage = { sec = 240, att = 2000, haste = 80, msg = 'Valkurm Emperor\'s wings beat faster -- it enrages!' },
        },
        [11357] = {  -- Tom Tit Tat
            name   = 'Tom Tit Tat',
            drain  = { periodSec = 10, healPct = 0.25 },
            enrage = { sec = 240, att = 2000, haste = 80, msg = 'Tom Tit Tat howls -- its assault intensifies!' },
        },

        -- =========================================================
        -- RANK II - HUNTER (light+ / two mechanics):
        -- CC pulses on a long timer + drain.  Players must
        -- manage status and commit to DPS.
        -- =========================================================
        [11358] = {  -- Roc
            name   = 'Roc',
            drain  = { periodSec = 9, healPct = 0.25 },
            cc     = { periodSec = 28, effect = xi.effect.PARALYZE, power = 40, dur = 8, msg = 'Roc hammers the air -- its wingbeat paralyses!' },
            enrage = { sec = 220, att = 3000, haste = 100, msg = 'Roc unleashes its full fury!' },
        },
        [11359] = {  -- Bomb Queen
            name   = 'Bomb Queen',
            drain  = { periodSec = 9, healPct = 0.25 },
            cc     = { periodSec = 26, effect = xi.effect.BIND, power = 1, dur = 6, msg = 'Bomb Queen erupts -- binding heat pins you down!' },
            enrage = { sec = 220, att = 3000, haste = 100, msg = 'Bomb Queen\'s core flares -- it detonates with fury!' },
        },
        [11360] = {  -- Aquarius
            name   = 'Aquarius',
            drain  = { periodSec = 9, healPct = 0.25 },
            cc     = { periodSec = 26, effect = xi.effect.SLOW, power = 512, dur = 10, msg = 'Aquarius surges -- water pressure slows you!' },
            enrage = { sec = 220, att = 3000, haste = 100, msg = 'Aquarius roars -- tidal force builds!' },
        },

        -- =========================================================
        -- RANK III - ELITE (medium / three mechanics):
        -- Stance dance (forces damage-type switching) + AoE + drain.
        -- Requires the group to co-ordinate and keep moving.
        -- =========================================================
        [11361] = {  -- Serket
            name   = 'Serket',
            drain  = { periodSec = 8, healPct = 0.25 },
            stance = { startHpp = 90, periodSec = 18, stances = {
                { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'Serket\'s carapace hardens -- use magic!' },
                { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'Serket wards the mystic arts -- strike with steel!' },
            } },
            enrage = { sec = 200, att = 3500, haste = 110, msg = 'Serket rears up in a frenzy!' },
        },
        [11362] = {  -- Vrtra
            name   = 'Vrtra',
            drain  = { periodSec = 8, healPct = 0.25 },
            aoe    = { periodSec = 14, dmgPct = 20, msg = 'Vrtra breathes a torrent -- get clear!' },
            enrage = { sec = 200, att = 3500, haste = 110, msg = 'Vrtra thrashes -- its breath weapon quickens!' },
            phases = {
                { hp = 50, action = 'fury', att = 2000, haste = 80, msg = 'Vrtra enters its second wind -- it grows fiercer!' },
            },
        },
        [11363] = {  -- Simurgh
            name   = 'Simurgh',
            drain  = { periodSec = 8, healPct = 0.25 },
            stance = { startHpp = 85, periodSec = 16, stances = {
                { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'Simurgh\'s feathers become living armor -- use magic!' },
                { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'Simurgh shrugs off magic -- cut it with steel!' },
            } },
            aoe    = { periodSec = 13, dmgPct = 20, msg = 'Simurgh screams -- shockwaves tear outward!' },
            enrage = { sec = 195, att = 4000, haste = 120, msg = 'Simurgh blazes with power -- the air ignites!' },
        },

        -- =========================================================
        -- RANK IV - CHAMPION (hard / four mechanics):
        -- Stance + AoE + dispel + CC + tighter enrage.
        -- Punishing: buffs are stripped, stance forces adaptation,
        -- AoE keeps pressure up throughout.
        -- =========================================================
        [11364] = {  -- Nidhogg
            name   = 'Nidhogg',
            stance = { startHpp = 85, periodSec = 15, stances = {
                { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'Nidhogg scales turn adamantine -- magic only!' },
                { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'Nidhogg nullifies the arcane -- steel only!' },
            } },
            aoe    = { periodSec = 12, dmgPct = 22, msg = 'Nidhogg erupts -- draconic pressure crushes all!' },
            drain  = { periodSec = 8, healPct = 0.25 },
            enrage = { sec = 195, att = 4500, haste = 130, msg = 'Nidhogg\'s eyes go crimson -- it accelerates!' },
            phases = {
                { hp = 60, action = 'dispel', count = 3, msg = 'Nidhogg roars -- your enhancements are torn away!' },
                { hp = 30, action = 'fury',   att = 2500, haste = 100, msg = 'Nidhogg convulses -- surging with draconic force!' },
            },
        },
        [11365] = {  -- King Behemoth
            name   = 'King Behemoth',
            aoe    = { periodSec = 11, dmgPct = 23, msg = 'King Behemoth thunderclaps -- shockwaves ripple out!' },
            cc     = { periodSec = 24, effect = xi.effect.TERROR, power = 1, dur = 5, msg = 'King Behemoth bellows -- you freeze in terror!' },
            drain  = { periodSec = 8, healPct = 0.25 },
            enrage = { sec = 190, att = 4500, haste = 130, msg = 'King Behemoth stamps the earth -- the assault peaks!' },
            phases = {
                { hp = 65, action = 'dispel', count = 3, msg = 'King Behemoth snorts -- blessings stripped!' },
                { hp = 35, action = 'fury',   att = 2500, haste = 100, msg = 'King Behemoth enters a killing rage!' },
            },
        },
        [11366] = {  -- Kirin
            name   = 'Kirin',
            stance = { startHpp = 80, periodSec = 14, stances = {
                { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'Kirin\'s divine hide repels iron -- use sorcery!' },
                { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'Kirin wards the arcane -- pierce it with steel!' },
            } },
            cc     = { periodSec = 22, effect = xi.effect.SILENCE, power = 1, dur = 7, msg = 'Kirin\'s celestial scream silences the battlefield!' },
            drain  = { periodSec = 8, healPct = 0.25 },
            enrage = { sec = 185, att = 5000, haste = 140, msg = 'Kirin\'s mane ignites -- it ascends its true power!' },
            phases = {
                { hp = 70, action = 'dispel', count = 4, msg = 'Kirin exhales holy wind -- your enhancements dissolve!' },
                { hp = 40, action = 'dispel', count = 4, msg = 'Kirin calls upon the heavens -- buffs erased!' },
                { hp = 20, action = 'fury',   att = 3000, haste = 120, msg = 'Kirin rises to divine wrath!' },
            },
        },

        -- =========================================================
        -- RANK V - LEGEND (full hardcore kit):
        -- Every mechanic. Escalating per-boss identity.
        -- Absolute Virtue: stance + doom + tight enrage.
        -- Pandemonium Warden: AoE + CC + dispel + nuke + enrage.
        -- Shinryu: the full kit -- all mechanics, hardest enrage.
        -- =========================================================
        [11367] = {  -- Absolute Virtue
            name   = 'Absolute Virtue',
            stance = { startHpp = 80, periodSec = 14, stances = {
                { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'Absolute Virtue transcends flesh -- magic only!' },
                { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'Absolute Virtue banishes magic -- steel only!' },
            } },
            drain  = { periodSec = 7, healPct = 0.25 },
            enrage = { sec = 185, att = 5500, haste = 150, msg = 'Absolute Virtue abandons restraint -- it goes all out!' },
            phases = {
                { hp = 50, action = 'fury', att = 3000, haste = 100, msg = 'Absolute Virtue surges -- power escalates!' },
            },
            doom   = { startHpp = 12, dur = 28, msg = 'Absolute Virtue marks you for oblivion!' },
        },
        [11368] = {  -- Pandemonium Warden
            name   = 'Pandemonium Warden',
            aoe    = { periodSec = 11, dmgPct = 24, msg = 'Pandemonium Warden erupts -- chaos tears outward!' },
            cc     = { periodSec = 22, effect = xi.effect.TERROR, power = 1, dur = 5, msg = 'Pandemonium Warden unleashes pandemonium -- frozen in dread!' },
            drain  = { periodSec = 7, healPct = 0.25 },
            enrage = { sec = 180, att = 6000, haste = 160, msg = 'Pandemonium Warden reaches its true form!' },
            phases = {
                { hp = 70, action = 'dispel', count = 4, msg = 'Pandemonium Warden howls -- enhancements erased!' },
                { hp = 50, action = 'nuke',   dmgPct = 38, msg = 'Pandemonium Warden collapses into a singularity!' },
                { hp = 30, action = 'dispel', count = 5, msg = 'Pandemonium Warden strips you bare!' },
                { hp = 15, action = 'fury',   att = 4000, haste = 130, msg = 'Pandemonium Warden rages without limit!' },
            },
            doom   = { startHpp = 10, dur = 25, msg = 'Pandemonium Warden sentences you to oblivion!' },
        },
        [11369] = {  -- Shinryu
            name   = 'Shinryu',
            stance = { startHpp = 90, periodSec = 12, stances = {
                { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'Shinryu\'s scales become diamond -- use sorcery!' },
                { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'Shinryu turns away the arcane -- pierce it with steel!' },
            } },
            aoe    = { periodSec = 10, dmgPct = 26, msg = 'Shinryu detonates -- dragonfire scours everything!' },
            cc     = { periodSec = 20, effect = xi.effect.SILENCE, power = 1, dur = 8, msg = 'Shinryu roars -- the battlefield falls silent!' },
            drain  = { periodSec = 6, healPct = 0.25 },
            enrage = { sec = 165, att = 8000, haste = 200, msg = 'Shinryu crosses into legend -- unmatched fury!' },
            phases = {
                { hp = 55, action = 'dispel', count = 5, msg = 'Shinryu exhales tempest-breath -- buffs annihilated!' },
                { hp = 40, action = 'nuke',   dmgPct = 42, msg = 'Shinryu\'s Judgment coalesces -- reality cracks!' },
                { hp = 15, action = 'fury',   att = 5000, haste = 160, msg = 'Shinryu ascends -- you stand before a god!' },
                { hp = 10, action = 'doom',   dur = 25, msg = 'Shinryu marks the unworthy for death!' },
            },
            doom   = { startHpp = 8, dur = 22, msg = 'Shinryu judges you -- DOOM!' },
        },
    },
}
