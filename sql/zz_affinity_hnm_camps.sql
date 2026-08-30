-- Affinity Simurgh + Roc camps (!affinitynm 4 / 7).
--
-- Retail rows were deleted so these replicas are the sole spawns.
-- Light deploy only applies sql/zz_*.sql -- re-assert the groups + camps
-- in case a stock reload dropped them. Map restart required.

DELETE FROM `mob_groups` WHERE `groupid` = 20003 AND `zoneid` = 110;
INSERT INTO `mob_groups` VALUES
 (20003, 3630, 110, 'Simurgh', 900, 0, 2255, 0, 0, 0, NULL);

DELETE FROM `mob_groups` WHERE `groupid` = 20006 AND `zoneid` = 120;
INSERT INTO `mob_groups` VALUES
 (20006, 3376, 120, 'Roc', 900, 0, 2112, 0, 0, 0, NULL);

DELETE FROM `mob_spawn_points` WHERE `mobid` IN (17228680, 17228242, 17269643, 17269106);
INSERT INTO `mob_spawn_points` VALUES
 (17228680, 0, 'Simurgh', 'Simurgh', 20003, 99, 99, -681.00, -31.00, -447.00, 0),
 (17269643, 0, 'Roc',     'Roc',     20006, 99, 99,  232.00,  -0.01, -327.00, 0);
