-- Maat UC: MNK/WAR B-tier H2H. Exclusive Hollow Smite (Lua-driven SC AI).
-- Document kit on list 1121; pool skill_list_id stays 0.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1121;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Maat_UC',1121,3496); -- Hollow Smite (50+)

UPDATE `mob_skills` SET
    `mob_anim_id` = 2505,
    `mob_skill_name` = 'hollow_smite',
    `mob_skill_aoe` = 0,
    `mob_skill_aoe_radius` = 0.0,
    `mob_skill_distance` = 7.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 4,
    `primary_sc` = 13,
    `secondary_sc` = 12,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3496;

UPDATE `mob_pools` SET
    `mJob` = 2,
    `sJob` = 1,
    `cmbSkill` = 1,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `skill_list_id` = 0,
    `spellList` = 0
WHERE `poolid` = 6006;
