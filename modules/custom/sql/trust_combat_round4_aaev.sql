-- Ark Angel EV / HM retail move sets + captured Trust animation IDs.
-- Applied after round2, which previously replaced unique AA moves with player WS.

-- AAEV
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1108;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_AAEV',1108,3710), -- Arrogance Incarnate (AoE, no SC)
('TRUST_AAEV',1108,3711), -- Vorpal Blade
('TRUST_AAEV',1108,3712), -- Dominion Slash (AoE, no SC)
('TRUST_AAEV',1108,3713); -- Chant du Cygne

-- /WHM supplies traits only; retail AAEV does not cast Holy/Holy II.
DELETE FROM `mob_spell_lists`
WHERE `spell_list_id` = 406
  AND `spell_id` IN (21, 22);

-- AAHM
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1107;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_AAHM',1107,3706), -- Cross Reaver (unique conal stun)
('TRUST_AAHM',1107,3708), -- Swift Blade
('TRUST_AAHM',1107,3709); -- Chant du Cygne

-- Ensure sword combat skill for AAHM animations / WS eligibility.
UPDATE `mob_pools` SET `cmbSkill` = 3 WHERE `poolid` = 5992;
