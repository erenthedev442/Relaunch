-- ============================================================
-- affinity_nm_spawns.sql
-- Places the 24 Augment-Sage affinity NMs (augment_affinity_catalog.lua) as
-- 15-minute (900s) NORMAL timed spawns in their menu zones, so the affinity
-- hunt is actually farmable. Each reuses the NM's real pool + droplist (full
-- retail loot); HP/MP=0 -> engine calculates HP/MP from the spawn-point level.
--
-- Reserved IDs:  groupid 20000-20023,  mobid = (zoneid<<12)|(3840+idx).
-- Existing retail/custom/HL spawns of these NMs are LEFT UNTOUCHED (separate ids).
--
-- Relocations (the menu zone cannot host a static overworld spawn):
--   Genbu / Seiryu / Suzaku / Kirin : Hall of the Gods (251, empty)  -> The Shrine of Ru'Avitau (178)
--   Proto-Omega                     : Temenos (37, instanced Limbus)  -> Ru'Aun Gardens (130)
--   (augment_affinity_catalog.lua nmZone updated to match; 178 + 130 are affinity-hooked, so grants fire.)
-- Phoenix has NO mob in the DB -> a Phoenix pool (30002) is cloned from Suzaku (3816), renamed.
--
-- Idempotent + reversible: the DELETEs below + re-run.  Applied unconditionally
-- by the deploy ledger (modules/custom/sql), so it persists across rebuilds.
-- ============================================================

-- ---- Phoenix mob pool: clone Suzaku (3816), rename to 'Phoenix' (poolid 30002) ----
DELETE FROM `mob_pools` WHERE `poolid` = 30002;
CREATE TEMPORARY TABLE `_phx` AS SELECT * FROM `mob_pools` WHERE `poolid` = 3816;
UPDATE `_phx` SET `poolid` = 30002, `name` = 'Phoenix', `packet_name` = 'Phoenix';
INSERT INTO `mob_pools` SELECT * FROM `_phx`;
DROP TEMPORARY TABLE `_phx`;

-- ---- mob_groups: respawntime=900, spawntype=0 (NORMAL timed), real dropid, HP/MP=0 (calc from level) ----
-- cols: groupid, poolid, zoneid, name, respawntime, spawntype, dropid, HP, MP, allegiance, content_tag
DELETE FROM `mob_groups` WHERE `groupid` BETWEEN 20000 AND 20023;
INSERT INTO `mob_groups` VALUES
 (20000,   387, 105, 'Behemoth',         900, 0,  251, 0, 0, 0, NULL),
 (20001,  2255, 127, 'King_Behemoth',    900, 0, 1450, 0, 0, 0, NULL),
 (20002,  2254, 174, 'King_Arthro',      900, 0, 1449, 0, 0, 0, NULL),
 (20003,  3630, 110, 'Simurgh',          900, 0, 2255, 0, 0, 0, NULL),
 (20004,    44, 128, 'Adamantoise',      900, 0,   21, 0, 0, 0, NULL),
 (20005,  1491, 178, 'Genbu',            900, 0,  946, 0, 0, 0, NULL),
 (20006,  3376, 120, 'Roc',              900, 0, 2112, 0, 0, 0, NULL),
 (20007,  3540, 178, 'Seiryu',           900, 0, 2196, 0, 0, 0, NULL),
 (20008,   592, 178, 'Byakko',           900, 0,  394, 0, 0, 0, NULL),
 (20009,   268, 113, 'Aspidochelone',    900, 0,  183, 0, 0, 0, NULL),
 (20010,  3070,  29, 'Ouryu',            900, 0, 1962, 0, 0, 0, NULL),
 (20011,   584, 153, 'Bune',             900, 0,  389, 0, 0, 0, NULL),
 (20012, 30002,  30, 'Phoenix',          900, 0, 2362, 0, 0, 0, NULL),
 (20013,  3816, 178, 'Suzaku',           900, 0, 2362, 0, 0, 0, NULL),
 (20014,  2265, 178, 'Kirin',            900, 0, 2819, 0, 0, 0, NULL),
 (20015,  1280, 154, 'Fafnir',           900, 0,  805, 0, 0, 0, NULL),
 (20016,  2840, 154, 'Nidhogg',          900, 0, 1781, 0, 0, 0, NULL),
 (20017,  4261, 205, 'Vrtra',            900, 0, 2592, 0, 0, 0, NULL),
 (20018,  3916,   5, 'Tiamat',           900, 0, 2416, 0, 0, 0, NULL),
 (20019,  2262, 125, 'King_Vinegarroon', 900, 0, 1451, 0, 0, 0, NULL),
 (20020,  2220, 190, 'Khimaira',         900, 0, 1437, 0, 0, 0, NULL),
 (20021,   680, 190, 'Cerberus',         900, 0,  446, 0, 0, 0, NULL),
 (20022,    21, 130, 'Absolute_Virtue',  900, 0,    3, 0, 0, 0, NULL),
 (20023,  3208, 130, 'Proto-Omega',      900, 0,    0, 0, 0, 0, NULL);

