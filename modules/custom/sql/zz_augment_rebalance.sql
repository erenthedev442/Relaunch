-- =====================================================================
-- zz_augment_rebalance.sql
-- Make the Augment Sage's ACHIEVEMENT scaling the real driver of augment
-- power, instead of a high base value slamming the engine's 5-bit boost cap.
--
-- Pairs with the Augment_Moogle.lua change (2026-06-06): the per-slot boost
-- is now pure achievement progress mapped across 0..31 (rank x affinity x
-- crit), no longer scaled off the base. The engine then computes, per slot:
--
--     final = (value + boost) * multiplier        (item_equipment.cpp:479)
--       boost = 0  at no achievements
--       boost = 31 at rank5 + affinity + a crit
--   so  floor = value * multiplier
--       cap   = (value + 31) * multiplier
--
-- DESIGN (chosen 2026-06-06: "aggressive" — achievements are everything):
--   value = 1, multiplier = (oldCap / 32). KEEPS each augment's current
--   per-slot cap, drops the floor to cap/32 so a fresh augment is weak and
--   the climb to the cap is EARNED via the Sage. Per 4-slot piece the range
--   is 4x the per-slot range (HP: 4..128/slot -> 16..512 per piece, matching
--   the live Nyame numbers, now achievement-gated).
--
-- NOTE: augments already at value=1 (every stock "+1" augment) need NO row —
-- the Moogle change alone makes their boost scale 1 -> 32 with achievements.
-- Only the HIGH-BASE flat stats below need their base flattened. The custom
-- "All elemental resists +10" (augId 796) is intentionally LEFT ALONE.
--
-- Re-runnable. Apply: mariadb xidb < modules/custom/sql/zz_augment_rebalance.sql
-- then RESTART the map server (augments load at boot via LoadAugmentData).
-- =====================================================================

-- ---- value 97 -> mult 4 : per-slot 4..128  (x4 = 16..512 per piece) ----
UPDATE `augments` SET `value` = 1, `multiplier` = 4 WHERE `augmentId` = 4;    -- HP+
UPDATE `augments` SET `value` = 1, `multiplier` = 4 WHERE `augmentId` = 12;   -- MP+
UPDATE `augments` SET `value` = 1, `multiplier` = 4 WHERE `augmentId` = 743;  -- Dmg:+ (melee)  [weapon base dmg]
UPDATE `augments` SET `value` = 1, `multiplier` = 4 WHERE `augmentId` = 749;  -- Dmg:+ (ranged)

-- ---- value 33 -> mult 2 : per-slot 2..64  (x4 = 8..256 per piece) ----
UPDATE `augments` SET `value` = 1, `multiplier` = 2 WHERE `augmentId` = 65;   -- Attack+
UPDATE `augments` SET `value` = 1, `multiplier` = 2 WHERE `augmentId` = 66;   -- Rng.Attack+
UPDATE `augments` SET `value` = 1, `multiplier` = 2 WHERE `augmentId` = 62;   -- Accuracy+
UPDATE `augments` SET `value` = 1, `multiplier` = 2 WHERE `augmentId` = 63;   -- Rng.Accuracy+
UPDATE `augments` SET `value` = 1, `multiplier` = 2 WHERE `augmentId` = 64;   -- Mag. Acc.+
UPDATE `augments` SET `value` = 1, `multiplier` = 2 WHERE `augmentId` = 70;   -- Mag.Acc.+ Mag.Atk.Bns+ (both rows)
UPDATE `augments` SET `value` = 1, `multiplier` = 2 WHERE `augmentId` = 18;   -- HP+ MP+ (both rows)
UPDATE `augments` SET `value` = 1, `multiplier` = 2 WHERE `augmentId` = 353;  -- TP Bonus+ (old cap 81 -> 64; engine caps TP Bonus at 1000)

-- ---- value 5 -> mult 1 : per-slot 1..32  (x4 = 4..128 per piece) ----
UPDATE `augments` SET `value` = 1, `multiplier` = 1 WHERE `augmentId` = 137;  -- Regen+ (old cap 36 -> 32)
