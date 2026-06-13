#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# apply_declutter.sh -- deliberate, standalone NPC declutter for the LIVE server.
#
# Hides ~878 inert "extra" NPCs (one-line townsfolk + cutscene-only walk-ons),
# already safety-filtered so it never touches warps, Salvage doors, Nomad
# Moogles, Pso'Xja lifts, or any service NPC. Fully reversible.
#
# This is intentionally NOT wired into the rolling Azure deploy (the files are
# sql/npc_declutter*.sql, outside the auto-applied sql/zz_*.sql set) so the
# declutter only happens when YOU run this.
#
# Run ON the Azure box, from the server checkout root:
#     git pull && sudo bash tools/npc_audit/apply_declutter.sh
#
# Flags:
#   --rollback     restore everything we hid (status 2 -> 0)
#   --dry-run      back up + show counts, apply NOTHING, no restart
#   --yes | -y     skip the restart confirmation (true one-shot)
#   --no-restart   apply the DB change but leave the xi_map restart to you
# ---------------------------------------------------------------------------
set -uo pipefail

DB=xidb
DIS="sql/npc_declutter.sql"
RB="sql/npc_declutter_ROLLBACK.sql"

ROLLBACK=0; DRYRUN=0; ASSUME_YES=0; NORESTART=0
for a in "$@"; do
  case "$a" in
    --rollback)   ROLLBACK=1 ;;
    --dry-run)    DRYRUN=1 ;;
    --yes|-y)     ASSUME_YES=1 ;;
    --no-restart) NORESTART=1 ;;
    *) echo "unknown flag: $a" >&2; exit 2 ;;
  esac
done

# unix_socket auth needs root; the user invokes via sudo.
if [ "$(id -u)" -ne 0 ]; then
  echo "run with sudo:  sudo bash tools/npc_audit/apply_declutter.sh $*" >&2
  exit 1
fi
# Must run from a server checkout that actually has the SQL.
if [ ! -f "$DIS" ]; then
  echo "ERROR: $DIS not found. cd to the server checkout root and 'git pull' first." >&2
  exit 1
fi

SQL="$DIS"; VERB="HIDE inert NPCs (status 2)"
if [ "$ROLLBACK" = 1 ]; then SQL="$RB"; VERB="RESTORE all hidden NPCs (status 0)"; fi

echo "=================================================="
echo " NPC declutter -- $VERB"
echo "=================================================="

# [1] targeted backup of the only table we touch (fast, ~31k rows).
mkdir -p sql/backups
BK="sql/backups/npc_list-predeclutter-$(date +%Y%m%d-%H%M%S).sql"
if mariadb-dump "$DB" npc_list > "$BK" 2>/dev/null \
   || mysqldump "$DB" npc_list > "$BK" 2>/dev/null; then
  echo "[1] backup -> $BK"
else
  rm -f "$BK"
  echo "[1] WARNING: backup failed -- the rollback file still works; continuing."
fi

before=$(mariadb -N -B "$DB" -e "SELECT COUNT(*) FROM npc_list WHERE status=2;" 2>/dev/null || echo 0)
before=${before:-0}
echo "[2] npc_list rows hidden (status=2) BEFORE: $before"

if [ "$DRYRUN" = 1 ]; then
  pending=$(grep -c '^UPDATE' "$SQL" 2>/dev/null || echo 0)
  echo "[dry-run] would run $pending UPDATE statement(s) from $SQL -- nothing applied."
  exit 0
fi

echo "[3] applying $SQL ..."
if ! mariadb "$DB" < "$SQL"; then
  echo "ERROR applying $SQL -- DB may be partial. Restore: sudo mariadb $DB < $BK" >&2
  exit 1
fi
after=$(mariadb -N -B "$DB" -e "SELECT COUNT(*) FROM npc_list WHERE status=2;" 2>/dev/null || echo 0)
after=${after:-0}
echo "    rows hidden AFTER:  $after   (delta $((after - before)))"

# [4] restart xi_map only -- NPC data loads at map boot; world/login stay up.
if [ "$NORESTART" = 1 ]; then
  echo "[4] --no-restart: change is staged in the DB; it shows on the next xi_map restart."
else
  if [ "$ASSUME_YES" != 1 ]; then
    read -r -p "[4] Restart xi_map now (briefly disconnects players on the map)? [y/N] " ans
    case "${ans:-N}" in
      [Yy]*) ;;
      *) echo "    skipped -- run when ready:  sudo systemctl restart xi_map"; exit 0 ;;
    esac
  fi
  systemctl restart xi_map && echo "    xi_map restarted."
fi

echo
echo "DONE. Walk a city; confirm shops / moogles / AH / gate-guards are present."
if [ "$ROLLBACK" = 1 ]; then
  echo "Re-apply the declutter:  sudo bash tools/npc_audit/apply_declutter.sh"
else
  echo "Undo everything:         sudo bash tools/npc_audit/apply_declutter.sh --rollback"
  echo "Or restore the backup:   sudo mariadb $DB < $BK && sudo systemctl restart xi_map"
fi
