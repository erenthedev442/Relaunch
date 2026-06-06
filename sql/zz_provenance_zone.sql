-- ---------------------------------------------------------------------------
-- zz_provenance_zone.sql
--
-- Provenance (zone 222) is repurposed on FJB as a player-facing hub, so players
-- need full quality-of-life there. We OR extra ZONEMISC bits into
-- zone_settings.misc (bits defined in src/map/zone.h):
--   MISC_TRUST = 0x0800 (2048)  - call Trust NPCs (the original hub need)
--   MISC_PET   = 0x0080 (128)   - summon pets: Call Wyvern (DRG), avatars (SMN),
--                                 Call Beast (BST), automatons (PUP)
--
-- Without MISC_PET, abilityCheckCallWyvern (scripts/globals/job_utils/dragoon.lua)
-- hits `not player:canUseMisc(xi.zoneMisc.PET)` and returns CANT_BE_USED_IN_AREA,
-- so a Dragoon can't summon its wyvern in the hub.
--
-- Upstream ships zone 222 with misc = 4096 (MISC_LOS_PLAYER_BLOCK). The OR
-- preserves that bit and is idempotent (safe to re-run): 4096|2048|128 = 6272.
--
-- Placement: zz_ prefix in sql/ makes this load AFTER sql/zone_settings.sql
-- (which DROPs + recreates the table). The previous file,
-- modules/custom/sql/provenance_zone_settings.sql, sorted BEFORE zone_settings
-- .sql, so a full `dbtool update full` wiped its bit -- this file supersedes it.
-- zone_settings are read once at map-server startup, so a map RESTART is
-- required for this to take effect in-game.
-- ---------------------------------------------------------------------------

UPDATE `zone_settings`
SET    `misc` = `misc` | 2048 | 128
WHERE  `zoneid` = 222;
