-- Joachim: BRD/WHM buffer. No WS. Throwing ranged AA (traverser stones).
-- Spell list: add Erase + Valor Minuet I–V + Knight's Minne I–V.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1026;
-- Keep empty — no weaponskills.

DELETE FROM `mob_spell_lists`
WHERE `spell_list_id` = 323
  AND `spell_id` IN (143, 389, 390, 391, 392, 393, 394, 395, 396, 397, 398);

INSERT INTO `mob_spell_lists` VALUES
('TRUST_Joachim',323,143,32,255), -- erase
('TRUST_Joachim',323,389,1,255),  -- knights_minne
('TRUST_Joachim',323,390,21,255), -- knights_minne_ii
('TRUST_Joachim',323,391,41,255), -- knights_minne_iii
('TRUST_Joachim',323,392,61,255), -- knights_minne_iv
('TRUST_Joachim',323,393,80,255), -- knights_minne_v
('TRUST_Joachim',323,394,3,255),  -- valor_minuet
('TRUST_Joachim',323,395,23,255), -- valor_minuet_ii
('TRUST_Joachim',323,396,43,255), -- valor_minuet_iii
('TRUST_Joachim',323,397,63,255), -- valor_minuet_iv
('TRUST_Joachim',323,398,87,255); -- valor_minuet_v

-- BRD/WHM, throwing skill for ranged stones. Low dmg mult (support chip).
UPDATE `mob_pools` SET
    `mJob` = 10,
    `sJob` = 3,
    `cmbSkill` = 27,
    `cmbDelay` = 500,
    `cmbDmgMult` = 40,
    `skill_list_id` = 1026,
    `spellList` = 323
WHERE `poolid` = 5911;
