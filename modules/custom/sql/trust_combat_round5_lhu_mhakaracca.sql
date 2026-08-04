-- Lhu Mhakaracca: affirm retail axe kit + BST/WAR pool.
-- (List was already correct; reaffirm for live deploy.)

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1058;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Lhu_Mhakaracca',1058,68), -- Spinning Axe (favored via script)
('TRUST_Lhu_Mhakaracca',1058,69), -- Rampage
('TRUST_Lhu_Mhakaracca',1058,72), -- Decimation
('TRUST_Lhu_Mhakaracca',1058,73); -- Onslaught

-- BST/WAR, Axe, delay 240.
UPDATE `mob_pools` SET
    `mJob` = 9,
    `sJob` = 1,
    `cmbSkill` = 5,
    `cmbDelay` = 240
WHERE `poolid` = 5943;
