-- ============================================================
-- gm_master_extra_mobs.sql
-- New mob_groups for the Game Master wave system, deliberately
-- pulled from OUTSIDE the Hunting League pool so wave fights have
-- visual variety instead of repeating the same 4-15 silhouettes.
--
-- GroupIds 11400-11431 for this system. All at zoneid=289
-- (Escha_RuAun) — the Wave Master NPC lives there. The mob_groups zoneid
-- MUST match the arena zone or the wave spawns fail.
-- Arena history: Balgas_Dais (146) -> Hall_of_the_Gods (251) -> Escha_RuAun
-- (289). Balga's Dais was too small; the Hall was long and narrow, so waves
-- spawned into the walls. Escha - Ru'Aun is large and open.
--
-- Tier mapping (matches game_master_catalog.lua difficulties):
--   11400-11403  Easy        — classic camp NMs (Lv 125 target)
--   11404-11407  Normal      — mid-tier NMs    (Lv 150 target)
--   11408-11411  Hard        — apex beasts     (Lv 175 target)
--   11412-11415  Insane      — gods & wyrms    (Lv 200 target)
--   11416-11418  Easy+       — additional Easy pool entries
--   11419-11421  Normal+     — additional Normal pool entries
--   11422-11424  Hard+       — additional Hard pool entries
--   11425-11428  Insane+/Nightmare — additional top-tier entries
--
-- Idempotent: groupid-range DELETE + re-insert.
-- ============================================================

DELETE FROM `mob_spawn_points` WHERE `groupid` BETWEEN 11400 AND 11431;
DELETE FROM `mob_groups`       WHERE `groupid` BETWEEN 11400 AND 11431;

-- ----- Easy tier (Lv 125 target) ---------------------------------
INSERT INTO `mob_groups` VALUES (11400,  228, 289, 'Argus',         0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11401, 3785, 289, 'Stray_Mary',    0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11402, 1138, 289, 'Dune_Widow',    0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11403, 6996, 289, 'Capricornus',   0, 128, 0, 0, 0, 0, NULL);

-- ----- Normal tier (Lv 150 target) -------------------------------
INSERT INTO `mob_groups` VALUES (11404,  484, 289, 'Boggelmann',    0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11405, 1877, 289, 'Hakutaku',      0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11406, 3763, 289, 'Steam_Cleaner', 0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11407, 1306, 289, 'Faust',         0, 128, 0, 0, 0, 0, NULL);

-- ----- Hard tier (Lv 175 target) ---------------------------------
INSERT INTO `mob_groups` VALUES (11408,  680, 289, 'Cerberus',      0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11409, 2018, 289, 'Hydra',         0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11410, 2220, 289, 'Khimaira',      0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11411, 3916, 289, 'Tiamat',        0, 128, 0, 0, 0, 0, NULL);

-- ----- Insane tier (Lv 200 target) -------------------------------
INSERT INTO `mob_groups` VALUES (11412,  325, 289, 'Bahamut',       0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11413, 3070, 289, 'Ouryu',         0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11414,  592, 289, 'Byakko',        0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11415, 3816, 289, 'Suzaku',        0, 128, 0, 0, 0, 0, NULL);

-- ----- Easy additions -----------------------------------------
INSERT INTO `mob_groups` VALUES (11416, 2384, 289, 'Leaping_Lizzy',     0, 128, 0, 0,      0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11417, 3947, 289, 'Tom_Tit_Tat',       0, 128, 0, 0,      0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11418,  206, 289, 'Aquarius',           0, 128, 0, 0,      0, 0, NULL);

-- ----- Normal additions ---------------------------------------
INSERT INTO `mob_groups` VALUES (11419, 3549, 289, 'Serket',             0, 128, 0, 0,      0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11420, 3630, 289, 'Simurgh',            0, 128, 0, 0,      0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11421, 3376, 289, 'Roc',                0, 128, 0, 0,      0, 0, NULL);

-- ----- Hard additions -----------------------------------------
INSERT INTO `mob_groups` VALUES (11422, 2840, 289, 'Nidhogg',            0, 128, 0, 0,      0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11423, 2255, 289, 'King_Behemoth',      0, 128, 0, 0,      0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11424, 4261, 289, 'Vrtra',              0, 128, 0, 0,      0, 0, NULL);

-- ----- Insane additions + Nightmare tier ----------------------
INSERT INTO `mob_groups` VALUES (11425, 2265, 289, 'Kirin',              0, 128, 0, 0,      0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11426,   21, 289, 'Absolute_Virtue',    0, 128, 0, 0,      0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11427, 3604, 289, 'Shinryu',            0, 128, 0, 0,      0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11428, 7175, 289, 'Pandemonium_Warden', 0, 128, 0, 147000, 0, 0, NULL);
