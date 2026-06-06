-- ============================================================
-- dungeon_dynamis_jeuno_scrub.sql
-- Wipes the native mob population of Dynamis-Jeuno (zone 188)
-- so the Dungeon System can use it as a clean dungeon arena.
--
-- Why: "The Eternal Throne" (id: eternal_throne) uses this zone.
-- The 85 native Dynamis mob_groups (Goblin Replica, Arch Goblin
-- Golem, Goblin NMs, etc.) would interfere with our spawns.
--
-- What gets deleted:
--   * mob_spawn_points rows in zone 188 mobid range
--     (17547264 .. 17551359), EXCEPT the 18 named Goblin NMs that
--     Dynamis-Jeuno/IDs.lua looks up via GetFirstID(). Those 18
--     are preserved by groupid (list below).
--   * mob_groups rows with zoneid = 188, same exclusion list.
--
-- WHY the exclusion: IDs.lua calls GetFirstID('Gabblox_Magpietongue')
-- etc. at zone-load time (server startup). Deleting those rows
-- causes the server to log a GetFirstID() nil-reference error for
-- each missing mob every time the zone is initialized. Keeping the
-- 18 mob_groups (and their spawn rows) silences those errors.
-- The 18 named NMs do NOT auto-spawn without an active Dynamis
-- session — their mob_groups are queried by the Dynamis system
-- only after xi.dynamis.zoneOnZoneIn activates the session, which
-- our override prevents for dungeon runners. Keeping them costs
-- zero gameplay impact.
--
-- Preserved groupids (zone 188 named Goblin NMs):
--   11 = Gabblox_Magpietongue,  21 = Tufflix_Loglimbs,
--   27 = Hermitrix_Toothrot,    28 = Wyrmwix_Snakespecs,
--   40 = Rutrix_Hamgams,        42 = Anvilix_Sootwrists,
--   43 = Bootrix_Jaggedelbow,   44 = Mobpix_Mucousmouth,
--   45 = Distilix_Stickytoes,   46 = Eremix_Snottynostril,
--   47 = Jabbrox_Grannyguise,   48 = Scruffix_Shaggychest,
--   49 = Blazox_Boneybod,       50 = Prowlox_Barrelbelly,
--   51 = Cloktix_Longnail,      52 = Mortilox_Wartpaws,
--   53 = Slystix_Megapeepers,   54 = Tymexox_Ninefingers
--
-- Consequences (acknowledge before applying):
--   * Dynamis-Jeuno will be effectively empty (the 18 preserved NMs
--     won't auto-spawn outside a Dynamis session). Dynamis quest
--     system for this zone will not function.
--   * On this server, Dynamis content is not active.
--
-- Reversibility:
--   * Re-run sql/mob_spawn_points.sql and sql/mob_groups.sql.
--   * Idempotent — safe to apply twice.
--
-- To apply:
--   mysql -u root -p xidb < modules/custom/sql/dungeon_dynamis_jeuno_scrub.sql
-- ============================================================

DELETE FROM `mob_spawn_points`
 WHERE `mobid`   BETWEEN 17547264 AND 17551359
   AND `groupid` NOT IN (11, 21, 27, 28, 40, 42, 43, 44, 45, 46,
                          47, 48, 49, 50, 51, 52, 53, 54);

DELETE FROM `mob_groups`
 WHERE `zoneid`  = 188
   AND `groupid` NOT IN (11, 21, 27, 28, 40, 42, 43, 44, 45, 46,
                          47, 48, 49, 50, 51, 52, 53, 54);
