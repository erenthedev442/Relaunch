-----------------------------------
-- survival_guide_npc_catalog.lua  (GENERATED from
-- scripts/globals/teleports/survival_guide_map.lua -- the retail Survival
-- Guide destination list, all 98 guide spots, grouped by region for the
-- customMenu. Labels are pre-shortened for the ~150-byte menu packet cap.)
--
-- Consumed by survival_guide_npc.lua (the warp book NPC).
-----------------------------------
local catalog = {}

catalog.zoneId    = xi.zone.ABDHALJS_ISLE_PURGONORGO
catalog.zonePath  = 'xi.zones.Abdhaljs_Isle-Purgonorgo'
catalog.npcPos    = { x = 560.971, y = -3.360, z = 514.586, rot = 64 }  -- 2026-07-06 moved off the Sage/Moogle row to beside the Leafallia homepoint (hp at 5.539,-0.434,8.133); !pos-verify after restart
catalog.npcName   = 'Survival_Guide'
catalog.packet    = 'Survival Guide'
-- Retail Survival Guide book model (npc_list look 0x0981 = 2433). If it
-- renders invisible as a dynamic entity, swap to a humanoid look (3000).
catalog.npcLook   = 2433
catalog.warpCost  = 1000   -- gil per warp (retail guides charge 1,000)

