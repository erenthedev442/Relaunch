-- August: restore unique Daybreak WS + weapon-swap AA skill lists.
-- round3 remapped these to player GS WS (Power Slash etc.), which broke
-- SPECIAL_AUGUST (skill IDs 3653-3658) and his captured AA animations.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1099;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_August',1099,3653), -- Tartaric Sigil
('TRUST_August',1099,3654), -- Null Field
('TRUST_August',1099,3655), -- Alabaster Burst
('TRUST_August',1099,3656), -- Noble Frenzy
('TRUST_August',1099,3657), -- Fulminous Fury
('TRUST_August',1099,3658); -- No Quarter

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1197;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_August_Melee',1197,3648), -- august_melee_sword
('TRUST_August_Melee',1197,3649), -- august_melee_axe
('TRUST_August_Melee',1197,3650), -- august_melee_h2h
('TRUST_August_Melee',1197,3651); -- august_melee_bow

-- Great Sword combat skill (Damage Limit+ / Inundation; pool already 4).
UPDATE `mob_pools` SET `cmbSkill` = 4 WHERE `poolid` = 5984;
