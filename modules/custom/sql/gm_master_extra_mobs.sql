-- ============================================================
-- gm_master_extra_mobs.sql
-- New mob_groups for the Game Master wave system, deliberately
-- pulled from OUTSIDE the Hunting League pool so wave fights have
-- visual variety instead of repeating the same 4-15 silhouettes.
--
-- GroupIds 11400-11415 reserved for this system. All at zoneid=146
-- (Balgas_Dais) — the Wave Master NPC lives there, not in GM_Home.
--
-- Tier mapping (matches game_master_catalog.lua difficulties):
--   11400-11403  Easy   — classic camp NMs (Lv 125 target)
--   11404-11407  Normal — mid-tier NMs    (Lv 150 target)
--   11408-11411  Hard   — apex beasts     (Lv 175 target)
--   11412-11415  Insane — gods & wyrms    (Lv 200 target)
--
-- Idempotent: zoneid-scoped DELETE so re-running this SQL only
-- touches the GM Master rows. The Hunting League rows at
-- zoneid=210 (groupids 11355-11369) and zoneid=292 are NOT
-- affected. Same protection pattern as the patched
-- hunting_league_mobs.sql / hunting_league_gm_home_mobs.sql.
-- ============================================================

DELETE FROM `mob_spawn_points` WHERE `groupid` BETWEEN 11400 AND 11415;
DELETE FROM `mob_groups` WHERE `groupid` BETWEEN 11400 AND 11415;

-- ----- Easy tier (Lv 125 target) ---------------------------------
-- Classic camp NMs from across early-FFXI. Lizard, rabbit, antlion,
-- dhalmel — four different creature classes for visual variety.
INSERT INTO `mob_groups` VALUES (11400,  228, 146, 'Argus',         0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11401, 3785, 146, 'Stray_Mary',    0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11402, 1138, 146, 'Dune_Widow',    0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11403, 6996, 146, 'Capricornus',   0, 128, 0, 0, 0, 0, NULL);

-- ----- Normal tier (Lv 150 target) -------------------------------
-- Mid-tier classics. Bogy, statue, cluster, elemental — heavy
-- visual + mechanical diversity in one tier.
INSERT INTO `mob_groups` VALUES (11404,  484, 146, 'Boggelmann',    0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11405, 1877, 146, 'Hakutaku',      0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11406, 3763, 146, 'Steam_Cleaner', 0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11407, 1306, 146, 'Faust',         0, 128, 0, 0, 0, 0, NULL);

-- ----- Hard tier (Lv 175 target) ---------------------------------
-- Apex creatures from classic FFXI HNM camps. Cerberus / Hydra /
-- Khimaira / Tiamat — three legendary HNMs + a wyrm for variety.
INSERT INTO `mob_groups` VALUES (11408,  680, 146, 'Cerberus',      0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11409, 2018, 146, 'Hydra',         0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11410, 2220, 146, 'Khimaira',      0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11411, 3916, 146, 'Tiamat',        0, 128, 0, 0, 0, 0, NULL);

-- ----- Insane tier (Lv 200 target) -------------------------------
-- Gods + legendary wyrms. The Four Heavenly Kings (well, two of
-- them) + the Bahamut dragon god + Ouryu. Different visual model
-- per slot so a 3-mob pile-on still looks like 3 different gods,
-- not 3 of the same.
INSERT INTO `mob_groups` VALUES (11412,  325, 146, 'Bahamut',       0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11413, 3070, 146, 'Ouryu',         0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11414,  592, 146, 'Byakko',        0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11415, 3816, 146, 'Suzaku',        0, 128, 0, 0, 0, 0, NULL);
