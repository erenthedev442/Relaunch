-- Fix Air Knife additional effect wind damage never proccing.
-- Root cause: ITEM_ADDEFFECT_CHANCE (mod 501) was 0 (missing), so the proc
-- check math.random(1,100) > 0 always returned early.  Set to 100 = 100%.
INSERT IGNORE INTO `item_mods` VALUES (21570, 501, 100);  -- ITEM_ADDEFFECT_CHANCE: 100%
