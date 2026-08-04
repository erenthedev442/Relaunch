-- Shantotto II: restore unique Trust MS + magical AA (was remapped to club WS).
-- Keep custom spell list modules/custom/sql/trusts/trust_shantottoii.sql (T2–V).
-- BLM/WHM. Lesson / Empirical / Final Exam / Doctor's Orders.
-- AA: auto_attack_shantotto_ii (3739). S-tier nuker (apex) + mbCap 79999.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1134;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Shantotto_II',1134,3743), -- Lesson in Pain (Dark + MEVA Down)
('TRUST_Shantotto_II',1134,3742), -- Empirical Research (MDEF Down)
('TRUST_Shantotto_II',1134,3740), -- Final Exam (Light)
('TRUST_Shantotto_II',1134,3741); -- Doctor's Orders (Dark)

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1163;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Shantotto_II_Melee',1163,3739); -- Magical AA (element = lowest resist)

-- Ensure unique rows / Trust anims (+2048 capture).
INSERT INTO `mob_skills` VALUES
(3739,2546,'auto_attack_shantotto_ii',0,0.0,15.0,2000,0,4,4,0,0,0,0,0),
(3740,2547,'final_exam',0,0.0,7.0,2000,1500,4,0,0,0,13,11,0),
(3741,2548,'doctors_orders',0,0.0,7.0,2000,1500,4,0,0,0,14,9,0),
(3742,2549,'empirical_research',0,0.0,7.0,2000,1500,4,0,0,0,12,1,0),
(3743,2550,'lesson_in_pain',0,0.0,7.0,2000,1500,4,0,0,0,10,4,0)
ON DUPLICATE KEY UPDATE
    `mob_anim_id` = VALUES(`mob_anim_id`),
    `mob_skill_name` = VALUES(`mob_skill_name`),
    `mob_skill_aoe` = VALUES(`mob_skill_aoe`),
    `mob_skill_aoe_radius` = VALUES(`mob_skill_aoe_radius`),
    `mob_skill_distance` = VALUES(`mob_skill_distance`),
    `mob_anim_time` = VALUES(`mob_anim_time`),
    `mob_prepare_time` = VALUES(`mob_prepare_time`),
    `mob_valid_targets` = VALUES(`mob_valid_targets`),
    `mob_skill_flag` = VALUES(`mob_skill_flag`),
    `primary_sc` = VALUES(`primary_sc`),
    `secondary_sc` = VALUES(`secondary_sc`),
    `tertiary_sc` = VALUES(`tertiary_sc`);

-- BLM/WHM. Magical AA via setMobSkillAttack(1163).
UPDATE `mob_pools` SET
    `mJob` = 4,
    `sJob` = 3,
    `cmbSkill` = 11,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `skill_list_id` = 1134,
    `spellList` = 428
WHERE `poolid` = 6019;
