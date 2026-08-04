-- Ayame UC: SAM/WAR A-tier skillchain closer.
-- WS: Jinpu / Koki / Mudo / Kasha / Ageha. Mudo is trust mobskill 3501.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1120;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Ayame_UC',1120,148),  -- Tachi: Jinpu (5)
('TRUST_Ayame_UC',1120,149),  -- Tachi: Koki (25)
('TRUST_Ayame_UC',1120,3501), -- Tachi: Mudo (50)
('TRUST_Ayame_UC',1120,152),  -- Tachi: Kasha (60)
('TRUST_Ayame_UC',1120,155);  -- Tachi: Ageha (70)

-- Mudo: Fudo-like Light/Distortion closer (AI restricts to Darkness).
UPDATE `mob_skills` SET
    `mob_anim_id` = 178,
    `mob_skill_name` = 'tachi_mudo',
    `mob_skill_aoe` = 0,
    `mob_skill_aoe_radius` = 0.0,
    `mob_skill_distance` = 7.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 4,
    `primary_sc` = 13,
    `secondary_sc` = 10,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3501;

-- Ensure Ageha row exists for trust list (player WS path uses weapon_skills).
-- Pool: SAM/WAR, great katana, skill list 1120.
UPDATE `mob_pools` SET
    `mJob` = 12,
    `sJob` = 1,
    `cmbSkill` = 10,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `skill_list_id` = 1120,
    `spellList` = 0
WHERE `poolid` = 6005;
