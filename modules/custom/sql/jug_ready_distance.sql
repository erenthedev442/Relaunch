-- Jug Ready skills shipped with pet_skill_distance = 3, so a pet that
-- looks in melee (especially on a large hitbox) fails the range check.
-- Blood Pacts are left alone (mob_skill_id = 0 or skill flags).
UPDATE `pet_skills`
   SET `pet_skill_distance` = 15
 WHERE `mob_skill_id` > 0
   AND `pet_skill_flag` = 0
   AND `pet_skill_distance` <= 3;
