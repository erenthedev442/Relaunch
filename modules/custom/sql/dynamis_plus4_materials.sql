-- ============================================================================
-- Dynamis - Divergence [D] -- +4 Reforge Forge materials (relaunch, ADDITIVE)
-- ----------------------------------------------------------------------------
-- Adds the ID-card drops that feed the +4 Reforge Forge (Dynamis_Plus4_Forge.lua)
-- to the existing [D] mobs. This file is ADDITIVE and self-contained -- it does
-- NOT edit dynamis_divergence.sql. It hangs extra item rows on that file's own
-- custom dropIds (294xx-297xx), which already carry the medal drops.
--
--   Rusted ID Card  (9538)  -> every WAVE-TRASH dropId  (wave 1 + wave 2), @COMMON
--   Black  ID Card  (9540)  -> every BOSS dropId        (mid-boss + mega-boss), @UNCOMMON
--
-- The job-matched Paragon Card is NOT a droplist row (it depends on the killer's
-- job); the forge module drops it from the 4 mega-bosses via onMobDeathEx.
--
-- dropId roles (from dynamis_divergence.sql mob_groups):
--     x9401 = mid-boss     x9402 = wave 1 trash
--     x9403 = wave 2 trash x9404 = mega-boss
--   San d'Oria 294xx | Bastok 295xx | Windurst 296xx | Jeuno 297xx
--
-- IDEMPOTENT: re-runnable. We DELETE only our own (dropId,item) rows for 9538/9540
-- on these dropIds before re-inserting, so we never stack duplicates and never
-- touch the medal rows the divergence file owns. NOT a one-time migration.
-- ============================================================================

-- Drop-rate helper vars (mirror dynamis_divergence.sql / sql/mob_droplist.sql).
SET @COMMON   = 150;
SET @UNCOMMON = 100;

-- Clean up only THIS file's rows (Rusted/Black on the [D] dropIds) so re-runs
-- are idempotent without disturbing the medal drops on the same dropIds.
DELETE FROM `mob_droplist`
 WHERE `itemId` IN (9538, 9540)
   AND `dropId` IN (
        29401, 29402, 29403, 29404,   -- San d'Oria [D]
        29501, 29502, 29503, 29504,   -- Bastok    [D]
        29601, 29602, 29603, 29604,   -- Windurst  [D]
        29701, 29702, 29703, 29704    -- Jeuno     [D]
   );

-- ----------------------------------------------------------------------------
-- Rusted Identification Card (9538) on WAVE-TRASH dropIds (wave 1 + wave 2).
-- mob_droplist: (dropId, dropType, groupId, groupRate, itemId, itemRate)
-- ----------------------------------------------------------------------------
-- San d'Oria [D]
INSERT INTO `mob_droplist` VALUES (29402, 0, 0, 1000, 9538, @COMMON); -- Wave 1 trash
INSERT INTO `mob_droplist` VALUES (29403, 0, 0, 1000, 9538, @COMMON); -- Wave 2 trash
-- Bastok [D]
INSERT INTO `mob_droplist` VALUES (29502, 0, 0, 1000, 9538, @COMMON); -- Wave 1 trash
INSERT INTO `mob_droplist` VALUES (29503, 0, 0, 1000, 9538, @COMMON); -- Wave 2 trash
-- Windurst [D]
INSERT INTO `mob_droplist` VALUES (29602, 0, 0, 1000, 9538, @COMMON); -- Wave 1 trash
INSERT INTO `mob_droplist` VALUES (29603, 0, 0, 1000, 9538, @COMMON); -- Wave 2 trash
-- Jeuno [D]
INSERT INTO `mob_droplist` VALUES (29702, 0, 0, 1000, 9538, @COMMON); -- Wave 1 trash
INSERT INTO `mob_droplist` VALUES (29703, 0, 0, 1000, 9538, @COMMON); -- Wave 2 trash

-- ----------------------------------------------------------------------------
-- Blackened Identification Card (9540) on BOSS dropIds (mid-boss + mega-boss).
-- ----------------------------------------------------------------------------
-- San d'Oria [D]
INSERT INTO `mob_droplist` VALUES (29401, 0, 0, 1000, 9540, @UNCOMMON); -- Mid-boss
INSERT INTO `mob_droplist` VALUES (29404, 0, 0, 1000, 9540, @UNCOMMON); -- Mega-boss (Halphas)
-- Bastok [D]
INSERT INTO `mob_droplist` VALUES (29501, 0, 0, 1000, 9540, @UNCOMMON); -- Mid-boss
INSERT INTO `mob_droplist` VALUES (29504, 0, 0, 1000, 9540, @UNCOMMON); -- Mega-boss (Ka'Rho Fearsinger)
-- Windurst [D]
INSERT INTO `mob_droplist` VALUES (29601, 0, 0, 1000, 9540, @UNCOMMON); -- Mid-boss
INSERT INTO `mob_droplist` VALUES (29604, 0, 0, 1000, 9540, @UNCOMMON); -- Mega-boss (Fii Pexu the Eternal)
-- Jeuno [D]
INSERT INTO `mob_droplist` VALUES (29701, 0, 0, 1000, 9540, @UNCOMMON); -- Mid-boss
INSERT INTO `mob_droplist` VALUES (29704, 0, 0, 1000, 9540, @UNCOMMON); -- Mega-boss (Obstatrix)
