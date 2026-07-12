-- Idempotent MIGRATION for the community/PWA feature batch (2026-07-06).
-- Adds ONLY the new tables + additive grants. Does NOT create users or touch
-- passwords -- safe to run against the LIVE xi_relaunch without disturbing the
-- existing portal_ro / portal_rw credentials.
CREATE TABLE IF NOT EXISTS xi_relaunch.portal_activity (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, ts INT UNSIGNED NOT NULL,
  charid INT UNSIGNED NOT NULL, charname VARCHAR(15) NOT NULL DEFAULT '',
  kind VARCHAR(24) NOT NULL, detail VARCHAR(255) NOT NULL DEFAULT '', KEY ts (ts), KEY charid (charid)
);
CREATE TABLE IF NOT EXISTS xi_relaunch.portal_snapshot (
  charid INT UNSIGNED NOT NULL PRIMARY KEY, mlvl SMALLINT UNSIGNED DEFAULT 0, kills INT UNSIGNED DEFAULT 0,
  hltier SMALLINT UNSIGNED DEFAULT 0, ascensions INT UNSIGNED DEFAULT 0, nmkills INT UNSIGNED DEFAULT 0,
  maxedjobs SMALLINT UNSIGNED DEFAULT 0, ach_csv TEXT,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS xi_relaunch.portal_push_sub (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, accid INT UNSIGNED NOT NULL,
  endpoint VARCHAR(500) NOT NULL, p256dh VARCHAR(255) DEFAULT '', auth VARCHAR(255) DEFAULT '',
  created DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, UNIQUE KEY endpoint (endpoint(255)), KEY accid (accid)
);
CREATE TABLE IF NOT EXISTS xi_relaunch.portal_ach_seen (
  charid INT UNSIGNED NOT NULL PRIMARY KEY, seen TEXT,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
-- Additive read grants (re-granting the chars/char_history column lists widens them).
GRANT SELECT (charid, accid, charname, nation, playtime, pos_zone, home_zone, gmlevel) ON xi_relaunch.chars TO 'portal_ro'@'localhost';
GRANT SELECT (charid, enemies_defeated, times_knocked_out, battles_fought, spells_cast, abilities_used, ws_used, items_used, distance_travelled) ON xi_relaunch.char_history TO 'portal_ro'@'localhost';
GRANT SELECT (itemId, modId, value) ON xi_relaunch.item_mods TO 'portal_ro'@'localhost';
GRANT SELECT ON xi_relaunch.portal_activity TO 'portal_ro'@'localhost';
-- Write grants for the sampler + push + ack.
GRANT SELECT, INSERT, DELETE ON xi_relaunch.portal_activity TO 'portal_rw'@'localhost';
GRANT SELECT, INSERT, UPDATE ON xi_relaunch.portal_snapshot TO 'portal_rw'@'localhost';
GRANT SELECT, INSERT, DELETE ON xi_relaunch.portal_push_sub TO 'portal_rw'@'localhost';
GRANT SELECT, INSERT, UPDATE ON xi_relaunch.portal_ach_seen TO 'portal_rw'@'localhost';
FLUSH PRIVILEGES;
