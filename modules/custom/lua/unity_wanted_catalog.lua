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
-- Item drops (5% each) are wired via unity_wanted_drops.sql. NMs drop the
-- BASE (NQ) items (owner change 2026-07-12); the +1 versions come from
-- trading the base item to the Unity Wanted Board with Unity Accolades
-- (upgradeCost below, keyed by the dropping NM's tier).
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
local BOARD_POS = { x = 511.0119, y = -3.1516, z = 515.5237, rot = 0 }

-- Second "Re-Hunt" board IN the hunt zone (Escha-Zi'tah), so players can spawn
-- the next NM without warping back to the hub. Placed by the T1 landing point
-- near the T1/T3 arena cluster. PLACEHOLDER coords -- fine-tune with !pos.
local HUNT_BOARD_POS = { x = -198.0, y = -0.5, z = 53.0, rot = 128 }

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
--   drops      : item drop table (5% each via unity_wanted_drops.sql):
--                { id=<NQ itemId>, name='<NQ name>', plus1=<+1 itemId>, plus1Name='<+1 name>' }
--                NQ drops from the NM; +1 comes from the Board upgrade trade.
--                The docs page + gear finder + the upgrade handler all read this.
-----------------------------------
return {
    boardPos     = BOARD_POS,
    huntBoardPos = HUNT_BOARD_POS,
    arena     = ARENA,
    warpPos   = WARP_POS,
    huntZoneId = ZONE_288,

    -- Accolade costs and rewards by tier
    costs    = { [1] = 200,  [2] = 600,  [3] = 1500 },
    rewards  = { [1] = 400,  [2] = 1500, [3] = 4000 },

    -- Accolade cost to upgrade a dropped BASE item to its +1 (trade the base
    -- item to the Unity Wanted Board). Keyed by the tier of the NM that drops
    -- it (owner pricing 2026-07-12).
    upgradeCost = { [1] = 4000, [2] = 15000, [3] = 40000 },

    -- Difficulty scaling applied on spawn (unity_wanted.lua). The base mob HP is
    -- far too low -- ~10k even at T3, killable with auto-attacks -- so set an
    -- absolute HP floor + offensive mods per tier. TUNE HERE. (HP is int32, safe
    -- to set large; att/acc/def/eva/matt/macc/regain/da/ta are int16 entity
    -- mods; dmgMult is the BASE_DAMAGE_MULTIPLIER mobMod, 100 = normal.)
    --
    -- 2026-07-13 rebalance (player reports: 'auto-attacked to death', 'AFKed
    -- Hidhaeg with tank fellow'). Geas-Fete pattern: layered offense --
    -- regain for constant TP moves, DA/TA for spike damage, macc/matt so
    -- casters bite. Tripled the previous multipliers.
    difficulty = {
        -- 2026-07-13 rebalance #2 (player report: 'T1 and T2 still too easy').
        -- Ladder compressed: T1 now uses the old T2 numbers; T2 the old T3
        -- numbers; T3 unchanged. T2 and T3 are intentionally identical -- the
        -- ladder is now cost/reward + weekly-bonus rotation, not raw stats.
        [1] = { hp =  750000, att = 1200, acc = 300, macc = 300, matt = 105, def = 350, eva = 200, regain = 150, da = 75, ta = 15, dmgMult = 175 },
        [2] = { hp = 2400000, att = 1800, acc = 400, macc = 400, matt = 150, def = 500, eva = 260, regain = 240, da = 90, ta = 30, dmgMult = 200 },
        [3] = { hp = 2400000, att = 1800, acc = 400, macc = 400, matt = 150, def = 500, eva = 260, regain = 240, da = 90, ta = 30, dmgMult = 200 },
    },

    -- Grace period (seconds) after spawn during which the mob is untargetable
    -- but already claimed to the paying player. Retail-style 'come prepare'
    -- window (player report 2026-07-13: 'no time to summon trusts before it
    -- aggros me'). Set to 0 to disable.
    graceSeconds = 60,

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
          drops = { {id=21349, name='Wingcutter', plus1=21350, plus1Name='Wingcutter +1'}, {id=27993, name='Macabre Gaunt.', plus1=27994, plus1Name='Macabre Gaunt. +1'} } },
        { id=5,  name='Keeper_of_Heiligtum', label='Keeper of Heiligtum', tier=1, minLv=76, maxLv=76, groupId=28,
          drops = { {id=21034, name='Kunimune', plus1=21035, plus1Name='Kunimune +1'}, {id=27230, name='Zoar Subligar', plus1=27231, plus1Name='Zoar Subligar +1'} } },
        { id=6,  name='Jester_Malatrix',     label='Jester Malatrix',     tier=1, minLv=76, maxLv=76, groupId=33,
          drops = { {id=20806, name='Buramgh', plus1=20807, plus1Name='Buramgh +1'}, {id=27636, name='Evalach', plus1=27637, plus1Name='Evalach +1'} } },
        { id=7,  name='Immanibugard',        label='Immanibugard',        tier=1, minLv=76, maxLv=76, groupId=34,
          drops = { {id=27409, name='Hippo. Socks', plus1=27410, plus1Name='Hippo. Socks +1'}, {id=27560, name='Apeile Ring', plus1=27561, plus1Name='Apeile Ring +1'} } },
        { id=8,  name='Orcfeltrap',          label='Orcfeltrap',          tier=1, minLv=75, maxLv=75, groupId=70,
          drops = { {id=20987, name='Tancho', plus1=20988, plus1Name='Tancho +1'}, {id=28423, name='Shinjutsu-no-Obi', plus1=28424, plus1Name='Shinjutsu-no-Obi +1'} } },
        { id=9,  name='Ironhorn_Baldurno',   label='Ironhorn Baldurno',   tier=1, minLv=78, maxLv=78, groupId=71 },
        { id=10, name='Sleepy_Mabel',        label='Sleepy Mabel',        tier=1, minLv=80, maxLv=80, groupId=72 },
        { id=11, name='Sybaritic_Samantha',  label='Sybaritic Samantha',  tier=1, minLv=78, maxLv=78, groupId=73,
          drops = { {id=27562, name='Metamor. Ring', plus1=27563, plus1Name='Metamor. Ring +1'}, {id=27508, name='Unmoving Collar', plus1=27509, plus1Name='Unmoving Collar +1'} } },
        { id=12, name='Bounding_Belinda',    label='Bounding Belinda',    tier=1, minLv=78, maxLv=78, groupId=74 },
        { id=13, name='Valkurm_Imperator',   label='Valkurm Imperator',   tier=1, minLv=76, maxLv=76, groupId=75,
          drops = { {id=26709, name='Imp. Wing Hair.', plus1=26710, plus1Name='Imp. Wing Hair. +1'}, {id=28273, name='Regal Pumps', plus1=28274, plus1Name='Regal Pumps +1'} } },
        { id=14, name='Joyous_Green',        label='Joyous Green',        tier=1, minLv=76, maxLv=76, groupId=76,
          drops = { {id=28429, name='Acuity Belt', plus1=28430, plus1Name='Acuity Belt +1'}, {id=28352, name='Canto Necklace', plus1=28353, plus1Name='Canto Necklace +1'} } },
        { id=15, name='Warblade_Beak',       label='Warblade Beak',       tier=1, minLv=78, maxLv=78, groupId=77,
          drops = { {id=27995, name='Shigure Tekko', plus1=27996, plus1Name='Shigure Tekko +1'}, {id=28490, name="Handler's Earring", plus1=28491, plus1Name="Handler's Earring +1"} } },
        { id=16, name='Cactrot_Veloz',       label='Cactrot Veloz',       tier=1, minLv=75, maxLv=75, groupId=78,
          drops = { {id=21222, name='Mengado', plus1=21223, plus1Name='Mengado +1'}, {id=28486, name='Arete del Luna', plus1=28487, plus1Name='Arete del Luna +1'} } },
        { id=17, name='Woodland_Mender',     label='Woodland Mender',     tier=1, minLv=75, maxLv=75, groupId=79,
          drops = { {id=21162, name='Pouwhenua', plus1=21163, plus1Name='Pouwhenua +1'}, {id=26868, name='Ros. Jaseran', plus1=26869, plus1Name='Ros. Jaseran +1'} } },
        { id=18, name='Emperor_Arthro',      label='Emperor Arthro',      tier=1, minLv=76, maxLv=76, groupId=80,
          drops = { {id=28136, name='Augury Cuisses', plus1=28137, plus1Name='Augury Cuisses +1'}, {id=28427, name='Sailfi Belt', plus1=28428, plus1Name='Sailfi Belt +1'} } },
        { id=19, name='Tiyanak',             label='Tiyanak',             tier=1, minLv=76, maxLv=76, groupId=81,
          drops = { {id=26896, name='Lugra Cloak', plus1=26897, plus1Name='Lugra Cloak +1'}, {id=28481, name='Lugra Earring', plus1=28482, plus1Name='Lugra Earring +1'} } },
        { id=20, name='Vermillion_Fishfly',  label='Vermillion Fishfly',  tier=1, minLv=78, maxLv=78, groupId=82,
          drops = { {id=25601, name='Blistering Sallet', plus1=25602, plus1Name='Blistering Sallet +1'}, {id=10770, name='Cacoethic Ring', plus1=10771, plus1Name='Cacoethic Ring +1'} } },
        { id=21, name='Intuila',             label='Intuila',             tier=1, minLv=75, maxLv=75, groupId=83,
          drops = { {id=28134, name='Assid. Pants', plus1=28135, plus1Name='Assid. Pants +1'} } },

        -- =====================================================================
        -- TIER 2  (Lv 99-119)
        -- Post-Zilart / Chains of Promathia era NMs
        -- =====================================================================
        { id=22, name='Muut',                label='Muut',                tier=2, minLv=110, maxLv=110, groupId=29,
          drops = { {id=20606, name='Anathema Harpe', plus1=20607, plus1Name='Anathema Harpe +1'} } },
        { id=23, name='Voso',                label='Voso',                tier=2, minLv=119, maxLv=119, groupId=32,
          drops = { {id=26942, name='Agony Jerkin', plus1=26943, plus1Name='Agony Jerkin +1'} } },
        { id=24, name='Beist',               label='Beist',               tier=2, minLv=119, maxLv=119, groupId=35,
          drops = { {id=26714, name='Adorned Helm', plus1=26715, plus1Name='Adorned Helm +1'}, {id=26872, name='Hime Domaru', plus1=26873, plus1Name='Hime Domaru +1'} } },
        { id=25, name='Lumber_Jill',         label='Lumber Jill',         tier=2, minLv=99,  maxLv=99,  groupId=84,
          drops = { {id=20611, name='Sangarius', plus1=20612, plus1Name='Sangarius +1'}, {id=27601, name='Ground. Mantle', plus1=27602, plus1Name='Ground. Mantle +1'} } },
        { id=26, name='Largantua',           label='Largantua',           tier=2, minLv=99,  maxLv=99,  groupId=85,
          drops = { {id=26870, name='Emet Harness', plus1=26871, plus1Name='Emet Harness +1'}, {id=27504, name="Warder's Charm", plus1=27505, plus1Name="Warder's Charm +1"} } },
        { id=27, name='Garbage_Gel',         label='Garbage Gel',         tier=2, minLv=99,  maxLv=99,  groupId=86,
          drops = { {id=20521, name='Emeici', plus1=20522, plus1Name='Emeici +1'}, {id=10768, name='Gelatinous Ring', plus1=10769, plus1Name='Gelatinous Ring +1'} } },
        { id=28, name='King_Uropygid',       label='King Uropygid',       tier=2, minLv=105, maxLv=105, groupId=87,
          drops = { {id=26731, name='Stinger Helm', plus1=26732, plus1Name='Stinger Helm +1'} } },
        { id=29, name='Vedrfolnir',          label='Vedrfolnir',          tier=2, minLv=105, maxLv=105, groupId=88,
          drops = { {id=20527, name='Fists of Fury', plus1=20528, plus1Name='Fists of Fury +1'}, {id=21159, name='Marin Staff', plus1=21160, plus1Name='Marin Staff +1'} } },
        { id=30, name='Glazemane',           label='Glazemane',           tier=2, minLv=105, maxLv=105, groupId=89,
          drops = { {id=20580, name='Kustawi', plus1=20581, plus1Name='Kustawi +1'}, {id=21690, name='Ushenzi', plus1=21691, plus1Name='Ushenzi +1'} } },
        { id=31, name='Volatile_Cluster',    label='Volatile Cluster',    tier=2, minLv=105, maxLv=105, groupId=90,
          drops = { {id=21029, name='Norifusa', plus1=21030, plus1Name='Norifusa +1'}, {id=27619, name="Aurist's Cape", plus1=27620, plus1Name="Aurist's Cape +1"} } },
        { id=32, name='Strix',               label='Strix',               tier=2, minLv=110, maxLv=110, groupId=91,
          drops = { {id=21099, name='Magesmasher', plus1=21100, plus1Name='Magesmasher +1'}, {id=28275, name='Jute Boots', plus1=28276, plus1Name='Jute Boots +1'} } },
        { id=33, name='Sovereign_Behemoth',  label='Sovereign Behemoth',  tier=2, minLv=119, maxLv=119, groupId=92,
          drops = { {id=22266, name='Antitail', plus1=22267, plus1Name='Antitail +1'}, {id=27542, name='Domin. Earring', plus1=27543, plus1Name='Domin. Earring +1'}, {id=26001, name='Loricate Torque', plus1=26002, plus1Name='Loricate Torque +1'} } },
        { id=34, name='Arke',               label='Arke',                tier=2, minLv=119, maxLv=119, groupId=93,
          drops = { {id=20613, name='Pukulatmuj', plus1=20614, plus1Name='Pukulatmuj +1'}, {id=21164, name='Ababinili', plus1=21165, plus1Name='Ababinili +1'} } },
        { id=35, name='Douma_Weapon',        label='Douma Weapon',        tier=2, minLv=105, maxLv=105, groupId=94,
          drops = { {id=26887, name='Shomonjijoe', plus1=26888, plus1Name='Shomonjijoe +1'}, {id=21418, name='Rigorous Grip', plus1=21419, plus1Name='Rigorous Grip +1'} } },
        { id=36, name='Kubool_Jas_Mhuufya',  label='Kubool Jas Mhuufya',  tier=2, minLv=110, maxLv=110, groupId=95,
          drops = { {id=20799, name='Mdomo Axe', plus1=20800, plus1Name='Mdomo Axe +1'}, {id=27532, name='Zwazo Earring', plus1=27533, plus1Name='Zwazo Earring +1'} } },
        { id=37, name='Thuban',              label="Thu'ban",             tier=2, minLv=115, maxLv=115, groupId=96,
          drops = { {id=21748, name='Habilitator', plus1=21749, plus1Name='Habilitator +1'}, {id=25923, name='Tatena. Sune.', plus1=25924, plus1Name='Tatena. Sune. +1'}, {id=26021, name='Vim Torque', plus1=26022, plus1Name='Vim Torque +1'} } },
        { id=38, name='Tumult_Curator',      label='Tumult Curator',      tier=2, minLv=119, maxLv=119, groupId=97,
          drops = { {id=20507, name='Comeuppances', plus1=20508, plus1Name='Comeuppances +1'}, {id=25732, name='Tatena. Harama.', plus1=25733, plus1Name='Tatena. Harama. +1'}, {id=22057, name='Contemplator', plus1=22058, plus1Name='Contemplator +1'} } },

        -- =====================================================================
        -- TIER 3  (Lv 120-145)
        -- High-tier endgame Unity NMs
        -- =====================================================================
        { id=39, name='Specter_Worm',              label='Specter Worm',           tier=3, minLv=128, maxLv=128, groupId=98,
          drops = { {id=21702, name='Kladenets', plus1=21703, plus1Name='Kladenets +1'}, {id=21343, name='Ghastly Tathlum', plus1=21344, plus1Name='Ghastly Tathlum +1'} } },
        { id=40, name='Bakunawa',                  label='Bakunawa',               tier=3, minLv=128, maxLv=128, groupId=99,
          drops = { {id=20708, name='Demers. Degen', plus1=20709, plus1Name='Demers. Degen +1'}, {id=27517, name='Bathy Choker', plus1=27518, plus1Name='Bathy Choker +1'} } },
        { id=41, name='Mephitas',                  label='Mephitas',               tier=3, minLv=128, maxLv=128, groupId=100,
          drops = { {id=20603, name='Ternion Dagger', plus1=20604, plus1Name='Ternion Dagger +1'}, {id=27558, name="Mephitas's Ring", plus1=27559, plus1Name="Mephitas's Ring +1"} } },
        { id=42, name='Vidmapire',                 label='Vidmapire',              tier=3, minLv=128, maxLv=128, groupId=101,
          drops = { {id=20980, name='Raicho', plus1=20981, plus1Name='Raicho +1'}, {id=27609, name='Fi Follet Cape', plus1=27610, plus1Name='Fi Follet Cape +1'} } },
        { id=43, name='Shedu',                     label='Shedu',                  tier=3, minLv=135, maxLv=135, groupId=102,
          drops = { {id=20681, name='Flyssa', plus1=20682, plus1Name='Flyssa +1'}, {id=21075, name='Septoptic', plus1=21076, plus1Name='Septoptic +1'}, {id=27148, name='Tatena. Gote', plus1=27149, plus1Name='Tatena. Gote +1'} } },
        { id=44, name='Azure-toothed_Clawberry',   label='Azure-toothed Clawberry',tier=3, minLv=135, maxLv=135, groupId=103,
          drops = { {id=27106, name='Asteria Mitts', plus1=27107, plus1Name='Asteria Mitts +1'}, {id=27108, name='Lamassu Mitts', plus1=27109, plus1Name='Lamassu Mitts +1'} } },
        { id=45, name='Centurio_XX-I',             label='Centurio XX-I',          tier=3, minLv=135, maxLv=135, groupId=104,
          drops = { {id=25680, name='Cohort Cloak', plus1=25681, plus1Name='Cohort Cloak +1'}, {id=28412, name='Kentarch Belt', plus1=28413, plus1Name='Kentarch Belt +1'} } },
        { id=46, name='Wyvernhunter_Bambrox',      label='Wyvernhunter Bambrox',   tier=3, minLv=135, maxLv=135, groupId=105,
          drops = { {id=21805, name='Pixquizpan', plus1=21806, plus1Name='Pixquizpan +1'}, {id=22120, name='Imati', plus1=22121, plus1Name='Imati +1'} } },
        { id=47, name='Tolba',                     label='Tolba',                  tier=3, minLv=140, maxLv=140, groupId=106,
          drops = { {id=21483, name='Malison', plus1=21484, plus1Name='Malison +1'}, {id=25709, name='Obviat. Cuirass', plus1=25710, plus1Name='Obviat. Cuirass +1'}, {id=26401, name='Forfend', plus1=26402, plus1Name='Forfend +1'} } },
        { id=48, name='Ayapec',                    label='Ayapec',                 tier=3, minLv=140, maxLv=140, groupId=107,
          drops = { {id=20804, name='Perun', plus1=20805, plus1Name='Perun +1'}, {id=26784, name='Hike Khat', plus1=26785, plus1Name='Hike Khat +1'} } },
        { id=49, name='Hidhaegg',                  label='Hidhaegg',               tier=3, minLv=140, maxLv=140, groupId=108,
          drops = { {id=20696, name='Combuster', plus1=20697, plus1Name='Combuster +1'}, {id=21695, name='Nullis', plus1=21696, plus1Name='Nullis +1'}, {id=25635, name='Loess Barbuta', plus1=25636, plus1Name='Loess Barbuta +1'} } },
        { id=50, name='Coca',                      label='Coca',                   tier=3, minLv=140, maxLv=140, groupId=109,
          drops = { {id=20942, name='Gae Derg', plus1=20943, plus1Name='Gae Derg +1'}, {id=27638, name='Ajax', plus1=27639, plus1Name='Ajax +1'} } },
        { id=51, name='Grand_Grenade',             label='Grand Grenade',          tier=3, minLv=140, maxLv=140, groupId=110,
          drops = { {id=21090, name='Loxotic Mace', plus1=21091, plus1Name='Loxotic Mace +1'}, {id=22254, name='Seeth. Bomblet', plus1=22255, plus1Name='Seeth. Bomblet +1'} } },
        { id=52, name='Sarama',                    label='Sarama',                 tier=3, minLv=140, maxLv=140, groupId=111,
          drops = { {id=21688, name='Montante', plus1=21689, plus1Name='Montante +1'}, {id=20679, name='Tanmogayi', plus1=20680, plus1Name='Tanmogayi +1'}, {id=25855, name='Tatena. Haidate', plus1=25856, plus1Name='Tatena. Haidate +1'} } },
        { id=53, name='Azrael',                    label='Azrael',                 tier=3, minLv=145, maxLv=145, groupId=112,
          drops = { {id=20851, name='Aizkora', plus1=20852, plus1Name='Aizkora +1'}, {id=26786, name='Alhazen Hat', plus1=26787, plus1Name='Alhazen Hat +1'} } },
        { id=54, name='Carousing_Celine',          label='Carousing Celine',       tier=3, minLv=145, maxLv=145, groupId=113,
          drops = { {id=27150, name='Gazu Bracelets', plus1=27151, plus1Name='Gazu Bracelets +1'}, {id=27548, name='Odnowa Earring', plus1=27549, plus1Name='Odnowa Earring +1'} } },
        { id=55, name='Camahueto',                 label='Camahueto',              tier=3, minLv=145, maxLv=145, groupId=114,
          drops = { {id=20898, name='Triska Scythe', plus1=20899, plus1Name='Triska Scythe +1'}, {id=27407, name='Hygieia Clogs', plus1=27408, plus1Name='Hygieia Clogs +1'} } },
        { id=56, name='Borealis_Shadow',           label='Borealis Shadow',        tier=3, minLv=145, maxLv=145, groupId=115,
          drops = { {id=20853, name='Beheader', plus1=20854, plus1Name='Beheader +1'}, {id=20527, name='Fists of Fury', plus1=20528, plus1Name='Fists of Fury +1'}, {id=21219, name='Paloma Bow', plus1=21220, plus1Name='Paloma Bow +1'}, {id=27640, name='Deliverance', plus1=27641, plus1Name='Deliverance +1'} } },
    },
}
