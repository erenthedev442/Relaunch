-- ============================================================
-- bst_ready_recast.sql
-- BST "Ready" ability (abilityId 251) gets its own 9-second recast.
--
-- Stock LSB row (sql/abilities.sql):
--   (251,'ready',9,25,1,0,102,...)   -- recastTime=0, recastId=102
-- Sic (abilityId 72) is also in recast group 102 with recastTime=90, so on
-- stock LSB the two SHARE Sic's 90-second cooldown -- Ready follows whatever
-- Sic's shared slot has ticked down to.
--
-- Owner call 2026-07-13: Ready should have its own 9-second recast, decoupled
-- from Sic. Achieved by (a) giving Ready its own recastId (251, matching the
-- ability's own id to keep the mapping obvious) and (b) setting recastTime=9.
-- Sic (72) is untouched -- it keeps its 90-second cooldown on group 102.
--
-- Applies via the modules/custom/sql deploy pipeline (idempotent UPDATE, safe
-- to re-run). Ability recasts are cached at map boot, so a MAP RESTART is
-- required for this to take effect -- every deploy restarts the map, so no
-- extra step on the normal path.
-- ============================================================
UPDATE `abilities`
   SET `recastTime` = 9,
       `recastId`   = 251
 WHERE `abilityId` = 251;
