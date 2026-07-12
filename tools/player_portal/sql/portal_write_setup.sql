-- Portal write-path setup -- run ONCE on the DB before enabling offline
-- item move/discard. Idempotent (IF NOT EXISTS), so re-running is safe.
--
-- Local dev uses root, so portal_rw is optional there -- but the
-- portal_item_log table is REQUIRED in both dev and prod (discard writes to it,
-- inside the same transaction, so if it's missing the discard safely 500s and
-- nothing is deleted).

-- 1) Recoverable trash log. Every discard copies the full item row here BEFORE
--    deleting it, so an admin can restore a mistaken discard.
CREATE TABLE IF NOT EXISTS portal_item_log (
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
  KEY charid (charid),
  KEY ts (ts)
);

-- 2) Scoped WRITE user (prod). Reads stay on portal_ro; this user can only
--    touch exactly what move/discard need -- nothing else in the DB.
--    >>> change the password before running. <<<
CREATE USER IF NOT EXISTS 'portal_rw'@'127.0.0.1' IDENTIFIED BY 'CHANGE_ME_strong_db_password';
GRANT SELECT, UPDATE, DELETE ON xidb.char_inventory   TO 'portal_rw'@'127.0.0.1';
GRANT INSERT                 ON xidb.portal_item_log  TO 'portal_rw'@'127.0.0.1';
GRANT SELECT                 ON xidb.accounts_sessions TO 'portal_rw'@'127.0.0.1';
GRANT SELECT                 ON xidb.chars            TO 'portal_rw'@'127.0.0.1';
GRANT SELECT                 ON xidb.char_storage     TO 'portal_rw'@'127.0.0.1';
GRANT SELECT                 ON xidb.char_equip       TO 'portal_rw'@'127.0.0.1';
GRANT SELECT                 ON xidb.item_equipment   TO 'portal_rw'@'127.0.0.1';
GRANT SELECT                 ON xidb.item_weapon      TO 'portal_rw'@'127.0.0.1';
FLUSH PRIVILEGES;

-- Then in the portal's .env (prod):
--   PORTAL_DB_WRITE_USER=portal_rw
--   PORTAL_DB_WRITE_PASS=<the password you set above>
