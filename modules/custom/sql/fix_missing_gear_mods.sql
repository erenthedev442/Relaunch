-- =============================================================
-- fix_missing_gear_mods.sql
-- Populates item_mods for item tiers that exist in item_basic /
-- item_equipment but have zero mod entries in item_mods.
--
-- Root cause: LSB's database dump included the +4 / some +1 / some +2
-- item rows in item_basic and item_equipment but did not include their
-- item_mods rows.  Players equipping these items got the item in the
-- slot but zero stat benefit.
--
-- Fix: derive mods from the nearest lower tier using a 10% scale-up
-- on positive values; negative values (penalties) are kept identical
-- so +4 gear never penalises more than +3.
--
-- Formula:
--   positive value -> GREATEST(value + 1, ROUND(value * 1.10))
--   negative value -> value  (no worsening of penalties)
--   zero           -> 0
--
-- Idempotent: INSERT IGNORE skips any row that already exists.
-- Safe to re-run after a database restore.
--
-- Stats fixed:
--   +1 items missing mods  (213 items, derived from base)
--   +2 items missing mods  (398 items, derived from +1)
--   +4 items missing mods  (4,027 items, derived from +3)
-- =============================================================

-- ── Step 1: +1 items ─────────────────────────────────────────
-- Copy mods from the base version, scaled up 10%.
INSERT IGNORE INTO item_mods (itemId, modId, value)
SELECT
    b1.itemid,
    im0.modId,
    CASE
        WHEN im0.value > 0 THEN GREATEST(im0.value + 1, ROUND(im0.value * 1.10))
        WHEN im0.value < 0 THEN im0.value
        ELSE 0
    END
FROM item_basic      b1
JOIN item_equipment  e1  ON e1.itemId  = b1.itemid
JOIN item_basic      b0  ON b0.name    = REPLACE(b1.name, '_+1', '')
JOIN item_mods       im0 ON im0.itemId = b0.itemid
WHERE b1.name LIKE '%\_+1'
  AND e1.itemId NOT IN (SELECT DISTINCT itemId FROM item_mods);

-- ── Step 2: +2 items ─────────────────────────────────────────
-- Copy mods from the +1 version (which is now complete), scaled up 10%.
INSERT IGNORE INTO item_mods (itemId, modId, value)
SELECT
    b2.itemid,
    im1.modId,
    CASE
        WHEN im1.value > 0 THEN GREATEST(im1.value + 1, ROUND(im1.value * 1.10))
        WHEN im1.value < 0 THEN im1.value
        ELSE 0
    END
FROM item_basic      b2
JOIN item_equipment  e2  ON e2.itemId  = b2.itemid
JOIN item_basic      b1  ON b1.name    = REPLACE(b2.name, '_+2', '_+1')
JOIN item_mods       im1 ON im1.itemId = b1.itemid
WHERE b2.name LIKE '%\_+2'
  AND e2.itemId NOT IN (SELECT DISTINCT itemId FROM item_mods);

-- ── Step 3: +4 items ─────────────────────────────────────────
-- Copy mods from the +3 version (already complete), scaled up 10%.
-- The +4 tier is the Ody/Sheol endgame augment — modestly better than +3.
INSERT IGNORE INTO item_mods (itemId, modId, value)
SELECT
    b4.itemid,
    im3.modId,
    CASE
        WHEN im3.value > 0 THEN GREATEST(im3.value + 1, ROUND(im3.value * 1.10))
        WHEN im3.value < 0 THEN im3.value
        ELSE 0
    END
FROM item_basic      b4
JOIN item_equipment  e4  ON e4.itemId  = b4.itemid
JOIN item_basic      b3  ON b3.name    = REPLACE(b4.name, '_+4', '_+3')
JOIN item_mods       im3 ON im3.itemId = b3.itemid
WHERE b4.name LIKE '%\_+4'
  AND e4.itemId NOT IN (SELECT DISTINCT itemId FROM item_mods);
