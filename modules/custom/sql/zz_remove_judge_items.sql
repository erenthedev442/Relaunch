-- =====================================================================
-- zz_remove_judge_items.sql
-- Purge the 19 stock "Judge" items from the server. These are the Ballista
-- referee ("Judge") NPC's gear + fishing bait — NPC/event items that are NOT
-- player-obtainable (no mob_droplist rows, aH = 0, several EX/Rare), but they
-- happen to be equippable so the gear scorer was listing them in the Gear
-- Finder with nonsense scores (e.g. "Judge's Cape 1100 DPS").
--
-- They are STOCK rows in sql/item_basic.sql, so we DON'T edit that tracked
-- file (merge-safety). Instead this override DELETEs them, applied AFTER the
-- stock import. Re-runnable (DELETE is idempotent); re-apply after any full
-- DB re-import of the stock item data.
--
-- Item IDs (name):
--   12332 judges_shield   12523 judges_helm     12551 judges_cuirass
--   12679 judges_gauntlets 12807 judges_cuisses  12935 judges_greaves
--   13074 judges_gorget   13215 judges_belt      13358 judges_earring
--   13505 judges_ring     13606 judges_cape      16622 judges_sword
--   17004 judge_minnow    17012 judges_rod       17174 judges_bow
--   17326 judges_arrow    17406 judges_lure      17644 judges_sword
--   19325 judge_fly
--
-- Effect: gone from the game (map reload drops them) AND from the Gear Finder
-- after the next docs regen (the scorers read the live DB).
--
-- Apply: mariadb xidb < modules/custom/sql/zz_remove_judge_items.sql
--        then RESTART the map server. Run refresh-site.bat to update the
--        Gear Finder docs page.
-- =====================================================================

DELETE FROM `item_basic`     WHERE `itemid` IN (12332,12523,12551,12679,12807,12935,13074,13215,13358,13505,13606,16622,17004,17012,17174,17326,17406,17644,19325);
DELETE FROM `item_equipment` WHERE `itemId` IN (12332,12523,12551,12679,12807,12935,13074,13215,13358,13505,13606,16622,17004,17012,17174,17326,17406,17644,19325);
DELETE FROM `item_weapon`    WHERE `itemId` IN (12332,12523,12551,12679,12807,12935,13074,13215,13358,13505,13606,16622,17004,17012,17174,17326,17406,17644,19325);
DELETE FROM `item_mods`      WHERE `itemId` IN (12332,12523,12551,12679,12807,12935,13074,13215,13358,13505,13606,16622,17004,17012,17174,17326,17406,17644,19325);
DELETE FROM `item_mods_pet`  WHERE `itemId` IN (12332,12523,12551,12679,12807,12935,13074,13215,13358,13505,13606,16622,17004,17012,17174,17326,17406,17644,19325);
DELETE FROM `item_latents`   WHERE `itemId` IN (12332,12523,12551,12679,12807,12935,13074,13215,13358,13505,13606,16622,17004,17012,17174,17326,17406,17644,19325);
DELETE FROM `item_usable`    WHERE `itemId` IN (12332,12523,12551,12679,12807,12935,13074,13215,13358,13505,13606,16622,17004,17012,17174,17326,17406,17644,19325);
