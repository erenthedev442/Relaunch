-- ============================================================================
-- Dynamis - Divergence (relaunch) -- CORRIDOR POPULATION PASS (owner 2026-07-12)
-- ----------------------------------------------------------------------------
-- Instanced 3-wave content built on the LSB instance framework. Each of the 4
-- city [D] zones keeps a 48+48 SQL spawn reserve across the full corridor.
-- Runtime instance configs activate an evenly-spaced T3 solo/trust subset:
-- 20 wave-1 trash, 6 time-extension statues, 20 wave-2 trash, and 3 named
-- bosses (mid at midpoint, mega + disjoined at the far corner). Keeping the
-- reserve coordinates makes future density tuning a Lua-only operation.
--
-- COORD PROVENANCE: every mob spawn coord below comes verbatim from a stock
-- retail Dynamis mob_spawn_points row for the donor zone (185/186/187/188).
-- Relaunch's [D] variants share DAT geometry with retail Dynamis, so these
-- are all validated-navmesh points. Mega + Disjoined coords are the far-corner
-- stock point offset a few units along the entry->far vector so mega faces
-- the party and disjoined sits at the actual corner.
--
-- MOB_GROUPS keep their existing poolIds (retail Vanguard Orc / Quadav / Yagudo
-- / Goblin pools) so mobs inherit real Dynamis TP/spell kits. Only the layout
-- changes.
--
-- INSTANCE_ENTITIES: DELETE-then-REPLACE per instance so re-runs stay idempotent.
--
-- Client-side names: fixed mobs render by DAT slot regardless of server-side
-- name. Since we now pull fresh mobids in each zone's mid range, the client
-- may show generic mob names (Vanguard-family per zone) rather than the
-- authored 'Squadron X / Regiment X'. polutils_name (website tables) stays on
-- theme.
-- ============================================================================

-- Drop-rate helper vars (mirror sql/mob_droplist.sql)
SET @ALWAYS   = 1000;
SET @COMMON   = 150;
SET @UNCOMMON = 100;
SET @RARE     = 50;


-- ============================================================================
-- San d'Oria [D] (zone 294, instance 29400) -- Orcs, unlocks FEET. mobid base 17981440.
-- Reuses zone-185 Vanguard Orc pools; coords from retail Dynamis-SdO stock spawns.
-- ============================================================================

-- ── mob_groups (unchanged: retail Vanguard family pools) ──
REPLACE INTO `mob_groups` VALUES (1, 3076, 294, 'Overseers_Tombstone', 0, 128, 29401, 35000, 1000, 0, NULL); -- Mid-boss
REPLACE INTO `mob_groups` VALUES (2, 4150, 294, 'SandoriaD_Squadron_A', 0, 128, 29402,  8000,    0, 0, NULL); -- Wave 1 trash
REPLACE INTO `mob_groups` VALUES (3, 4151, 294, 'SandoriaD_Squadron_B', 0, 128, 29402,  8000,    0, 0, NULL); -- Wave 1 trash
REPLACE INTO `mob_groups` VALUES (4, 4162, 294, 'SandoriaD_Squadron_C', 0, 128, 29402,  8000,    0, 0, NULL); -- Wave 1 trash
REPLACE INTO `mob_groups` VALUES (5, 3548, 294, 'SandoriaD_Statue',     0, 128,     0,  6000,    0, 0, NULL); -- Time-extension statue
REPLACE INTO `mob_groups` VALUES (6, 4193, 294, 'SandoriaD_Regiment_A', 0, 128, 29403, 11000,    0, 0, NULL); -- Wave 2 trash
REPLACE INTO `mob_groups` VALUES (7, 4172, 294, 'SandoriaD_Regiment_B', 0, 128, 29403, 11000,    0, 0, NULL); -- Wave 2 trash
REPLACE INTO `mob_groups` VALUES (8, 4135, 294, 'SandoriaD_Regiment_C', 0, 128, 29403, 11000,    0, 0, NULL); -- Wave 2 trash
REPLACE INTO `mob_groups` VALUES (9, 3340, 294, 'Halphas',             0, 128, 29404, 70000, 2000, 0, NULL); -- Mega-boss

-- ── mob_spawn_points: corridor pass ──
DELETE FROM `mob_spawn_points` WHERE `mobid` BETWEEN 17981440 AND 17985535;
-- ── Wave 1 corridor: 48 trash spread entry -> mid-boss (band 20-55%) ──

-- REPACK 2026-07-13: purge the old out-of-boundary corridor rows (mobids 17982500..17982605 were past zoneMin+1024).
DELETE FROM `mob_spawn_points`   WHERE mobid   BETWEEN 17982500 AND 17982605;
DELETE FROM `instance_entities`  WHERE id      BETWEEN 17982500 AND 17982605;
REPLACE INTO `mob_spawn_points` VALUES (17982300, 0, 'SandoriaD_Squadron_A', 'Squadron Knight', 2, 95, 99, 128.530, -0.499, 79.175, 216);
REPLACE INTO `mob_spawn_points` VALUES (17982301, 0, 'SandoriaD_Squadron_B', 'Squadron\'s Wyvern', 3, 95, 99, 109.249, -0.500, 80.079, 24);
REPLACE INTO `mob_spawn_points` VALUES (17982302, 0, 'SandoriaD_Squadron_C', 'Squadron Evoker', 4, 95, 99, 107.299, -0.500, 78.311, 63);
REPLACE INTO `mob_spawn_points` VALUES (17982303, 0, 'SandoriaD_Squadron_A', 'Squadron Knight', 2, 95, 99, 110.302, 0.018, 72.994, 192);
REPLACE INTO `mob_spawn_points` VALUES (17982304, 0, 'SandoriaD_Squadron_B', 'Squadron\'s Wyvern', 3, 95, 99, 139.281, -0.500, 61.133, 224);
REPLACE INTO `mob_spawn_points` VALUES (17982305, 0, 'SandoriaD_Squadron_C', 'Squadron Evoker', 4, 95, 99, 99.013, 1.956, 75.483, 103);
REPLACE INTO `mob_spawn_points` VALUES (17982306, 0, 'SandoriaD_Squadron_A', 'Squadron Knight', 2, 95, 99, 104.748, 2.457, 67.969, 31);
REPLACE INTO `mob_spawn_points` VALUES (17982307, 0, 'SandoriaD_Squadron_B', 'Squadron\'s Wyvern', 3, 95, 99, 156.344, -7.102, 52.107, 32);
REPLACE INTO `mob_spawn_points` VALUES (17982308, 0, 'SandoriaD_Squadron_C', 'Squadron Evoker', 4, 95, 99, 105.527, 3.000, 64.529, 196);
REPLACE INTO `mob_spawn_points` VALUES (17982309, 0, 'SandoriaD_Squadron_A', 'Squadron Knight', 2, 95, 99, 156.643, -7.300, 43.381, 64);
REPLACE INTO `mob_spawn_points` VALUES (17982310, 0, 'SandoriaD_Squadron_B', 'Squadron\'s Wyvern', 3, 95, 99, 156.591, -7.197, 41.199, 64);
REPLACE INTO `mob_spawn_points` VALUES (17982311, 0, 'SandoriaD_Squadron_C', 'Squadron Evoker', 4, 95, 99, 98.270, 3.499, 46.082, 53);
REPLACE INTO `mob_spawn_points` VALUES (17982312, 0, 'SandoriaD_Squadron_A', 'Squadron Knight', 2, 95, 99, 97.811, 3.500, 46.083, 200);
REPLACE INTO `mob_spawn_points` VALUES (17982313, 0, 'SandoriaD_Squadron_B', 'Squadron\'s Wyvern', 3, 95, 99, 143.339, -0.499, 28.716, 193);
REPLACE INTO `mob_spawn_points` VALUES (17982314, 0, 'SandoriaD_Squadron_C', 'Squadron Evoker', 4, 95, 99, 139.960, -0.500, 24.655, 140);
REPLACE INTO `mob_spawn_points` VALUES (17982315, 0, 'SandoriaD_Squadron_A', 'Squadron Knight', 2, 95, 99, 144.062, -0.500, 23.454, 27);
REPLACE INTO `mob_spawn_points` VALUES (17982316, 0, 'SandoriaD_Squadron_B', 'Squadron\'s Wyvern', 3, 95, 99, 100.800, 3.500, 35.756, 220);
REPLACE INTO `mob_spawn_points` VALUES (17982317, 0, 'SandoriaD_Squadron_C', 'Squadron Evoker', 4, 95, 99, 100.056, 3.500, 35.177, 114);
REPLACE INTO `mob_spawn_points` VALUES (17982318, 0, 'SandoriaD_Squadron_A', 'Squadron Knight', 2, 95, 99, 84.750, 1.500, -1.177, 52);
REPLACE INTO `mob_spawn_points` VALUES (17982319, 0, 'SandoriaD_Squadron_B', 'Squadron\'s Wyvern', 3, 95, 99, 86.604, 1.500, -4.901, 91);
REPLACE INTO `mob_spawn_points` VALUES (17982320, 0, 'SandoriaD_Squadron_C', 'Squadron Evoker', 4, 95, 99, 85.604, 1.500, -5.807, 86);
REPLACE INTO `mob_spawn_points` VALUES (17982321, 0, 'SandoriaD_Squadron_A', 'Squadron Knight', 2, 95, 99, 102.098, 1.495, -15.832, 131);
REPLACE INTO `mob_spawn_points` VALUES (17982322, 0, 'SandoriaD_Squadron_B', 'Squadron\'s Wyvern', 3, 95, 99, 109.284, 0.491, -26.162, 192);
REPLACE INTO `mob_spawn_points` VALUES (17982323, 0, 'SandoriaD_Squadron_C', 'Squadron Evoker', 4, 95, 99, 115.546, 0.483, -28.087, 6);
REPLACE INTO `mob_spawn_points` VALUES (17982324, 0, 'SandoriaD_Squadron_A', 'Squadron Knight', 2, 95, 99, 109.912, 0.500, -27.347, 187);
REPLACE INTO `mob_spawn_points` VALUES (17982325, 0, 'SandoriaD_Squadron_B', 'Squadron\'s Wyvern', 3, 95, 99, 100.921, 1.101, -25.135, 163);
REPLACE INTO `mob_spawn_points` VALUES (17982326, 0, 'SandoriaD_Squadron_C', 'Squadron Evoker', 4, 95, 99, 80.891, -7.900, -20.895, 208);
REPLACE INTO `mob_spawn_points` VALUES (17982327, 0, 'SandoriaD_Squadron_A', 'Squadron Knight', 2, 95, 99, 0.000, -2.500, 43.000, 88);
REPLACE INTO `mob_spawn_points` VALUES (17982328, 0, 'SandoriaD_Squadron_B', 'Squadron\'s Wyvern', 3, 95, 99, 96.918, 0.950, -29.808, 33);
REPLACE INTO `mob_spawn_points` VALUES (17982329, 0, 'SandoriaD_Squadron_C', 'Squadron Evoker', 4, 95, 99, -2.618, -1.838, 36.580, 254);
REPLACE INTO `mob_spawn_points` VALUES (17982330, 0, 'SandoriaD_Squadron_A', 'Squadron Knight', 2, 95, 99, 63.727, 2.000, -24.076, 90);
REPLACE INTO `mob_spawn_points` VALUES (17982331, 0, 'SandoriaD_Squadron_B', 'Squadron\'s Wyvern', 3, 95, 99, 10.946, 1.318, 12.804, 184);
REPLACE INTO `mob_spawn_points` VALUES (17982332, 0, 'SandoriaD_Squadron_C', 'Squadron Evoker', 4, 95, 99, 103.101, 0.500, -44.316, 232);
REPLACE INTO `mob_spawn_points` VALUES (17982333, 0, 'SandoriaD_Squadron_A', 'Squadron Knight', 2, 95, 99, 89.213, 0.815, -40.036, 250);
REPLACE INTO `mob_spawn_points` VALUES (17982334, 0, 'SandoriaD_Squadron_B', 'Squadron\'s Wyvern', 3, 95, 99, 79.391, 1.499, -38.816, 208);
REPLACE INTO `mob_spawn_points` VALUES (17982335, 0, 'SandoriaD_Squadron_C', 'Squadron Evoker', 4, 95, 99, 82.350, 1.499, -40.100, 87);
REPLACE INTO `mob_spawn_points` VALUES (17982336, 0, 'SandoriaD_Squadron_A', 'Squadron Knight', 2, 95, 99, 82.401, 1.500, -40.154, 79);
REPLACE INTO `mob_spawn_points` VALUES (17982337, 0, 'SandoriaD_Squadron_B', 'Squadron\'s Wyvern', 3, 95, 99, 80.791, 1.486, -41.763, 128);
REPLACE INTO `mob_spawn_points` VALUES (17982338, 0, 'SandoriaD_Squadron_C', 'Squadron Evoker', 4, 95, 99, 78.825, 1.954, -42.778, 176);
REPLACE INTO `mob_spawn_points` VALUES (17982339, 0, 'SandoriaD_Squadron_A', 'Squadron Knight', 2, 95, 99, 33.202, 1.500, -20.752, 178);
REPLACE INTO `mob_spawn_points` VALUES (17982340, 0, 'SandoriaD_Squadron_B', 'Squadron\'s Wyvern', 3, 95, 99, 35.638, 1.500, -27.701, 144);
REPLACE INTO `mob_spawn_points` VALUES (17982341, 0, 'SandoriaD_Squadron_C', 'Squadron Evoker', 4, 95, 99, 24.610, 1.500, -20.542, 186);
REPLACE INTO `mob_spawn_points` VALUES (17982342, 0, 'SandoriaD_Squadron_A', 'Squadron Knight', 2, 95, 99, 25.037, 1.500, -22.387, 223);
REPLACE INTO `mob_spawn_points` VALUES (17982343, 0, 'SandoriaD_Squadron_B', 'Squadron\'s Wyvern', 3, 95, 99, 70.814, 1.499, -51.196, 162);
REPLACE INTO `mob_spawn_points` VALUES (17982344, 0, 'SandoriaD_Squadron_C', 'Squadron Evoker', 4, 95, 99, 86.179, 0.521, -58.298, 168);
REPLACE INTO `mob_spawn_points` VALUES (17982345, 0, 'SandoriaD_Squadron_A', 'Squadron Knight', 2, 95, 99, 7.254, 1.499, -17.358, 64);
REPLACE INTO `mob_spawn_points` VALUES (17982346, 0, 'SandoriaD_Squadron_B', 'Squadron\'s Wyvern', 3, 95, 99, -16.831, 1.594, 5.726, 246);
REPLACE INTO `mob_spawn_points` VALUES (17982347, 0, 'SandoriaD_Squadron_C', 'Squadron Evoker', 4, 95, 99, -15.743, 1.599, 2.314, 22);

-- ── Statues: 10 time-extension statues spread 15-90% along corridor ──
REPLACE INTO `mob_spawn_points` VALUES (17982348, 0, 'SandoriaD_Statue', 'Corporal Tombstone', 5, 99, 99, 132.805, -1.204, 100.939, 245);
REPLACE INTO `mob_spawn_points` VALUES (17982349, 0, 'SandoriaD_Statue', 'Corporal Tombstone', 5, 99, 99, 100.815, 2.430, 71.055, 158);
REPLACE INTO `mob_spawn_points` VALUES (17982350, 0, 'SandoriaD_Statue', 'Corporal Tombstone', 5, 99, 99, 85.604, 1.500, -5.807, 86);
REPLACE INTO `mob_spawn_points` VALUES (17982351, 0, 'SandoriaD_Statue', 'Corporal Tombstone', 5, 99, 99, 79.391, 1.499, -38.816, 208);
REPLACE INTO `mob_spawn_points` VALUES (17982352, 0, 'SandoriaD_Statue', 'Corporal Tombstone', 5, 99, 99, -8.353, 1.500, -23.227, 40);
REPLACE INTO `mob_spawn_points` VALUES (17982353, 0, 'SandoriaD_Statue', 'Corporal Tombstone', 5, 99, 99, -77.463, 1.500, -1.404, 182);
REPLACE INTO `mob_spawn_points` VALUES (17982354, 0, 'SandoriaD_Statue', 'Corporal Tombstone', 5, 99, 99, -108.034, -2.500, 20.609, 227);
REPLACE INTO `mob_spawn_points` VALUES (17982355, 0, 'SandoriaD_Statue', 'Corporal Tombstone', 5, 99, 99, -149.342, -2.500, 62.827, 33);
REPLACE INTO `mob_spawn_points` VALUES (17982356, 0, 'SandoriaD_Statue', 'Corporal Tombstone', 5, 99, 99, -146.880, -2.499, 17.266, 211);
REPLACE INTO `mob_spawn_points` VALUES (17982357, 0, 'SandoriaD_Statue', 'Corporal Tombstone', 5, 99, 99, -191.374, -9.290, 25.688, 26);

