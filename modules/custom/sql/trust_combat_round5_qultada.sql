-- Qultada: COR/RNG. Marksmanship AA + sword/gun WS kit (already on 1082).
-- WS: Burning Blade / Savage Blade / Sniper Shot / Detonator.

-- Keep retail WS list.
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1082;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Qultada',1082,33),  -- Burning Blade
('TRUST_Qultada',1082,42),  -- Savage Blade
('TRUST_Qultada',1082,210), -- Sniper Shot
('TRUST_Qultada',1082,215); -- Detonator

-- Light / Dark Shot utility anims (script-invoked, no TP).
UPDATE `mob_skills` SET
    `mob_anim_id` = 123,
    `mob_skill_name` = 'light_shot',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 22.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 4,
    `mob_skill_flag` = 4
WHERE `mob_skill_id` = 2015;

UPDATE `mob_skills` SET
    `mob_anim_id` = 124,
    `mob_skill_name` = 'dark_shot',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 22.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 4,
    `mob_skill_flag` = 4
WHERE `mob_skill_id` = 2016;

-- COR/RNG, marksmanship primary (gun AA).
UPDATE `mob_pools` SET
    `mJob` = 17,
    `sJob` = 11,
    `cmbSkill` = 26,
    `cmbDelay` = 600,
    `cmbDmgMult` = 200,
    `skill_list_id` = 1082,
    `spellList` = 0
WHERE `poolid` = 5967;
