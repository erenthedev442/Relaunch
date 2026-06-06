-- ---------------------------------------------------------------------------
-- One-time backfill for the leaderboard lifetime counters.
--
-- After adding lifetime tracking to Reforge_System.lua and HuntingLeague.lua,
-- existing characters had a current mark balance but no _Lifetime counter
-- and no Custom_NM_Kills count. This script estimates those counters from
-- whatever data IS in char_vars so the leaderboards have a starting picture
-- on day one.
--
-- Idempotent: every UPSERT uses GREATEST() so re-running won't lower
-- anyone's counter, and the script can be re-applied safely if you tune
-- the math below.
--
-- Apply with:
--   python tools/dbtool.py update modules/custom/sql/seed_lifetime_counters.sql
--
-- Tuning knobs (edit these constants, then re-run):
--   SEED_FACTOR              — multiplier on current balance to estimate
--                              lifetime earnings. 1.0 = "you've at least
--                              earned what you currently hold". 2.0 = "you
--                              probably spent half of what you've earned".
--                              Default 1.5 is moderately generous.
--   AVG_HL_POINTS_PER_KILL   — average HL points per NM kill across tiers.
--                              From hunting_league_catalog.lua: tier 1 = 1pt,
--                              tier 5 = ~15pts. ~5 is the rough midpoint.
--   AVG_RF_MARKS_PER_KILL    — average Reforge marks per NM kill. From
--                              reforge_catalog.lua: 25-35 across the three
--                              pools. 27 is the population mean.
-- ---------------------------------------------------------------------------

-- =========================================================================
-- 1. Lifetime Reforge marks per-currency.
--    Seed each _Lifetime CharVar from the current balance * SEED_FACTOR.
--    SEED_FACTOR = 1.5 (i.e. assume players have spent ~33% of what they've
--    earned). Tune by editing the literal `* 1.5` in each query.
-- =========================================================================

-- NOTE: We alias the SELECT-side `char_vars` as `src` so that the bare
-- `char_vars.value` reference inside ON DUPLICATE KEY UPDATE unambiguously
-- means the target row (the existing record being updated). Without the
-- alias, MySQL 5.7+ rejects this with:
--   ERROR 1052 (23000): Column 'char_vars.value' in UPDATE is ambiguous

INSERT INTO char_vars (charid, varname, value, expiry)
SELECT src.charid, 'RF_AF_Marks_Lifetime', FLOOR(src.value * 1.5), 0
  FROM char_vars AS src
 WHERE src.varname = 'RF_AF_Marks' AND src.value > 0
ON DUPLICATE KEY UPDATE value = GREATEST(char_vars.value, VALUES(value));

INSERT INTO char_vars (charid, varname, value, expiry)
SELECT src.charid, 'RF_Relic_Marks_Lifetime', FLOOR(src.value * 1.5), 0
  FROM char_vars AS src
 WHERE src.varname = 'RF_Relic_Marks' AND src.value > 0
ON DUPLICATE KEY UPDATE value = GREATEST(char_vars.value, VALUES(value));

INSERT INTO char_vars (charid, varname, value, expiry)
SELECT src.charid, 'RF_Empy_Marks_Lifetime', FLOOR(src.value * 1.5), 0
  FROM char_vars AS src
 WHERE src.varname = 'RF_Empy_Marks' AND src.value > 0
ON DUPLICATE KEY UPDATE value = GREATEST(char_vars.value, VALUES(value));


-- =========================================================================
-- 2. Custom_NM_Kills estimate.
--    Sum of derived kills from two sources:
--      a. Hunting League: HL_Points / 5     (avg 5 pts per kill)
--      b. Reforge:        lifetime_marks_sum / 27   (avg 27 marks per kill)
--    Floor to integer. UPSERT with GREATEST so any later live data wins.
-- =========================================================================

INSERT INTO char_vars (charid, varname, value, expiry)
SELECT
    bases.charid,
    'Custom_NM_Kills',
    FLOOR(
        (COALESCE(hl.value,         0) / 5)  +
        (COALESCE(rf_lifetime.total, 0) / 27)
    ),
    0
FROM (
    SELECT DISTINCT charid
      FROM char_vars
     WHERE varname IN (
        'HL_Points',
        'RF_AF_Marks_Lifetime',
        'RF_Relic_Marks_Lifetime',
        'RF_Empy_Marks_Lifetime'
     )
) bases
LEFT JOIN char_vars hl
  ON hl.charid = bases.charid AND hl.varname = 'HL_Points'
LEFT JOIN (
    SELECT charid, SUM(value) AS total
      FROM char_vars
     WHERE varname IN (
        'RF_AF_Marks_Lifetime',
        'RF_Relic_Marks_Lifetime',
        'RF_Empy_Marks_Lifetime'
     )
  GROUP BY charid
) rf_lifetime
  ON rf_lifetime.charid = bases.charid
ON DUPLICATE KEY UPDATE value = GREATEST(char_vars.value, VALUES(value));


-- =========================================================================
-- Quick verification queries (uncomment to print results after apply).
-- =========================================================================

-- SELECT c.charname,
--        cv1.value AS af_lifetime,
--        cv2.value AS relic_lifetime,
--        cv3.value AS empy_lifetime,
--        cv4.value AS nm_kills
--   FROM chars c
--   LEFT JOIN char_vars cv1 ON cv1.charid = c.charid AND cv1.varname = 'RF_AF_Marks_Lifetime'
--   LEFT JOIN char_vars cv2 ON cv2.charid = c.charid AND cv2.varname = 'RF_Relic_Marks_Lifetime'
--   LEFT JOIN char_vars cv3 ON cv3.charid = c.charid AND cv3.varname = 'RF_Empy_Marks_Lifetime'
--   LEFT JOIN char_vars cv4 ON cv4.charid = c.charid AND cv4.varname = 'Custom_NM_Kills'
--  WHERE COALESCE(cv1.value, 0) + COALESCE(cv2.value, 0) + COALESCE(cv3.value, 0) + COALESCE(cv4.value, 0) > 0
--  ORDER BY (COALESCE(cv1.value, 0) + COALESCE(cv2.value, 0) + COALESCE(cv3.value, 0)) DESC;
