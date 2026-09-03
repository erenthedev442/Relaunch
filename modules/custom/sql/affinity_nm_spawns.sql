-- ============================================================
-- affinity_nm_spawns.sql
-- Places the 24 Augment-Sage affinity NMs (augment_affinity_catalog.lua) as
-- 15-minute (900s) NORMAL timed spawns in their menu zones, so the affinity
-- hunt is actually farmable. Each reuses the NM's real pool and, where the repo
-- has one, its retail dropid. The affinity-register trophy is still guaranteed
-- from Lua because old retail dropids did not always contain that trophy (e.g.
-- Simurgh's 2255 had no Giant Bird Plume). HP/MP=0 -> engine calculates HP/MP
-- from level.
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
-- Relocations (only when the retail zone cannot host a static overworld spawn):
--   Proto-Omega : Temenos (37, instanced Limbus) -> Sealion's Den (32, lobby cave)
--     Do NOT park him on the airship (Y=-231). One to be Feared / Warrior's Path
--     copies sit on that deck; the overworld NM then renders as an untargetable
--     ghost beside Omega. Lobby is 600/130/780, between the Tavnazian zoneline
--     (600/130/797) and the Iron Gate (612/132/774).
--   Phoenix     : no retail overworld NM -> Riverne Site A01 (30), Suzaku-cloned pool 30002
-- Sky gods stay on their Ru'Aun islands. Kirin stays in the Shrine of Ru'Avitau.
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
-- Retail dropids are used for nostalgic HNM loot (Defending Ring, Ridill,
-- abjurations, god gear, etc.). The registration trophy is still granted in Lua
-- on death by modules/custom/lua/affinity_nm_autopop.lua (DEATH listener ->
-- killer:addItem). The 21000-range trophy INSERT below is kept only for
-- reference; GetDropList rejects those ids because MAX_DROPID is 5000.
DELETE FROM `mob_groups` WHERE `groupid` BETWEEN 20000 AND 20023;
INSERT INTO `mob_groups` VALUES
 (20000,   387, 127, 'Behemoth',         900, 0,  251, 0, 0, 0, NULL),
 (20001,  2255, 127, 'King_Behemoth',    900, 0, 1450, 0, 0, 0, NULL),
 (20002,  2254, 104, 'King_Arthro',      900, 0, 1449, 0, 0, 0, NULL),
 (20003,  3630, 110, 'Simurgh',          900, 0, 2255, 0, 0, 0, NULL),
 (20004,    44, 128, 'Adamantoise',      900, 0,   21, 0, 0, 0, NULL),
 (20005,  1491, 130, 'Genbu',            900, 0,  946, 0, 0, 0, NULL),
 (20006,  3376, 120, 'Roc',              900, 0, 2112, 0, 0, 0, NULL),
 (20007,  3540, 130, 'Seiryu',           900, 0, 2196, 0, 0, 0, NULL),
 (20008,   592, 130, 'Byakko',           900, 0,  394, 0, 0, 0, NULL),
 (20009,   268, 128, 'Aspidochelone',    900, 0,  183, 0, 0, 0, NULL),
 (20010,  3070,  29, 'Ouryu',            900, 0, 1962, 0, 0, 0, NULL),
 (20011,   584, 153, 'Bune',             900, 0,  389, 0, 0, 0, NULL),
 (20012, 30002,  30, 'Phoenix',          900, 0, 2362, 0, 0, 0, NULL),
 (20013,  3816, 130, 'Suzaku',           900, 0, 2362, 0, 0, 0, NULL),
 (20014,  2265, 178, 'Kirin',            900, 0, 2819, 0, 0, 0, NULL),
 (20015,  1280, 154, 'Fafnir',           900, 0,  805, 0, 0, 0, NULL),
 (20016,  2840, 154, 'Nidhogg',          900, 0, 1781, 0, 0, 0, NULL),
 (20017,  4261, 190, 'Vrtra',            900, 0, 2592, 0, 0, 0, NULL),
 (20018,  3916,   7, 'Tiamat',           900, 0, 2416, 0, 0, 0, NULL),
 (20019,  2262, 125, 'King_Vinegarroon', 900, 0, 1451, 0, 0, 0, NULL),
 (20020,  2220,  79, 'Khimaira',         900, 0, 1437, 0, 0, 0, NULL),
 (20021,   680,  61, 'Cerberus',         900, 0,  446, 0, 0, 0, NULL),
 (20022,    21,  33, 'Absolute_Virtue',  900, 0,    3, 0, 0, 0, NULL),
 (20023,  3208,  32, 'Proto-Omega',      900, 0, 4900, 0, 0, 0, NULL);

-- Proto-Omega has no normal mob dropid in this repo (Limbus rewards are not
-- wired as a standard corpse table), so give the Affinity HNM a small valid
-- nostalgic table: retail Omega parts plus direct Homam pieces.
DELETE FROM `mob_droplist` WHERE `dropId` = 4900;
INSERT INTO `mob_droplist` (`dropId`,`dropType`,`groupId`,`groupRate`,`itemId`,`itemRate`) VALUES
 (4900, 0, 0, 1000,  1925, 240), -- Omega's Eye
 (4900, 0, 0, 1000,  1926, 240), -- Omega's Heart
 (4900, 0, 0, 1000,  1927, 240), -- Omega's Foreleg
 (4900, 0, 0, 1000,  1928, 240), -- Omega's Hind Leg
 (4900, 0, 0, 1000,  1929, 240), -- Omega's Tail
 (4900, 0, 0, 1000, 15240,  50), -- Homam Zucchetto
 (4900, 0, 0, 1000, 14488,  50), -- Homam Corazza
 (4900, 0, 0, 1000, 14905,  50), -- Homam Manopolas
 (4900, 0, 0, 1000, 15576,  50), -- Homam Cosciales
 (4900, 0, 0, 1000, 15661,  50); -- Homam Gambieras

-- ---- historical trophy droplists (21000-21023; engine ignores ids > 5000) ----
-- Kept only as a roster/item reference. The 11 live Sage trophies and all
-- 24 collection rewards are granted by affinity_nm_autopop.lua.
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
 (17298309, 0, 'Behemoth',         'Behemoth',          20000,  99,  99, -277.763, -20.309, 72.189, 127),
 (17298310, 0, 'King_Behemoth',    'King Behemoth',     20001,  99,  99, -267.50, -19.80,   73.70, 0),
 (17204087, 0, 'King_Arthro',      'King Arthro',       20002,  99,  99,  -177.8894, 0.2285, 434.2736, 237),
 (17228680, 0, 'Simurgh',          'Simurgh',           20003,  99,  99, -681.00, -31.00, -447.00, 0),
 (17302409, 0, 'Adamantoise',      'Adamantoise',       20004,  99,  99,  3.00, -0.42, 8.00, 0),
 (17310621, 0, 'Genbu',            'Genbu',             20005,  99,  99,  261.87, -70.22, 526.41, 0),
 (17269643, 0, 'Roc',              'Roc',               20006,  99,  99,  232.00, -0.01, -327.00, 0),
 (17310622, 0, 'Seiryu',           'Seiryu',            20007,  99,  99,  580.84, -70.22, -84.53, 0),
 (17310623, 0, 'Byakko',           'Byakko',            20008,  99,  99,  -419.40, -70.20, 410.96, 0),
 (17302414, 0, 'Aspidochelone',    'Aspidochelone',     20009,  99,  99,  19.000,   0.089,  14.000, 117),
 (16896911, 0, 'Ouryu',            'Ouryu',             20010,  99,  99,  618.78,   0.56, -552.23, 0),
 (17404816, 0, 'Bune',             'Bune',              20011,  99,  99,  405.43,  11.40,  -98.61, 0),
 (16901009, 0, 'Phoenix',          'Phoenix',           20012,  99,  99,  685.00, -31.76, -481.00, 0),
 (17310624, 0, 'Suzaku',           'Suzaku',            20013,  99,  99,  -520.84, -70.22, -271.52, 0),
 (17507219, 0, 'Kirin',            'Kirin',             20014,  99,  99,  -68.00, 32.58, 3.50, 0),
 (17408916, 0, 'Fafnir',           'Fafnir',            20015,  99,  99,  46.00, 6.00, 18.00, 0),
 (17408917, 0, 'Nidhogg',          'Nidhogg',           20016,  99,  99,  46.00, 6.00, 24.00, 0),
 (17556374, 0, 'Vrtra',            'Vrtra',             20017,  99,  99,  228.000,   7.134, -311.000, 17),
 (16806807, 0, 'Tiamat',           'Tiamat',            20018,  99,  99, -529.519,  -5.811,  -43.413, 233),
 (17290136, 0, 'King_Vinegarroon', 'King Vinegarroon',  20019,  99,  99,  -239.00, -0.23, -650.00, 0),
 (17101721, 0, 'Khimaira',         'Khimaira',          20020,  99,  99,  603.887, -16.140, 414.765, 255),
 (17027994, 0, 'Cerberus',         'Cerberus',          20021,  99,  99,  316.000, -23.000, -84.000, 127),
 (16913307, 0, 'Absolute_Virtue',  'Absolute Virtue',   20022,  99,  99,  461.266,  -1.643, -580.192, 4),
 (16909196, 0, 'Proto-Omega',      'Proto-Omega',       20023,  99,  99, 600.000, 130.360, 780.000, 64);

-- ---- Suppress the RETAIL duplicates that share these spawn spots ----
-- The affinity NM sits at (or beside) the retail NM's point, so the retail mobid
-- ALSO popped -> two/three NMs up and the retail one gives no trophy (Duff test
-- 2026-07-06: #2 King Behemoth, #4 Simurgh, #5 Adamantoise, #7 Roc). Delete ONLY
-- these specific retail spawn rows (scoped by mobid -> safe, never by groupid) so
-- the affinity version is the sole spawn at each spot. Idempotent.
DELETE FROM `mob_spawn_points` WHERE `mobid` IN (
    17297440,  -- retail Behemoth       (Behemoth's Dominion) -- leaves only affinity King Behemoth
    17297441,  -- retail King Behemoth  (Behemoth's Dominion)
    17228242,  -- retail Simurgh        (Rolanberry Fields)
    17269106,  -- retail Roc            (Sauromugue Champaign)
    17301537,  -- retail Adamantoise    (Valley of Sorrows)
    17301538   -- retail Aspidochelone  (Valley of Sorrows)
);
