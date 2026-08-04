-- Maat: restore retail H2H kit + Bear Killer (was remapped to Raging/Victory Smite).
-- Anim 1625 for Bear Killer. MNK/THF Hand-to-Hand.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1048;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Maat',1048,1),    -- Combo
('TRUST_Maat',1048,3),    -- One-Ilm Punch
('TRUST_Maat',1048,7),    -- Howling Fist
('TRUST_Maat',1048,8),    -- Dragon Kick
('TRUST_Maat',1048,9),    -- Asuran Fists
('TRUST_Maat',1048,3263); -- Bear Killer (conal)

UPDATE `mob_skills` SET
    `mob_anim_id` = 1625,
    `mob_skill_name` = 'bear_killer',
    `mob_skill_aoe` = 4,
    `mob_skill_aoe_radius` = 0.0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `knockback` = 0,
    `primary_sc` = 5,
    `secondary_sc` = 8,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3263;

-- MNK/THF, Hand-to-Hand.
UPDATE `mob_pools` SET
    `mJob` = 2,
    `sJob` = 6,
    `cmbSkill` = 1,
    `cmbDelay` = 240
WHERE `poolid` = 5933;
