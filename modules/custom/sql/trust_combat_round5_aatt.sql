-- Ark Angel TT: restore Guillotine + Amon Drive (round2 wiped list as "magic only").
-- BLM/DRK Scythe. ASAP@2000 no SC. MB-only nukes + Sleepga package in Lua.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1110;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_AATT',1110,945), -- Guillotine (Ark Angel scythe anim)
('TRUST_AATT',1110,935); -- Amon Drive (AoE Para+Petrify)

UPDATE `mob_skills` SET
    `mob_anim_id` = 647,
    `mob_skill_name` = 'guillotine',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `mob_prepare_time` = 0,
    `primary_sc` = 7,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 945;

UPDATE `mob_skills` SET
    `mob_anim_id` = 636,
    `mob_skill_name` = 'amon_drive',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 10.0,
    `mob_skill_distance` = 15.0,
    `mob_valid_targets` = 4,
    `mob_prepare_time` = 500,
    `primary_sc` = 0,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 935;

-- Spell kit: ensure Sleep/Sleep II + Aero IV max; drop Aspir II (retail: Aspir).
-- Stock list already has 253/259 — must DELETE before INSERT (PK spell_list_id+spell_id).
DELETE FROM `mob_spell_lists` WHERE `spell_list_id` = 408 AND `spell_id` IN (157, 248, 253, 259);
INSERT INTO `mob_spell_lists` VALUES
('TRUST_AATT',408,157,72,255), -- aero_iv
('TRUST_AATT',408,253,20,255), -- sleep
('TRUST_AATT',408,259,41,255); -- sleep_ii

-- BLM/DRK, Scythe AA.
UPDATE `mob_pools` SET
    `mJob` = 4,
    `sJob` = 8,
    `cmbSkill` = 7,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `skill_list_id` = 1110,
    `spellList` = 408
WHERE `poolid` = 5995;
