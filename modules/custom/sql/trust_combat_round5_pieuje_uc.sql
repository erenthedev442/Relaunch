-- Pieuje UC: WHM/PLD A-tier stationary club healer.
-- WS driven from Lua (prefer Nott). Document kit on list 1068; pool skill_list_id = 0.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1068;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Pieuje_UC',1068,163),  -- Starlight (5)
('TRUST_Pieuje_UC',1068,164),  -- Moonlight (25)
('TRUST_Pieuje_UC',1068,3502); -- Nott (50)

-- Affirm MP-recovery club WS anims / targeting.
UPDATE `mob_skills` SET
    `mob_anim_id` = 79,
    `mob_skill_name` = 'starlight',
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 1
WHERE `mob_skill_id` = 163;

UPDATE `mob_skills` SET
    `mob_anim_id` = 80,
    `mob_skill_name` = 'moonlight',
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 1
WHERE `mob_skill_id` = 164;

UPDATE `mob_skills` SET
    `mob_anim_id` = 89,
    `mob_skill_name` = 'nott',
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 1
WHERE `mob_skill_id` = 3502;

-- Spell list 365: retail kit (drop Regen; add single-target Protect/Shell).
DELETE FROM `mob_spell_lists` WHERE `spell_list_name` = 'TRUST_Pieuje_UC' OR `spell_list_id` = 365;

INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,1,1,255);    -- cure
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,2,11,255);   -- cure_ii
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,3,21,255);   -- cure_iii
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,4,41,255);   -- cure_iv
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,5,61,255);   -- cure_v
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,6,80,255);   -- cure_vi
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,14,6,255);   -- poisona
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,15,9,255);   -- paralyna
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,16,14,255);  -- blindna
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,17,19,255);  -- silena
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,18,39,255);  -- stona
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,19,34,255);  -- viruna
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,20,29,255);  -- cursna
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,43,7,255);   -- protect
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,44,27,255);  -- protect_ii
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,45,47,255);  -- protect_iii
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,46,63,255);  -- protect_iv
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,47,76,255);  -- protect_v
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,48,17,255);  -- shell
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,49,37,255);  -- shell_ii
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,50,57,255);  -- shell_iii
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,51,68,255);  -- shell_iv
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,52,76,255);  -- shell_v
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,57,40,255);  -- haste
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,95,61,255);  -- esuna
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,96,55,255);  -- auspice
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,112,45,255); -- flash (PLD sub / wiki)
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,125,7,255);  -- protectra
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,126,27,255); -- protectra_ii
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,127,47,255); -- protectra_iii
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,128,63,255); -- protectra_iv
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,129,75,255); -- protectra_v
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,130,17,255); -- shellra
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,131,37,255); -- shellra_ii
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,132,57,255); -- shellra_iii
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,133,68,255); -- shellra_iv
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,134,75,255); -- shellra_v
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Pieuje_UC',365,143,32,255); -- erase

UPDATE `mob_pools` SET
    `mJob` = 3,
    `sJob` = 7,
    `cmbSkill` = 11,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `skill_list_id` = 0,
    `spellList` = 365
WHERE `poolid` = 5953;
