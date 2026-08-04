-- Abenzio: restore Goobbue Trust MS (Blow / Uppercut / Antiphase / Blank Gaze).
-- round3 remapped these to player H2H WS, which broke animations / kit identity.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1074;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Abenzio',1074,3355), -- Blow
('TRUST_Abenzio',1074,3356), -- Uppercut
('TRUST_Abenzio',1074,3357), -- Antiphase (AoE silence)
('TRUST_Abenzio',1074,3358); -- Blank Gaze (conal paralysis)

UPDATE `mob_pools` SET `cmbSkill` = 1 WHERE `poolid` = 5959; -- H2H (MNK vines)

-- AoE flags for Trust copies.
UPDATE `mob_skills` SET `mob_skill_aoe` = 1, `mob_skill_distance` = 15.0 WHERE `mob_skill_id` = 3357;
UPDATE `mob_skills` SET `mob_skill_aoe` = 4 WHERE `mob_skill_id` = 3358;
