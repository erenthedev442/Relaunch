-- Ingrid: restore club kit (list was empty) + retail spell kit.
-- WHM/WHM. Seraph Strike / Judgment / Hexa Strike.
-- Spells: Haste, Banish I–III, Cursna only (no Cure / Protectra).
-- CLOSER@1500. Melee. Undead Killer in Lua.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1036;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Ingrid',1036,161), -- Seraph Strike (Light / Impaction)
('TRUST_Ingrid',1036,167), -- Judgment (Impaction)
('TRUST_Ingrid',1036,168); -- Hexa Strike (Fusion)

UPDATE `mob_skills` SET
    `mob_anim_id` = 77,
    `mob_skill_name` = 'seraph_strike',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 8,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 161;

UPDATE `mob_skills` SET
    `mob_anim_id` = 83,
    `mob_skill_name` = 'judgment',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 8,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 167;

UPDATE `mob_skills` SET
    `mob_anim_id` = 84,
    `mob_skill_name` = 'hexa_strike',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 11,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 168;

-- Retail spell kit only.
DELETE FROM `mob_spell_lists` WHERE `spell_list_id` = 333;

INSERT INTO `mob_spell_lists` VALUES
('TRUST_Ingrid',333,20,29,255), -- cursna
('TRUST_Ingrid',333,28,5,255),  -- banish
('TRUST_Ingrid',333,29,30,255), -- banish_ii
('TRUST_Ingrid',333,30,65,255), -- banish_iii
('TRUST_Ingrid',333,57,40,255); -- haste

-- WHM/WHM, Club. Delay 240 + Store TP → ~100 TP/hit.
UPDATE `mob_pools` SET
    `mJob` = 3,
    `sJob` = 3,
    `cmbSkill` = 11,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `skill_list_id` = 1036,
    `spell_list_id` = 333
WHERE `poolid` = 5921;
