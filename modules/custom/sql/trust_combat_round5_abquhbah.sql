-- Abquhbah: restore retail H2H kit (Combo / Backhand Blow / Salaheem Spirit).
-- round3 stripped 3541 and base list had been padded with player H2H WS.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1097;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Abquhbah',1097,1),    -- Combo
('TRUST_Abquhbah',1097,4),    -- Backhand Blow
('TRUST_Abquhbah',1097,3541); -- Salaheem Spirit (party attr buff)

UPDATE `mob_pools` SET `cmbSkill` = 1 WHERE `poolid` = 5982; -- H2H

-- Party AoE buff (already aoe=1 / 15' in mob_skills; reaffirm for live).
UPDATE `mob_skills` SET `mob_skill_aoe` = 1, `mob_skill_distance` = 15.0 WHERE `mob_skill_id` = 3541;
