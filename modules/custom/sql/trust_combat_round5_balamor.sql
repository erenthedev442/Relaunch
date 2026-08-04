-- Balamor: restore unique Defiant Trust MS + dark magical AA list.
-- Base/round3 had player GS WS (Hard Slash…Scourge), which broke Trust anims.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1098;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Balamor',1098,3617), -- Feast of Arrows
('TRUST_Balamor',1098,3618), -- Regurgitated Swarm
('TRUST_Balamor',1098,3619), -- Setting the Stage
('TRUST_Balamor',1098,3620); -- Last Laugh (HP Drain)

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 2098;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Balamor_Melee',2098,3614), -- balamor_auto_attack
('TRUST_Balamor_Melee',2098,3615), -- balamor_auto_attack_b
('TRUST_Balamor_Melee',2098,3616); -- balamor_auto_attack_c

-- AA skill rows (Trust anim capture 296-298 + 2048).
INSERT INTO `mob_skills` VALUES (3614,2344,'balamor_auto_attack',0,0.0,7.0,2000,0,4,4,0,0,0,0,0)
    ON DUPLICATE KEY UPDATE
        `mob_anim_id` = 2344,
        `mob_skill_name` = 'balamor_auto_attack',
        `mob_skill_aoe` = 0,
        `mob_skill_distance` = 7.0,
        `mob_anim_time` = 2000,
        `mob_prepare_time` = 0,
        `mob_valid_targets` = 4,
        `mob_skill_flag` = 4;

INSERT INTO `mob_skills` VALUES (3615,2345,'balamor_auto_attack_b',0,0.0,7.0,2000,0,4,4,0,0,0,0,0)
    ON DUPLICATE KEY UPDATE
        `mob_anim_id` = 2345,
        `mob_skill_name` = 'balamor_auto_attack_b',
        `mob_skill_aoe` = 0,
        `mob_skill_distance` = 7.0,
        `mob_anim_time` = 2000,
        `mob_prepare_time` = 0,
        `mob_valid_targets` = 4,
        `mob_skill_flag` = 4;

INSERT INTO `mob_skills` VALUES (3616,2346,'balamor_auto_attack_c',0,0.0,7.0,2000,0,4,4,0,0,0,0,0)
    ON DUPLICATE KEY UPDATE
        `mob_anim_id` = 2346,
        `mob_skill_name` = 'balamor_auto_attack_c',
        `mob_skill_aoe` = 0,
        `mob_skill_distance` = 7.0,
        `mob_anim_time` = 2000,
        `mob_prepare_time` = 0,
        `mob_valid_targets` = 4,
        `mob_skill_flag` = 4;

-- Ensure Trust WS rows keep captured Trust anims / single-target flags.
INSERT INTO `mob_skills` VALUES (3617,2347,'feast_of_arrows',0,0.0,7.0,2000,1500,4,0,0,0,0,0,0)
    ON DUPLICATE KEY UPDATE
        `mob_anim_id` = 2347,
        `mob_skill_name` = 'feast_of_arrows',
        `mob_skill_aoe` = 0;

INSERT INTO `mob_skills` VALUES (3618,2349,'regurgitated_swarm',0,0.0,7.0,2000,1500,4,0,0,0,0,0,0)
    ON DUPLICATE KEY UPDATE
        `mob_anim_id` = 2349,
        `mob_skill_name` = 'regurgitated_swarm',
        `mob_skill_aoe` = 0;

INSERT INTO `mob_skills` VALUES (3619,2350,'setting_the_stage',0,0.0,7.0,2000,1500,4,0,0,0,0,0,0)
    ON DUPLICATE KEY UPDATE
        `mob_anim_id` = 2350,
        `mob_skill_name` = 'setting_the_stage',
        `mob_skill_aoe` = 0;

INSERT INTO `mob_skills` VALUES (3620,2351,'last_laugh',0,0.0,7.0,2000,1500,4,0,0,0,0,0,0)
    ON DUPLICATE KEY UPDATE
        `mob_anim_id` = 2351,
        `mob_skill_name` = 'last_laugh',
        `mob_skill_aoe` = 0;

-- DRK/BLM, Great Sword (Damage Limit+ / Inundation trait path).
UPDATE `mob_pools` SET `sJob` = 4, `cmbSkill` = 4 WHERE `poolid` = 5983;
