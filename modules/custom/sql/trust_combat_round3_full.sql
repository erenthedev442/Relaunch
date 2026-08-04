-- ============================================================================
-- trust_combat_round3_full.sql
--
-- Full-roster pass (after round2): remaining MS-only DD/tank/hybrid/ranged
-- trusts remapped to player WS so weaponskills.lua WSD/ratings apply.
-- Also cmbSkill fixes + strip weak lvl+2 signature MS from mixed lists.
--
-- Apply AFTER trust_combat_audit_fix.sql + trust_combat_round2_fix.sql
-- (or alone — deletes are idempotent). Map restart required.
-- C++ rebuild still required for gambits_container SC-fallback.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- MS-only → player WS
-- ---------------------------------------------------------------------------
-- Trion keeps unique Trust MS (see trust_combat_round5_trion.sql). Do not remap to player sword WS.
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1020;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Trion',1020,968);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Trion',1020,970);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Trion',1020,3193);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Trion',1020,3194);

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1022;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Lion',1022,16);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Lion',1022,23);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Lion',1022,25);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Lion',1022,31);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Lion',1022,224);

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1023;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Tenzen',1023,150);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Tenzen',1023,151);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Tenzen',1023,152);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Tenzen',1023,156);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Tenzen',1023,157);

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1028;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Prishe',1028,5);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Prishe',1028,7);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Prishe',1028,8);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Prishe',1028,9);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Prishe',1028,14);

-- Gessho keeps unique Trust MS (see trust_combat_round5_gessho.sql). Do not remap to player katana WS.
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1033;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Gessho',1033,3256);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Gessho',1033,3257);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Gessho',1033,3259);

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1037;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Lehko_Habhoka',1037,16);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Lehko_Habhoka',1037,23);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Lehko_Habhoka',1037,25);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Lehko_Habhoka',1037,31);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Lehko_Habhoka',1037,224);

-- Mnejing keeps Valoredge Trust MS (see trust_combat_round5_mnejing.sql). Do not remap to player H2H WS.
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1041;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Mnejing',1041,1940);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Mnejing',1041,1941);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Mnejing',1041,3245);

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1047;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Fablinix',1047,3261); -- Bomb Toss (AoE fire)
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Fablinix',1047,3262); -- Goblin Rush

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1048;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Maat',1048,5);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Maat',1048,7);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Maat',1048,8);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Maat',1048,9);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Maat',1048,14);

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1055;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Semih_Lafihna',1055,196);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Semih_Lafihna',1055,198);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Semih_Lafihna',1055,199);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Semih_Lafihna',1055,201);

-- Abenzio keeps Goobbue Trust MS (see trust_combat_round5_abenzio.sql). Do not remap to player H2H WS.
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1074;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Abenzio',1074,3355);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Abenzio',1074,3356);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Abenzio',1074,3357);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Abenzio',1074,3358);

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1086;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Mildaurion',1086,40);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Mildaurion',1086,41);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Mildaurion',1086,42);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Mildaurion',1086,225);

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1094;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Selh_teus',1094,40);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Selh_teus',1094,42);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Selh_teus',1094,225);

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1099;
-- August keeps unique Trust MS (see trust_combat_round5_august.sql). Do not remap to player GS WS.
INSERT INTO `mob_skill_lists` VALUES ('TRUST_August',1099,3653);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_August',1099,3654);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_August',1099,3655);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_August',1099,3656);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_August',1099,3657);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_August',1099,3658);

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1112;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Iroha',1112,150);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Iroha',1112,151);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Iroha',1112,152);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Iroha',1112,156);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Iroha',1112,157);

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1121;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Maat_UC',1121,5);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Maat_UC',1121,7);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Maat_UC',1121,8);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Maat_UC',1121,9);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Maat_UC',1121,14);

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1124;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Lion_II',1124,16);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Lion_II',1124,23);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Lion_II',1124,25);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Lion_II',1124,31);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Lion_II',1124,224);

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1126;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Prishe_II',1126,5);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Prishe_II',1126,7);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Prishe_II',1126,8);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Prishe_II',1126,9);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Prishe_II',1126,14);

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1133;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Iroha_II',1133,150);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Iroha_II',1133,151);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Iroha_II',1133,152);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Iroha_II',1133,156);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Iroha_II',1133,157);

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1040;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Ovjang',1040,165);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Ovjang',1040,168);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Ovjang',1040,169);

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1083;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Adelheid',1083,165);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Adelheid',1083,168);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Adelheid',1083,169);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Adelheid',1083,174);

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1134;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Shantotto_II',1134,165);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Shantotto_II',1134,168);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Shantotto_II',1134,169);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Shantotto_II',1134,174);

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1163;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Shantotto_II_Melee',1163,165);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Shantotto_II_Melee',1163,168);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Shantotto_II_Melee',1163,169);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Shantotto_II_Melee',1163,174);

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1197;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_August_Melee',1197,3648);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_August_Melee',1197,3649);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_August_Melee',1197,3650);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_August_Melee',1197,3651);

