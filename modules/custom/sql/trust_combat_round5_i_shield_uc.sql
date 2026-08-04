-- Invincible Shield UC: WAR/COR A-tier provoke DD.
-- WS: Raging Rush / Steel Cyclone / Soturi's Fury. No shield break kit.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1069;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Invincible_Shield_UC',1069,86),  -- Raging Rush (5)
('TRUST_Invincible_Shield_UC',1069,88),  -- Steel Cyclone (25)
('TRUST_Invincible_Shield_UC',1069,3499); -- Soturi's Fury (50+)

UPDATE `mob_skills` SET
    `mob_anim_id` = 103,
    `mob_skill_name` = 'soturis_fury',
    `mob_skill_aoe` = 0,
    `mob_skill_aoe_radius` = 0.0,
    `mob_skill_distance` = 7.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 4,
    `primary_sc` = 13,
    `secondary_sc` = 12,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3499;

-- Affirm great-axe WS anims.
UPDATE `mob_skills` SET
    `mob_anim_id` = 97,
    `mob_skill_name` = 'raging_rush',
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 4
WHERE `mob_skill_id` = 86;

UPDATE `mob_skills` SET
    `mob_anim_id` = 99,
    `mob_skill_name` = 'steel_cyclone',
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 4
WHERE `mob_skill_id` = 88;

UPDATE `mob_pools` SET
    `mJob` = 1,
    `sJob` = 17,
    `cmbSkill` = 6,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `skill_list_id` = 1069,
    `spellList` = 0
WHERE `poolid` = 5954;
