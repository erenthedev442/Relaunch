-----------------------------------
-- unity_junction_map.lua  (AUTO-GENERATED 2026-07-12 -- regen via
-- scratchpad gen_unity_junctions.py; sources: sql/npc_list.sql stock
-- Ethereal_Junction rows + the retail NM->zone table from BG-wiki
-- Category:Unity_Concord.)
--
-- byNm:      catalog NM name -> retail zone id (where its junction is)
-- junctions: zone id -> { zoneName, list of stock junction NPC ids +
--            positions }. warp = first junction, offset in the module.
-----------------------------------
return {
    byNm = {
        ['Abyssdiver'] = 118,  -- Buburimu Peninsula
        ['Arke'] = 120,  -- Sauromugue Champaign
        ['Ayapec'] = 153,  -- The Boyahda Tree
        ['Azrael'] = 160,  -- Den of Rancor
        ['Azure-toothed_Clawberry'] = 159,  -- Temple of Uggalepih
        ['Bakunawa'] = 176,  -- Sea Serpent Grotto
        ['Beist'] = 112,  -- Xarcabard
        ['Borealis_Shadow'] = 204,  -- Fei'Yin
        ['Bounding_Belinda'] = 107,  -- South Gustaberg
        ['Cactrot_Veloz'] = 114,  -- Eastern Altepa Desert
        ['Camahueto'] = 5,  -- Uleguerand Range
        ['Carousing_Celine'] = 204,  -- Fei'Yin
        ['Centurio_XX-I'] = 208,  -- Quicksand Caves
        ['Coca'] = 205,  -- Ifrit's Cauldron
        ['Douma_Weapon'] = 122,  -- Ro'Maeve
        ['Emperor_Arthro'] = 104,  -- Jugner Forest
        ['Garbage_Gel'] = 167,  -- Bostaunieux Oubliette
        ['Glazemane'] = 113,  -- Cape Teriggan
        ['Grand_Grenade'] = 61,  -- Mount Zhayolm
        ['Hidhaegg'] = 153,  -- The Boyahda Tree
        ['Hugemaw_Harold'] = 101,  -- East Ronfaure
        ['Immanibugard'] = 24,  -- Lufaise Meadows
        ['Intuila'] = 4,  -- Bibiki Bay
        ['Ironhorn_Baldurno'] = 102,  -- La Theine Plateau
        ['Jester_Malatrix'] = 126,  -- Qufim Island
        ['Joyous_Green'] = 109,  -- Pashhow Marshlands
        ['Keeper_of_Heiligtum'] = 121,  -- The Sanctuary of Zi'Tah
        ['King_Uropygid'] = 125,  -- Western Altepa Desert
        ['Kubool_Jas_Mhuufya'] = 51,  -- Wajaom Woodlands
        ['Largantua'] = 111,  -- Beaucedine Glacier
        ['Lumber_Jill'] = 105,  -- Batallia Downs
        ['Mephitas'] = 200,  -- Garlaige Citadel
        ['Muut'] = 7,  -- Attohwa Chasm
        ['Orcfeltrap'] = 2,  -- Carpenters' Landing
        ['Prickly_Pitriv'] = 116,  -- East Sarutabaruta
        ['Sarama'] = 61,  -- Mount Zhayolm
        ['Serpopard_Ninlil'] = 117,  -- Tahrongi Canyon
        ['Shedu'] = 79,  -- Caedarva Mire
        ['Sleepy_Mabel'] = 108,  -- Konschtat Highlands
        ['Sovereign_Behemoth'] = 127,  -- Behemoth's Dominion
        ['Specter_Worm'] = 174,  -- Kuftal Tunnel
        ['Strix'] = 110,  -- Rolanberry Fields
        ['Sybaritic_Samantha'] = 123,  -- Yuhtunga Jungle
        ['Thuban'] = 51,  -- Wajaom Woodlands
        ['Tiyanak'] = 25,  -- Misareaux Coast
        ['Tolba'] = 128,  -- Valley of Sorrows
        ['Tumult_Curator'] = 68,  -- Aydeewa Subterrane
        ['Valkurm_Imperator'] = 103,  -- Valkurm Dunes
        ['Vedrfolnir'] = 113,  -- Cape Teriggan
        ['Vermillion_Fishfly'] = 24,  -- Lufaise Meadows
        ['Vidmapire'] = 72,  -- Alzadaal Undersea Ruins
        ['Volatile_Cluster'] = 25,  -- Misareaux Coast
        ['Voso'] = 213,  -- Labyrinth of Onzozo
        ['Warblade_Beak'] = 119,  -- Meriphataud Mountains
        ['Woodland_Mender'] = 124,  -- Yhoator Jungle
        ['Wyvernhunter_Bambrox'] = 212,  -- Gustav Tunnel
    },
    junctions = {
        [2] = { zoneName = 'Carpenters_Landing', points = {
            { id = 16785786, x = 126.09, y = -6.84, z = -440.03, rot = 0 },
            { id = 16785787, x = 152.89, y = -8.74, z = -511.44, rot = 0 },
            { id = 16785788, x = 77.98, y = -6.0, z = -603.0, rot = 0 },
        } },
        [4] = { zoneName = 'Bibiki_Bay', points = {
            { id = 0, x = 582.55, y = -20.54, z = 847.86, rot = 0, custom = true },
            { id = 16794045, x = 198.67, y = -28.0, z = 562.66, rot = 0 },
            { id = 16794046, x = 361.16, y = -20.0, z = 319.81, rot = 0 },
        } },
        [5] = { zoneName = 'Uleguerand_Range', points = {
            { id = 16798157, x = -241.09, y = -19.13, z = -302.63, rot = 0 },
            { id = 16798158, x = -604.66, y = -48.06, z = -124.24, rot = 0 },
            { id = 16798159, x = -638.82, y = -39.2, z = -16.11, rot = 0 },
        } },
        [7] = { zoneName = 'Attohwa_Chasm', points = {
            { id = 16806389, x = -357.24, y = -4.0, z = 240.21, rot = 0 },
            { id = 16806390, x = -595.16, y = -3.96, z = 119.09, rot = 0 },
            { id = 16806391, x = -240.48, y = -3.97, z = -75.33, rot = 0 },
        } },
        [24] = { zoneName = 'Lufaise_Meadows', points = {
            { id = 16875918, x = -167.97, y = -15.94, z = 117.02, rot = 0 },
            { id = 16875919, x = 200.02, y = 0.26, z = -89.29, rot = 0 },
            { id = 16875920, x = 398.1, y = 0.69, z = -144.07, rot = 0 },
        } },
        [25] = { zoneName = 'Misareaux_Coast', points = {
            { id = 16879997, x = -66.48, y = -15.13, z = 18.72, rot = 0 },
            { id = 16879998, x = -222.85, y = -31.14, z = 118.53, rot = 0 },
            { id = 16879999, x = 297.84, y = 24.64, z = -342.37, rot = 0 },
        } },
        [51] = { zoneName = 'Wajaom_Woodlands', points = {
            -- Stock rows are uncaptured (0,0,0). These safe anchors correspond
            -- to the three retail Wajaom battle areas at K-9, I-9, and I-8.
            { id = 0, x = 358.827, y = -16.241, z = -52.142, rot = 128, custom = true },
            { id = 0, x = 184.674, y = -20.0, z = -94.958, rot = 128, custom = true },
            { id = 0, x = 104.620, y = -20.750, z = 47.619, rot = 128, custom = true },
        } },
        [61] = { zoneName = 'Mount_Zhayolm', points = {
            { id = 0, x = 404.5, y = -27.513, z = 123.5, rot = 128, custom = true },
        } },
        [68] = { zoneName = 'Aydeewa_Subterrane', points = {
            { id = 0, x = 6.0, y = 20.0, z = -88.0, rot = 64, custom = true },
        } },
        [72] = { zoneName = 'Alzadaal_Undersea_Ruins', points = {
            { id = 17072392, x = 73.0, y = -4.0, z = -73.0, rot = 0 },
        } },
        [79] = { zoneName = 'Caedarva_Mire', points = {
            { id = 0, x = -658.0, y = -13.0, z = 343.0, rot = 64, custom = true },
        } },
        [101] = { zoneName = 'East_Ronfaure', points = {
            { id = 17191542, x = 522.23, y = -30.0, z = -41.48, rot = 0 },
            { id = 17191543, x = 237.74, y = -20.0, z = -160.0, rot = 0 },
            { id = 17191544, x = 565.27, y = -10.29, z = -378.18, rot = 0 },
        } },
        [102] = { zoneName = 'La_Theine_Plateau', points = {
            { id = 0, x = 777.0, y = 28.5, z = -16.0, rot = 224, custom = true },
        } },
        [103] = { zoneName = 'Valkurm_Dunes', points = {
            { id = 17199761, x = 718.63, y = 0.0, z = -83.62, rot = 0 },
        } },
        [104] = { zoneName = 'Jugner_Forest', points = {
            { id = 0, x = 84.97, y = 0.33, z = -201.37, rot = 0, custom = true },
        } },
        [105] = { zoneName = 'Batallia_Downs', points = {
            { id = 0, x = -65.0, y = -2.0, z = 451.0, rot = 192, custom = true },
        } },
        [107] = { zoneName = 'South_Gustaberg', points = {
            { id = 17216191, x = -153.8, y = -0.12, z = -200.77, rot = 0 },
        } },
        [108] = { zoneName = 'Konschtat_Highlands', points = {
            { id = 17220173, x = -315.28, y = 47.96, z = 564.78, rot = 0 },
        } },
        [109] = { zoneName = 'Pashhow_Marshlands', points = {
            { id = 0, x = 469.0, y = 24.489, z = 412.0, rot = 32, custom = true },
        } },
        [110] = { zoneName = 'Rolanberry_Fields', points = {
            { id = 17228385, x = -678.01, y = -32.0, z = -482.68, rot = 0 },
        } },
        [111] = { zoneName = 'Beaucedine_Glacier', points = {
            { id = 0, x = -26.0, y = -59.56, z = -123.0, rot = 32, custom = true },
        } },
        [112] = { zoneName = 'Xarcabard', points = {
            { id = 17236357, x = 400.59, y = -0.04, z = -244.78, rot = 0 },
            { id = 17236358, x = 353.1, y = -7.8, z = -67.06, rot = 0 },
            { id = 17236359, x = 343.8, y = -8.28, z = 110.78, rot = 0 },
        } },
        [113] = { zoneName = 'Cape_Teriggan', points = {
            { id = 0, x = 162.949, y = 8.0, z = 156.08, rot = 0, custom = true },
            { id = 0, x = -314.69, y = -0.349, z = 79.87, rot = 0, custom = true },
            { id = 0, x = 195.529, y = 7.949, z = -3.789, rot = 0, custom = true },
        } },
        [114] = { zoneName = 'Eastern_Altepa_Desert', points = {
            { id = 0, x = -258.0, y = 8.5, z = -263.0, rot = 128, custom = true },
        } },
        [116] = { zoneName = 'East_Sarutabaruta', points = {
            { id = 0, x = 260.2, y = -17.175, z = -444.6, rot = 128, custom = true },
        } },
        [117] = { zoneName = 'Tahrongi_Canyon', points = {
            { id = 0, x = -158.0, y = 47.0, z = 650.0, rot = 192, custom = true },
        } },
        [118] = { zoneName = 'Buburimu_Peninsula', points = {
            { id = 0, x = -483.7, y = -32.0, z = 48.0, rot = 64, custom = true },
        } },
        [119] = { zoneName = 'Meriphataud_Mountains', points = {
            { id = 0, x = -295.0, y = 16.852, z = 425.0, rot = 224, custom = true },
        } },
        [120] = { zoneName = 'Sauromugue_Champaign', points = {
            { id = 0, x = 346.0, y = 5.659, z = -254.0, rot = 96, custom = true },
        } },
        [121] = { zoneName = 'The_Sanctuary_of_ZiTah', points = {
            { id = 17273424, x = 432.84, y = 0.16, z = -480.49, rot = 0 },
            { id = 17273425, x = 443.42, y = 0.0, z = -37.28, rot = 0 },
            { id = 17273426, x = 399.63, y = 0.16, z = -272.72, rot = 0 },
        } },
        [122] = { zoneName = 'RoMaeve', points = {
            { id = 17277235, x = 47.23, y = -2.0, z = -92.31, rot = 0 },
        } },
        [123] = { zoneName = 'Yuhtunga_Jungle', points = {
            { id = 17281662, x = -401.75, y = 16.25, z = -415.05, rot = 0 },
            { id = 17281663, x = -403.0, y = 0.0, z = -192.0, rot = 0 },
        } },
        [124] = { zoneName = 'Yhoator_Jungle', points = {
            { id = 17285708, x = 34.16, y = -0.12, z = 124.75, rot = 0 },
        } },
        [125] = { zoneName = 'Western_Altepa_Desert', points = {
            { id = 17289805, x = -394.34, y = -0.33, z = -517.91, rot = 0 },
            { id = 17289806, x = -519.22, y = 0.0, z = -79.73, rot = 0 },
            { id = 17289807, x = 148.51, y = 0.39, z = 251.42, rot = 0 },
        } },
        [126] = { zoneName = 'Qufim_Island', points = {
            { id = 17293791, x = 140.3, y = -20.96, z = 23.19, rot = 0 },
            { id = 17293792, x = -160.0, y = -20.0, z = 77.0, rot = 0 },
            { id = 17293793, x = -121.75, y = -19.19, z = 216.29, rot = 0 },
        } },
        [127] = { zoneName = 'Behemoths_Dominion', points = {
            { id = 17297497, x = -247.29, y = -19.95, z = 32.4, rot = 0 },
            { id = 17297499, x = 161.26, y = 4.0, z = -85.59, rot = 0 },
        } },
        [128] = { zoneName = 'Valley_of_Sorrows', points = {
            { id = 17301599, x = -45.67, y = -0.21, z = 3.48, rot = 0 },
            { id = 17301600, x = -126.85, y = -0.23, z = -42.62, rot = 0 },
            { id = 17301601, x = -66.35, y = 0.06, z = -50.4, rot = 0 },
        } },
        [153] = { zoneName = 'The_Boyahda_Tree', points = {
            { id = 17404425, x = 50.86, y = -18.21, z = -154.58, rot = 0 },
        } },
        [159] = { zoneName = 'Temple_of_Uggalepih', points = {
            { id = 0, x = 225.75, y = 0.039, z = -25.0, rot = 0, custom = true },
            { id = 17429037, x = -97.17, y = -0.1, z = -59.7, rot = 0 },
        } },
        [160] = { zoneName = 'Den_of_Rancor', points = {
            { id = 17433102, x = 37.51, y = 36.0, z = -85.85, rot = 0 },
            { id = 17433103, x = 29.23, y = 36.0, z = -191.74, rot = 0 },
            { id = 17433104, x = -5.09, y = 36.13, z = -364.3, rot = 0 },
        } },
        [167] = { zoneName = 'Bostaunieux_Oubliette', points = {
            { id = 17461595, x = -223.05, y = -0.04, z = -98.28, rot = 0 },
        } },
        [174] = { zoneName = 'Kuftal_Tunnel', points = {
            { id = 17490332, x = 40.01, y = 0.1, z = 166.52, rot = 0 },
        } },
        [176] = { zoneName = 'Sea_Serpent_Grotto', points = {
            { id = 0, x = 225.0, y = -24.0, z = 337.0, rot = 128, custom = true },
        } },
        [200] = { zoneName = 'Garlaige_Citadel', points = {
            { id = 17596876, x = -167.89, y = 19.25, z = 321.51, rot = 0 },
            { id = 0, x = -361.3, y = 19.0, z = 283.13, rot = 0, custom = true },
            { id = 17596878, x = -260.17, y = 19.35, z = 233.9, rot = 0 },
        } },
        [204] = { zoneName = 'FeiYin', points = {
            { id = 17613282, x = 44.25, y = -15.44, z = 150.36, rot = 0 },
            -- 17613283/17613284 removed 2026-07-17: stock npc_list junction
            -- ids that don't exist in this DB (GetNPCByID error every boot)
            -- and carried (0,0,0) placeholder coords anyway.
        } },
        [205] = { zoneName = 'Ifrits_Cauldron', points = {
            { id = 17617281, x = 7.38, y = 3.95, z = 232.4, rot = 0 },
            { id = 17617282, x = -110.83, y = 3.86, z = 110.96, rot = 0 },
        } },
        [208] = { zoneName = 'Quicksand_Caves', points = {
            { id = 17629791, x = 813.66, y = 1.94, z = -560.66, rot = 0 },
            { id = 17629793, x = 822.08, y = -8.0, z = -382.99, rot = 0 },
        } },
        [212] = { zoneName = 'Gustav_Tunnel', points = {
            { id = 0, x = 298.0, y = -40.7, z = 66.0, rot = 96, custom = true },
        } },
        [213] = { zoneName = 'Labyrinth_of_Onzozo', points = {
            -- Stock npc_list junction rows carried (0,0,0) placeholders; verified
            -- safe anchor from Jbae's !pos 2026-07-13. Single custom junction (same
            -- pattern as zone 212) -- the Board warp uses points[1] so this doubles
            -- as the warp target.
            { id = 0, x = 35.86, y = 10.0, z = -0.51, rot = 94, custom = true },
        } },
    },
}
