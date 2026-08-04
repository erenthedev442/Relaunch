-- Jakoh Wahcondalo UC: THF/WAR A-tier knife skirmisher.
-- WS driven from Lua (no auto TP list) — random dump, no SC close.
-- Document kit on list 1071; pool skill_list_id stays 0.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1071;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Jakoh_Wahcondalo_UC',1071,23),   -- Dancing Edge (5)
('TRUST_Jakoh_Wahcondalo_UC',1071,25),   -- Evisceration (25)
('TRUST_Jakoh_Wahcondalo_UC',1071,3497); -- Sarva's Storm (50)

UPDATE `mob_skills` SET
    `mob_anim_id` = 236,
    `mob_skill_name` = 'sarvas_storm',
    `mob_skill_aoe` = 0,
    `mob_skill_aoe_radius` = 0.0,
    `mob_skill_distance` = 7.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 4,
    `primary_sc` = 14,
    `secondary_sc` = 10,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3497;

-- Affirm dagger WS anims (player WS ids reused as mobskills).
UPDATE `mob_skills` SET
    `mob_anim_id` = 38,
    `mob_skill_name` = 'dancing_edge',
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 4
WHERE `mob_skill_id` = 23;

UPDATE `mob_skills` SET
    `mob_anim_id` = 40,
    `mob_skill_name` = 'evisceration',
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 4
WHERE `mob_skill_id` = 25;

UPDATE `mob_pools` SET
    `mJob` = 6,
    `sJob` = 1,
    `cmbSkill` = 2,
    `cmbDelay` = 201,
    `cmbDmgMult` = 100,
    `skill_list_id` = 0,
    `spellList` = 0
WHERE `poolid` = 5956;
