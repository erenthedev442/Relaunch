-- Volker: restore retail sword kit (had Red Lotus; missing Fast Blade + Berserk-Ruf).
-- WAR/WAR. Fast Blade / Savage / Spirits Within / Vorpal / Berserk-Ruf (ATK boost).

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1018;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Volker',1018,32),   -- Fast Blade
('TRUST_Volker',1018,39),   -- Spirits Within
('TRUST_Volker',1018,40),   -- Vorpal Blade
('TRUST_Volker',1018,42),   -- Savage Blade
('TRUST_Volker',1018,3205); -- Berserk-Ruf (Attack Boost)

-- Affirm player sword WS anims / SC.
UPDATE `mob_skills` SET
    `mob_anim_id` = 1,
    `mob_skill_name` = 'fast_blade',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 4,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 32;

UPDATE `mob_skills` SET
    `mob_anim_id` = 8,
    `mob_skill_name` = 'spirits_within',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 0,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 39;

UPDATE `mob_skills` SET
    `mob_anim_id` = 9,
    `mob_skill_name` = 'vorpal_blade',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 5,
    `secondary_sc` = 8,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 40;

UPDATE `mob_skills` SET
    `mob_anim_id` = 11,
    `mob_skill_name` = 'savage_blade',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 12,
    `secondary_sc` = 4,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 42;

UPDATE `mob_skills` SET
    `mob_anim_id` = 673,
    `mob_skill_name` = 'berserk_ruf',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 1,
    `mob_prepare_time` = 1500,
    `primary_sc` = 0,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3205;

-- WAR/WAR, Sword.
UPDATE `mob_pools` SET
    `mJob` = 1,
    `sJob` = 1,
    `cmbSkill` = 3,
    `cmbDelay` = 240,
    `skill_list_id` = 1018
WHERE `poolid` = 5903;
