-- reforge_zone_settings.sql
-- Zone-level QoL for Diorama Abdhaljs-Ghelsba (zone 43) -- the hub/arena where
-- the Reforge spawner stations + vendor NPCs live (!reforged ->
-- xi.zone.DIORAMA_ABDHALJS_GHELSBA; see modules/custom/lua/Reforge_System.lua).
--
-- Upstream LSB ships zone 43 (an otherwise-empty diorama) at misc = 152, which
-- is MISC_PET (0x80=128) | MISC_TREASURE (0x10=16) | MISC_MOGMENU (0x08=8).
-- FJB repurposes it as a player-facing Reforge hub, so it needs the same
-- convenience flags as the other custom hubs: TRUST (party self-sufficiency)
-- and AH (browse/sell between pops). MISC_PET is already set, so BST/SMN/PUP/
-- DRG pets and GEO luopan spells already work here.
--
-- ZONEMISC bits (src/map/zone.h):
--   MISC_PET   = 0x0080 (128)   <-- already set on zone 43
--   MISC_AH    = 0x0200 (512)   <-- this row OR's this bit on
--   MISC_TRUST = 0x0800 (2048)  <-- this row OR's this bit on
--
-- Additive `| 2560` (=512|2048) is idempotent and preserves the live PET flag
-- (re-running is a no-op once both bits are set). 152 | 2560 = 2712.
--
-- NOTE: zone_settings is read ONCE at map-server startup, so xi_map must be
-- RESTARTED for this to take effect (no hot-reload of the misc mask exists).
--
-- To apply:
--   sudo mysql xi_relaunch < modules/custom/sql/reforge_zone_settings.sql
--   (then restart xi_map)

UPDATE `zone_settings`
SET    `misc`   = `misc` | 2560
WHERE  `zoneid` = 43;
