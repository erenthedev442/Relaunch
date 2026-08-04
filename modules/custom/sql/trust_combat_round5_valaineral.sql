-- Valaineral: confirm retail sword WS + Uriel Blade (AoE light).
-- Skill list was already correct; safe re-apply for live DBs.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1025;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Valaineral',1025,38),  -- Circle Blade
('TRUST_Valaineral',1025,42),  -- Savage Blade
('TRUST_Valaineral',1025,47),  -- Sanguine Blade
('TRUST_Valaineral',1025,238); -- Uriel Blade (AoE)

UPDATE `mob_pools` SET `cmbSkill` = 3 WHERE `poolid` = 5910;

-- Uriel Blade: radial AoE around self/target.
UPDATE `mob_skills` SET `mob_skill_aoe` = 1 WHERE `mob_skill_id` = 238;
