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
-- Population pass (2026-07): waves 4->12 trash + 2->4 statues per zone. The
-- first-pass 12-mob roster cleared in ~10 min and made the 60+ext timer
-- pointless (player report 2026-07-10). New points interpolate the validated
-- clusters above (same courtyard / Vanguard-field envelopes).
-- Wave 1: Squadron reinforcements
REPLACE INTO `mob_spawn_points` VALUES (17981454, 0, 'SandoriaD_Squadron_A', 'Orcish Squadron', 2, 95, 99,  -8.000, -2.000, 42.000,  32);
REPLACE INTO `mob_spawn_points` VALUES (17981455, 0, 'SandoriaD_Squadron_B', 'Orcish Squadron', 3, 95, 99,   5.500, -2.200, 35.500, 190);
REPLACE INTO `mob_spawn_points` VALUES (17981456, 0, 'SandoriaD_Squadron_C', 'Orcish Squadron', 4, 95, 99,   0.500, -2.100, 42.500,   0);
REPLACE INTO `mob_spawn_points` VALUES (17981457, 0, 'SandoriaD_Squadron_A', 'Orcish Squadron', 2, 95, 99,   9.500, -2.000, 39.500, 110);
REPLACE INTO `mob_spawn_points` VALUES (17981458, 0, 'SandoriaD_Squadron_B', 'Orcish Squadron', 3, 95, 99,  -6.500, -2.000, 37.000,  60);
REPLACE INTO `mob_spawn_points` VALUES (17981459, 0, 'SandoriaD_Squadron_C', 'Orcish Squadron', 4, 95, 99,   3.000, -2.300, 43.000, 150);
REPLACE INTO `mob_spawn_points` VALUES (17981460, 0, 'SandoriaD_Squadron_A', 'Orcish Squadron', 2, 95, 99,  -4.500, -2.200, 44.500, 100);
REPLACE INTO `mob_spawn_points` VALUES (17981461, 0, 'SandoriaD_Squadron_B', 'Orcish Squadron', 3, 95, 99,   7.000, -2.100, 43.500, 220);
-- Wave 1: extra time-extension statues
REPLACE INTO `mob_spawn_points` VALUES (17981462, 0, 'SandoriaD_Statue', 'Corporal Tombstone', 5, 99, 99,  12.000, -2.000, 36.000, 160);
REPLACE INTO `mob_spawn_points` VALUES (17981463, 0, 'SandoriaD_Statue', 'Corporal Tombstone', 5, 99, 99, -12.000, -2.000, 36.000,  96);
-- Wave 2: Regiment reinforcements (Vanguard field)
REPLACE INTO `mob_spawn_points` VALUES (17981464, 0, 'SandoriaD_Regiment_A', 'Orcish Regiment', 6, 97, 99, 137.000, -2.400, 107.500, 200);
REPLACE INTO `mob_spawn_points` VALUES (17981465, 0, 'SandoriaD_Regiment_B', 'Orcish Regiment', 7, 97, 99, 128.000, -2.000, 103.000, 130);
REPLACE INTO `mob_spawn_points` VALUES (17981466, 0, 'SandoriaD_Regiment_C', 'Orcish Regiment', 8, 97, 99, 140.000, -2.500, 103.500, 240);
REPLACE INTO `mob_spawn_points` VALUES (17981467, 0, 'SandoriaD_Regiment_A', 'Orcish Regiment', 6, 97, 99, 133.500, -2.500, 106.000, 180);
REPLACE INTO `mob_spawn_points` VALUES (17981468, 0, 'SandoriaD_Regiment_B', 'Orcish Regiment', 7, 97, 99, 126.500, -1.500, 100.000, 140);
REPLACE INTO `mob_spawn_points` VALUES (17981469, 0, 'SandoriaD_Regiment_C', 'Orcish Regiment', 8, 97, 99, 143.000, -2.500, 108.500, 250);
REPLACE INTO `mob_spawn_points` VALUES (17981470, 0, 'SandoriaD_Regiment_A', 'Orcish Regiment', 6, 97, 99, 130.000, -1.800, 106.500, 160);
REPLACE INTO `mob_spawn_points` VALUES (17981471, 0, 'SandoriaD_Regiment_B', 'Orcish Regiment', 7, 97, 99, 135.500, -2.300, 101.500,  90);

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
REPLACE INTO `instance_entities` VALUES (29400, 17981454);
REPLACE INTO `instance_entities` VALUES (29400, 17981455);
REPLACE INTO `instance_entities` VALUES (29400, 17981456);
REPLACE INTO `instance_entities` VALUES (29400, 17981457);
REPLACE INTO `instance_entities` VALUES (29400, 17981458);
REPLACE INTO `instance_entities` VALUES (29400, 17981459);
REPLACE INTO `instance_entities` VALUES (29400, 17981460);
REPLACE INTO `instance_entities` VALUES (29400, 17981461);
REPLACE INTO `instance_entities` VALUES (29400, 17981462);
REPLACE INTO `instance_entities` VALUES (29400, 17981463);
REPLACE INTO `instance_entities` VALUES (29400, 17981464);
REPLACE INTO `instance_entities` VALUES (29400, 17981465);
REPLACE INTO `instance_entities` VALUES (29400, 17981466);
REPLACE INTO `instance_entities` VALUES (29400, 17981467);
REPLACE INTO `instance_entities` VALUES (29400, 17981468);
REPLACE INTO `instance_entities` VALUES (29400, 17981469);
REPLACE INTO `instance_entities` VALUES (29400, 17981470);
REPLACE INTO `instance_entities` VALUES (29400, 17981471);

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
REPLACE INTO `mob_spawn_points` VALUES (17985537, 0, 'BastokD_Squadron_A', 'Quadav Squadron', 2, 95, 99, -12.5, -1.56, -118.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985538, 0, 'BastokD_Squadron_B', 'Quadav Squadron', 3, 95, 99,  -6.0, -1.56, -124.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985539, 0, 'BastokD_Squadron_C', 'Quadav Squadron', 4, 95, 99, -19.0, -1.56, -124.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985540, 0, 'BastokD_Squadron_A', 'Quadav Squadron', 2, 95, 99, -12.5, -1.56, -130.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985541, 0, 'BastokD_Statue', 'Adamantking Image', 5, 99, 99,  -4.0, -1.56, -116.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985542, 0, 'BastokD_Statue', 'Adamantking Image', 5, 99, 99, -21.0, -1.56, -116.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985543, 0, 'MushaEffigy_BastokD', 'Mu\'Sha Effigy', 1, 99, 99, -12.509, -1.559, -124.363, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985544, 0, 'BastokD_Regiment_A', 'Quadav Regiment', 6, 97, 99, -12.5, -1.56, -132.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985545, 0, 'BastokD_Regiment_B', 'Quadav Regiment', 7, 97, 99,  -6.0, -1.56, -130.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985546, 0, 'BastokD_Regiment_C', 'Quadav Regiment', 8, 97, 99, -19.0, -1.56, -130.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985547, 0, 'BastokD_Regiment_A', 'Quadav Regiment', 6, 97, 99, -12.5, -1.56, -136.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985548, 0, 'KaRhoFearsinger', 'Ka\'Rho Fearsinger', 9, 99, 99, -12.5, -1.56, -138.0, 56);
-- Population pass (2026-07): waves 4->12 trash + 2->4 statues (see zone 294 note).
REPLACE INTO `mob_spawn_points` VALUES (17985550, 0, 'BastokD_Squadron_A', 'Quadav Squadron', 2, 95, 99,  -9.0, -1.56, -120.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985551, 0, 'BastokD_Squadron_B', 'Quadav Squadron', 3, 95, 99, -16.0, -1.56, -121.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985552, 0, 'BastokD_Squadron_C', 'Quadav Squadron', 4, 95, 99,  -9.5, -1.56, -127.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985553, 0, 'BastokD_Squadron_A', 'Quadav Squadron', 2, 95, 99, -16.5, -1.56, -127.5, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985554, 0, 'BastokD_Squadron_B', 'Quadav Squadron', 3, 95, 99, -12.5, -1.56, -121.5, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985555, 0, 'BastokD_Squadron_C', 'Quadav Squadron', 4, 95, 99,  -6.5, -1.56, -119.5, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985556, 0, 'BastokD_Squadron_A', 'Quadav Squadron', 2, 95, 99, -19.5, -1.56, -119.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985557, 0, 'BastokD_Squadron_B', 'Quadav Squadron', 3, 95, 99, -12.0, -1.56, -126.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985558, 0, 'BastokD_Statue', 'Adamantking Image', 5, 99, 99,  -8.0, -1.56, -116.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985559, 0, 'BastokD_Statue', 'Adamantking Image', 5, 99, 99, -17.0, -1.56, -116.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985560, 0, 'BastokD_Regiment_A', 'Quadav Regiment', 6, 97, 99,  -9.0, -1.56, -133.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985561, 0, 'BastokD_Regiment_B', 'Quadav Regiment', 7, 97, 99, -16.0, -1.56, -133.5, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985562, 0, 'BastokD_Regiment_C', 'Quadav Regiment', 8, 97, 99, -12.5, -1.56, -134.5, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985563, 0, 'BastokD_Regiment_A', 'Quadav Regiment', 6, 97, 99,  -6.5, -1.56, -131.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985564, 0, 'BastokD_Regiment_B', 'Quadav Regiment', 7, 97, 99, -19.0, -1.56, -131.5, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985565, 0, 'BastokD_Regiment_C', 'Quadav Regiment', 8, 97, 99,  -9.5, -1.56, -136.5, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985566, 0, 'BastokD_Regiment_A', 'Quadav Regiment', 6, 97, 99, -15.5, -1.56, -137.0, 56);
REPLACE INTO `mob_spawn_points` VALUES (17985567, 0, 'BastokD_Regiment_B', 'Quadav Regiment', 7, 97, 99, -12.5, -1.56, -140.0, 56);
REPLACE INTO `instance_list` VALUES (29500, 'dynamis_bastok_d', 295, 234, 60, 116.482, 0.994, -72.121, 128, NULL, NULL, NULL, NULL);
REPLACE INTO `instance_entities` VALUES (29500, 17985537);
REPLACE INTO `instance_entities` VALUES (29500, 17985538);
REPLACE INTO `instance_entities` VALUES (29500, 17985539);
REPLACE INTO `instance_entities` VALUES (29500, 17985540);
REPLACE INTO `instance_entities` VALUES (29500, 17985541);
REPLACE INTO `instance_entities` VALUES (29500, 17985542);
REPLACE INTO `instance_entities` VALUES (29500, 17985543);
REPLACE INTO `instance_entities` VALUES (29500, 17985544);
REPLACE INTO `instance_entities` VALUES (29500, 17985545);
REPLACE INTO `instance_entities` VALUES (29500, 17985546);
REPLACE INTO `instance_entities` VALUES (29500, 17985547);
REPLACE INTO `instance_entities` VALUES (29500, 17985548);
REPLACE INTO `instance_entities` VALUES (29500, 17985550);
REPLACE INTO `instance_entities` VALUES (29500, 17985551);
REPLACE INTO `instance_entities` VALUES (29500, 17985552);
REPLACE INTO `instance_entities` VALUES (29500, 17985553);
REPLACE INTO `instance_entities` VALUES (29500, 17985554);
REPLACE INTO `instance_entities` VALUES (29500, 17985555);
REPLACE INTO `instance_entities` VALUES (29500, 17985556);
REPLACE INTO `instance_entities` VALUES (29500, 17985557);
REPLACE INTO `instance_entities` VALUES (29500, 17985558);
REPLACE INTO `instance_entities` VALUES (29500, 17985559);
REPLACE INTO `instance_entities` VALUES (29500, 17985560);
REPLACE INTO `instance_entities` VALUES (29500, 17985561);
REPLACE INTO `instance_entities` VALUES (29500, 17985562);
REPLACE INTO `instance_entities` VALUES (29500, 17985563);
REPLACE INTO `instance_entities` VALUES (29500, 17985564);
REPLACE INTO `instance_entities` VALUES (29500, 17985565);
REPLACE INTO `instance_entities` VALUES (29500, 17985566);
REPLACE INTO `instance_entities` VALUES (29500, 17985567);
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
REPLACE INTO `mob_spawn_points` VALUES (17989633, 0, 'WindyD_Squadron_A', 'Yagudo Squadron', 2, 95, 99, 94.9, -3.17, -141.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989634, 0, 'WindyD_Squadron_B', 'Yagudo Squadron', 3, 95, 99, 101.0, -3.17, -147.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989635, 0, 'WindyD_Squadron_C', 'Yagudo Squadron', 4, 95, 99, 88.0, -3.17, -147.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989636, 0, 'WindyD_Squadron_A', 'Yagudo Squadron', 2, 95, 99, 94.9, -3.17, -153.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989637, 0, 'WindyD_Statue', 'Evincing Statue', 5, 99, 99, 103.0, -3.17, -140.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989638, 0, 'WindyD_Statue', 'Evincing Statue', 5, 99, 99, 86.0, -3.17, -140.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989639, 0, 'EvincingIdol_WindyD', 'Evincing Idol', 1, 99, 99, 94.944, -3.171, -147.770, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989640, 0, 'WindyD_Regiment_A', 'Yagudo Regiment', 6, 97, 99, 94.9, -3.17, -155.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989641, 0, 'WindyD_Regiment_B', 'Yagudo Regiment', 7, 97, 99, 101.0, -3.17, -153.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989642, 0, 'WindyD_Regiment_C', 'Yagudo Regiment', 8, 97, 99, 88.0, -3.17, -153.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989643, 0, 'WindyD_Regiment_A', 'Yagudo Regiment', 6, 97, 99, 94.9, -3.17, -159.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989644, 0, 'FiiPexuTheEternal', 'Fii Pexu the Eternal', 9, 99, 99, 94.9, -3.17, -161.0, 64);
-- Population pass (2026-07): waves 4->12 trash + 2->4 statues (see zone 294 note).
REPLACE INTO `mob_spawn_points` VALUES (17989646, 0, 'WindyD_Squadron_A', 'Yagudo Squadron', 2, 95, 99,  91.0, -3.17, -143.5, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989647, 0, 'WindyD_Squadron_B', 'Yagudo Squadron', 3, 95, 99,  98.5, -3.17, -143.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989648, 0, 'WindyD_Squadron_C', 'Yagudo Squadron', 4, 95, 99,  94.9, -3.17, -145.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989649, 0, 'WindyD_Squadron_A', 'Yagudo Squadron', 2, 95, 99,  88.5, -3.17, -150.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989650, 0, 'WindyD_Squadron_B', 'Yagudo Squadron', 3, 95, 99, 101.5, -3.17, -150.5, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989651, 0, 'WindyD_Squadron_C', 'Yagudo Squadron', 4, 95, 99,  92.0, -3.17, -149.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989652, 0, 'WindyD_Squadron_A', 'Yagudo Squadron', 2, 95, 99,  97.5, -3.17, -149.5, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989653, 0, 'WindyD_Squadron_B', 'Yagudo Squadron', 3, 95, 99,  94.9, -3.17, -151.5, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989654, 0, 'WindyD_Statue', 'Evincing Statue', 5, 99, 99,  99.0, -3.17, -140.5, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989655, 0, 'WindyD_Statue', 'Evincing Statue', 5, 99, 99,  90.0, -3.17, -140.5, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989656, 0, 'WindyD_Regiment_A', 'Yagudo Regiment', 6, 97, 99,  91.0, -3.17, -155.5, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989657, 0, 'WindyD_Regiment_B', 'Yagudo Regiment', 7, 97, 99,  98.5, -3.17, -156.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989658, 0, 'WindyD_Regiment_C', 'Yagudo Regiment', 8, 97, 99,  94.9, -3.17, -157.5, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989659, 0, 'WindyD_Regiment_A', 'Yagudo Regiment', 6, 97, 99,  88.0, -3.17, -155.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989660, 0, 'WindyD_Regiment_B', 'Yagudo Regiment', 7, 97, 99, 101.5, -3.17, -155.5, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989661, 0, 'WindyD_Regiment_C', 'Yagudo Regiment', 8, 97, 99,  92.5, -3.17, -160.0, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989662, 0, 'WindyD_Regiment_A', 'Yagudo Regiment', 6, 97, 99,  97.0, -3.17, -160.5, 64);
REPLACE INTO `mob_spawn_points` VALUES (17989663, 0, 'WindyD_Regiment_B', 'Yagudo Regiment', 7, 97, 99,  94.9, -3.17, -163.5, 64);
REPLACE INTO `instance_list` VALUES (29600, 'dynamis_windurst_d', 296, 239, 60, -221.988, 1.000, -120.184, 0, NULL, NULL, NULL, NULL);
REPLACE INTO `instance_entities` VALUES (29600, 17989633);
REPLACE INTO `instance_entities` VALUES (29600, 17989634);
REPLACE INTO `instance_entities` VALUES (29600, 17989635);
REPLACE INTO `instance_entities` VALUES (29600, 17989636);
REPLACE INTO `instance_entities` VALUES (29600, 17989637);
REPLACE INTO `instance_entities` VALUES (29600, 17989638);
REPLACE INTO `instance_entities` VALUES (29600, 17989639);
REPLACE INTO `instance_entities` VALUES (29600, 17989640);
REPLACE INTO `instance_entities` VALUES (29600, 17989641);
REPLACE INTO `instance_entities` VALUES (29600, 17989642);
REPLACE INTO `instance_entities` VALUES (29600, 17989643);
REPLACE INTO `instance_entities` VALUES (29600, 17989644);
REPLACE INTO `instance_entities` VALUES (29600, 17989646);
REPLACE INTO `instance_entities` VALUES (29600, 17989647);
REPLACE INTO `instance_entities` VALUES (29600, 17989648);
REPLACE INTO `instance_entities` VALUES (29600, 17989649);
REPLACE INTO `instance_entities` VALUES (29600, 17989650);
REPLACE INTO `instance_entities` VALUES (29600, 17989651);
REPLACE INTO `instance_entities` VALUES (29600, 17989652);
REPLACE INTO `instance_entities` VALUES (29600, 17989653);
REPLACE INTO `instance_entities` VALUES (29600, 17989654);
REPLACE INTO `instance_entities` VALUES (29600, 17989655);
REPLACE INTO `instance_entities` VALUES (29600, 17989656);
REPLACE INTO `instance_entities` VALUES (29600, 17989657);
REPLACE INTO `instance_entities` VALUES (29600, 17989658);
REPLACE INTO `instance_entities` VALUES (29600, 17989659);
REPLACE INTO `instance_entities` VALUES (29600, 17989660);
REPLACE INTO `instance_entities` VALUES (29600, 17989661);
REPLACE INTO `instance_entities` VALUES (29600, 17989662);
REPLACE INTO `instance_entities` VALUES (29600, 17989663);
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
REPLACE INTO `mob_spawn_points` VALUES (17993729, 0, 'JeunoD_Squadron_A', 'Goblin Squadron', 2, 95, 99, -0.25, 8.5, -47.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993730, 0, 'JeunoD_Squadron_B', 'Goblin Squadron', 3, 95, 99, 6.0, 8.5, -54.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993731, 0, 'JeunoD_Squadron_C', 'Goblin Squadron', 4, 95, 99, -7.0, 8.5, -54.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993732, 0, 'JeunoD_Squadron_A', 'Goblin Squadron', 2, 95, 99, -0.25, 8.5, -60.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993733, 0, 'JeunoD_Statue', 'Impish Statue', 5, 99, 99, 8.0, 8.5, -47.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993734, 0, 'JeunoD_Statue', 'Impish Statue', 5, 99, 99, -9.0, 8.5, -47.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993735, 0, 'ImpishGolem_JeunoD', 'Impish Golem', 1, 99, 99, -0.250, 8.500, -53.982, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993736, 0, 'JeunoD_Regiment_A', 'Goblin Regiment', 6, 97, 99, -0.25, 8.5, -62.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993737, 0, 'JeunoD_Regiment_B', 'Goblin Regiment', 7, 97, 99, 6.0, 8.5, -60.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993738, 0, 'JeunoD_Regiment_C', 'Goblin Regiment', 8, 97, 99, -7.0, 8.5, -60.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993739, 0, 'JeunoD_Regiment_A', 'Goblin Regiment', 6, 97, 99, -0.25, 8.5, -66.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993740, 0, 'Obstatrix_JeunoD', 'Obstatrix', 9, 99, 99, -0.25, 8.5, -68.0, 209);
-- Population pass (2026-07): waves 4->12 trash + 2->4 statues (see zone 294 note).
REPLACE INTO `mob_spawn_points` VALUES (17993742, 0, 'JeunoD_Squadron_A', 'Goblin Squadron', 2, 95, 99,  3.00, 8.5, -50.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993743, 0, 'JeunoD_Squadron_B', 'Goblin Squadron', 3, 95, 99, -4.00, 8.5, -50.5, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993744, 0, 'JeunoD_Squadron_C', 'Goblin Squadron', 4, 95, 99, -0.25, 8.5, -52.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993745, 0, 'JeunoD_Squadron_A', 'Goblin Squadron', 2, 95, 99,  5.50, 8.5, -57.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993746, 0, 'JeunoD_Squadron_B', 'Goblin Squadron', 3, 95, 99, -6.00, 8.5, -57.5, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993747, 0, 'JeunoD_Squadron_C', 'Goblin Squadron', 4, 95, 99,  2.50, 8.5, -56.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993748, 0, 'JeunoD_Squadron_A', 'Goblin Squadron', 2, 95, 99, -3.00, 8.5, -56.5, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993749, 0, 'JeunoD_Squadron_B', 'Goblin Squadron', 3, 95, 99, -0.25, 8.5, -58.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993750, 0, 'JeunoD_Statue', 'Impish Statue', 5, 99, 99,  5.00, 8.5, -47.5, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993751, 0, 'JeunoD_Statue', 'Impish Statue', 5, 99, 99, -6.50, 8.5, -47.5, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993752, 0, 'JeunoD_Regiment_A', 'Goblin Regiment', 6, 97, 99,  3.00, 8.5, -62.5, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993753, 0, 'JeunoD_Regiment_B', 'Goblin Regiment', 7, 97, 99, -4.00, 8.5, -63.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993754, 0, 'JeunoD_Regiment_C', 'Goblin Regiment', 8, 97, 99, -0.25, 8.5, -64.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993755, 0, 'JeunoD_Regiment_A', 'Goblin Regiment', 6, 97, 99,  5.50, 8.5, -61.5, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993756, 0, 'JeunoD_Regiment_B', 'Goblin Regiment', 7, 97, 99, -6.50, 8.5, -62.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993757, 0, 'JeunoD_Regiment_C', 'Goblin Regiment', 8, 97, 99,  2.00, 8.5, -66.5, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993758, 0, 'JeunoD_Regiment_A', 'Goblin Regiment', 6, 97, 99, -3.50, 8.5, -67.0, 209);
REPLACE INTO `mob_spawn_points` VALUES (17993759, 0, 'JeunoD_Regiment_B', 'Goblin Regiment', 7, 97, 99, -0.25, 8.5, -70.5, 209);
REPLACE INTO `instance_list` VALUES (29700, 'dynamis_jeuno_d', 297, 243, 60, 48.930, 10.002, -71.032, 195, NULL, NULL, NULL, NULL);
REPLACE INTO `instance_entities` VALUES (29700, 17993729);
REPLACE INTO `instance_entities` VALUES (29700, 17993730);
REPLACE INTO `instance_entities` VALUES (29700, 17993731);
REPLACE INTO `instance_entities` VALUES (29700, 17993732);
REPLACE INTO `instance_entities` VALUES (29700, 17993733);
REPLACE INTO `instance_entities` VALUES (29700, 17993734);
REPLACE INTO `instance_entities` VALUES (29700, 17993735);
REPLACE INTO `instance_entities` VALUES (29700, 17993736);
REPLACE INTO `instance_entities` VALUES (29700, 17993737);
REPLACE INTO `instance_entities` VALUES (29700, 17993738);
REPLACE INTO `instance_entities` VALUES (29700, 17993739);
REPLACE INTO `instance_entities` VALUES (29700, 17993740);
REPLACE INTO `instance_entities` VALUES (29700, 17993742);
REPLACE INTO `instance_entities` VALUES (29700, 17993743);
REPLACE INTO `instance_entities` VALUES (29700, 17993744);
REPLACE INTO `instance_entities` VALUES (29700, 17993745);
REPLACE INTO `instance_entities` VALUES (29700, 17993746);
REPLACE INTO `instance_entities` VALUES (29700, 17993747);
REPLACE INTO `instance_entities` VALUES (29700, 17993748);
REPLACE INTO `instance_entities` VALUES (29700, 17993749);
REPLACE INTO `instance_entities` VALUES (29700, 17993750);
REPLACE INTO `instance_entities` VALUES (29700, 17993751);
REPLACE INTO `instance_entities` VALUES (29700, 17993752);
REPLACE INTO `instance_entities` VALUES (29700, 17993753);
REPLACE INTO `instance_entities` VALUES (29700, 17993754);
REPLACE INTO `instance_entities` VALUES (29700, 17993755);
REPLACE INTO `instance_entities` VALUES (29700, 17993756);
REPLACE INTO `instance_entities` VALUES (29700, 17993757);
REPLACE INTO `instance_entities` VALUES (29700, 17993758);
REPLACE INTO `instance_entities` VALUES (29700, 17993759);
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
REPLACE INTO `mob_spawn_points` VALUES (17981453, 0, 'Disjoined_Elvaan_D',   'Disjoined Elvaan',   10, 99, 99, 131.470, -0.499, 92.000, 215);
REPLACE INTO `mob_spawn_points` VALUES (17985549, 0, 'Disjoined_Galka_D',    'Disjoined Galka',    10, 99, 99, -12.500, -1.560, -144.000, 56);
REPLACE INTO `mob_spawn_points` VALUES (17989645, 0, 'Disjoined_Tarutaru_D', 'Disjoined Tarutaru', 10, 99, 99, 94.900, -3.170, -167.000, 64);
REPLACE INTO `mob_spawn_points` VALUES (17993741, 0, 'Disjoined_Mithra_D',   'Disjoined Mithra',   10, 99, 99, -0.250, 8.500, -74.000, 209);
REPLACE INTO `instance_entities` VALUES (29400, 17981453);
REPLACE INTO `instance_entities` VALUES (29500, 17985549);
REPLACE INTO `instance_entities` VALUES (29600, 17989645);
REPLACE INTO `instance_entities` VALUES (29700, 17993741);
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
