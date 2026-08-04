-- Mnejing: restore Valoredge Trust WS (Chimera Ripper / String Clipper / Shield Subverter).
-- round3 remapped these to player H2H WS, which broke animations / kit identity.
-- Attachment abilities (Strobe/Shield Bash/Flashbulb/Disruptor) stay as MS gambits.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1041;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Mnejing',1041,1940), -- Chimera Ripper
('TRUST_Mnejing',1041,1941), -- String Clipper
('TRUST_Mnejing',1041,3245); -- Shield Subverter

-- Pool already uses PLD + H2H combat skill for Valoredge frame AA rating.
UPDATE `mob_pools` SET `cmbSkill` = 1 WHERE `poolid` = 5926;

-- Shield Subverter is conal AoE + Silence.
UPDATE `mob_skills` SET `mob_skill_aoe` = 4 WHERE `mob_skill_id` = 3245;
