-- Ingrid II: restore unique Club WS + Self-Aggrandizement; WHM/WAR Club.
-- Skill list 1131 was empty; pool had Sword and no WAR sub.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1131;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Ingrid_II',1131,3647), -- Merciless Strike
('TRUST_Ingrid_II',1131,164),  -- Moonlight
('TRUST_Ingrid_II',1131,3645), -- Inexorable Strike
('TRUST_Ingrid_II',1131,3644); -- Ruthlessness (conal drain)
-- Self-Aggrandizement (3646) is an ability gambit, not a TP WS.

UPDATE `mob_skills` SET
    `mob_anim_id` = 266,
    `mob_skill_name` = 'ruthlessness',
    `mob_skill_aoe` = 4,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 0,
    `secondary_sc` = 0
WHERE `mob_skill_id` = 3644;

UPDATE `mob_skills` SET
    `mob_anim_id` = 268,
    `mob_skill_name` = 'inexorable_strike',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 13,
    `secondary_sc` = 11
WHERE `mob_skill_id` = 3645;

UPDATE `mob_skills` SET
    `mob_anim_id` = 267,
    `mob_skill_name` = 'self_aggrandizement',
    `mob_skill_aoe` = 1,
    `mob_skill_distance` = 20.0,
    `mob_valid_targets` = 1,
    `primary_sc` = 0,
    `secondary_sc` = 0
WHERE `mob_skill_id` = 3646;

UPDATE `mob_skills` SET
    `mob_anim_id` = 82,
    `mob_skill_name` = 'merciless_strike',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 8,
    `secondary_sc` = 0
WHERE `mob_skill_id` = 3647;

-- WHM/WAR, Club.
UPDATE `mob_pools` SET
    `mJob` = 3,
    `sJob` = 1,
    `cmbSkill` = 11
WHERE `poolid` = 6016;

-- Spells: Banish I–III, Cursna, Holy (no Cure line / Holy II).
DELETE FROM `mob_spell_lists` WHERE `spell_list_id` = 425;

INSERT INTO `mob_spell_lists` VALUES
('TRUST_Ingrid_II',425,20,29,255), -- cursna
('TRUST_Ingrid_II',425,21,50,255), -- holy
('TRUST_Ingrid_II',425,28,5,255),  -- banish
('TRUST_Ingrid_II',425,29,30,255), -- banish_ii
('TRUST_Ingrid_II',425,30,65,255); -- banish_iii
