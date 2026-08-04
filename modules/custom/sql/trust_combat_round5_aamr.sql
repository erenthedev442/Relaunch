-- AAMR: restore Trust axe WS + Havoc Spiral (unique anims).
-- round2 had remapped these to player axe WS (Rampage/Calamity/Decimation/Cloudsplitter/Ruinator).

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1109;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_AAMR',1109,3715), -- Rampage
('TRUST_AAMR',1109,3716), -- Calamity
('TRUST_AAMR',1109,3717), -- Havoc Spiral (AoE + Sleep)
('TRUST_AAMR',1109,3718); -- Cloudsplitter

UPDATE `mob_pools` SET `cmbSkill` = 5 WHERE `poolid` = 5994; -- Axe

-- Havoc Spiral radial AoE (match mob_skills.sql).
UPDATE `mob_skills` SET `mob_skill_aoe` = 1, `mob_skill_distance` = 7.0 WHERE `mob_skill_id` = 3717;
