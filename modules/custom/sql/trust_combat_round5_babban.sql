-- Babban: restore plantoid MS (Wild Oats / Head Butt / Photosynthesis / Petal Pirouette).
-- round2 remapped these to player H2H WS, which broke mandragora kit / animations.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1073;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Babban',1073,3351), -- Wild Oats
('TRUST_Babban',1073,3354), -- Head Butt
('TRUST_Babban',1073,3352), -- Photosynthesis (self Regen, daytime check in Lua)
('TRUST_Babban',1073,3353); -- Petal Pirouette (AoE TP reset)

UPDATE `mob_pools` SET `cmbSkill` = 1 WHERE `poolid` = 5958; -- H2H

-- Photosynthesis: self target. Petal Pirouette: radial AoE.
INSERT INTO `mob_skills` VALUES (3352,48,'photosynthesis',0,0.0,7.0,2000,1500,1,0,0,0,0,0,0)
    ON DUPLICATE KEY UPDATE
        `mob_anim_id` = 48,
        `mob_skill_name` = 'photosynthesis',
        `mob_valid_targets` = 1;

UPDATE `mob_skills` SET `mob_skill_aoe` = 1, `mob_skill_distance` = 7.0 WHERE `mob_skill_id` = 3353;

-- Retail HP-10%.
INSERT INTO `mob_pool_mods` VALUES (5958,3,-10,0)
    ON DUPLICATE KEY UPDATE `value` = -10;
