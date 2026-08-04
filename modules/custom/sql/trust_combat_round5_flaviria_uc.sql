-- Flaviria UC: DRG/WAR A-tier polearm DD.
-- WS driven from Lua (no auto TP list) so she does not hold for skillchains.
-- Document kit on list 1072; pool skill_list_id stays 0.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1072;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Flaviria_UC',1072,118),  -- Skewer (5)
('TRUST_Flaviria_UC',1072,120),  -- Impulse Drive (25)
('TRUST_Flaviria_UC',1072,3500); -- Celidon's Torment (50)

-- Celidon: Camlann-like ignore DEF, piercing, no SC props needed (Lua pick).
UPDATE `mob_skills` SET
    `mob_anim_id` = 133,
    `mob_skill_name` = 'celidons_torment',
    `mob_skill_aoe` = 0,
    `mob_skill_aoe_radius` = 0.0,
    `mob_skill_distance` = 7.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 4,
    `primary_sc` = 13,
    `secondary_sc` = 12,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3500;

-- Affirm Skewer / Impulse anims (player WS ids reused as mobskills).
UPDATE `mob_skills` SET
    `mob_anim_id` = 127,
    `mob_skill_name` = 'skewer',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 4
WHERE `mob_skill_id` = 118;

UPDATE `mob_skills` SET
    `mob_anim_id` = 129,
    `mob_skill_name` = 'impulse_drive',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 4
WHERE `mob_skill_id` = 120;

UPDATE `mob_pools` SET
    `mJob` = 14,
    `sJob` = 1,
    `cmbSkill` = 8,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `skill_list_id` = 0,
    `spellList` = 0
WHERE `poolid` = 5957;
