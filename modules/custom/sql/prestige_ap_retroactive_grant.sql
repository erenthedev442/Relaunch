-- ============================================================================
-- prestige_ap_retroactive_grant.sql  --  ONE-TIME retroactive AP top-up
-- ----------------------------------------------------------------------------
-- Before 2026-06-21 commit 36fc051f4e, every Prestige ascension granted a
-- flat 10 Ascension Points regardless of level.  The new tiered system grants:
--   P.Lv  1-50  ->  10 AP per ascension  (unchanged)
--   P.Lv 51-80  ->  15 AP per ascension  (+5)
--   P.Lv 81+    ->  20 AP per ascension  (+10)
--
-- This script grants every character the difference between what they earned
-- under the old flat rate and what they WOULD have earned under the new tiers,
-- across every job they have levelled past Prestige 50.
--
-- Deficit formula for a job at prestige level N:
--   N <= 50 : 0
--   N <= 80 : 5*N - 250     (= (N-50) * 5)
--   N  > 80 : 10*N - 650    (= 30*5 + (N-80)*10)
--
-- Both Prestige_AP_<jobId>          (unspent, spendable)
-- and  Prestige_AP_Lifetime_<jobId> (lifetime total, flavour counter)
-- are incremented by the deficit.
--
-- IDEMPOTENT: characters who already received the retro grant are skipped
-- (guarded by charVar Prestige_AP_Retro_Done = 1).
--
-- Applies via the modules/custom/sql sha256 ledger (runs once on first deploy).
-- Can also be applied manually on the Azure box:
--   sudo mariadb xidb < modules/custom/sql/prestige_ap_retroactive_grant.sql
-- ============================================================================

-- Step 1 ---- compute per-char per-job deficit ----------------------------------
CREATE TEMPORARY TABLE _retro_deficit AS
SELECT
    cv.charid,
    REPLACE(cv.varname, 'Prestige_Level_', '') AS job_id,
    cv.value AS prestige_level,
    CASE
        WHEN cv.value <= 50 THEN 0
        WHEN cv.value <= 80 THEN 5 * cv.value - 250
        ELSE                     10 * cv.value - 650
    END AS deficit
FROM `char_vars` cv
WHERE cv.varname LIKE 'Prestige\_Level\_%'
  AND cv.value > 50
  -- skip any char already patched
  AND NOT EXISTS (
      SELECT 1
      FROM   `char_vars` done
      WHERE  done.charid  = cv.charid
        AND  done.varname = 'Prestige_AP_Retro_Done'
        AND  done.value   = 1
  );

-- Step 2 ---- grant unspent AP (the spendable pool) ----------------------------
UPDATE `char_vars` cv
JOIN   `_retro_deficit` d
    ON  cv.charid  = d.charid
   AND  cv.varname = CONCAT('Prestige_AP_', d.job_id)
SET    cv.value = cv.value + d.deficit
WHERE  d.deficit > 0;

-- Step 3 ---- grant lifetime AP (flavour counter) ------------------------------
UPDATE `char_vars` cv
JOIN   `_retro_deficit` d
    ON  cv.charid  = d.charid
   AND  cv.varname = CONCAT('Prestige_AP_Lifetime_', d.job_id)
SET    cv.value = cv.value + d.deficit
WHERE  d.deficit > 0;

-- Step 4 ---- stamp each affected char so re-runs are no-ops ------------------
INSERT INTO `char_vars` (charid, varname, value)
SELECT DISTINCT d.charid, 'Prestige_AP_Retro_Done', 1
FROM   `_retro_deficit` d
WHERE  d.deficit > 0
ON DUPLICATE KEY UPDATE value = 1;

DROP TEMPORARY TABLE _retro_deficit;
