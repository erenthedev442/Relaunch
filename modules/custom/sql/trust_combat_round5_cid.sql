-- Cid: restore club WS + unique Trust fire WS (Fiery Tailings / Critical Mass).
-- round3 remapped him to GA player WS (Shield Break…Metatron), wrong kit/anims.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1052;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Cid',1052,166),  -- True Strike
('TRUST_Cid',1052,168),  -- Hexa Strike
('TRUST_Cid',1052,3323), -- Fiery Tailings (AoE fire)
('TRUST_Cid',1052,3322); -- Critical Mass (fire)

-- Fiery Tailings: large radial AoE. Critical Mass: single target.
UPDATE `mob_skills` SET
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_anim_id` = 2356,
    `mob_skill_name` = 'critical_mass'
WHERE `mob_skill_id` = 3322;

UPDATE `mob_skills` SET
    `mob_skill_aoe` = 1,
    `mob_skill_distance` = 20.0,
    `mob_anim_id` = 2355,
    `mob_skill_name` = 'fiery_tailings'
WHERE `mob_skill_id` = 3323;

-- WAR/RNG, Club (melee) — gun via RATTACK gambit.
UPDATE `mob_pools` SET
    `sJob` = 11,
    `cmbSkill` = 11
WHERE `poolid` = 5937;