catalog.regions =
{
    {
        label = 'Quon: San d\'Oria',
        destinations =
        {
            { label = 'West Ronfaure',         zone = xi.zone.WEST_RONFAURE, x = -451.40, y = -19.75, z = -218.00, r = 128 },
            { label = 'La Theine Plateau',     zone = xi.zone.LA_THEINE_PLATEAU, x = 774.35, y = 29.00, z = -18.57, r = 224 },
            { label = 'Valkurm Dunes',         zone = xi.zone.VALKURM_DUNES, x = 137.90, y = -7.50, z = 97.00, r = 162 },
            { label = 'Jugner Forest',         zone = xi.zone.JUGNER_FOREST, x = 62.99, y = 0.00, z = -12.75, r = 65 },
            { label = 'Batallia Downs',        zone = xi.zone.BATALLIA_DOWNS, x = -67.00, y = -1.70, z = 448.25, r = 192 },
            { label = 'Davoi',                 zone = xi.zone.DAVOI, x = 221.75, y = -1.00, z = -10.00, r = 0 },
            { label = 'Fort Ghelsba',          zone = xi.zone.FORT_GHELSBA, x = -142.24, y = -19.93, z = 7.75, r = 96 },
            { label = 'Ordelles Caves',        zone = xi.zone.ORDELLES_CAVES, x = -102.91, y = 0.10, z = 632.90, r = 128 },
            { label = 'Ranperre\'s Tomb',      zone = xi.zone.KING_RANPERRES_TOMB, x = -120.23, y = 0.00, z = 248.57, r = 0 },
            { label = 'Bostaunieux',           zone = xi.zone.BOSTAUNIEUX_OUBLIETTE, x = -12.88, y = 0.10, z = 25.45, r = 0 },
            { label = 'Eldieme Necro.',        zone = xi.zone.THE_ELDIEME_NECROPOLIS, x = 419.21, y = -52.25, z = -99.50, r = 128 },
            { label = 'N. San d\'Oria',        zone = xi.zone.NORTHERN_SAN_DORIA, x = -175.21, y = -4.00, z = 80.00, r = 0 },
            { label = 'Carpenters\' Land.',    zone = xi.zone.CARPENTERS_LANDING, x = 224.99, y = -2.00, z = -529.26, r = 192 },
        },
    },
    {
        label = 'Quon: Bastok',
        destinations =
        {
            { label = 'Bastok Mines',          zone = xi.zone.BASTOK_MINES, x = 18.82, y = 0.00, z = -115.00, r = 0 },
            { label = 'North Gustaberg',       zone = xi.zone.NORTH_GUSTABERG, x = -581.84, y = 40.00, z = 53.14, r = 96 },
            { label = 'Konschtat',             zone = xi.zone.KONSCHTAT_HIGHLANDS, x = -223.00, y = 71.07, z = 828.00, r = 32 },
            { label = 'Pashhow Marsh.',        zone = xi.zone.PASHHOW_MARSHLANDS, x = 466.06, y = 24.00, z = 410.91, r = 32 },
            { label = 'Rolanberry',            zone = xi.zone.ROLANBERRY_FIELDS, x = -227.97, y = 4.54, z = 386.94, r = 64 },
            { label = 'Dangruf Wadi',          zone = xi.zone.DANGRUF_WADI, x = -23.16, y = 0.35, z = 0.15, r = 160 },
            { label = 'Gusgen Mines',          zone = xi.zone.GUSGEN_MINES, x = 59.91, y = -67.93, z = -267.18, r = 192 },
            { label = 'Zeruhn Mines',          zone = xi.zone.ZERUHN_MINES, x = -10.05, y = 0.00, z = 5.81, r = 192 },
            { label = 'Korroloka Tunnel',      zone = xi.zone.KORROLOKA_TUNNEL, x = -463.82, y = -10.08, z = -22.20, r = 32 },
            { label = 'Beadeaux',              zone = xi.zone.BEADEAUX, x = -263.99, y = 1.59, z = 105.86, r = 192 },
            { label = 'Crawlers\' Nest',       zone = xi.zone.CRAWLERS_NEST, x = 364.00, y = -32.20, z = -22.03, r = 64 },
            { label = 'Gustav Tunnel',         zone = xi.zone.GUSTAV_TUNNEL, x = 296.68, y = -40.42, z = 64.68, r = 96 },
        },
    },
    {
        label = 'Mindartia: Windurst',
        destinations =
        {
            { label = 'Port Windurst',         zone = xi.zone.PORT_WINDURST, x = -220.00, y = -8.09, z = 180.15, r = 64 },
            { label = 'W. Sarutabaruta',       zone = xi.zone.WEST_SARUTABARUTA, x = -14.75, y = -12.00, z = 315.75, r = 0 },
            { label = 'Tahrongi Canyon',       zone = xi.zone.TAHRONGI_CANYON, x = -160.00, y = 47.25, z = 647.11, r = 192 },
            { label = 'Buburimu Peninsula',    zone = xi.zone.BUBURIMU_PENINSULA, x = -485.74, y = -32.00, z = 47.32, r = 64 },
            { label = 'Meriphataud Mtns.',     zone = xi.zone.MERIPHATAUD_MOUNTAINS, x = -297.76, y = 17.00, z = 422.22, r = 224 },
            { label = 'Sauromugue Champ.',     zone = xi.zone.SAUROMUGUE_CHAMPAIGN, x = 344.83, y = 6.22, z = -255.30, r = 96 },
            { label = 'Inner Horutoto',        zone = xi.zone.INNER_HORUTOTO_RUINS, x = 452.94, y = -8.00, z = 181.07, r = 192 },
            { label = 'Shakhrami',             zone = xi.zone.MAZE_OF_SHAKHRAMI, x = -338.99, y = -12.21, z = -179.00, r = 0 },
            { label = 'Garlaige',              zone = xi.zone.GARLAIGE_CITADEL, x = -381.75, y = -6.00, z = 363.50, r = 128 },
            { label = 'Castle Oztroja',        zone = xi.zone.CASTLE_OZTROJA, x = -221.00, y = 0.25, z = -14.25, r = 192 },
            { label = 'Lab. of Onzozo',        zone = xi.zone.LABYRINTH_OF_ONZOZO, x = -62.30, y = -20.10, z = -280.69, r = 160 },
            { label = 'Toraimarai Canal',      zone = xi.zone.TORAIMARAI_CANAL, x = -308.25, y = 15.00, z = 260.78, r = 192 },
        },
    },
    {
        label = 'Jeuno & the North',
        destinations =
        {
            { label = 'Ru\'Lude Gardens',      zone = xi.zone.RULUDE_GARDENS, x = 44.25, y = 10.00, z = -69.00, r = 128 },
            { label = 'Qufim Island',          zone = xi.zone.QUFIM_ISLAND, x = -251.98, y = -19.96, z = 298.21, r = 64 },
            { label = 'Lower Delkfutt\'s',     zone = xi.zone.LOWER_DELKFUTTS_TOWER, x = 462.73, y = 0.00, z = -51.00, r = 0 },
            { label = 'Behemoth\'s Dom.',      zone = xi.zone.BEHEMOTHS_DOMINION, x = 337.41, y = 26.63, z = -73.95, r = 128 },
            { label = 'Beaucedine',            zone = xi.zone.BEAUCEDINE_GLACIER, x = -28.92, y = -59.00, z = -124.07, r = 32 },
            { label = 'Xarcabard',             zone = xi.zone.XARCABARD, x = 203.98, y = -24.27, z = -204.31, r = 192 },
            { label = 'Zvahl Baileys',         zone = xi.zone.CASTLE_ZVAHL_BAILEYS, x = 372.00, y = -12.05, z = -23.85, r = 64 },
            { label = 'Ranguemont Pass',       zone = xi.zone.RANGUEMONT_PASS, x = -145.24, y = 4.37, z = -298.79, r = 160 },
        },
    },
    {
        label = 'Outlands: South',
        destinations =
        {
            { label = 'Rabao',                 zone = xi.zone.RABAO, x = -3.41, y = -2.70, z = -93.60, r = 64 },
            { label = 'E. Altepa Desert',      zone = xi.zone.EASTERN_ALTEPA_DESERT, x = -258.88, y = 8.60, z = -265.00, r = 128 },
            { label = 'W. Altepa Desert',      zone = xi.zone.WESTERN_ALTEPA_DESERT, x = 419.33, y = -3.12, z = 11.68, r = 32 },
            { label = 'Cape Teriggan',         zone = xi.zone.CAPE_TERIGGAN, x = -186.67, y = 7.90, z = -67.00, r = 128 },
            { label = 'Valley Of Sorrows',     zone = xi.zone.VALLEY_OF_SORROWS, x = -163.30, y = -8.29, z = 23.04, r = 0 },
            { label = 'Kuftal Tunnel',         zone = xi.zone.KUFTAL_TUNNEL, x = -16.84, y = -20.47, z = -237.00, r = 0 },
            { label = 'Kazham',                zone = xi.zone.KAZHAM, x = -41.21, y = -10.00, z = -93.00, r = 0 },
            { label = 'Yuhtunga Jungle',       zone = xi.zone.YUHTUNGA_JUNGLE, x = -239.51, y = 0.00, z = -402.77, r = 64 },
            { label = 'Yhoator Jungle',        zone = xi.zone.YHOATOR_JUNGLE, x = 197.82, y = 0.00, z = -81.82, r = 160 },
            { label = 'Ifrit\'s Cauldron',     zone = xi.zone.IFRITS_CAULDRON, x = 89.00, y = 0.32, z = -298.11, r = 192 },
            { label = 'Uggalepih Temple',      zone = xi.zone.TEMPLE_OF_UGGALEPIH, x = 60.01, y = -8.00, z = 58.19, r = 64 },
            { label = 'Sea Serpent Grotto',    zone = xi.zone.SEA_SERPENT_GROTTO, x = 223.97, y = -23.71, z = 334.99, r = 128 },
            { label = 'Norg',                  zone = xi.zone.NORG, x = -13.84, y = 1.10, z = -33.14, r = 32 },
        },
    },
    {
        label = 'Outlands: East/Sky',
        destinations =
        {
            { label = 'Zi\'Tah Sanctuary',     zone = xi.zone.THE_SANCTUARY_OF_ZITAH, x = -44.98, y = 0.27, z = -149.86, r = 64 },
            { label = 'Ro\'Maeve',             zone = xi.zone.ROMAEVE, x = 13.75, y = -28.25, z = 54.04, r = 32 },
            { label = 'Ru\'Aun Gardens',       zone = xi.zone.RUAUN_GARDENS, x = 12.99, y = -54.16, z = -594.21, r = 192 },
            { label = 'Dragon\'s Aery',        zone = xi.zone.DRAGONS_AERY, x = -60.33, y = -1.17, z = -33.69, r = 160 },
            { label = 'Bibiki Bay',            zone = xi.zone.BIBIKI_BAY, x = 493.72, y = -3.04, z = 728.05, r = 0 },
            { label = 'Oldton Movalpolos',     zone = xi.zone.OLDTON_MOVALPOLOS, x = -260.78, y = 8.00, z = -54.00, r = 128 },
        },
    },
    {
        label = 'Tavnazia',
        destinations =
        {
            { label = 'Lufaise Meadows',       zone = xi.zone.LUFAISE_MEADOWS, x = -554.00, y = -6.20, z = -57.11, r = 192 },
            { label = 'Misareaux Coast',       zone = xi.zone.MISAREAUX_COAST, x = -60.98, y = -29.96, z = 262.22, r = 64 },
            { label = 'Phomiuna Aqueducts',    zone = xi.zone.PHOMIUNA_AQUEDUCTS, x = 253.18, y = 0.00, z = -266.02, r = 128 },
            { label = 'Sacrarium',             zone = xi.zone.SACRARIUM, x = -219.99, y = -12.00, z = 58.27, r = 64 },
            { label = 'Tavnazian Safehold',    zone = xi.zone.TAVNAZIAN_SAFEHOLD, x = -4.99, y = -28.08, z = 103.10, r = 64 },
        },
    },
    {
        label = 'Near East (ToAU)',
        destinations =
        {
            { label = 'Whitegate',             zone = xi.zone.AHT_URHGAN_WHITEGATE, x = 133.13, y = 0.00, z = 16.17, r = 224 },
            { label = 'Wajaom Woodlands',      zone = xi.zone.WAJAOM_WOODLANDS, x = -838.97, y = -20.00, z = 99.19, r = 64 },
            { label = 'Mamook',                zone = xi.zone.MAMOOK, x = 217.16, y = -23.84, z = -103.14, r = 32 },
            { label = 'Halvung',               zone = xi.zone.HALVUNG, x = 503.23, y = -0.17, z = 241.76, r = 32 },
            { label = 'Arrapago Reef',         zone = xi.zone.ARRAPAGO_REEF, x = 475.97, y = -15.64, z = -20.00, r = 128 },
            { label = 'Caedarva Mire',         zone = xi.zone.CAEDARVA_MIRE, x = -660.00, y = -13.36, z = 342.78, r = 64 },
            { label = 'Aydeewa',               zone = xi.zone.AYDEEWA_SUBTERRANE, x = 5.00, y = 20.67, z = -89.98, r = 128 },
            { label = 'Nashmau',               zone = xi.zone.NASHMAU, x = -18.80, y = 0.00, z = -33.01, r = 128 },
        },
    },
    {
        label = 'Past: Quon (S)',
        destinations =
        {
            { label = 'East Ronfaure (S)',     zone = xi.zone.EAST_RONFAURE_S, x = 662.02, y = -18.96, z = -595.91, r = 64 },
            { label = 'Jugner Forest (S)',     zone = xi.zone.JUGNER_FOREST_S, x = -193.97, y = -7.75, z = -493.80, r = 64 },
            { label = 'Batallia Downs (S)',    zone = xi.zone.BATALLIA_DOWNS_S, x = -404.00, y = -16.02, z = -164.28, r = 192 },
            { label = 'S. San d\'Oria (S)',    zone = xi.zone.SOUTHERN_SAN_DORIA_S, x = 82.02, y = 1.00, z = -66.79, r = 64 },
            { label = 'North Gustaberg (S)',   zone = xi.zone.NORTH_GUSTABERG_S, x = -289.00, y = 38.64, z = 531.99, r = 192 },
            { label = 'Pashhow Marsh. (S)',    zone = xi.zone.PASHHOW_MARSHLANDS_S, x = 547.80, y = 25.00, z = -341.00, r = 0 },
            { label = 'Rolanberry (S)',        zone = xi.zone.ROLANBERRY_FIELDS_S, x = -38.00, y = 0.50, z = -866.97, r = 224 },
            { label = 'Bastok Markets (S)',    zone = xi.zone.BASTOK_MARKETS_S, x = -246.17, y = 0.00, z = 94.13, r = 160 },
            { label = 'Grauberg (S)',          zone = xi.zone.GRAUBERG_S, x = 794.00, y = 71.48, z = 773.16, r = 64 },
            { label = 'Vunkerl Inlet (S)',     zone = xi.zone.VUNKERL_INLET_S, x = -521.01, y = -32.36, z = 205.91, r = 192 },
        },
    },
    {
        label = 'Past: Mindartia (S)',
        destinations =
        {
            { label = 'W. Sarutabaruta (S)',   zone = xi.zone.WEST_SARUTABARUTA_S, x = 83.00, y = -24.65, z = 566.09, r = 192 },
            { label = 'Windurst Waters (S)',   zone = xi.zone.WINDURST_WATERS_S, x = -57.08, y = -5.71, z = 215.99, r = 128 },
            { label = 'Meriphataud Mtns. (S)', zone = xi.zone.MERIPHATAUD_MOUNTAINS_S, x = 732.90, y = -33.50, z = -10.00, r = 0 },
            { label = 'Sauromugue Champ. (S)', zone = xi.zone.SAUROMUGUE_CHAMPAIGN_S, x = 475.97, y = -8.04, z = -438.29, r = 192 },
            { label = 'Karugo-Narugo (S)',     zone = xi.zone.FORT_KARUGO_NARUGO_S, x = 125.37, y = -20.91, z = 605.38, r = 224 },
            { label = 'Beaucedine (S)',        zone = xi.zone.BEAUCEDINE_GLACIER_S, x = -144.01, y = -80.13, z = 232.59, r = 192 },
            { label = 'Zvahl Baileys (S)',     zone = xi.zone.CASTLE_ZVAHL_BAILEYS_S, x = 372.00, y = -12.05, z = -23.78, r = 64 },
            { label = 'Crawlers\' Nest (S)',   zone = xi.zone.CRAWLERS_NEST_S, x = 363.99, y = -32.20, z = -22.07, r = 64 },
            { label = 'Garlaige (S)',          zone = xi.zone.GARLAIGE_CITADEL_S, x = -301.80, y = -6.08, z = 127.37, r = 128 },
            { label = 'Eldieme Necro. (S)',    zone = xi.zone.THE_ELDIEME_NECROPOLIS_S, x = 419.29, y = -52.25, z = -99.41, r = 128 },
        },
    },
    {
        label = 'Adoulin',
        destinations =
        {
            { label = 'Eastern Adoulin',       zone = xi.zone.EASTERN_ADOULIN, x = -53.50, y = 0.15, z = -116.93, r = 64 },
        },
    },
}

return catalog
