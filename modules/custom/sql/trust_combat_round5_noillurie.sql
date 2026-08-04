-- Noillurie: restore Great Katana Tachi kit (was remapped to sword WS).
-- SAM/PLD. Jinpu / Yukikaze / Gekko / Kasha / Kaiten. Spell list 354 Cure I–IV.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1057;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Noillurie',1057,148), -- Tachi: Jinpu
('TRUST_Noillurie',1057,150), -- Tachi: Yukikaze
('TRUST_Noillurie',1057,151), -- Tachi: Gekko
('TRUST_Noillurie',1057,152), -- Tachi: Kasha
('TRUST_Noillurie',1057,153); -- Tachi: Kaiten

-- Affirm GK anim / SC props (Light / Fragmentation on Kaiten).
UPDATE `mob_skills` SET
    `mob_anim_id` = 170,
    `mob_skill_name` = 'tachi_jinpu',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 4,
    `secondary_sc` = 6,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 148;

UPDATE `mob_skills` SET
    `mob_anim_id` = 172,
    `mob_skill_name` = 'tachi_yukikaze',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 7,
    `secondary_sc` = 6,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 150;

UPDATE `mob_skills` SET
    `mob_anim_id` = 173,
    `mob_skill_name` = 'tachi_gekko',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 10,
    `secondary_sc` = 5,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 151;

UPDATE `mob_skills` SET
    `mob_anim_id` = 174,
    `mob_skill_name` = 'tachi_kasha',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 11,
    `secondary_sc` = 2,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 152;

UPDATE `mob_skills` SET
    `mob_anim_id` = 175,
    `mob_skill_name` = 'tachi_kaiten',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 13,
    `secondary_sc` = 12,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 153;

-- SAM/PLD, Great Katana (was sword cmbSkill=3 / delay 240).
UPDATE `mob_pools` SET
    `mJob` = 12,
    `sJob` = 7,
    `cmbSkill` = 10,
    `cmbDelay` = 440
WHERE `poolid` = 5942;
