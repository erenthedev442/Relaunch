-----------------------------------
-- huntnm_warp_table.lua
-- One row per NM listed at https://www.ffxi-legendary.com/progression/hunters-guild/
-- (source: modules/custom/lua/hunters_guild_catalog.lua huntTargets). Used by
-- the !huntwarp command to drop the player near each NM's stock spawn point.
--
-- Coord source: sql/mob_spawn_points.sql resolved by (mob name, zone id).
-- Capricornus is a lottery-placeholder NM (stock row is 1/1/1); manual coord
-- below is the F-10 spawn area in Jugner Forest per bg-wiki.
-----------------------------------
return {
    -- AF Hunters' Guild -- Wyrm Circuit
    { key = 'tarasque',        label = 'Tarasque',           guild = 'AF',    tier = 1, zone = 205, zoneName = 'Ifrits Cauldron',        x =  118.000, y =  19.000, z =  163.000, rot = 250 },
    { key = 'capricornus',     label = 'Capricornus',        guild = 'AF',    tier = 2, zone = 104, zoneName = 'Jugner Forest',          x =  240.000, y =  -5.000, z =   40.000, rot = 128 },  -- lottery-placeholder NM; coord is F-10 spawn area
    { key = 'charybdis',       label = 'Charybdis',          guild = 'AF',    tier = 3, zone = 176, zoneName = 'Sea Serpent Grotto',     x = -152.000, y =  48.000, z = -328.000, rot = 127 },
    { key = 'tiamat',          label = 'Tiamat',             guild = 'AF',    tier = 4, zone =   7, zoneName = 'Attohwa Chasm',          x = -529.519, y =  -5.811, z =  -43.413, rot = 233 },
    { key = 'fafnir',          label = 'Fafnir',             guild = 'AF',    tier = 5, zone = 154, zoneName = "Dragon's Aery",          x =   78.000, y =   6.000, z =   39.000, rot = 127 },

    -- Relic Hunters' Guild -- TOAU / Desert Beasts
    { key = 'cactrot_rapido',  label = 'Cactrot Rapido',     guild = 'Relic', tier = 1, zone = 114, zoneName = 'Eastern Altepa Desert',  x =  -43.733, y =   0.029, z = -205.890, rot =  66 },
    { key = 'lord_of_onzozo',  label = 'Lord of Onzozo',     guild = 'Relic', tier = 2, zone = 213, zoneName = 'Labyrinth of Onzozo',    x =  -44.000, y =  14.000, z =  -58.000, rot =  73 },
    { key = 'king_vinegarroon',label = 'King Vinegarroon',   guild = 'Relic', tier = 3, zone = 125, zoneName = 'Western Altepa Desert',  x = -239.000, y =  -0.226, z = -650.000, rot =  11 },
    { key = 'khimaira',        label = 'Khimaira',           guild = 'Relic', tier = 4, zone =  79, zoneName = 'Caedarva Mire',          x =  603.887, y = -16.140, z =  414.765, rot = 255 },
    { key = 'cerberus',        label = 'Cerberus',           guild = 'Relic', tier = 5, zone =  61, zoneName = 'Mount Zhayolm',          x =  316.000, y = -23.000, z =  -84.000, rot = 127 },

    -- Empyrean Hunters' Guild -- Sky Court
    { key = 'faust',           label = 'Faust',              guild = 'Empy',  tier = 1, zone = 178, zoneName = 'The Shrine of Ru\'Avitau', x = 740.000, y =  -0.463, z =  -99.000, rot = 192 },
    { key = 'despot',          label = 'Despot',             guild = 'Empy',  tier = 2, zone = 130, zoneName = "Ru'Aun Gardens",         x =   -0.100, y = -42.000, z = -291.000, rot = 114 },
    { key = 'steam_cleaner',   label = 'Steam Cleaner',      guild = 'Empy',  tier = 3, zone = 177, zoneName = "Ve'Lugannon Palace",     x =  317.000, y =  -1.000, z =  361.000, rot =  65 },
    { key = 'brigandish_blade',label = 'Brigandish Blade',   guild = 'Empy',  tier = 4, zone = 177, zoneName = "Ve'Lugannon Palace",     x =   -1.000, y =  -1.000, z = -283.000, rot =  63 },
    { key = 'bahamut',         label = 'Bahamut',            guild = 'Empy',  tier = 5, zone =  29, zoneName = 'Riverne - Site #B01',    x = -706.661, y =   0.405, z =  820.898, rot =   3 },

    -- League Hunters' Guild -- Apex World Bosses
    { key = 'bune',            label = 'Bune',               guild = 'HL',    tier = 1, zone = 212, zoneName = 'Gustav Tunnel',          x =  -72.000, y = -10.000, z = -170.000, rot = 119 },
    { key = 'carmine_dobsonfly',label= 'Carmine Dobsonfly',  guild = 'HL',    tier = 2, zone =  30, zoneName = 'Riverne - Site #A01',    x = -199.488, y =  47.865, z = -846.699, rot =  25 },
    { key = 'jormungand',      label = 'Jormungand',         guild = 'HL',    tier = 5, zone =   5, zoneName = 'Uleguerand Range',       x = -203.667, y =-176.028, z =  132.710, rot =  76 },
}
