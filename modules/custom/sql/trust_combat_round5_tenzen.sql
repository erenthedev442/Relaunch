-- Tenzen: restore Amatsu WS (round3 remapped to player Tachi Yukikaze…Shoha).
-- SAM/SAM Great Katana. Torimai / Kazakiri / Yukiarashi / Tsukioboro /
-- Hanaikusa / Tsukikage (story IDs 1390–1395; Trust fTP branched in Lua).

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1023;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Tenzen',1023,1390), -- Amatsu: Torimai
('TRUST_Tenzen',1023,1391), -- Amatsu: Kazakiri
('TRUST_Tenzen',1023,1392), -- Amatsu: Yukiarashi
('TRUST_Tenzen',1023,1393), -- Amatsu: Tsukioboro
('TRUST_Tenzen',1023,1394), -- Amatsu: Hanaikusa
('TRUST_Tenzen',1023,1395); -- Amatsu: Tsukikage

-- Affirm Amatsu anims / SC props (shared with story Tenzen).
UPDATE `mob_skills` SET
    `mob_anim_id` = 1037,
    `mob_skill_name` = 'amatsu_torimai',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 1,
    `secondary_sc` = 4,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 1390;

UPDATE `mob_skills` SET
    `mob_anim_id` = 1038,
    `mob_skill_name` = 'amatsu_kazakiri',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 4,
    `secondary_sc` = 6,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 1391;

UPDATE `mob_skills` SET
    `mob_anim_id` = 1039,
    `mob_skill_name` = 'amatsu_yukiarashi',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 7,
    `secondary_sc` = 6,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 1392;

UPDATE `mob_skills` SET
    `mob_anim_id` = 1040,
    `mob_skill_name` = 'amatsu_tsukioboro',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 10,
    `secondary_sc` = 5,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 1393;

UPDATE `mob_skills` SET
    `mob_anim_id` = 1041,
    `mob_skill_name` = 'amatsu_hanaikusa',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 11,
    `secondary_sc` = 2,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 1394;

UPDATE `mob_skills` SET
    `mob_anim_id` = 1036,
    `mob_skill_name` = 'amatsu_tsukikage',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 12,
    `secondary_sc` = 6,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 1395;

-- SAM/SAM, Great Katana, delay 440 (~203 TP/hit with STORE_TP).
UPDATE `mob_pools` SET
    `mJob` = 12,
    `sJob` = 12,
    `cmbSkill` = 10,
    `cmbDelay` = 440
WHERE `poolid` = 5908;
