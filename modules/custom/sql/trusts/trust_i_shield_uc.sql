-- =====================================================================
-- trust_i_shield_uc.sql
-- Fix Invincible Shield UC (spell 954 / pool 5954):
--   * Was WAR/MNK with Apururu UC spell list 367 and EMPTY skill list 1069
--   * Retail is WAR/COR provoke DD-tank (no Cure/Flash); kit was wrong
--
-- APPLY: mysql ... < modules/custom/sql/trusts/trust_i_shield_uc.sql
-- then restart map (pools / skill lists load at boot).
-- =====================================================================

-- Skill list 1069 — Soturi's Fury not in mob_skills yet; use GA kit.
DELETE FROM `mob_skill_lists` WHERE skill_list_id = 1069;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Invincible_Shield_UC', 1069, 80);  -- Shield Break
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Invincible_Shield_UC', 1069, 83);  -- Armor Break
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Invincible_Shield_UC', 1069, 86);  -- Raging Rush
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Invincible_Shield_UC', 1069, 88);  -- Steel Cyclone

-- Detach Apururu WHM spell list; UC has no magics.
UPDATE `mob_pools`
SET
    `mJob` = 1,          -- WAR
    `sJob` = 17,         -- COR
    `spellList` = 0,
    `skill_list_id` = 1069
WHERE `poolid` = 5954;
