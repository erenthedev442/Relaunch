-- ============================================================================
-- prime_voucher.sql
--
-- The "Prime Voucher" (item 29699) -- the token a GM grants at their
-- discretion. A player trades one to the Prime Armory NPC at GM Home to claim
-- a Prime weapon of their choice (see modules/custom/lua/PrimeArmory_NPC.lua).
--
-- Grant one to a player with the GM command:  !primevoucher <player> [count]
-- (modules/custom/commands/primevoucher.lua). The voucher is EX/bound, so a GM
-- can't trade it by hand -- that command adds it straight to the player. (Plain
-- !additem 29699 still works to give one to YOURSELF for testing.)
--
-- Flags = 28736 = NOAUCTION(64) + NOSALE(4096) + NODELIVERY(8192) + EX(16384):
--   bound to the character (no AH, no NPC sale-for-gil, no mail, no player
--   trade) so the granted token can't be sold or handed off -- but it CAN be
--   spent at the NPC (delItem ignores EX). stackSize 12 lets a player hold
--   several at once. type 1 = GENERAL (plain inventory item).
--
-- Idempotent: DELETE then INSERT.
-- ============================================================================

DELETE FROM `item_basic` WHERE `itemid` = 29699;

INSERT INTO `item_basic`
    (`itemid`, `subid`, `name`, `sortname`, `name_jp`, `type`, `stackSize`, `flags`, `aH`, `BaseSell`)
VALUES
    (29699, 0, 'prime_voucher', 'prime_voucher', 'プライム券', 1, 12, 28736, 0, 0);
