-- Iroha II: restore unique Amatsu II WS + Rise From Ashes.
-- Base list was remapped to player Tachi Yukikaze…Shoha (wrong kit/anims).

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1133;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Iroha_II',1133,3733), -- Amatsu: Kyori (Fire)
('TRUST_Iroha_II',1133,3734), -- Amatsu: Hanadoki (Light + Dispel)
('TRUST_Iroha_II',1133,3737), -- Amatsu: Suien (Fire)
('TRUST_Iroha_II',1133,3736); -- Amatsu: Gachirin (Light)
-- Rise From Ashes (3738) is ability AI, not a TP WS.

UPDATE `mob_skills` SET
    `mob_anim_id` = 492,
    `mob_skill_name` = 'amatsu_kyori',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 7,
    `secondary_sc` = 0
WHERE `mob_skill_id` = 3733;

UPDATE `mob_skills` SET
    `mob_anim_id` = 489,
    `mob_skill_name` = 'amatsu_hanadoki',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 12,
    `secondary_sc` = 5
WHERE `mob_skill_id` = 3734;

UPDATE `mob_skills` SET
    `mob_anim_id` = 491,
    `mob_skill_name` = 'amatsu_gachirin',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 13,
    `secondary_sc` = 12
WHERE `mob_skill_id` = 3736;

UPDATE `mob_skills` SET
    `mob_anim_id` = 493,
    `mob_skill_name` = 'amatsu_suien',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 11,
    `secondary_sc` = 0
WHERE `mob_skill_id` = 3737;

UPDATE `mob_skills` SET
    `mob_anim_id` = 516,
    `mob_skill_name` = 'rise_from_ashes',
    `mob_skill_aoe` = 1,
    `mob_skill_distance` = 20.0,
    `mob_valid_targets` = 1,
    `primary_sc` = 0,
    `secondary_sc` = 0
WHERE `mob_skill_id` = 3738;

-- SAM/WHM, Great Katana (pool already correct; reaffirm).
UPDATE `mob_pools` SET
    `mJob` = 12,
    `sJob` = 3,
    `cmbSkill` = 10
WHERE `poolid` = 6018;

-- Protectra V / Shellra V / Flare II only.
DELETE FROM `mob_spell_lists` WHERE `spell_list_id` = 427;

INSERT INTO `mob_spell_lists` VALUES
('TRUST_Iroha_II',427,129,75,255), -- protectra_v
('TRUST_Iroha_II',427,134,75,255), -- shellra_v
('TRUST_Iroha_II',427,205,75,255); -- flare_ii
