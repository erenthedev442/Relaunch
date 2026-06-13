-- hunting_league_zone_settings.sql
-- Zone-level settings for the Hunting League zones.
--
-- (1) GM Home (zone 210): set zonetype to DUNGEON (4) so that mob AI
--     initialises properly. Without this, mobs load with no AI and appear
--     passive (no aggro, no TP moves) — effectively NPC-like behaviour.
--
-- (2) Reisenjima Henge (zone 292, the Hunting League hub): add the
--     MISC_PET flag so pet jobs can call their pets here. Upstream LSB
--     ships zone 292 with misc = 2048 (MISC_TRUST only): trusts work but
--     every pet call is blocked, which strands BST/SMN mains in the main
--     progression zone. Adding MISC_PET (0x0080 = 128) brings it to 2176,
--     matching its sibling Reisenjima zones (291 and 293 both already
--     ship at 2176 = MISC_TRUST | MISC_PET). MISC_PET gates BST (Call
--     Beast / Bestial Loyalty / jug items), SMN avatars, PUP automatons,
--     DRG Call Wyvern and GEO luopan — one flag fixes them all.
--
-- ZONE_TYPE flags (zone.h):
--   UNKNOWN   = 0x0000
--   CITY      = 0x0001
--   OUTDOORS  = 0x0002
--   DUNGEON   = 0x0004
--   DYNAMIS   = 0x0080
--   INSTANCED = 0x0100
--
-- ZONEMISC bits (zone.h):
--   MISC_PET   = 0x0080 (128)    <-- (2) enables this bit
--   MISC_TRUST = 0x0800 (2048)
--
-- NOTE: zone_settings is read once at map-server startup, so xi_map must
-- be restarted for these to take effect live (no hot-reload of the misc
-- mask exists).
--
-- To apply:
--   mysql -u root -p your_db_name < modules/custom/sql/hunting_league_zone_settings.sql

UPDATE `zone_settings`
SET    `zonetype` = 4
WHERE  `zoneid`   = 210;

-- Allow pet jobs (BST/SMN/PUP/DRG/GEO) to call pets in the Hunting League
-- hub. Additive | 128 is idempotent and preserves any other flags already
-- on the row (base ships 2048 -> becomes 2176 = MISC_TRUST | MISC_PET).
UPDATE `zone_settings`
SET    `misc`     = `misc` | 128
WHERE  `zoneid`   = 292;
