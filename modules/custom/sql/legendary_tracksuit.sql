-- ============================================================================
-- legendary_tracksuit.sql   (RELAUNCH -- lives in modules/custom/sql/)
--
-- The "Legendary Track Suit" -- a strictly-cosmetic 4-piece Legacy migration
-- reward set (zero stats, Lv.1, all jobs/races, Rare/Ex):
--
--   23875 track_jacket    body  MId 515   (blue/white colorway)
--   23876 track_pants     legs  MId 515
--   23877 track_shoes     feet  MId 515
--   23878 legend_sweater  body  MId 615   (crimson/white, sweater + scarf)
--
-- Models 515/615 are CLIENT models that exist in every retail install but are
-- referenced by NO item on this server (verified vs item_equipment 2026-07-10),
-- so their textures were custom-repainted (blue track suit / red sweater) in
-- the "Relaunch Custom DATs" pack without altering any existing item's look.
-- Item ids 23875-78 were FREE (no item_basic row); their client tooltip text
-- lives in the same pack (ROM/286/73.DAT, cloned from donor armor records).
-- Without the DAT pack the pieces still equip and render the models in their
-- ORIGINAL colors (black/silver suit, dusty-red sweater) with blank names.
--
-- No item_mods rows on purpose: the set is pure glamour.
-- GRANTED BY: modules/custom/lua/legacy_tracksuit_grant.lua on login when
-- charVar Legacy_TrackSuit_Grant == 1 (set by the portal Legacy claim).
--
-- Apply, then RESTART the map (item tables cached at boot). Idempotent.
-- ============================================================================

DELETE FROM `item_basic` WHERE `itemid` IN (23875, 23876, 23877, 23878);
INSERT INTO `item_basic` (`itemid`, `subid`, `name`, `sortname`, `name_jp`, `type`, `stackSize`, `flags`, `aH`, `BaseSell`) VALUES
    (23875, 0, 'track_jacket',   'track_jacket',   '', 6, 1, 64596, 0, 0),
    (23876, 0, 'track_pants',    'track_pants',    '', 6, 1, 64596, 0, 0),
    (23877, 0, 'track_shoes',    'track_shoes',    '', 6, 1, 64596, 0, 0),
    (23878, 0, 'legend_sweater', 'legend_sweater', '', 6, 1, 64596, 0, 0);

DELETE FROM `item_equipment` WHERE `itemId` IN (23875, 23876, 23877, 23878);
INSERT INTO `item_equipment` (`itemId`, `name`, `level`, `ilevel`, `jobs`, `MId`, `shieldSize`, `scriptType`, `slot`, `rslot`, `rslotlook`, `su_level`) VALUES
    (23875, 'track_jacket',   1, 0, 4194303, 515, 0, 0,  32, 0, 0, 0),
    (23876, 'track_pants',    1, 0, 4194303, 515, 0, 0, 128, 0, 0, 0),
    (23877, 'track_shoes',    1, 0, 4194303, 515, 0, 0, 256, 0, 0, 0),
    (23878, 'legend_sweater', 1, 0, 4194303, 615, 0, 0,  32, 0, 0, 0);
