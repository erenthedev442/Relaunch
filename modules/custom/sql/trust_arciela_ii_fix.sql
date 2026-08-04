-- Arciela II: restore retail RDM spell coverage and unique TP moves.
-- Prefer trust_combat_round5_arciela_ii.sql for full combat props.

DELETE FROM `mob_spell_lists`
WHERE `spell_list_id` = 426
  AND `spell_id` IN (43,44,45,46,47,48,49,50,51,52);

INSERT INTO `mob_spell_lists` VALUES
('TRUST_Arciela_II',426,43,7,255),
('TRUST_Arciela_II',426,44,27,255),
('TRUST_Arciela_II',426,45,47,255),
('TRUST_Arciela_II',426,46,63,255),
('TRUST_Arciela_II',426,47,77,255),
('TRUST_Arciela_II',426,48,17,255),
('TRUST_Arciela_II',426,49,37,255),
('TRUST_Arciela_II',426,50,57,255),
('TRUST_Arciela_II',426,51,68,255),
('TRUST_Arciela_II',426,52,87,255);

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1132;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Arciela_II',1132,3699),
('TRUST_Arciela_II',1132,3700),
('TRUST_Arciela_II',1132,3701),
('TRUST_Arciela_II',1132,3702),
('TRUST_Arciela_II',1132,3703),
('TRUST_Arciela_II',1132,3704);

UPDATE `mob_pools` SET
    `mJob` = 5,
    `sJob` = 4,
    `skill_list_id` = 1132,
    `spellList` = 426
WHERE `poolid` = 6017;
