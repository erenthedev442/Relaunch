-- ============================================================================
-- Dynamis - Divergence (relaunch) -- Phase 1 slice: San d'Oria [D] (zone 294)
-- ----------------------------------------------------------------------------
-- Instanced 3-wave content built on the LSB instance framework (see
-- scripts/zones/Dynamis-San_dOria_[D]/instances/dynamis_san_doria_d.lua).
--
-- Reuses the AUTHENTIC Dynamis-San d'Oria (zone 185) Orc pools for fidelity:
--   3076 Overlords_Tombstone  (mid-boss statue)   3340 Reapertongue (Orc NM -> mega-boss)
--   3548 Serjeant_Tombstone   (time-extension statue)
--   4150/4151/4162 Vanguard.. (Wave 1 "Squadron")  4193/4172/4135 Vanguard.. (Wave 2 "Regiment")
--
-- mobid = 16777216 + (zoneid<<12) + groupid-slot ; zone 294 base = 17981440.
-- Coordinates are real zone-185 spawn points (same map geometry as 294 = valid navmesh).
--
-- IDEMPOTENT: safe to re-run every deploy (REPLACE / DELETE+INSERT, scoped to zone 294
-- and the custom 294xx droplist range). NOT a one-time migration.
-- HP/levels are first-pass values -- tune to the relaunch curve during playtest.
-- ============================================================================

-- Drop-rate helper vars (mirror sql/mob_droplist.sql)
SET @ALWAYS   = 1000;
SET @COMMON   = 150;
SET @UNCOMMON = 100;
SET @RARE     = 50;

-- ----------------------------------------------------------------------------
-- mob_groups  (groupid, poolid, zoneid, name, respawntime, spawntype, dropid, HP, MP, allegiance, content_tag)
--   spawntype 128 = scripted (instance spawns via SpawnMob); respawntime 0 = no auto-respawn.
-- ----------------------------------------------------------------------------
REPLACE INTO `mob_groups` VALUES (1, 3076, 294, 'Overseers_Tombstone', 0, 128, 29401, 35000, 1000, 0, NULL); -- Mid-boss
REPLACE INTO `mob_groups` VALUES (2, 4150, 294, 'SandoriaD_Squadron_A', 0, 128, 29402,  8000,    0, 0, NULL); -- Wave 1 trash
REPLACE INTO `mob_groups` VALUES (3, 4151, 294, 'SandoriaD_Squadron_B', 0, 128, 29402,  8000,    0, 0, NULL); -- Wave 1 trash
REPLACE INTO `mob_groups` VALUES (4, 4162, 294, 'SandoriaD_Squadron_C', 0, 128, 29402,  8000,    0, 0, NULL); -- Wave 1 trash
REPLACE INTO `mob_groups` VALUES (5, 3548, 294, 'SandoriaD_Statue',     0, 128,     0,  6000,    0, 0, NULL); -- Time-extension statue
REPLACE INTO `mob_groups` VALUES (6, 4193, 294, 'SandoriaD_Regiment_A', 0, 128, 29403, 11000,    0, 0, NULL); -- Wave 2 trash
REPLACE INTO `mob_groups` VALUES (7, 4172, 294, 'SandoriaD_Regiment_B', 0, 128, 29403, 11000,    0, 0, NULL); -- Wave 2 trash
REPLACE INTO `mob_groups` VALUES (8, 4135, 294, 'SandoriaD_Regiment_C', 0, 128, 29403, 11000,    0, 0, NULL); -- Wave 2 trash
REPLACE INTO `mob_groups` VALUES (9, 3340, 294, 'Halphas',             0, 128, 29404, 70000, 2000, 0, NULL); -- Mega-boss

