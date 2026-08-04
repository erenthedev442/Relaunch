-- Gessho: restore unique Yagudo Trust WS + keep katana combat skill.
-- round3 remapped these to player Blade:* WS, which broke animations / kit identity.
-- Shiko no Mitate (3258) and Rinpyotosha (3260) are ability gambits, not TP WS.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1033;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Gessho',1033,3256), -- Hane Fubuki
('TRUST_Gessho',1033,3257), -- Shibaraku
('TRUST_Gessho',1033,3259); -- Happobarai

UPDATE `mob_pools` SET `cmbSkill` = 9 WHERE `poolid` = 5918;
