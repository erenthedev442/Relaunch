-- Selh'teus: restore unique Trust WS (was remapped to sword WS).
-- PLD/SAM staff. Luminous Lance (ranged Light/Fusion) / Rejuvenation / Revelation (Light/Fusion).
-- Trust skill IDs 3621–3623 (capture anim +2048).

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1094;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Selh_teus',1094,3621), -- Luminous Lance (ranged)
('TRUST_Selh_teus',1094,3622), -- Rejuvenation (party HP/MP/TP)
('TRUST_Selh_teus',1094,3623); -- Revelation

UPDATE `mob_skills` SET
    `mob_anim_id` = 2531,
    `mob_skill_name` = 'luminous_lance',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 20.0,
    `mob_valid_targets` = 4,
    `mob_skill_flag` = 4,
    `primary_sc` = 13,
    `secondary_sc` = 11,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3621;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2529,
    `mob_skill_name` = 'rejuvenation',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 0.0,
    `mob_skill_distance` = 20.0,
    `mob_valid_targets` = 1,
    `mob_skill_flag` = 0,
    `primary_sc` = 0,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3622;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2530,
    `mob_skill_name` = 'revelation',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 20.0,
    `mob_valid_targets` = 4,
    `mob_skill_flag` = 0,
    `primary_sc` = 13,
    `secondary_sc` = 11,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3623;

-- PLD/SAM, Staff AA (treated as Paladin for support AI). Retail weapon type is staff.
UPDATE `mob_pools` SET
    `mJob` = 7,
    `sJob` = 12,
    `cmbSkill` = 12,
    `cmbDelay` = 240
WHERE `poolid` = 5979;
