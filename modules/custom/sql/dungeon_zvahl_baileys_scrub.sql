-- ============================================================
-- dungeon_zvahl_baileys_scrub.sql
-- Wipes the native mob population of Castle Zvahl Baileys (zone
-- 161) so the Dungeon System can use it as a clean dungeon space.
--
-- Why: the Dungeon System's "The Outer Bastion" entry uses this
-- zone as its arena. We dynamically spawn our own mobs via
-- `insertDynamicEntity` with our own HL groupIds (11355..11369);
-- the vanilla zone population (270 spawn_points across 49 mob_groups
-- — Demon Pawns, Dark Knights, Goblin patrols, Orcish raiders,
-- Quadav/Yagudo squads, Marquis NMs, etc.) would compete for AI
-- ticks, generate background combat, and just generally make the
-- "you walked into an empty fortress" feel impossible.
--
-- What gets deleted:
--   1. mob_spawn_points rows in zone 161's mobid range
--      (17436672 .. 17440767), EXCEPT the 9 SCRIPTED/LOTTERY
--      mobs that the vanilla zone IDs.lua looks up via
--      GetFirstID(name). Those 9 are preserved by groupid:
--        7 = Likho, 37 = Marquis_Sabnock, 42 = Marquis_Allocen,
--        44 = Marquis_Amon, 45 = Duke_Haborym,
--        46 = Grand_Duke_Batym, 48 = Dark_Spark,
--        49 = Mimic, 50 = Marquis_Andrealphus.
--      All 9 have respawntime=0 + spawntype=128 or 32, meaning
--      they're already dormant in normal play — they don't show
--      up unless a Garrison BCNM or quest event triggers them.
--   2. mob_groups rows with zoneid = 161, same exclusion list.
--
-- WHY the exclusion: the very first apply of this scrub (without
-- exclusions) caused the map server to log:
--   [error] GetFirstID(Marquis_Sabnock) in zone Castle_Zvahl_Baileys:
--           Returning nil
-- once per missing mob, repeatedly. Those mobs never spawned
-- visibly so the dungeon worked fine, but the log noise was bad
-- enough to drown out everything else. Preserving the 9 group
-- definitions costs zero gameplay impact and silences the logs.
--
-- Consequences (acknowledge these before applying):
--   * The Castle Zvahl Baileys outer-castle BCNMs that hook off
--     OTHER mob_groups (Demon Pawn / Goblin / Quadav / Yagudo
--     patrols, the 29 active groups) will not function on this
--     server. On Legendary this is acceptable — the server's
--     progression runs through HL / Reforge / Dungeons rather
--     than vanilla CoP/Zilart BCNMs.
--   * The Bibiki Bay / Tonberry / Demon population that normally
--     patrols the castle approach is gone. Anyone visiting the
--     zone for sightseeing will see an empty fortress (which is
--     the point — that's what makes it a dungeon arena).
--
-- Reversibility:
--   * Re-run the vanilla `sql/mob_spawn_points.sql` and
--     `sql/mob_groups.sql` files to restore the native population.
--   * This file is idempotent on its own — running it twice does
--     nothing the second time (the rows are already gone).
--
-- To apply (run once after committing to the dungeon swap):
--   mysql -u root -p your_db_name < modules/custom/sql/dungeon_zvahl_baileys_scrub.sql
--
-- Pattern lifted from:
--   modules/custom/sql/hunting_league_gm_home_mobs.sql
--   modules/custom/sql/rakaznar_inner_court_5x.sql
-- ============================================================

-- Wipe the active patrols. The 9 IDs.lua-referenced mobs
-- (groupids 7, 37, 42, 44, 45, 46, 48, 49, 50) are spared
-- so GetFirstID() can still resolve them — they don't spawn
-- naturally anyway (respawntime=0 + scripted/lottery spawntype),
-- so keeping them costs zero gameplay impact.
DELETE FROM `mob_spawn_points`
 WHERE `mobid`   BETWEEN 17436672 AND 17440767
   AND `groupid` NOT IN (7, 37, 42, 44, 45, 46, 48, 49, 50);

DELETE FROM `mob_groups`
 WHERE `zoneid`  = 161
   AND `groupid` NOT IN (7, 37, 42, 44, 45, 46, 48, 49, 50);
