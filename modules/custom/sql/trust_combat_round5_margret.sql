-- Margret: affirm retail archery kit + RNG/THF pool.
-- Piercing / Sidewinder / Arching / Refulgent. WS@2000 no SC.
-- Decoy / Double / Barrage / Sharpshot / Stealth Shot. TH3 + TP package in Lua.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1077;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Margret',1077,193), -- Piercing Arrow
('TRUST_Margret',1077,196), -- Sidewinder
('TRUST_Margret',1077,198), -- Arching Arrow (Fusion/Compression dual SC)
('TRUST_Margret',1077,201); -- Refulgent Arrow

UPDATE `mob_skills` SET
    `mob_anim_id` = 192,
    `mob_skill_name` = 'piercing_arrow',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 15.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 5,
    `secondary_sc` = 1,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 193;

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

-- Arching Arrow: Fusion (Lv2 Fire/Light — her only dual-element SC WS).
UPDATE `mob_skills` SET
    `mob_anim_id` = 220,
    `mob_skill_name` = 'arching_arrow',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 15.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 11,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 198;

UPDATE `mob_skills` SET
    `mob_anim_id` = 232,
    `mob_skill_name` = 'refulgent_arrow',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 15.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 5,
    `secondary_sc` = 1,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 201;

-- RNG/THF, Archery. Delay 360 + Store TP package → ~252 TP/hit.
UPDATE `mob_pools` SET
    `mJob` = 11,
    `sJob` = 6,
    `cmbSkill` = 25,
    `cmbDelay` = 360,
    `cmbDmgMult` = 200,
    `skill_list_id` = 1077
WHERE `poolid` = 5962;
