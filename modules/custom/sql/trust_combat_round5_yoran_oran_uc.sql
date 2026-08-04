-- Yoran-Oran UC: WHM/BLM A-tier standback healer.
-- No AA. Nott (3502) is listener-driven — skill list stays EMPTY so the
-- engine's TP-before-gambit path cannot steal cure priority (retail Nott
-- is lowest; he may keep curing even at 3000 TP until OOM).
-- Spell kit: Cure I–VI, -na, Protectra/Shellra I–V, Erase, Stoneskin.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1095;
-- Keep empty — Nott fired via useMobAbility(3502), not auto TP skills.

-- Self-target club anim; no SC props.
UPDATE `mob_skills` SET
    `mob_anim_id` = 89,
    `mob_skill_name` = 'nott',
    `mob_skill_aoe` = 0,
    `mob_skill_aoe_radius` = 0.0,
    `mob_skill_distance` = 7.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 1,
    `primary_sc` = 0,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3502;

DELETE FROM `mob_spell_lists` WHERE `spell_list_name` = 'TRUST_Yoran-Oran_UC' OR `spell_list_id` = 393;

INSERT INTO `mob_spell_lists` VALUES ('TRUST_Yoran-Oran_UC',393,1,1,255);    -- cure
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Yoran-Oran_UC',393,2,11,255);   -- cure_ii
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Yoran-Oran_UC',393,3,21,255);   -- cure_iii
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Yoran-Oran_UC',393,4,41,255);   -- cure_iv
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Yoran-Oran_UC',393,5,61,255);   -- cure_v
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Yoran-Oran_UC',393,6,80,255);   -- cure_vi
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Yoran-Oran_UC',393,14,6,255);   -- poisona
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Yoran-Oran_UC',393,15,9,255);   -- paralyna
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Yoran-Oran_UC',393,16,14,255);  -- blindna
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Yoran-Oran_UC',393,17,19,255);  -- silena
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Yoran-Oran_UC',393,18,39,255);  -- stona
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Yoran-Oran_UC',393,19,34,255);  -- viruna
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Yoran-Oran_UC',393,20,29,255);  -- cursna
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Yoran-Oran_UC',393,54,28,255);  -- stoneskin
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Yoran-Oran_UC',393,125,7,255);  -- protectra
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Yoran-Oran_UC',393,126,27,255); -- protectra_ii
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Yoran-Oran_UC',393,127,47,255); -- protectra_iii
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Yoran-Oran_UC',393,128,63,255); -- protectra_iv
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Yoran-Oran_UC',393,129,75,255); -- protectra_v
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Yoran-Oran_UC',393,130,17,255); -- shellra
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Yoran-Oran_UC',393,131,37,255); -- shellra_ii
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Yoran-Oran_UC',393,132,57,255); -- shellra_iii
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Yoran-Oran_UC',393,133,68,255); -- shellra_iv
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Yoran-Oran_UC',393,134,75,255); -- shellra_v
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Yoran-Oran_UC',393,143,32,255); -- erase

UPDATE `mob_pools` SET
    `mJob` = 3,
    `sJob` = 4,
    `cmbSkill` = 11,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `behavior` = 2,
    `skill_list_id` = 0,
    `spellList` = 393
WHERE `poolid` = 5980;
