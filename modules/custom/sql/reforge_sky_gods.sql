-- ============================================================================
-- reforge_sky_gods.sql
-- DEPRECATED: superseded by reforge_nms.sql (broader scope: also includes
-- Unity NMs + Abyssea NMs as Relic / Empyrean Mark sources).
--
-- Re-applying this file does nothing (the DELETE+INSERT is now empty).
-- Kept as a no-op so old DBs that already imported these rows can re-run
-- without errors; the active rows are owned by reforge_nms.sql now.
-- ============================================================================

DELETE FROM `mob_groups` WHERE `groupid` BETWEEN 11400 AND 11404;
-- (rows moved to reforge_nms.sql)
