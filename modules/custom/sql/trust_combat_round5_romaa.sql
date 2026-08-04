-- Romaa Mihgo: restore Cobra Clamp (was stripped as orphan; Swift Blade was filler).
-- THF/WAR sword. Fast Blade / Vorpal / Savage / Cobra Clamp (conal Stun+Para).

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1064;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Romaa_Mihgo',1064,32),   -- Fast Blade
('TRUST_Romaa_Mihgo',1064,40),   -- Vorpal Blade
('TRUST_Romaa_Mihgo',1064,42),   -- Savage Blade
('TRUST_Romaa_Mihgo',1064,3297); -- Cobra Clamp

UPDATE `mob_skills` SET
    `mob_anim_id` = 260,
    `mob_skill_name` = 'cobra_clamp',
    `mob_skill_aoe` = 4,
    `mob_skill_aoe_radius` = 7.0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 12,
    `secondary_sc` = 10,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3297;

-- Affirm sword WS anims.
UPDATE `mob_skills` SET
    `mob_anim_id` = 1,
    `mob_skill_name` = 'fast_blade',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4
WHERE `mob_skill_id` = 32;

UPDATE `mob_skills` SET
    `mob_anim_id` = 9,
    `mob_skill_name` = 'vorpal_blade',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4
WHERE `mob_skill_id` = 40;

UPDATE `mob_skills` SET
    `mob_anim_id` = 11,
    `mob_skill_name` = 'savage_blade',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4
WHERE `mob_skill_id` = 42;

-- THF/WAR, Sword.
UPDATE `mob_pools` SET
    `mJob` = 6,
    `sJob` = 1,
    `cmbSkill` = 3,
    `cmbDelay` = 240
WHERE `poolid` = 5949;
