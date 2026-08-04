-- Ayame: full retail GK WS list including Tachi: Koki (149).
-- Player WS IDs (144-152) are correct for Trust Ayame animations.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1015;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Ayame',1015,144), -- Tachi: Enpi
('TRUST_Ayame',1015,145), -- Tachi: Hobaku
('TRUST_Ayame',1015,146), -- Tachi: Goten
('TRUST_Ayame',1015,147), -- Tachi: Kagero
('TRUST_Ayame',1015,148), -- Tachi: Jinpu
('TRUST_Ayame',1015,149), -- Tachi: Koki
('TRUST_Ayame',1015,150), -- Tachi: Yukikaze
('TRUST_Ayame',1015,151), -- Tachi: Gekko
('TRUST_Ayame',1015,152); -- Tachi: Kasha

UPDATE `mob_pools` SET `cmbSkill` = 10 WHERE `poolid` = 5900; -- Great Katana
