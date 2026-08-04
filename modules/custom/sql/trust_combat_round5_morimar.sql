-- Morimar: restore unique GA kit + special AA (was remapped to player axe WS).
-- Camaraderie / Into the Light / Arduous Decision on TP list.
-- Vehement Resolution + 12 Blades are script-driven.
-- WAR/BST Great Axe. Capture anims 284-291 +2048.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1105;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Morimar',1105,3677), -- Camaraderie of the Crevasse (Detonation/Impaction)
('TRUST_Morimar',1105,3678), -- Into the Light (Fusion/Impaction)
('TRUST_Morimar',1105,3679); -- Arduous Decision (Fragmentation/Compression)

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 2100;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Morimar_Melee',2100,3673), -- morimar_auto_attack
('TRUST_Morimar_Melee',2100,3674), -- morimar_auto_attack_b
('TRUST_Morimar_Melee',2100,3675); -- morimar_auto_attack_c

-- Special AA rows (NO_TP_COST flag 4, prepare 0).
INSERT INTO `mob_skills` VALUES (3673,2332,'morimar_auto_attack',0,0.0,7.0,2000,0,4,4,0,0,0,0,0)
    ON DUPLICATE KEY UPDATE
        `mob_anim_id` = 2332,
        `mob_skill_name` = 'morimar_auto_attack',
        `mob_skill_aoe` = 0,
        `mob_skill_distance` = 7.0,
        `mob_anim_time` = 2000,
        `mob_prepare_time` = 0,
        `mob_valid_targets` = 4,
        `mob_skill_flag` = 4;

INSERT INTO `mob_skills` VALUES (3674,2333,'morimar_auto_attack_b',0,0.0,7.0,2000,0,4,4,0,0,0,0,0)
    ON DUPLICATE KEY UPDATE
        `mob_anim_id` = 2333,
        `mob_skill_name` = 'morimar_auto_attack_b',
        `mob_skill_aoe` = 0,
        `mob_skill_distance` = 7.0,
        `mob_anim_time` = 2000,
        `mob_prepare_time` = 0,
        `mob_valid_targets` = 4,
        `mob_skill_flag` = 4;

INSERT INTO `mob_skills` VALUES (3675,2334,'morimar_auto_attack_c',0,0.0,7.0,2000,0,4,4,0,0,0,0,0)
    ON DUPLICATE KEY UPDATE
        `mob_anim_id` = 2334,
        `mob_skill_name` = 'morimar_auto_attack_c',
        `mob_skill_aoe` = 0,
        `mob_skill_distance` = 7.0,
        `mob_anim_time` = 2000,
        `mob_prepare_time` = 0,
        `mob_valid_targets` = 4,
        `mob_skill_flag` = 4;

-- Affirm Trust WS / ability rows (anims +2048, SC props).
UPDATE `mob_skills` SET
    `mob_anim_id` = 2335,
    `mob_skill_name` = 'vehement_resolution',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 1,
    `knockback` = 0,
    `primary_sc` = 0,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3676;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2336,
    `mob_skill_name` = 'camaraderie_of_the_crevasse',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `knockback` = 0,
    `primary_sc` = 6,
    `secondary_sc` = 8,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3677;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2337,
    `mob_skill_name` = 'into_the_light',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `knockback` = 0,
    `primary_sc` = 11,
    `secondary_sc` = 8,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3678;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2338,
    `mob_skill_name` = 'arduous_decision',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `knockback` = 0,
    `primary_sc` = 12,
    `secondary_sc` = 2,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3679;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2339,
    `mob_skill_name` = '12_blades_of_remorse',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 0.0,
    `mob_skill_distance` = 10.0,
    `mob_valid_targets` = 4,
    `knockback` = 0,
    `primary_sc` = 13,
    `secondary_sc` = 10,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3680;

-- WAR/BST, Great Axe.
UPDATE `mob_pools` SET
    `mJob` = 1,
    `sJob` = 9,
    `cmbSkill` = 6,
    `cmbDelay` = 240
WHERE `poolid` = 5990;
