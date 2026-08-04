-- Rainemard: RDM/PLD sword kit (was RDM-only). Affirm retail sword WS anims/SC props.
-- Skill list 1035 already Burning / Red Lotus / Vorpal / Savage Blade.

UPDATE `mob_skills` SET
    `mob_anim_id` = 2,
    `mob_skill_name` = 'burning_blade',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 3,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 33;

UPDATE `mob_skills` SET
    `mob_anim_id` = 3,
    `mob_skill_name` = 'red_lotus_blade',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 3,
    `secondary_sc` = 6,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 34;

UPDATE `mob_skills` SET
    `mob_anim_id` = 9,
    `mob_skill_name` = 'vorpal_blade',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 5,
    `secondary_sc` = 8,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 40;

UPDATE `mob_skills` SET
    `mob_anim_id` = 11,
    `mob_skill_name` = 'savage_blade',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 12,
    `secondary_sc` = 4,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 42;

-- RDM/PLD, Sword.
UPDATE `mob_pools` SET
    `mJob` = 5,
    `sJob` = 7,
    `cmbSkill` = 3,
    `cmbDelay` = 240
WHERE `poolid` = 5920;
