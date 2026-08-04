-- Shikaree Z: affirm retail DRG/WHM polearm kit (player WS anims already correct).
-- Was catalogued as ranged_dd; power path is melee_dd B skirmisher.
-- WS: Raiden Thrust / Skewer / Wheeling Thrust / Impulse Drive.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1030;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Shikaree_Z',1030,114), -- Raiden Thrust
('TRUST_Shikaree_Z',1030,118), -- Skewer
('TRUST_Shikaree_Z',1030,119), -- Wheeling Thrust
('TRUST_Shikaree_Z',1030,120); -- Impulse Drive

-- Affirm player polearm WS anims / SC props.
UPDATE `mob_skills` SET
    `mob_anim_id` = 123,
    `mob_skill_name` = 'raiden_thrust',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 1,
    `secondary_sc` = 8,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 114;

UPDATE `mob_skills` SET
    `mob_anim_id` = 127,
    `mob_skill_name` = 'skewer',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 1,
    `secondary_sc` = 8,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 118;

UPDATE `mob_skills` SET
    `mob_anim_id` = 128,
    `mob_skill_name` = 'wheeling_thrust',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 11,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 119;

UPDATE `mob_skills` SET
    `mob_anim_id` = 129,
    `mob_skill_name` = 'impulse_drive',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 9,
    `secondary_sc` = 7,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 120;

-- DRG/WHM, Polearm AA. HP-10% / MP+100% via pool mods.
UPDATE `mob_pools` SET
    `mJob` = 14,
    `sJob` = 3,
    `cmbSkill` = 8,
    `cmbDelay` = 240,
    `spellList` = 327,
    `skill_list_id` = 1030
WHERE `poolid` = 5915;

DELETE FROM `mob_pool_mods` WHERE `poolid` = 5915 AND `modid` IN (3, 6);
INSERT INTO `mob_pool_mods` VALUES (5915,3,-10,0); -- HPP: -10
INSERT INTO `mob_pool_mods` VALUES (5915,6,100,0); -- MPP: 100
