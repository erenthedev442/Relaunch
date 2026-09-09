-- ---------------------------------------------------------------------------
-- zzzz_jse_ja_enhancements.sql
--
-- AF / Relic / Empyrean pieces that enhance a job ability while that ability
-- is active. These are STATUS_EFFECT_ACTIVE latents (latentId 13), not flat
-- item_mods -- swapping the piece on or off mid-ability must apply/remove
-- the bonus.
--
-- Why this file exists:
--   * gen_naked_item_stats.py ignores "Enhances" / "Hasso:" / "Seigan:" text,
--     so +3 JSE shipped with displayed stats only.
--   * A few +2 latents were never copied to +3 (Kasuga Haidate Hasso, Fallen's
--     Last Resort, Kasuga Kabuto Seigan, Hattori Innin/Yonin, Maculele
--     Climactic, Arbatel Addendum).
--   * Kasuga Haidate +2 stored Hasso haste as HASTE_GEAR. Retail is Job
--     Ability haste, same pool as Hasso itself (TWOHAND_HASTE_ABILITY).
--   * zzz_reforge_carryforward copied always-on COUNTER / DOUBLE_ATTACK onto
--     Kasuga Kabuto +3 / Hattori Zukin +3 / Hattori Hakama +3. Those bonuses
--     are Seigan / Innin / Yonin only. This file loads after that one
--     (zzzz_ > zzz_) and removes the flat mods.
--
-- Haste values are in 1/1000ths (1000 = 10%), matching scripts/effects/hasso.lua.
-- BG-Wiki Hasso / Seigan / Innin / Yonin / Climactic Flourish / Last Resort /
-- Berserk equipment tables (2026-09-09).
-- ---------------------------------------------------------------------------

-- Carryforward always-on copies of JA-only bonuses.
DELETE FROM `item_mods` WHERE `itemId` = 23431 AND `modId` = 291; -- kasuga_kabuto_+3 flat COUNTER
DELETE FROM `item_mods` WHERE `itemId` = 23432 AND `modId` = 288; -- hattori_zukin_+3 flat DOUBLE_ATTACK
DELETE FROM `item_mods` WHERE `itemId` = 23633 AND `modId` = 291; -- hattori_hakama_+3 flat COUNTER

-- Wrong haste pool on Relic +2 legs (gear haste instead of JA haste).
DELETE FROM `item_latents`
 WHERE `itemId` = 23297 AND `modId` = 384 AND `latentId` = 13 AND `latentParam` = 353;

LOCK TABLES `item_latents` WRITE;

-- ============================ SAM: Hasso ============================
-- Extra Job Ability haste while Hasso (353) is up. 2H only, same as the JA.
-- Empyrean hands (Wakido Kote) + Relic legs (Kasuga / Unkai Haidate) stack.

INSERT IGNORE INTO `item_latents` VALUES (11235,217,150,13,353);  -- unkai_haidate_+1: Hasso JA haste +1.5%
INSERT IGNORE INTO `item_latents` VALUES (11135,217,250,13,353);  -- unkai_haidate_+2: Hasso JA haste +2.5%
INSERT IGNORE INTO `item_latents` VALUES (27259,217,250,13,353);  -- kasuga_haidate: Hasso JA haste +2.5%
INSERT IGNORE INTO `item_latents` VALUES (27260,217,300,13,353);  -- kasuga_haidate_+1: Hasso JA haste +3%
INSERT IGNORE INTO `item_latents` VALUES (23297,217,300,13,353);  -- kasuga_haidate_+2: Hasso JA haste +3%
INSERT IGNORE INTO `item_latents` VALUES (23632,217,300,13,353);  -- kasuga_haidate_+3: Hasso JA haste +3%

INSERT IGNORE INTO `item_latents` VALUES (27954,217,100,13,353);  -- wakido_kote: Hasso JA haste +1%
INSERT IGNORE INTO `item_latents` VALUES (27975,217,200,13,353);  -- wakido_kote_+1: Hasso JA haste +2%
INSERT IGNORE INTO `item_latents` VALUES (23185,217,300,13,353);  -- wakido_kote_+2: Hasso JA haste +3%
INSERT IGNORE INTO `item_latents` VALUES (23520,217,400,13,353);  -- wakido_kote_+3: Hasso JA haste +4%

INSERT IGNORE INTO `item_latents` VALUES (23319,217,100,13,353);  -- wakido_sune-ate_+2: Hasso +1 (~1% JA haste)
INSERT IGNORE INTO `item_latents` VALUES (23654,217,200,13,353);  -- wakido_sune-ate_+3: Hasso +2 (~2% JA haste)

-- ============================ SAM: Seigan ============================
-- Counter rate with Seigan (354) up and no Third Eye.

