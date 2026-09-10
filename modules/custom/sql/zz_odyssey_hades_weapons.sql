-- ============================================================================
-- zz_odyssey_hades_weapons.sql
--
-- Hades Odyssey weapons: Ambuscade-like sticks (skill 250, DMG at or a notch
-- under the paired Ambu final) so the 349,999 WS ceiling is a gear check,
-- not an Odyssey fTP multiplier. No ADDS_WEAPONSKILL / linked WSD on the
-- unfinished retail rows -- those WS come from the player's build.
--
-- Gleti's Crossbow / Mpaca's Bow had MId 0; use Arke (52) and Ullr (144).
-- Idempotent. Restart xi_map after apply (item tables are cached at boot).
-- ============================================================================

UPDATE `item_weapon`
    SET `ilvl_skill` = 250, `ilvl_parry` = 250, `ilvl_macc` = 250, `delay` = 576, `dmg` = 165
    WHERE `itemId` = 21527; -- Sakpata's Fists  (Karambit 180/576)

UPDATE `item_weapon`
    SET `ilvl_skill` = 250, `ilvl_parry` = 250, `ilvl_macc` = 250, `delay` = 180, `dmg` = 118
    WHERE `itemId` = 21567; -- Gleti's Knife    (Tauret 125/180)

UPDATE `item_weapon`
    SET `ilvl_skill` = 250, `ilvl_parry` = 250, `ilvl_macc` = 250, `delay` = 240, `dmg` = 158
    WHERE `itemId` = 21637; -- Sakpata's Sword  (Naegling 166/240)

UPDATE `item_weapon`
    SET `ilvl_skill` = 250, `ilvl_parry` = 250, `ilvl_macc` = 250, `delay` = 480, `dmg` = 318
    WHERE `itemId` = 21675; -- Agwu's Claymore  (Nandaka 333/480)

UPDATE `item_weapon`
    SET `ilvl_skill` = 250, `ilvl_parry` = 250, `ilvl_macc` = 250, `delay` = 288, `dmg` = 190
    WHERE `itemId` IN (21723, 21724); -- Ikenga's / Agwu's Axe (Dolichenus 200/288)

UPDATE `item_weapon`
    SET `ilvl_skill` = 250, `ilvl_parry` = 250, `ilvl_macc` = 250, `delay` = 508, `dmg` = 340
    WHERE `itemId` = 21780; -- Bunzi's Chopper  (Lycurgos 359/508)

UPDATE `item_weapon`
    SET `ilvl_skill` = 250, `ilvl_parry` = 250, `ilvl_macc` = 250, `delay` = 528, `dmg` = 350
    WHERE `itemId` = 21832; -- Agwu's Scythe    (Drepanum 366/528)

UPDATE `item_weapon`
    SET `ilvl_skill` = 250, `ilvl_parry` = 250, `ilvl_macc` = 250, `delay` = 480, `dmg` = 318
    WHERE `itemId` = 21884; -- Ikenga's Lance   (Shining One 333/480)

UPDATE `item_weapon`
    SET `ilvl_skill` = 250, `ilvl_parry` = 250, `ilvl_macc` = 250, `delay` = 288, `dmg` = 190
    WHERE `itemId` = 22041; -- Bunzi's Rod      (Maxentius 200/288)

UPDATE `item_weapon`
    SET `ilvl_skill` = 250, `ilvl_parry` = 250, `ilvl_macc` = 250
    WHERE `itemId` = 22100; -- Mpaca's Staff    (keep 268/402; under Xoanon DPS)

UPDATE `item_weapon`
    SET `ilvl_skill` = 250, `ilvl_parry` = 0, `ilvl_macc` = 0, `delay` = 288, `dmg` = 118
    WHERE `itemId` = 22150; -- Gleti's Crossbow (Scout's 126/288)

UPDATE `item_weapon`
    SET `ilvl_skill` = 250, `ilvl_parry` = 0, `ilvl_macc` = 0, `delay` = 360, `dmg` = 168
    WHERE `itemId` = 22151; -- Mpaca's Bow      (Ullr 178/360)

UPDATE `item_equipment` SET `MId` = 52  WHERE `itemId` = 22150; -- Arke Crossbow
UPDATE `item_equipment` SET `MId` = 144 WHERE `itemId` = 22151; -- Ullr

-- Modest combat stats on the unfinished retail rows. Do not copy Ambu
-- ADDS_WEAPONSKILL or linked WSD%; Odyssey WS is the ordinary curve.
DELETE FROM `item_mods` WHERE `itemId` IN (21675, 21723, 21724, 21780, 21884, 22041, 22100, 22150, 22151);
INSERT INTO `item_mods` (`itemId`, `modId`, `value`) VALUES
    -- Agwu's Claymore
    (21675,  8,  15),  -- STR
    (21675,  9,  15),  -- DEX
    (21675, 23,  30),  -- ATT
    (21675, 25,  40),  -- ACC
    (21675, 30,  40),  -- MACC
    -- Ikenga's Axe
    (21723,  8,  15),
    (21723,  9,  15),
    (21723, 23,  30),
    (21723, 25,  40),
    (21723, 30,  40),
    -- Agwu's Axe
    (21724,  8,  15),
    (21724, 12,  15),  -- INT
    (21724, 23,  30),
    (21724, 25,  40),
    (21724, 30,  40),
    -- Bunzi's Chopper
    (21780,  8,  15),
    (21780, 10,  15),  -- VIT
    (21780, 23,  30),
    (21780, 25,  40),
    (21780, 30,  40),
    -- Ikenga's Lance
    (21884,  8,  15),
    (21884,  9,  15),
    (21884, 23,  30),
    (21884, 25,  40),
    (21884, 30,  40),
    -- Bunzi's Rod
    (22041, 12,  15),
    (22041, 13,  15),  -- MND
    (22041, 25,  40),
    (22041, 28,  16),  -- MATT
    (22041, 30,  40),
    -- Mpaca's Staff
    (22100, 12,  15),
    (22100, 13,  15),
    (22100, 25,  40),
    (22100, 28,  16),
    (22100, 30,  40),
    -- Gleti's Crossbow
    (22150, 11,  15),  -- AGI
    (22150, 24,  30),  -- RATT
    (22150, 26,  40),  -- RACC
    (22150, 30,  40),
    -- Mpaca's Bow
    (22151,  8,  15),
    (22151, 11,  15),
    (22151, 24,  30),
    (22151, 26,  40),
    (22151, 30,  40);
