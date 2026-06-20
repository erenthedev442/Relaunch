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
-- NOTE: augments already at value=1 (every stock "+1" augment) need NO row to
-- scale 1 -> 32 with achievements -- the Moogle change handles that. Rows below
-- exist for two reasons: (1) HIGH-BASE flat stats (HP/MP/Attack/...) whose base
-- is flattened to 1 so the achievement boost isn't wasted against the 5-bit cap;
-- (2) RECOVERY/sustain stats we deliberately cap ABOVE 32 (multiplier > 1). The
-- custom "All elemental resists +10" (augId 796) is intentionally LEFT ALONE.
--
-- Re-runnable. Apply: mariadb xidb < modules/custom/sql/zz_augment_rebalance.sql
-- then RESTART the map server (augments load at boot via LoadAugmentData).
-- =====================================================================

-- ---- value 97 -> mult 4 : per-slot 4..128  (x4 = 16..512 per piece) ----
UPDATE `augments` SET `value` = 1, `multiplier` = 4 WHERE `augmentId` = 4;    -- HP+
UPDATE `augments` SET `value` = 1, `multiplier` = 4 WHERE `augmentId` = 12;   -- MP+
-- (743 melee Dmg / 749 ranged Dmg removed 2026-06-19: banned augments, dropped
--  from augment_catalog.lua -- no longer offered, so no override belongs here.)

-- ---- value 33 -> mult 2 : per-slot 2..64  (x4 = 8..256 per piece) ----
UPDATE `augments` SET `value` = 1, `multiplier` = 2 WHERE `augmentId` = 65;   -- Attack+
UPDATE `augments` SET `value` = 1, `multiplier` = 2 WHERE `augmentId` = 66;   -- Rng.Attack+
UPDATE `augments` SET `value` = 1, `multiplier` = 2 WHERE `augmentId` = 62;   -- Accuracy+
UPDATE `augments` SET `value` = 1, `multiplier` = 2 WHERE `augmentId` = 63;   -- Rng.Accuracy+
UPDATE `augments` SET `value` = 1, `multiplier` = 2 WHERE `augmentId` = 64;   -- Mag. Acc.+
UPDATE `augments` SET `value` = 1, `multiplier` = 2 WHERE `augmentId` = 70;   -- Mag.Acc.+ Mag.Atk.Bns+ (both rows)
UPDATE `augments` SET `value` = 1, `multiplier` = 2 WHERE `augmentId` = 18;   -- HP+ MP+ (both rows)
UPDATE `augments` SET `value` = 1, `multiplier` = 2 WHERE `augmentId` = 353;  -- TP Bonus+ (old cap 81 -> 64; engine caps TP Bonus at 1000)

-- ---- RECOVERY / SUSTAIN (flat per-tick stats) ----
-- All defaulted to multiplier 0/1 (the engine treats both as x1) so they capped
-- at the same 32/slot = 128/piece as a stock augment. Bumped 2026-06-08 so the
-- achievement climb actually means something for sustain builds. DIFFERENTIATED
-- per owner decision: combat Refresh (138) is held at x2 because x4 (~170 MP/sec
-- from one maxed piece) would remove MP as a resource for casters; the resting
-- "while healing" MP stat (52) CAN go x4 since it only ticks out of combat.
--   x4 -> per-slot 4..128  (x4 slots = 16..512 per piece)
UPDATE `augments` SET `value` = 1, `multiplier` = 4 WHERE `augmentId` = 137;  -- Regen (HP/tick, combat)              -> 16..512/piece
UPDATE `augments` SET `value` = 1, `multiplier` = 4 WHERE `augmentId` = 110;  -- Pet: Regen (HP/tick)                 -> 16..512/piece
UPDATE `augments` SET `value` = 1, `multiplier` = 4 WHERE `augmentId` = 51;   -- HP recovered while healing (resting) -> 16..512/piece
UPDATE `augments` SET `value` = 1, `multiplier` = 4 WHERE `augmentId` = 52;   -- MP recovered while healing (resting) -> 16..512/piece
--   x2 -> per-slot 2..64   (x4 slots = 8..256 per piece)
UPDATE `augments` SET `value` = 1, `multiplier` = 2 WHERE `augmentId` = 138;  -- Refresh (MP/tick, combat)            -> 8..256/piece (capped on purpose)

-- ---- HASTE (gear/pet haste, modId 384, stored /1024) ----
-- The stock haste augments are OVER-SCALED: mult 100 means a FRESH augment already
-- grants ~9.8% haste -- near the 25% gear-haste cap -- ignoring the Sage curve, and
-- a maxed one computes to ~312%/slot. Re-tuned to scale ~1% -> 25% (the gear cap)
-- across a 4-slot piece like every other augment: final = (value+boost)*mult, read
-- as a % via /1024, so a maxed piece = 4*(1+31)*2 = 256 = 25%. Slow keeps its
-- negative sign (self-slow); the catalog shows its magnitude.
UPDATE `augments` SET `value` =  1, `multiplier` = 2 WHERE `augmentId` = 49;   -- Haste       -> ~1..25% / piece
UPDATE `augments` SET `value` =  1, `multiplier` = 2 WHERE `augmentId` = 111;  -- Pet: Haste  -> ~1..25% / piece
UPDATE `augments` SET `value` = -1, `multiplier` = 2 WHERE `augmentId` = 50;   -- Slow (negative haste; display shows magnitude)

-- ---- INT+ (augId 516) ----
-- Stock entry has value=0/mult=0 → floor of 0; set to value=1/mult=1 to match MND (517).
UPDATE `augments` SET `value` = 1, `multiplier` = 1 WHERE `augmentId` = 516;  -- INT+ -> 1..32/slot

-- ---- Flat weapon Dmg+ TOP tier (743 melee / 749 ranged) -- restored 2026-06-20 ----
-- Stock value is +97 (Dmg:+97), absurd stacked across 5 augment slots. Rebalance to
-- value=1/mult=1 -> +1..32 per slot (the retail DMG+32 cap), scaling with Augment Sage.
UPDATE `augments` SET `value` = 1, `multiplier` = 1 WHERE `augmentId` = 743;  -- DMG melee  -> +1..32/slot
UPDATE `augments` SET `value` = 1, `multiplier` = 1 WHERE `augmentId` = 749;  -- DMG ranged -> +1..32/slot

-- ---- INDIVIDUAL WS DMG+ (augIds 1024-1058, one per named weaponskill) ----
-- Original: value=1, mult=5 → per-slot 5..160, 5 slots = 25..800%
-- New:      value=9, mult=1 → per-slot 9.. 40, 5 slots = 45..200%
-- Cap reduced 800→200% so WS DMG augments are strong but not ludicrous.
UPDATE `augments` SET `value` = 9, `multiplier` = 1 WHERE `augmentId` BETWEEN 1024 AND 1058;
