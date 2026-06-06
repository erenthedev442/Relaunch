-- reforge_zone_settings.sql
-- Enable trust casting in Gwora-Corridor (zone 278), the hub zone where
-- the Reforged vendor NPC lives (see modules/custom/lua/Reforge_System.lua,
-- catalog.huntZoneId = xi.zone.GWORA_CORRIDOR).
--
-- Upstream LSB ships zone 278 with misc=0 (no QoL flags) because retail
-- FFXI doesn't allow trusts inside the Walk of Echoes corridor. FJB
-- repurposes it as a player-facing vendor hub, so players need to be
-- able to call trusts the same as in Reisenjima Henge (zone 292, the
-- Hunting League hub, which upstream ships with misc=2048).
--
-- ZONEMISC bits (src/map/zone.h):
--   MISC_ESCAPE  = 0x0001  (1)     Escape spell
--   MISC_FELLOW  = 0x0002  (2)     Fellow NPC
--   MISC_MOUNT   = 0x0004  (4)     Chocobos / mounts
--   MISC_MAZURKA = 0x0008  (8)
--   MISC_TRACTOR = 0x0010  (16)
--   MISC_MOGMENU = 0x0020  (32)
--   MISC_COSTUME = 0x0040  (64)
--   MISC_PET     = 0x0080  (128)
--   MISC_TREASURE= 0x0100  (256)
--   MISC_AH      = 0x0200  (512)
--   MISC_YELL    = 0x0400  (1024)
--   MISC_TRUST   = 0x0800  (2048)  <-- this row enables this bit
--
-- If you later want full hub-zone QoL (mounts, AH, yell, etc.), use
-- misc = 4095 (all 12 bits, the GM_Home pattern).
--
-- To apply (zone settings load at map-server startup, so a restart is
-- required for this to take effect):
--   mysql -u root -p your_db_name < modules/custom/sql/reforge_zone_settings.sql

UPDATE `zone_settings`
SET    `misc`   = 2048
WHERE  `zoneid` = 278;
