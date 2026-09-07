-- ============================================================================
-- cor_die_ability_subids.sql
-- ----------------------------------------------------------------------------
-- item_basic.subid is what the client prints for "You already know <ability>"
-- when a scroll/die check fails (item_state.cpp uses subid as the message
-- param). Early COR job dice stored the ability ID (which matched the roll
-- animation). Allies'/Miser's/Companions'/Avengers' dice stored the roll
-- animation instead:
--   Allies' Die   5502  subid 138  -> Deploy (ability 138)
--   Miser's Die   5503  subid 139  -> (wrong ability name)
--   Companions    5504  subid 265
--   Avengers      5505  subid 266
-- GEO/RUN dice shipped with subid 0.
--
-- Ability IDs: Allies 302, Miser 303, Companions 304, Avengers 305,
-- Naturalists 390, Runeists 391.
-- Idempotent. item_basic is read at map boot.
-- ============================================================================

UPDATE `item_basic` SET `subid` = 302 WHERE `itemid` = 5502 AND `name` = 'allies_die';
UPDATE `item_basic` SET `subid` = 303 WHERE `itemid` = 5503 AND `name` = 'misers_die';
UPDATE `item_basic` SET `subid` = 304 WHERE `itemid` = 5504 AND `name` = 'companions_die';
UPDATE `item_basic` SET `subid` = 305 WHERE `itemid` = 5505 AND `name` = 'avengers_die';
UPDATE `item_basic` SET `subid` = 390 WHERE `itemid` = 6368 AND `name` = 'geomancer_die';
UPDATE `item_basic` SET `subid` = 391 WHERE `itemid` = 6369 AND `name` = 'rune_fencer_die';
