-- Rongelouts: restore Tongue Lash + sword kit (was great-sword player WS).
-- WAR/WAR. Tongue Lash (AoE Terror) / Red Lotus / Savage / Seraph Blade.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1088;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Rongelouts',1088,3486), -- Tongue Lash (AoE Terror)
('TRUST_Rongelouts',1088,34),   -- Red Lotus Blade
('TRUST_Rongelouts',1088,42),   -- Savage Blade
('TRUST_Rongelouts',1088,37);   -- Seraph Blade

UPDATE `mob_skills` SET
    `mob_anim_id` = 260,
    `mob_skill_name` = 'tongue_lash',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 7.0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 0,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3486;

UPDATE `mob_skills` SET
    `mob_anim_id` = 3,
    `mob_skill_name` = 'red_lotus_blade',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 3,
    `secondary_sc` = 6,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 34;

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
    `mob_anim_id` = 5,
    `mob_skill_name` = 'seraph_blade',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 4,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 37;

-- WAR/WAR, Sword (was great-sword cmbSkill=4 / no sub).
UPDATE `mob_pools` SET
    `mJob` = 1,
    `sJob` = 1,
    `cmbSkill` = 3,
    `cmbDelay` = 240
WHERE `poolid` = 5973;
