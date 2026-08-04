-- ============================================================================
-- trust_combat_round2_fix.sql
--
-- Round-2 trust combat hotfixes (post audit):
--   1) Ark Angels / Babban / Tenzen II — custom MS → player WS (real WSD path)
--   2) Naja — Black Halo last for HIGHEST opener
--   3) Pool cmbSkill: Club / Archery / Marksmanship / H2H / Axe / GK / Sword
--   4) Teodor — add single-target T4/T5 nukes
--
-- Also requires map rebuild (gambits_container SC-fallback) + Lua reload
-- (catalog Mumor II nuker, MID_RANGE kits, AI scripts).
--
-- Safe to re-apply. Map restart required.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Skill lists → player WS
-- ---------------------------------------------------------------------------
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1027;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Naja_Salaheem',1027,166);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Naja_Salaheem',1027,168);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Naja_Salaheem',1027,3215);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Naja_Salaheem',1027,169);

-- Babban: keep plantoid MS (Wild Oats / Head Butt / Photosynthesis / Petal Pirouette)
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1073;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Babban',1073,3351);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Babban',1073,3354);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Babban',1073,3352);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Babban',1073,3353);

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1107;
-- Captured AAHM Trust animation IDs (retail set).
INSERT INTO `mob_skill_lists` VALUES ('TRUST_AAHM',1107,3706);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_AAHM',1107,3708);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_AAHM',1107,3709);

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1108;
-- Captured AAEV Trust animation IDs; unique AoEs now have working Lua damage.
INSERT INTO `mob_skill_lists` VALUES ('TRUST_AAEV',1108,3710);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_AAEV',1108,3711);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_AAEV',1108,3712);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_AAEV',1108,3713);

-- AAMR: Trust-unique axe / Havoc Spiral anims (do not remap to player WS 69-77)
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1109;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_AAMR',1109,3715);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_AAMR',1109,3716);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_AAMR',1109,3717);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_AAMR',1109,3718);

-- AATT nuker: strip underpowered MS (magic only)
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1110;

-- AAGK: Trust-unique GK / Dragonfall anims (do not remap to player WS 150-157)
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1111;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_AAGK',1111,3722);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_AAGK',1111,3723);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_AAGK',1111,3724);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_AAGK',1111,3725);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_AAGK',1111,3726);

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1123;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Naja_Salaheem_UC',1123,166);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Naja_Salaheem_UC',1123,168);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Naja_Salaheem_UC',1123,3215);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Naja_Salaheem_UC',1123,169);

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1129;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Tenzen_II',1129,196);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Tenzen_II',1129,198);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Tenzen_II',1129,199);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Tenzen_II',1129,201);

-- ---------------------------------------------------------------------------
-- Pool combat skill / delay (ranged need real SLOT_RANGED)
-- ---------------------------------------------------------------------------
UPDATE `mob_pools` SET `cmbSkill` = 11 WHERE `poolid` = 5912; -- Naja Club
UPDATE `mob_pools` SET `cmbSkill` = 26, `cmbDelay` = 600, `cmbDmgMult` = 200 WHERE `poolid` = 5941; -- Elivira Marksmanship
UPDATE `mob_pools` SET `cmbSkill` = 25, `cmbDelay` = 500, `cmbDmgMult` = 200 WHERE `poolid` = 5957; -- Flaviria Archery
UPDATE `mob_pools` SET `cmbSkill` = 1 WHERE `poolid` = 5958; -- Babban H2H
UPDATE `mob_pools` SET `cmbSkill` = 25, `cmbDelay` = 500, `cmbDmgMult` = 200 WHERE `poolid` = 5962; -- Margret Archery
UPDATE `mob_pools` SET `cmbSkill` = 25, `cmbDelay` = 500, `cmbDmgMult` = 200 WHERE `poolid` = 5988; -- Makki Archery (idempotent)
UPDATE `mob_pools` SET `cmbSkill` = 3 WHERE `poolid` = 5992; -- AA HM Sword
UPDATE `mob_pools` SET `cmbSkill` = 5 WHERE `poolid` = 5994; -- AA MR Axe
UPDATE `mob_pools` SET `cmbSkill` = 10 WHERE `poolid` = 5996; -- AA GK Great Katana
UPDATE `mob_pools` SET `cmbSkill` = 25, `cmbDelay` = 500, `cmbDmgMult` = 200 WHERE `poolid` = 6014; -- Tenzen II Archery (+dmgMult)

-- ---------------------------------------------------------------------------
-- Teodor single-target nukes
-- ---------------------------------------------------------------------------
DELETE FROM `mob_spell_lists` WHERE `spell_list_id` = 399 AND `spell_id` IN (147,148,152,153,157,158,162,163,167,168,172,173);
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Teodor',399,147,73,255);
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Teodor',399,148,86,255);
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Teodor',399,152,74,255);
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Teodor',399,153,89,255);
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Teodor',399,157,72,255);
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Teodor',399,158,83,255);
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Teodor',399,162,68,255);
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Teodor',399,163,77,255);
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Teodor',399,167,75,255);
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Teodor',399,168,92,255);
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Teodor',399,172,70,255);
INSERT INTO `mob_spell_lists` VALUES ('TRUST_Teodor',399,173,80,255);
