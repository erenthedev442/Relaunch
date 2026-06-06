#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# _deploy_remote.sh  -  runs ON the Azure server, launched by deploy-to-azure.bat.
# Quick path: imports the just-uploaded sql/zz_*.sql into the live DB and
# restarts the map server. Uses sudo mariadb (same method as your other Azure
# bats) - no dbtool, nothing to install.
# ---------------------------------------------------------------------------
set -uo pipefail

echo "=============================================="
echo " Legendary - applying SQL changes to live server"
echo "=============================================="

# Find the server folder.
BIN="$(find "$HOME" -maxdepth 5 -name xi_map -type f 2>/dev/null | head -n1 || true)"
REPO=""
if [ -n "$BIN" ]; then REPO="$(dirname "$BIN")"; fi
if [ -z "$REPO" ] || [ ! -d "$REPO/sql" ]; then
  for d in "$HOME/server" "$HOME/FFXI-Private-Server-FJB" /opt/server; do
    if [ -d "$d/sql" ]; then REPO="$d"; break; fi
  done
fi
if [ -z "${REPO:-}" ] || [ ! -d "$REPO/sql" ]; then
  echo "ERROR: could not find the server folder." >&2; exit 1
fi
echo "Server folder: $REPO"
cd "$REPO"

# Collect the freshly-uploaded files from the home folder.
shopt -s nullglob
UP=( "$HOME"/zz_*.sql )
if [ ${#UP[@]} -eq 0 ]; then
  echo "Nothing to do - no uploaded zz_*.sql files found." >&2; exit 1
fi
echo "Files to apply:"; printf '   %s\n' "${UP[@]##*/}"

# Best-effort safety backup of item_mods (the table these files touch).
mkdir -p sql/backups 2>/dev/null || sudo mkdir -p sql/backups
BK="sql/backups/predeploy-item_mods-$(date +%Y%m%d-%H%M%S).sql"
if sudo mariadb-dump xidb item_mods > "$BK" 2>/dev/null || sudo mysqldump xidb item_mods > "$BK" 2>/dev/null; then
  echo "Backed up item_mods -> $BK"
else
  rm -f "$BK" 2>/dev/null || true
  echo "WARNING: couldn't back up item_mods - continuing (imports are idempotent)."
fi

# Import each uploaded file via sudo mariadb, and refresh the repo copy.
for f in "${UP[@]}"; do
  base="$(basename "$f")"
  echo "Importing $base ..."
  if ! sudo mariadb xidb < "$f"; then
    echo "ERROR importing $base. Restore from $BK if needed." >&2; exit 1
  fi
  sudo cp -f "$f" "$REPO/sql/$base"
  sudo chown xi:xi "$REPO/sql/$base" 2>/dev/null || true
  rm -f "$f"
done
echo "Database updated."

# Restart the map server so item/zone data reloads (players briefly disconnect).
echo "Restarting map server..."
if sudo systemctl restart xi_map 2>/dev/null; then
  echo "Restarted xi_map."
elif sudo systemctl restart xi 2>/dev/null; then
  echo "Restarted xi."
else
  echo "NOTE: couldn't restart via systemctl - restart the map server yourself."
fi

echo "=============================================="
echo " DONE - changes are live."
echo "=============================================="
