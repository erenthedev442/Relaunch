#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# _azure_update_remote.sh  -  runs ON the Azure server, launched by
# "Azure - Deploy + Rebuild.bat". Rebuilds the binaries and reloads the mod SQL,
# using the same methods as your existing Azure bats (sudo mariadb, cmake
# --build build, sudo systemctl restart xi) - NO dbtool, nothing to install.
# ---------------------------------------------------------------------------
set -uo pipefail

echo "================================================"
echo " Legendary - rebuild + reload mods (Azure)"
echo "================================================"

# Locate the server folder.
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

# Place freshly-uploaded zz_*.sql (your latest from the laptop) into sql/.
shopt -s nullglob
UP=( "$HOME"/zz_*.sql )
if [ ${#UP[@]} -gt 0 ]; then
  echo "Refreshing custom SQL:"; printf '  %s\n' "${UP[@]##*/}"
  for f in "${UP[@]}"; do
    sudo cp -f "$f" "$REPO/sql/$(basename "$f")"
    rm -f "$f"
  done
  sudo chown xi:xi "$REPO"/sql/zz_*.sql 2>/dev/null || true
fi

# [1] Safety backup (best-effort; the zz_ reload below is idempotent anyway).
echo; echo "[1/5] Backing up database..."
mkdir -p sql/backups 2>/dev/null || sudo mkdir -p sql/backups
BK="sql/backups/predeploy-$(date +%Y%m%d-%H%M%S).sql"
if sudo mariadb-dump xidb > "$BK" 2>/dev/null || sudo mysqldump xidb > "$BK" 2>/dev/null; then
  echo "  saved $BK"
else
  rm -f "$BK" 2>/dev/null || true
  echo "  WARNING: couldn't create a backup - continuing (mod reload is idempotent)."
fi

# [2] Update code from the fork (--ff-only never leaves a half-merged mess).
echo; echo "[2/5] Updating code (git pull)..."
if git pull --ff-only; then
  echo "  code updated."
else
  echo "  NOTE: no fast-forward (local changes or nothing new) - keeping current code."
fi

# Ensure every custom C++ module listed in the committed init.txt is also in the
# box's init.txt (which is per-machine / assume-unchanged), so the rebuild below
# actually compiles newly-added modules (e.g. cross_job_ability_bindings.cpp).
# Additive only -- never removes the box's own entries.
INIT="$REPO/modules/init.txt"
if [ -f "$INIT" ]; then
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    if ! grep -qxF "$line" "$INIT"; then
      echo "  + init.txt: $line"
      printf '%s\n' "$line" | sudo tee -a "$INIT" >/dev/null
    fi
  done < <(git show HEAD:modules/init.txt 2>/dev/null | grep -E '^custom/cpp/.*\.cpp$' || true)
  sudo chown xi:xi "$INIT" 2>/dev/null || true
fi

# [3] Rebuild (same command as your Azure - Rebuild Server.bat).
echo; echo "[3/5] Rebuilding server binaries..."
if [ -d build ]; then
  if cmake --build build -j2; then
    echo "  build OK."
  else
    echo "ERROR: build failed - server NOT restarted. Fix the code and re-run." >&2
    exit 1
  fi
else
  echo "  WARNING: no build/ directory found - skipping rebuild."
fi

# [4] Reload the custom mod SQL. Only the zz_*.sql layer (gear/zones/mods),
#     which is idempotent (INSERT IGNORE / ON DUPLICATE / DELETE) so it's
#     safe to re-run. Player data is never touched.
echo; echo "[4/5] Reloading custom mod SQL (zz_*.sql)..."
shopt -s nullglob
for f in sql/zz_*.sql; do
  echo "  $f"
  if ! sudo mariadb xidb < "$f"; then
    echo "ERROR applying $f - server NOT restarted. Restore from sql/backups if needed." >&2
    exit 1
  fi
done
echo "  SQL reloaded."

# [5] Restart so the new code + data take effect.
echo; echo "[5/5] Restarting server (players briefly disconnect)..."
if sudo systemctl restart xi 2>/dev/null; then
  echo "  restarted xi."
elif sudo systemctl restart xi_map xi_connect xi_search xi_world 2>/dev/null; then
  echo "  restarted xi_* services."
else
  echo "  WARNING: couldn't restart via systemctl - restart manually."
fi

echo "================================================"
echo " DONE - rebuilt, mod SQL reloaded, restarted."
echo "================================================"
