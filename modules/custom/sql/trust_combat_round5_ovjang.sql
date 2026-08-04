-- Ovjang: restore Stormwaker automaton kit (round3 injected club Skullbreaker…).
-- RDM/BLM. Slapstick / Knockout / Sixth Element (preferred; Gravitation; non-ele magic).
-- Spells already retail (337): Slow/Silence/Paralyze/Dispel, ST nukes I–IV.
-- CLOSER@1500; Dispel first; MP+20% + Nashmeira synergy in Lua.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1040;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Ovjang',1040,1943), -- Slapstick
('TRUST_Ovjang',1040,2067), -- Knockout
('TRUST_Ovjang',1040,3244); -- Sixth Element (preferred — last for HIGHEST)

UPDATE `mob_skills` SET
    `mob_anim_id` = 1306,
    `mob_skill_name` = 'slapstick',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 1500,
    `primary_sc` = 5,
    `secondary_sc` = 8,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 1943;

UPDATE `mob_skills` SET
    `mob_anim_id` = 1406,
    `mob_skill_name` = 'knockout',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `mob_prepare_time` = 1500,
    `primary_sc` = 4,
    `secondary_sc` = 6,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 2067;

-- Sixth Element: non-ele magic, Gravitation.
UPDATE `mob_skills` SET
    `mob_anim_id` = 2035,
    `mob_skill_name` = 'sixth_element',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `mob_prepare_time` = 1500,
    `primary_sc` = 11,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3244;

-- RDM/BLM Stormwaker. Occasional staff AA between casts.
UPDATE `mob_pools` SET
    `mJob` = 5,
    `sJob` = 4,
    `cmbSkill` = 3,
    `cmbDelay` = 240,
    `cmbDmgMult` = 80,
    `skill_list_id` = 1040,
    `spellList` = 337
WHERE `poolid` = 5925;
