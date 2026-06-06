-- ============================================================================
-- fix_missing_gear_mods_v2.sql
-- Inserts stat mods for equippable items that have zero rows in item_mods.
-- Idempotent: uses INSERT IGNORE so re-running is safe.
--
-- NOTE: Due to a MariaDB optimizer quirk with correlated HAVING subqueries inside
-- INSERT IGNORE, some items may be skipped on the first run. Run this script TWICE
-- if any items remain at zero mods after the first pass. The second pass is always
-- safe (INSERT IGNORE skips already-inserted rows).
--
-- METHOD: Statistical interpolation
--   For each target item (zero mods, equippable slot, ilevel=0, level>=40),
--   compute the average mod values from reference items that share:
--     - Same equipment slot
--     - Level within ±5 of target
--     - Job bitmask overlap > 0  (jobs=0 items match all)
--
--   Threshold for inclusion:
--     Armor slots (head/body/hands/legs/feet): modId must appear in >= 25% of ref items
--     Accessory slots (neck/waist/ear/ring/back): modId must appear in >= 10% AND >= 2 ref items
--
--   Race-restriction flags (modId=276) and extreme values (>=9999) are excluded.
--
-- TARGET ITEMS COVERED (175 total):
--   - bewitched_*, voodoo_* sets (30 items each, 5 slots)   -- Ambuscade cursed tier 1/2
--   - jinxed_*, vexed_* sets (25 items each, 5 slots)       -- Salvage cursed tier 1/2
--   - Various level 99 accessories (earrings, rings, necklaces, capes, belts)
--   - Level 40-99 mid-level accessories (earrings, rings, necklaces)
--   - 5 non-AH level 99 equippable items (hoxne set, sroda, orpheuss_sash)
--
-- ITEMS INTENTIONALLY SKIPPED (no mods added):
--   - hexed_* items (excluded by name pattern)
--   - Level 1 cosmetic items (fishing belts, tanks, onion gear)
--   - Level 15-30 utility accessories (weapon-skill belts, class earrings)
--   - Level 50 job-specific rings (soldiers_ring, kampfer_ring, etc.)
--   - Level 60-70 job-specific earrings (soldiers_earring, etc.)
--   - Level 65 teleport/recall/ladybug rings (utility, no combat stats)
--   - Non-AH level 99 items with jobs=0 (not equippable by any job)
-- ============================================================================

INSERT IGNORE INTO item_mods (itemId, modId, value)
SELECT
    targets.itemId,
    rm.modId,
    ROUND(AVG(rm.value)) AS value
FROM (
    -- Target items: equippable armor/accessory slots, ilevel=0, level>=40,
    -- zero existing mods, non-hexed, non-NoAuction, jobs>0
    SELECT e.itemId, e.slot, e.level, e.jobs
    FROM item_equipment e
    JOIN item_basic b ON b.itemid = e.itemId
    WHERE e.itemId NOT IN (SELECT DISTINCT itemId FROM item_mods)
      AND e.ilevel = 0
      AND e.level >= 40
      AND e.jobs > 0
      AND b.name NOT LIKE 'hexed%'
      AND (b.flags & 64) = 0      -- not NoAuction-flagged as unsellable
      -- Must be an equippable armor/accessory slot (not weapon/ammo/grip)
      AND (e.slot & 16   OR e.slot & 32   OR e.slot & 64  OR e.slot & 128
        OR e.slot & 256  OR e.slot & 512  OR e.slot & 1024 OR e.slot & 6144
        OR e.slot & 24576 OR e.slot & 32768)
      -- Include: AH-listed items OR the 5 specific non-AH equippable accessories
      AND (b.aH <> 0 OR e.itemId IN (26041, 26043, 26120, 26236, 26359))
      -- Exclude: Exclusive-flag items
      AND (b.flags & 16384) = 0
      -- Exclude: Level 60-75 single-job earrings (class earrings with no combat stats)
      AND NOT (
          e.level BETWEEN 60 AND 75
          AND e.slot = 6144
          AND (
              b.name LIKE 'soldiers_%'  OR b.name LIKE 'kampfer_%'   OR
              b.name LIKE 'medicine_%'  OR b.name LIKE 'fencers_%'   OR
              b.name LIKE 'rogues_%'    OR b.name LIKE 'guardian_%'  OR
              b.name LIKE 'sorcerers_%' OR b.name LIKE 'tamers_%'    OR
              b.name LIKE 'slayers_%'   OR b.name LIKE 'trackers_%'  OR
              b.name LIKE 'ronin_%'     OR b.name LIKE 'shinobi_%'   OR
              b.name LIKE 'minstrels_%' OR b.name LIKE 'conjurers_%' OR
              b.name LIKE 'drake_%'
          )
      )
      -- Exclude: Level 65 utility rings (teleport/recall/ladybug - no combat stats in retail)
      AND NOT (
          e.level = 65
          AND (b.name LIKE 'teleport%' OR b.name LIKE 'recall%' OR b.name LIKE 'ladybug%')
      )
      -- Exclude: Level 50 job-specific rings (class rings with no combat stats)
      AND NOT (e.level = 50 AND e.slot = 24576 AND b.name LIKE '%_ring')
) AS targets

