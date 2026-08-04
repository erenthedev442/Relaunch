-- Lhe Lhangavo: retail H2H WS kit (was Combo / wrong IDs / Victory Smite).
-- MNK/WAR Hand-to-Hand pool already correct — affirm.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1079;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Lhe_Lhangavo',1079,4), -- Backhand Blow
('TRUST_Lhe_Lhangavo',1079,5), -- Raging Fists
('TRUST_Lhe_Lhangavo',1079,8), -- Dragon Kick
('TRUST_Lhe_Lhangavo',1079,9); -- Asuran Fists

-- MNK/WAR, Hand-to-Hand.
UPDATE `mob_pools` SET
    `mJob` = 2,
    `sJob` = 1,
    `cmbSkill` = 1
WHERE `poolid` = 5964;
