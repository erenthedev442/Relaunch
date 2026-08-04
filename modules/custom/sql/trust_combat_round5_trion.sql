-- Trion: restore unique Trust WS + Royal Bash / Royal Savior.
-- round3 remapped these to player sword WS, which broke interrupt/savior kit.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1020;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Trion',1020,968),  -- Red Lotus Blade (Trust anim)
('TRUST_Trion',1020,970),  -- Savage Blade (Trust anim)
('TRUST_Trion',1020,3193), -- Royal Bash
('TRUST_Trion',1020,3194); -- Royal Savior

UPDATE `mob_pools` SET `cmbSkill` = 3 WHERE `poolid` = 5905;
