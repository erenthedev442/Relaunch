-- Iroha: restore unique Amatsu WS (wrongly remapped to player Tachi Yukikaze…Shoha).
-- SAM/WHM Great Katana; Protectra V / Shellra V only.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1112;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Iroha',1112,3558), -- Amatsu: Hanadoki (Light)
('TRUST_Iroha',1112,3559), -- Amatsu: Choun (Fire)
('TRUST_Iroha',1112,3556), -- Amatsu: Fuga (Fire)
('TRUST_Iroha',1112,3560); -- Amatsu: Gachirin (Light)

UPDATE `mob_skills` SET
    `mob_anim_id` = 488,
    `mob_skill_name` = 'amatsu_fuga',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 11,
    `secondary_sc` = 0
WHERE `mob_skill_id` = 3556;

UPDATE `mob_skills` SET
    `mob_anim_id` = 489,
    `mob_skill_name` = 'amatsu_hanadoki',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 8,
    `secondary_sc` = 0
WHERE `mob_skill_id` = 3558;

UPDATE `mob_skills` SET
    `mob_anim_id` = 490,
    `mob_skill_name` = 'amatsu_choun',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 3,
    `secondary_sc` = 0
WHERE `mob_skill_id` = 3559;

UPDATE `mob_skills` SET
    `mob_anim_id` = 491,
    `mob_skill_name` = 'amatsu_gachirin',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 13,
    `secondary_sc` = 12
WHERE `mob_skill_id` = 3560;

-- SAM/WHM, Great Katana.
UPDATE `mob_pools` SET
    `mJob` = 12,
    `sJob` = 3,
    `cmbSkill` = 10
WHERE `poolid` = 5997;

-- Protectra V / Shellra V only (no lower tiers).
DELETE FROM `mob_spell_lists` WHERE `spell_list_id` = 410;

INSERT INTO `mob_spell_lists` VALUES
('TRUST_Iroha',410,129,75,255), -- protectra_v
('TRUST_Iroha',410,134,75,255); -- shellra_v
