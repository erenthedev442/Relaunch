-- Makki-Chebukki: restore retail archery kit (had Arching Arrow; missing Flaming/Dulling).
-- RNG/BLM. Flaming / Dulling / Sidewinder / Empyreal. WS@2000 no SC.
-- Flashy Shot / Sharpshot / Barrage. Lightsday idle in Lua.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1103;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Makki-Chebukki',1103,192), -- Flaming Arrow
('TRUST_Makki-Chebukki',1103,194), -- Dulling Arrow
('TRUST_Makki-Chebukki',1103,196), -- Sidewinder
('TRUST_Makki-Chebukki',1103,199); -- Empyreal Arrow

UPDATE `mob_skills` SET
    `mob_anim_id` = 191,
    `mob_skill_name` = 'flaming_arrow',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 15.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 3,
    `secondary_sc` = 1,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 192;

UPDATE `mob_skills` SET
    `mob_anim_id` = 193,
    `mob_skill_name` = 'dulling_arrow',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 15.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 3,
    `secondary_sc` = 1,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 194;

UPDATE `mob_skills` SET
    `mob_anim_id` = 195,
    `mob_skill_name` = 'sidewinder',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 15.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 5,
    `secondary_sc` = 1,
    `tertiary_sc` = 6
WHERE `mob_skill_id` = 196;

UPDATE `mob_skills` SET
    `mob_anim_id` = 221,
    `mob_skill_name` = 'empyreal_arrow',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 15.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 11,
    `secondary_sc` = 1,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 199;

-- RNG/BLM, Archery delay 500 (~168 TP with Store TP package).
UPDATE `mob_pools` SET
    `mJob` = 11,
    `sJob` = 4,
    `cmbSkill` = 25,
    `cmbDelay` = 500,
    `cmbDmgMult` = 200,
    `skill_list_id` = 1103
WHERE `poolid` = 5988;
