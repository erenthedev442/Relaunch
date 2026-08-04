-- Tenzen II: Oisoya only (base was remapped to Sidewinder…Refulgent player bow WS).
-- SAM/RNG Archery. Light/Distortion. Pure opener AI in Lua (hold @3000).

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1129;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Tenzen_II',1129,3542); -- Oisoya (Namas variant; Light/Distortion)

UPDATE `mob_skills` SET
    `mob_anim_id` = 1042,
    `mob_skill_name` = 'oisoya',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 15.0,
    `mob_valid_targets` = 4,
    `mob_prepare_time` = 1500,
    `primary_sc` = 13,
    `secondary_sc` = 10,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3542;

-- Story Oisoya: keep anim; add Light/Distortion for BCNM consistency.
UPDATE `mob_skills` SET
    `mob_anim_id` = 1042,
    `mob_skill_name` = 'oisoya',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 15.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 13,
    `secondary_sc` = 10,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 1397;

-- SAM/RNG, Archery RA. Delay 500 + Store TP package → ~252 TP/hit @90+.
UPDATE `mob_pools` SET
    `mJob` = 12,
    `sJob` = 11,
    `cmbSkill` = 25,
    `cmbDelay` = 500,
    `cmbDmgMult` = 200,
    `skill_list_id` = 1129
WHERE `poolid` = 6014;
