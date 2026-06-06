-- hunting_league_zone_settings.sql
-- Sets GM Home (zone 210) zonetype to DUNGEON (4) so that mob AI
-- initialises properly. Without this, mobs load with no AI and appear
-- passive (no aggro, no TP moves) — effectively NPC-like behaviour.
--
-- ZONE_TYPE flags (zone.h):
--   UNKNOWN   = 0x0000
--   CITY      = 0x0001
--   OUTDOORS  = 0x0002
--   DUNGEON   = 0x0004
--   DYNAMIS   = 0x0080
--   INSTANCED = 0x0100
--
-- To apply:
--   mysql -u root -p your_db_name < modules/custom/sql/hunting_league_zone_settings.sql

UPDATE `zone_settings`
SET    `zonetype` = 4
WHERE  `zoneid`   = 210;
