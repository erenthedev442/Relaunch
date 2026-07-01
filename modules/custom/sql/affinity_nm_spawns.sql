-- ============================================================
-- affinity_nm_spawns.sql
-- Places the 24 Augment-Sage affinity NMs (augment_affinity_catalog.lua) as
-- 15-minute (900s) NORMAL timed spawns in their menu zones, so the affinity
-- hunt is actually farmable. Each reuses the NM's real pool + a DEDICATED 100%
-- trophy droplist (21000-21023): the affinity-register trophy MUST be guaranteed,
-- and the old retail dropids did not even contain the trophy (e.g. Simurgh's
-- 2255 had no Giant Bird Plume). HP/MP=0 -> engine calculates HP/MP from level.
--
-- Reserved IDs:  groupid 20000-20023,  mobid = 0x1000000 | (zoneid<<12) | targid.
--   CRITICAL: a valid mob entity id MUST include the 0x1000000 (16777216) entity
--   base, and its targid (low 12 bits) MUST be < 0x400 (1024). The per-zone entity
--   table is partitioned BY TARGID RANGE (zone_entities.cpp GetEntity): targid
--   < 0x400 = mobs/NPCs/ships, 0x400-0x6FF = PCs ONLY, >= 0x700 = dynamic. A mob at
--   targid >= 0x400 is InsertMOB'd into m_mobList but GetEntity searches m_charList
--   for that range, so GetMobByID never finds it and it never spawns ("Mob doesn't
--   exist"). Real mob+NPC targids in every affinity zone top out at 699, so we use
--   targids 901-924 (0x385-0x39C): free in-zone AND < 0x400.
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

-- ---- mob_groups: respawntime=900, spawntype=0 (NORMAL timed), HP/MP=0 (calc) ----
-- cols: groupid, poolid, zoneid, name, respawntime, spawntype, dropid, HP, MP, allegiance, content_tag
-- dropid = 0: the ENGINE droplist is intentionally NOT used. A droplist id must be
-- < MAX_DROPID (5000, itemutils.h); the dedicated trophy lists below were created at
-- 21000-21023, which GetDropList rejects ("DropID too big") so nothing ever dropped.
-- The registration trophy is instead granted in Lua on death by
-- modules/custom/lua/affinity_nm_autopop.lua (DEATH listener -> killer:addItem).
-- The 21000-range droplist INSERT below is kept only for reference.
DELETE FROM `mob_groups` WHERE `groupid` BETWEEN 20000 AND 20023;
INSERT INTO `mob_groups` VALUES
 (20000,   387, 105, 'Behemoth',         900, 0, 0, 0, 0, 0, NULL),
 (20001,  2255, 127, 'King_Behemoth',    900, 0, 0, 0, 0, 0, NULL),
 (20002,  2254, 174, 'King_Arthro',      900, 0, 0, 0, 0, 0, NULL),
 (20003,  3630, 110, 'Simurgh',          900, 0, 0, 0, 0, 0, NULL),
 (20004,    44, 128, 'Adamantoise',      900, 0, 0, 0, 0, 0, NULL),
 (20005,  1491, 178, 'Genbu',            900, 0, 0, 0, 0, 0, NULL),
 (20006,  3376, 120, 'Roc',              900, 0, 0, 0, 0, 0, NULL),
 (20007,  3540, 178, 'Seiryu',           900, 0, 0, 0, 0, 0, NULL),
 (20008,   592, 178, 'Byakko',           900, 0, 0, 0, 0, 0, NULL),
 (20009,   268, 113, 'Aspidochelone',    900, 0, 0, 0, 0, 0, NULL),
 (20010,  3070,  29, 'Ouryu',            900, 0, 0, 0, 0, 0, NULL),
 (20011,   584, 153, 'Bune',             900, 0, 0, 0, 0, 0, NULL),
 (20012, 30002,  30, 'Phoenix',          900, 0, 0, 0, 0, 0, NULL),
 (20013,  3816, 178, 'Suzaku',           900, 0, 0, 0, 0, 0, NULL),
 (20014,  2265, 178, 'Kirin',            900, 0, 0, 0, 0, 0, NULL),
 (20015,  1280, 154, 'Fafnir',           900, 0, 0, 0, 0, 0, NULL),
 (20016,  2840, 154, 'Nidhogg',          900, 0, 0, 0, 0, 0, NULL),
 (20017,  4261, 205, 'Vrtra',            900, 0, 0, 0, 0, 0, NULL),
 (20018,  3916,   5, 'Tiamat',           900, 0, 0, 0, 0, 0, NULL),
 (20019,  2262, 125, 'King_Vinegarroon', 900, 0, 0, 0, 0, 0, NULL),
 (20020,  2220, 190, 'Khimaira',         900, 0, 0, 0, 0, 0, NULL),
 (20021,   680, 190, 'Cerberus',         900, 0, 0, 0, 0, 0, NULL),
 (20022,    21, 130, 'Absolute_Virtue',  900, 0, 0, 0, 0, 0, NULL),
 (20023,  3208, 130, 'Proto-Omega',      900, 0, 0, 0, 0, 0, NULL);

-- ---- dedicated 100% trophy droplists (21000-21023) ----
-- Each affinity NM drops ONLY its unique registration trophy, GUARANTEED
-- (dropType 0, itemRate 1000 = 100%). The trophy is the Augment-Sage registration
-- gate, so it must always drop. Item ids mirror augment_affinity_catalog.lua.
-- Isolated from retail (retail NM spawns keep their own mob_groups + dropids).
DELETE FROM `mob_droplist` WHERE `dropId` BETWEEN 21000 AND 21023;
INSERT INTO `mob_droplist` (`dropId`,`dropType`,`groupId`,`groupRate`,`itemId`,`itemRate`) VALUES
 (21000, 0, 0, 1000,   860, 1000),  -- Behemoth          -> Behemoth Hide
 (21001, 0, 0, 1000,   883, 1000),  -- King Behemoth     -> Behemoth Horn
 (21002, 0, 0, 1000,  8983, 1000),  -- King Arthro       -> Emperor Arthro's Shell
 (21003, 0, 0, 1000,   843, 1000),  -- Simurgh           -> Giant Bird Plume
 (21004, 0, 0, 1000,   908, 1000),  -- Adamantoise       -> Adamantoise Shell
 (21005, 0, 0, 1000,  1404, 1000),  -- Genbu             -> Seal of Genbu
 (21006, 0, 0, 1000,   842, 1000),  -- Roc               -> Giant Bird Feather
 (21007, 0, 0, 1000,  1405, 1000),  -- Seiryu            -> Seal of Seiryu
 (21008, 0, 0, 1000,  1406, 1000),  -- Byakko            -> Seal of Byakko
 (21009, 0, 0, 1000,  2421, 1000),  -- Aspidochelone     -> Spirit Turtle Shell
 (21010, 0, 0, 1000,   903, 1000),  -- Ouryu             -> Dragon Talon
 (21011, 0, 0, 1000,  2229, 1000),  -- Bune              -> Vial of Chimera Blood
 (21012, 0, 0, 1000,   844, 1000),  -- Phoenix           -> Phoenix Feather
 (21013, 0, 0, 1000,  1407, 1000),  -- Suzaku            -> Seal of Suzaku
 (21014, 0, 0, 1000, 10038, 1000),  -- Kirin             -> Kirin's Mane
 (21015, 0, 0, 1000, 10037, 1000),  -- Fafnir            -> Fafnir's Scale
 (21016, 0, 0, 1000,   865, 1000),  -- Nidhogg           -> Handful of Nidhogg's Scales
 (21017, 0, 0, 1000,  1526, 1000),  -- Vrtra             -> Wyrm Beard
 (21018, 0, 0, 1000,  1816, 1000),  -- Tiamat            -> Wyrm Horn
 (21019, 0, 0, 1000,  1017, 1000),  -- King Vinegarroon  -> Scorpion Stinger
 (21020, 0, 0, 1000,  2372, 1000),  -- Khimaira          -> Khimaira Mane
 (21021, 0, 0, 1000,  2169, 1000),  -- Cerberus          -> Cerberus Hide
 (21022, 0, 0, 1000,  1567, 1000),  -- Absolute Virtue   -> Attestation of Virtue
 (21023, 0, 0, 1000, 15800, 1000);  -- Proto-Omega       -> Omega Ring

-- ---- mob_spawn_points: one timed spawn per NM at a valid in-zone coord ----
-- cols: mobid, spawnslotid, mobname, polutils_name, groupid, minLevel, maxLevel, pos_x, pos_y, pos_z, pos_rot
-- mobid = 16777216 + (zoneid<<12) + targid, with targid = 900+idx (901-924).
-- CRITICAL: a MOB's targid MUST be < 0x400 (1024). The engine partitions the
-- per-zone entity table by targid (zone_entities.cpp CZoneEntities::GetEntity):
--   targid < 0x400  -> mobs / NPCs / ships
--   0x400-0x6FF     -> PCs (players) ONLY
--   >= 0x700        -> dynamic (pets/trusts)
-- A mob placed at targid >= 0x400 is InsertMOB'd into m_mobList but GetEntity
-- looks for it in m_charList, so GetMobByID never finds it and it never spawns.
-- (Both earlier schemes were broken: 3840+idx was >=0x700 dynamic; 1536+idx was
-- in the 0x400-0x6FF PC range.) Existing mob+NPC targids across every affinity
-- zone top out at 699, so 901-924 are free AND < 0x400.
DELETE FROM `mob_spawn_points` WHERE `groupid` BETWEEN 20000 AND 20023;
INSERT INTO `mob_spawn_points` VALUES
 (17208197, 0, 'Behemoth',         'Behemoth',          20000,  80,  80, -670.00, -23.00,  352.00, 0),
 (17298310, 0, 'King_Behemoth',    'King Behemoth',     20001,  85,  85, -267.50, -19.80,   73.70, 0),
 (17490823, 0, 'King_Arthro',      'King Arthro',       20002,  55,  55,  -27.91, -10.69, -185.26, 0),
 (17228680, 0, 'Simurgh',          'Simurgh',           20003,  80,  80, -682.25, -31.61, -433.62, 0),
 (17302409, 0, 'Adamantoise',      'Adamantoise',       20004,  80,  80,  -98.00,  -0.05,  -39.00, 0),
 (17507210, 0, 'Genbu',            'Genbu',             20005, 125, 125,  892.85,  99.50,  718.02, 0),
 (17269643, 0, 'Roc',              'Roc',               20006,  80,  80,  479.94,   7.67, -286.00, 0),
 (17507212, 0, 'Seiryu',           'Seiryu',            20007, 125, 125,  901.36,  99.50,  695.60, 0),
 (17507213, 0, 'Byakko',           'Byakko',            20008, 125, 125,  901.26,  99.50,  666.78, 0),
 (17240974, 0, 'Aspidochelone',    'Aspidochelone',     20009,  85,  85, -175.33,   7.68, -247.30, 0),
 (16896911, 0, 'Ouryu',            'Ouryu',             20010,  99,  99,  618.78,   0.56, -552.23, 0),
 (17404816, 0, 'Bune',             'Bune',              20011,  83,  83,  405.43,  11.40,  -98.61, 0),
 (16901009, 0, 'Phoenix',          'Phoenix',           20012,  90,  90,  682.74, -31.76, -500.81, 0),
 (17507218, 0, 'Suzaku',           'Suzaku',            20013, 125, 125,  882.13,  99.79,  648.93, 0),
 (17507219, 0, 'Kirin',            'Kirin',             20014, 124, 124,  866.85,  99.50,  622.56, 0),
 (17408916, 0, 'Fafnir',           'Fafnir',            20015,  90,  90,  -63.39,  -1.56,   16.26, 0),
 (17408917, 0, 'Nidhogg',          'Nidhogg',           20016,  90,  90,  -60.87,  -1.55,  -11.13, 0),
 (17617814, 0, 'Vrtra',            'Vrtra',             20017,  95,  95,  168.79,   0.90,  -19.83, 0),
 (16798615, 0, 'Tiamat',           'Tiamat',            20018,  95,  95, -242.35, -39.88, -415.62, 0),
 (17290136, 0, 'King_Vinegarroon', 'King Vinegarroon',  20019,  80,  80,  683.42,  -0.78,  -41.82, 0),
 (17556377, 0, 'Khimaira',         'Khimaira',          20020,  85,  85, -124.00,  -0.50,  249.52, 0),
 (17556378, 0, 'Cerberus',         'Cerberus',          20021,  85,  85, -147.00,  -0.50,  250.00, 0),
 (17310619, 0, 'Absolute_Virtue',  'Absolute Virtue',   20022,  92,  92,   -6.03, -40.52, -417.21, 0),
 (17310620, 0, 'Proto-Omega',      'Proto-Omega',       20023,  99,  99,    6.84, -38.60, -444.97, 0);
