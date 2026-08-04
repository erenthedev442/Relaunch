-- Chacharoon: restore unique Qiqirn Trust MS (Sharp Eye / Tripe Gripe / Pocket Sand).
-- Skill list was empty (commented). Conal flags for Sharp Eye + Pocket Sand.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1078;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Chacharoon',1078,3442), -- Sharp Eye (conal)
('TRUST_Chacharoon',1078,3441), -- Tripe Gripe
('TRUST_Chacharoon',1078,3440); -- Pocket Sand (conal)

UPDATE `mob_skills` SET
    `mob_skill_aoe` = 4,
    `mob_skill_distance` = 10.0,
    `mob_anim_id` = 2317,
    `mob_skill_name` = 'pocket_sand'
WHERE `mob_skill_id` = 3440;

UPDATE `mob_skills` SET
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_anim_id` = 2316,
    `mob_skill_name` = 'tripe_gripe'
WHERE `mob_skill_id` = 3441;

UPDATE `mob_skills` SET
    `mob_skill_aoe` = 4,
    `mob_skill_distance` = 15.0,
    `mob_anim_id` = 2319,
    `mob_skill_name` = 'sharp_eye'
WHERE `mob_skill_id` = 3442;

-- THF/RNG, club (stick), very low delay, low base damage.
UPDATE `mob_pools` SET
    `sJob` = 11,
    `cmbSkill` = 11,
    `cmbDelay` = 140,
    `cmbDmgMult` = 55
WHERE `poolid` = 5963;
