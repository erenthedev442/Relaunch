-- hub_zone_settings.sql
-- Zone-level settings for the !hub (Abdhaljs Isle-Purgonorgo, zone 44).
--
-- MISC_MOGMENU (0x20 = 32): required for the hub's Nomad Moogle
-- (modules/custom/lua/nomad_moogle.lua) to actually WORK. The NPC's
-- sendMenu(MOOGLE) opens the client menu regardless, but the map server
-- validates each selection against the zone's misc flags:
--   - job change (c2s 0x100_myroom_job): requires MISC_MOGMENU (or being
--     inside your own Mog House)
--   - Delivery Box (c2s 0x04d_pbx): requires MISC_MOGMENU or MISC_AH
-- Without this bit the menu opens but every action is silently rejected.
--
-- `misc | 32` is idempotent and preserves the zone's existing flags
-- (including the global MISC_AH bit from ah_anywhere_zone_settings.sql).
--
-- NOTE: zone_settings is read once at map-server startup, so xi_map must
-- be restarted for this to take effect (no hot-reload of the misc mask).

UPDATE `zone_settings`
SET    `misc`   = `misc` | 32
WHERE  `zoneid` = 44;
