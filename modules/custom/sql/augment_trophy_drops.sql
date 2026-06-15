-- =====================================================================
-- augment_trophy_drops.sql
-- Wires up augment-system NM trophy items that were defined in the
-- catalogs (augment_affinity_catalog.lua / augment_sage_catalog.lua) but
-- were never added to any droplist, so the turn-ins were unobtainable.
--
-- Idempotent (DELETE-then-INSERT, safe to re-run). Needs a MAP RESTART to
-- take effect -- droplists are loaded into mob data at server startup.
-- =====================================================================

-- Emperor Arthro's Shell (8983) -> King Arthro, Jugner Forest (dropId 1449)
--   augment_affinity_catalog.lua -- Dexterity / Accuracy affinity trophy. 100%.
DELETE FROM mob_droplist WHERE dropId = 1449 AND itemId = 8983;
INSERT INTO mob_droplist (dropId, dropType, groupId, groupRate, itemId, itemRate)
VALUES (1449, 0, 0, 1000, 8983, 1000);

-- Fafnir's Scale (10037) -> Fafnir, Dragon's Aery (dropId 805)
--   augment_sage_catalog.lua -- Augment Sage rank 4 trophy. 100%.
DELETE FROM mob_droplist WHERE dropId = 805 AND itemId = 10037;
INSERT INTO mob_droplist (dropId, dropType, groupId, groupRate, itemId, itemRate)
VALUES (805, 0, 0, 1000, 10037, 1000);

-- Kirin's Mane (10038) -> Kirin, Ru'Avitau / GM Home / Reisenjima (dropId 2819)
--   augment_sage_catalog.lua -- Augment Sage rank 5 trophy. 100%.
DELETE FROM mob_droplist WHERE dropId = 2819 AND itemId = 10038;
INSERT INTO mob_droplist (dropId, dropType, groupId, groupRate, itemId, itemRate)
VALUES (2819, 0, 0, 1000, 10038, 1000);
