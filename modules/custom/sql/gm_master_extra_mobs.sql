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
-- Tier mapping (matches game_master_catalog.lua difficulties). Every tier now
-- draws from a DISTINCT pool so no two tiers repeat the same silhouettes -- the
-- 5 endgame tiers each get their own themed god/HNM roster:
--   11400-11403 + 11416-11418  Easy        — classic camp NMs
--   11404-11407 + 11419-11421  Normal      — mid-tier NMs
--   11408-11411 + 11422-11424  Hard        — apex beasts
--   11412-11415, 11425-11442   Endgame (5 disjoint pools):
--     Insane     = Four Gods       (Byakko/Suzaku/Genbu/Seiryu)
--     Nightmare  = Elder Wyrms     (Bahamut/Ouryu/Fafnir/Jormungand)
--     Apocalypse = Primeval Titans (Adamantoise/Aspidochelone/Behemoth/Sandworm)
--     Oblivion   = Void Sovereigns (Kirin/Absolute Virtue/Pandemonium Warden/Shinryu/Jailer of Love)
--     Ragnarok   = The Unmade      (Ultima/Omega/Odin/Dynamis Lord/Provenance Watcher)
--     Terror     = Abyssal Terrors (Glavoid/Chloris/Sarameya/Orthrus/Bukhis/Sobek)
--
-- Idempotent: groupid-range DELETE + re-insert.
-- ============================================================

-- Zone-scoped so re-applying NEVER wipes another zone's mobs that reuse these
-- groupids. mob_groups PK is (zoneid, groupid), so the Reforge NMs at 11400-11414
-- in zone 278 (reforge_nms.sql) coexist with the GM/Voidspire pool in zone 289.
-- (Before 2026-06-30 this DELETE was unscoped and clobbered them cross-zone,
-- leaving Voidspire/Wave NMs unable to spawn.) No mob_spawn_points cleanup: these
-- mobs are DYNAMIC (insertDynamicEntity), have no spawn points, and the old
-- unscoped spawn_points DELETE only harmed Reforge's static spawn points.
DELETE FROM `mob_groups` WHERE `groupid` BETWEEN 11400 AND 11450 AND `zoneid` = 289;

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

-- =====================================================================
-- Distinct endgame pools (2026-07-09): the top tiers used to SHARE the same
-- 4 gods (Kirin/AV/PW/Shinryu), which felt stale. Each endgame tier now gets
-- its own themed roster. Level/HP are overridden per-difficulty at spawn, so
-- these reuse the retail poolids purely for the model + name variety.
-- =====================================================================

-- ----- Insane tier: The Four Gods (complete the set; Byakko/Suzaku already above)
INSERT INTO `mob_groups` VALUES (11429, 1491, 289, 'Genbu',              0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11430, 3540, 289, 'Seiryu',             0, 128, 0, 0, 0, 0, NULL);

-- ----- Nightmare tier: Elder Wyrms (Bahamut/Ouryu already above)
INSERT INTO `mob_groups` VALUES (11431, 1280, 289, 'Fafnir',             0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11432, 2156, 289, 'Jormungand',         0, 128, 0, 0, 0, 0, NULL);

-- ----- Apocalypse tier: Primeval Titans (the original three HNMs + Sandworm)
INSERT INTO `mob_groups` VALUES (11433,   44, 289, 'Adamantoise',        0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11434,  268, 289, 'Aspidochelone',      0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11435,  387, 289, 'Behemoth',           0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11436, 3448, 289, 'Sandworm',           0, 128, 0, 0, 0, 0, NULL);

-- ----- Oblivion tier: Void Sovereigns (Kirin/AV/PW/Shinryu above + Jailer of Love)
INSERT INTO `mob_groups` VALUES (11441, 2134, 289, 'Jailer_of_Love',     0, 128, 0, 0, 0, 0, NULL);

-- ----- Ragnarok tier: The Unmade (ultimate weapons + death gods)
INSERT INTO `mob_groups` VALUES (11437, 4083, 289, 'Ultima',             0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11438, 2973, 289, 'Omega',              0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11439, 2941, 289, 'Odin',               0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11440, 1154, 289, 'Dynamis_Lord',       0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11442, 4654, 289, 'Provenance_Watcher', 0, 128, 0, 0, 0, 0, NULL);

-- ----- Terror tier: Abyssal Terrors (apex Abyssea NMs for the 8-god pile-on farm)
INSERT INTO `mob_groups` VALUES (11443, 4555, 289, 'Glavoid',            0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11444, 4554, 289, 'Chloris',            0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11445, 3465, 289, 'Sarameya',           0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11446, 3061, 289, 'Orthrus',            0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11447,  572, 289, 'Bukhis',             0, 128, 0, 0, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11448, 3695, 289, 'Sobek',              0, 128, 0, 0, 0, 0, NULL);