-- ── Wave 2 corridor: 48 trash spread mid-boss -> mega-boss (band 55-95%) ──
REPLACE INTO `mob_spawn_points` VALUES (17982358, 0, 'SandoriaD_Regiment_A', 'Regiment Knight', 6, 97, 99, 7.760, -3.500, -32.980, 20);
REPLACE INTO `mob_spawn_points` VALUES (17982359, 0, 'SandoriaD_Regiment_B', 'Regiment\'s Wyvern', 7, 97, 99, -17.965, 1.500, -19.617, 212);
REPLACE INTO `mob_spawn_points` VALUES (17982360, 0, 'SandoriaD_Regiment_C', 'Regiment Evoker', 8, 97, 99, -17.562, 1.475, -24.666, 57);
REPLACE INTO `mob_spawn_points` VALUES (17982361, 0, 'SandoriaD_Regiment_A', 'Regiment Knight', 6, 97, 99, -16.663, 1.245, -28.637, 58);
REPLACE INTO `mob_spawn_points` VALUES (17982362, 0, 'SandoriaD_Regiment_B', 'Regiment\'s Wyvern', 7, 97, 99, -38.727, 1.500, -12.372, 157);
REPLACE INTO `mob_spawn_points` VALUES (17982363, 0, 'SandoriaD_Regiment_C', 'Regiment Evoker', 8, 97, 99, -88.518, -6.494, 61.069, 166);
REPLACE INTO `mob_spawn_points` VALUES (17982364, 0, 'SandoriaD_Regiment_A', 'Regiment Knight', 6, 97, 99, -91.414, -6.499, 59.515, 72);
REPLACE INTO `mob_spawn_points` VALUES (17982365, 0, 'SandoriaD_Regiment_B', 'Regiment\'s Wyvern', 7, 97, 99, 5.121, 1.500, -71.234, 167);
REPLACE INTO `mob_spawn_points` VALUES (17982366, 0, 'SandoriaD_Regiment_C', 'Regiment Evoker', 8, 97, 99, 9.552, 1.500, -77.217, 25);
REPLACE INTO `mob_spawn_points` VALUES (17982367, 0, 'SandoriaD_Regiment_A', 'Regiment Knight', 6, 97, 99, -72.585, 1.500, -6.376, 238);
REPLACE INTO `mob_spawn_points` VALUES (17982368, 0, 'SandoriaD_Regiment_B', 'Regiment\'s Wyvern', 7, 97, 99, -9.296, 1.500, -72.505, 244);
REPLACE INTO `mob_spawn_points` VALUES (17982369, 0, 'SandoriaD_Regiment_C', 'Regiment Evoker', 8, 97, 99, -16.860, 1.500, -70.267, 244);
REPLACE INTO `mob_spawn_points` VALUES (17982370, 0, 'SandoriaD_Regiment_A', 'Regiment Knight', 6, 97, 99, -9.963, 1.500, -76.020, 204);
REPLACE INTO `mob_spawn_points` VALUES (17982371, 0, 'SandoriaD_Regiment_B', 'Regiment\'s Wyvern', 7, 97, 99, -82.735, 1.500, -1.439, 5);
REPLACE INTO `mob_spawn_points` VALUES (17982372, 0, 'SandoriaD_Regiment_C', 'Regiment Evoker', 8, 97, 99, -99.688, -2.500, 23.889, 110);
REPLACE INTO `mob_spawn_points` VALUES (17982373, 0, 'SandoriaD_Regiment_A', 'Regiment Knight', 6, 97, 99, -128.843, -6.499, 91.490, 184);
REPLACE INTO `mob_spawn_points` VALUES (17982374, 0, 'SandoriaD_Regiment_B', 'Regiment\'s Wyvern', 7, 97, 99, -107.596, -2.500, 26.199, 132);
REPLACE INTO `mob_spawn_points` VALUES (17982375, 0, 'SandoriaD_Regiment_C', 'Regiment Evoker', 8, 97, 99, -18.843, 1.784, -80.856, 221);
REPLACE INTO `mob_spawn_points` VALUES (17982376, 0, 'SandoriaD_Regiment_A', 'Regiment Knight', 6, 97, 99, -82.023, -7.900, -17.974, 30);
REPLACE INTO `mob_spawn_points` VALUES (17982377, 0, 'SandoriaD_Regiment_B', 'Regiment\'s Wyvern', 7, 97, 99, -17.314, 1.500, -85.458, 90);
REPLACE INTO `mob_spawn_points` VALUES (17982378, 0, 'SandoriaD_Regiment_C', 'Regiment Evoker', 8, 97, 99, -139.516, -6.500, 91.338, 70);
REPLACE INTO `mob_spawn_points` VALUES (17982379, 0, 'SandoriaD_Regiment_A', 'Regiment Knight', 6, 97, 99, -29.038, 1.500, -85.065, 72);
REPLACE INTO `mob_spawn_points` VALUES (17982380, 0, 'SandoriaD_Regiment_B', 'Regiment\'s Wyvern', 7, 97, 99, -84.391, 1.500, -37.608, 169);
REPLACE INTO `mob_spawn_points` VALUES (17982381, 0, 'SandoriaD_Regiment_C', 'Regiment Evoker', 8, 97, 99, -78.370, 1.439, -49.927, 219);
REPLACE INTO `mob_spawn_points` VALUES (17982382, 0, 'SandoriaD_Regiment_A', 'Regiment Knight', 6, 97, 99, -99.430, 1.349, -23.604, 161);
REPLACE INTO `mob_spawn_points` VALUES (17982383, 0, 'SandoriaD_Regiment_B', 'Regiment\'s Wyvern', 7, 97, 99, -102.198, 1.491, -22.293, 151);
REPLACE INTO `mob_spawn_points` VALUES (17982384, 0, 'SandoriaD_Regiment_C', 'Regiment Evoker', 8, 97, 99, -83.250, 0.779, -49.537, 28);
REPLACE INTO `mob_spawn_points` VALUES (17982385, 0, 'SandoriaD_Regiment_A', 'Regiment Knight', 6, 97, 99, -97.009, 0.500, -35.325, 105);
REPLACE INTO `mob_spawn_points` VALUES (17982386, 0, 'SandoriaD_Regiment_B', 'Regiment\'s Wyvern', 7, 97, 99, -149.342, -2.500, 62.827, 33);
REPLACE INTO `mob_spawn_points` VALUES (17982387, 0, 'SandoriaD_Regiment_C', 'Regiment Evoker', 8, 97, 99, -154.256, -2.500, 66.927, 174);
REPLACE INTO `mob_spawn_points` VALUES (17982388, 0, 'SandoriaD_Regiment_A', 'Regiment Knight', 6, 97, 99, -106.786, 0.500, -32.995, 61);
REPLACE INTO `mob_spawn_points` VALUES (17982389, 0, 'SandoriaD_Regiment_B', 'Regiment\'s Wyvern', 7, 97, 99, -156.529, -2.500, 62.659, 99);
REPLACE INTO `mob_spawn_points` VALUES (17982390, 0, 'SandoriaD_Regiment_C', 'Regiment Evoker', 8, 97, 99, -110.732, 0.500, -31.437, 82);
REPLACE INTO `mob_spawn_points` VALUES (17982391, 0, 'SandoriaD_Regiment_A', 'Regiment Knight', 6, 97, 99, -159.564, -2.500, 62.312, 23);
REPLACE INTO `mob_spawn_points` VALUES (17982392, 0, 'SandoriaD_Regiment_B', 'Regiment\'s Wyvern', 7, 97, 99, -158.708, -2.500, 58.594, 43);
REPLACE INTO `mob_spawn_points` VALUES (17982393, 0, 'SandoriaD_Regiment_C', 'Regiment Evoker', 8, 97, 99, -111.594, 0.500, -35.298, 146);
REPLACE INTO `mob_spawn_points` VALUES (17982394, 0, 'SandoriaD_Regiment_A', 'Regiment Knight', 6, 97, 99, -115.615, 0.500, -30.507, 149);
REPLACE INTO `mob_spawn_points` VALUES (17982395, 0, 'SandoriaD_Regiment_B', 'Regiment\'s Wyvern', 7, 97, 99, -146.880, -2.499, 17.266, 211);
REPLACE INTO `mob_spawn_points` VALUES (17982396, 0, 'SandoriaD_Regiment_C', 'Regiment Evoker', 8, 97, 99, -147.749, -2.499, 14.696, 241);
REPLACE INTO `mob_spawn_points` VALUES (17982397, 0, 'SandoriaD_Regiment_A', 'Regiment Knight', 6, 97, 99, -159.068, -1.500, 16.968, 11);
REPLACE INTO `mob_spawn_points` VALUES (17982398, 0, 'SandoriaD_Regiment_B', 'Regiment\'s Wyvern', 7, 97, 99, -175.571, -1.500, 26.289, 174);
REPLACE INTO `mob_spawn_points` VALUES (17982399, 0, 'SandoriaD_Regiment_C', 'Regiment Evoker', 8, 97, 99, -180.315, -1.500, 32.838, 6);
REPLACE INTO `mob_spawn_points` VALUES (17982400, 0, 'SandoriaD_Regiment_A', 'Regiment Knight', 6, 97, 99, -194.942, -2.498, 70.551, 221);
REPLACE INTO `mob_spawn_points` VALUES (17982401, 0, 'SandoriaD_Regiment_B', 'Regiment\'s Wyvern', 7, 97, 99, -199.176, -2.500, 76.942, 141);
REPLACE INTO `mob_spawn_points` VALUES (17982402, 0, 'SandoriaD_Regiment_C', 'Regiment Evoker', 8, 97, 99, -185.930, -9.300, 29.037, 181);
REPLACE INTO `mob_spawn_points` VALUES (17982403, 0, 'SandoriaD_Regiment_A', 'Regiment Knight', 6, 97, 99, -186.659, -9.300, 24.944, 220);
REPLACE INTO `mob_spawn_points` VALUES (17982404, 0, 'SandoriaD_Regiment_B', 'Regiment\'s Wyvern', 7, 97, 99, -195.864, -1.500, 46.667, 143);
REPLACE INTO `mob_spawn_points` VALUES (17982405, 0, 'SandoriaD_Regiment_C', 'Regiment Evoker', 8, 97, 99, -253.318, -4.099, 113.539, 12);

-- ── Bosses (registered slots at corridor midpoint / far end) ──
REPLACE INTO `mob_spawn_points` VALUES (17981770, 0, 'Overseers_Tombstone', 'Overseer\'s Tombstone', 1, 99, 99, 78.825, 1.954, -42.778, 176);
REPLACE INTO `mob_spawn_points` VALUES (17982112, 0, 'Halphas', 'Halphas', 9, 99, 99, -270.042, -6.655, 98.578, 24);
REPLACE INTO `mob_spawn_points` VALUES (17982238, 0, 'Disjoined_Elvaan_D', 'Disjoined Elvaan', 10, 99, 99, -277.958, -6.741, 97.422, 24);

-- ── instance_entities: register all 109 mobs ──
DELETE FROM `instance_entities` WHERE `instanceid` = 29400;
REPLACE INTO `instance_entities` VALUES (29400, 17982300);
REPLACE INTO `instance_entities` VALUES (29400, 17982301);
REPLACE INTO `instance_entities` VALUES (29400, 17982302);
REPLACE INTO `instance_entities` VALUES (29400, 17982303);
REPLACE INTO `instance_entities` VALUES (29400, 17982304);
REPLACE INTO `instance_entities` VALUES (29400, 17982305);
REPLACE INTO `instance_entities` VALUES (29400, 17982306);
REPLACE INTO `instance_entities` VALUES (29400, 17982307);
REPLACE INTO `instance_entities` VALUES (29400, 17982308);
REPLACE INTO `instance_entities` VALUES (29400, 17982309);
REPLACE INTO `instance_entities` VALUES (29400, 17982310);
REPLACE INTO `instance_entities` VALUES (29400, 17982311);
REPLACE INTO `instance_entities` VALUES (29400, 17982312);
REPLACE INTO `instance_entities` VALUES (29400, 17982313);
REPLACE INTO `instance_entities` VALUES (29400, 17982314);
REPLACE INTO `instance_entities` VALUES (29400, 17982315);
REPLACE INTO `instance_entities` VALUES (29400, 17982316);
REPLACE INTO `instance_entities` VALUES (29400, 17982317);
REPLACE INTO `instance_entities` VALUES (29400, 17982318);
REPLACE INTO `instance_entities` VALUES (29400, 17982319);
REPLACE INTO `instance_entities` VALUES (29400, 17982320);
REPLACE INTO `instance_entities` VALUES (29400, 17982321);
REPLACE INTO `instance_entities` VALUES (29400, 17982322);
REPLACE INTO `instance_entities` VALUES (29400, 17982323);
REPLACE INTO `instance_entities` VALUES (29400, 17982324);
REPLACE INTO `instance_entities` VALUES (29400, 17982325);
REPLACE INTO `instance_entities` VALUES (29400, 17982326);
REPLACE INTO `instance_entities` VALUES (29400, 17982327);
REPLACE INTO `instance_entities` VALUES (29400, 17982328);
REPLACE INTO `instance_entities` VALUES (29400, 17982329);
REPLACE INTO `instance_entities` VALUES (29400, 17982330);
REPLACE INTO `instance_entities` VALUES (29400, 17982331);
REPLACE INTO `instance_entities` VALUES (29400, 17982332);
REPLACE INTO `instance_entities` VALUES (29400, 17982333);
REPLACE INTO `instance_entities` VALUES (29400, 17982334);
REPLACE INTO `instance_entities` VALUES (29400, 17982335);
REPLACE INTO `instance_entities` VALUES (29400, 17982336);
REPLACE INTO `instance_entities` VALUES (29400, 17982337);
REPLACE INTO `instance_entities` VALUES (29400, 17982338);
REPLACE INTO `instance_entities` VALUES (29400, 17982339);
REPLACE INTO `instance_entities` VALUES (29400, 17982340);
REPLACE INTO `instance_entities` VALUES (29400, 17982341);
REPLACE INTO `instance_entities` VALUES (29400, 17982342);
REPLACE INTO `instance_entities` VALUES (29400, 17982343);
REPLACE INTO `instance_entities` VALUES (29400, 17982344);
REPLACE INTO `instance_entities` VALUES (29400, 17982345);
REPLACE INTO `instance_entities` VALUES (29400, 17982346);
REPLACE INTO `instance_entities` VALUES (29400, 17982347);
REPLACE INTO `instance_entities` VALUES (29400, 17982348);
REPLACE INTO `instance_entities` VALUES (29400, 17982349);
REPLACE INTO `instance_entities` VALUES (29400, 17982350);
REPLACE INTO `instance_entities` VALUES (29400, 17982351);
REPLACE INTO `instance_entities` VALUES (29400, 17982352);
REPLACE INTO `instance_entities` VALUES (29400, 17982353);
REPLACE INTO `instance_entities` VALUES (29400, 17982354);
REPLACE INTO `instance_entities` VALUES (29400, 17982355);
REPLACE INTO `instance_entities` VALUES (29400, 17982356);
REPLACE INTO `instance_entities` VALUES (29400, 17982357);
REPLACE INTO `instance_entities` VALUES (29400, 17982358);
REPLACE INTO `instance_entities` VALUES (29400, 17982359);
REPLACE INTO `instance_entities` VALUES (29400, 17982360);
REPLACE INTO `instance_entities` VALUES (29400, 17982361);
REPLACE INTO `instance_entities` VALUES (29400, 17982362);
REPLACE INTO `instance_entities` VALUES (29400, 17982363);
REPLACE INTO `instance_entities` VALUES (29400, 17982364);
REPLACE INTO `instance_entities` VALUES (29400, 17982365);
REPLACE INTO `instance_entities` VALUES (29400, 17982366);
REPLACE INTO `instance_entities` VALUES (29400, 17982367);
REPLACE INTO `instance_entities` VALUES (29400, 17982368);
REPLACE INTO `instance_entities` VALUES (29400, 17982369);
REPLACE INTO `instance_entities` VALUES (29400, 17982370);
REPLACE INTO `instance_entities` VALUES (29400, 17982371);
REPLACE INTO `instance_entities` VALUES (29400, 17982372);
REPLACE INTO `instance_entities` VALUES (29400, 17982373);
REPLACE INTO `instance_entities` VALUES (29400, 17982374);
REPLACE INTO `instance_entities` VALUES (29400, 17982375);
REPLACE INTO `instance_entities` VALUES (29400, 17982376);
REPLACE INTO `instance_entities` VALUES (29400, 17982377);
REPLACE INTO `instance_entities` VALUES (29400, 17982378);
REPLACE INTO `instance_entities` VALUES (29400, 17982379);
REPLACE INTO `instance_entities` VALUES (29400, 17982380);
REPLACE INTO `instance_entities` VALUES (29400, 17982381);
REPLACE INTO `instance_entities` VALUES (29400, 17982382);
REPLACE INTO `instance_entities` VALUES (29400, 17982383);
REPLACE INTO `instance_entities` VALUES (29400, 17982384);
REPLACE INTO `instance_entities` VALUES (29400, 17982385);
REPLACE INTO `instance_entities` VALUES (29400, 17982386);
REPLACE INTO `instance_entities` VALUES (29400, 17982387);
REPLACE INTO `instance_entities` VALUES (29400, 17982388);
REPLACE INTO `instance_entities` VALUES (29400, 17982389);
REPLACE INTO `instance_entities` VALUES (29400, 17982390);
REPLACE INTO `instance_entities` VALUES (29400, 17982391);
REPLACE INTO `instance_entities` VALUES (29400, 17982392);
REPLACE INTO `instance_entities` VALUES (29400, 17982393);
REPLACE INTO `instance_entities` VALUES (29400, 17982394);
REPLACE INTO `instance_entities` VALUES (29400, 17982395);
REPLACE INTO `instance_entities` VALUES (29400, 17982396);
REPLACE INTO `instance_entities` VALUES (29400, 17982397);
REPLACE INTO `instance_entities` VALUES (29400, 17982398);
REPLACE INTO `instance_entities` VALUES (29400, 17982399);
REPLACE INTO `instance_entities` VALUES (29400, 17982400);
REPLACE INTO `instance_entities` VALUES (29400, 17982401);
REPLACE INTO `instance_entities` VALUES (29400, 17982402);
REPLACE INTO `instance_entities` VALUES (29400, 17982403);
REPLACE INTO `instance_entities` VALUES (29400, 17982404);
REPLACE INTO `instance_entities` VALUES (29400, 17982405);
REPLACE INTO `instance_entities` VALUES (29400, 17981770);
REPLACE INTO `instance_entities` VALUES (29400, 17982112);
REPLACE INTO `instance_entities` VALUES (29400, 17982238);

