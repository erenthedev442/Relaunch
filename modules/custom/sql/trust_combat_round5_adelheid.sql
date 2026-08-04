-- Adelheid: restore SCH microtubes + Twirling Dervish (base had club Skullbreaker…Realmrazer).
-- SCH/BLM Club. Paralyzing / Silencing / Binding Microtube + Twirling Dervish (AoE @50).
-- Unique anims 2472–2475. Storm/helix AI + C nuker scholar path in Lua.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1083;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Adelheid',1083,3466), -- Paralyzing Microtube
('TRUST_Adelheid',1083,3467), -- Silencing Microtube
('TRUST_Adelheid',1083,3468), -- Binding Microtube
('TRUST_Adelheid',1083,3469); -- Twirling Dervish (AoE Light/Fusion; lv50)

UPDATE `mob_skills` SET
    `mob_anim_id` = 2472,
    `mob_skill_name` = 'paralyzing_microtube',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `mob_prepare_time` = 1500,
    `primary_sc` = 7,
    `secondary_sc` = 5,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3466;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2473,
    `mob_skill_name` = 'silencing_microtube',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `mob_prepare_time` = 1500,
    `primary_sc` = 3,
    `secondary_sc` = 6,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3467;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2474,
    `mob_skill_name` = 'binding_microtube',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `mob_prepare_time` = 1500,
    `primary_sc` = 9,
    `secondary_sc` = 7,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3468;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2475,
    `mob_skill_name` = 'twirling_dervish',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 8.0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `mob_prepare_time` = 1500,
    `primary_sc` = 13,
    `secondary_sc` = 11,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3469;

-- SCH/BLM, Club AA (~100 TP/hit with Store TP package).
UPDATE `mob_pools` SET
    `mJob` = 20,
    `sJob` = 4,
    `cmbSkill` = 11,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `skill_list_id` = 1083,
    `spellList` = 381
WHERE `poolid` = 5968;
