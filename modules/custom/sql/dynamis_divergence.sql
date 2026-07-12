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
-- mobid = 16777216 + (zoneid<<12) + slot ; zone 294 base = 17981440.
-- MOBID CHOICE IS DISPLAY-DRIVEN: the client names fixed mobs from its zone DAT
-- by mob index and ignores server-side names, so every spawn below sits on the
-- stock mobid whose DAT name matches its role (Squadron_* wave 1, Corporal
-- Tombstone statues, Regiment_* wave 2, Halphas & co. on their retail indexes).
-- polutils_name mirrors that DAT name so the website tables match the game.
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
REPLACE INTO `mob_spawn_points` VALUES (17981448, 0, 'SandoriaD_Squadron_A', 'Squadron Knight', 2, 95, 99, -2.858, -2.398, 39.388, 27);
REPLACE INTO `mob_spawn_points` VALUES (17981449, 0, 'SandoriaD_Squadron_B', 'Squadron\'s Wyvern', 3, 95, 99, 3.551, -2.434, 39.609, 96);
REPLACE INTO `mob_spawn_points` VALUES (17981451, 0, 'SandoriaD_Squadron_C', 'Squadron Evoker', 4, 95, 99, -2.618, -1.838, 36.580, 254);
REPLACE INTO `mob_spawn_points` VALUES (17981470, 0, 'SandoriaD_Squadron_A', 'Squadron Knight', 2, 95, 99, 8.000, -2.000, 44.000, 128);
-- Wave 1: time-extension statues
REPLACE INTO `mob_spawn_points` VALUES (17981442, 0, 'SandoriaD_Statue', 'Corporal Tombstone', 5, 99, 99, 12.000, -2.000, 40.000, 128);
REPLACE INTO `mob_spawn_points` VALUES (17981447, 0, 'SandoriaD_Statue', 'Corporal Tombstone', 5, 99, 99, -12.000, -2.000, 40.000, 64);
-- Wave 1: mid-boss (deeper, Reapertongue spot)
REPLACE INTO `mob_spawn_points` VALUES (17981770, 0, 'Overseers_Tombstone', 'Overseer\'s Tombstone', 1, 99, 99, 109.854, -0.634, 76.595, 215);
-- Wave 2: Regiment trash (Vanguard field)
REPLACE INTO `mob_spawn_points` VALUES (17981800, 0, 'SandoriaD_Regiment_A', 'Regiment Knight', 6, 97, 99, 141.604, -2.420, 108.763, 231);
REPLACE INTO `mob_spawn_points` VALUES (17981801, 0, 'SandoriaD_Regiment_B', 'Regiment\'s Wyvern', 7, 97, 99, 132.572, -2.509, 108.942, 157);
REPLACE INTO `mob_spawn_points` VALUES (17981793, 0, 'SandoriaD_Regiment_C', 'Regiment Evoker', 8, 97, 99, 144.495, -2.500, 106.451, 251);
REPLACE INTO `mob_spawn_points` VALUES (17981807, 0, 'SandoriaD_Regiment_A', 'Regiment Knight', 6, 97, 99, 123.614, -0.500, 97.504, 149);
-- Wave 2: mega-boss Halphas (Vanguard's Avatar spot)
REPLACE INTO `mob_spawn_points` VALUES (17982112, 0, 'Halphas', 'Halphas', 9, 99, 99, 131.470, -0.499, 84.582, 248);
-- Population pass (2026-07): waves 4->12 trash + 2->4 statues per zone. The
-- first-pass 12-mob roster cleared in ~10 min and made the 60+ext timer
-- pointless (player report 2026-07-10). New points interpolate the validated
-- clusters above (same courtyard / Vanguard-field envelopes).
-- Wave 1: Squadron reinforcements
REPLACE INTO `mob_spawn_points` VALUES (17981473, 0, 'SandoriaD_Squadron_A', 'Squadron Knight', 2, 95, 99, -8.000, -2.000, 42.000, 32);
REPLACE INTO `mob_spawn_points` VALUES (17981471, 0, 'SandoriaD_Squadron_B', 'Squadron\'s Wyvern', 3, 95, 99, 5.500, -2.200, 35.500, 190);
REPLACE INTO `mob_spawn_points` VALUES (17981472, 0, 'SandoriaD_Squadron_C', 'Squadron Evoker', 4, 95, 99, 0.500, -2.100, 42.500, 0);
REPLACE INTO `mob_spawn_points` VALUES (17981480, 0, 'SandoriaD_Squadron_A', 'Squadron Knight', 2, 95, 99, 9.500, -2.000, 39.500, 110);
REPLACE INTO `mob_spawn_points` VALUES (17981474, 0, 'SandoriaD_Squadron_B', 'Squadron\'s Wyvern', 3, 95, 99, -6.500, -2.000, 37.000, 60);
REPLACE INTO `mob_spawn_points` VALUES (17981475, 0, 'SandoriaD_Squadron_C', 'Squadron Evoker', 4, 95, 99, 3.000, -2.300, 43.000, 150);
REPLACE INTO `mob_spawn_points` VALUES (17981490, 0, 'SandoriaD_Squadron_A', 'Squadron Knight', 2, 95, 99, -4.500, -2.200, 44.500, 100);
REPLACE INTO `mob_spawn_points` VALUES (17981481, 0, 'SandoriaD_Squadron_B', 'Squadron\'s Wyvern', 3, 95, 99, 7.000, -2.100, 43.500, 220);
-- Wave 1: extra time-extension statues
REPLACE INTO `mob_spawn_points` VALUES (17981452, 0, 'SandoriaD_Statue', 'Corporal Tombstone', 5, 99, 99, 12.000, -2.000, 36.000, 160);
REPLACE INTO `mob_spawn_points` VALUES (17981457, 0, 'SandoriaD_Statue', 'Corporal Tombstone', 5, 99, 99, -12.000, -2.000, 36.000, 96);
-- Wave 2: Regiment reinforcements (Vanguard field)
REPLACE INTO `mob_spawn_points` VALUES (17981856, 0, 'SandoriaD_Regiment_A', 'Regiment Knight', 6, 97, 99, 137.000, -2.400, 107.500, 200);
REPLACE INTO `mob_spawn_points` VALUES (17981808, 0, 'SandoriaD_Regiment_B', 'Regiment\'s Wyvern', 7, 97, 99, 128.000, -2.000, 103.000, 130);
REPLACE INTO `mob_spawn_points` VALUES (17981794, 0, 'SandoriaD_Regiment_C', 'Regiment Evoker', 8, 97, 99, 140.000, -2.500, 103.500, 240);
REPLACE INTO `mob_spawn_points` VALUES (17981872, 0, 'SandoriaD_Regiment_A', 'Regiment Knight', 6, 97, 99, 133.500, -2.500, 106.000, 180);
REPLACE INTO `mob_spawn_points` VALUES (17981857, 0, 'SandoriaD_Regiment_B', 'Regiment\'s Wyvern', 7, 97, 99, 126.500, -1.500, 100.000, 140);
REPLACE INTO `mob_spawn_points` VALUES (17981854, 0, 'SandoriaD_Regiment_C', 'Regiment Evoker', 8, 97, 99, 143.000, -2.500, 108.500, 250);
REPLACE INTO `mob_spawn_points` VALUES (17981897, 0, 'SandoriaD_Regiment_A', 'Regiment Knight', 6, 97, 99, 130.000, -1.800, 106.500, 160);
REPLACE INTO `mob_spawn_points` VALUES (17981873, 0, 'SandoriaD_Regiment_B', 'Regiment\'s Wyvern', 7, 97, 99, 135.500, -2.300, 101.500, 90);

-- ----------------------------------------------------------------------------
-- instance_list  (instanceid, name, instance_zone, entrance_zone, time_limit_min, x, y, z, rot, music_day, music_night, battlesolo, battlemulti)
--   29400 = 294*100. entrance_zone 230 = Southern San d'Oria. 60-min base limit.
--   Entry pos = southern staging area (validated zone-185 coord); player advances north.
-- ----------------------------------------------------------------------------
REPLACE INTO `instance_list` VALUES (29400, 'dynamis_san_doria_d', 294, 230, 60, 161.838, -2.000, 161.673, 93, NULL, NULL, NULL, NULL);

-- ----------------------------------------------------------------------------
-- instance_entities  (instanceid, mobid) -- pre-load every mob into instance 29400
-- ----------------------------------------------------------------------------
DELETE FROM `instance_entities` WHERE `instanceid` = 29400; -- drop stale registrations (incl. previously-claimed mobids)
REPLACE INTO `instance_entities` VALUES (29400, 17981448);
REPLACE INTO `instance_entities` VALUES (29400, 17981449);
REPLACE INTO `instance_entities` VALUES (29400, 17981451);
REPLACE INTO `instance_entities` VALUES (29400, 17981470);
REPLACE INTO `instance_entities` VALUES (29400, 17981442);
REPLACE INTO `instance_entities` VALUES (29400, 17981447);
REPLACE INTO `instance_entities` VALUES (29400, 17981770);
REPLACE INTO `instance_entities` VALUES (29400, 17981800);
REPLACE INTO `instance_entities` VALUES (29400, 17981801);
REPLACE INTO `instance_entities` VALUES (29400, 17981793);
REPLACE INTO `instance_entities` VALUES (29400, 17981807);
REPLACE INTO `instance_entities` VALUES (29400, 17982112);
REPLACE INTO `instance_entities` VALUES (29400, 17981473);
REPLACE INTO `instance_entities` VALUES (29400, 17981471);
REPLACE INTO `instance_entities` VALUES (29400, 17981472);
REPLACE INTO `instance_entities` VALUES (29400, 17981480);
REPLACE INTO `instance_entities` VALUES (29400, 17981474);
REPLACE INTO `instance_entities` VALUES (29400, 17981475);
REPLACE INTO `instance_entities` VALUES (29400, 17981490);
REPLACE INTO `instance_entities` VALUES (29400, 17981481);
REPLACE INTO `instance_entities` VALUES (29400, 17981452);
REPLACE INTO `instance_entities` VALUES (29400, 17981457);
REPLACE INTO `instance_entities` VALUES (29400, 17981856);
REPLACE INTO `instance_entities` VALUES (29400, 17981808);
REPLACE INTO `instance_entities` VALUES (29400, 17981794);
REPLACE INTO `instance_entities` VALUES (29400, 17981872);
REPLACE INTO `instance_entities` VALUES (29400, 17981857);
REPLACE INTO `instance_entities` VALUES (29400, 17981854);
REPLACE INTO `instance_entities` VALUES (29400, 17981897);
REPLACE INTO `instance_entities` VALUES (29400, 17981873);

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

-- ============================================================================
-- Bastok [D] (zone 295, instance 29500) -- Quadav, unlocks HANDS. mobid base 17985536.
-- Reuses zone-186 Quadav pools; coords cluster the validated Gu'Dha Effigy anchor.
-- ============================================================================
REPLACE INTO `mob_groups` VALUES (1, 1855, 295, 'MushaEffigy_BastokD', 0, 128, 29501, 35000, 1000, 0, NULL);
REPLACE INTO `mob_groups` VALUES (2, 4197, 295, 'BastokD_Squadron_A',  0, 128, 29502,  8000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (3, 4163, 295, 'BastokD_Squadron_B',  0, 128, 29502,  8000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (4, 4139, 295, 'BastokD_Squadron_C',  0, 128, 29502,  8000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (5, 3548, 295, 'BastokD_Statue',      0, 128,     0,  6000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (6, 4177, 295, 'BastokD_Regiment_A',  0, 128, 29503, 11000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (7, 4178, 295, 'BastokD_Regiment_B',  0, 128, 29503, 11000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (8, 4191, 295, 'BastokD_Regiment_C',  0, 128, 29503, 11000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (9, 1859, 295, 'KaRhoFearsinger',     0, 128, 29504, 70000, 2000, 0, NULL);
REPLACE INTO `mob_spawn_points` VALUES (17985540, 0, 'BastokD_Squadron_A', 'Squadron Weaponmaster', 2, 95, 99, -12.5, -1.56, -118.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985543, 0, 'BastokD_Squadron_B', 'Squadron\'s Avatar', 3, 95, 99, -6.0, -1.56, -124.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985546, 0, 'BastokD_Squadron_C', 'Squadron Magician', 4, 95, 99, -19.0, -1.56, -124.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985557, 0, 'BastokD_Squadron_A', 'Squadron Weaponmaster', 2, 95, 99, -12.5, -1.56, -130.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985539, 0, 'BastokD_Statue', 'Lithicthrower Image', 5, 99, 99, -4.0, -1.56, -116.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985544, 0, 'BastokD_Statue', 'Lithicthrower Image', 5, 99, 99, -21.0, -1.56, -116.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985538, 0, 'MushaEffigy_BastokD', 'Mu\'Sha Effigy', 1, 99, 99, -12.509, -1.559, -124.363, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985897, 0, 'BastokD_Regiment_A', 'Regiment Weaponmaster', 6, 97, 99, -12.5, -1.56, -132.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985900, 0, 'BastokD_Regiment_B', 'Regiment\'s Avatar', 7, 97, 99, -6.0, -1.56, -130.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985902, 0, 'BastokD_Regiment_C', 'Regiment Magician', 8, 97, 99, -19.0, -1.56, -130.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985916, 0, 'BastokD_Regiment_A', 'Regiment Weaponmaster', 6, 97, 99, -12.5, -1.56, -136.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985895, 0, 'KaRhoFearsinger', 'Ka\'Rho Fearsinger', 9, 99, 99, -12.5, -1.56, -138.0, 56);
-- Population pass (2026-07): waves 4->12 trash + 2->4 statues (see zone 294 note).
REPLACE INTO `mob_spawn_points` VALUES (17985583, 0, 'BastokD_Squadron_A', 'Squadron Weaponmaster', 2, 95, 99, -9.0, -1.56, -120.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985564, 0, 'BastokD_Squadron_B', 'Squadron\'s Avatar', 3, 95, 99, -16.0, -1.56, -121.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985561, 0, 'BastokD_Squadron_C', 'Squadron Magician', 4, 95, 99, -9.5, -1.56, -127.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985611, 0, 'BastokD_Squadron_A', 'Squadron Weaponmaster', 2, 95, 99, -16.5, -1.56, -127.5, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985574, 0, 'BastokD_Squadron_B', 'Squadron\'s Avatar', 3, 95, 99, -12.5, -1.56, -121.5, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985586, 0, 'BastokD_Squadron_C', 'Squadron Magician', 4, 95, 99, -6.5, -1.56, -119.5, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985620, 0, 'BastokD_Squadron_A', 'Squadron Weaponmaster', 2, 95, 99, -19.5, -1.56, -119.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985596, 0, 'BastokD_Squadron_B', 'Squadron\'s Avatar', 3, 95, 99, -12.0, -1.56, -126.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985548, 0, 'BastokD_Statue', 'Lithicthrower Image', 5, 99, 99, -8.0, -1.56, -116.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985554, 0, 'BastokD_Statue', 'Lithicthrower Image', 5, 99, 99, -17.0, -1.56, -116.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985926, 0, 'BastokD_Regiment_A', 'Regiment Weaponmaster', 6, 97, 99, -9.0, -1.56, -133.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985928, 0, 'BastokD_Regiment_B', 'Regiment\'s Avatar', 7, 97, 99, -16.0, -1.56, -133.5, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985922, 0, 'BastokD_Regiment_C', 'Regiment Magician', 8, 97, 99, -12.5, -1.56, -134.5, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985933, 0, 'BastokD_Regiment_A', 'Regiment Weaponmaster', 6, 97, 99, -6.5, -1.56, -131.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985949, 0, 'BastokD_Regiment_B', 'Regiment\'s Avatar', 7, 97, 99, -19.0, -1.56, -131.5, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985944, 0, 'BastokD_Regiment_C', 'Regiment Magician', 8, 97, 99, -9.5, -1.56, -136.5, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985938, 0, 'BastokD_Regiment_A', 'Regiment Weaponmaster', 6, 97, 99, -15.5, -1.56, -137.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985971, 0, 'BastokD_Regiment_B', 'Regiment\'s Avatar', 7, 97, 99, -12.5, -1.56, -140.0, 56);
REPLACE INTO `instance_list` VALUES (29500, 'dynamis_bastok_d', 295, 234, 60, 116.482, 0.994, -72.121, 128, NULL, NULL, NULL, NULL);
DELETE FROM `instance_entities` WHERE `instanceid` = 29500; -- drop stale registrations (incl. previously-claimed mobids)
REPLACE INTO `instance_entities` VALUES (29500, 17985540);
REPLACE INTO `instance_entities` VALUES (29500, 17985543);
REPLACE INTO `instance_entities` VALUES (29500, 17985546);
REPLACE INTO `instance_entities` VALUES (29500, 17985557);
REPLACE INTO `instance_entities` VALUES (29500, 17985539);
REPLACE INTO `instance_entities` VALUES (29500, 17985544);
REPLACE INTO `instance_entities` VALUES (29500, 17985538);
REPLACE INTO `instance_entities` VALUES (29500, 17985897);
REPLACE INTO `instance_entities` VALUES (29500, 17985900);
REPLACE INTO `instance_entities` VALUES (29500, 17985902);
REPLACE INTO `instance_entities` VALUES (29500, 17985916);
REPLACE INTO `instance_entities` VALUES (29500, 17985895);
REPLACE INTO `instance_entities` VALUES (29500, 17985583);
REPLACE INTO `instance_entities` VALUES (29500, 17985564);
REPLACE INTO `instance_entities` VALUES (29500, 17985561);
REPLACE INTO `instance_entities` VALUES (29500, 17985611);
REPLACE INTO `instance_entities` VALUES (29500, 17985574);
REPLACE INTO `instance_entities` VALUES (29500, 17985586);
REPLACE INTO `instance_entities` VALUES (29500, 17985620);
REPLACE INTO `instance_entities` VALUES (29500, 17985596);
REPLACE INTO `instance_entities` VALUES (29500, 17985548);
REPLACE INTO `instance_entities` VALUES (29500, 17985554);
REPLACE INTO `instance_entities` VALUES (29500, 17985926);
REPLACE INTO `instance_entities` VALUES (29500, 17985928);
REPLACE INTO `instance_entities` VALUES (29500, 17985922);
REPLACE INTO `instance_entities` VALUES (29500, 17985933);
REPLACE INTO `instance_entities` VALUES (29500, 17985949);
REPLACE INTO `instance_entities` VALUES (29500, 17985944);
REPLACE INTO `instance_entities` VALUES (29500, 17985938);
REPLACE INTO `instance_entities` VALUES (29500, 17985971);
DELETE FROM `mob_droplist` WHERE `dropId` IN (29501, 29502, 29503, 29504);
INSERT INTO `mob_droplist` VALUES (29501, 0, 0, 1000, 9539, @ALWAYS);
INSERT INTO `mob_droplist` VALUES (29501, 0, 0, 1000, 9539, @COMMON);
INSERT INTO `mob_droplist` VALUES (29502, 0, 0, 1000, 9539, @UNCOMMON);
INSERT INTO `mob_droplist` VALUES (29503, 0, 0, 1000, 9541, @UNCOMMON);
INSERT INTO `mob_droplist` VALUES (29504, 0, 0, 1000, 9541, @ALWAYS);
INSERT INTO `mob_droplist` VALUES (29504, 0, 0, 1000, 9541, @COMMON);
INSERT INTO `mob_droplist` VALUES (29504, 0, 0, 1000, 9543, @UNCOMMON);

-- ============================================================================
-- Windurst [D] (zone 296, instance 29600) -- Yagudo, unlocks HEAD. mobid base 17989632.
-- Reuses zone-187 Yagudo pools; coords cluster the validated Tzee Xicu Idol anchor.
-- ============================================================================
REPLACE INTO `mob_groups` VALUES (1, 4070, 296, 'EvincingIdol_WindyD', 0, 128, 29601, 35000, 1000, 0, NULL);
REPLACE INTO `mob_groups` VALUES (2, 4183, 296, 'WindyD_Squadron_A',   0, 128, 29602,  8000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (3, 4176, 296, 'WindyD_Squadron_B',   0, 128, 29602,  8000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (4, 4175, 296, 'WindyD_Squadron_C',   0, 128, 29602,  8000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (5, 3548, 296, 'WindyD_Statue',       0, 128,     0,  6000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (6, 4181, 296, 'WindyD_Regiment_A',   0, 128, 29603, 11000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (7, 4198, 296, 'WindyD_Regiment_B',   0, 128, 29603, 11000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (8, 4141, 296, 'WindyD_Regiment_C',   0, 128, 29603, 11000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (9, 2464, 296, 'FiiPexuTheEternal',   0, 128, 29604, 70000, 2000, 0, NULL);
REPLACE INTO `mob_spawn_points` VALUES (17989636, 0, 'WindyD_Squadron_A', 'Squadron Hoplite', 2, 95, 99, 94.9, -3.17, -141.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989645, 0, 'WindyD_Squadron_B', 'Squadron\'s Wyvern', 3, 95, 99, 101.0, -3.17, -147.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989640, 0, 'WindyD_Squadron_C', 'Squadron Magian', 4, 95, 99, 88.0, -3.17, -147.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989665, 0, 'WindyD_Squadron_A', 'Squadron Hoplite', 2, 95, 99, 94.9, -3.17, -153.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989635, 0, 'WindyD_Statue', 'Incarnation Icon', 5, 99, 99, 103.0, -3.17, -140.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989641, 0, 'WindyD_Statue', 'Incarnation Icon', 5, 99, 99, 86.0, -3.17, -140.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989634, 0, 'EvincingIdol_WindyD', 'Evincing Idol', 1, 99, 99, 94.944, -3.171, -147.770, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989983, 0, 'WindyD_Regiment_A', 'Regiment Hoplite', 6, 97, 99, 94.9, -3.17, -155.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989994, 0, 'WindyD_Regiment_B', 'Regiment\'s Wyvern', 7, 97, 99, 101.0, -3.17, -153.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989988, 0, 'WindyD_Regiment_C', 'Regiment Magian', 8, 97, 99, 88.0, -3.17, -153.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17990001, 0, 'WindyD_Regiment_A', 'Regiment Hoplite', 6, 97, 99, 94.9, -3.17, -159.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989981, 0, 'FiiPexuTheEternal', 'Fii Pexu the Eternal', 9, 99, 99, 94.9, -3.17, -161.0, 64);
-- Population pass (2026-07): waves 4->12 trash + 2->4 statues (see zone 294 note).
REPLACE INTO `mob_spawn_points` VALUES (17989671, 0, 'WindyD_Squadron_A', 'Squadron Hoplite', 2, 95, 99, 91.0, -3.17, -143.5, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989668, 0, 'WindyD_Squadron_B', 'Squadron\'s Wyvern', 3, 95, 99, 98.5, -3.17, -143.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989661, 0, 'WindyD_Squadron_C', 'Squadron Magian', 4, 95, 99, 94.9, -3.17, -145.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989692, 0, 'WindyD_Squadron_A', 'Squadron Hoplite', 2, 95, 99, 88.5, -3.17, -150.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989680, 0, 'WindyD_Squadron_B', 'Squadron\'s Wyvern', 3, 95, 99, 101.5, -3.17, -150.5, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989673, 0, 'WindyD_Squadron_C', 'Squadron Magian', 4, 95, 99, 92.0, -3.17, -149.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989695, 0, 'WindyD_Squadron_A', 'Squadron Hoplite', 2, 95, 99, 97.5, -3.17, -149.5, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989689, 0, 'WindyD_Squadron_B', 'Squadron\'s Wyvern', 3, 95, 99, 94.9, -3.17, -151.5, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989646, 0, 'WindyD_Statue', 'Incarnation Icon', 5, 99, 99, 99.0, -3.17, -140.5, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989651, 0, 'WindyD_Statue', 'Incarnation Icon', 5, 99, 99, 90.0, -3.17, -140.5, 64);
REPLACE INTO `mob_spawn_points` VALUES (17990010, 0, 'WindyD_Regiment_A', 'Regiment Hoplite', 6, 97, 99, 91.0, -3.17, -155.5, 64);
REPLACE INTO `mob_spawn_points` VALUES (17990015, 0, 'WindyD_Regiment_B', 'Regiment\'s Wyvern', 7, 97, 99, 98.5, -3.17, -156.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17990007, 0, 'WindyD_Regiment_C', 'Regiment Magian', 8, 97, 99, 94.9, -3.17, -157.5, 64);
REPLACE INTO `mob_spawn_points` VALUES (17990021, 0, 'WindyD_Regiment_A', 'Regiment Hoplite', 6, 97, 99, 88.0, -3.17, -155.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17990033, 0, 'WindyD_Regiment_B', 'Regiment\'s Wyvern', 7, 97, 99, 101.5, -3.17, -155.5, 64);
REPLACE INTO `mob_spawn_points` VALUES (17990017, 0, 'WindyD_Regiment_C', 'Regiment Magian', 8, 97, 99, 92.5, -3.17, -160.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17990037, 0, 'WindyD_Regiment_A', 'Regiment Hoplite', 6, 97, 99, 97.0, -3.17, -160.5, 64);
REPLACE INTO `mob_spawn_points` VALUES (17990057, 0, 'WindyD_Regiment_B', 'Regiment\'s Wyvern', 7, 97, 99, 94.9, -3.17, -163.5, 64);
REPLACE INTO `instance_list` VALUES (29600, 'dynamis_windurst_d', 296, 239, 60, -221.988, 1.000, -120.184, 0, NULL, NULL, NULL, NULL);
DELETE FROM `instance_entities` WHERE `instanceid` = 29600; -- drop stale registrations (incl. previously-claimed mobids)
REPLACE INTO `instance_entities` VALUES (29600, 17989636);
REPLACE INTO `instance_entities` VALUES (29600, 17989645);
REPLACE INTO `instance_entities` VALUES (29600, 17989640);
REPLACE INTO `instance_entities` VALUES (29600, 17989665);
REPLACE INTO `instance_entities` VALUES (29600, 17989635);
REPLACE INTO `instance_entities` VALUES (29600, 17989641);
REPLACE INTO `instance_entities` VALUES (29600, 17989634);
REPLACE INTO `instance_entities` VALUES (29600, 17989983);
REPLACE INTO `instance_entities` VALUES (29600, 17989994);
REPLACE INTO `instance_entities` VALUES (29600, 17989988);
REPLACE INTO `instance_entities` VALUES (29600, 17990001);
REPLACE INTO `instance_entities` VALUES (29600, 17989981);
REPLACE INTO `instance_entities` VALUES (29600, 17989671);
REPLACE INTO `instance_entities` VALUES (29600, 17989668);
REPLACE INTO `instance_entities` VALUES (29600, 17989661);
REPLACE INTO `instance_entities` VALUES (29600, 17989692);
REPLACE INTO `instance_entities` VALUES (29600, 17989680);
REPLACE INTO `instance_entities` VALUES (29600, 17989673);
REPLACE INTO `instance_entities` VALUES (29600, 17989695);
REPLACE INTO `instance_entities` VALUES (29600, 17989689);
REPLACE INTO `instance_entities` VALUES (29600, 17989646);
REPLACE INTO `instance_entities` VALUES (29600, 17989651);
REPLACE INTO `instance_entities` VALUES (29600, 17990010);
REPLACE INTO `instance_entities` VALUES (29600, 17990015);
REPLACE INTO `instance_entities` VALUES (29600, 17990007);
REPLACE INTO `instance_entities` VALUES (29600, 17990021);
REPLACE INTO `instance_entities` VALUES (29600, 17990033);
REPLACE INTO `instance_entities` VALUES (29600, 17990017);
REPLACE INTO `instance_entities` VALUES (29600, 17990037);
REPLACE INTO `instance_entities` VALUES (29600, 17990057);
DELETE FROM `mob_droplist` WHERE `dropId` IN (29601, 29602, 29603, 29604);
INSERT INTO `mob_droplist` VALUES (29601, 0, 0, 1000, 9539, @ALWAYS);
INSERT INTO `mob_droplist` VALUES (29601, 0, 0, 1000, 9539, @COMMON);
INSERT INTO `mob_droplist` VALUES (29602, 0, 0, 1000, 9539, @UNCOMMON);
INSERT INTO `mob_droplist` VALUES (29603, 0, 0, 1000, 9541, @UNCOMMON);
INSERT INTO `mob_droplist` VALUES (29604, 0, 0, 1000, 9541, @ALWAYS);
INSERT INTO `mob_droplist` VALUES (29604, 0, 0, 1000, 9541, @COMMON);
INSERT INTO `mob_droplist` VALUES (29604, 0, 0, 1000, 9543, @UNCOMMON);

-- ============================================================================
-- Jeuno [D] (zone 297, instance 29700) -- Goblins, unlocks LEGS. mobid base 17993728.
-- Reuses zone-188 Goblin pools; coords cluster the validated Gabblox anchor.
-- ============================================================================
REPLACE INTO `mob_groups` VALUES (1, 1668, 297, 'ImpishGolem_JeunoD', 0, 128, 29701, 35000, 1000, 0, NULL);
REPLACE INTO `mob_groups` VALUES (2, 4184, 297, 'JeunoD_Squadron_A',  0, 128, 29702,  8000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (3, 4199, 297, 'JeunoD_Squadron_B',  0, 128, 29702,  8000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (4, 4170, 297, 'JeunoD_Squadron_C',  0, 128, 29702,  8000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (5, 3548, 297, 'JeunoD_Statue',      0, 128,     0,  6000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (6, 4182, 297, 'JeunoD_Regiment_A',  0, 128, 29703, 11000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (7, 4147, 297, 'JeunoD_Regiment_B',  0, 128, 29703, 11000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (8, 4192, 297, 'JeunoD_Regiment_C',  0, 128, 29703, 11000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (9, 1444, 297, 'Obstatrix_JeunoD',   0, 128, 29704, 70000, 2000, 0, NULL);
REPLACE INTO `mob_spawn_points` VALUES (17993732, 0, 'JeunoD_Squadron_A', 'Squadron Berserker', 2, 95, 99, -0.25, 8.5, -47.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993741, 0, 'JeunoD_Squadron_B', 'Squadron\'s Wyvern', 3, 95, 99, 6.0, 8.5, -54.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993736, 0, 'JeunoD_Squadron_C', 'Squadron Arcanomancer', 4, 95, 99, -7.0, 8.5, -54.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993748, 0, 'JeunoD_Squadron_A', 'Squadron Berserker', 2, 95, 99, -0.25, 8.5, -60.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993731, 0, 'JeunoD_Statue', 'Impish Statue', 5, 99, 99, 8.0, 8.5, -47.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993737, 0, 'JeunoD_Statue', 'Impish Statue', 5, 99, 99, -9.0, 8.5, -47.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993730, 0, 'ImpishGolem_JeunoD', 'Impish Golem', 1, 99, 99, -0.250, 8.500, -53.982, 209);
REPLACE INTO `mob_spawn_points` VALUES (17994070, 0, 'JeunoD_Regiment_A', 'Regiment Berserker', 6, 97, 99, -0.25, 8.5, -62.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17994079, 0, 'JeunoD_Regiment_B', 'Regiment\'s Wyvern', 7, 97, 99, 6.0, 8.5, -60.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17994074, 0, 'JeunoD_Regiment_C', 'Regiment Arcanomancer', 8, 97, 99, -7.0, 8.5, -60.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17994083, 0, 'JeunoD_Regiment_A', 'Regiment Berserker', 6, 97, 99, -0.25, 8.5, -66.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17994068, 0, 'Obstatrix_JeunoD', 'Obstatrix', 9, 99, 99, -0.25, 8.5, -68.0, 209);
-- Population pass (2026-07): waves 4->12 trash + 2->4 statues (see zone 294 note).
REPLACE INTO `mob_spawn_points` VALUES (17993778, 0, 'JeunoD_Squadron_A', 'Squadron Berserker', 2, 95, 99, 3.00, 8.5, -50.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993758, 0, 'JeunoD_Squadron_B', 'Squadron\'s Wyvern', 3, 95, 99, -4.00, 8.5, -50.5, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993753, 0, 'JeunoD_Squadron_C', 'Squadron Arcanomancer', 4, 95, 99, -0.25, 8.5, -52.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993787, 0, 'JeunoD_Squadron_A', 'Squadron Berserker', 2, 95, 99, 5.50, 8.5, -57.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993783, 0, 'JeunoD_Squadron_B', 'Squadron\'s Wyvern', 3, 95, 99, -6.00, 8.5, -57.5, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993768, 0, 'JeunoD_Squadron_C', 'Squadron Arcanomancer', 4, 95, 99, 2.50, 8.5, -56.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993806, 0, 'JeunoD_Squadron_A', 'Squadron Berserker', 2, 95, 99, -3.00, 8.5, -56.5, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993785, 0, 'JeunoD_Squadron_B', 'Squadron\'s Wyvern', 3, 95, 99, -0.25, 8.5, -58.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993744, 0, 'JeunoD_Statue', 'Impish Statue', 5, 99, 99, 5.00, 8.5, -47.5, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993749, 0, 'JeunoD_Statue', 'Impish Statue', 5, 99, 99, -6.50, 8.5, -47.5, 209);
REPLACE INTO `mob_spawn_points` VALUES (17994091, 0, 'JeunoD_Regiment_A', 'Regiment Berserker', 6, 97, 99, 3.00, 8.5, -62.5, 209);
REPLACE INTO `mob_spawn_points` VALUES (17994120, 0, 'JeunoD_Regiment_B', 'Regiment\'s Wyvern', 7, 97, 99, -4.00, 8.5, -63.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17994087, 0, 'JeunoD_Regiment_C', 'Regiment Arcanomancer', 8, 97, 99, -0.25, 8.5, -64.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17994100, 0, 'JeunoD_Regiment_A', 'Regiment Berserker', 6, 97, 99, 5.50, 8.5, -61.5, 209);
REPLACE INTO `mob_spawn_points` VALUES (17994127, 0, 'JeunoD_Regiment_B', 'Regiment\'s Wyvern', 7, 97, 99, -6.50, 8.5, -62.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17994095, 0, 'JeunoD_Regiment_C', 'Regiment Arcanomancer', 8, 97, 99, 2.00, 8.5, -66.5, 209);
REPLACE INTO `mob_spawn_points` VALUES (17994108, 0, 'JeunoD_Regiment_A', 'Regiment Berserker', 6, 97, 99, -3.50, 8.5, -67.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17994155, 0, 'JeunoD_Regiment_B', 'Regiment\'s Wyvern', 7, 97, 99, -0.25, 8.5, -70.5, 209);
REPLACE INTO `instance_list` VALUES (29700, 'dynamis_jeuno_d', 297, 243, 60, 48.930, 10.002, -71.032, 195, NULL, NULL, NULL, NULL);
DELETE FROM `instance_entities` WHERE `instanceid` = 29700; -- drop stale registrations (incl. previously-claimed mobids)
REPLACE INTO `instance_entities` VALUES (29700, 17993732);
REPLACE INTO `instance_entities` VALUES (29700, 17993741);
REPLACE INTO `instance_entities` VALUES (29700, 17993736);
REPLACE INTO `instance_entities` VALUES (29700, 17993748);
REPLACE INTO `instance_entities` VALUES (29700, 17993731);
REPLACE INTO `instance_entities` VALUES (29700, 17993737);
REPLACE INTO `instance_entities` VALUES (29700, 17993730);
REPLACE INTO `instance_entities` VALUES (29700, 17994070);
REPLACE INTO `instance_entities` VALUES (29700, 17994079);
REPLACE INTO `instance_entities` VALUES (29700, 17994074);
REPLACE INTO `instance_entities` VALUES (29700, 17994083);
REPLACE INTO `instance_entities` VALUES (29700, 17994068);
REPLACE INTO `instance_entities` VALUES (29700, 17993778);
REPLACE INTO `instance_entities` VALUES (29700, 17993758);
REPLACE INTO `instance_entities` VALUES (29700, 17993753);
REPLACE INTO `instance_entities` VALUES (29700, 17993787);
REPLACE INTO `instance_entities` VALUES (29700, 17993783);
REPLACE INTO `instance_entities` VALUES (29700, 17993768);
REPLACE INTO `instance_entities` VALUES (29700, 17993806);
REPLACE INTO `instance_entities` VALUES (29700, 17993785);
REPLACE INTO `instance_entities` VALUES (29700, 17993744);
REPLACE INTO `instance_entities` VALUES (29700, 17993749);
REPLACE INTO `instance_entities` VALUES (29700, 17994091);
REPLACE INTO `instance_entities` VALUES (29700, 17994120);
REPLACE INTO `instance_entities` VALUES (29700, 17994087);
REPLACE INTO `instance_entities` VALUES (29700, 17994100);
REPLACE INTO `instance_entities` VALUES (29700, 17994127);
REPLACE INTO `instance_entities` VALUES (29700, 17994095);
REPLACE INTO `instance_entities` VALUES (29700, 17994108);
REPLACE INTO `instance_entities` VALUES (29700, 17994155);
DELETE FROM `mob_droplist` WHERE `dropId` IN (29701, 29702, 29703, 29704);
INSERT INTO `mob_droplist` VALUES (29701, 0, 0, 1000, 9539, @ALWAYS);
INSERT INTO `mob_droplist` VALUES (29701, 0, 0, 1000, 9539, @COMMON);
INSERT INTO `mob_droplist` VALUES (29702, 0, 0, 1000, 9539, @UNCOMMON);
INSERT INTO `mob_droplist` VALUES (29703, 0, 0, 1000, 9541, @UNCOMMON);
INSERT INTO `mob_droplist` VALUES (29704, 0, 0, 1000, 9541, @ALWAYS);
INSERT INTO `mob_droplist` VALUES (29704, 0, 0, 1000, 9541, @COMMON);
INSERT INTO `mob_droplist` VALUES (29704, 0, 0, 1000, 9543, @UNCOMMON);

-- ============================================================================
-- Wave 3: Disjoined NMs (Fomor, race-themed) -- spawn after the Mega-Boss falls.
-- No time extension in wave 3; this is the toughest fight. Drops Demon's Medals.
-- Reuses Fomor job pools (1382 BLM, 1385 MNK, 1387 PLD, 1388 RNG). groupid 10.
-- ============================================================================
REPLACE INTO `mob_groups` VALUES (10, 1387, 294, 'Disjoined_Elvaan_D',   0, 128, 29405, 80000, 2000, 0, NULL);
REPLACE INTO `mob_groups` VALUES (10, 1385, 295, 'Disjoined_Galka_D',    0, 128, 29505, 80000, 2000, 0, NULL);
REPLACE INTO `mob_groups` VALUES (10, 1382, 296, 'Disjoined_Tarutaru_D', 0, 128, 29605, 75000, 3000, 0, NULL);
REPLACE INTO `mob_groups` VALUES (10, 1388, 297, 'Disjoined_Mithra_D',   0, 128, 29705, 80000, 2000, 0, NULL);
REPLACE INTO `mob_spawn_points` VALUES (17982238, 0, 'Disjoined_Elvaan_D', 'Disjoined Elvaan', 10, 99, 99, 131.470, -0.499, 92.000, 215);
REPLACE INTO `mob_spawn_points` VALUES (17986326, 0, 'Disjoined_Galka_D', 'Disjoined Galka', 10, 99, 99, -12.500, -1.560, -144.000, 56);
REPLACE INTO `mob_spawn_points` VALUES (17990425, 0, 'Disjoined_Tarutaru_D', 'Disjoined Tarutaru', 10, 99, 99, 94.900, -3.170, -167.000, 64);
REPLACE INTO `mob_spawn_points` VALUES (17994487, 0, 'Disjoined_Mithra_D', 'Disjoined Mithra', 10, 99, 99, -0.250, 8.500, -74.000, 209);
REPLACE INTO `instance_entities` VALUES (29400, 17982238);
REPLACE INTO `instance_entities` VALUES (29500, 17986326);
REPLACE INTO `instance_entities` VALUES (29600, 17990425);
REPLACE INTO `instance_entities` VALUES (29700, 17994487);
DELETE FROM `mob_droplist` WHERE `dropId` IN (29405, 29505, 29605, 29705);
INSERT INTO `mob_droplist` VALUES (29405, 0, 0, 1000, 9543, @ALWAYS);
INSERT INTO `mob_droplist` VALUES (29405, 0, 0, 1000, 9541, @COMMON);
INSERT INTO `mob_droplist` VALUES (29505, 0, 0, 1000, 9543, @ALWAYS);
INSERT INTO `mob_droplist` VALUES (29505, 0, 0, 1000, 9541, @COMMON);
INSERT INTO `mob_droplist` VALUES (29605, 0, 0, 1000, 9543, @ALWAYS);
INSERT INTO `mob_droplist` VALUES (29605, 0, 0, 1000, 9541, @COMMON);
INSERT INTO `mob_droplist` VALUES (29705, 0, 0, 1000, 9543, @ALWAYS);
INSERT INTO `mob_droplist` VALUES (29705, 0, 0, 1000, 9541, @COMMON);

-- ============================================================================
-- Zone type: the [D] zones ship from upstream as zonetype 128 (DYNAMIS only).
-- CInstanceLoader requires the INSTANCED (256) bit -- without it every
-- createInstance() fails with "Invalid zone for instanceid" and the entry
-- portal eats the toll, prints "the rift opens", and warps nobody (the exact
-- player report 2026-07-09). 384 = DYNAMIS|INSTANCED keeps dynamis combat
-- semantics AND lets the zone host instances. Idempotent.
-- NOTE: zonetype is read once at map BOOT (zoneutils CreateZone) -> this fix
-- is restart-gated. Stock sql/zone_settings.sql rows carry the same patch.
-- ============================================================================
UPDATE `zone_settings` SET `zonetype` = `zonetype` | 256
WHERE `zoneid` IN (294, 295, 296, 297) AND (`zonetype` & 256) = 0;
