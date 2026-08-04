-- Darrcuiln: restore unique Trust MS + special AA list.
-- audit/base remapped him to player GA WS (Raging Rush…Ukko's), which broke
-- Trust anims and his special auto-attack kit.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1106;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Darrcuiln',1106,3685), -- Howling Gust
('TRUST_Darrcuiln',1106,3687), -- Starward Yowl
('TRUST_Darrcuiln',1106,3686), -- Righteous Rasp
('TRUST_Darrcuiln',1106,3684), -- Aurous Charge
('TRUST_Darrcuiln',1106,3688); -- Stalking Prey (AoE)

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 2099;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Darrcuiln_Melee',2099,3165), -- darrcuiln_charge
('TRUST_Darrcuiln_Melee',2099,3166), -- darrcuiln_claw
('TRUST_Darrcuiln_Melee',2099,3167); -- darrcuiln_howl

-- Special AA rows.
INSERT INTO `mob_skills` VALUES (3165,2320,'darrcuiln_charge',0,0.0,7.0,2000,0,4,4,0,0,0,0,0)
    ON DUPLICATE KEY UPDATE
        `mob_anim_id` = 2320,
        `mob_skill_name` = 'darrcuiln_charge',
        `mob_skill_distance` = 7.0,
        `mob_anim_time` = 2000,
        `mob_prepare_time` = 0,
        `mob_valid_targets` = 4,
        `mob_skill_flag` = 4;

INSERT INTO `mob_skills` VALUES (3166,2321,'darrcuiln_claw',0,0.0,7.0,2000,0,4,4,0,0,0,0,0)
    ON DUPLICATE KEY UPDATE
        `mob_anim_id` = 2321,
        `mob_skill_name` = 'darrcuiln_claw',
        `mob_skill_distance` = 7.0,
        `mob_anim_time` = 2000,
        `mob_prepare_time` = 0,
        `mob_valid_targets` = 4,
        `mob_skill_flag` = 4;

INSERT INTO `mob_skills` VALUES (3167,2322,'darrcuiln_howl',0,0.0,18.0,2000,0,4,4,0,0,0,0,0)
    ON DUPLICATE KEY UPDATE
        `mob_anim_id` = 2322,
        `mob_skill_name` = 'darrcuiln_howl',
        `mob_skill_distance` = 18.0,
        `mob_anim_time` = 2000,
        `mob_prepare_time` = 0,
        `mob_valid_targets` = 4,
        `mob_skill_flag` = 4;

-- Trust WS rows / Stalking Prey AoE.
UPDATE `mob_skills` SET
    `mob_anim_id` = 2323,
    `mob_skill_name` = 'aurous_charge',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0
WHERE `mob_skill_id` = 3684;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2324,
    `mob_skill_name` = 'howling_gust',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0
WHERE `mob_skill_id` = 3685;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2325,
    `mob_skill_name` = 'righteous_rasp',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0
WHERE `mob_skill_id` = 3686;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2326,
    `mob_skill_name` = 'starward_yowl',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0
WHERE `mob_skill_id` = 3687;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2327,
    `mob_skill_name` = 'stalking_prey',
    `mob_skill_aoe` = 1,
    `mob_skill_distance` = 12.0
WHERE `mob_skill_id` = 3688;

-- WAR/RDM, H2H (claws/teeth); special AA via setMobSkillAttack.
UPDATE `mob_pools` SET
    `sJob` = 5,
    `cmbSkill` = 1
WHERE `poolid` = 5991;
