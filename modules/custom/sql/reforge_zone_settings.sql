-- reforge_zone_settings.sql
-- Zone-level QoL for Gwora-Corridor (zone 278) -- the hub/arena where the
-- Reforge spawner + vendor NPCs live (!reforged -> xi.zone.GWORA_CORRIDOR;
-- see modules/custom/lua/Reforge_System.lua).
--
-- Upstream LSB ships zone 278 (a Walk of Echoes corridor) with no QoL flags.
-- FJB repurposes it as a player-facing Reforge hub, so it needs the same
-- flags as the Hunting League hub (Reisenjima, zones 291-293, which run at
-- misc = 2688 = TRUST | AH | PET).
--
-- BUG (reported 2026-06-18): "GEO spells unable to use in !reforged" + "unable
-- to call my Wyvern in that area" -- same symptom the Hunting League arena had.
-- Root cause: zone 278 was live at misc = 2560 (TRUST 0x0800 | AH 0x0200) but
-- MISSING MISC_PET (0x0080 = 128). Every pet call is gated by MISC_PET --
-- BST Call Beast, SMN avatars, PUP automatons, DRG Call Wyvern, AND each GEO
-- Geo- spell (which summons a luopan PET -> blocked with "Cannot be used in
-- this area"; GEO Indi- spells are NOT gated). OR'ing the PET bit on takes
-- 2560 -> 2688, matching the working Reisenjima zones.
--
-- ZONEMISC bits (src/map/zone.h):
--   MISC_PET   = 0x0080 (128)    <-- this row OR's this bit on
--   MISC_AH    = 0x0200 (512)
--   MISC_TRUST = 0x0800 (2048)
--
-- Additive `| 128` is idempotent and preserves the live TRUST | AH flags
-- (re-running is a no-op once PET is set). The previous version of this file
-- used `SET misc = 2048`, which dropped the AH bit AND never added PET.
--
-- NOTE: zone_settings is read ONCE at map-server startup, so xi_map must be
-- RESTARTED for this to take effect (no hot-reload of the misc mask exists).
--
-- To apply:
--   sudo mysql xidb < modules/custom/sql/reforge_zone_settings.sql
--   (then restart xi_map)

UPDATE `zone_settings`
SET    `misc`   = `misc` | 128
WHERE  `zoneid` = 278;
