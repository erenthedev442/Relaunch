#!/usr/bin/env bash
#
# setup_portal.sh -- one-shot Player Portal setup on a server box.
# Run this ON THE BOX after the portal code is present (see DEPLOY.md).
#
# It creates a venv + installs deps, creates the READ-ONLY (portal_ro) and
# WRITE (portal_rw) DB users scoped to exactly what the portal touches, creates
# the recoverable-trash table, writes a production .env (generating the JWT
# secret), and installs + starts a systemd service. It does NOT set up the
# Cloudflare tunnel -- that has an interactive login; see DEPLOY.md.
#
# Defaults target the RELAUNCH staging DB. Override via env or edit CONFIG.
#   bash deploy/setup_portal.sh
set -euo pipefail

# ---------------- CONFIG ----------------
DB_NAME="${DB_NAME:-xi_relaunch}"          # relaunch staging DB (mirrors live)
DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-3306}"
DB_ADMIN_USER="${DB_ADMIN_USER:-root}"     # an account that can CREATE USER / GRANT
PORT="${PORT:-8090}"                        # local uvicorn port (relaunch = 8080+10)
SERVICE_NAME="${SERVICE_NAME:-ffxi-portal-relaunch}"
SERVICE_USER="${SERVICE_USER:-$USER}"
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"   # the tools/player_portal dir
# ----------------------------------------

