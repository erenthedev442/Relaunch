-- Leonoyne: restore GS kit (list was empty) + Spine Chiller.
-- BLM/PLD. Freezebite / Shockwave / Herculean Slash / Spine Chiller (rare Terror).
-- Ice Spikes + Blizzaga I–III. ASAP@1000 RANDOM. Enblizzard + MP convert in Lua.
-- B-tier nuker (pressure) — no kit inject (kit would disable AA).

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1089;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Leonoyne',1089,51),   -- Freezebite
('TRUST_Leonoyne',1089,52),   -- Shockwave
('TRUST_Leonoyne',1089,58),   -- Herculean Slash
('TRUST_Leonoyne',1089,2274); -- Spine Chiller (unique; Terror)

-- Player GS WS anims / SC (used via skill_id <= 255 weaponskill path).
UPDATE `mob_skills` SET
    `mob_anim_id` = 109,
    `mob_skill_name` = 'freezebite',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 10.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 7,
    `secondary_sc` = 6,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 51;

UPDATE `mob_skills` SET
    `mob_anim_id` = 110,
    `mob_skill_name` = 'shockwave',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 10.0,
    `mob_skill_distance` = 10.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 5,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 52;

UPDATE `mob_skills` SET
    `mob_anim_id` = 116,
    `mob_skill_name` = 'herculean_slash',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 10.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 7,
    `secondary_sc` = 8,
    `tertiary_sc` = 6
WHERE `mob_skill_id` = 58;

-- Spine Chiller: was commented out in base dump — insert if missing.
INSERT INTO `mob_skills` VALUES
(2274,2018,'spine_chiller',4,10.0,10.0,2000,1500,4,0,0,0,7,6,0)
ON DUPLICATE KEY UPDATE
    `mob_anim_id` = 2018,
    `mob_skill_name` = 'spine_chiller',
    `mob_skill_aoe` = 4,
    `mob_skill_aoe_radius` = 10.0,
    `mob_skill_distance` = 10.0,
    `mob_valid_targets` = 4,
    `mob_prepare_time` = 1500,
    `primary_sc` = 7,
    `secondary_sc` = 6,
    `tertiary_sc` = 0;

-- BLM/PLD, Great Sword.
UPDATE `mob_pools` SET
    `mJob` = 4,
    `sJob` = 7,
    `cmbSkill` = 4,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `skill_list_id` = 1089,
    `spellList` = 387
WHERE `poolid` = 5974;