-- ── instance_list (unchanged) ──
REPLACE INTO `instance_list` VALUES (29400, 'dynamis_san_doria_d', 294, 230, 90, 161.838, -2.000, 161.673, 93, NULL, NULL, NULL, NULL);

-- ── mob_droplist (unchanged) ──
DELETE FROM `mob_droplist` WHERE `dropId` IN (29401, 29402, 29403, 29404);
INSERT INTO `mob_droplist` VALUES (29401, 0, 0, 1000, 9539, @ALWAYS);
INSERT INTO `mob_droplist` VALUES (29401, 0, 0, 1000, 9539, @COMMON);
INSERT INTO `mob_droplist` VALUES (29402, 0, 0, 1000, 9539, @UNCOMMON);
INSERT INTO `mob_droplist` VALUES (29403, 0, 0, 1000, 9541, @UNCOMMON);
INSERT INTO `mob_droplist` VALUES (29404, 0, 0, 1000, 9541, @ALWAYS);
INSERT INTO `mob_droplist` VALUES (29404, 0, 0, 1000, 9541, @COMMON);
INSERT INTO `mob_droplist` VALUES (29404, 0, 0, 1000, 9543, @UNCOMMON);

-- ============================================================================
-- Bastok [D] (zone 295, instance 29500) -- Quadav, unlocks HANDS. mobid base 17985536.
-- Reuses zone-186 Vanguard Quadav pools; coords from retail Dynamis-Bastok stock spawns.
-- ============================================================================

