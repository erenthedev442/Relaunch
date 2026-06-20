-- =============================================================================
-- zz_repair_job_merits.sql
-- One-time repair for job-specific merit rows incorrectly set by the OLD
-- !automerits command (which had no category filter and iterated ALL xi.merit
-- IDs, raising Group 1, Group 2, WS, and Others merits in addition to the
-- intended generic categories).
--
-- The ACTIVE automerits.lua already has the correct category filter (only
-- 0x0040..0x0100). This script fixes existing player data.
--
-- What this does:
--   1. Computes a per-character merit point refund based on what was spent
--      on non-generic merits (meritid >= 0x0140 = 320).
--   2. Adds those points back to char_exp.merits (capped at 255).
--   3. Deletes all non-generic merit rows from char_merit.
--
-- Cost schedule (from merit.cpp upgrade[] array):
--   Others/Group1 (UpgradeID 5/6, meritid 0x0140-0x07FF excl. WS):
--     per-rank costs {1,2,3,4,5} → cumulative refund by rank: 1,3,6,10,15
--   WS (UpgradeID 8, meritid 0x0680-0x06BF = 1664-1727):
--     per-rank costs {20,22,24,27,30} → cumulative: 20,42,66,93,123
--   Group2 (UpgradeID 7, meritid >= 0x0800 = 2048):
--     per-rank costs {3,4,5,5,5} → cumulative refund by rank: 3,7,12,17,22
--
-- SAFE TO RUN ON LIVE DB.  However, the map server MUST be restarted
-- immediately after, before any online player logs out — otherwise their
-- in-memory merit state will re-save the old (invalid) rows on logout.
-- Pattern: run this SQL → restart xi_map within the same window.
--
-- Players need to relog after the restart to see their updated merit points
-- and empty Group 1/2 slots. Their unspent balance will include the refund.
-- =============================================================================

-- ---- PREVIEW (uncomment to dry-run, shows chars + affected merit count) ----
-- SELECT
--     c.charname,
--     COUNT(*)              AS merit_rows_affected,
--     SUM(cm.upgrades)      AS total_ranks_removed,
--     SUM(CASE
--         WHEN cm.meritid BETWEEN 1664 AND 1727 THEN
--             CASE cm.upgrades WHEN 1 THEN 20 WHEN 2 THEN 42 WHEN 3 THEN 66
--                              WHEN 4 THEN 93 ELSE 123 END
--         WHEN cm.meritid >= 2048 THEN
--             CASE cm.upgrades WHEN 1 THEN 3 WHEN 2 THEN 7 WHEN 3 THEN 12
--                              WHEN 4 THEN 17 ELSE 22 END
--         ELSE
--             CASE cm.upgrades WHEN 1 THEN 1 WHEN 2 THEN 3 WHEN 3 THEN 6
--                              WHEN 4 THEN 10 ELSE 15 END
--     END)                  AS merit_pts_refunded
-- FROM char_merit cm
-- JOIN chars c ON c.charid = cm.charid
-- WHERE cm.meritid >= 320
-- GROUP BY c.charname
-- ORDER BY merit_pts_refunded DESC;
-- ---------------------------------------------------------------------------

START TRANSACTION;

-- Step 1: Compute refund per character
CREATE TEMPORARY TABLE IF NOT EXISTS _merit_repair_refunds AS
SELECT
    charid,
    SUM(
        CASE
            -- WS merits: meritid 0x0680..0x06BF (1664..1727), costs {20,22,24,27,30}
            WHEN meritid BETWEEN 1664 AND 1727 THEN
                CASE upgrades WHEN 1 THEN 20 WHEN 2 THEN 42 WHEN 3 THEN 66
                              WHEN 4 THEN 93 ELSE 123 END
            -- Group 2: meritid >= 0x0800 (2048), costs {3,4,5,5,5}
            WHEN meritid >= 2048 THEN
                CASE upgrades WHEN 1 THEN 3 WHEN 2 THEN 7 WHEN 3 THEN 12
                              WHEN 4 THEN 17 ELSE 22 END
            -- Others + Group 1 (everything else >= 0x0140), costs {1,2,3,4,5}
            ELSE
                CASE upgrades WHEN 1 THEN 1 WHEN 2 THEN 3 WHEN 3 THEN 6
                              WHEN 4 THEN 10 ELSE 15 END
        END
    ) AS refund_pts
FROM char_merit
WHERE meritid >= 320
GROUP BY charid;

-- Step 2: Refund merit points to char_exp (capped at 255 for tinyint unsigned)
UPDATE char_exp ce
JOIN _merit_repair_refunds r ON r.charid = ce.charid
SET ce.merits = LEAST(255, ce.merits + r.refund_pts);

-- Step 3: Delete all non-generic merit rows
DELETE FROM char_merit WHERE meritid >= 320;

COMMIT;

DROP TEMPORARY TABLE IF EXISTS _merit_repair_refunds;
