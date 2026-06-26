-----------------------------------
-- unity_wanted_catalog.lua
-- Unity Wanted NM definitions for the relaunch Unity Concord system.
-- All NMs spawn in zone 288 (Escha-Zi'tah / Reisenjima_Henge) via
-- groupId/groupZoneId so mob_pools provides model + base stats.
--
-- Tiers:
--   1 = Lv 75-80   (200 accolade cost, 400 reward)
--   2 = Lv 99-119  (600 accolade cost, 1500 reward)
--   3 = Lv 120-145 (1500 accolade cost, 4000 reward)
--
-- Weekly double-reward bonus is handled in unity_wanted.lua.
-- groupId + groupZoneId are the zone-288 mob_groups entries populated by
-- unity_wanted_mobs.sql (or already present for the Escha-origin NMs).
-----------------------------------

local ZONE_288 = xi.zone.ESCHA_ZITAH  -- == 288

-- Arena spawn cluster positions inside zone 288.
-- Each tier gets a dedicated area well away from the Hunting League clusters.
-- T1/T2 share a western arena; T3 has a separate deeper area.
-- TUNE: adjust after in-game map testing.
local ARENA = {
    T1 = { x = -200.0, y = -0.5, z =  50.0, rot = 128 },
    T2 = { x = -200.0, y = -0.5, z =  10.0, rot = 128 },
    T3 = { x = -250.0, y = -0.5, z =  30.0, rot = 128 },
}

-- Board NPC location in Celennia Memorial Library.
local BOARD_POS = { x = -110.000, y = -2.150, z = -106.000, rot = 190 }

-- Warp landing point for players entering the Unity Arena in zone 288.
-- Position them slightly east of the mob spawn to face the NM.
local WARP_POS = {
    T1 = { x = -195.0, y = -0.5, z =  50.0, rot = 128 },
    T2 = { x = -195.0, y = -0.5, z =  10.0, rot = 128 },
    T3 = { x = -245.0, y = -0.5, z =  30.0, rot = 128 },
}

-----------------------------------
-- NM catalog
-- Fields:
--   id         : unique catalog key (charVar storage)
--   name       : internal mob_groups.name string (must match exactly)
--   label      : display name shown in menus
--   tier       : 1/2/3 (determines cost, reward, spawn area)
--   minLv      : min level passed to insertDynamicEntity
--   maxLv      : max level
--   groupId    : zone-288 mob_groups.groupid
--   detection  : aggro bitfield (default SIGHT_AND_HEARING)
-----------------------------------
return {
    boardPos  = BOARD_POS,
    arena     = ARENA,
    warpPos   = WARP_POS,
    huntZoneId = ZONE_288,

    -- Accolade costs and rewards by tier
    costs    = { [1] = 200,  [2] = 600,  [3] = 1500 },
    rewards  = { [1] = 400,  [2] = 1500, [3] = 4000 },

    -- Despawn idle NMs after this many seconds (no player engagement)
    despawnSecs = 120,

    nms = {
        -- =====================================================================
        -- TIER 1  (Lv 75-80)
        -- These are the classic Unity Wanted low-tier NMs from outdoor Vana'diel
        -- =====================================================================
        { id=1,  name='Hugemaw_Harold',      label='Hugemaw Harold',      tier=1, minLv=78, maxLv=78, groupId=24 },
        { id=2,  name='Prickly_Pitriv',      label='Prickly Pitriv',      tier=1, minLv=78, maxLv=78, groupId=25 },
        { id=3,  name='Serpopard_Ninlil',    label='Serpopard Ninlil',    tier=1, minLv=75, maxLv=75, groupId=26 },
        { id=4,  name='Abyssdiver',          label='Abyssdiver',          tier=1, minLv=75, maxLv=75, groupId=27 },
        { id=5,  name='Keeper_of_Heiligtum', label='Keeper of Heiligtum', tier=1, minLv=76, maxLv=76, groupId=28 },
        { id=6,  name='Jester_Malatrix',     label='Jester Malatrix',     tier=1, minLv=76, maxLv=76, groupId=33 },
        { id=7,  name='Immanibugard',        label='Immanibugard',        tier=1, minLv=76, maxLv=76, groupId=34 },
        { id=8,  name='Orcfeltrap',          label='Orcfeltrap',          tier=1, minLv=75, maxLv=75, groupId=70 },
        { id=9,  name='Ironhorn_Baldurno',   label='Ironhorn Baldurno',   tier=1, minLv=78, maxLv=78, groupId=71 },
        { id=10, name='Sleepy_Mabel',        label='Sleepy Mabel',        tier=1, minLv=80, maxLv=80, groupId=72 },
        { id=11, name='Sybaritic_Samantha',  label='Sybaritic Samantha',  tier=1, minLv=78, maxLv=78, groupId=73 },
        { id=12, name='Bounding_Belinda',    label='Bounding Belinda',    tier=1, minLv=78, maxLv=78, groupId=74 },
        { id=13, name='Valkurm_Imperator',   label='Valkurm Imperator',   tier=1, minLv=76, maxLv=76, groupId=75 },
        { id=14, name='Joyous_Green',        label='Joyous Green',        tier=1, minLv=76, maxLv=76, groupId=76 },
        { id=15, name='Warblade_Beak',       label='Warblade Beak',       tier=1, minLv=78, maxLv=78, groupId=77 },
        { id=16, name='Cactrot_Veloz',       label='Cactrot Veloz',       tier=1, minLv=75, maxLv=75, groupId=78 },
        { id=17, name='Woodland_Mender',     label='Woodland Mender',     tier=1, minLv=75, maxLv=75, groupId=79 },
        { id=18, name='Emperor_Arthro',      label='Emperor Arthro',      tier=1, minLv=76, maxLv=76, groupId=80 },
        { id=19, name='Tiyanak',             label='Tiyanak',             tier=1, minLv=76, maxLv=76, groupId=81 },
        { id=20, name='Vermillion_Fishfly',  label='Vermillion Fishfly',  tier=1, minLv=78, maxLv=78, groupId=82 },
        { id=21, name='Intuila',             label='Intuila',             tier=1, minLv=75, maxLv=75, groupId=83 },

        -- =====================================================================
        -- TIER 2  (Lv 99-119)
        -- Post-Zilart / Chains of Promathia era NMs
        -- =====================================================================
        { id=22, name='Muut',                label='Muut',                tier=2, minLv=110, maxLv=110, groupId=29 },
        { id=23, name='Voso',                label='Voso',                tier=2, minLv=119, maxLv=119, groupId=32 },
        { id=24, name='Beist',               label='Beist',               tier=2, minLv=119, maxLv=119, groupId=35 },
        { id=25, name='Lumber_Jill',         label='Lumber Jill',         tier=2, minLv=99,  maxLv=99,  groupId=84 },
        { id=26, name='Largantua',           label='Largantua',           tier=2, minLv=99,  maxLv=99,  groupId=85 },
        { id=27, name='Garbage_Gel',         label='Garbage Gel',         tier=2, minLv=99,  maxLv=99,  groupId=86 },
        { id=28, name='King_Uropygid',       label='King Uropygid',       tier=2, minLv=105, maxLv=105, groupId=87 },
        { id=29, name='Vedrfolnir',          label='Vedrfolnir',          tier=2, minLv=105, maxLv=105, groupId=88 },
        { id=30, name='Glazemane',           label='Glazemane',           tier=2, minLv=105, maxLv=105, groupId=89 },
        { id=31, name='Volatile_Cluster',    label='Volatile Cluster',    tier=2, minLv=105, maxLv=105, groupId=90 },
        { id=32, name='Strix',               label='Strix',               tier=2, minLv=110, maxLv=110, groupId=91 },
        { id=33, name='Sovereign_Behemoth',  label='Sovereign Behemoth',  tier=2, minLv=119, maxLv=119, groupId=92 },
        { id=34, name='Arke',               label='Arke',                tier=2, minLv=119, maxLv=119, groupId=93 },
        { id=35, name='Douma_Weapon',        label='Douma Weapon',        tier=2, minLv=105, maxLv=105, groupId=94 },
        { id=36, name='Kubool_Jas_Mhuufya',  label='Kubool Jas Mhuufya',  tier=2, minLv=110, maxLv=110, groupId=95 },
        { id=37, name='Thuban',              label="Thu'ban",             tier=2, minLv=115, maxLv=115, groupId=96 },
        { id=38, name='Tumult_Curator',      label='Tumult Curator',      tier=2, minLv=119, maxLv=119, groupId=97 },

        -- =====================================================================
        -- TIER 3  (Lv 120-145)
        -- High-tier endgame Unity NMs
        -- =====================================================================
        { id=39, name='Specter_Worm',              label='Specter Worm',           tier=3, minLv=128, maxLv=128, groupId=98  },
        { id=40, name='Bakunawa',                  label='Bakunawa',               tier=3, minLv=128, maxLv=128, groupId=99  },
        { id=41, name='Mephitas',                  label='Mephitas',               tier=3, minLv=128, maxLv=128, groupId=100 },
        { id=42, name='Vidmapire',                 label='Vidmapire',              tier=3, minLv=128, maxLv=128, groupId=101 },
        { id=43, name='Shedu',                     label='Shedu',                  tier=3, minLv=135, maxLv=135, groupId=102 },
        { id=44, name='Azure-toothed_Clawberry',   label='Azure-toothed Clawberry',tier=3, minLv=135, maxLv=135, groupId=103 },
        { id=45, name='Centurio_XX-I',             label='Centurio XX-I',          tier=3, minLv=135, maxLv=135, groupId=104 },
        { id=46, name='Wyvernhunter_Bambrox',      label='Wyvernhunter Bambrox',   tier=3, minLv=135, maxLv=135, groupId=105 },
        { id=47, name='Tolba',                     label='Tolba',                  tier=3, minLv=140, maxLv=140, groupId=106 },
        { id=48, name='Ayapec',                    label='Ayapec',                 tier=3, minLv=140, maxLv=140, groupId=107 },
        { id=49, name='Hidhaegg',                  label='Hidhaegg',               tier=3, minLv=140, maxLv=140, groupId=108 },
        { id=50, name='Coca',                      label='Coca',                   tier=3, minLv=140, maxLv=140, groupId=109 },
        { id=51, name='Grand_Grenade',             label='Grand Grenade',          tier=3, minLv=140, maxLv=140, groupId=110 },
        { id=52, name='Sarama',                    label='Sarama',                 tier=3, minLv=140, maxLv=140, groupId=111 },
        { id=53, name='Azrael',                    label='Azrael',                 tier=3, minLv=145, maxLv=145, groupId=112 },
        { id=54, name='Carousing_Celine',          label='Carousing Celine',       tier=3, minLv=145, maxLv=145, groupId=113 },
        { id=55, name='Camahueto',                 label='Camahueto',              tier=3, minLv=145, maxLv=145, groupId=114 },
        { id=56, name='Borealis_Shadow',           label='Borealis Shadow',        tier=3, minLv=145, maxLv=145, groupId=115 },
    },
}
