-- ============================================================================
-- prime_weapons_gear.sql
--
-- Turns the 7 grantable Prime weapons into strong endgame rewards AND wires
-- each one's ADDS_WEAPONSKILL mod to the matching Prime weapon skill (so the
-- WS becomes available the moment the weapon is equipped).
--
-- For each weapon:
--   * UPDATE item_weapon  -> boost base DMG + set the iLvl skill bonuses
--     (prime_sword/maul/staff shipped with ilvl_skill/parry/macc = 0).
--   * DELETE + re-INSERT item_mods -> a clean strong stat package PLUS the
--     ADDS_WEAPONSKILL (355 -> weapon-skill id) link.
--
-- Mod ids: STR 8, DEX 9, VIT 10, AGI 11, INT 12, MND 13, ATT 23, ACC 25,
--          MATT 28, MACC 30, STORE_TP 73, DOUBLE_ATTACK 288,
--          MAGIC_DAMAGE 311, ADDS_WEAPONSKILL 355.
--
-- Weapon -> skill -> granted WS:
--   21531 Prime Fists   (H2H)    -> 230 Dragon Blow
--   21534 Varga Purnikawa (H2H)  -> 231 Maru Kala
--   21589 Mpu Gandring  (Dagger) -> 232 Merciless Strike
--   21621 Naegling      (Sword)  -> 229 Fast Blade II
--   21642 Prime Sword   (Sword)  -> 233 Imperator
--   21999 Prime Maul    (Club)   -> 234 Dagda
--   22102 Prime Staff   (Staff)  -> 235 Oshala
--
-- Apply, then restart the map (engine caches item_weapon/item_mods at startup).
-- Idempotent. DMG values are intentionally strong -- tune here if needed.
-- ============================================================================

-- ----- base damage + iLvl skill --------------------------------------------
UPDATE `item_weapon` SET `dmg` = 240, `ilvl_skill` = 269, `ilvl_parry` = 269, `ilvl_macc` = 269 WHERE `itemId` = 21531; -- Prime Fists
UPDATE `item_weapon` SET `dmg` = 240, `ilvl_skill` = 269, `ilvl_parry` = 269, `ilvl_macc` = 269 WHERE `itemId` = 21534; -- Varga Purnikawa
UPDATE `item_weapon` SET `dmg` = 195, `ilvl_skill` = 269, `ilvl_parry` = 269, `ilvl_macc` = 269 WHERE `itemId` = 21589; -- Mpu Gandring
UPDATE `item_weapon` SET `dmg` = 245, `ilvl_skill` = 269, `ilvl_parry` = 269, `ilvl_macc` = 269 WHERE `itemId` = 21621; -- Naegling
UPDATE `item_weapon` SET `dmg` = 245, `ilvl_skill` = 269, `ilvl_parry` = 269, `ilvl_macc` = 269 WHERE `itemId` = 21642; -- Prime Sword
UPDATE `item_weapon` SET `dmg` = 275, `ilvl_skill` = 269, `ilvl_parry` = 269, `ilvl_macc` = 269 WHERE `itemId` = 21999; -- Prime Maul
UPDATE `item_weapon` SET `dmg` = 295, `ilvl_skill` = 269, `ilvl_parry` = 269, `ilvl_macc` = 269 WHERE `itemId` = 22102; -- Prime Staff

-- ----- stat packages + ADDS_WEAPONSKILL ------------------------------------
DELETE FROM `item_mods` WHERE `itemId` IN (21531, 21534, 21589, 21621, 21642, 21999, 22102);

INSERT INTO `item_mods` (`itemId`, `modId`, `value`) VALUES
    -- 21531 Prime Fists (H2H) -> Dragon Blow
    (21531,   8, 40), (21531,   9, 40), (21531,  25, 60), (21531,  23, 60), (21531,  73, 10), (21531, 288, 10), (21531, 355, 230),
    -- 21534 Varga Purnikawa (H2H) -> Maru Kala
    (21534,   8, 40), (21534,   9, 40), (21534,  25, 60), (21534,  23, 60), (21534,  73, 10), (21534, 288, 10), (21534, 355, 231),
    -- 21589 Mpu Gandring (Dagger) -> Merciless Strike  (DEX/AGI weapon skill)
    (21589,   9, 40), (21589,  11, 40), (21589,  25, 60), (21589,  23, 50), (21589,  73, 10), (21589, 288, 10), (21589, 355, 232),
    -- 21621 Naegling (Sword) -> Fast Blade II
    (21621,   8, 40), (21621,   9, 40), (21621,  25, 60), (21621,  23, 60), (21621,  73, 10), (21621, 288, 10), (21621, 355, 229),
    -- 21642 Prime Sword (Sword) -> Imperator  (DEX/MND weapon skill)
    (21642,   8, 40), (21642,   9, 40), (21642,  13, 30), (21642,  25, 60), (21642,  23, 60), (21642,  73, 10), (21642, 288, 10), (21642, 355, 233),
    -- 21999 Prime Maul (Club) -> Dagda  (STR/MND weapon skill)
    (21999,   8, 40), (21999,  13, 40), (21999,  25, 60), (21999,  23, 60), (21999,  73, 10), (21999, 288, 10), (21999, 355, 234),
    -- 22102 Prime Staff (Staff) -> Oshala  (MND/INT weapon skill; also a caster staff)
    (22102,  12, 40), (22102,  13, 40), (22102,  30, 60), (22102,  28, 40), (22102, 311, 200), (22102,  25, 50), (22102,  23, 50), (22102, 355, 235);
