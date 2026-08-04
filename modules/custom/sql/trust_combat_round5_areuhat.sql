-- Areuhat: restore sword WS + Trust wyrm TP moves (Dragon Breath / Hurricane Wing).
-- round3 stripped 3438/3439 (stall risk from wyrm skill checks); checks now allow trusts.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1054;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Areuhat',1054,37),   -- Seraph Blade
('TRUST_Areuhat',1054,40),   -- Vorpal Blade
('TRUST_Areuhat',1054,42),   -- Savage Blade
('TRUST_Areuhat',1054,3438), -- Dragon Breath (Trust anim 2430, target-AoE)
('TRUST_Areuhat',1054,3439); -- Hurricane Wing (Trust anim 2429, radial AoE)

UPDATE `mob_pools` SET `cmbSkill` = 3 WHERE `poolid` = 5939; -- Sword (WAR/PLD)

-- Reaffirm Trust skill geometry / animations (match mob_skills.sql).
UPDATE `mob_skills` SET `mob_anim_id` = 2430, `mob_skill_aoe` = 2, `mob_skill_distance` = 7.0 WHERE `mob_skill_id` = 3438;
UPDATE `mob_skills` SET `mob_anim_id` = 2429, `mob_skill_aoe` = 1, `mob_skill_distance` = 7.0 WHERE `mob_skill_id` = 3439;

-- Enhanced Blood Rage (60s = 30 base + 30) and Demon Killer already in mob_pool_mods (5939).
