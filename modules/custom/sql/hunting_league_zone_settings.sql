-- hunting_league_zone_settings.sql
-- Zone-level settings for the Hunting League / Reisenjima zones.
--
-- (1) GM Home (zone 210): set zonetype to DUNGEON (4) so that mob AI
--     initialises properly. Without this, mobs load with no AI and appear
--     passive (no aggro, no TP moves) — effectively NPC-like behaviour.
--
-- (2) Reisenjima zones (292 Henge / 291 Reisenjima / 293 Sanctorium):
--     assert the MISC_PET flag so pet jobs work here. Upstream LSB ships
--     Henge (292) with misc = 2048 (MISC_TRUST only) -- trusts work but
--     every pet call is blocked, stranding pet jobs in the main
--     progression zone. MISC_PET (0x0080 = 128) gates BST (Call Beast /
--     Bestial Loyalty / jug items), SMN avatars, PUP automatons, DRG Call
--     Wyvern AND GEO Geo- spells -- each Geo- spell summons a luopan PET,
--     so without this bit they fail with "Cannot be used in this area"
--     (scripts/globals/job_utils/geomancer.lua geoOnMagicCastingCheck ->
--     CANT_BE_USED_IN_AREA). GEO Indi- spells are NOT gated and work
--     regardless. 291 and 293 already ship at 2176 (TRUST | PET); we OR
--     the bit on all three idempotently so pets/luopan work across every
--     Reisenjima zone even if the live DB drifted from the SQL source.
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

-- Allow pet jobs (BST/SMN/PUP/DRG + GEO luopan) to use pets across ALL
-- Reisenjima zones. Additive | 128 is idempotent: it sets MISC_PET and
-- preserves existing flags (Henge 2048 -> 2176; 291/293 already 2176 ->
-- no-op). GEO's Geo- spells summon a luopan, so they need this bit too;
-- Indi- spells don't.
UPDATE `zone_settings`
SET    `misc`     = `misc` | 128
WHERE  `zoneid`   IN (291, 292, 293);