echo ">> Portal dir: ${APP_DIR}"
echo ">> Target DB : ${DB_NAME} @ ${DB_HOST}:${DB_PORT}   uvicorn port: ${PORT}"
read -rsp "MySQL admin (${DB_ADMIN_USER}) password: " DB_ADMIN_PASS; echo
read -rsp "Set a password for portal_ro (read-only): " RO_PASS; echo
read -rsp "Set a password for portal_rw (write)    : " RW_PASS; echo
MYSQL=(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_ADMIN_USER" "-p${DB_ADMIN_PASS}")

echo ">> venv + dependencies"
python3 -m venv "$APP_DIR/.venv"
"$APP_DIR/.venv/bin/pip" install --quiet --upgrade pip
"$APP_DIR/.venv/bin/pip" install --quiet -r "$APP_DIR/requirements.txt"

echo ">> DB users, grants, and recoverable-trash table on ${DB_NAME}"
"${MYSQL[@]}" <<SQL
-- READ-ONLY user: exactly the columns the portal reads, nothing else.
CREATE USER IF NOT EXISTS 'portal_ro'@'127.0.0.1' IDENTIFIED BY '${RO_PASS}';
GRANT SELECT (id, login, password, current_email, timecreate)              ON ${DB_NAME}.accounts          TO 'portal_ro'@'127.0.0.1';
GRANT SELECT (charid, accid, charname, nation, playtime, pos_zone, home_zone) ON ${DB_NAME}.chars          TO 'portal_ro'@'127.0.0.1';
GRANT SELECT (charid, mjob, sjob, mlvl, slvl, hp, mp)                      ON ${DB_NAME}.char_stats        TO 'portal_ro'@'127.0.0.1';
GRANT SELECT (charid, location, slot, itemId, quantity, bazaar)            ON ${DB_NAME}.char_inventory    TO 'portal_ro'@'127.0.0.1';
GRANT SELECT (charid, enemies_defeated, times_knocked_out, battles_fought) ON ${DB_NAME}.char_history      TO 'portal_ro'@'127.0.0.1';
GRANT SELECT (charid, varname, value)                                      ON ${DB_NAME}.char_vars         TO 'portal_ro'@'127.0.0.1';
GRANT SELECT (charid, containerid, slotid)                                 ON ${DB_NAME}.char_equip        TO 'portal_ro'@'127.0.0.1';
GRANT SELECT (charid, face, race, size)                                    ON ${DB_NAME}.char_look         TO 'portal_ro'@'127.0.0.1';
GRANT SELECT (itemid, name)                                                ON ${DB_NAME}.item_basic        TO 'portal_ro'@'127.0.0.1';
GRANT SELECT (zoneid, name)                                                ON ${DB_NAME}.zone_settings     TO 'portal_ro'@'127.0.0.1';
GRANT SELECT ON ${DB_NAME}.char_jobs          TO 'portal_ro'@'127.0.0.1';
GRANT SELECT ON ${DB_NAME}.char_storage       TO 'portal_ro'@'127.0.0.1';
GRANT SELECT ON ${DB_NAME}.accounts_sessions  TO 'portal_ro'@'127.0.0.1';

-- Recoverable trash log (discard copies the full row here before deleting).
CREATE TABLE IF NOT EXISTS ${DB_NAME}.portal_item_log (
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

-- Offline vault: items stored OUTSIDE the game's containers, so they don't count
-- against any in-game limit. Deposit moves a row here from char_inventory; withdraw
-- moves it back. extra/signature preserved so augments survive the round trip.
CREATE TABLE IF NOT EXISTS ${DB_NAME}.portal_vault (
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
GRANT SELECT ON ${DB_NAME}.portal_vault TO 'portal_ro'@'127.0.0.1';

-- WRITE user: only what offline move/discard/vault need.
CREATE USER IF NOT EXISTS 'portal_rw'@'127.0.0.1' IDENTIFIED BY '${RW_PASS}';
GRANT SELECT, INSERT, UPDATE, DELETE ON ${DB_NAME}.char_inventory TO 'portal_rw'@'127.0.0.1';
GRANT INSERT                 ON ${DB_NAME}.portal_item_log   TO 'portal_rw'@'127.0.0.1';
GRANT SELECT, INSERT, DELETE ON ${DB_NAME}.portal_vault      TO 'portal_rw'@'127.0.0.1';
GRANT SELECT                 ON ${DB_NAME}.accounts_sessions TO 'portal_rw'@'127.0.0.1';
GRANT SELECT                 ON ${DB_NAME}.chars             TO 'portal_rw'@'127.0.0.1';
GRANT SELECT                 ON ${DB_NAME}.char_storage      TO 'portal_rw'@'127.0.0.1';
GRANT SELECT (charid, containerid, slotid) ON ${DB_NAME}.char_equip TO 'portal_rw'@'127.0.0.1';
GRANT SELECT (itemId)        ON ${DB_NAME}.item_equipment    TO 'portal_rw'@'127.0.0.1';
GRANT SELECT (itemId)        ON ${DB_NAME}.item_weapon       TO 'portal_rw'@'127.0.0.1';
GRANT UPDATE (pos_zone, pos_prevzone, pos_x, pos_y, pos_z, pos_rot, moghouse) ON ${DB_NAME}.chars TO 'portal_rw'@'127.0.0.1';
GRANT SELECT, UPDATE (face, race, size) ON ${DB_NAME}.char_look TO 'portal_rw'@'127.0.0.1';
GRANT SELECT ON ${DB_NAME}.char_jobs TO 'portal_rw'@'127.0.0.1';
GRANT SELECT, UPDATE (mjob, sjob, mlvl, slvl) ON ${DB_NAME}.char_stats TO 'portal_rw'@'127.0.0.1';
FLUSH PRIVILEGES;
SQL

echo ">> .env (mode 600)"
SECRET="$("$APP_DIR/.venv/bin/python" -c 'import secrets; print(secrets.token_urlsafe(48))')"
umask 077
cat > "$APP_DIR/.env" <<ENV
PORTAL_DB_HOST=${DB_HOST}
PORTAL_DB_PORT=${DB_PORT}
PORTAL_DB_NAME=${DB_NAME}
PORTAL_DB_USER=portal_ro
PORTAL_DB_PASS=${RO_PASS}
PORTAL_DB_WRITE_USER=portal_rw
PORTAL_DB_WRITE_PASS=${RW_PASS}
PORTAL_JWT_SECRET=${SECRET}
PORTAL_JWT_TTL_HOURS=12
PORTAL_COOKIE_NAME=portal_session
PORTAL_COOKIE_SECURE=true
PORTAL_COOKIE_SAMESITE=lax
PORTAL_CORS_ORIGINS=
ENV

echo ">> systemd service: ${SERVICE_NAME}"
sudo tee "/etc/systemd/system/${SERVICE_NAME}.service" >/dev/null <<UNIT
[Unit]
Description=Legendary FFXI Player Portal (${DB_NAME})
After=network.target mariadb.service

[Service]
User=${SERVICE_USER}
WorkingDirectory=${APP_DIR}
ExecStart=${APP_DIR}/.venv/bin/uvicorn app:app --host 127.0.0.1 --port ${PORT}
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT

sudo systemctl daemon-reload
sudo systemctl enable --now "${SERVICE_NAME}"
sleep 1
echo
echo ">> Portal is running on http://127.0.0.1:${PORT}"
curl -fsS "http://127.0.0.1:${PORT}/api/health" && echo "  (health OK)"
echo ">> Next: point the Cloudflare tunnel at 127.0.0.1:${PORT} -- see DEPLOY.md"
