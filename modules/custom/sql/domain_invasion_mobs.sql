-- Domain Invasion mob_groups (zone 210 = GM_Home, used as groupZoneId)
-- Pool refs: 894=Dahak, 5699=Azi_Dahaka, 2325=Lamia_Bowyer, 5634=Naga_Raja
-- Columns: groupid, poolid, zoneid, name, respawntime, spawntype, dropid, HP, MP, allegiance, content_tag
-- These IDs are spawned dynamically by domain_invasion.lua; the DB rows
-- only supply the model / skeleton.  Stats (HP, mods, level) are overridden
-- entirely in Lua, so the DB values for HP/MP are 0 (unused).
DELETE FROM mob_groups WHERE groupid BETWEEN 11480 AND 11483 AND zoneid = 210;
INSERT INTO `mob_groups` VALUES
    (11480, 894,  210, 'Escha_Dahak', 0, 128, 0, 0, 0, 0, NULL),
    (11481, 5699, 210, 'Azi_Dahaka',  0, 128, 0, 0, 0, 0, NULL),
    (11482, 2325, 210, 'Escha_Lamia', 0, 128, 0, 0, 0, 0, NULL),
    (11483, 5634, 210, 'Naga_Raja',   0, 128, 0, 0, 0, 0, NULL);
