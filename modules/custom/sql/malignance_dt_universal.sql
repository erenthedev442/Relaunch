-----------------------------------------------------------------------------
-- Malignance "Damage taken -X%"  ->  universal DT (mod 160). Retail-correct.
--
-- BUG (player report, Burtgang): the Malignance set's "Damage taken -X%" only
-- reduced PHYSICAL (and ranged) damage -- MAGIC and BREATH were untouched.
-- Cause: stock sql/item_mods.sql models it as DMGPHYS(161) + DMGRANGE(164),
-- with NO DMGMAGIC(163), DMGBREATH(162), or universal DMG(160).
--
-- The engine adds Mod::DMG (160) into ALL FOUR damage-taken formulas
-- (src/map/utils/battleutils.cpp: breath 2099, magic 4817, phys 4860,
-- ranged 4909 -- each value/10000), so consolidating each piece's split into a
-- single 160 makes its "Damage taken -X%" reduce phys / magic / breath / ranged
-- alike, which is what retail Malignance does. 161 == 164 on every piece, so one
-- 160 value preserves the magnitude: phys/ranged unchanged, magic/breath newly
-- covered.
--
-- Idempotent (DELETE the split mods, INSERT the universal one). Scoped to the
-- five body pieces only. Custom override -- the stock sql/item_mods.sql is left
-- as-is; this corrects the DB on apply.
--   23732 chapeau  23733 tabard  23734 gloves  23735 tights  23736 boots
--
-- DEPLOY: item mods are cached in RAM at boot, so this needs the DB updated AND
-- a map RESTART (item-list reload) to go live. No C++ rebuild.
-----------------------------------------------------------------------------
DELETE FROM item_mods
 WHERE itemId IN (23732, 23733, 23734, 23735, 23736)
   AND modId  IN (161, 164);

INSERT INTO item_mods (itemId, modId, value) VALUES
  (23732, 160, -600),   -- chapeau : Damage taken -6%
  (23733, 160, -900),   -- tabard  : Damage taken -9%
  (23734, 160, -500),   -- gloves  : Damage taken -5%
  (23735, 160, -700),   -- tights  : Damage taken -7%
  (23736, 160, -700)    -- boots   : Damage taken -7%
ON DUPLICATE KEY UPDATE value = VALUES(value);
