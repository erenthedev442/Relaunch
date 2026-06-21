-- =============================================================================
-- oneoff_cleanup_jbae_judge_dupes.sql   (RUN BY HAND ONLY -- never auto-applied)
--
-- Removes duplicate Judge gear from player Jbae, keeping exactly ONE set.
-- Cleans up the damage from zz_grant_judge_gear_jbae.sql, which re-ran every
-- deploy and appended a fresh 13-piece set each time (found 7 sets / inv 159).
--
-- Lives in tools/ on purpose: tools/*.sql is NOT in the deploy auto-apply globs
-- (sql/*.sql + modules/custom/sql/*.sql), so this can never re-run on a deploy.
--
-- *** RUN ONLY WHILE JBAE IS OFFLINE ***  Live-DB inventory edits to an online
-- char are overwritten by the server's char-save on logout. Verify first:
--   SELECT COUNT(*) FROM accounts_sessions
--   WHERE charid = (SELECT charid FROM chars WHERE charname='Jbae');   -- must be 0
--
-- Equipped-safe (never deletes a char_equip-referenced slot) and idempotent
-- (re-running always converges to one set: 1 of each piece + 2 earrings + 2 rings).
-- =============================================================================

SET @jbae = (SELECT charid FROM chars WHERE charname='Jbae' LIMIT 1);

DROP TEMPORARY TABLE IF EXISTS _jbae_keep;
CREATE TEMPORARY TABLE _jbae_keep (slot INT PRIMARY KEY);

-- Keep target copies per itemId (2 for earring 13358 + ring 13505, else 1),
-- preferring equipped slots, then lowest slot.
INSERT INTO _jbae_keep (slot)
SELECT slot FROM (
    SELECT ci.slot,
           ROW_NUMBER() OVER (
               PARTITION BY ci.itemId
               ORDER BY (ce.slotid IS NOT NULL) DESC, ci.slot
           ) AS rn,
           CASE WHEN ci.itemId IN (13358, 13505) THEN 2 ELSE 1 END AS keep_n
    FROM char_inventory ci
    LEFT JOIN char_equip ce
      ON ce.charid = ci.charid AND ce.containerid = ci.location AND ce.slotid = ci.slot
    WHERE ci.charid = @jbae AND ci.location = 0
      AND ci.itemId IN (12523,12551,12679,12807,12935,13074,13215,13358,13505,13606,12332)
) t
WHERE rn <= keep_n;

-- Safety net: always keep any equipped Judge slot, regardless of the above.
INSERT IGNORE INTO _jbae_keep (slot)
SELECT ci.slot
FROM char_inventory ci
JOIN char_equip ce
  ON ce.charid = ci.charid AND ce.containerid = ci.location AND ce.slotid = ci.slot
WHERE ci.charid = @jbae AND ci.location = 0
  AND ci.itemId IN (12523,12551,12679,12807,12935,13074,13215,13358,13505,13606,12332);

-- Delete every Judge copy that is NOT in the keep list.
DELETE ci FROM char_inventory ci
WHERE ci.charid = @jbae AND ci.location = 0
  AND ci.itemId IN (12523,12551,12679,12807,12935,13074,13215,13358,13505,13606,12332)
  AND ci.slot NOT IN (SELECT slot FROM _jbae_keep);

DROP TEMPORARY TABLE IF EXISTS _jbae_keep;
