-- ============================================================================
-- prime_weapons_gear.sql
--
-- Turns the grantable Prime weapons into strong endgame rewards AND wires each
-- one's ADDS_WEAPONSKILL mod to the matching Prime weapon skill (so the WS
-- becomes available the moment the weapon is equipped -- main hand for melee,
-- ranged slot for the bow/gun).
--
-- For each weapon:
--   * UPDATE item_weapon  -> boost base DMG + set the iLvl skill bonuses
--     (the prime_* weapons shipped with ilvl_skill/parry/macc = 0).
--   * DELETE + re-INSERT item_mods -> a clean strong stat package PLUS the
--     ADDS_WEAPONSKILL (355 -> weapon-skill id) link.
--
-- Mod ids: STR 8, DEX 9, VIT 10, AGI 11, INT 12, MND 13, ATT 23, RATT 24,
--          ACC 25, RACC 26, MATT 28, MACC 30, STORE_TP 73, DOUBLE_ATTACK 288,
--          MAGIC_DAMAGE 311, RAPID_SHOT 359, ADDS_WEAPONSKILL 355.
--
-- Weapon -> skill -> granted WS:
--   21531 Prime Fists     (H2H)         -> 230 Dragon Blow
--   21534 Varga Purnikawa (H2H)         -> 231 Maru Kala
--   21589 Mpu Gandring    (Dagger)      -> 232 Merciless Strike
--   21621 Naegling        (Sword)       -> 229 Fast Blade II
--   21642 Prime Sword     (Sword)       -> 233 Imperator
--   21999 Prime Maul      (Club)        -> 234 Dagda
--   22102 Prime Staff     (Staff)       -> 235 Oshala
--   21781 Prime Great Axe (Great Axe)   -> 94  Disaster
--   21833 Prime Scythe    (Scythe)      -> 110 Origin
--   21887 Prime Lance     (Polearm)     -> 126 Diarmuid
--   22155 Prime Bow       (Archery)     -> 204 Sarv      (needs arrows to WS)
--   22159 Prime Gun       (Marksmanship)-> 222 Terminus  (needs bullets to WS)
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
UPDATE `item_weapon` SET `dmg` = 340, `ilvl_skill` = 269, `ilvl_parry` = 269, `ilvl_macc` = 269 WHERE `itemId` = 21781; -- Prime Great Axe
UPDATE `item_weapon` SET `dmg` = 350, `ilvl_skill` = 269, `ilvl_parry` = 269, `ilvl_macc` = 269 WHERE `itemId` = 21833; -- Prime Scythe
UPDATE `item_weapon` SET `dmg` = 340, `ilvl_skill` = 269, `ilvl_parry` = 269, `ilvl_macc` = 269 WHERE `itemId` = 21887; -- Prime Lance
UPDATE `item_weapon` SET `dmg` = 290, `ilvl_skill` = 269, `ilvl_parry` = 269, `ilvl_macc` = 269 WHERE `itemId` = 22155; -- Prime Bow
UPDATE `item_weapon` SET `dmg` = 160, `ilvl_skill` = 269, `ilvl_parry` = 269, `ilvl_macc` = 269 WHERE `itemId` = 22159; -- Prime Gun

-- ----- stat packages + ADDS_WEAPONSKILL ------------------------------------
DELETE FROM `item_mods` WHERE `itemId` IN (21531, 21534, 21589, 21621, 21642, 21999, 22102, 21781, 21833, 21887, 22155, 22159);

INSERT INTO `item_mods` (`itemId`, `modId`, `value`) VALUES
    -- 21531 Prime Fists (H2H) -> Dragon Blow
    (21531,   8, 40), (21531,   9, 40), (21531,  25, 60), (21531,  23, 60), (21531,  73, 10), (21531, 288, 10), (21531, 355, 230),
    -- 21534 Varga Purnikawa (H2H) -> Maru Kala
    (21534,   8, 40), (21534,   9, 40), (21534,  25, 60), (21534,  23, 60), (21534,  73, 10), (21534, 288, 10), (21534, 355, 231),
    -- 21589 Mpu Gandring (Dagger) -> Merciless Strike  (DEX/AGI)
    (21589,   9, 40), (21589,  11, 40), (21589,  25, 60), (21589,  23, 50), (21589,  73, 10), (21589, 288, 10), (21589, 355, 232),
    -- 21621 Naegling (Sword) -> Savage Blade + Savage Blade DMG+15% (retail)
    (21621,   8,  40), (21621,   9,  40), (21621,  12,  15), (21621,  13,  15), -- STR/DEX/INT/MND
    (21621,  23,  60), (21621,  25,  60), (21621,  28,  16), (21621,  30,  40), -- Att/Acc/MAtt/MAcc
    (21621,  73,  10), (21621, 288,  10), (21621, 311, 217),                    -- StoreTP/DA/MagicDmg
    (21621, 355,  42), (21621, 612,  15),                                       -- Savage Blade WS + DMG+15%
    -- 21642 Prime Sword (Sword) -> Imperator  (DEX/MND)
    (21642,   8, 40), (21642,   9, 40), (21642,  13, 30), (21642,  25, 60), (21642,  23, 60), (21642,  73, 10), (21642, 288, 10), (21642, 355, 233),
    -- 21999 Prime Maul (Club) -> Dagda  (STR/MND)
    (21999,   8, 40), (21999,  13, 40), (21999,  25, 60), (21999,  23, 60), (21999,  73, 10), (21999, 288, 10), (21999, 355, 234),
    -- 22102 Prime Staff (Staff) -> Oshala  (MND/INT; also a caster staff)
    (22102,  12, 40), (22102,  13, 40), (22102,  30, 60), (22102,  28, 40), (22102, 311, 200), (22102,  25, 50), (22102,  23, 50), (22102, 355, 235),
    -- 21781 Prime Great Axe -> Disaster  (STR/VIT)
    (21781,   8, 40), (21781,  10, 30), (21781,  25, 60), (21781,  23, 60), (21781,  73, 10), (21781, 288, 10), (21781, 355, 94),
    -- 21833 Prime Scythe -> Origin  (STR/INT)
    (21833,   8, 40), (21833,  12, 30), (21833,  25, 60), (21833,  23, 60), (21833,  73, 10), (21833, 288, 10), (21833, 355, 110),
    -- 21887 Prime Lance -> Diarmuid  (STR/VIT)
    (21887,   8, 40), (21887,  10, 30), (21887,  25, 60), (21887,  23, 60), (21887,  73, 10), (21887, 288, 10), (21887, 355, 126),
    -- 22155 Prime Bow -> Sarv  (ranged: AGI/STR, Ranged Acc/Att, Rapid Shot)
    (22155,  11, 40), (22155,   8, 30), (22155,  26, 60), (22155,  24, 60), (22155,  73, 10), (22155, 359, 10), (22155, 355, 204),
    -- 22159 Prime Gun -> Terminus  (ranged: AGI/DEX, Ranged Acc/Att, Rapid Shot)
    (22159,  11, 40), (22159,   9, 30), (22159,  26, 60), (22159,  24, 60), (22159,  73, 10), (22159, 359, 10), (22159, 355, 222);
