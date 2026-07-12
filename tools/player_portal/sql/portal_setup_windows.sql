-- =====================================================================
-- Player Portal DB setup -- OVH VPS (Windows), co-located with xi_relaunch.
-- =====================================================================
-- This is the standalone SQL equivalent of deploy/setup_portal.sh's DB step,
-- for the VPS where the portal runs ON THE SAME MACHINE as MariaDB (so it
-- connects over TCP to 127.0.0.1 and the users are scoped to '127.0.0.1').
--
-- Run it ONCE on the VPS as a DB admin (root), against the relaunch DB:
--   mysql -h 127.0.0.1 -u root -p xi_relaunch < portal_setup_windows.sql
--
-- >>> BEFORE RUNNING: replace the two CHANGE_ME passwords below, and put the
--     SAME values in the portal's .env (PORTAL_DB_PASS / PORTAL_DB_WRITE_PASS).
--
-- Idempotent (IF NOT EXISTS) -- safe to re-run. Grants are scoped to exactly
-- the columns the portal reads/writes; the users can touch nothing else.
--
-- NOTE on host matching: the app connects via TCP to 127.0.0.1, but with MariaDB's
-- default name resolution (skip-name-resolve OFF) that connection authenticates as
-- user@'localhost' -- so the accounts MUST be '@localhost' or you get
-- "Access denied for user 'portal_ro'@'localhost'" (this bit us live 2026-07-06).
-- Only switch these to '127.0.0.1' if you enable skip-name-resolve on MariaDB.
-- =====================================================================

-- ---- Recoverable trash log (discard copies the full row here first) --------
CREATE TABLE IF NOT EXISTS xi_relaunch.portal_item_log (
  id        BIGINT UNSIGNED   NOT NULL AUTO_INCREMENT PRIMARY KEY,
  ts        DATETIME          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  charid    INT UNSIGNED      NOT NULL,
  accid     INT UNSIGNED      NOT NULL,
  itemId    SMALLINT UNSIGNED NOT NULL,
  quantity  INT UNSIGNED      NOT NULL,
  fromLoc   TINYINT UNSIGNED  NOT NULL,
  fromSlot  TINYINT UNSIGNED  NOT NULL,
  signature VARCHAR(20)       NOT NULL DEFAULT '',
  extra     TINYBLOB,
  KEY charid (charid), KEY ts (ts)
);

