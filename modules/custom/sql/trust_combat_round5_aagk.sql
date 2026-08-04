-- AAGK: restore Trust GK WS + Dragonfall (unique anims).
-- round2 had remapped these to player Tachi WS (150-157), breaking Dragonfall / Trust anims.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1111;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_AAGK',1111,3722), -- Tachi: Yukikaze
('TRUST_AAGK',1111,3723), -- Tachi: Gekko
('TRUST_AAGK',1111,3724), -- Dragonfall (AoE + Bind)
('TRUST_AAGK',1111,3725), -- Tachi: Kasha
('TRUST_AAGK',1111,3726); -- Tachi: Fudo

UPDATE `mob_pools` SET `cmbSkill` = 10 WHERE `poolid` = 5996; -- Great Katana

-- Reaffirm Trust skill geometry (Dragonfall radial AoE).
UPDATE `mob_skills` SET `mob_skill_aoe` = 1, `mob_skill_distance` = 7.0 WHERE `mob_skill_id` = 3724;
