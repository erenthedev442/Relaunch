-- ============================================================================
-- dungeon_rescue_stranded_players.sql  --  un-strand dungeon casualties
-- ----------------------------------------------------------------------------
-- Moves ANY character saved inside a Dynamis [D] instance zone back to GM Home
-- (zone 210), at the dungeon system's standard exit-warp spot in front of the
-- Dungeon Master. This is the one-command recovery for the recurring
-- "Player already logged in" login-stranding bug.
--
-- WHY THIS HAPPENS
--   The dungeon system enters its arena with a plain setPos. The [D] instance
--   zones (Dynamis-San_dOria/Bastok/Windurst/Jeuno [D] = 294/295/296/297) only
--   define onInstanceZoneIn, which does NOT reliably eject on a cold LOGIN. If
--   the server restarts or crashes while a player is mid-run, that player's
--   saved pos_zone is the instance. On relog the engine tries to load them
--   back into the dead instance, zone-in never completes, and the map server
--   keeps the half-loaded character registered -> perpetual
--   "Invalid GP_CLI_COMMAND_LOGIN packet from <name>: Player already logged in."
--
--   The dungeons have since been migrated to the NORMAL Dynamis zones
--   (185/186/187/188), which self-heal: their real onZoneIn ejects a
--   sessionless arrival to town via the standard Dynamis eject cutscene. So
--   only the legacy [D] zones (294-297) can strand a player, and only those
--   are rescued here. (See modules/custom/lua/dungeon_catalog.lua, the
--   "Zone history" block on the whispering_halls entry.)
--
-- DESTINATION  matches catalog.exitWarp in dungeon_catalog.lua:
--   zone 210 (GM_Home), pos (-15.000, 0.000, -11.000), rot 128
--   pos_prevzone is also reset to 210 so a "return to previous zone" can never
--   bounce the character straight back into a dead instance.
--
-- SAFE: read-only on everyone NOT stranded (the WHERE clause scopes the write
-- to pos_zone IN (294,295,296,297) only). Idempotent -- once no one is stranded
-- it updates 0 rows. Run it any time; best run while the map server is down (or
-- before the affected player logs in) so the rescued position is what loads.
--
-- Apply:
--   mysql -u root -p xidb < modules/custom/sql/dungeon_rescue_stranded_players.sql
-- ============================================================================

-- 1. Show who is currently stranded (diagnostic; safe no-op if empty).
SELECT `charid`, `charname`, `pos_zone`, `pos_prevzone`
  FROM `chars`
 WHERE `pos_zone` IN (294, 295, 296, 297);

-- 2. Rescue them to GM Home.
UPDATE `chars`
   SET `pos_zone`     = 210,
       `pos_prevzone` = 210,
       `pos_x`        = -15.000,
       `pos_y`        =   0.000,
       `pos_z`        = -11.000,
       `pos_rot`      = 128
 WHERE `pos_zone` IN (294, 295, 296, 297);

-- 3. Confirm none remain (should return an empty set).
SELECT `charid`, `charname`, `pos_zone`
  FROM `chars`
 WHERE `pos_zone` IN (294, 295, 296, 297);