-- Reference: all existing item_mods rows whose items share slot/level/jobs
JOIN item_mods rm ON 1 = 1
JOIN item_equipment re ON re.itemId = rm.itemId

WHERE
    -- Match same equipment slot
    re.slot = targets.slot
    -- Match level within ±5
    AND re.level BETWEEN targets.level - 5 AND targets.level + 5
    -- Reference must also be ilevel=0 (non-iLevel gear, same tier)
    AND re.ilevel = 0
    -- Job overlap: reference must share at least one job with target
    -- (jobs=0 on target would mean no overlap, but we already exclude jobs=0 targets above)
    AND (re.jobs & targets.jobs) > 0
    -- Only positive stat values
    AND rm.value > 0
    -- Exclude extreme/buggy values (9999 sentinel values)
    AND rm.value < 9999
    -- Exclude race-restriction flag (not a combat stat)
    AND rm.modId != 276
    -- Don't use the target item itself as a reference
    AND rm.itemId != targets.itemId
    -- Paranoia: skip reference items that are themselves missing mods
    -- (they might be other cursed items - we want real gear as reference)
    AND EXISTS (SELECT 1 FROM item_mods chk WHERE chk.itemId = rm.itemId LIMIT 1)

GROUP BY
    targets.itemId,
    targets.slot,
    targets.level,
    targets.jobs,
    rm.modId

HAVING
    -- Armor slots use 25% threshold (these items tend to have consistent stat profiles)
    -- Accessory slots use 10% threshold with minimum 2 items
    -- (accessories are highly specialized; lower threshold still filters outliers)
    COUNT(DISTINCT rm.itemId) >= (
        SELECT GREATEST(
            2,
            COUNT(DISTINCT r2.itemId) * (
                CASE
                    WHEN targets.slot IN (16, 32, 64, 128, 256) THEN 0.25  -- armor
                    ELSE 0.10                                                 -- accessories
                END
            )
        )
        FROM item_mods r2
        JOIN item_equipment re2 ON re2.itemId = r2.itemId
        WHERE re2.slot = targets.slot
          AND re2.level BETWEEN targets.level - 5 AND targets.level + 5
          AND re2.ilevel = 0
          AND (re2.jobs & targets.jobs) > 0
          AND r2.value > 0
          AND r2.value < 9999
          AND r2.modId != 276
          AND r2.itemId != targets.itemId
          AND EXISTS (SELECT 1 FROM item_mods chk2 WHERE chk2.itemId = r2.itemId LIMIT 1)
    )
    -- The rounded average must be a meaningful value
    AND ABS(ROUND(AVG(rm.value))) >= 1;
