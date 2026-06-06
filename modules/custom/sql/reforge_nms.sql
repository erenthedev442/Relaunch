-- ============================================================================
-- reforge_nms.sql
-- Custom mob_groups entries for the Reforge Armor system.
-- Three groups of NMs map to three different mark currencies:
--
--   Sky Gods    (groupids 11400-11404) -> Artifact Marks (RF_AF_Marks)
--   Unity NMs   (groupids 11405-11409) -> Relic Marks    (RF_Relic_Marks)
--   Abyssea NMs (groupids 11410-11414) -> Empyrean Marks (RF_Empy_Marks)
--
-- Zone 278 = Gwora-Corridor (matches reforge_catalog.lua huntZoneId).
--
-- These NMs are spawned dynamically by Reforge_System.lua via
-- insertDynamicEntity (no mob_spawn_points required).
--
-- Safe to re-apply (DELETE then INSERT).
-- ============================================================================

DELETE FROM `mob_groups` WHERE `groupid` BETWEEN 11400 AND 11414;

-- --- Sky Gods (AF Marks) ----------------------------------------------------
-- Pool IDs: Kirin=2265, Byakko=592, Seiryu=3540, Suzaku=3816, Genbu=1491
INSERT INTO `mob_groups` VALUES (11400, 2265, 278, 'Kirin',     0, 128, 2819, 60000, 60000, 0, NULL);
INSERT INTO `mob_groups` VALUES (11401,  592, 278, 'Byakko',    0, 128, 1231, 50000,     0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11402, 3540, 278, 'Seiryu',    0, 128, 1041, 50000, 50000, 0, NULL);
INSERT INTO `mob_groups` VALUES (11403, 3816, 278, 'Suzaku',    0, 128, 1079, 50000, 50000, 0, NULL);
INSERT INTO `mob_groups` VALUES (11404, 1491, 278, 'Genbu',     0, 128,  121, 50000, 50000, 0, NULL);

-- --- Unity NMs (Relic Marks) -----------------------------------------------
-- Pool IDs: Padfoot=3083, Khun=5669, Glavoid=4555, Bukhis=572, Tinnin=3922
INSERT INTO `mob_groups` VALUES (11405, 3083, 278, 'Padfoot',   0, 128, 2407, 60000,     0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11406, 5669, 278, 'Khun',      0, 128,    0, 70000, 50000, 0, NULL);
INSERT INTO `mob_groups` VALUES (11407, 4555, 278, 'Glavoid',   0, 128,    0, 80000,     0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11408,  572, 278, 'Bukhis',    0, 128,    0, 70000, 50000, 0, NULL);
INSERT INTO `mob_groups` VALUES (11409, 3922, 278, 'Tinnin',    0, 128,    0, 90000,     0, 0, NULL);

-- --- Abyssea NMs (Empyrean Marks) ------------------------------------------
-- Pool IDs: Briareus=530, Iratham=4566, Itzpapalotl=2109, Aello=4720, Hadhayosh=1872
INSERT INTO `mob_groups` VALUES (11410,  530, 278, 'Briareus',    0, 128, 811, 55000,     0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11411, 4566, 278, 'Iratham',     0, 128,   0, 55000,     0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11412, 2109, 278, 'Itzpapalotl', 0, 128,   7, 55000, 50000, 0, NULL);
INSERT INTO `mob_groups` VALUES (11413, 4720, 278, 'Aello',       0, 128,   7, 55000,     0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11414, 1872, 278, 'Hadhayosh',   0, 128,   0, 80000,     0, 0, NULL);
