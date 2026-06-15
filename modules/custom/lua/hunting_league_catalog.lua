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
    huntZoneId   = xi.zone.REISENJIMA_HENGE,
    huntZonePath = 'xi.zones.Reisenjima_Henge',

    -- Position of the Hunt Seals NPC (tier/rank + seal purchases). This is
    -- also the !hunt warp landing spot, so updates here should sync to
    -- scripts/commands/hunt.lua.
    sealsPos       = { x = -11.0000, y = 5.5090, z = -12.1827, rot = 230 },

    -- Position of the Spawner NPC (pops NMs on demand). +4 on X (vendor row
    -- widened from 3 -> 4 units 2026-06-13 so the name labels stop overlapping).
    spawnerPos     = { x = -7.0000, y = 5.5090, z = -12.1827, rot = 230 },

    -- Position of the Hunt Accessories NPC (Neck/Earrings/Rings/etc. shop).
    -- Continues the +4-unit vendor row (one slot past the Armor NPC).
    accessoriesPos = { x =  5.0000, y = 5.5090, z = -12.1827, rot = 230 },

    -- Where dynamic NMs appear when the Spawner NPC pops them.
    mobSpawnPos = { x = 1.1883, y = 5.5000, z = 1.8036, rot = 208 },

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
    unengagedDespawnSecs = 30,  -- 30 seconds

    -- =========================================================
    -- TIER DEFINITIONS
    -- =========================================================
    --
    -- Power ladder (2026-05 rebalance - "too easy" pass):
    --
    --   Every tier now has hpBoost (was T5-only) so fights actually
    --   last. HASTE_GEAR (1024ths of 1%), DOUBLE_ATTACK / TRIPLE_ATTACK
    --   (% chance), and REGEN (HP/tick) are layered on so mobs swing
    --   hard, swing often, and self-heal - players have to commit.
    --   MDEF + MEVA prevent caster groups from one-shotting via nuke.
    --
    --   T1 Initiate   3x HP, mild challenge for a fresh Lv99
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
            mobs =
            {
                { name = 'Leaping_Lizzy',    label = 'Leaping Lizzy',    points = 5,  groupId = 11355, minLv = 150, maxLv = 150,
                  hpBoost = 4,
                  mods = {
                      [xi.mod.DEF] = 385,
                      [xi.mod.ATT] = 1800,
                      [xi.mod.ACC] = 180,   -- T1 normalized target
                      [xi.mod.EVASION] = 120,
                      [xi.mod.MEVA] = 120,
                      [xi.mod.STR]           = 50,    -- + damage on hit
                      [xi.mod.DEX]           = 50,    -- DEX feeds ACC formula (~0.75 DEX = 1 ACC)
                      [xi.mod.HASTE_GEAR]    = 100,   -- ~10%
                      [xi.mod.DOUBLE_ATTACK] = 5,
                      [xi.mod.REGEN]         = 50,
                  },
                },
                { name = 'Valkurm_Emperor',  label = 'Valkurm Emperor',  points = 5,  groupId = 11356, minLv = 150, maxLv = 150,
                  hpBoost = 4,
                  mods = {
                      [xi.mod.DEF] = 385,
                      [xi.mod.ATT] = 1800,
                      [xi.mod.ACC] = 180,   -- T1 normalized target
                      [xi.mod.EVASION] = 120,
                      [xi.mod.MEVA] = 120,
                      [xi.mod.HASTE_GEAR]    = 100,
                      [xi.mod.DOUBLE_ATTACK] = 5,
                      [xi.mod.REGEN]         = 50,
                  },
                },
                { name = 'Tom_Tit_Tat',      label = 'Tom Tit Tat',      points = 5,  groupId = 11357, minLv = 150, maxLv = 150,
                  hpBoost = 4,
                  mods = {
                      [xi.mod.DEF] = 385,
                      [xi.mod.ATT] = 1800,
                      [xi.mod.ACC] = 180,   -- T1 normalized target
                      [xi.mod.EVASION] = 120,
                      [xi.mod.MEVA] = 120,
                      [xi.mod.HASTE_GEAR]    = 100,
                      [xi.mod.DOUBLE_ATTACK] = 5,
                      [xi.mod.REGEN]         = 50,
                  },
                },
            },
        },

        -- TIER 2 - Mid-tier HNMs (lv40-60)
        {
            tier       = 2,
            name       = 'Rank II - Hunter',
            unlockCost = 50,
            mobs =
            {
                { name = 'Roc',         label = 'Roc',         points = 12, groupId = 11358, minLv = 150, maxLv = 150,
                  hpBoost = 6,
                  mods = {
                      [xi.mod.DEF] = 660,
                      [xi.mod.ATT] = 3000,
                      [xi.mod.ACC] = 600,   -- T2 normalized target
                      [xi.mod.EVASION] = 180,
                      [xi.mod.MEVA] = 240,
                      [xi.mod.MDEF] = 120,
                      [xi.mod.HASTE_GEAR]    = 150,   -- ~15%
                      [xi.mod.DOUBLE_ATTACK] = 10,
                      [xi.mod.REGEN]         = 100,
                  },
                },
                { name = 'Bomb_Queen',  label = 'Bomb Queen',  points = 12, groupId = 11359, minLv = 150, maxLv = 150,
                  hpBoost = 6,
                  mods = {
                      [xi.mod.DEF] = 660,
                      [xi.mod.ATT] = 3000,
                      [xi.mod.ACC] = 600,   -- T2 normalized target
                      [xi.mod.EVASION] = 180,
                      [xi.mod.MEVA] = 240,
                      [xi.mod.MDEF] = 120,
                      [xi.mod.STR]           = 100,
                      [xi.mod.DEX]           = 100,
                      [xi.mod.HASTE_GEAR]    = 150,
                      [xi.mod.DOUBLE_ATTACK] = 10,
                      [xi.mod.REGEN]         = 100,
                  },
                },
                { name = 'Aquarius',    label = 'Aquarius',    points = 12, groupId = 11360, minLv = 150, maxLv = 150,
                  hpBoost = 6,
                  mods = {
                      [xi.mod.DEF] = 660,
                      [xi.mod.ATT] = 3000,
                      [xi.mod.ACC] = 600,   -- T2 normalized target
                      [xi.mod.EVASION] = 180,
                      [xi.mod.MEVA] = 240,
                      [xi.mod.MDEF] = 120,
                      [xi.mod.STR]           = 100,
                      [xi.mod.DEX]           = 100,
                      [xi.mod.HASTE_GEAR]    = 150,
                      [xi.mod.DOUBLE_ATTACK] = 10,
                      [xi.mod.REGEN]         = 100,
                  },
                },
            },
        },

        -- TIER 3 - Classic HNMs (lv60-75)
        {
            tier       = 3,
            name       = 'Rank III - Elite',
            unlockCost = 150,
            mobs =
            {
                { name = 'Serket',    label = 'Serket',    points = 22, groupId = 11361, minLv = 150, maxLv = 150,
                  hpBoost = 10,
                  mods = {
                      [xi.mod.DEF] = 990,
                      [xi.mod.ATT] = 4800,
                      [xi.mod.ACC] = 840,   -- T3 normalized target
                      [xi.mod.EVASION] = 300,
                      [xi.mod.MEVA] = 360,
                      [xi.mod.MDEF] = 240,
                      [xi.mod.HASTE_GEAR]    = 200,   -- ~20%
                      [xi.mod.DOUBLE_ATTACK] = 15,
                      [xi.mod.TRIPLE_ATTACK] = 3,
                      [xi.mod.REGEN]         = 200,
                  },
                },
                { name = 'Vrtra',     label = 'Vrtra',     points = 22, groupId = 11362, minLv = 150, maxLv = 150,
                  hpBoost = 10,
                  mods = {
                      [xi.mod.DEF] = 990,
                      [xi.mod.ATT] = 4800,
                      [xi.mod.ACC] = 840,   -- T3 normalized target
                      [xi.mod.EVASION] = 300,
                      [xi.mod.MEVA] = 360,
                      [xi.mod.MDEF] = 240,
                      [xi.mod.STR]           = 200,
                      [xi.mod.DEX]           = 200,
                      [xi.mod.HASTE_GEAR]    = 200,
                      [xi.mod.DOUBLE_ATTACK] = 15,
                      [xi.mod.TRIPLE_ATTACK] = 3,
                      [xi.mod.REGEN]         = 200,
                  },
                },
                { name = 'Simurgh',   label = 'Simurgh',   points = 22, groupId = 11363, minLv = 150, maxLv = 150,
                  -- Difficulty bump (2026-06-13, owner request): tuned a notch
                  -- above its T3 tier-mates (Serket/Vrtra) -- +25% HP, harder &
                  -- faster hits (ATT/HASTE/Double+Triple Atk), and stronger Regen
                  -- so a group has to out-DPS the self-heal. Dial up/down here.
                  hpBoost = 12,
                  mods = {
                      [xi.mod.DEF] = 990,
                      [xi.mod.ATT] = 5280,  -- T3+ (was 4000)
                      [xi.mod.ACC] = 900,   -- T3+ (was 700)
                      [xi.mod.EVASION] = 300,
                      [xi.mod.MEVA] = 360,
                      [xi.mod.MDEF] = 240,
                      [xi.mod.STR]           = 200,
                      [xi.mod.DEX]           = 200,
                      [xi.mod.HASTE_GEAR]    = 230,   -- ~22% (was 200)
                      [xi.mod.DOUBLE_ATTACK] = 20,    -- was 15
                      [xi.mod.TRIPLE_ATTACK] = 5,     -- was 3
                      [xi.mod.REGEN]         = 275,   -- was 200
                  },
                },
            },
        },

        -- TIER 4 - Sky / Sea / Wyrm-tier (lv80-90)
        {
            tier       = 4,
            name       = 'Rank IV - Champion',
            unlockCost = 350,
            mobs =
            {
                { name = 'Nidhogg',       label = 'Nidhogg',       points = 38, groupId = 11364, minLv = 150, maxLv = 150,
                  hpBoost = 14,
                  mods = {
                      [xi.mod.DEF] = 1430,
                      [xi.mod.ATT] = 7200,
                      [xi.mod.ACC] = 1080,   -- T4 normalized target
                      [xi.mod.EVASION] = 420,
                      [xi.mod.MEVA] = 480,
                      [xi.mod.MDEF] = 420,
                      [xi.mod.HASTE_GEAR]    = 250,   -- ~25%
                      [xi.mod.DOUBLE_ATTACK] = 20,
                      [xi.mod.TRIPLE_ATTACK] = 8,
                      [xi.mod.REGEN]         = 400,
                  },
                },
                { name = 'King_Behemoth', label = 'King Behemoth', points = 38, groupId = 11365, minLv = 150, maxLv = 150,
                  hpBoost = 14,
                  mods = {
                      [xi.mod.DEF] = 1430,
                      [xi.mod.ATT] = 7200,
                      [xi.mod.ACC] = 1080,   -- T4 normalized target
                      [xi.mod.EVASION] = 420,
                      [xi.mod.MEVA] = 480,
                      [xi.mod.MDEF] = 420,
                      [xi.mod.STR]           = 300,
                      [xi.mod.DEX]           = 300,
                      [xi.mod.HASTE_GEAR]    = 250,
                      [xi.mod.DOUBLE_ATTACK] = 20,
                      [xi.mod.TRIPLE_ATTACK] = 8,
                      [xi.mod.REGEN]         = 400,
                  },
                },
                { name = 'Kirin',         label = 'Kirin',         points = 38, groupId = 11366, minLv = 150, maxLv = 150,
                  hpBoost = 14,
                  mods = {
                      [xi.mod.DEF] = 1430,
                      [xi.mod.ATT] = 7200,
                      [xi.mod.ACC] = 1080,   -- T4 normalized target
                      [xi.mod.EVASION] = 420,
                      [xi.mod.MEVA] = 480,
                      [xi.mod.MDEF] = 420,
                      [xi.mod.STR]           = 300,
                      [xi.mod.DEX]           = 300,
                      [xi.mod.HASTE_GEAR]    = 250,
                      [xi.mod.DOUBLE_ATTACK] = 20,
                      [xi.mod.TRIPLE_ATTACK] = 8,
                      [xi.mod.REGEN]         = 400,
                  },
                },
            },
        },

        -- TIER 5 - Legend (lv99 superbosses)
        {
            tier       = 5,
            name       = 'Rank V - Legend',
            unlockCost = 700,
            mobs =
            {
                { name = 'Absolute_Virtue',    label = 'Absolute Virtue',    points = 65, groupId = 11367, minLv = 150, maxLv = 150,
                  hpBoost = 24,
                  mods = {
                      [xi.mod.DEF] = 2200,
                      [xi.mod.ATT] = 10800,
                      [xi.mod.ACC] = 2160,  -- unmissable except vs huge EVA stacks
                      [xi.mod.EVASION] = 600,
                      [xi.mod.MEVA] = 720,
                      [xi.mod.MDEF] = 720,
                      [xi.mod.STR]           = 500,
                      [xi.mod.DEX]           = 500,
                      [xi.mod.HASTE_GEAR]    = 300,   -- ~30% (capped by engine)
                      [xi.mod.DOUBLE_ATTACK] = 25,
                      [xi.mod.TRIPLE_ATTACK] = 12,
                      [xi.mod.REGEN]         = 800,
                  },
                },
                { name = 'Pandemonium_Warden', label = 'Pandemonium Warden', points = 65, groupId = 11368, minLv = 150, maxLv = 150,
                  hpBoost = 24,
                  mods = {
                      [xi.mod.DEF] = 2200,
                      [xi.mod.ATT] = 10800,
                      [xi.mod.ACC] = 600,
                      [xi.mod.EVASION] = 600,
                      [xi.mod.MEVA] = 720,
                      [xi.mod.MDEF] = 720,
                      [xi.mod.HASTE_GEAR]    = 300,
                      [xi.mod.DOUBLE_ATTACK] = 25,
                      [xi.mod.TRIPLE_ATTACK] = 12,
                      [xi.mod.REGEN]         = 800,
                  },
                },
                { name = 'Shinryu',            label = 'Shinryu',            points = 110, groupId = 11369, minLv = 225, maxLv = 250,
                  hpBoost = 48,
                  mods = {
                      [xi.mod.DEF] = 8800,
                      [xi.mod.MDEF] = 6000,
                      [xi.mod.ATT] = 18000,
                      [xi.mod.ACC] = 3000,  -- guaranteed hit even on full EVA stacks
                      [xi.mod.EVASION] = 4800,
                      [xi.mod.MEVA] = 2400,
                      [xi.mod.STR]           = 800,
                      [xi.mod.DEX]           = 800,
                      [xi.mod.HASTE_GEAR]    = 400,
                      [xi.mod.DOUBLE_ATTACK] = 35,
                      [xi.mod.TRIPLE_ATTACK] = 15,
                      [xi.mod.REGEN]         = 2000,
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
        -- This Hunt-Marks vendor now keeps ONLY the Sortie earring NQ/+1
        -- series because those need per-job augment treatment that's
        -- outside the scope of the role-balanced scorer. The +2 series was
        -- moved to the Dungeon Infamy Vendor (owner request 2026-06-05) as
        -- an Infamy-exclusive "best in game" reward.
        -- ---------------------------------------------------------

        -- ---------------------------------------------------------
        -- Sortie Earrings (NQ) - cost 100 each
        --    Item IDs 25420-25548, 3 per job (NQ/+1/+2), 22 jobs.
        --    NQ stats shown; ACC/MACC ~+6 from augment pool.
        -- ---------------------------------------------------------
        {
            label = 'Sortie: NQ',
            items =
            {
                { name = "Boii Earring",        id = 25420, cost = 100,
                  stats = { 'WAR: DblAtk+7%', 'Subtle Blow+5' } },
                { name = "Bhikku Earring",      id = 25426, cost = 100,
                  stats = { 'MNK: H2H+10', 'Counter+7' } },
                { name = "Ebers Earring",       id = 25432, cost = 100,
                  stats = { 'WHM: Healing+10', 'Enmity-7' } },
                { name = "Wicce Earring",       id = 25438, cost = 100,
                  stats = { 'BLM: MagATK+7', 'Mag Dmg+7' } },
                { name = "Lethargy Earring",    id = 25444, cost = 100,
                  stats = { 'RDM: FastCast+7%', 'Enh.dur+7%' } },
                { name = "Skulker's Earring",   id = 25450, cost = 100,
                  stats = { 'THF: TripleAtk+3%', 'Subtle Blow+5' } },
                { name = "Chevalier's Earring", id = 25456, cost = 100,
                  stats = { 'PLD: DEF+20', 'Shield+10', 'Cure+10%' } },
                { name = "Heathen's Earring",   id = 25462, cost = 100,
                  stats = { 'DRK: ATT+15', 'PDL+7%' } },
                { name = "Nukumi Earring",      id = 25468, cost = 100,
                  stats = { 'BST: Axe+10', 'PDL+7%' } },
                { name = "Fili Earring",        id = 25474, cost = 100,
                  stats = { 'BRD: Singing+10', 'Enmity-7' } },
                { name = "Amini Earring",       id = 25480, cost = 100,
                  stats = { 'RNG: Enmity-7', 'PDL+7%' } },
                { name = "Kasuga Earring",      id = 25486, cost = 100,
                  stats = { 'SAM: Store TP+7', 'SC Bonus+5' } },
                { name = "Hattori Earring",     id = 25492, cost = 100,
                  stats = { 'NIN: Katana+10', 'Throwing+10' } },
                { name = "Peltast's Earring",   id = 25498, cost = 100,
                  stats = { 'DRG: Subtle Blow+5', 'PDL+7%' } },
                { name = "Beckoner's Earring",  id = 25504, cost = 100,
                  stats = { 'SMN: Refresh+1', 'BP dmg+3' } },
                { name = "Hashishin Earring",   id = 25510, cost = 100,
                  stats = { 'BLU: Sword+10', 'Blue Mag+10' } },
                { name = "Chasseur's Earring",  id = 25516, cost = 100,
                  stats = { 'COR: Enmity-7', 'Recycle+10' } },
                { name = "Karagoz Earring",     id = 25522, cost = 100,
                  stats = { 'PUP: H2H+10', 'Subtle Blow+5' } },
                { name = "Maculele Earring",    id = 25528, cost = 100,
                  stats = { 'DNC: SC Bonus+5', 'PDL+7%' } },
                { name = "Arbatel Earring",     id = 25534, cost = 100,
                  stats = { 'SCH: MagATK+7', 'Mag Dmg+7' } },
                { name = "Azimuth Earring",     id = 25540, cost = 100,
                  stats = { 'GEO: MagATK+7', 'Geomancy+10' } },
                { name = "Erilaz Earring",      id = 25546, cost = 100,
                  stats = { 'RUN: MagEva+10', 'Regen+10%' } },
            },
        },

        -- ---------------------------------------------------------
        -- 5. Sortie Earrings (+1) - cost 200 each
        -- ---------------------------------------------------------
        {
            label = 'Sortie: +1',
            items =
            {
                { name = "Boii Earring +1",        id = 25421, cost = 200,
                  stats = { 'WAR: DblAtk+7%', 'Subtle Blow+5', 'Acc/MACC +8~12' } },
                { name = "Bhikku Earring +1",      id = 25427, cost = 200,
                  stats = { 'MNK: H2H+10', 'Counter+7', 'Acc/MACC +8~12' } },
                { name = "Ebers Earring +1",       id = 25433, cost = 200,
                  stats = { 'WHM: Healing+10', 'Enmity-7', 'Acc/MACC +8~12' } },
                { name = "Wicce Earring +1",       id = 25439, cost = 200,
                  stats = { 'BLM: MagATK+7', 'Mag Dmg+7', 'Acc/MACC +8~12' } },
                { name = "Lethargy Earring +1",    id = 25445, cost = 200,
                  stats = { 'RDM: FastCast+7%', 'Enh.dur+7%', 'Acc/MACC +8~12' } },
                { name = "Skulker's Earring +1",   id = 25451, cost = 200,
                  stats = { 'THF: TripleAtk+3%', 'SubBlow+5', 'Acc/MACC +8~12' } },
                { name = "Chevalier's Earring +1", id = 25457, cost = 200,
                  stats = { 'PLD: DEF+20', 'Shield+10', 'Acc/MACC +8~12' } },
                { name = "Heathen's Earring +1",   id = 25463, cost = 200,
                  stats = { 'DRK: ATT+15', 'PDL+7%', 'Acc/MACC +8~12' } },
                { name = "Nukumi Earring +1",      id = 25469, cost = 200,
                  stats = { 'BST: Axe+10', 'PDL+7%', 'Acc/MACC +8~12' } },
                { name = "Fili Earring +1",        id = 25475, cost = 200,
                  stats = { 'BRD: Singing+10', 'Enmity-7', 'Acc/MACC +8~12' } },
                { name = "Amini Earring +1",       id = 25481, cost = 200,
                  stats = { 'RNG: Enmity-7', 'PDL+7%', 'Acc/MACC +8~12' } },
                { name = "Kasuga Earring +1",      id = 25487, cost = 200,
                  stats = { 'SAM: Store TP+7', 'SC Bonus+5', 'Acc/MACC +8~12' } },
                { name = "Hattori Earring +1",     id = 25493, cost = 200,
                  stats = { 'NIN: Katana+10', 'Throwing+10', 'Acc/MACC +8~12' } },
                { name = "Peltast's Earring +1",   id = 25499, cost = 200,
                  stats = { 'DRG: SubBlow+5', 'PDL+7%', 'Acc/MACC +8~12' } },
                { name = "Beckoner's Earring +1",  id = 25505, cost = 200,
                  stats = { 'SMN: Refresh+1', 'BP dmg+3', 'Acc/MACC +8~12' } },
                { name = "Hashishin Earring +1",   id = 25511, cost = 200,
                  stats = { 'BLU: Sword+10', 'Blue Mag+10', 'Acc/MACC +8~12' } },
                { name = "Chasseur's Earring +1",  id = 25517, cost = 200,
                  stats = { 'COR: Enmity-7', 'Recycle+10', 'Acc/MACC +8~12' } },
                { name = "Karagoz Earring +1",     id = 25523, cost = 200,
                  stats = { 'PUP: H2H+10', 'SubBlow+5', 'Acc/MACC +8~12' } },
                { name = "Maculele Earring +1",    id = 25529, cost = 200,
                  stats = { 'DNC: SC Bonus+5', 'PDL+7%', 'Acc/MACC +8~12' } },
                { name = "Arbatel Earring +1",     id = 25535, cost = 200,
                  stats = { 'SCH: MagATK+7', 'Mag Dmg+7', 'Acc/MACC +8~12' } },
                { name = "Azimuth Earring +1",     id = 25541, cost = 200,
                  stats = { 'GEO: MagATK+7', 'Geomancy+10', 'Acc/MACC +8~12' } },
                { name = "Erilaz Earring +1",      id = 25547, cost = 200,
                  stats = { 'RUN: MagEva+10', 'Regen+10%', 'Acc/MACC +8~12' } },
            },
        },

        -- ---------------------------------------------------------
        -- Sortie Earrings (+2): MOVED to the Dungeon Infamy Vendor
        -- (owner request 2026-06-05). The +2 series is now an
        -- Infamy-exclusive 'best in game' reward - see
        -- catalog.vendorItemsAuto in dungeon_catalog.lua
        -- (auto-promoted by tools/build_infamy_top_picks.py).
        -- NQ and +1 remain here on Hunt Marks.
        -- ---------------------------------------------------------

        -- (Rings / Back / Waist categories decommissioned - see top of
        -- rewardCategories. Those slots are now served by the medal-paid
        -- Accessory NPC at Reisenjima Henge x=8.49.)

        -- ---------------------------------------------------------
        -- Magic Scrolls  (item IDs 29696+; spells custom to this server)
        -- Apply modules/custom/sql/silencega_scroll.sql to the DB first.
        -- ---------------------------------------------------------
        {
            label = 'Spells',
            items =
            {
                { name = 'Scroll of Silencega', id = 29696, cost = 200,
                  stats = { 'WHM 40 / RDM 50 / SCH 50', 'AoE Silence (Wind)', 'Enfeebling Magic' } },
                { name = 'Scroll of Divine Aegis', id = 29697, cost = 400,
                  stats = { 'PLD 50', 'Holy shield → AoE detonation', 'Enhancing / Divine Magic' } },
                { name = 'Scroll of Convergence', id = 29698, cost = 350,
                  stats = { 'RDM 50', 'Random enfeeble + elemental damage', 'Enfeebling Magic' } },
            },
        },
    },
}
