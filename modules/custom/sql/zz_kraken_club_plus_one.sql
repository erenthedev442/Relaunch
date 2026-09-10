-- ============================================================================
-- zz_kraken_club_plus_one.sql
--
-- Kraken Club +1 (19972) -- unused retail hole after Epeo/Idris 19968-19971.
-- Client DAT clones 17440 and paints a white box + "+1" on the icon
-- (Custom DATs/Legendary-Relic-Weapon-DATs).
--
-- Same toy as the NQ (8-hit, Delay 264, low damage) but iLvl 119 / All Jobs
-- so the swings connect. ACC / Store TP / Subtle Blow only -- no DA/TA/WSD.
-- Rare, inscribable, no AH. Serials use the same LEG#### table as the NQ.
--
-- Obtain path is not in this file. Do not add a drop.
-- Idempotent. Restart xi_map after apply (item tables are cached at boot).
-- ============================================================================

-- CANEQUIP|INSCRIBABLE|NOAUCTION|RARE = 2048+32+64+32768 = 34912
DELETE FROM `item_basic` WHERE `itemid` = 19972;
INSERT INTO `item_basic`
    (`itemid`, `subid`, `name`, `sortname`, `name_jp`, `type`, `stackSize`, `flags`, `aH`, `BaseSell`)
VALUES
    (19972, 0, 'kraken_club_+1', 'kraken_club_+1', 'クラーケンクラブ+1', 7, 1, 34912, 0, 0);

DELETE FROM `item_weapon` WHERE `itemId` = 19972;
INSERT INTO `item_weapon`
    (`itemId`, `name`, `skill`, `subskill`, `ilvl_skill`, `ilvl_parry`, `ilvl_macc`, `dmgType`, `hit`, `delay`, `dmg`, `unlock_points`)
VALUES
    (19972, 'kraken_club_+1', 11, 0, 269, 269, 228, 3, 8, 264, 16, 0);

-- jobs 4194303 = All Jobs. MId 110 matches NQ so the 3D club is unchanged.
DELETE FROM `item_equipment` WHERE `itemId` = 19972;
INSERT INTO `item_equipment`
    (`itemId`, `name`, `level`, `ilevel`, `jobs`, `MId`, `shieldSize`, `scriptType`, `slot`, `rslot`, `rslotlook`, `su_level`)
VALUES
    (19972, 'kraken_club_+1', 99, 119, 4194303, 110, 0, 0, 3, 0, 0, 0);

DELETE FROM `item_mods` WHERE `itemId` = 19972;
INSERT INTO `item_mods` (`itemId`, `modId`, `value`) VALUES
    (19972,  25, 25),  -- ACC
    (19972,  73,  4),  -- STORETP
    (19972, 289,  5);  -- SUBTLE_BLOW

DELETE FROM `auction_house_items` WHERE `itemid` = 19972;
DELETE FROM `auction_house` WHERE `itemid` = 19972;
