-- Lion: restore unique pirate WS kit (was remapped to player dagger WS).
-- Anims 2029–2032. THF/THF Dagger.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1022;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Lion',1022,3198), -- Grapeshot (conal stun)
('TRUST_Lion',1022,3199), -- Pirate Pummel
('TRUST_Lion',1022,3200), -- Powder Keg (conal)
('TRUST_Lion',1022,3201); -- Walk the Plank (AoE)

UPDATE `mob_skills` SET
    `mob_anim_id` = 2029,
    `mob_skill_name` = 'grapeshot',
    `mob_skill_aoe` = 4,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `knockback` = 0,
    `primary_sc` = 3,
    `secondary_sc` = 2
WHERE `mob_skill_id` = 3198;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2030,
    `mob_skill_name` = 'pirate_pummel',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `knockback` = 0,
    `primary_sc` = 9,
    `secondary_sc` = 0
WHERE `mob_skill_id` = 3199;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2031,
    `mob_skill_name` = 'powder_keg',
    `mob_skill_aoe` = 4,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `knockback` = 2,
    `primary_sc` = 5,
    `secondary_sc` = 1
WHERE `mob_skill_id` = 3200;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2032,
    `mob_skill_name` = 'walk_the_plank',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 8.0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `knockback` = 2,
    `primary_sc` = 11,
    `secondary_sc` = 0
WHERE `mob_skill_id` = 3201;

-- THF/THF, Dagger.
UPDATE `mob_pools` SET
    `mJob` = 6,
    `sJob` = 6,
    `cmbSkill` = 2
WHERE `poolid` = 5907;
