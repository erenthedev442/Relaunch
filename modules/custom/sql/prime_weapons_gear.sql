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
    (21999,   8, 40), (21999,  13, 40), (21999,  25, 60), (21999,  23, 60), (21999,  73, 10), (21999, 288, 10),
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

-- ============================================================================
-- PRIME VENDOR weapons -- the 16 final "Level 119 III" forms sold by the Prime
-- Vendor NPC (modules/custom/lua/PrimeVendor_NPC.lua). Added 2026-06-20.
--
-- SAME custom "strong functional package" style as above. These are NOT retail
-- stat values: the real mods ship `TODO: Not implemented` in LSB and are
-- image-only on BG-Wiki, so this is an original balanced package, tunable here.
-- Extra ids used: VIT 10, CHR 14, HP 2, MP 5, MEVA 31, DEF 1; new-type WS
-- Great Sword -> 60 Resolution, Axe -> 78 Blitz. Dokoku (Katana) +
-- Kusanagi (Great Katana): uses ADDS_WEAPONSKILL -> 159 (Tachi: Mumei) since
-- Mumei is a custom Prime WS (commented out in stock weapon_skills.sql) and
-- cannot be obtained any other way; enabled by tachi_mumei_ws.sql.
-- Dokoku (Katana) is left with no ADDS_WEAPONSKILL (its native Blade: WS
-- already cover it). Duban (shield) + Loughnashade (harp) are non-WS
-- support pieces (Duban has no item_weapon row; it's a shield).
-- ============================================================================
UPDATE `item_weapon` SET `dmg` = 240, `ilvl_skill` = 269, `ilvl_parry` = 269, `ilvl_macc` = 269 WHERE `itemId` = 21535; -- Varga Purnikawa (III)
UPDATE `item_weapon` SET `dmg` = 195, `ilvl_skill` = 269, `ilvl_parry` = 269, `ilvl_macc` = 269 WHERE `itemId` = 21590; -- Mpu Gandring (III)
UPDATE `item_weapon` SET `dmg` = 245, `ilvl_skill` = 269, `ilvl_parry` = 269, `ilvl_macc` = 269 WHERE `itemId` = 21646; -- Caliburnus
UPDATE `item_weapon` SET `dmg` = 360, `ilvl_skill` = 269, `ilvl_parry` = 269, `ilvl_macc` = 269 WHERE `itemId` = 21653; -- Helheim
UPDATE `item_weapon` SET `dmg` = 250, `ilvl_skill` = 269, `ilvl_parry` = 269, `ilvl_macc` = 269 WHERE `itemId` = 21730; -- Spalirisos
UPDATE `item_weapon` SET `dmg` = 340, `ilvl_skill` = 269, `ilvl_parry` = 269, `ilvl_macc` = 269 WHERE `itemId` = 21785; -- Laphria
UPDATE `item_weapon` SET `dmg` = 350, `ilvl_skill` = 269, `ilvl_parry` = 269, `ilvl_macc` = 269 WHERE `itemId` = 21837; -- Foenaria
UPDATE `item_weapon` SET `dmg` = 340, `ilvl_skill` = 269, `ilvl_parry` = 269, `ilvl_macc` = 269 WHERE `itemId` = 21891; -- Gae Buide
UPDATE `item_weapon` SET `dmg` = 230, `ilvl_skill` = 269, `ilvl_parry` = 269, `ilvl_macc` = 269 WHERE `itemId` = 21932; -- Dokoku
UPDATE `item_weapon` SET `dmg` = 360, `ilvl_skill` = 269, `ilvl_parry` = 269, `ilvl_macc` = 269 WHERE `itemId` = 21986; -- Kusanagi
UPDATE `item_weapon` SET `dmg` = 275, `ilvl_skill` = 269, `ilvl_parry` = 269, `ilvl_macc` = 269 WHERE `itemId` = 22002; -- Lorg Mor
UPDATE `item_weapon` SET `dmg` = 295, `ilvl_skill` = 269, `ilvl_parry` = 269, `ilvl_macc` = 269 WHERE `itemId` = 22106; -- Opashoro
UPDATE `item_weapon` SET `dmg` = 290, `ilvl_skill` = 269, `ilvl_parry` = 269, `ilvl_macc` = 269 WHERE `itemId` = 22163; -- Pinaka
UPDATE `item_weapon` SET `dmg` = 160, `ilvl_skill` = 269, `ilvl_parry` = 269, `ilvl_macc` = 269 WHERE `itemId` = 22164; -- Earp

DELETE FROM `item_mods` WHERE `itemId` IN (21535, 21590, 21646, 21653, 21730, 21785, 21837, 21891, 21932, 21986, 22002, 22106, 22163, 22164, 26495, 22307);

INSERT INTO `item_mods` (`itemId`, `modId`, `value`) VALUES
    -- 21535 Varga Purnikawa (H2H) -> Maru Kala
    (21535, 8, 40), (21535, 9, 40), (21535, 25, 60), (21535, 23, 60), (21535, 73, 10), (21535, 288, 10), (21535, 355, 231),
    -- 21590 Mpu Gandring (Dagger) -> Merciless Strike
    (21590, 9, 40), (21590, 11, 40), (21590, 25, 60), (21590, 23, 50), (21590, 73, 10), (21590, 288, 10), (21590, 355, 232),
    -- 21646 Caliburnus (Sword) -> Imperator
    (21646, 8, 40), (21646, 9, 40), (21646, 25, 60), (21646, 23, 60), (21646, 73, 10), (21646, 288, 10), (21646, 355, 233),
    (21646, 160, -1000), (21646, 369, 4), -- Damage taken -10%, Refresh +4
    -- 21653 Helheim (Great Sword) -> Fimbulvetr
    (21653, 8, 40), (21653, 10, 20), (21653, 25, 60), (21653, 23, 70), (21653, 73, 10), (21653, 288, 10), (21653, 355, 62),
    -- 21730 Spalirisos (Axe) -> Blitz
    (21730, 8, 40), (21730, 9, 20), (21730, 25, 60), (21730, 23, 60), (21730, 73, 10), (21730, 288, 10), (21730, 355, 78),
    -- 21785 Laphria (Great Axe) -> Disaster
    (21785, 8, 40), (21785, 10, 30), (21785, 25, 60), (21785, 23, 70), (21785, 73, 10), (21785, 288, 10), (21785, 355, 94),
    -- 21837 Foenaria (Scythe) -> Origin
    (21837, 8, 40), (21837, 12, 30), (21837, 25, 60), (21837, 23, 70), (21837, 73, 10), (21837, 288, 10), (21837, 355, 110),
    -- 21891 Gae Buide (Polearm) -> Diarmuid
    (21891, 8, 40), (21891, 10, 30), (21891, 25, 60), (21891, 23, 70), (21891, 73, 10), (21891, 288, 10), (21891, 355, 126),
    -- 21932 Dokoku (Katana) -> Zesho Meppo
    (21932, 9, 40), (21932, 11, 30), (21932, 25, 60), (21932, 23, 60), (21932, 73, 10), (21932, 288, 10), (21932, 355, 142),
    -- 21986 Kusanagi (Great Katana) -> Tachi: Mumei (159)
    (21986, 8, 40), (21986, 9, 30), (21986, 25, 60), (21986, 23, 70), (21986, 73, 10), (21986, 288, 10), (21986, 355, 159),
    -- 22002 Lorg Mor (Club) -> Dagda
    (22002, 8, 40), (22002, 13, 40), (22002, 25, 60), (22002, 23, 60), (22002, 73, 10), (22002, 288, 10), (22002, 355, 234),
    (22002, 160, -1000), (22002, 370, 7), -- Damage taken -10%, Regen +7
    -- 22106 Opashoro (Staff) -> Oshala
    (22106, 12, 40), (22106, 13, 40), (22106, 30, 60), (22106, 28, 40), (22106, 311, 200), (22106, 25, 50), (22106, 23, 50), (22106, 355, 235), (22106, 1040, 3),
    -- 22163 Pinaka (Archery) -> Sarv
    (22163, 11, 40), (22163, 8, 30), (22163, 26, 60), (22163, 24, 60), (22163, 73, 10), (22163, 359, 10), (22163, 355, 204),
    -- 22164 Earp (Marksmanship) -> Terminus
    (22164, 11, 40), (22164, 9, 30), (22164, 26, 60), (22164, 24, 60), (22164, 73, 10), (22164, 359, 10), (22164, 355, 222),
    -- 26495 Duban (Shield) -- defensive support, no WS / no item_weapon row
    (26495, 1, 150), (26495, 10, 50), (26495, 2, 300), (26495, 31, 50),
    (26495, 958, 20), (26495, 831, -2500), -- Status resistance +20, Magic damage taken II -25%
    -- 22307 Loughnashade (String/Harp) -- BRD song support, no WS
    (22307, 14, 40), (22307, 30, 50), (22307, 5, 100), (22307, 2, 100), (22307, 452, 4);

-- ============================================================================
-- AFTERMATH (mod 256) -- folded in here 2026-06-22 so it can NEVER desync from
-- the DELETE blocks above again. Those DELETE+re-INSERTs drop mod 256; the
-- standalone prime_weapons_zz_aftermath_fix.sql only restored it via the custom-
-- sql CHANGE-LEDGER, so a deploy that re-ran THIS file (but skipped the unchanged
-- fix file) wiped aftermath off every Prime/Aeonic weapon ("no aftermath on
-- Caliburnus after the rebuild"; live: 21642/21646/21837 had 355 but no 256).
-- Keeping the re-insert in the SAME file makes wipe + restore atomic.
-- Aftermath value: 46 = physical, 47 = club (Dagda), 48 = staff (Oshala).
-- Also (re)grants Origin (355=110) to Foenaria upgrade stages 21834-21836.
-- ============================================================================
-- Earlier variants must not retain native Prime WS/aftermath rows from an
-- older deployment. Only the completed forms below receive the pinnacle path.
DELETE FROM `item_mods`
WHERE `itemId` IN (21649, 21650, 21651, 21652, 21930, 21931, 21998, 21999, 22000, 22001)
  AND `modId` IN (256, 355);

INSERT INTO `item_mods` (`itemId`, `modId`, `value`) VALUES
    (21834, 355, 110), (21835, 355, 110), (21836, 355, 110),                       -- Foenaria stages -> Origin WS
    (21833, 256, 46), (21834, 256, 46), (21835, 256, 46), (21836, 256, 46), (21837, 256, 46), -- Scythe / Foenaria
    (21531, 256, 46), (21534, 256, 46), (21535, 256, 46),                         -- Fists / Varga Purnikawa
    (21586, 256, 46), (21589, 256, 46), (21590, 256, 46),                         -- Dagger / Mpu Gandring
    (21642, 256, 46), (21646, 256, 46),                                            -- Prime Sword / Caliburnus (Imperator)
    (21653, 256, 46),                                                               -- Helheim / Fimbulvetr
    (21726, 256, 46), (21730, 256, 46),                                            -- Prime Pickaxe / Spalirisos
    (21781, 256, 46), (21785, 256, 46),                                            -- Prime Great Axe / Laphria (Disaster)
    (21887, 256, 46), (21891, 256, 46),                                            -- Prime Lance / Gae Buide (Diarmuid)
    (21932, 256, 46),                                                               -- Dokoku / Zesho Meppo
    (21986, 256, 46),                                                               -- Kusanagi (Tachi: Mumei)
    (22155, 256, 46), (22163, 256, 46),                                            -- Prime Bow / Pinaka (Sarv)
    (22159, 256, 46), (22164, 256, 46),                                            -- Prime Gun / Earp (Terminus)
    (22002, 256, 47),                                                               -- Lorg Mor / Dagda
    (22102, 256, 48), (22106, 256, 48)                                             -- Prime Staff / Opashoro (staff)
ON DUPLICATE KEY UPDATE `value` = VALUES(`value`);