-- Areuhat: keep Dragon Breath / Hurricane Wing (3438/3439); skill checks allow trusts
-- DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1054 AND `mob_skill_id` IN (3438,3439);
-- Abquhbah: keep Combo / Backhand Blow / Salaheem Spirit (do not strip 3541)
-- DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1097 AND `mob_skill_id` = 3541;
-- Strip weak / missing-Lua MS from mixed lists (HIGHEST can pick and stall)
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1051 AND `mob_skill_id` IN (3336,3337); -- Karaha Howling Moon / Lunar Bay

-- Nashmeira I/II healers: sole MS → dagger WS so they still spend TP
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1038;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Nashmeira',1038,16);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Nashmeira',1038,23);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Nashmeira',1038,25);
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1127;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Nashmeira_II',1127,16);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Nashmeira_II',1127,23);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Nashmeira_II',1127,25);

-- ---------------------------------------------------------------------------
-- Pool cmbSkill (weapon type must match WS / ranged slot)
-- ---------------------------------------------------------------------------
UPDATE `mob_pools` SET `cmbSkill` = 3 WHERE `poolid` = 5905; -- Trion Sword
UPDATE `mob_pools` SET `cmbSkill` = 2 WHERE `poolid` = 5907; -- Lion Dagger
UPDATE `mob_pools` SET `cmbSkill` = 10 WHERE `poolid` = 5908; -- Tenzen GK
UPDATE `mob_pools` SET `cmbSkill` = 4 WHERE `poolid` = 5906; -- Zeid GS
UPDATE `mob_pools` SET `cmbSkill` = 11 WHERE `poolid` = 5909; -- Mihli Club
UPDATE `mob_pools` SET `cmbSkill` = 1 WHERE `poolid` = 5913; -- Prishe H2H
UPDATE `mob_pools` SET `cmbSkill` = 8 WHERE `poolid` = 5915; -- Shikaree Polearm
UPDATE `mob_pools` SET `cmbSkill` = 6 WHERE `poolid` = 5917; -- Iron Eater GA
UPDATE `mob_pools` SET `cmbSkill` = 9 WHERE `poolid` = 5918; -- Gessho Katana
UPDATE `mob_pools` SET `cmbSkill` = 2 WHERE `poolid` = 5922; -- Lehko Dagger
UPDATE `mob_pools` SET `cmbSkill` = 1 WHERE `poolid` = 5924; -- Zazarg H2H
UPDATE `mob_pools` SET `cmbSkill` = 1 WHERE `poolid` = 5926; -- Mnejing H2H
UPDATE `mob_pools` SET `cmbSkill` = 26, `cmbDelay` = 600, `cmbDmgMult` = 200 WHERE `poolid` = 5928; -- Luzaf Marksmanship
UPDATE `mob_pools` SET `cmbSkill` = 8 WHERE `poolid` = 5929; -- Najelith Polearm
UPDATE `mob_pools` SET `cmbSkill` = 2 WHERE `poolid` = 5932; -- Fablinix Dagger
UPDATE `mob_pools` SET `cmbSkill` = 1 WHERE `poolid` = 5933; -- Maat H2H
UPDATE `mob_pools` SET `cmbSkill` = 12 WHERE `poolid` = 5936; -- Karaha Staff
UPDATE `mob_pools` SET `cmbSkill` = 11 WHERE `poolid` = 5937; -- Cid Club (not GA)
UPDATE `mob_pools` SET `cmbSkill` = 10 WHERE `poolid` = 5938; -- Gilgamesh GK
UPDATE `mob_pools` SET `cmbSkill` = 25, `cmbDelay` = 500, `cmbDmgMult` = 200 WHERE `poolid` = 5940; -- Semih Archery
UPDATE `mob_pools` SET `cmbSkill` = 5 WHERE `poolid` = 5943; -- Lhu Axe
UPDATE `mob_pools` SET `cmbSkill` = 11 WHERE `poolid` = 5944; -- Ferreous Club
UPDATE `mob_pools` SET `cmbSkill` = 2 WHERE `poolid` = 5945; -- Lilisette Dagger
UPDATE `mob_pools` SET `cmbSkill` = 11 WHERE `poolid` = 5946; -- Mumor Club
UPDATE `mob_pools` SET `cmbSkill` = 11 WHERE `poolid` = 5947; -- Uka Club
UPDATE `mob_pools` SET `cmbSkill` = 6 WHERE `poolid` = 5954; -- I.Shield GA
UPDATE `mob_pools` SET `cmbSkill` = 2 WHERE `poolid` = 5956; -- Jakoh Dagger
UPDATE `mob_pools` SET `cmbSkill` = 1 WHERE `poolid` = 5959; -- Abenzio H2H
UPDATE `mob_pools` SET `cmbSkill` = 4 WHERE `poolid` = 5960; -- Rughadjeen GS
UPDATE `mob_pools` SET `cmbSkill` = 26, `cmbDelay` = 600, `cmbDmgMult` = 200 WHERE `poolid` = 5967; -- Qultada Marksmanship
UPDATE `mob_pools` SET `cmbSkill` = 4 WHERE `poolid` = 5969; -- Amchuchu GS
UPDATE `mob_pools` SET `cmbSkill` = 3 WHERE `poolid` = 5971; -- Mildaurion Sword
UPDATE `mob_pools` SET `cmbSkill` = 8 WHERE `poolid` = 5972; -- Halver Polearm
UPDATE `mob_pools` SET `cmbSkill` = 4 WHERE `poolid` = 5973; -- Rongelouts GS
UPDATE `mob_pools` SET `cmbSkill` = 2 WHERE `poolid` = 5975; -- Maximilian Dagger
UPDATE `mob_pools` SET `cmbSkill` = 3 WHERE `poolid` = 5979; -- Selh'teus Sword
UPDATE `mob_pools` SET `cmbSkill` = 1 WHERE `poolid` = 5982; -- Abquhbah H2H
UPDATE `mob_pools` SET `cmbSkill` = 4 WHERE `poolid` = 5983; -- Balamor GS
UPDATE `mob_pools` SET `cmbSkill` = 4 WHERE `poolid` = 5984; -- August GS
UPDATE `mob_pools` SET `cmbSkill` = 5 WHERE `poolid` = 5990; -- Morimar Axe
UPDATE `mob_pools` SET `cmbSkill` = 10 WHERE `poolid` = 5997; -- Iroha GK
UPDATE `mob_pools` SET `cmbSkill` = 4 WHERE `poolid` = 6004; -- Excenmille S Great Sword
UPDATE `mob_pools` SET `cmbSkill` = 10 WHERE `poolid` = 6005; -- Ayame UC GK
UPDATE `mob_pools` SET `cmbSkill` = 1 WHERE `poolid` = 6006; -- Maat UC H2H
UPDATE `mob_pools` SET `cmbSkill` = 11 WHERE `poolid` = 6008; -- Naja UC Club
UPDATE `mob_pools` SET `cmbSkill` = 2 WHERE `poolid` = 6009; -- Lion II Dagger
UPDATE `mob_pools` SET `cmbSkill` = 4 WHERE `poolid` = 6010; -- Zeid II GS
UPDATE `mob_pools` SET `cmbSkill` = 1 WHERE `poolid` = 6011; -- Prishe II H2H
UPDATE `mob_pools` SET `cmbSkill` = 2 WHERE `poolid` = 6013; -- Lilisette II Dagger
UPDATE `mob_pools` SET `cmbSkill` = 10 WHERE `poolid` = 6018; -- Iroha II GK