-- ---- mob_spawn_points: one timed spawn per NM at a valid in-zone coord ----
-- cols: mobid, spawnslotid, mobname, polutils_name, groupid, minLevel, maxLevel, pos_x, pos_y, pos_z, pos_rot
DELETE FROM `mob_spawn_points` WHERE `groupid` BETWEEN 20000 AND 20023;
INSERT INTO `mob_spawn_points` VALUES
 (433921, 0, 'Behemoth',         'Behemoth',          20000,  80,  80, -670.00, -23.00,  352.00, 0),
 (524034, 0, 'King_Behemoth',    'King Behemoth',     20001,  85,  85,  171.18,   4.29, -124.58, 0),
 (716547, 0, 'King_Arthro',      'King Arthro',       20002,  55,  55,  -27.91, -10.69, -185.26, 0),
 (454404, 0, 'Simurgh',          'Simurgh',           20003,  80,  80, -682.25, -31.61, -433.62, 0),
 (528133, 0, 'Adamantoise',      'Adamantoise',       20004,  80,  80,  -98.00,  -0.05,  -39.00, 0),
 (732934, 0, 'Genbu',            'Genbu',             20005, 125, 125,  892.85,  99.50,  718.02, 0),
 (495367, 0, 'Roc',              'Roc',               20006,  80,  80,  479.94,   7.67, -286.00, 0),
 (732936, 0, 'Seiryu',           'Seiryu',            20007, 125, 125,  901.36,  99.50,  695.60, 0),
 (732937, 0, 'Byakko',           'Byakko',            20008, 125, 125,  901.26,  99.50,  666.78, 0),
 (466698, 0, 'Aspidochelone',    'Aspidochelone',     20009,  85,  85, -175.33,   7.68, -247.30, 0),
 (122635, 0, 'Ouryu',            'Ouryu',             20010,  99,  99,  618.78,   0.56, -552.23, 0),
 (630540, 0, 'Bune',             'Bune',              20011,  83,  83,  405.43,  11.40,  -98.61, 0),
 (126733, 0, 'Phoenix',          'Phoenix',           20012,  90,  90,  682.74, -31.76, -500.81, 0),
 (732942, 0, 'Suzaku',           'Suzaku',            20013, 125, 125,  882.13,  99.79,  648.93, 0),
 (732943, 0, 'Kirin',            'Kirin',             20014, 124, 124,  866.85,  99.50,  622.56, 0),
 (634640, 0, 'Fafnir',           'Fafnir',            20015,  90,  90,  -63.39,  -1.56,   16.26, 0),
 (634641, 0, 'Nidhogg',          'Nidhogg',           20016,  90,  90,  -60.87,  -1.55,  -11.13, 0),
 (843538, 0, 'Vrtra',            'Vrtra',             20017,  95,  95,  168.79,   0.90,  -19.83, 0),
 ( 24339, 0, 'Tiamat',           'Tiamat',            20018,  95,  95, -242.35, -39.88, -415.62, 0),
 (515860, 0, 'King_Vinegarroon', 'King Vinegarroon',  20019,  80,  80,  683.42,  -0.78,  -41.82, 0),
 (782101, 0, 'Khimaira',         'Khimaira',          20020,  85,  85, -124.00,  -0.50,  249.52, 0),
 (782102, 0, 'Cerberus',         'Cerberus',          20021,  85,  85, -147.00,  -0.50,  250.00, 0),
 (536343, 0, 'Absolute_Virtue',  'Absolute Virtue',   20022,  92,  92,   -6.03, -40.52, -417.21, 0),
 (536344, 0, 'Proto-Omega',      'Proto-Omega',       20023,  99,  99,    6.84, -38.60, -444.97, 0);