-- ---- Offline vault (items stored outside the game's containers) ------------
CREATE TABLE IF NOT EXISTS xi_relaunch.portal_vault (
  id           BIGINT UNSIGNED   NOT NULL AUTO_INCREMENT PRIMARY KEY,
  charid       INT UNSIGNED      NOT NULL,
  accid        INT UNSIGNED      NOT NULL,
  itemId       SMALLINT UNSIGNED NOT NULL,
  quantity     INT UNSIGNED      NOT NULL,
  signature    VARCHAR(20)       NOT NULL DEFAULT '',
  extra        TINYBLOB,
  deposited_at DATETIME          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY charid (charid)
);

-- ---- Player-chosen profile cosmetics (title / accent / featured / showcase) -
CREATE TABLE IF NOT EXISTS xi_relaunch.portal_profile (
  charid     INT UNSIGNED NOT NULL PRIMARY KEY,
  title      VARCHAR(48)  NOT NULL DEFAULT '',
  accent     VARCHAR(16)  NOT NULL DEFAULT 'gold',
  featured   VARCHAR(32)  NOT NULL DEFAULT '',
  showcase   VARCHAR(64)  NOT NULL DEFAULT '',
  updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ---- Live activity feed (the sampler diffs char state into timestamped rows) -
CREATE TABLE IF NOT EXISTS xi_relaunch.portal_activity (
  id       BIGINT UNSIGNED   NOT NULL AUTO_INCREMENT PRIMARY KEY,
  ts       INT UNSIGNED      NOT NULL,
  charid   INT UNSIGNED      NOT NULL,
  charname VARCHAR(15)       NOT NULL DEFAULT '',
  kind     VARCHAR(24)       NOT NULL,
  detail   VARCHAR(255)      NOT NULL DEFAULT '',
  KEY ts (ts), KEY charid (charid)
);

-- ---- Sampler's last-known per-character snapshot (the diff source) ----------
CREATE TABLE IF NOT EXISTS xi_relaunch.portal_snapshot (
  charid     INT UNSIGNED      NOT NULL PRIMARY KEY,
  mlvl       SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  kills      INT UNSIGNED      NOT NULL DEFAULT 0,
  hltier     SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  ascensions INT UNSIGNED      NOT NULL DEFAULT 0,
  nmkills    INT UNSIGNED      NOT NULL DEFAULT 0,
  maxedjobs  SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  ach_csv    TEXT,
  updated_at DATETIME          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ---- Web-push subscriptions (one row per installed browser) ----------------
CREATE TABLE IF NOT EXISTS xi_relaunch.portal_push_sub (
  id       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  accid    INT UNSIGNED    NOT NULL,
  endpoint VARCHAR(500)    NOT NULL,
  p256dh   VARCHAR(255)    NOT NULL DEFAULT '',
  auth     VARCHAR(255)    NOT NULL DEFAULT '',
  created  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY endpoint (endpoint(255)), KEY accid (accid)
);

-- ---- Which achievements a player has acknowledged (unlock "moments") --------
CREATE TABLE IF NOT EXISTS xi_relaunch.portal_ach_seen (
  charid     INT UNSIGNED NOT NULL PRIMARY KEY,
  seen       TEXT,
  updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ---- READ-ONLY user (portal_ro) -- everything /api/me & inventory reads -----
CREATE USER IF NOT EXISTS 'portal_ro'@'localhost' IDENTIFIED BY 'CHANGE_ME_read_password';
GRANT SELECT (id, login, password, current_email, timecreate)                ON xi_relaunch.accounts         TO 'portal_ro'@'localhost';
GRANT SELECT (charid, accid, charname, nation, playtime, pos_zone, home_zone, gmlevel) ON xi_relaunch.chars    TO 'portal_ro'@'localhost';
GRANT SELECT (charid, mjob, sjob, mlvl, slvl, hp, mp)                         ON xi_relaunch.char_stats       TO 'portal_ro'@'localhost';
GRANT SELECT (charid, location, slot, itemId, quantity, bazaar)              ON xi_relaunch.char_inventory   TO 'portal_ro'@'localhost';
GRANT SELECT (charid, enemies_defeated, times_knocked_out, battles_fought, spells_cast, abilities_used, ws_used, items_used, distance_travelled) ON xi_relaunch.char_history TO 'portal_ro'@'localhost';
GRANT SELECT (charid, varname, value)                                        ON xi_relaunch.char_vars        TO 'portal_ro'@'localhost';
GRANT SELECT (charid, containerid, slotid)                                   ON xi_relaunch.char_equip       TO 'portal_ro'@'localhost';
GRANT SELECT (charid, face, race, size)                                       ON xi_relaunch.char_look        TO 'portal_ro'@'localhost';
GRANT SELECT (itemid, name)                                                   ON xi_relaunch.item_basic       TO 'portal_ro'@'localhost';
GRANT SELECT (zoneid, name)                                                   ON xi_relaunch.zone_settings    TO 'portal_ro'@'localhost';
GRANT SELECT ON xi_relaunch.char_jobs          TO 'portal_ro'@'localhost';
GRANT SELECT ON xi_relaunch.char_storage       TO 'portal_ro'@'localhost';
GRANT SELECT ON xi_relaunch.accounts_sessions  TO 'portal_ro'@'localhost';
GRANT SELECT ON xi_relaunch.portal_vault       TO 'portal_ro'@'localhost';
GRANT SELECT (charid, title, accent, featured, showcase) ON xi_relaunch.portal_profile TO 'portal_ro'@'localhost';
GRANT SELECT (name, value) ON xi_relaunch.server_variables TO 'portal_ro'@'localhost';   -- live events board reads [WB]* / [Inv]* schedule state
GRANT SELECT (extra) ON xi_relaunch.char_inventory TO 'portal_ro'@'localhost';           -- gear page: augment-presence detection
GRANT SELECT (priv) ON xi_relaunch.accounts TO 'portal_ro'@'localhost';                  -- admin dashboard gate (accounts.priv = GM level)
GRANT SELECT (itemid, stack, seller_name, price, buyer_name, sale, sell_date) ON xi_relaunch.auction_house TO 'portal_ro'@'localhost';  -- AH price-check + trends
GRANT SELECT (itemId, modId, value) ON xi_relaunch.item_mods TO 'portal_ro'@'localhost';  -- gear set builder: real item stats
GRANT SELECT ON xi_relaunch.portal_activity TO 'portal_ro'@'localhost';                    -- live activity feed

-- ---- WRITE user (portal_rw) -- only what offline move/discard/vault need ----
CREATE USER IF NOT EXISTS 'portal_rw'@'localhost' IDENTIFIED BY 'CHANGE_ME_write_password';
GRANT SELECT, INSERT, UPDATE, DELETE ON xi_relaunch.char_inventory   TO 'portal_rw'@'localhost';
GRANT INSERT                 ON xi_relaunch.portal_item_log   TO 'portal_rw'@'localhost';
GRANT SELECT, INSERT, DELETE ON xi_relaunch.portal_vault      TO 'portal_rw'@'localhost';
GRANT SELECT                 ON xi_relaunch.accounts_sessions TO 'portal_rw'@'localhost';
GRANT SELECT                 ON xi_relaunch.chars             TO 'portal_rw'@'localhost';
GRANT SELECT                 ON xi_relaunch.char_storage      TO 'portal_rw'@'localhost';
GRANT SELECT (charid, containerid, slotid) ON xi_relaunch.char_equip TO 'portal_rw'@'localhost';
GRANT SELECT (itemId)        ON xi_relaunch.item_equipment    TO 'portal_rw'@'localhost';
GRANT SELECT (itemId)        ON xi_relaunch.item_weapon       TO 'portal_rw'@'localhost';
GRANT UPDATE (pos_zone, pos_prevzone, pos_x, pos_y, pos_z, pos_rot, moghouse) ON xi_relaunch.chars TO 'portal_rw'@'localhost';
GRANT SELECT, UPDATE (face, race, size) ON xi_relaunch.char_look TO 'portal_rw'@'localhost';
GRANT SELECT ON xi_relaunch.char_jobs TO 'portal_rw'@'localhost';
GRANT SELECT, UPDATE (mjob, sjob, mlvl, slvl) ON xi_relaunch.char_stats TO 'portal_rw'@'localhost';
GRANT SELECT (charid, enemies_defeated, times_knocked_out, battles_fought) ON xi_relaunch.char_history TO 'portal_rw'@'localhost';  -- profile customization: NM-kills badge count (_char_cosmetic_context runs on the write conn during save)
GRANT SELECT, INSERT, UPDATE ON xi_relaunch.char_vars TO 'portal_rw'@'localhost';   -- legacy migration reward writes char_vars (HL_Tier / PW_Trial_* / Legacy_Reward_Claimed)
GRANT SELECT, INSERT, UPDATE ON xi_relaunch.portal_profile TO 'portal_rw'@'localhost';  -- profile customization
GRANT SELECT, INSERT, DELETE ON xi_relaunch.portal_activity  TO 'portal_rw'@'localhost';  -- sampler writes feed events (+ prunes old)
GRANT SELECT, INSERT, UPDATE ON xi_relaunch.portal_snapshot  TO 'portal_rw'@'localhost';  -- sampler diff snapshot
GRANT SELECT, INSERT, DELETE ON xi_relaunch.portal_push_sub  TO 'portal_rw'@'localhost';  -- web-push subscriptions
GRANT SELECT, INSERT, UPDATE ON xi_relaunch.portal_ach_seen  TO 'portal_rw'@'localhost';  -- achievement "seen" acknowledgement

FLUSH PRIVILEGES;
