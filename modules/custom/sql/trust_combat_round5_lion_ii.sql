-- Lion II: restore ST pirate WS kit (was remapped to player dagger WS).
-- Same anims as Lion I (2029–2032), all single-target. THF/NIN + Utsusemi list 418.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1124;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Lion_II',1124,3491), -- Grapeshot (ST)
('TRUST_Lion_II',1124,3492), -- Pirate Pummel (ST)
('TRUST_Lion_II',1124,3493), -- Powder Keg (ST)
('TRUST_Lion_II',1124,3494); -- Walk the Plank (ST)

UPDATE `mob_skills` SET
    `mob_anim_id` = 2029,
    `mob_skill_name` = 'grapeshot',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `knockback` = 0,
    `primary_sc` = 3,
    `secondary_sc` = 2
WHERE `mob_skill_id` = 3491;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2030,
    `mob_skill_name` = 'pirate_pummel',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `knockback` = 0,
    `primary_sc` = 9,
    `secondary_sc` = 0
WHERE `mob_skill_id` = 3492;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2031,
    `mob_skill_name` = 'powder_keg',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `knockback` = 2,
    `primary_sc` = 5,
    `secondary_sc` = 1
WHERE `mob_skill_id` = 3493;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2032,
    `mob_skill_name` = 'walk_the_plank',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `knockback` = 2,
    `primary_sc` = 11,
    `secondary_sc` = 0
WHERE `mob_skill_id` = 3494;

-- THF/NIN, Dagger, Utsusemi spell list.
UPDATE `mob_pools` SET
    `mJob` = 6,
    `sJob` = 13,
    `cmbSkill` = 2,
    `spellList` = 418
WHERE `poolid` = 6009;
