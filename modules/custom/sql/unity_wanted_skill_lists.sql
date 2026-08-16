-- ============================================================================
-- unity_wanted_skill_lists.sql
-- Solo-friendly Unity Wanted TP lists. Family skill lists stay untouched;
-- Unity dynamic spawns pin these IDs via insertDynamicEntity skillList=.
--
-- Stripped (not solo-friendly):
--   Muut              Danse Macabre (533) charm
--   Hidhaegg          Absolute Terror (957)
--   Shedu             Dreadstorm (2025) terror; Unity-only reduced Fulmination
--                     and 10-second Fossilizing Breath petrify remain enabled
--   Tumult Curator    Thundris Shriek (2119) terror
--   Grand Grenade     Self-Destruct (509) HP-scaled wipe + suicide
--   Bambrox           Bomb Toss Suicide (592)
--   Vidmapire         Eternal Damnation (2111) doom  (+ empty pool list 284 fixed)
--
-- REQUIRES MAP RESTART: mob_skill_lists is cached at map-server boot.
-- ============================================================================

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` BETWEEN 9700 AND 9708;

-- 9700 Muut (Corse 74 without Danse Macabre)
REPLACE INTO `mob_skill_lists` VALUES ('UW_Muut', 9700, 530); -- memento_mori
REPLACE INTO `mob_skill_lists` VALUES ('UW_Muut', 9700, 531); -- silence_seal
REPLACE INTO `mob_skill_lists` VALUES ('UW_Muut', 9700, 532); -- envoutement

-- 9701 Hidhaegg (NidhoggWyrm 263 without Absolute Terror)
REPLACE INTO `mob_skill_lists` VALUES ('UW_Hidhaegg', 9701, 1039); -- hurricane_wing
REPLACE INTO `mob_skill_lists` VALUES ('UW_Hidhaegg', 9701, 1040); -- spike_flail
REPLACE INTO `mob_skill_lists` VALUES ('UW_Hidhaegg', 9701, 1041); -- dragon_breath
REPLACE INTO `mob_skill_lists` VALUES ('UW_Hidhaegg', 9701, 1046); -- horrid_roar_2

-- 9702 Shedu (Khimaira 168 without Dreadstorm)
REPLACE INTO `mob_skill_lists` VALUES ('UW_Shedu', 9702, 2022); -- tenebrous_mist
REPLACE INTO `mob_skill_lists` VALUES ('UW_Shedu', 9702, 2023); -- thunderstrike
REPLACE INTO `mob_skill_lists` VALUES ('UW_Shedu', 9702, 2024); -- tourbillion
REPLACE INTO `mob_skill_lists` VALUES ('UW_Shedu', 9702, 2026); -- fossilizing_breath
REPLACE INTO `mob_skill_lists` VALUES ('UW_Shedu', 9702, 2027); -- plague_swipe

-- 9708 Shedu execute window (adds Fulmination at <=37% HP)
REPLACE INTO `mob_skill_lists` VALUES ('UW_Shedu_LowHP', 9708, 2022); -- tenebrous_mist
REPLACE INTO `mob_skill_lists` VALUES ('UW_Shedu_LowHP', 9708, 2023); -- thunderstrike
REPLACE INTO `mob_skill_lists` VALUES ('UW_Shedu_LowHP', 9708, 2024); -- tourbillion
REPLACE INTO `mob_skill_lists` VALUES ('UW_Shedu_LowHP', 9708, 2026); -- fossilizing_breath
REPLACE INTO `mob_skill_lists` VALUES ('UW_Shedu_LowHP', 9708, 2027); -- plague_swipe
REPLACE INTO `mob_skill_lists` VALUES ('UW_Shedu_LowHP', 9708, 2028); -- fulmination

-- 9703 Tumult Curator (Pandemonium 316 without Thundris Shriek)
REPLACE INTO `mob_skill_lists` VALUES ('UW_Tumult_Curator', 9703, 2113); -- hellsnap
REPLACE INTO `mob_skill_lists` VALUES ('UW_Tumult_Curator', 9703, 2114); -- hellclap
REPLACE INTO `mob_skill_lists` VALUES ('UW_Tumult_Curator', 9703, 2115); -- cackle
REPLACE INTO `mob_skill_lists` VALUES ('UW_Tumult_Curator', 9703, 2116); -- necrobane
REPLACE INTO `mob_skill_lists` VALUES ('UW_Tumult_Curator', 9703, 2117); -- necropurge
REPLACE INTO `mob_skill_lists` VALUES ('UW_Tumult_Curator', 9703, 2118); -- bilgestorm

-- 9704 Grand Grenade (Bomb 56 without Self-Destruct)
REPLACE INTO `mob_skill_lists` VALUES ('UW_Grand_Grenade', 9704, 510); -- berserk

-- 9705 Wyvernhunter Bambrox (Goblin 133 without Bomb Toss Suicide)
REPLACE INTO `mob_skill_lists` VALUES ('UW_Bambrox', 9705, 590); -- goblin_rush
REPLACE INTO `mob_skill_lists` VALUES ('UW_Bambrox', 9705, 591); -- bomb_toss

-- 9706 Vidmapire (Vampyr kit without Eternal Damnation / Nocturnal Servitude)
-- Pool skill_list_id 284 is empty in LSB; this also restores a usable TP kit.
REPLACE INTO `mob_skill_lists` VALUES ('UW_Vidmapire', 9706, 2106); -- bloodrake
REPLACE INTO `mob_skill_lists` VALUES ('UW_Vidmapire', 9706, 2107); -- decollation
REPLACE INTO `mob_skill_lists` VALUES ('UW_Vidmapire', 9706, 2108); -- nosferatus_kiss
REPLACE INTO `mob_skill_lists` VALUES ('UW_Vidmapire', 9706, 2109); -- heliovoid
REPLACE INTO `mob_skill_lists` VALUES ('UW_Vidmapire', 9706, 2110); -- wings_of_gehenna