-- ── mob_groups (unchanged: retail Vanguard family pools) ──
REPLACE INTO `mob_groups` VALUES (1, 1855, 295, 'MushaEffigy_BastokD', 0, 128, 29501, 35000, 1000, 0, NULL);
REPLACE INTO `mob_groups` VALUES (2, 4197, 295, 'BastokD_Squadron_A',  0, 128, 29502,  8000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (3, 4163, 295, 'BastokD_Squadron_B',  0, 128, 29502,  8000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (4, 4139, 295, 'BastokD_Squadron_C',  0, 128, 29502,  8000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (5, 3548, 295, 'BastokD_Statue',      0, 128,     0,  6000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (6, 4177, 295, 'BastokD_Regiment_A',  0, 128, 29503, 11000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (7, 4178, 295, 'BastokD_Regiment_B',  0, 128, 29503, 11000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (8, 4191, 295, 'BastokD_Regiment_C',  0, 128, 29503, 11000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (9, 1859, 295, 'KaRhoFearsinger',     0, 128, 29504, 70000, 2000, 0, NULL);

-- ── mob_spawn_points: corridor pass ──
DELETE FROM `mob_spawn_points` WHERE `mobid` BETWEEN 17985536 AND 17989631;
-- ── Wave 1 corridor: 48 trash spread entry -> mid-boss (band 20-55%) ──

-- REPACK 2026-07-13: purge the old out-of-boundary corridor rows (mobids 17986500..17986605 were past zoneMin+1024).
DELETE FROM `mob_spawn_points`   WHERE mobid   BETWEEN 17986500 AND 17986605;
DELETE FROM `instance_entities`  WHERE id      BETWEEN 17986500 AND 17986605;
REPLACE INTO `mob_spawn_points` VALUES (17986400, 0, 'BastokD_Squadron_A', 'Squadron Weaponmaster', 2, 95, 99, 71.326, 6.500, -29.040, 247);
REPLACE INTO `mob_spawn_points` VALUES (17986401, 0, 'BastokD_Squadron_B', 'Squadron\'s Avatar', 3, 95, 99, 49.144, -0.500, -72.117, 115);
REPLACE INTO `mob_spawn_points` VALUES (17986402, 0, 'BastokD_Squadron_C', 'Squadron Magician', 4, 95, 99, 86.753, 6.500, -1.397, 160);
REPLACE INTO `mob_spawn_points` VALUES (17986403, 0, 'BastokD_Squadron_A', 'Squadron Weaponmaster', 2, 95, 99, 59.668, -0.500, -17.649, 25);
REPLACE INTO `mob_spawn_points` VALUES (17986404, 0, 'BastokD_Squadron_B', 'Squadron\'s Avatar', 3, 95, 99, 40.444, -0.500, -47.574, 32);
REPLACE INTO `mob_spawn_points` VALUES (17986405, 0, 'BastokD_Squadron_C', 'Squadron Magician', 4, 95, 99, 67.427, 6.500, -6.995, 125);
REPLACE INTO `mob_spawn_points` VALUES (17986406, 0, 'BastokD_Squadron_A', 'Squadron Weaponmaster', 2, 95, 99, 91.224, -0.500, 6.704, 24);
REPLACE INTO `mob_spawn_points` VALUES (17986407, 0, 'BastokD_Squadron_B', 'Squadron\'s Avatar', 3, 95, 99, 65.522, 6.500, -6.398, 25);
REPLACE INTO `mob_spawn_points` VALUES (17986408, 0, 'BastokD_Squadron_C', 'Squadron Magician', 4, 95, 99, 31.283, -1.155, -84.309, 203);
REPLACE INTO `mob_spawn_points` VALUES (17986409, 0, 'BastokD_Squadron_A', 'Squadron Weaponmaster', 2, 95, 99, 29.913, -0.499, -63.533, 137);
REPLACE INTO `mob_spawn_points` VALUES (17986410, 0, 'BastokD_Squadron_B', 'Squadron\'s Avatar', 3, 95, 99, 67.354, 6.500, 0.666, 6);
REPLACE INTO `mob_spawn_points` VALUES (17986411, 0, 'BastokD_Squadron_C', 'Squadron Magician', 4, 95, 99, 78.922, -0.500, 8.583, 128);
REPLACE INTO `mob_spawn_points` VALUES (17986412, 0, 'BastokD_Squadron_A', 'Squadron Weaponmaster', 2, 95, 99, 51.506, 6.399, -1.653, 98);
REPLACE INTO `mob_spawn_points` VALUES (17986413, 0, 'BastokD_Squadron_B', 'Squadron\'s Avatar', 3, 95, 99, 15.421, -0.500, -81.002, 241);
REPLACE INTO `mob_spawn_points` VALUES (17986414, 0, 'BastokD_Squadron_C', 'Squadron Magician', 4, 95, 99, 14.365, -3.499, -59.726, 121);
REPLACE INTO `mob_spawn_points` VALUES (17986415, 0, 'BastokD_Squadron_A', 'Squadron Weaponmaster', 2, 95, 99, 41.854, -0.500, 7.997, 3);
REPLACE INTO `mob_spawn_points` VALUES (17986416, 0, 'BastokD_Squadron_B', 'Squadron\'s Avatar', 3, 95, 99, 25.051, 6.500, -6.374, 96);
REPLACE INTO `mob_spawn_points` VALUES (17986417, 0, 'BastokD_Squadron_C', 'Squadron Magician', 4, 95, 99, 2.199, -3.370, -64.131, 219);
REPLACE INTO `mob_spawn_points` VALUES (17986418, 0, 'BastokD_Squadron_A', 'Squadron Weaponmaster', 2, 95, 99, 23.512, 6.500, -2.799, 104);
REPLACE INTO `mob_spawn_points` VALUES (17986419, 0, 'BastokD_Squadron_B', 'Squadron\'s Avatar', 3, 95, 99, 8.490, -0.500, -24.093, 128);
REPLACE INTO `mob_spawn_points` VALUES (17986420, 0, 'BastokD_Squadron_C', 'Squadron Magician', 4, 95, 99, 17.478, 6.500, -5.124, 123);
REPLACE INTO `mob_spawn_points` VALUES (17986421, 0, 'BastokD_Squadron_A', 'Squadron Weaponmaster', 2, 95, 99, 30.380, 5.343, 11.809, 64);
REPLACE INTO `mob_spawn_points` VALUES (17986422, 0, 'BastokD_Squadron_B', 'Squadron\'s Avatar', 3, 95, 99, 4.663, -0.500, -24.165, 0);
REPLACE INTO `mob_spawn_points` VALUES (17986423, 0, 'BastokD_Squadron_C', 'Squadron Magician', 4, 95, 99, 15.875, 6.500, -0.761, 245);
REPLACE INTO `mob_spawn_points` VALUES (17986424, 0, 'BastokD_Squadron_A', 'Squadron Weaponmaster', 2, 95, 99, -8.208, -0.500, -77.431, 235);
REPLACE INTO `mob_spawn_points` VALUES (17986425, 0, 'BastokD_Squadron_B', 'Squadron\'s Avatar', 3, 95, 99, 34.862, 0.000, 22.937, 248);
REPLACE INTO `mob_spawn_points` VALUES (17986426, 0, 'BastokD_Squadron_C', 'Squadron Magician', 4, 95, 99, 9.427, -0.500, -5.045, 63);
REPLACE INTO `mob_spawn_points` VALUES (17986427, 0, 'BastokD_Squadron_A', 'Squadron Weaponmaster', 2, 95, 99, 11.362, -0.500, 2.981, 101);
REPLACE INTO `mob_spawn_points` VALUES (17986428, 0, 'BastokD_Squadron_B', 'Squadron\'s Avatar', 3, 95, 99, 9.073, -0.500, 0.785, 193);
REPLACE INTO `mob_spawn_points` VALUES (17986429, 0, 'BastokD_Squadron_C', 'Squadron Magician', 4, 95, 99, 7.746, -0.066, 3.135, 53);
REPLACE INTO `mob_spawn_points` VALUES (17986430, 0, 'BastokD_Squadron_A', 'Squadron Weaponmaster', 2, 95, 99, 2.053, 6.500, -1.791, 2);
REPLACE INTO `mob_spawn_points` VALUES (17986431, 0, 'BastokD_Squadron_B', 'Squadron\'s Avatar', 3, 95, 99, -19.315, -0.500, -77.140, 181);
REPLACE INTO `mob_spawn_points` VALUES (17986432, 0, 'BastokD_Squadron_C', 'Squadron Magician', 4, 95, 99, -6.048, -0.500, -6.941, 62);
REPLACE INTO `mob_spawn_points` VALUES (17986433, 0, 'BastokD_Squadron_A', 'Squadron Weaponmaster', 2, 95, 99, 8.730, -0.500, 16.593, 62);
REPLACE INTO `mob_spawn_points` VALUES (17986434, 0, 'BastokD_Squadron_B', 'Squadron\'s Avatar', 3, 95, 99, -25.232, -0.303, -80.729, 120);
REPLACE INTO `mob_spawn_points` VALUES (17986435, 0, 'BastokD_Squadron_C', 'Squadron Magician', 4, 95, 99, -16.149, -2.000, -130.500, 147);
REPLACE INTO `mob_spawn_points` VALUES (17986436, 0, 'BastokD_Squadron_A', 'Squadron Weaponmaster', 2, 95, 99, 3.814, 6.500, 24.002, 43);
REPLACE INTO `mob_spawn_points` VALUES (17986437, 0, 'BastokD_Squadron_B', 'Squadron\'s Avatar', 3, 95, 99, -0.731, 6.500, 21.482, 165);
REPLACE INTO `mob_spawn_points` VALUES (17986438, 0, 'BastokD_Squadron_C', 'Squadron Magician', 4, 95, 99, 1.353, 6.651, 28.012, 106);
REPLACE INTO `mob_spawn_points` VALUES (17986439, 0, 'BastokD_Squadron_A', 'Squadron Weaponmaster', 2, 95, 99, -38.162, -0.500, -62.945, 5);
REPLACE INTO `mob_spawn_points` VALUES (17986440, 0, 'BastokD_Squadron_B', 'Squadron\'s Avatar', 3, 95, 99, -38.715, -0.500, -51.344, 176);
REPLACE INTO `mob_spawn_points` VALUES (17986441, 0, 'BastokD_Squadron_C', 'Squadron Magician', 4, 95, 99, -38.465, -0.500, -43.297, 83);
REPLACE INTO `mob_spawn_points` VALUES (17986442, 0, 'BastokD_Squadron_A', 'Squadron Weaponmaster', 2, 95, 99, -40.789, -0.500, -47.628, 89);
REPLACE INTO `mob_spawn_points` VALUES (17986443, 0, 'BastokD_Squadron_B', 'Squadron\'s Avatar', 3, 95, 99, -17.605, -0.500, 23.406, 136);
REPLACE INTO `mob_spawn_points` VALUES (17986444, 0, 'BastokD_Squadron_C', 'Squadron Magician', 4, 95, 99, -16.910, 6.500, 28.500, 50);
REPLACE INTO `mob_spawn_points` VALUES (17986445, 0, 'BastokD_Squadron_A', 'Squadron Weaponmaster', 2, 95, 99, -51.935, -8.500, -70.675, 199);
REPLACE INTO `mob_spawn_points` VALUES (17986446, 0, 'BastokD_Squadron_B', 'Squadron\'s Avatar', 3, 95, 99, -17.632, 6.500, 31.270, 57);
REPLACE INTO `mob_spawn_points` VALUES (17986447, 0, 'BastokD_Squadron_C', 'Squadron Magician', 4, 95, 99, -20.675, 6.500, 28.194, 187);

-- ── Statues: 10 time-extension statues spread 15-90% along corridor ──
REPLACE INTO `mob_spawn_points` VALUES (17986448, 0, 'BastokD_Statue', 'Lithicthrower Image', 5, 99, 99, 68.147, -0.362, -78.017, 36);
REPLACE INTO `mob_spawn_points` VALUES (17986449, 0, 'BastokD_Statue', 'Lithicthrower Image', 5, 99, 99, 60.294, -0.500, -15.040, 192);
REPLACE INTO `mob_spawn_points` VALUES (17986450, 0, 'BastokD_Statue', 'Lithicthrower Image', 5, 99, 99, 15.421, -0.500, -81.002, 241);
REPLACE INTO `mob_spawn_points` VALUES (17986451, 0, 'BastokD_Statue', 'Lithicthrower Image', 5, 99, 99, -4.255, -0.500, -79.221, 161);
REPLACE INTO `mob_spawn_points` VALUES (17986452, 0, 'BastokD_Statue', 'Lithicthrower Image', 5, 99, 99, 8.263, -0.157, 8.389, 49);
REPLACE INTO `mob_spawn_points` VALUES (17986453, 0, 'BastokD_Statue', 'Lithicthrower Image', 5, 99, 99, -36.413, -0.500, -61.870, 47);
REPLACE INTO `mob_spawn_points` VALUES (17986454, 0, 'BastokD_Statue', 'Lithicthrower Image', 5, 99, 99, -20.675, 6.500, 28.194, 187);
REPLACE INTO `mob_spawn_points` VALUES (17986455, 0, 'BastokD_Statue', 'Lithicthrower Image', 5, 99, 99, -82.389, 0.151, -4.340, 10);
REPLACE INTO `mob_spawn_points` VALUES (17986456, 0, 'BastokD_Statue', 'Lithicthrower Image', 5, 99, 99, -104.397, 7.216, 47.481, 67);
REPLACE INTO `mob_spawn_points` VALUES (17986457, 0, 'BastokD_Statue', 'Lithicthrower Image', 5, 99, 99, -155.074, -0.543, -18.459, 19);

-- ── Wave 2 corridor: 48 trash spread mid-boss -> mega-boss (band 55-95%) ──
REPLACE INTO `mob_spawn_points` VALUES (17986458, 0, 'BastokD_Regiment_A', 'Regiment Weaponmaster', 6, 97, 99, -13.875, -0.500, 38.749, 87);
REPLACE INTO `mob_spawn_points` VALUES (17986459, 0, 'BastokD_Regiment_B', 'Regiment\'s Avatar', 7, 97, 99, -15.178, -0.018, 39.101, 75);
REPLACE INTO `mob_spawn_points` VALUES (17986460, 0, 'BastokD_Regiment_C', 'Regiment Magician', 8, 97, 99, -56.741, -8.500, -57.299, 153);
REPLACE INTO `mob_spawn_points` VALUES (17986461, 0, 'BastokD_Regiment_A', 'Regiment Weaponmaster', 6, 97, 99, -58.887, -8.506, -63.955, 17);
REPLACE INTO `mob_spawn_points` VALUES (17986462, 0, 'BastokD_Regiment_B', 'Regiment\'s Avatar', 7, 97, 99, -59.433, -8.544, -66.659, 184);
REPLACE INTO `mob_spawn_points` VALUES (17986463, 0, 'BastokD_Regiment_C', 'Regiment Magician', 8, 97, 99, -56.600, -0.500, -9.896, 254);
REPLACE INTO `mob_spawn_points` VALUES (17986464, 0, 'BastokD_Regiment_A', 'Regiment Weaponmaster', 6, 97, 99, -51.100, -0.500, 7.706, 11);
REPLACE INTO `mob_spawn_points` VALUES (17986465, 0, 'BastokD_Regiment_B', 'Regiment\'s Avatar', 7, 97, 99, -49.959, -0.500, 11.644, 70);
REPLACE INTO `mob_spawn_points` VALUES (17986466, 0, 'BastokD_Regiment_C', 'Regiment Magician', 8, 97, 99, -57.343, -0.500, 2.341, 108);
REPLACE INTO `mob_spawn_points` VALUES (17986467, 0, 'BastokD_Regiment_A', 'Regiment Weaponmaster', 6, 97, 99, -56.834, -0.500, 11.244, 135);
REPLACE INTO `mob_spawn_points` VALUES (17986468, 0, 'BastokD_Regiment_B', 'Regiment\'s Avatar', 7, 97, 99, -62.898, -0.500, 5.906, 160);
REPLACE INTO `mob_spawn_points` VALUES (17986469, 0, 'BastokD_Regiment_C', 'Regiment Magician', 8, 97, 99, -47.615, -0.500, 38.928, 194);
REPLACE INTO `mob_spawn_points` VALUES (17986470, 0, 'BastokD_Regiment_A', 'Regiment Weaponmaster', 6, 97, 99, -52.027, -0.499, 36.924, 69);
REPLACE INTO `mob_spawn_points` VALUES (17986471, 0, 'BastokD_Regiment_B', 'Regiment\'s Avatar', 7, 97, 99, -81.217, -0.500, -4.778, 237);
REPLACE INTO `mob_spawn_points` VALUES (17986472, 0, 'BastokD_Regiment_C', 'Regiment Magician', 8, 97, 99, -82.531, -0.068, -5.206, 25);
REPLACE INTO `mob_spawn_points` VALUES (17986473, 0, 'BastokD_Regiment_A', 'Regiment Weaponmaster', 6, 97, 99, -82.389, 0.151, -4.340, 10);
REPLACE INTO `mob_spawn_points` VALUES (17986474, 0, 'BastokD_Regiment_B', 'Regiment\'s Avatar', 7, 97, 99, -83.391, -0.500, -4.250, 28);
REPLACE INTO `mob_spawn_points` VALUES (17986475, 0, 'BastokD_Regiment_C', 'Regiment Magician', 8, 97, 99, -89.843, -0.500, -3.790, 209);
REPLACE INTO `mob_spawn_points` VALUES (17986476, 0, 'BastokD_Regiment_A', 'Regiment Weaponmaster', 6, 97, 99, -109.066, -8.464, -59.580, 64);
REPLACE INTO `mob_spawn_points` VALUES (17986477, 0, 'BastokD_Regiment_B', 'Regiment\'s Avatar', 7, 97, 99, -109.290, -8.622, -59.401, 64);
REPLACE INTO `mob_spawn_points` VALUES (17986478, 0, 'BastokD_Regiment_C', 'Regiment Magician', 8, 97, 99, -101.219, -0.500, -8.639, 39);
REPLACE INTO `mob_spawn_points` VALUES (17986479, 0, 'BastokD_Regiment_A', 'Regiment Weaponmaster', 6, 97, 99, -105.290, -0.251, -9.147, 32);
REPLACE INTO `mob_spawn_points` VALUES (17986480, 0, 'BastokD_Regiment_B', 'Regiment\'s Avatar', 7, 97, 99, -112.600, -0.842, -38.962, 240);
REPLACE INTO `mob_spawn_points` VALUES (17986481, 0, 'BastokD_Regiment_C', 'Regiment Magician', 8, 97, 99, -118.128, -0.500, -49.878, 177);
REPLACE INTO `mob_spawn_points` VALUES (17986482, 0, 'BastokD_Regiment_A', 'Regiment Weaponmaster', 6, 97, 99, -125.110, -0.500, -40.652, 226);
REPLACE INTO `mob_spawn_points` VALUES (17986483, 0, 'BastokD_Regiment_B', 'Regiment\'s Avatar', 7, 97, 99, -126.727, -0.500, -42.690, 112);
REPLACE INTO `mob_spawn_points` VALUES (17986484, 0, 'BastokD_Regiment_C', 'Regiment Magician', 8, 97, 99, -128.455, -0.500, -43.144, 112);
REPLACE INTO `mob_spawn_points` VALUES (17986485, 0, 'BastokD_Regiment_A', 'Regiment Weaponmaster', 6, 97, 99, -99.507, 7.263, 47.654, 249);
REPLACE INTO `mob_spawn_points` VALUES (17986486, 0, 'BastokD_Regiment_B', 'Regiment\'s Avatar', 7, 97, 99, -97.697, 7.253, 51.128, 208);
REPLACE INTO `mob_spawn_points` VALUES (17986487, 0, 'BastokD_Regiment_C', 'Regiment Magician', 8, 97, 99, -125.300, -0.499, -18.719, 161);
REPLACE INTO `mob_spawn_points` VALUES (17986488, 0, 'BastokD_Regiment_A', 'Regiment Weaponmaster', 6, 97, 99, -105.974, 7.351, 51.139, 50);
REPLACE INTO `mob_spawn_points` VALUES (17986489, 0, 'BastokD_Regiment_B', 'Regiment\'s Avatar', 7, 97, 99, -101.297, 10.164, 61.351, 45);
REPLACE INTO `mob_spawn_points` VALUES (17986490, 0, 'BastokD_Regiment_C', 'Regiment Magician', 8, 97, 99, -130.141, -2.179, -0.430, 75);
REPLACE INTO `mob_spawn_points` VALUES (17986491, 0, 'BastokD_Regiment_A', 'Regiment Weaponmaster', 6, 97, 99, -101.900, 11.031, 65.200, 246);
REPLACE INTO `mob_spawn_points` VALUES (17986492, 0, 'BastokD_Regiment_B', 'Regiment\'s Avatar', 7, 97, 99, -106.531, 10.100, 60.949, 80);
REPLACE INTO `mob_spawn_points` VALUES (17986493, 0, 'BastokD_Regiment_C', 'Regiment Magician', 8, 97, 99, -103.288, 11.450, 67.890, 41);
REPLACE INTO `mob_spawn_points` VALUES (17986494, 0, 'BastokD_Regiment_A', 'Regiment Weaponmaster', 6, 97, 99, -128.456, -8.978, 16.966, 166);
REPLACE INTO `mob_spawn_points` VALUES (17986495, 0, 'BastokD_Regiment_B', 'Regiment\'s Avatar', 7, 97, 99, -133.551, -4.299, 7.920, 195);
REPLACE INTO `mob_spawn_points` VALUES (17986496, 0, 'BastokD_Regiment_C', 'Regiment Magician', 8, 97, 99, -106.409, 11.986, 66.730, 106);
REPLACE INTO `mob_spawn_points` VALUES (17986497, 0, 'BastokD_Regiment_A', 'Regiment Weaponmaster', 6, 97, 99, -134.343, -4.838, 8.958, 210);
REPLACE INTO `mob_spawn_points` VALUES (17986498, 0, 'BastokD_Regiment_B', 'Regiment\'s Avatar', 7, 97, 99, -111.052, 10.222, 61.820, 162);
REPLACE INTO `mob_spawn_points` VALUES (17986499, 0, 'BastokD_Regiment_C', 'Regiment Magician', 8, 97, 99, -104.509, 11.500, 73.066, 87);
REPLACE INTO `mob_spawn_points` VALUES (17986500, 0, 'BastokD_Regiment_A', 'Regiment Weaponmaster', 6, 97, 99, -131.731, -11.686, 21.691, 131);
REPLACE INTO `mob_spawn_points` VALUES (17986501, 0, 'BastokD_Regiment_B', 'Regiment\'s Avatar', 7, 97, 99, -108.000, 11.500, 71.783, 131);
REPLACE INTO `mob_spawn_points` VALUES (17986502, 0, 'BastokD_Regiment_C', 'Regiment Magician', 8, 97, 99, -145.442, -0.497, -11.516, 85);
REPLACE INTO `mob_spawn_points` VALUES (17986503, 0, 'BastokD_Regiment_A', 'Regiment Weaponmaster', 6, 97, 99, -155.074, -0.543, -18.459, 19);
REPLACE INTO `mob_spawn_points` VALUES (17986504, 0, 'BastokD_Regiment_B', 'Regiment\'s Avatar', 7, 97, 99, -164.861, -3.941, -26.738, 169);
REPLACE INTO `mob_spawn_points` VALUES (17986505, 0, 'BastokD_Regiment_C', 'Regiment Magician', 8, 97, 99, -168.284, -6.392, -20.822, 46);

-- ── Bosses (existing mobids, RELOCATED to corridor midpoint / far end) ──
REPLACE INTO `mob_spawn_points` VALUES (17985538, 0, 'MushaEffigy_BastokD', 'Mu\'Sha Effigy', 1, 99, 99, -38.162, -0.500, -62.945, 5);
REPLACE INTO `mob_spawn_points` VALUES (17985895, 0, 'KaRhoFearsinger', 'Ka\'Rho Fearsinger', 9, 99, 99, -184.911, -8.980, -23.771, 181);
REPLACE INTO `mob_spawn_points` VALUES (17986326, 0, 'Disjoined_Galka_D', 'Disjoined Galka', 10, 99, 99, -192.805, -9.242, -22.505, 181);

-- ── instance_entities: register all 109 mobs ──
DELETE FROM `instance_entities` WHERE `instanceid` = 29500;
REPLACE INTO `instance_entities` VALUES (29500, 17986400);
REPLACE INTO `instance_entities` VALUES (29500, 17986401);
REPLACE INTO `instance_entities` VALUES (29500, 17986402);
REPLACE INTO `instance_entities` VALUES (29500, 17986403);
REPLACE INTO `instance_entities` VALUES (29500, 17986404);
REPLACE INTO `instance_entities` VALUES (29500, 17986405);
REPLACE INTO `instance_entities` VALUES (29500, 17986406);
REPLACE INTO `instance_entities` VALUES (29500, 17986407);
REPLACE INTO `instance_entities` VALUES (29500, 17986408);
REPLACE INTO `instance_entities` VALUES (29500, 17986409);
REPLACE INTO `instance_entities` VALUES (29500, 17986410);
REPLACE INTO `instance_entities` VALUES (29500, 17986411);
REPLACE INTO `instance_entities` VALUES (29500, 17986412);
REPLACE INTO `instance_entities` VALUES (29500, 17986413);
REPLACE INTO `instance_entities` VALUES (29500, 17986414);
REPLACE INTO `instance_entities` VALUES (29500, 17986415);
REPLACE INTO `instance_entities` VALUES (29500, 17986416);
REPLACE INTO `instance_entities` VALUES (29500, 17986417);
REPLACE INTO `instance_entities` VALUES (29500, 17986418);
REPLACE INTO `instance_entities` VALUES (29500, 17986419);
REPLACE INTO `instance_entities` VALUES (29500, 17986420);
REPLACE INTO `instance_entities` VALUES (29500, 17986421);
REPLACE INTO `instance_entities` VALUES (29500, 17986422);
REPLACE INTO `instance_entities` VALUES (29500, 17986423);
REPLACE INTO `instance_entities` VALUES (29500, 17986424);
REPLACE INTO `instance_entities` VALUES (29500, 17986425);
REPLACE INTO `instance_entities` VALUES (29500, 17986426);
REPLACE INTO `instance_entities` VALUES (29500, 17986427);
REPLACE INTO `instance_entities` VALUES (29500, 17986428);
REPLACE INTO `instance_entities` VALUES (29500, 17986429);
REPLACE INTO `instance_entities` VALUES (29500, 17986430);
REPLACE INTO `instance_entities` VALUES (29500, 17986431);
REPLACE INTO `instance_entities` VALUES (29500, 17986432);
REPLACE INTO `instance_entities` VALUES (29500, 17986433);
REPLACE INTO `instance_entities` VALUES (29500, 17986434);
REPLACE INTO `instance_entities` VALUES (29500, 17986435);
REPLACE INTO `instance_entities` VALUES (29500, 17986436);
REPLACE INTO `instance_entities` VALUES (29500, 17986437);
REPLACE INTO `instance_entities` VALUES (29500, 17986438);
REPLACE INTO `instance_entities` VALUES (29500, 17986439);
REPLACE INTO `instance_entities` VALUES (29500, 17986440);
REPLACE INTO `instance_entities` VALUES (29500, 17986441);
REPLACE INTO `instance_entities` VALUES (29500, 17986442);
REPLACE INTO `instance_entities` VALUES (29500, 17986443);
REPLACE INTO `instance_entities` VALUES (29500, 17986444);
REPLACE INTO `instance_entities` VALUES (29500, 17986445);
REPLACE INTO `instance_entities` VALUES (29500, 17986446);
REPLACE INTO `instance_entities` VALUES (29500, 17986447);
REPLACE INTO `instance_entities` VALUES (29500, 17986448);
REPLACE INTO `instance_entities` VALUES (29500, 17986449);
REPLACE INTO `instance_entities` VALUES (29500, 17986450);
REPLACE INTO `instance_entities` VALUES (29500, 17986451);
REPLACE INTO `instance_entities` VALUES (29500, 17986452);
REPLACE INTO `instance_entities` VALUES (29500, 17986453);
REPLACE INTO `instance_entities` VALUES (29500, 17986454);
REPLACE INTO `instance_entities` VALUES (29500, 17986455);
REPLACE INTO `instance_entities` VALUES (29500, 17986456);
REPLACE INTO `instance_entities` VALUES (29500, 17986457);
REPLACE INTO `instance_entities` VALUES (29500, 17986458);
REPLACE INTO `instance_entities` VALUES (29500, 17986459);
REPLACE INTO `instance_entities` VALUES (29500, 17986460);
REPLACE INTO `instance_entities` VALUES (29500, 17986461);
REPLACE INTO `instance_entities` VALUES (29500, 17986462);
REPLACE INTO `instance_entities` VALUES (29500, 17986463);
REPLACE INTO `instance_entities` VALUES (29500, 17986464);
REPLACE INTO `instance_entities` VALUES (29500, 17986465);
REPLACE INTO `instance_entities` VALUES (29500, 17986466);
REPLACE INTO `instance_entities` VALUES (29500, 17986467);
REPLACE INTO `instance_entities` VALUES (29500, 17986468);
REPLACE INTO `instance_entities` VALUES (29500, 17986469);
REPLACE INTO `instance_entities` VALUES (29500, 17986470);
REPLACE INTO `instance_entities` VALUES (29500, 17986471);
REPLACE INTO `instance_entities` VALUES (29500, 17986472);
REPLACE INTO `instance_entities` VALUES (29500, 17986473);
REPLACE INTO `instance_entities` VALUES (29500, 17986474);
REPLACE INTO `instance_entities` VALUES (29500, 17986475);
REPLACE INTO `instance_entities` VALUES (29500, 17986476);
REPLACE INTO `instance_entities` VALUES (29500, 17986477);
REPLACE INTO `instance_entities` VALUES (29500, 17986478);
REPLACE INTO `instance_entities` VALUES (29500, 17986479);
REPLACE INTO `instance_entities` VALUES (29500, 17986480);
REPLACE INTO `instance_entities` VALUES (29500, 17986481);
REPLACE INTO `instance_entities` VALUES (29500, 17986482);
REPLACE INTO `instance_entities` VALUES (29500, 17986483);
REPLACE INTO `instance_entities` VALUES (29500, 17986484);
REPLACE INTO `instance_entities` VALUES (29500, 17986485);
REPLACE INTO `instance_entities` VALUES (29500, 17986486);
REPLACE INTO `instance_entities` VALUES (29500, 17986487);
REPLACE INTO `instance_entities` VALUES (29500, 17986488);
REPLACE INTO `instance_entities` VALUES (29500, 17986489);
REPLACE INTO `instance_entities` VALUES (29500, 17986490);
REPLACE INTO `instance_entities` VALUES (29500, 17986491);
REPLACE INTO `instance_entities` VALUES (29500, 17986492);
REPLACE INTO `instance_entities` VALUES (29500, 17986493);
REPLACE INTO `instance_entities` VALUES (29500, 17986494);
REPLACE INTO `instance_entities` VALUES (29500, 17986495);
REPLACE INTO `instance_entities` VALUES (29500, 17986496);
REPLACE INTO `instance_entities` VALUES (29500, 17986497);
REPLACE INTO `instance_entities` VALUES (29500, 17986498);
REPLACE INTO `instance_entities` VALUES (29500, 17986499);
REPLACE INTO `instance_entities` VALUES (29500, 17986500);
REPLACE INTO `instance_entities` VALUES (29500, 17986501);
REPLACE INTO `instance_entities` VALUES (29500, 17986502);
REPLACE INTO `instance_entities` VALUES (29500, 17986503);
REPLACE INTO `instance_entities` VALUES (29500, 17986504);
REPLACE INTO `instance_entities` VALUES (29500, 17986505);
REPLACE INTO `instance_entities` VALUES (29500, 17985538);
REPLACE INTO `instance_entities` VALUES (29500, 17985895);
REPLACE INTO `instance_entities` VALUES (29500, 17986326);

-- ── instance_list (unchanged) ──
REPLACE INTO `instance_list` VALUES (29500, 'dynamis_bastok_d', 295, 234, 90, 116.482, 0.994, -72.121, 128, NULL, NULL, NULL, NULL);

-- ── mob_droplist (unchanged) ──
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
-- Reuses zone-187 Vanguard Yagudo pools; coords from retail Dynamis-Windy stock spawns.
-- ============================================================================

-- ── mob_groups (unchanged: retail Vanguard family pools) ──
REPLACE INTO `mob_groups` VALUES (1, 4070, 296, 'EvincingIdol_WindyD', 0, 128, 29601, 35000, 1000, 0, NULL);
REPLACE INTO `mob_groups` VALUES (2, 4183, 296, 'WindyD_Squadron_A',   0, 128, 29602,  8000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (3, 4176, 296, 'WindyD_Squadron_B',   0, 128, 29602,  8000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (4, 4175, 296, 'WindyD_Squadron_C',   0, 128, 29602,  8000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (5, 3548, 296, 'WindyD_Statue',       0, 128,     0,  6000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (6, 4181, 296, 'WindyD_Regiment_A',   0, 128, 29603, 11000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (7, 4198, 296, 'WindyD_Regiment_B',   0, 128, 29603, 11000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (8, 4141, 296, 'WindyD_Regiment_C',   0, 128, 29603, 11000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (9, 2464, 296, 'FiiPexuTheEternal',   0, 128, 29604, 70000, 2000, 0, NULL);

-- ── mob_spawn_points: corridor pass ──
DELETE FROM `mob_spawn_points` WHERE `mobid` BETWEEN 17989632 AND 17993727;
-- ── Wave 1 corridor: 48 trash spread entry -> mid-boss (band 20-55%) ──
REPLACE INTO `mob_spawn_points` VALUES (17990500, 0, 'WindyD_Squadron_A', 'Squadron Hoplite', 2, 95, 99, -127.000, -3.025, -141.443, 130);
REPLACE INTO `mob_spawn_points` VALUES (17990501, 0, 'WindyD_Squadron_B', 'Squadron\'s Vessel', 3, 95, 99, -125.722, -3.035, -138.891, 139);
REPLACE INTO `mob_spawn_points` VALUES (17990502, 0, 'WindyD_Squadron_C', 'Squadron Scryer', 4, 95, 99, -123.919, -3.000, -140.605, 237);
REPLACE INTO `mob_spawn_points` VALUES (17990503, 0, 'WindyD_Squadron_A', 'Squadron Hoplite', 2, 95, 99, -108.719, -3.026, -126.931, 197);
REPLACE INTO `mob_spawn_points` VALUES (17990504, 0, 'WindyD_Squadron_B', 'Squadron\'s Vessel', 3, 95, 99, -105.716, -2.972, -124.508, 220);
REPLACE INTO `mob_spawn_points` VALUES (17990505, 0, 'WindyD_Squadron_C', 'Squadron Scryer', 4, 95, 99, -103.523, -2.758, -124.416, 231);
REPLACE INTO `mob_spawn_points` VALUES (17990506, 0, 'WindyD_Squadron_A', 'Squadron Hoplite', 2, 95, 99, -68.620, -3.863, -116.798, 245);
REPLACE INTO `mob_spawn_points` VALUES (17990507, 0, 'WindyD_Squadron_B', 'Squadron\'s Vessel', 3, 95, 99, -51.754, -2.981, -110.016, 195);
REPLACE INTO `mob_spawn_points` VALUES (17990508, 0, 'WindyD_Squadron_C', 'Squadron Scryer', 4, 95, 99, -50.714, -3.000, -112.800, 130);
REPLACE INTO `mob_spawn_points` VALUES (17990509, 0, 'WindyD_Squadron_A', 'Squadron Hoplite', 2, 95, 99, -48.050, -2.511, -107.254, 20);
REPLACE INTO `mob_spawn_points` VALUES (17990510, 0, 'WindyD_Squadron_B', 'Squadron\'s Vessel', 3, 95, 99, -47.137, -3.863, -108.998, 35);
REPLACE INTO `mob_spawn_points` VALUES (17990511, 0, 'WindyD_Squadron_C', 'Squadron Scryer', 4, 95, 99, -46.870, -3.000, -99.403, 23);
REPLACE INTO `mob_spawn_points` VALUES (17990512, 0, 'WindyD_Squadron_A', 'Squadron Hoplite', 2, 95, 99, -41.778, -3.863, -94.702, 85);
REPLACE INTO `mob_spawn_points` VALUES (17990513, 0, 'WindyD_Squadron_B', 'Squadron\'s Vessel', 3, 95, 99, -87.822, -3.000, 36.638, 141);
REPLACE INTO `mob_spawn_points` VALUES (17990514, 0, 'WindyD_Squadron_C', 'Squadron Scryer', 4, 95, 99, -88.676, -3.000, 38.587, 110);
REPLACE INTO `mob_spawn_points` VALUES (17990515, 0, 'WindyD_Squadron_A', 'Squadron Hoplite', 2, 95, 99, -86.622, -3.000, 38.319, 112);
REPLACE INTO `mob_spawn_points` VALUES (17990516, 0, 'WindyD_Squadron_B', 'Squadron\'s Vessel', 3, 95, 99, -81.889, -3.308, 34.222, 189);
REPLACE INTO `mob_spawn_points` VALUES (17990517, 0, 'WindyD_Squadron_C', 'Squadron Scryer', 4, 95, 99, -82.775, -3.853, 36.474, 204);
REPLACE INTO `mob_spawn_points` VALUES (17990518, 0, 'WindyD_Squadron_A', 'Squadron Hoplite', 2, 95, 99, -73.842, -4.187, 28.121, 31);
REPLACE INTO `mob_spawn_points` VALUES (17990519, 0, 'WindyD_Squadron_B', 'Squadron\'s Vessel', 3, 95, 99, -57.424, -3.000, 11.524, 214);
REPLACE INTO `mob_spawn_points` VALUES (17990520, 0, 'WindyD_Squadron_C', 'Squadron Scryer', 4, 95, 99, -50.565, -4.187, 7.740, 143);
REPLACE INTO `mob_spawn_points` VALUES (17990521, 0, 'WindyD_Squadron_A', 'Squadron Hoplite', 2, 95, 99, -50.545, -4.187, 7.720, 143);
REPLACE INTO `mob_spawn_points` VALUES (17990522, 0, 'WindyD_Squadron_B', 'Squadron\'s Vessel', 3, 95, 99, -11.509, -3.183, -54.976, 226);
REPLACE INTO `mob_spawn_points` VALUES (17990523, 0, 'WindyD_Squadron_C', 'Squadron Scryer', 4, 95, 99, -37.834, -2.886, 2.252, 9);
REPLACE INTO `mob_spawn_points` VALUES (17990524, 0, 'WindyD_Squadron_A', 'Squadron Hoplite', 2, 95, 99, -34.958, -5.206, 1.268, 143);
REPLACE INTO `mob_spawn_points` VALUES (17990525, 0, 'WindyD_Squadron_B', 'Squadron\'s Vessel', 3, 95, 99, -5.874, -4.307, -55.422, 192);
REPLACE INTO `mob_spawn_points` VALUES (17990526, 0, 'WindyD_Squadron_C', 'Squadron Scryer', 4, 95, 99, -4.260, -4.369, -55.797, 17);
REPLACE INTO `mob_spawn_points` VALUES (17990527, 0, 'WindyD_Squadron_A', 'Squadron Hoplite', 2, 95, 99, 2.305, -4.470, -60.836, 215);
REPLACE INTO `mob_spawn_points` VALUES (17990528, 0, 'WindyD_Squadron_B', 'Squadron\'s Vessel', 3, 95, 99, -15.307, -7.903, -12.895, 52);
REPLACE INTO `mob_spawn_points` VALUES (17990529, 0, 'WindyD_Squadron_C', 'Squadron Scryer', 4, 95, 99, -14.488, -7.533, -2.019, 190);
REPLACE INTO `mob_spawn_points` VALUES (17990530, 0, 'WindyD_Squadron_A', 'Squadron Hoplite', 2, 95, 99, 2.956, -7.170, -36.579, 0);
REPLACE INTO `mob_spawn_points` VALUES (17990531, 0, 'WindyD_Squadron_B', 'Squadron\'s Vessel', 3, 95, 99, 5.922, -7.197, -35.900, 28);
REPLACE INTO `mob_spawn_points` VALUES (17990532, 0, 'WindyD_Squadron_C', 'Squadron Scryer', 4, 95, 99, 13.595, -4.455, -59.012, 234);
REPLACE INTO `mob_spawn_points` VALUES (17990533, 0, 'WindyD_Squadron_A', 'Squadron Hoplite', 2, 95, 99, 15.259, -3.560, -63.064, 111);
REPLACE INTO `mob_spawn_points` VALUES (17990534, 0, 'WindyD_Squadron_B', 'Squadron\'s Vessel', 3, 95, 99, 16.565, -2.527, -65.018, 27);
REPLACE INTO `mob_spawn_points` VALUES (17990535, 0, 'WindyD_Squadron_C', 'Squadron Scryer', 4, 95, 99, 14.990, -4.381, -55.776, 178);
REPLACE INTO `mob_spawn_points` VALUES (17990536, 0, 'WindyD_Squadron_A', 'Squadron Hoplite', 2, 95, 99, -2.375, -9.123, -8.827, 115);
REPLACE INTO `mob_spawn_points` VALUES (17990537, 0, 'WindyD_Squadron_B', 'Squadron\'s Vessel', 3, 95, 99, 9.769, -7.205, -34.507, 184);
REPLACE INTO `mob_spawn_points` VALUES (17990538, 0, 'WindyD_Squadron_C', 'Squadron Scryer', 4, 95, 99, -3.272, -8.831, -5.343, 241);
REPLACE INTO `mob_spawn_points` VALUES (17990539, 0, 'WindyD_Squadron_A', 'Squadron Hoplite', 2, 95, 99, -4.486, -9.658, 5.464, 151);
REPLACE INTO `mob_spawn_points` VALUES (17990540, 0, 'WindyD_Squadron_B', 'Squadron\'s Vessel', 3, 95, 99, 24.406, -2.243, -67.707, 23);
REPLACE INTO `mob_spawn_points` VALUES (17990541, 0, 'WindyD_Squadron_C', 'Squadron Scryer', 4, 95, 99, 7.291, -9.692, -14.044, 6);
REPLACE INTO `mob_spawn_points` VALUES (17990542, 0, 'WindyD_Squadron_A', 'Squadron Hoplite', 2, 95, 99, 2.509, -9.674, -3.921, 98);
REPLACE INTO `mob_spawn_points` VALUES (17990543, 0, 'WindyD_Squadron_B', 'Squadron\'s Vessel', 3, 95, 99, 0.102, -9.779, 1.757, 162);
REPLACE INTO `mob_spawn_points` VALUES (17990544, 0, 'WindyD_Squadron_C', 'Squadron Scryer', 4, 95, 99, 27.565, -2.487, -67.654, 220);
REPLACE INTO `mob_spawn_points` VALUES (17990545, 0, 'WindyD_Squadron_A', 'Squadron Hoplite', 2, 95, 99, 22.436, -7.006, -42.127, 38);
REPLACE INTO `mob_spawn_points` VALUES (17990546, 0, 'WindyD_Squadron_B', 'Squadron\'s Vessel', 3, 95, 99, 5.666, -10.283, 2.543, 64);
REPLACE INTO `mob_spawn_points` VALUES (17990547, 0, 'WindyD_Squadron_C', 'Squadron Scryer', 4, 95, 99, -83.505, -9.922, 100.949, 166);

-- ── Statues: 10 time-extension statues spread 15-90% along corridor ──
REPLACE INTO `mob_spawn_points` VALUES (17990548, 0, 'WindyD_Statue', 'Incarnation Icon', 5, 99, 99, -146.424, -2.499, -138.759, 21);
REPLACE INTO `mob_spawn_points` VALUES (17990549, 0, 'WindyD_Statue', 'Incarnation Icon', 5, 99, 99, -81.889, -3.308, 34.222, 189);
REPLACE INTO `mob_spawn_points` VALUES (17990550, 0, 'WindyD_Statue', 'Incarnation Icon', 5, 99, 99, 5.904, -7.298, -34.856, 26);
REPLACE INTO `mob_spawn_points` VALUES (17990551, 0, 'WindyD_Statue', 'Incarnation Icon', 5, 99, 99, -89.751, -9.918, 108.445, 213);
REPLACE INTO `mob_spawn_points` VALUES (17990552, 0, 'WindyD_Statue', 'Incarnation Icon', 5, 99, 99, 24.001, -10.500, 6.531, 93);
REPLACE INTO `mob_spawn_points` VALUES (17990553, 0, 'WindyD_Statue', 'Incarnation Icon', 5, 99, 99, 80.808, -3.687, -93.026, 198);
REPLACE INTO `mob_spawn_points` VALUES (17990554, 0, 'WindyD_Statue', 'Incarnation Icon', 5, 99, 99, -92.002, -12.999, 187.916, 92);
REPLACE INTO `mob_spawn_points` VALUES (17990555, 0, 'WindyD_Statue', 'Incarnation Icon', 5, 99, 99, -103.872, -13.000, 219.970, 20);
REPLACE INTO `mob_spawn_points` VALUES (17990556, 0, 'WindyD_Statue', 'Incarnation Icon', 5, 99, 99, 100.601, -3.266, 122.127, 77);
REPLACE INTO `mob_spawn_points` VALUES (17990557, 0, 'WindyD_Statue', 'Incarnation Icon', 5, 99, 99, 109.007, -11.335, 152.977, 215);

-- ── Wave 2 corridor: 48 trash spread mid-boss -> mega-boss (band 55-95%) ──
REPLACE INTO `mob_spawn_points` VALUES (17990558, 0, 'WindyD_Regiment_A', 'Regiment Hoplite', 6, 97, 99, 10.854, -10.470, 3.927, 196);
REPLACE INTO `mob_spawn_points` VALUES (17990559, 0, 'WindyD_Regiment_B', 'Regiment\'s Vessel', 7, 97, 99, -190.279, -2.929, 143.972, 70);
REPLACE INTO `mob_spawn_points` VALUES (17990560, 0, 'WindyD_Regiment_C', 'Regiment Scryer', 8, 97, 99, 35.117, -7.559, -48.841, 160);
REPLACE INTO `mob_spawn_points` VALUES (17990561, 0, 'WindyD_Regiment_A', 'Regiment Hoplite', 6, 97, 99, -130.130, -5.500, 131.446, 107);
REPLACE INTO `mob_spawn_points` VALUES (17990562, 0, 'WindyD_Regiment_B', 'Regiment\'s Vessel', 7, 97, 99, 41.857, -2.999, -61.608, 3);
REPLACE INTO `mob_spawn_points` VALUES (17990563, 0, 'WindyD_Regiment_C', 'Regiment Scryer', 8, 97, 99, -189.993, -3.232, 149.146, 143);
REPLACE INTO `mob_spawn_points` VALUES (17990564, 0, 'WindyD_Regiment_A', 'Regiment Hoplite', 6, 97, 99, -164.197, -3.613, 148.654, 127);
REPLACE INTO `mob_spawn_points` VALUES (17990565, 0, 'WindyD_Regiment_B', 'Regiment\'s Vessel', 7, 97, 99, 24.001, -10.500, 6.531, 93);
REPLACE INTO `mob_spawn_points` VALUES (17990566, 0, 'WindyD_Regiment_C', 'Regiment Scryer', 8, 97, 99, -80.316, -6.237, 121.434, 3);
REPLACE INTO `mob_spawn_points` VALUES (17990567, 0, 'WindyD_Regiment_A', 'Regiment Hoplite', 6, 97, 99, -95.432, -5.513, 130.729, 251);
REPLACE INTO `mob_spawn_points` VALUES (17990568, 0, 'WindyD_Regiment_B', 'Regiment\'s Vessel', 7, 97, 99, -139.342, -3.613, 149.117, 128);
REPLACE INTO `mob_spawn_points` VALUES (17990569, 0, 'WindyD_Regiment_C', 'Regiment Scryer', 8, 97, 99, -101.796, -5.718, 137.319, 82);
REPLACE INTO `mob_spawn_points` VALUES (17990570, 0, 'WindyD_Regiment_A', 'Regiment Hoplite', 6, 97, 99, 60.575, -8.013, -46.368, 125);
REPLACE INTO `mob_spawn_points` VALUES (17990571, 0, 'WindyD_Regiment_B', 'Regiment\'s Vessel', 7, 97, 99, 38.143, -10.500, 16.407, 1);
REPLACE INTO `mob_spawn_points` VALUES (17990572, 0, 'WindyD_Regiment_C', 'Regiment Scryer', 8, 97, 99, 84.087, -3.687, -113.998, 64);
REPLACE INTO `mob_spawn_points` VALUES (17990573, 0, 'WindyD_Regiment_A', 'Regiment Hoplite', 6, 97, 99, 89.473, -2.798, -142.530, 14);
REPLACE INTO `mob_spawn_points` VALUES (17990574, 0, 'WindyD_Regiment_B', 'Regiment\'s Vessel', 7, 97, 99, 56.821, -10.180, 27.057, 225);
REPLACE INTO `mob_spawn_points` VALUES (17990575, 0, 'WindyD_Regiment_C', 'Regiment Scryer', 8, 97, 99, 94.944, -3.171, -147.770, 64);
REPLACE INTO `mob_spawn_points` VALUES (17990576, 0, 'WindyD_Regiment_A', 'Regiment Hoplite', 6, 97, 99, -10.681, -16.500, 127.305, 19);
REPLACE INTO `mob_spawn_points` VALUES (17990577, 0, 'WindyD_Regiment_B', 'Regiment\'s Vessel', 7, 97, 99, -97.498, -12.924, 182.906, 80);
REPLACE INTO `mob_spawn_points` VALUES (17990578, 0, 'WindyD_Regiment_C', 'Regiment Scryer', 8, 97, 99, -31.223, -16.500, 149.847, 44);
REPLACE INTO `mob_spawn_points` VALUES (17990579, 0, 'WindyD_Regiment_A', 'Regiment Hoplite', 6, 97, 99, -94.000, -13.482, 190.000, 45);
REPLACE INTO `mob_spawn_points` VALUES (17990580, 0, 'WindyD_Regiment_B', 'Regiment\'s Vessel', 7, 97, 99, 72.069, -8.120, 46.617, 119);
REPLACE INTO `mob_spawn_points` VALUES (17990581, 0, 'WindyD_Regiment_C', 'Regiment Scryer', 8, 97, 99, 74.720, -7.780, 47.509, 12);
REPLACE INTO `mob_spawn_points` VALUES (17990582, 0, 'WindyD_Regiment_A', 'Regiment Hoplite', 6, 97, 99, -99.732, -18.000, 203.763, 98);
REPLACE INTO `mob_spawn_points` VALUES (17990583, 0, 'WindyD_Regiment_B', 'Regiment\'s Vessel', 7, 97, 99, -72.066, -12.916, 201.008, 142);
REPLACE INTO `mob_spawn_points` VALUES (17990584, 0, 'WindyD_Regiment_C', 'Regiment Scryer', 8, 97, 99, -63.812, -12.999, 200.095, 58);
REPLACE INTO `mob_spawn_points` VALUES (17990585, 0, 'WindyD_Regiment_A', 'Regiment Hoplite', 6, 97, 99, 81.717, -3.246, 79.814, 85);
REPLACE INTO `mob_spawn_points` VALUES (17990586, 0, 'WindyD_Regiment_B', 'Regiment\'s Vessel', 7, 97, 99, -58.923, -13.613, 216.845, 74);
REPLACE INTO `mob_spawn_points` VALUES (17990587, 0, 'WindyD_Regiment_C', 'Regiment Scryer', 8, 97, 99, 89.162, -3.135, 98.413, 163);
REPLACE INTO `mob_spawn_points` VALUES (17990588, 0, 'WindyD_Regiment_A', 'Regiment Hoplite', 6, 97, 99, 9.136, -16.500, 189.738, 140);
REPLACE INTO `mob_spawn_points` VALUES (17990589, 0, 'WindyD_Regiment_B', 'Regiment\'s Vessel', 7, 97, 99, -52.700, -13.613, 233.598, 245);
REPLACE INTO `mob_spawn_points` VALUES (17990590, 0, 'WindyD_Regiment_C', 'Regiment Scryer', 8, 97, 99, 29.315, -16.500, 187.117, 195);
REPLACE INTO `mob_spawn_points` VALUES (17990591, 0, 'WindyD_Regiment_A', 'Regiment Hoplite', 6, 97, 99, 85.404, -5.172, 137.880, 192);
REPLACE INTO `mob_spawn_points` VALUES (17990592, 0, 'WindyD_Regiment_B', 'Regiment\'s Vessel', 7, 97, 99, 100.605, -3.157, 122.373, 251);
REPLACE INTO `mob_spawn_points` VALUES (17990593, 0, 'WindyD_Regiment_C', 'Regiment Scryer', 8, 97, 99, 114.650, -8.000, 120.194, 192);
REPLACE INTO `mob_spawn_points` VALUES (17990594, 0, 'WindyD_Regiment_A', 'Regiment Hoplite', 6, 97, 99, 105.428, -11.285, 143.603, 110);
REPLACE INTO `mob_spawn_points` VALUES (17990595, 0, 'WindyD_Regiment_B', 'Regiment\'s Vessel', 7, 97, 99, -33.217, -12.975, 257.196, 242);
REPLACE INTO `mob_spawn_points` VALUES (17990596, 0, 'WindyD_Regiment_C', 'Regiment Scryer', 8, 97, 99, -25.551, -12.989, 256.231, 155);
REPLACE INTO `mob_spawn_points` VALUES (17990597, 0, 'WindyD_Regiment_A', 'Regiment Hoplite', 6, 97, 99, -18.457, -12.862, 255.660, 52);
REPLACE INTO `mob_spawn_points` VALUES (17990598, 0, 'WindyD_Regiment_B', 'Regiment\'s Vessel', 7, 97, 99, 109.007, -11.335, 152.977, 215);
REPLACE INTO `mob_spawn_points` VALUES (17990599, 0, 'WindyD_Regiment_C', 'Regiment Scryer', 8, 97, 99, 45.992, -9.287, 219.587, 52);
REPLACE INTO `mob_spawn_points` VALUES (17990600, 0, 'WindyD_Regiment_A', 'Regiment Hoplite', 6, 97, 99, 84.419, -8.034, 187.649, 131);
REPLACE INTO `mob_spawn_points` VALUES (17990601, 0, 'WindyD_Regiment_B', 'Regiment\'s Vessel', 7, 97, 99, 109.842, -11.433, 162.439, 43);
REPLACE INTO `mob_spawn_points` VALUES (17990602, 0, 'WindyD_Regiment_C', 'Regiment Scryer', 8, 97, 99, 50.809, -8.000, 222.507, 89);
REPLACE INTO `mob_spawn_points` VALUES (17990603, 0, 'WindyD_Regiment_A', 'Regiment Hoplite', 6, 97, 99, 94.466, -8.062, 185.797, 227);
REPLACE INTO `mob_spawn_points` VALUES (17990604, 0, 'WindyD_Regiment_B', 'Regiment\'s Vessel', 7, 97, 99, -0.761, -9.791, 269.177, 150);
REPLACE INTO `mob_spawn_points` VALUES (17990605, 0, 'WindyD_Regiment_C', 'Regiment Scryer', 8, 97, 99, -12.980, -13.000, 282.181, 79);

-- ── Bosses (existing mobids, RELOCATED to corridor midpoint / far end) ──
REPLACE INTO `mob_spawn_points` VALUES (17989634, 0, 'EvincingIdol_WindyD', 'Evincing Idol', 1, 99, 99, -14.488, -7.533, -2.019, 190);
REPLACE INTO `mob_spawn_points` VALUES (17990606, 0, 'FiiPexuTheEternal', 'Fii Pexu the Eternal', 9, 99, 99, 108.944, -8.059, 218.604, 2);
REPLACE INTO `mob_spawn_points` VALUES (17990425, 0, 'Disjoined_Tarutaru_D', 'Disjoined Tarutaru', 10, 99, 99, 114.534, -8.211, 224.326, 2);

-- ── instance_entities: register all 109 mobs ──
DELETE FROM `instance_entities` WHERE `instanceid` = 29600;
REPLACE INTO `instance_entities` VALUES (29600, 17990500);
REPLACE INTO `instance_entities` VALUES (29600, 17990501);
REPLACE INTO `instance_entities` VALUES (29600, 17990502);
REPLACE INTO `instance_entities` VALUES (29600, 17990503);
REPLACE INTO `instance_entities` VALUES (29600, 17990504);
REPLACE INTO `instance_entities` VALUES (29600, 17990505);
REPLACE INTO `instance_entities` VALUES (29600, 17990506);
REPLACE INTO `instance_entities` VALUES (29600, 17990507);
REPLACE INTO `instance_entities` VALUES (29600, 17990508);
REPLACE INTO `instance_entities` VALUES (29600, 17990509);
REPLACE INTO `instance_entities` VALUES (29600, 17990510);
REPLACE INTO `instance_entities` VALUES (29600, 17990511);
REPLACE INTO `instance_entities` VALUES (29600, 17990512);
REPLACE INTO `instance_entities` VALUES (29600, 17990513);
REPLACE INTO `instance_entities` VALUES (29600, 17990514);
REPLACE INTO `instance_entities` VALUES (29600, 17990515);
REPLACE INTO `instance_entities` VALUES (29600, 17990516);
REPLACE INTO `instance_entities` VALUES (29600, 17990517);
REPLACE INTO `instance_entities` VALUES (29600, 17990518);
REPLACE INTO `instance_entities` VALUES (29600, 17990519);
REPLACE INTO `instance_entities` VALUES (29600, 17990520);
REPLACE INTO `instance_entities` VALUES (29600, 17990521);
REPLACE INTO `instance_entities` VALUES (29600, 17990522);
REPLACE INTO `instance_entities` VALUES (29600, 17990523);
REPLACE INTO `instance_entities` VALUES (29600, 17990524);
REPLACE INTO `instance_entities` VALUES (29600, 17990525);
REPLACE INTO `instance_entities` VALUES (29600, 17990526);
REPLACE INTO `instance_entities` VALUES (29600, 17990527);
REPLACE INTO `instance_entities` VALUES (29600, 17990528);
REPLACE INTO `instance_entities` VALUES (29600, 17990529);
REPLACE INTO `instance_entities` VALUES (29600, 17990530);
REPLACE INTO `instance_entities` VALUES (29600, 17990531);
REPLACE INTO `instance_entities` VALUES (29600, 17990532);
REPLACE INTO `instance_entities` VALUES (29600, 17990533);
REPLACE INTO `instance_entities` VALUES (29600, 17990534);
REPLACE INTO `instance_entities` VALUES (29600, 17990535);
REPLACE INTO `instance_entities` VALUES (29600, 17990536);
REPLACE INTO `instance_entities` VALUES (29600, 17990537);
REPLACE INTO `instance_entities` VALUES (29600, 17990538);
REPLACE INTO `instance_entities` VALUES (29600, 17990539);
REPLACE INTO `instance_entities` VALUES (29600, 17990540);
REPLACE INTO `instance_entities` VALUES (29600, 17990541);
REPLACE INTO `instance_entities` VALUES (29600, 17990542);
REPLACE INTO `instance_entities` VALUES (29600, 17990543);
REPLACE INTO `instance_entities` VALUES (29600, 17990544);
REPLACE INTO `instance_entities` VALUES (29600, 17990545);
REPLACE INTO `instance_entities` VALUES (29600, 17990546);
REPLACE INTO `instance_entities` VALUES (29600, 17990547);
REPLACE INTO `instance_entities` VALUES (29600, 17990548);
REPLACE INTO `instance_entities` VALUES (29600, 17990549);
REPLACE INTO `instance_entities` VALUES (29600, 17990550);
REPLACE INTO `instance_entities` VALUES (29600, 17990551);
REPLACE INTO `instance_entities` VALUES (29600, 17990552);
REPLACE INTO `instance_entities` VALUES (29600, 17990553);
REPLACE INTO `instance_entities` VALUES (29600, 17990554);
REPLACE INTO `instance_entities` VALUES (29600, 17990555);
REPLACE INTO `instance_entities` VALUES (29600, 17990556);
REPLACE INTO `instance_entities` VALUES (29600, 17990557);
REPLACE INTO `instance_entities` VALUES (29600, 17990558);
REPLACE INTO `instance_entities` VALUES (29600, 17990559);
REPLACE INTO `instance_entities` VALUES (29600, 17990560);
REPLACE INTO `instance_entities` VALUES (29600, 17990561);
REPLACE INTO `instance_entities` VALUES (29600, 17990562);
REPLACE INTO `instance_entities` VALUES (29600, 17990563);
REPLACE INTO `instance_entities` VALUES (29600, 17990564);
REPLACE INTO `instance_entities` VALUES (29600, 17990565);
REPLACE INTO `instance_entities` VALUES (29600, 17990566);
REPLACE INTO `instance_entities` VALUES (29600, 17990567);
REPLACE INTO `instance_entities` VALUES (29600, 17990568);
REPLACE INTO `instance_entities` VALUES (29600, 17990569);
REPLACE INTO `instance_entities` VALUES (29600, 17990570);
REPLACE INTO `instance_entities` VALUES (29600, 17990571);
REPLACE INTO `instance_entities` VALUES (29600, 17990572);
REPLACE INTO `instance_entities` VALUES (29600, 17990573);
REPLACE INTO `instance_entities` VALUES (29600, 17990574);
REPLACE INTO `instance_entities` VALUES (29600, 17990575);
REPLACE INTO `instance_entities` VALUES (29600, 17990576);
REPLACE INTO `instance_entities` VALUES (29600, 17990577);
REPLACE INTO `instance_entities` VALUES (29600, 17990578);
REPLACE INTO `instance_entities` VALUES (29600, 17990579);
REPLACE INTO `instance_entities` VALUES (29600, 17990580);
REPLACE INTO `instance_entities` VALUES (29600, 17990581);
REPLACE INTO `instance_entities` VALUES (29600, 17990582);
REPLACE INTO `instance_entities` VALUES (29600, 17990583);
REPLACE INTO `instance_entities` VALUES (29600, 17990584);
REPLACE INTO `instance_entities` VALUES (29600, 17990585);
REPLACE INTO `instance_entities` VALUES (29600, 17990586);
REPLACE INTO `instance_entities` VALUES (29600, 17990587);
REPLACE INTO `instance_entities` VALUES (29600, 17990588);
REPLACE INTO `instance_entities` VALUES (29600, 17990589);
REPLACE INTO `instance_entities` VALUES (29600, 17990590);
REPLACE INTO `instance_entities` VALUES (29600, 17990591);
REPLACE INTO `instance_entities` VALUES (29600, 17990592);
REPLACE INTO `instance_entities` VALUES (29600, 17990593);
REPLACE INTO `instance_entities` VALUES (29600, 17990594);
REPLACE INTO `instance_entities` VALUES (29600, 17990595);
REPLACE INTO `instance_entities` VALUES (29600, 17990596);
REPLACE INTO `instance_entities` VALUES (29600, 17990597);
REPLACE INTO `instance_entities` VALUES (29600, 17990598);
REPLACE INTO `instance_entities` VALUES (29600, 17990599);
REPLACE INTO `instance_entities` VALUES (29600, 17990600);
REPLACE INTO `instance_entities` VALUES (29600, 17990601);
REPLACE INTO `instance_entities` VALUES (29600, 17990602);
REPLACE INTO `instance_entities` VALUES (29600, 17990603);
REPLACE INTO `instance_entities` VALUES (29600, 17990604);
REPLACE INTO `instance_entities` VALUES (29600, 17990605);
REPLACE INTO `instance_entities` VALUES (29600, 17989634);
REPLACE INTO `instance_entities` VALUES (29600, 17990606);
REPLACE INTO `instance_entities` VALUES (29600, 17990425);

-- ── instance_list (unchanged) ──
REPLACE INTO `instance_list` VALUES (29600, 'dynamis_windurst_d', 296, 239, 90, -221.988, 1.000, -120.184, 0, NULL, NULL, NULL, NULL);

-- ── mob_droplist (unchanged) ──
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
-- Reuses zone-188 Vanguard Goblin pools; coords from retail Dynamis-Jeuno stock spawns.
-- ============================================================================

-- ── mob_groups (unchanged: retail Vanguard family pools) ──
REPLACE INTO `mob_groups` VALUES (1, 1668, 297, 'ImpishGolem_JeunoD', 0, 128, 29701, 35000, 1000, 0, NULL);
REPLACE INTO `mob_groups` VALUES (2, 4184, 297, 'JeunoD_Squadron_A',  0, 128, 29702,  8000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (3, 4199, 297, 'JeunoD_Squadron_B',  0, 128, 29702,  8000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (4, 4170, 297, 'JeunoD_Squadron_C',  0, 128, 29702,  8000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (5, 3548, 297, 'JeunoD_Statue',      0, 128,     0,  6000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (6, 4182, 297, 'JeunoD_Regiment_A',  0, 128, 29703, 11000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (7, 4147, 297, 'JeunoD_Regiment_B',  0, 128, 29703, 11000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (8, 4192, 297, 'JeunoD_Regiment_C',  0, 128, 29703, 11000,    0, 0, NULL);
REPLACE INTO `mob_groups` VALUES (9, 1444, 297, 'Obstatrix_JeunoD',   0, 128, 29704, 70000, 2000, 0, NULL);

-- ── mob_spawn_points: corridor pass ──
DELETE FROM `mob_spawn_points` WHERE `mobid` BETWEEN 17993728 AND 17997823;
-- ── Wave 1 corridor: 48 trash spread entry -> mid-boss (band 20-55%) ──

-- REPACK 2026-07-13: purge the old out-of-boundary corridor rows (mobids 17994700..17994805 were past zoneMin+1024).
DELETE FROM `mob_spawn_points`   WHERE mobid   BETWEEN 17994700 AND 17994805;
DELETE FROM `instance_entities`  WHERE id      BETWEEN 17994700 AND 17994805;
REPLACE INTO `mob_spawn_points` VALUES (17994600, 0, 'JeunoD_Squadron_A', 'Squadron Berserker', 2, 95, 99, 13.162, 8.400, -50.063, 3);
REPLACE INTO `mob_spawn_points` VALUES (17994601, 0, 'JeunoD_Squadron_B', 'Squadron\'s Fiend', 3, 95, 99, 23.127, 8.500, -35.830, 119);
REPLACE INTO `mob_spawn_points` VALUES (17994602, 0, 'JeunoD_Squadron_C', 'Squadron Trickster', 4, 95, 99, 19.399, 8.500, -35.754, 233);
REPLACE INTO `mob_spawn_points` VALUES (17994603, 0, 'JeunoD_Squadron_A', 'Squadron Berserker', 2, 95, 99, 2.179, 8.500, -61.613, 30);
REPLACE INTO `mob_spawn_points` VALUES (17994604, 0, 'JeunoD_Squadron_B', 'Squadron\'s Fiend', 3, 95, 99, 15.411, 8.500, -36.876, 120);
REPLACE INTO `mob_spawn_points` VALUES (17994605, 0, 'JeunoD_Squadron_C', 'Squadron Trickster', 4, 95, 99, 3.285, 8.753, -54.795, 57);
REPLACE INTO `mob_spawn_points` VALUES (17994606, 0, 'JeunoD_Squadron_A', 'Squadron Berserker', 2, 95, 99, 7.250, 8.400, -45.459, 62);
REPLACE INTO `mob_spawn_points` VALUES (17994607, 0, 'JeunoD_Squadron_B', 'Squadron\'s Fiend', 3, 95, 99, 16.211, 8.502, -34.077, 109);
REPLACE INTO `mob_spawn_points` VALUES (17994608, 0, 'JeunoD_Squadron_C', 'Squadron Trickster', 4, 95, 99, 31.785, -0.500, -25.679, 230);
REPLACE INTO `mob_spawn_points` VALUES (17994609, 0, 'JeunoD_Squadron_A', 'Squadron Berserker', 2, 95, 99, 0.659, 8.500, -55.955, 186);
REPLACE INTO `mob_spawn_points` VALUES (17994610, 0, 'JeunoD_Squadron_B', 'Squadron\'s Fiend', 3, 95, 99, -0.250, 8.500, -53.982, 209);
REPLACE INTO `mob_spawn_points` VALUES (17994611, 0, 'JeunoD_Squadron_C', 'Squadron Trickster', 4, 95, 99, 31.406, -0.364, -21.094, 58);
REPLACE INTO `mob_spawn_points` VALUES (17994612, 0, 'JeunoD_Squadron_A', 'Squadron Berserker', 2, 95, 99, -1.622, 8.408, -51.594, 126);
REPLACE INTO `mob_spawn_points` VALUES (17994613, 0, 'JeunoD_Squadron_B', 'Squadron\'s Fiend', 3, 95, 99, 28.487, -0.292, -21.805, 181);
REPLACE INTO `mob_spawn_points` VALUES (17994614, 0, 'JeunoD_Squadron_C', 'Squadron Trickster', 4, 95, 99, 5.371, 8.400, -36.954, 26);
REPLACE INTO `mob_spawn_points` VALUES (17994615, 0, 'JeunoD_Squadron_A', 'Squadron Berserker', 2, 95, 99, -0.153, -0.516, -100.577, 63);
REPLACE INTO `mob_spawn_points` VALUES (17994616, 0, 'JeunoD_Squadron_B', 'Squadron\'s Fiend', 3, 95, 99, -11.514, -0.495, -75.751, 235);
REPLACE INTO `mob_spawn_points` VALUES (17994617, 0, 'JeunoD_Squadron_C', 'Squadron Trickster', 4, 95, 99, -10.168, 8.972, -48.570, 220);
REPLACE INTO `mob_spawn_points` VALUES (17994618, 0, 'JeunoD_Squadron_A', 'Squadron Berserker', 2, 95, 99, 32.522, -0.597, -9.860, 120);
REPLACE INTO `mob_spawn_points` VALUES (17994619, 0, 'JeunoD_Squadron_B', 'Squadron\'s Fiend', 3, 95, 99, -14.506, -0.595, -76.689, 4);
REPLACE INTO `mob_spawn_points` VALUES (17994620, 0, 'JeunoD_Squadron_C', 'Squadron Trickster', 4, 95, 99, -9.088, 8.400, -38.517, 120);
REPLACE INTO `mob_spawn_points` VALUES (17994621, 0, 'JeunoD_Squadron_A', 'Squadron Berserker', 2, 95, 99, 26.255, -0.497, -8.034, 216);
REPLACE INTO `mob_spawn_points` VALUES (17994622, 0, 'JeunoD_Squadron_B', 'Squadron\'s Fiend', 3, 95, 99, -17.690, 8.321, -51.944, 66);
REPLACE INTO `mob_spawn_points` VALUES (17994623, 0, 'JeunoD_Squadron_C', 'Squadron Trickster', 4, 95, 99, 17.362, 1.050, -7.853, 46);
REPLACE INTO `mob_spawn_points` VALUES (17994624, 0, 'JeunoD_Squadron_A', 'Squadron Berserker', 2, 95, 99, 26.245, -0.598, -2.773, 134);
REPLACE INTO `mob_spawn_points` VALUES (17994625, 0, 'JeunoD_Squadron_B', 'Squadron\'s Fiend', 3, 95, 99, 14.046, 1.874, -7.569, 218);
REPLACE INTO `mob_spawn_points` VALUES (17994626, 0, 'JeunoD_Squadron_C', 'Squadron Trickster', 4, 95, 99, 12.683, 2.250, -7.074, 239);
REPLACE INTO `mob_spawn_points` VALUES (17994627, 0, 'JeunoD_Squadron_A', 'Squadron Berserker', 2, 95, 99, -25.953, -0.597, -76.961, 0);
REPLACE INTO `mob_spawn_points` VALUES (17994628, 0, 'JeunoD_Squadron_B', 'Squadron\'s Fiend', 3, 95, 99, -2.148, 4.000, -15.060, 196);
REPLACE INTO `mob_spawn_points` VALUES (17994629, 0, 'JeunoD_Squadron_C', 'Squadron Trickster', 4, 95, 99, -26.648, -0.595, -73.024, 152);
REPLACE INTO `mob_spawn_points` VALUES (17994630, 0, 'JeunoD_Squadron_A', 'Squadron Berserker', 2, 95, 99, -28.159, -0.597, -62.402, 137);
REPLACE INTO `mob_spawn_points` VALUES (17994631, 0, 'JeunoD_Squadron_B', 'Squadron\'s Fiend', 3, 95, 99, 8.713, 2.399, -3.411, 11);
REPLACE INTO `mob_spawn_points` VALUES (17994632, 0, 'JeunoD_Squadron_C', 'Squadron Trickster', 4, 95, 99, -28.800, -0.597, -55.027, 137);
REPLACE INTO `mob_spawn_points` VALUES (17994633, 0, 'JeunoD_Squadron_A', 'Squadron Berserker', 2, 95, 99, 5.895, 2.497, -3.213, 129);
REPLACE INTO `mob_spawn_points` VALUES (17994634, 0, 'JeunoD_Squadron_B', 'Squadron\'s Fiend', 3, 95, 99, -37.115, -0.595, -55.282, 189);
REPLACE INTO `mob_spawn_points` VALUES (17994635, 0, 'JeunoD_Squadron_C', 'Squadron Trickster', 4, 95, 99, -37.662, -0.495, -51.629, 194);
REPLACE INTO `mob_spawn_points` VALUES (17994636, 0, 'JeunoD_Squadron_A', 'Squadron Berserker', 2, 95, 99, -37.337, -0.595, -49.359, 65);
REPLACE INTO `mob_spawn_points` VALUES (17994637, 0, 'JeunoD_Squadron_B', 'Squadron\'s Fiend', 3, 95, 99, -38.217, -0.495, -50.561, 155);
REPLACE INTO `mob_spawn_points` VALUES (17994638, 0, 'JeunoD_Squadron_C', 'Squadron Trickster', 4, 95, 99, -38.000, -0.219, -49.151, 136);
REPLACE INTO `mob_spawn_points` VALUES (17994639, 0, 'JeunoD_Squadron_A', 'Squadron Berserker', 2, 95, 99, -34.238, -0.500, -35.540, 39);
REPLACE INTO `mob_spawn_points` VALUES (17994640, 0, 'JeunoD_Squadron_B', 'Squadron\'s Fiend', 3, 95, 99, -36.999, -0.599, -39.221, 132);
REPLACE INTO `mob_spawn_points` VALUES (17994641, 0, 'JeunoD_Squadron_C', 'Squadron Trickster', 4, 95, 99, -37.623, -0.599, -39.861, 195);
REPLACE INTO `mob_spawn_points` VALUES (17994642, 0, 'JeunoD_Squadron_A', 'Squadron Berserker', 2, 95, 99, -19.515, 2.988, -6.545, 217);
REPLACE INTO `mob_spawn_points` VALUES (17994643, 0, 'JeunoD_Squadron_B', 'Squadron\'s Fiend', 3, 95, 99, -19.259, 2.500, -5.104, 193);
REPLACE INTO `mob_spawn_points` VALUES (17994644, 0, 'JeunoD_Squadron_C', 'Squadron Trickster', 4, 95, 99, -30.602, 2.400, -18.634, 182);
REPLACE INTO `mob_spawn_points` VALUES (17994645, 0, 'JeunoD_Squadron_A', 'Squadron Berserker', 2, 95, 99, -21.299, 2.400, -4.747, 101);
REPLACE INTO `mob_spawn_points` VALUES (17994646, 0, 'JeunoD_Squadron_B', 'Squadron\'s Fiend', 3, 95, 99, -32.949, 2.399, -17.375, 65);
REPLACE INTO `mob_spawn_points` VALUES (17994647, 0, 'JeunoD_Squadron_C', 'Squadron Trickster', 4, 95, 99, -48.690, 9.718, -22.325, 149);

-- ── Statues: 10 time-extension statues spread 15-90% along corridor ──
REPLACE INTO `mob_spawn_points` VALUES (17994648, 0, 'JeunoD_Statue', 'Impish Statue', 5, 99, 99, 19.849, -0.498, -73.261, 105);
REPLACE INTO `mob_spawn_points` VALUES (17994649, 0, 'JeunoD_Statue', 'Impish Statue', 5, 99, 99, 18.201, 8.500, -34.451, 7);
REPLACE INTO `mob_spawn_points` VALUES (17994650, 0, 'JeunoD_Statue', 'Impish Statue', 5, 99, 99, 29.040, -0.535, -21.201, 188);
REPLACE INTO `mob_spawn_points` VALUES (17994651, 0, 'JeunoD_Statue', 'Impish Statue', 5, 99, 99, 21.160, 0.000, -7.386, 214);
REPLACE INTO `mob_spawn_points` VALUES (17994652, 0, 'JeunoD_Statue', 'Impish Statue', 5, 99, 99, -28.800, -0.597, -55.027, 137);
REPLACE INTO `mob_spawn_points` VALUES (17994653, 0, 'JeunoD_Statue', 'Impish Statue', 5, 99, 99, -17.152, 2.633, -4.719, 238);
REPLACE INTO `mob_spawn_points` VALUES (17994654, 0, 'JeunoD_Statue', 'Impish Statue', 5, 99, 99, -53.960, 5.409, -10.837, 162);
REPLACE INTO `mob_spawn_points` VALUES (17994655, 0, 'JeunoD_Statue', 'Impish Statue', 5, 99, 99, -56.806, 5.999, -1.818, 16);
REPLACE INTO `mob_spawn_points` VALUES (17994656, 0, 'JeunoD_Statue', 'Impish Statue', 5, 99, 99, 13.664, 1.615, 66.393, 4);
REPLACE INTO `mob_spawn_points` VALUES (17994657, 0, 'JeunoD_Statue', 'Impish Statue', 5, 99, 99, -13.471, 1.400, 70.353, 100);

-- ── Wave 2 corridor: 48 trash spread mid-boss -> mega-boss (band 55-95%) ──
REPLACE INTO `mob_spawn_points` VALUES (17994658, 0, 'JeunoD_Regiment_A', 'Regiment Berserker', 6, 97, 99, -57.498, 11.377, -33.822, 196);
REPLACE INTO `mob_spawn_points` VALUES (17994659, 0, 'JeunoD_Regiment_B', 'Regiment\'s Fiend', 7, 97, 99, -56.118, 11.479, -27.656, 82);
REPLACE INTO `mob_spawn_points` VALUES (17994660, 0, 'JeunoD_Regiment_C', 'Regiment Trickster', 8, 97, 99, 13.523, 1.400, 39.323, 41);
REPLACE INTO `mob_spawn_points` VALUES (17994661, 0, 'JeunoD_Regiment_A', 'Regiment Berserker', 6, 97, 99, -59.190, 11.500, -28.240, 239);
REPLACE INTO `mob_spawn_points` VALUES (17994662, 0, 'JeunoD_Regiment_B', 'Regiment\'s Fiend', 7, 97, 99, -57.349, 11.399, -22.852, 135);
REPLACE INTO `mob_spawn_points` VALUES (17994663, 0, 'JeunoD_Regiment_C', 'Regiment Trickster', 8, 97, 99, 14.511, -5.849, 42.249, 67);
REPLACE INTO `mob_spawn_points` VALUES (17994664, 0, 'JeunoD_Regiment_A', 'Regiment Berserker', 6, 97, 99, 10.959, 1.400, 43.162, 67);
REPLACE INTO `mob_spawn_points` VALUES (17994665, 0, 'JeunoD_Regiment_B', 'Regiment\'s Fiend', 7, 97, 99, 1.370, -5.798, 38.835, 132);
REPLACE INTO `mob_spawn_points` VALUES (17994666, 0, 'JeunoD_Regiment_C', 'Regiment Trickster', 8, 97, 99, 13.080, 1.400, 44.113, 163);
REPLACE INTO `mob_spawn_points` VALUES (17994667, 0, 'JeunoD_Regiment_A', 'Regiment Berserker', 6, 97, 99, -55.643, 5.405, -7.396, 176);
REPLACE INTO `mob_spawn_points` VALUES (17994668, 0, 'JeunoD_Regiment_B', 'Regiment\'s Fiend', 7, 97, 99, -60.177, 5.400, -15.276, 0);
REPLACE INTO `mob_spawn_points` VALUES (17994669, 0, 'JeunoD_Regiment_C', 'Regiment Trickster', 8, 97, 99, 11.863, 1.400, 45.700, 161);
REPLACE INTO `mob_spawn_points` VALUES (17994670, 0, 'JeunoD_Regiment_A', 'Regiment Berserker', 6, 97, 99, -56.234, 5.500, -5.880, 154);
REPLACE INTO `mob_spawn_points` VALUES (17994671, 0, 'JeunoD_Regiment_B', 'Regiment\'s Fiend', 7, 97, 99, -9.932, 1.399, 38.362, 62);
REPLACE INTO `mob_spawn_points` VALUES (17994672, 0, 'JeunoD_Regiment_C', 'Regiment Trickster', 8, 97, 99, 0.144, 1.756, 43.922, 81);
REPLACE INTO `mob_spawn_points` VALUES (17994673, 0, 'JeunoD_Regiment_A', 'Regiment Berserker', 6, 97, 99, -58.156, 5.400, -6.159, 167);
REPLACE INTO `mob_spawn_points` VALUES (17994674, 0, 'JeunoD_Regiment_B', 'Regiment\'s Fiend', 7, 97, 99, 0.095, 1.500, 44.937, 144);
REPLACE INTO `mob_spawn_points` VALUES (17994675, 0, 'JeunoD_Regiment_C', 'Regiment Trickster', 8, 97, 99, -65.010, 5.500, -16.206, 202);
REPLACE INTO `mob_spawn_points` VALUES (17994676, 0, 'JeunoD_Regiment_A', 'Regiment Berserker', 6, 97, 99, -66.984, 5.400, -17.737, 53);
REPLACE INTO `mob_spawn_points` VALUES (17994677, 0, 'JeunoD_Regiment_B', 'Regiment\'s Fiend', 7, 97, 99, -14.347, -5.922, 39.553, 59);
REPLACE INTO `mob_spawn_points` VALUES (17994678, 0, 'JeunoD_Regiment_C', 'Regiment Trickster', 8, 97, 99, -58.763, 5.400, -0.782, 93);
REPLACE INTO `mob_spawn_points` VALUES (17994679, 0, 'JeunoD_Regiment_A', 'Regiment Berserker', 6, 97, 99, -14.460, -5.922, 41.967, 59);
REPLACE INTO `mob_spawn_points` VALUES (17994680, 0, 'JeunoD_Regiment_B', 'Regiment\'s Fiend', 7, 97, 99, 11.470, 1.400, 54.486, 134);
REPLACE INTO `mob_spawn_points` VALUES (17994681, 0, 'JeunoD_Regiment_C', 'Regiment Trickster', 8, 97, 99, 10.027, 1.500, 54.662, 67);
REPLACE INTO `mob_spawn_points` VALUES (17994682, 0, 'JeunoD_Regiment_A', 'Regiment Berserker', 6, 97, 99, -67.983, 5.400, -4.665, 31);
REPLACE INTO `mob_spawn_points` VALUES (17994683, 0, 'JeunoD_Regiment_B', 'Regiment\'s Fiend', 7, 97, 99, 10.886, 1.400, 59.295, 87);
REPLACE INTO `mob_spawn_points` VALUES (17994684, 0, 'JeunoD_Regiment_C', 'Regiment Trickster', 8, 97, 99, 23.000, 1.500, 64.000, 55);
REPLACE INTO `mob_spawn_points` VALUES (17994685, 0, 'JeunoD_Regiment_A', 'Regiment Berserker', 6, 97, 99, -13.852, 1.400, 52.596, 186);
REPLACE INTO `mob_spawn_points` VALUES (17994686, 0, 'JeunoD_Regiment_B', 'Regiment\'s Fiend', 7, 97, 99, -69.024, 5.400, 3.028, 122);
REPLACE INTO `mob_spawn_points` VALUES (17994687, 0, 'JeunoD_Regiment_C', 'Regiment Trickster', 8, 97, 99, 13.664, 1.615, 66.393, 4);
REPLACE INTO `mob_spawn_points` VALUES (17994688, 0, 'JeunoD_Regiment_A', 'Regiment Berserker', 6, 97, 99, 13.436, 1.500, 68.693, 29);
REPLACE INTO `mob_spawn_points` VALUES (17994689, 0, 'JeunoD_Regiment_B', 'Regiment\'s Fiend', 7, 97, 99, -73.041, 5.400, 6.496, 133);
REPLACE INTO `mob_spawn_points` VALUES (17994690, 0, 'JeunoD_Regiment_C', 'Regiment Trickster', 8, 97, 99, -10.587, 1.500, 61.318, 75);
REPLACE INTO `mob_spawn_points` VALUES (17994691, 0, 'JeunoD_Regiment_A', 'Regiment Berserker', 6, 97, 99, 12.442, 1.400, 69.607, 228);
REPLACE INTO `mob_spawn_points` VALUES (17994692, 0, 'JeunoD_Regiment_B', 'Regiment\'s Fiend', 7, 97, 99, -73.626, 5.400, 9.305, 176);
REPLACE INTO `mob_spawn_points` VALUES (17994693, 0, 'JeunoD_Regiment_C', 'Regiment Trickster', 8, 97, 99, 8.561, 1.400, 70.903, 53);
REPLACE INTO `mob_spawn_points` VALUES (17994694, 0, 'JeunoD_Regiment_A', 'Regiment Berserker', 6, 97, 99, -10.102, -5.500, 65.898, 121);
REPLACE INTO `mob_spawn_points` VALUES (17994695, 0, 'JeunoD_Regiment_B', 'Regiment\'s Fiend', 7, 97, 99, -9.120, 1.400, 67.003, 97);
REPLACE INTO `mob_spawn_points` VALUES (17994696, 0, 'JeunoD_Regiment_C', 'Regiment Trickster', 8, 97, 99, -10.568, 1.400, 68.006, 21);
REPLACE INTO `mob_spawn_points` VALUES (17994697, 0, 'JeunoD_Regiment_A', 'Regiment Berserker', 6, 97, 99, -14.354, -5.000, 66.490, 42);
REPLACE INTO `mob_spawn_points` VALUES (17994698, 0, 'JeunoD_Regiment_B', 'Regiment\'s Fiend', 7, 97, 99, -23.000, 1.500, 64.000, 183);
REPLACE INTO `mob_spawn_points` VALUES (17994699, 0, 'JeunoD_Regiment_C', 'Regiment Trickster', 8, 97, 99, -13.471, 1.400, 70.353, 100);
REPLACE INTO `mob_spawn_points` VALUES (17994700, 0, 'JeunoD_Regiment_A', 'Regiment Berserker', 6, 97, 99, 1.122, 2.500, 105.777, 71);
REPLACE INTO `mob_spawn_points` VALUES (17994701, 0, 'JeunoD_Regiment_B', 'Regiment\'s Fiend', 7, 97, 99, -2.164, 2.500, 106.255, 209);
REPLACE INTO `mob_spawn_points` VALUES (17994702, 0, 'JeunoD_Regiment_C', 'Regiment Trickster', 8, 97, 99, -2.084, 2.500, 107.186, 57);
REPLACE INTO `mob_spawn_points` VALUES (17994703, 0, 'JeunoD_Regiment_A', 'Regiment Berserker', 6, 97, 99, 1.255, 2.486, 111.045, 63);
REPLACE INTO `mob_spawn_points` VALUES (17994704, 0, 'JeunoD_Regiment_B', 'Regiment\'s Fiend', 7, 97, 99, -0.508, 2.499, 112.929, 190);
REPLACE INTO `mob_spawn_points` VALUES (17994705, 0, 'JeunoD_Regiment_C', 'Regiment Trickster', 8, 97, 99, 0.320, 2.599, 114.251, 169);

-- ── Bosses (existing mobids, RELOCATED to corridor midpoint / far end) ──
REPLACE INTO `mob_spawn_points` VALUES (17993730, 0, 'ImpishGolem_JeunoD', 'Impish Golem', 1, 99, 99, -32.949, 2.399, -17.375, 65);
REPLACE INTO `mob_spawn_points` VALUES (17994068, 0, 'Obstatrix_JeunoD', 'Obstatrix', 9, 99, 99, 0.827, 1.668, 121.848, 205);
REPLACE INTO `mob_spawn_points` VALUES (17994487, 0, 'Disjoined_Mithra_D', 'Disjoined Mithra', 10, 99, 99, -1.107, 1.332, 129.604, 205);

-- ── instance_entities: register all 109 mobs ──
DELETE FROM `instance_entities` WHERE `instanceid` = 29700;
REPLACE INTO `instance_entities` VALUES (29700, 17994600);
REPLACE INTO `instance_entities` VALUES (29700, 17994601);
REPLACE INTO `instance_entities` VALUES (29700, 17994602);
REPLACE INTO `instance_entities` VALUES (29700, 17994603);
REPLACE INTO `instance_entities` VALUES (29700, 17994604);
REPLACE INTO `instance_entities` VALUES (29700, 17994605);
REPLACE INTO `instance_entities` VALUES (29700, 17994606);
REPLACE INTO `instance_entities` VALUES (29700, 17994607);
REPLACE INTO `instance_entities` VALUES (29700, 17994608);
REPLACE INTO `instance_entities` VALUES (29700, 17994609);
REPLACE INTO `instance_entities` VALUES (29700, 17994610);
REPLACE INTO `instance_entities` VALUES (29700, 17994611);
REPLACE INTO `instance_entities` VALUES (29700, 17994612);
REPLACE INTO `instance_entities` VALUES (29700, 17994613);
REPLACE INTO `instance_entities` VALUES (29700, 17994614);
REPLACE INTO `instance_entities` VALUES (29700, 17994615);
REPLACE INTO `instance_entities` VALUES (29700, 17994616);
REPLACE INTO `instance_entities` VALUES (29700, 17994617);
REPLACE INTO `instance_entities` VALUES (29700, 17994618);
REPLACE INTO `instance_entities` VALUES (29700, 17994619);
REPLACE INTO `instance_entities` VALUES (29700, 17994620);
REPLACE INTO `instance_entities` VALUES (29700, 17994621);
REPLACE INTO `instance_entities` VALUES (29700, 17994622);
REPLACE INTO `instance_entities` VALUES (29700, 17994623);
REPLACE INTO `instance_entities` VALUES (29700, 17994624);
REPLACE INTO `instance_entities` VALUES (29700, 17994625);
REPLACE INTO `instance_entities` VALUES (29700, 17994626);
REPLACE INTO `instance_entities` VALUES (29700, 17994627);
REPLACE INTO `instance_entities` VALUES (29700, 17994628);
REPLACE INTO `instance_entities` VALUES (29700, 17994629);
REPLACE INTO `instance_entities` VALUES (29700, 17994630);
REPLACE INTO `instance_entities` VALUES (29700, 17994631);
REPLACE INTO `instance_entities` VALUES (29700, 17994632);
REPLACE INTO `instance_entities` VALUES (29700, 17994633);
REPLACE INTO `instance_entities` VALUES (29700, 17994634);
REPLACE INTO `instance_entities` VALUES (29700, 17994635);
REPLACE INTO `instance_entities` VALUES (29700, 17994636);
REPLACE INTO `instance_entities` VALUES (29700, 17994637);
REPLACE INTO `instance_entities` VALUES (29700, 17994638);
REPLACE INTO `instance_entities` VALUES (29700, 17994639);
REPLACE INTO `instance_entities` VALUES (29700, 17994640);
REPLACE INTO `instance_entities` VALUES (29700, 17994641);
REPLACE INTO `instance_entities` VALUES (29700, 17994642);
REPLACE INTO `instance_entities` VALUES (29700, 17994643);
REPLACE INTO `instance_entities` VALUES (29700, 17994644);
REPLACE INTO `instance_entities` VALUES (29700, 17994645);
REPLACE INTO `instance_entities` VALUES (29700, 17994646);
REPLACE INTO `instance_entities` VALUES (29700, 17994647);
REPLACE INTO `instance_entities` VALUES (29700, 17994648);
REPLACE INTO `instance_entities` VALUES (29700, 17994649);
REPLACE INTO `instance_entities` VALUES (29700, 17994650);
REPLACE INTO `instance_entities` VALUES (29700, 17994651);
REPLACE INTO `instance_entities` VALUES (29700, 17994652);
REPLACE INTO `instance_entities` VALUES (29700, 17994653);
REPLACE INTO `instance_entities` VALUES (29700, 17994654);
REPLACE INTO `instance_entities` VALUES (29700, 17994655);
REPLACE INTO `instance_entities` VALUES (29700, 17994656);
REPLACE INTO `instance_entities` VALUES (29700, 17994657);
REPLACE INTO `instance_entities` VALUES (29700, 17994658);
REPLACE INTO `instance_entities` VALUES (29700, 17994659);
REPLACE INTO `instance_entities` VALUES (29700, 17994660);
REPLACE INTO `instance_entities` VALUES (29700, 17994661);
REPLACE INTO `instance_entities` VALUES (29700, 17994662);
REPLACE INTO `instance_entities` VALUES (29700, 17994663);
REPLACE INTO `instance_entities` VALUES (29700, 17994664);
REPLACE INTO `instance_entities` VALUES (29700, 17994665);
REPLACE INTO `instance_entities` VALUES (29700, 17994666);
REPLACE INTO `instance_entities` VALUES (29700, 17994667);
REPLACE INTO `instance_entities` VALUES (29700, 17994668);
REPLACE INTO `instance_entities` VALUES (29700, 17994669);
REPLACE INTO `instance_entities` VALUES (29700, 17994670);
REPLACE INTO `instance_entities` VALUES (29700, 17994671);
REPLACE INTO `instance_entities` VALUES (29700, 17994672);
REPLACE INTO `instance_entities` VALUES (29700, 17994673);
REPLACE INTO `instance_entities` VALUES (29700, 17994674);
REPLACE INTO `instance_entities` VALUES (29700, 17994675);
REPLACE INTO `instance_entities` VALUES (29700, 17994676);
REPLACE INTO `instance_entities` VALUES (29700, 17994677);
REPLACE INTO `instance_entities` VALUES (29700, 17994678);
REPLACE INTO `instance_entities` VALUES (29700, 17994679);
REPLACE INTO `instance_entities` VALUES (29700, 17994680);
REPLACE INTO `instance_entities` VALUES (29700, 17994681);
REPLACE INTO `instance_entities` VALUES (29700, 17994682);
REPLACE INTO `instance_entities` VALUES (29700, 17994683);
REPLACE INTO `instance_entities` VALUES (29700, 17994684);
REPLACE INTO `instance_entities` VALUES (29700, 17994685);
REPLACE INTO `instance_entities` VALUES (29700, 17994686);
REPLACE INTO `instance_entities` VALUES (29700, 17994687);
REPLACE INTO `instance_entities` VALUES (29700, 17994688);
REPLACE INTO `instance_entities` VALUES (29700, 17994689);
REPLACE INTO `instance_entities` VALUES (29700, 17994690);
REPLACE INTO `instance_entities` VALUES (29700, 17994691);
REPLACE INTO `instance_entities` VALUES (29700, 17994692);
REPLACE INTO `instance_entities` VALUES (29700, 17994693);
REPLACE INTO `instance_entities` VALUES (29700, 17994694);
REPLACE INTO `instance_entities` VALUES (29700, 17994695);
REPLACE INTO `instance_entities` VALUES (29700, 17994696);
REPLACE INTO `instance_entities` VALUES (29700, 17994697);
REPLACE INTO `instance_entities` VALUES (29700, 17994698);
REPLACE INTO `instance_entities` VALUES (29700, 17994699);
REPLACE INTO `instance_entities` VALUES (29700, 17994700);
REPLACE INTO `instance_entities` VALUES (29700, 17994701);
REPLACE INTO `instance_entities` VALUES (29700, 17994702);
REPLACE INTO `instance_entities` VALUES (29700, 17994703);
REPLACE INTO `instance_entities` VALUES (29700, 17994704);
REPLACE INTO `instance_entities` VALUES (29700, 17994705);
REPLACE INTO `instance_entities` VALUES (29700, 17993730);
REPLACE INTO `instance_entities` VALUES (29700, 17994068);
REPLACE INTO `instance_entities` VALUES (29700, 17994487);

-- ── instance_list (unchanged) ──
REPLACE INTO `instance_list` VALUES (29700, 'dynamis_jeuno_d', 297, 243, 90, 48.930, 10.002, -71.032, 195, NULL, NULL, NULL, NULL);

-- ── mob_droplist (unchanged) ──
DELETE FROM `mob_droplist` WHERE `dropId` IN (29701, 29702, 29703, 29704);
INSERT INTO `mob_droplist` VALUES (29701, 0, 0, 1000, 9539, @ALWAYS);
INSERT INTO `mob_droplist` VALUES (29701, 0, 0, 1000, 9539, @COMMON);
INSERT INTO `mob_droplist` VALUES (29702, 0, 0, 1000, 9539, @UNCOMMON);
INSERT INTO `mob_droplist` VALUES (29703, 0, 0, 1000, 9541, @UNCOMMON);
INSERT INTO `mob_droplist` VALUES (29704, 0, 0, 1000, 9541, @ALWAYS);
INSERT INTO `mob_droplist` VALUES (29704, 0, 0, 1000, 9541, @COMMON);
INSERT INTO `mob_droplist` VALUES (29704, 0, 0, 1000, 9543, @UNCOMMON);

-- ============================================================================
-- Wave 3: Disjoined NM mob_groups + droplists. Spawn coords + instance_entities
-- are now inside each per-zone block above (relocated to the far corner as part
-- of the corridor pass). Only mob_groups + droplists live here (cross-zone).
-- ============================================================================
REPLACE INTO `mob_groups` VALUES (10, 1387, 294, 'Disjoined_Elvaan_D',   0, 128, 29405, 80000, 2000, 0, NULL);
REPLACE INTO `mob_groups` VALUES (10, 1385, 295, 'Disjoined_Galka_D',    0, 128, 29505, 80000, 2000, 0, NULL);
REPLACE INTO `mob_groups` VALUES (10, 1382, 296, 'Disjoined_Tarutaru_D', 0, 128, 29605, 75000, 3000, 0, NULL);
REPLACE INTO `mob_groups` VALUES (10, 1388, 297, 'Disjoined_Mithra_D',   0, 128, 29705, 80000, 2000, 0, NULL);
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

