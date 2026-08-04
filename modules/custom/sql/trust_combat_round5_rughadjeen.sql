-- Rughadjeen: confirm GS retail WS + Victory Beacon (conal Trust MS).
-- Skill list was already correct; this is a safe re-apply for live DBs.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1075;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Rughadjeen',1075,49),   -- Power Slash
('TRUST_Rughadjeen',1075,54),   -- Sickle Moon
('TRUST_Rughadjeen',1075,56),   -- Ground Strike
('TRUST_Rughadjeen',1075,3237); -- Victory Beacon (conal)

-- Great Sword (Algol). Victory Beacon stays conal.
UPDATE `mob_pools` SET `cmbSkill` = 4 WHERE `poolid` = 5960;
UPDATE `mob_skills` SET `mob_skill_aoe` = 4 WHERE `mob_skill_id` = 3237;
