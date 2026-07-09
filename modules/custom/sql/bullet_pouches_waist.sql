-- ============================================================================
-- bullet_pouches_waist.sql   (renamed from bullet_pouches_ammo.sql)
--
-- The four "Bullet Pouch" items are equippable WAIST pieces for ranged jobs.
--
-- WHY WAIST, NOT AMMO: item IDs 26347-26350 are [Waist] items in the CLIENT's
-- DAT, so the client only ever lets you equip them to the waist slot. An earlier
-- pass set the SERVER slot to Ammo (8) to make them "infinite ammo" -- but then
-- the client refused them (it thinks they're waist) AND the server refused them
-- in waist -> unequippable in BOTH slots ("can't equip to my waist"). Aligning
-- the server slot to what the client shows (Waist = 1024) makes them equippable
-- again.
--
-- The infinite-ammo goal still holds: each pouch KEEPS RECYCLE (mod 305) = 100,
-- which works as a WORN mod (ranged code only spends ammo when rand(100) >
-- recycleChance; >=100 = never). So wear the pouch on your waist + a stack of
-- real bullets and the bullets are never consumed -- plus the pouch grants
-- ranged stats. RARE (stackSize 1). The pouch no longer carries bullet DMG
-- itself (that comes from the real bullets you equip in the ammo slot).
--
-- Pouch                          jobs       mods
--   26350 Chrono Bullet Pouch      RNG+COR    RATT 20 / RACC 20
--   26348 Living Bullet Pouch      COR        MATT 35 / MACC 25
--   26347 Eradicating Bullet Pouch RNG        RATT 30 / RACC 30
--   26349 Devastating Bullet Pouch RNG+COR    RACC 35 / MACC 35
--
-- Apply, then restart the map (item data is cached at startup). Idempotent.
-- ============================================================================

-- ----- 1. class: WEAPON (7) -> EQUIPMENT/armor (6) so it loads as waist gear --
UPDATE `item_basic` SET `type` = 6 WHERE `itemid` IN (26347, 26348, 26349, 26350);

-- ----- 2. drop the ranged-weapon profile (armor does not use item_weapon) -----
DELETE FROM `item_weapon` WHERE `itemId` IN (26347, 26348, 26349, 26350);

-- ----- 3. equip in the WAIST slot (1024), iLvl 119, jobs copied from each bullet
DELETE FROM `item_equipment` WHERE `itemId` IN (26347, 26348, 26349, 26350);
INSERT INTO `item_equipment` VALUES
    (26350,'chrono_bullet_pouch',     99,119,66560,0,0,0,1024,0,0,0),
    (26348,'living_bullet_pouch',     99,119,65536,0,0,0,1024,0,0,0),
    (26347,'eradicating_bullet_pouch',99,119, 1024,0,0,0,1024,0,0,0),
    (26349,'devastating_bullet_pouch',99,119,66560,0,0,0,1024,0,0,0);

-- ----- 4. mods: keep each pouch's stats + RECYCLE(305)=100 (worn -> your -------
--          equipped bullets are never consumed) --------------------------------
DELETE FROM `item_mods` WHERE `itemId` IN (26347, 26348, 26349, 26350);
INSERT INTO `item_mods` (`itemId`,`modId`,`value`) VALUES
    (26350,  24, 20), (26350,  26, 20), (26350, 305, 100),   -- Chrono:      RATT 20, RACC 20
    (26348,  28, 35), (26348,  30, 25), (26348, 305, 100),   -- Living:      MATT 35, MACC 25
    (26347,  24, 30), (26347,  26, 30), (26347, 305, 100),   -- Eradicating: RATT 30, RACC 30
    (26349,  26, 35), (26349,  30, 35), (26349, 305, 100);   -- Devastating: RACC 35, MACC 35

-- ----- 5. de-register the "usable" identity so they are PURE WAIST GEAR --------
--   These 6 items (4 bullet pouches + chrono quiver + quelling bolt quiver) were
--   ALSO in item_usable (use -> 99-stack, 1h reuse) WHILE being waist gear -- the
--   dual registration is what made pouches/quivers "hit or miss" (client vs server
--   disagree on equip-vs-use). Worn infinite-ammo is the design, and the ammo
--   itself is now buyable in !shop, so the usable dispenser is redundant. Drop it
--   -> one clean identity, no cooldown. (To restore the usable dispensers instead,
--   remove these items from item_equipment/item_mods and re-add item_usable rows.)
DELETE FROM `item_usable` WHERE `itemid` IN (26345, 26346, 26347, 26348, 26349, 26350);
