-- Iron Eater: WAR/WAR Great Axe; retail WS list already correct (Shield/Armor/Steel).
-- Affirm pool jobs + skill list anims for live deploy.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1032;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Iron_Eater',1032,80), -- Shield Break
('TRUST_Iron_Eater',1032,83), -- Armor Break
('TRUST_Iron_Eater',1032,88); -- Steel Cyclone

UPDATE `mob_skills` SET
    `mob_anim_id` = 91,
    `mob_skill_name` = 'shield_break',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4
WHERE `mob_skill_id` = 80;

UPDATE `mob_skills` SET
    `mob_anim_id` = 94,
    `mob_skill_name` = 'armor_break',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4
WHERE `mob_skill_id` = 83;

UPDATE `mob_skills` SET
    `mob_anim_id` = 99,
    `mob_skill_name` = 'steel_cyclone',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 10,
    `secondary_sc` = 6
WHERE `mob_skill_id` = 88;

-- WAR/WAR, Great Axe.
UPDATE `mob_pools` SET
    `mJob` = 1,
    `sJob` = 1,
    `cmbSkill` = 6
WHERE `poolid` = 5917;
