-- Fablinix: restore Goblin Trust WS (Bomb Toss / Goblin Rush).
-- round3 remapped him to club player WS (Skullbreaker…Black Halo) and Club skill.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1047;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Fablinix',1047,3261), -- Bomb Toss (AoE fire)
('TRUST_Fablinix',1047,3262); -- Goblin Rush

UPDATE `mob_skills` SET
    `mob_anim_id` = 335,
    `mob_skill_name` = 'bomb_toss',
    `mob_skill_aoe` = 2,
    `mob_skill_distance` = 13.5,
    `mob_valid_targets` = 4
WHERE `mob_skill_id` = 3261;

UPDATE `mob_skills` SET
    `mob_anim_id` = 334,
    `mob_skill_name` = 'goblin_rush',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 6.0,
    `mob_valid_targets` = 4
WHERE `mob_skill_id` = 3262;

-- THF/RDM, Dagger melee; crossbow via RATTACK gambit.
UPDATE `mob_pools` SET
    `mJob` = 6,
    `sJob` = 5,
    `cmbSkill` = 2
WHERE `poolid` = 5932;

-- Stun available at master 42 (BLM-level access on retail notes).
UPDATE `mob_spell_lists` SET `min_level` = 42
WHERE `spell_list_name` = 'TRUST_Fablinix' AND `spell_id` = 252;
