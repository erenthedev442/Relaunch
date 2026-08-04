-- Gilgamesh: restore unique Trust GK WS (Goten / Kasha / Iainuki / Kamai).
-- Base list was remapped to player Tachi Enpi…Shoha (wrong kit/anims).

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1053;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Gilgamesh',1053,3436), -- Tachi: Goten
('TRUST_Gilgamesh',1053,3437), -- Tachi: Kasha
('TRUST_Gilgamesh',1053,3435), -- Iainuki
('TRUST_Gilgamesh',1053,3434); -- Tachi: Kamai (AoE wind)

UPDATE `mob_skills` SET
    `mob_anim_id` = 385,
    `mob_skill_name` = 'tachi_kamai',
    `mob_skill_aoe` = 1,
    `mob_skill_distance` = 12.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 9,
    `secondary_sc` = 4
WHERE `mob_skill_id` = 3434;

UPDATE `mob_skills` SET
    `mob_anim_id` = 386,
    `mob_skill_name` = 'iainuki',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4
WHERE `mob_skill_id` = 3435;

UPDATE `mob_skills` SET
    `mob_anim_id` = 383,
    `mob_skill_name` = 'tachi_goten',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4
WHERE `mob_skill_id` = 3436;

UPDATE `mob_skills` SET
    `mob_anim_id` = 384,
    `mob_skill_name` = 'tachi_kasha',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 11,
    `secondary_sc` = 2
WHERE `mob_skill_id` = 3437;

-- SAM/WAR, Great Katana.
UPDATE `mob_pools` SET
    `mJob` = 12,
    `sJob` = 1,
    `cmbSkill` = 10
WHERE `poolid` = 5938;