INSERT IGNORE INTO `item_latents` VALUES (11175,291,3,13,354);    -- unkai_kabuto_+1: Seigan Counter +~2.5%
INSERT IGNORE INTO `item_latents` VALUES (11075,291,5,13,354);    -- unkai_kabuto_+2: Seigan Counter +5%
INSERT IGNORE INTO `item_latents` VALUES (26762,291,12,13,354);   -- kasuga_kabuto: Seigan Counter +12%
INSERT IGNORE INTO `item_latents` VALUES (26763,291,14,13,354);   -- kasuga_kabuto_+1: Seigan Counter +14%
-- 23096 kasuga_kabuto_+2 already in item_latents.sql (Counter +16)
INSERT IGNORE INTO `item_latents` VALUES (23431,291,18,13,354);   -- kasuga_kabuto_+3: Seigan Counter +18%

-- ============================ NIN: Innin ============================
-- Double Attack while Innin (421) is up.

INSERT IGNORE INTO `item_latents` VALUES (11176,288,3,13,421);    -- iga_zukin_+1: Innin DA +3%
INSERT IGNORE INTO `item_latents` VALUES (11076,288,5,13,421);    -- iga_zukin_+2: Innin DA +5%
INSERT IGNORE INTO `item_latents` VALUES (26764,288,7,13,421);    -- hattori_zukin: Innin DA +7%
INSERT IGNORE INTO `item_latents` VALUES (26765,288,9,13,421);    -- hattori_zukin_+1: Innin DA +9%
-- 23097 hattori_zukin_+2 already in item_latents.sql (DA +11)
INSERT IGNORE INTO `item_latents` VALUES (23432,288,13,13,421);   -- hattori_zukin_+3: Innin DA +13%

-- ============================ NIN: Yonin ============================
-- Counter while Yonin (420) is up.

INSERT IGNORE INTO `item_latents` VALUES (11236,291,8,13,420);    -- iga_hakama_+1: Yonin Counter +8%
INSERT IGNORE INTO `item_latents` VALUES (11136,291,10,13,420);   -- iga_hakama_+2: Yonin Counter +10%
INSERT IGNORE INTO `item_latents` VALUES (27261,291,12,13,420);   -- hattori_hakama: Yonin Counter +12%
INSERT IGNORE INTO `item_latents` VALUES (27262,291,14,13,420);   -- hattori_hakama_+1: Yonin Counter +14%
-- 23298 hattori_hakama_+2 already in item_latents.sql (Counter +16)
INSERT IGNORE INTO `item_latents` VALUES (23633,291,18,13,420);   -- hattori_hakama_+3: Yonin Counter +18%

-- ============================ DNC: Climactic Flourish ============================
-- 23103 maculele_tiara_+2 already in item_latents.sql (crit +1 / crit dmg +28%)

INSERT IGNORE INTO `item_latents` VALUES (23438,165,1,13,443);    -- maculele_tiara_+3: Climactic crit rate +1
INSERT IGNORE INTO `item_latents` VALUES (23438,421,31,13,443);   -- maculele_tiara_+3: Climactic crit dmg +31%

-- ============================ SCH: Addendum ============================
-- 23171 arbatel_gown_+2 already in item_latents.sql (Enmity -26)

INSERT IGNORE INTO `item_latents` VALUES (23506,27,-26,13,401);   -- arbatel_gown_+3: Addendum: White Enmity -26
INSERT IGNORE INTO `item_latents` VALUES (23506,27,-26,13,402);   -- arbatel_gown_+3: Addendum: Black Enmity -26

-- ============================ BLU: Chain Affinity ============================
-- 23100 hashishin_kavuk_+2 already in item_latents.sql (MAGIC_DAMAGE +26)

INSERT IGNORE INTO `item_latents` VALUES (23435,311,26,13,164);   -- hashishin_kavuk_+3: Chain Affinity magic damage +26

-- ============================ DRK: Last Resort ============================
-- Abyss / Fallen's feet: reduce the DEF penalty by 10% while Last Resort (64) is up.
-- NQ / +1 / +2 already in item_latents.sql.

INSERT IGNORE INTO `item_latents` VALUES (23673,63,10,13,64);     -- fallens_sollerets_+3: Last Resort DEFP +10

-- ============================ WAR: Berserk ============================
-- Lowers the DEF penalty to 15% (DEFP +10 vs the base -25%) while Berserk (56)
-- is up. Old Warrior's Calligae already have this; Agoge never did.

INSERT IGNORE INTO `item_latents` VALUES (27328,63,10,13,56);     -- agoge_calligae: Berserk DEFP +10
INSERT IGNORE INTO `item_latents` VALUES (27329,63,10,13,56);     -- agoge_calligae_+1: Berserk DEFP +10
INSERT IGNORE INTO `item_latents` VALUES (23331,63,10,13,56);     -- agoge_calligae_+2: Berserk DEFP +10
INSERT IGNORE INTO `item_latents` VALUES (23666,63,10,13,56);     -- agoge_calligae_+3: Berserk DEFP +10

UNLOCK TABLES;
