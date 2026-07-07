-----------------------------------
-- unity_wanted_catalog.lua
-- Unity Wanted NM definitions for the relaunch Unity Concord system.
-- All NMs spawn in zone 288 (Escha-Zi'tah) via
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
-- Item drops (50% each) are wired via unity_wanted_drops.sql.
-----------------------------------

local ZONE_288 = xi.zone.ESCHA_ZITAH  -- == 288

-- Arena spawn cluster positions inside zone 288.
-- Each tier gets a dedicated area well away from the Hunting League clusters.
-- T1/T2 share a western arena; T3 has a separate deeper area.
-- TUNE: adjust after in-game map testing.
local ARENA = {
    T1 = { x = -200.0, y = -0.5, z =  50.0, rot = 128 },
    T2 = { x = -33.5, y = 0.5, z = -150.8, rot = 45 },
    T3 = { x = -250.0, y = -0.5, z =  30.0, rot = 128 },
}

-- Board NPC location in Celennia Memorial Library.
local BOARD_POS = { x = 560.971, y = -3.360, z = 544.586, rot = 64 }

-- Warp landing point for players entering the Unity Arena in zone 288.
-- Position them slightly east of the mob spawn to face the NM.
local WARP_POS = {
    T1 = { x = -195.0, y = -0.5, z =  50.0, rot = 128 },
    T2 = { x = -26.5, y = 0.5, z = -165.5, rot = 171 },
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
--   drops      : item drop table for documentation (50% each via unity_wanted_drops.sql)
--                { id=itemId, name='Display Name' } — name used on the docs page
-----------------------------------
return {
    boardPos  = BOARD_POS,
    arena     = ARENA,
    warpPos   = WARP_POS,
    huntZoneId = ZONE_288,

    -- Accolade costs and rewards by tier
    costs    = { [1] = 200,  [2] = 600,  [3] = 1500 },
    rewards  = { [1] = 400,  [2] = 1500, [3] = 4000 },

    -- The 11 Unity leaders (xi.unityLeader). id = setUnityLeader() value.
    -- Display names kept short to fit the customMenu 150-byte/menu cap.
    leaders =
    {
        { id = 1,  name = 'Pieuje'      },
        { id = 2,  name = 'Ayame'       },
        { id = 3,  name = 'Inv. Shield' },
        { id = 4,  name = 'Apururu'     },
        { id = 5,  name = 'Maat'        },
        { id = 6,  name = 'Aldo'        },
        { id = 7,  name = 'Jakoh W.'    },
        { id = 8,  name = 'Naja S.'     },
        { id = 9,  name = 'Flaviria'    },
        { id = 10, name = 'Yoran-Oran'  },
        { id = 11, name = 'Sylvie'      },
    },

    -- Accolade reward shop (spend unity_accolades). Known-valid item ids reused
    -- from the LSB Unity NPC shop (scripts/globals/unity.lua). Easily expanded --
    -- add { item = xi.item.XXX, label = '...', cost = N } rows.
    shop =
    {
        { item = xi.item.SCROLL_OF_INSTANT_PROTECT, label = 'Instant Protect',     cost = 50   },
        { item = xi.item.SCROLL_OF_INSTANT_SHELL,   label = 'Instant Shell',       cost = 50   },
        { item = xi.item.SCROLL_OF_INSTANT_WARP,    label = 'Instant Warp',        cost = 100  },
        { item = xi.item.SCROLL_OF_INSTANT_RERAISE, label = 'Instant Reraise',     cost = 200  },
        { item = xi.item.TRAINING_MANUAL,           label = 'Training Manual',     cost = 100  },
        { item = xi.item.PINCH_OF_PRIZE_POWDER,     label = 'Prize Powder',        cost = 150  },
        { item = xi.item.REFRACTIVE_CRYSTAL,        label = 'Refractive Crystal',  cost = 2000 },
        { item = xi.item.SPECIAL_GOBBIEDIAL_KEY,    label = 'Gobbiedial Key',      cost = 3000 },
    },

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
        { id=4,  name='Abyssdiver',          label='Abyssdiver',          tier=1, minLv=75, maxLv=75, groupId=27,
          drops = { {id=21350, name='Wingcutter +1'}, {id=27994, name='Macabre Gaunt. +1'} } },
        { id=5,  name='Keeper_of_Heiligtum', label='Keeper of Heiligtum', tier=1, minLv=76, maxLv=76, groupId=28,
          drops = { {id=21035, name='Kunimune +1'}, {id=27231, name='Zoar Subligar +1'} } },
        { id=6,  name='Jester_Malatrix',     label='Jester Malatrix',     tier=1, minLv=76, maxLv=76, groupId=33,
          drops = { {id=20807, name='Buramgh +1'}, {id=27637, name='Evalach +1'} } },
        { id=7,  name='Immanibugard',        label='Immanibugard',        tier=1, minLv=76, maxLv=76, groupId=34,
          drops = { {id=27410, name='Hippo. Socks +1'}, {id=27561, name='Apeile Ring +1'} } },
        { id=8,  name='Orcfeltrap',          label='Orcfeltrap',          tier=1, minLv=75, maxLv=75, groupId=70,
          drops = { {id=20988, name='Tancho +1'}, {id=28424, name='Shinjutsu-no-Obi +1'} } },
        { id=9,  name='Ironhorn_Baldurno',   label='Ironhorn Baldurno',   tier=1, minLv=78, maxLv=78, groupId=71 },
        { id=10, name='Sleepy_Mabel',        label='Sleepy Mabel',        tier=1, minLv=80, maxLv=80, groupId=72 },
        { id=11, name='Sybaritic_Samantha',  label='Sybaritic Samantha',  tier=1, minLv=78, maxLv=78, groupId=73,
          drops = { {id=27563, name='Metamor. Ring +1'}, {id=27509, name='Unmoving Collar +1'} } },
        { id=12, name='Bounding_Belinda',    label='Bounding Belinda',    tier=1, minLv=78, maxLv=78, groupId=74 },
        { id=13, name='Valkurm_Imperator',   label='Valkurm Imperator',   tier=1, minLv=76, maxLv=76, groupId=75,
          drops = { {id=26710, name='Imp. Wing Hair. +1'}, {id=28274, name='Regal Pumps +1'} } },
        { id=14, name='Joyous_Green',        label='Joyous Green',        tier=1, minLv=76, maxLv=76, groupId=76,
          drops = { {id=28430, name='Acuity Belt +1'}, {id=28353, name='Canto Necklace +1'} } },
        { id=15, name='Warblade_Beak',       label='Warblade Beak',       tier=1, minLv=78, maxLv=78, groupId=77,
          drops = { {id=27996, name='Shigure Tekko +1'}, {id=28491, name="Handler's Earring +1"} } },
        { id=16, name='Cactrot_Veloz',       label='Cactrot Veloz',       tier=1, minLv=75, maxLv=75, groupId=78,
          drops = { {id=21223, name='Mengado +1'}, {id=28487, name='Arete del Luna +1'} } },
        { id=17, name='Woodland_Mender',     label='Woodland Mender',     tier=1, minLv=75, maxLv=75, groupId=79,
          drops = { {id=21163, name='Pouwhenua +1'}, {id=26869, name='Ros. Jaseran +1'} } },
        { id=18, name='Emperor_Arthro',      label='Emperor Arthro',      tier=1, minLv=76, maxLv=76, groupId=80,
          drops = { {id=28137, name='Augury Cuisses +1'}, {id=28428, name='Sailfi Belt +1'} } },
        { id=19, name='Tiyanak',             label='Tiyanak',             tier=1, minLv=76, maxLv=76, groupId=81,
          drops = { {id=26897, name='Lugra Cloak +1'}, {id=28482, name='Lugra Earring +1'} } },
        { id=20, name='Vermillion_Fishfly',  label='Vermillion Fishfly',  tier=1, minLv=78, maxLv=78, groupId=82,
          drops = { {id=25602, name='Blistering Sallet +1'}, {id=10771, name='Cacoethic Ring +1'} } },
        { id=21, name='Intuila',             label='Intuila',             tier=1, minLv=75, maxLv=75, groupId=83,
          drops = { {id=28135, name='Assid. Pants +1'} } },

        -- =====================================================================
        -- TIER 2  (Lv 99-119)
        -- Post-Zilart / Chains of Promathia era NMs
        -- =====================================================================
        { id=22, name='Muut',                label='Muut',                tier=2, minLv=110, maxLv=110, groupId=29,
          drops = { {id=20607, name='Anathema Harpe +1'} } },
        { id=23, name='Voso',                label='Voso',                tier=2, minLv=119, maxLv=119, groupId=32,
          drops = { {id=26943, name='Agony Jerkin +1'} } },
        { id=24, name='Beist',               label='Beist',               tier=2, minLv=119, maxLv=119, groupId=35,
          drops = { {id=26715, name='Adorned Helm +1'}, {id=26873, name='Hime Domaru +1'} } },
        { id=25, name='Lumber_Jill',         label='Lumber Jill',         tier=2, minLv=99,  maxLv=99,  groupId=84,
          drops = { {id=20612, name='Sangarius +1'}, {id=27602, name='Ground. Mantle +1'} } },
        { id=26, name='Largantua',           label='Largantua',           tier=2, minLv=99,  maxLv=99,  groupId=85,
          drops = { {id=26871, name='Emet Harness +1'}, {id=27505, name="Warder's Charm +1"} } },
        { id=27, name='Garbage_Gel',         label='Garbage Gel',         tier=2, minLv=99,  maxLv=99,  groupId=86,
          drops = { {id=20522, name='Emeici +1'}, {id=10769, name='Gelatinous Ring +1'} } },
        { id=28, name='King_Uropygid',       label='King Uropygid',       tier=2, minLv=105, maxLv=105, groupId=87,
          drops = { {id=26732, name='Stinger Helm +1'} } },
        { id=29, name='Vedrfolnir',          label='Vedrfolnir',          tier=2, minLv=105, maxLv=105, groupId=88,
          drops = { {id=20528, name='Fists of Fury +1'}, {id=21160, name='Marin Staff +1'} } },
        { id=30, name='Glazemane',           label='Glazemane',           tier=2, minLv=105, maxLv=105, groupId=89,
          drops = { {id=20581, name='Kustawi +1'}, {id=21691, name='Ushenzi +1'} } },
        { id=31, name='Volatile_Cluster',    label='Volatile Cluster',    tier=2, minLv=105, maxLv=105, groupId=90,
          drops = { {id=21030, name='Norifusa +1'}, {id=27620, name="Aurist's Cape +1"} } },
        { id=32, name='Strix',               label='Strix',               tier=2, minLv=110, maxLv=110, groupId=91,
          drops = { {id=21100, name='Magesmasher +1'}, {id=28276, name='Jute Boots +1'} } },
        { id=33, name='Sovereign_Behemoth',  label='Sovereign Behemoth',  tier=2, minLv=119, maxLv=119, groupId=92,
          drops = { {id=22267, name='Antitail +1'}, {id=27543, name='Domin. Earring +1'}, {id=26002, name='Loricate Torque +1'} } },
        { id=34, name='Arke',               label='Arke',                tier=2, minLv=119, maxLv=119, groupId=93,
          drops = { {id=20614, name='Pukulatmuj +1'}, {id=21165, name='Ababinili +1'} } },
        { id=35, name='Douma_Weapon',        label='Douma Weapon',        tier=2, minLv=105, maxLv=105, groupId=94,
          drops = { {id=26888, name='Shomonjijoe +1'}, {id=21419, name='Rigorous Grip +1'} } },
        { id=36, name='Kubool_Jas_Mhuufya',  label='Kubool Jas Mhuufya',  tier=2, minLv=110, maxLv=110, groupId=95,
          drops = { {id=20800, name='Mdomo Axe +1'}, {id=27533, name='Zwazo Earring +1'} } },
        { id=37, name='Thuban',              label="Thu'ban",             tier=2, minLv=115, maxLv=115, groupId=96,
          drops = { {id=21749, name='Habilitator +1'}, {id=25924, name='Tatena. Sune. +1'}, {id=26022, name='Vim Torque +1'} } },
        { id=38, name='Tumult_Curator',      label='Tumult Curator',      tier=2, minLv=119, maxLv=119, groupId=97,
          drops = { {id=20508, name='Comeuppances +1'}, {id=25733, name='Tatena. Harama. +1'}, {id=22058, name='Contemplator +1'} } },

        -- =====================================================================
        -- TIER 3  (Lv 120-145)
        -- High-tier endgame Unity NMs
        -- =====================================================================
        { id=39, name='Specter_Worm',              label='Specter Worm',           tier=3, minLv=128, maxLv=128, groupId=98,
          drops = { {id=21703, name='Kladenets +1'}, {id=21344, name='Ghastly Tathlum +1'} } },
        { id=40, name='Bakunawa',                  label='Bakunawa',               tier=3, minLv=128, maxLv=128, groupId=99,
          drops = { {id=20709, name='Demers. Degen +1'}, {id=27518, name='Bathy Choker +1'} } },
        { id=41, name='Mephitas',                  label='Mephitas',               tier=3, minLv=128, maxLv=128, groupId=100,
          drops = { {id=20604, name='Ternion Dagger +1'}, {id=27559, name="Mephitas's Ring +1"} } },
        { id=42, name='Vidmapire',                 label='Vidmapire',              tier=3, minLv=128, maxLv=128, groupId=101,
          drops = { {id=20981, name='Raicho +1'}, {id=27610, name='Fi Follet Cape +1'} } },
        { id=43, name='Shedu',                     label='Shedu',                  tier=3, minLv=135, maxLv=135, groupId=102,
          drops = { {id=20682, name='Flyssa +1'}, {id=21076, name='Septoptic +1'}, {id=27149, name='Tatena. Gote +1'} } },
        { id=44, name='Azure-toothed_Clawberry',   label='Azure-toothed Clawberry',tier=3, minLv=135, maxLv=135, groupId=103,
          drops = { {id=27107, name='Asteria Mitts +1'}, {id=27109, name='Lamassu Mitts +1'} } },
        { id=45, name='Centurio_XX-I',             label='Centurio XX-I',          tier=3, minLv=135, maxLv=135, groupId=104,
          drops = { {id=25681, name='Cohort Cloak +1'}, {id=28413, name='Kentarch Belt +1'} } },
        { id=46, name='Wyvernhunter_Bambrox',      label='Wyvernhunter Bambrox',   tier=3, minLv=135, maxLv=135, groupId=105,
          drops = { {id=21806, name='Pixquizpan +1'}, {id=22121, name='Imati +1'} } },
        { id=47, name='Tolba',                     label='Tolba',                  tier=3, minLv=140, maxLv=140, groupId=106,
          drops = { {id=21484, name='Malison +1'}, {id=25710, name='Obviat. Cuirass +1'}, {id=26402, name='Forfend +1'} } },
        { id=48, name='Ayapec',                    label='Ayapec',                 tier=3, minLv=140, maxLv=140, groupId=107,
          drops = { {id=20805, name='Perun +1'}, {id=26785, name='Hike Khat +1'} } },
        { id=49, name='Hidhaegg',                  label='Hidhaegg',               tier=3, minLv=140, maxLv=140, groupId=108,
          drops = { {id=20697, name='Combuster +1'}, {id=21696, name='Nullis +1'}, {id=25636, name='Loess Barbuta +1'} } },
        { id=50, name='Coca',                      label='Coca',                   tier=3, minLv=140, maxLv=140, groupId=109,
          drops = { {id=20943, name='Gae Derg +1'}, {id=27639, name='Ajax +1'} } },
        { id=51, name='Grand_Grenade',             label='Grand Grenade',          tier=3, minLv=140, maxLv=140, groupId=110,
          drops = { {id=21091, name='Loxotic Mace +1'}, {id=22255, name='Seeth. Bomblet +1'} } },
        { id=52, name='Sarama',                    label='Sarama',                 tier=3, minLv=140, maxLv=140, groupId=111,
          drops = { {id=21689, name='Montante +1'}, {id=20680, name='Tanmogayi +1'}, {id=25856, name='Tatena. Haidate +1'} } },
        { id=53, name='Azrael',                    label='Azrael',                 tier=3, minLv=145, maxLv=145, groupId=112,
          drops = { {id=20852, name='Aizkora +1'}, {id=26787, name='Alhazen Hat +1'} } },
        { id=54, name='Carousing_Celine',          label='Carousing Celine',       tier=3, minLv=145, maxLv=145, groupId=113,
          drops = { {id=27151, name='Gazu Bracelets +1'}, {id=27549, name='Odnowa Earring +1'} } },
        { id=55, name='Camahueto',                 label='Camahueto',              tier=3, minLv=145, maxLv=145, groupId=114,
          drops = { {id=20899, name='Triska Scythe +1'}, {id=27408, name='Hygieia Clogs +1'} } },
        { id=56, name='Borealis_Shadow',           label='Borealis Shadow',        tier=3, minLv=145, maxLv=145, groupId=115,
          drops = { {id=20854, name='Beheader +1'}, {id=20528, name='Fists of Fury +1'}, {id=21220, name='Paloma Bow +1'}, {id=27641, name='Deliverance +1'} } },
    },
}