-- ----------------------------------------------------------------------------
-- mob_spawn_points  (mobid, spawnslotid, mobname, polutils_name, groupid, minLevel, maxLevel, x, y, z, rot)
--   Each spawn = one unique mobid; groupid links back to mob_groups above.
--   Wave 1 clusters in the entrance courtyard (~0,-2,38); Wave 2 in the Vanguard field (~130,-1,95).
-- ----------------------------------------------------------------------------
-- Wave 1: Squadron trash
REPLACE INTO `mob_spawn_points` VALUES (17981441, 0, 'SandoriaD_Squadron_A', 'Orcish Squadron', 2, 95, 99,  -2.858, -2.398, 39.388,  27);
REPLACE INTO `mob_spawn_points` VALUES (17981442, 0, 'SandoriaD_Squadron_B', 'Orcish Squadron', 3, 95, 99,   3.551, -2.434, 39.609,  96);
REPLACE INTO `mob_spawn_points` VALUES (17981443, 0, 'SandoriaD_Squadron_C', 'Orcish Squadron', 4, 95, 99,  -2.618, -1.838, 36.580, 254);
REPLACE INTO `mob_spawn_points` VALUES (17981444, 0, 'SandoriaD_Squadron_A', 'Orcish Squadron', 2, 95, 99,   8.000, -2.000, 44.000, 128);
-- Wave 1: time-extension statues
REPLACE INTO `mob_spawn_points` VALUES (17981445, 0, 'SandoriaD_Statue', 'Corporal Tombstone', 5, 99, 99,  12.000, -2.000, 40.000, 128);
REPLACE INTO `mob_spawn_points` VALUES (17981446, 0, 'SandoriaD_Statue', 'Corporal Tombstone', 5, 99, 99, -12.000, -2.000, 40.000,  64);
-- Wave 1: mid-boss (deeper, Reapertongue spot)
REPLACE INTO `mob_spawn_points` VALUES (17981447, 0, 'Overseers_Tombstone', 'Overseer\'s Tombstone', 1, 99, 99, 109.854, -0.634, 76.595, 215);
-- Wave 2: Regiment trash (Vanguard field)
REPLACE INTO `mob_spawn_points` VALUES (17981448, 0, 'SandoriaD_Regiment_A', 'Orcish Regiment', 6, 97, 99, 141.604, -2.420, 108.763, 231);
REPLACE INTO `mob_spawn_points` VALUES (17981449, 0, 'SandoriaD_Regiment_B', 'Orcish Regiment', 7, 97, 99, 132.572, -2.509, 108.942, 157);
REPLACE INTO `mob_spawn_points` VALUES (17981450, 0, 'SandoriaD_Regiment_C', 'Orcish Regiment', 8, 97, 99, 144.495, -2.500, 106.451, 251);
REPLACE INTO `mob_spawn_points` VALUES (17981451, 0, 'SandoriaD_Regiment_A', 'Orcish Regiment', 6, 97, 99, 123.614, -0.500, 97.504, 149);
-- Wave 2: mega-boss Halphas (Vanguard's Avatar spot)
REPLACE INTO `mob_spawn_points` VALUES (17981452, 0, 'Halphas', 'Halphas', 9, 99, 99, 131.470, -0.499, 84.582, 248);

-- ----------------------------------------------------------------------------
-- instance_list  (instanceid, name, instance_zone, entrance_zone, time_limit_min, x, y, z, rot, music_day, music_night, battlesolo, battlemulti)
--   29400 = 294*100. entrance_zone 230 = Southern San d'Oria. 60-min base limit.
--   Entry pos = southern staging area (validated zone-185 coord); player advances north.
-- ----------------------------------------------------------------------------
REPLACE INTO `instance_list` VALUES (29400, 'dynamis_san_doria_d', 294, 230, 60, 161.838, -2.000, 161.673, 93, NULL, NULL, NULL, NULL);

-- ----------------------------------------------------------------------------
-- instance_entities  (instanceid, mobid) -- pre-load every mob into instance 29400
-- ----------------------------------------------------------------------------
REPLACE INTO `instance_entities` VALUES (29400, 17981441);
REPLACE INTO `instance_entities` VALUES (29400, 17981442);
REPLACE INTO `instance_entities` VALUES (29400, 17981443);
REPLACE INTO `instance_entities` VALUES (29400, 17981444);
REPLACE INTO `instance_entities` VALUES (29400, 17981445);
REPLACE INTO `instance_entities` VALUES (29400, 17981446);
REPLACE INTO `instance_entities` VALUES (29400, 17981447);
REPLACE INTO `instance_entities` VALUES (29400, 17981448);
REPLACE INTO `instance_entities` VALUES (29400, 17981449);
REPLACE INTO `instance_entities` VALUES (29400, 17981450);
REPLACE INTO `instance_entities` VALUES (29400, 17981451);
REPLACE INTO `instance_entities` VALUES (29400, 17981452);

-- ----------------------------------------------------------------------------
-- mob_droplist  (dropId, dropType, groupId, groupRate, itemId, itemRate)
--   Currency: 9539 Beastmen's Medal (W1), 9541 Kindred's Medal (W2), 9543 Demon's Medal (mega-boss).
--   dropType 0 = normal. Custom dropIds 29401-29404 (rebuilt each run for idempotency).
-- ----------------------------------------------------------------------------
DELETE FROM `mob_droplist` WHERE `dropId` IN (29401, 29402, 29403, 29404);
-- 29401 mid-boss: guaranteed Beastmen's Medal + a chance at a second
INSERT INTO `mob_droplist` VALUES (29401, 0, 0, 1000, 9539, @ALWAYS);
INSERT INTO `mob_droplist` VALUES (29401, 0, 0, 1000, 9539, @COMMON);
-- 29402 Wave 1 trash: occasional Beastmen's Medal
INSERT INTO `mob_droplist` VALUES (29402, 0, 0, 1000, 9539, @UNCOMMON);
-- 29403 Wave 2 trash: occasional Kindred's Medal
INSERT INTO `mob_droplist` VALUES (29403, 0, 0, 1000, 9541, @UNCOMMON);
-- 29404 mega-boss Halphas: guaranteed Kindred's Medal (+chance of a 2nd) + chance of a Demon's Medal
INSERT INTO `mob_droplist` VALUES (29404, 0, 0, 1000, 9541, @ALWAYS);
INSERT INTO `mob_droplist` VALUES (29404, 0, 0, 1000, 9541, @COMMON);
INSERT INTO `mob_droplist` VALUES (29404, 0, 0, 1000, 9543, @UNCOMMON);
