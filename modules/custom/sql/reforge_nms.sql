-- ============================================================================
-- reforge_nms.sql
-- Custom mob_groups entries for the Reforge Armor system.
-- Three groups of NMs map to three different mark currencies:
--
--   Sky Gods    (groupids 11400-11404) -> Artifact Marks (RF_AF_Marks)
--   Unity NMs   (groupids 11405-11409) -> Relic Marks    (RF_Relic_Marks)
--   Abyssea NMs (groupids 11410-11414) -> Empyrean Marks (RF_Empy_Marks)
--
-- Zone 43 = Diorama Abdhaljs-Ghelsba (matches reforge_catalog.lua huntZoneId).
-- MOVED 2026-07-07: the hub relocated from Gwora-Corridor (zone 278) to the
-- blank Diorama (zone 43). insertDynamicEntity passes groupZoneId =
-- catalog.huntZoneId, and mob_groups PK is (zoneid, groupid), so these pool
-- rows MUST live under the hub's zone or the NMs spawn with no stats (lv255).
--
-- These NMs are spawned dynamically by Reforge_System.lua via
-- insertDynamicEntity (no mob_spawn_points required).
--
-- Safe to re-apply (DELETE then INSERT).
-- ============================================================================

-- Reforge-only TP lists exclude upstream list rows whose mob_skills records are
-- commented out (Bukhis: 2389/2533/2640; Hadhayosh: 2391/2586). Leaving those
-- IDs selectable can produce dead TP turns. The remaining moves all have live
-- mob_skills rows and action scripts.
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` IN (3000, 3001);
INSERT INTO `mob_skill_lists` VALUES ('Reforge_Bukhis',    3000, 1360); -- Apocalyptic Ray
INSERT INTO `mob_skill_lists` VALUES ('Reforge_Hadhayosh', 3001,  628); -- Wild Horn
INSERT INTO `mob_skill_lists` VALUES ('Reforge_Hadhayosh', 3001,  629); -- Thunderbolt
INSERT INTO `mob_skill_lists` VALUES ('Reforge_Hadhayosh', 3001,  632); -- Flame Armor
INSERT INTO `mob_skill_lists` VALUES ('Reforge_Hadhayosh', 3001,  633); -- Howl

-- Complete targeting metadata for newly implemented Harpeia/Glavoid handlers.
-- mob_skill_aoe=4 is conal; knockback is the displacement strength consumed by
-- the core after the Lua handler resolves.
UPDATE `mob_skills` SET `knockback` = 3
WHERE `mob_skill_id` = 2725; -- Rending Talons
UPDATE `mob_skills` SET `knockback` = 5
WHERE `mob_skill_id` = 2726; -- Shrieking Gale
UPDATE `mob_skills` SET `mob_skill_aoe` = 4, `knockback` = 7
WHERE `mob_skill_id` = 2191; -- Desiccation

-- Clean up the OLD zone-278 rows left behind by the move (orphaned now that no
-- Reforge NPCs live in Gwora). Zone-scoped so it can't touch the zone-289
-- Game Master / Voidspire pool that shares these groupids.
DELETE FROM `mob_groups` WHERE `groupid` BETWEEN 11400 AND 11414 AND `zoneid` = 278;

-- Zone-scoped (mob_groups PK is (zoneid, groupid)): these groupids are ALSO
-- used by the Game Master / Voidspire pool in zone 289, so keep the zoneid
-- filter or a re-apply would wipe those mobs.
DELETE FROM `mob_groups` WHERE `groupid` BETWEEN 11400 AND 11414 AND `zoneid` = 43;

-- --- Sky Gods (AF Marks) ----------------------------------------------------
-- Pool IDs: Kirin=2265, Byakko=592, Seiryu=3540, Suzaku=3816, Genbu=1491
INSERT INTO `mob_groups` VALUES (11400, 2265, 43, 'Kirin',     0, 128, 2819, 60000, 60000, 0, NULL);
INSERT INTO `mob_groups` VALUES (11401,  592, 43, 'Byakko',    0, 128, 1231, 50000,     0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11402, 3540, 43, 'Seiryu',    0, 128, 1041, 50000, 50000, 0, NULL);
INSERT INTO `mob_groups` VALUES (11403, 3816, 43, 'Suzaku',    0, 128, 1079, 50000, 50000, 0, NULL);
INSERT INTO `mob_groups` VALUES (11404, 1491, 43, 'Genbu',     0, 128,  121, 50000, 50000, 0, NULL);

-- --- Unity NMs (Relic Marks) -----------------------------------------------
-- Pool IDs: Padfoot=3083, Khun=5669, Glavoid=4555, Bukhis=572, Tinnin=3922
INSERT INTO `mob_groups` VALUES (11405, 3083, 43, 'Padfoot',   0, 128, 2407, 60000,     0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11406, 5669, 43, 'Khun',      0, 128,    0, 70000, 50000, 0, NULL);
INSERT INTO `mob_groups` VALUES (11407, 4555, 43, 'Glavoid',   0, 128,    0, 80000,     0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11408,  572, 43, 'Bukhis',    0, 128,    0, 70000, 50000, 0, NULL);
INSERT INTO `mob_groups` VALUES (11409, 3922, 43, 'Tinnin',    0, 128,    0, 90000,     0, 0, NULL);

-- --- Abyssea NMs (Empyrean Marks) ------------------------------------------
-- Pool IDs: Briareus=530, Iratham=4566, Itzpapalotl=2109, Aello=4720, Hadhayosh=1872
INSERT INTO `mob_groups` VALUES (11410,  530, 43, 'Briareus',    0, 128, 811, 55000,     0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11411, 4566, 43, 'Iratham',     0, 128,   0, 55000,     0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11412, 2109, 43, 'Itzpapalotl', 0, 128,   7, 55000, 50000, 0, NULL);
INSERT INTO `mob_groups` VALUES (11413, 4720, 43, 'Aello',       0, 128,   7, 55000,     0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11414, 1872, 43, 'Hadhayosh',   0, 128,   0, 80000,     0, 0, NULL);
