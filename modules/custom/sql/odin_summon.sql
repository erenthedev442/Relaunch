-- Register Odin's automatic Zantetsuken as a real pet skill.
-- pet_skill_id 670 matches xi.jobAbility.ZANTETSUKEN; mob skill 2126 supplies
-- the retail Zantetsuken animation/skill mapping. Flags 70 = Astral Flow (2)
-- + special (4) + Blood Pact: Rage (64).
DELETE FROM `pet_skills` WHERE `pet_skill_id` = 670;
INSERT INTO `pet_skills`
    (`pet_skill_id`, `mob_skill_id`, `pet_anim_id`, `pet_skill_name`,
     `pet_skill_aoe`, `pet_skill_radius`, `pet_skill_distance`,
     `pet_anim_time`, `pet_prepare_time`, `pet_valid_targets`, `pet_message`,
     `pet_skill_flag`, `pet_skill_param`, `pet_skill_finish_category`,
     `knockback`, `primary_sc`, `secondary_sc`, `tertiary_sc`)
VALUES
    (670, 2126, 150, 'zantetsuken',
     1, 10, 21, 2000, 1000, 4, 317, 70, 0, 13, 0, 0, 0, 0);
