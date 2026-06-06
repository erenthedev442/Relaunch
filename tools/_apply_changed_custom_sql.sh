#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# _apply_changed_custom_sql.sh  --  runs ON the Azure box, called by
# "Azure - Deploy to Server.bat" right after the file sync. Applies every
# modules/custom/sql/*.sql whose CONTENT changed since the last deploy, so
# DB-side changes (trusts, mob groups, item mods, etc.) actually reach the
# live database -- the gap that used to require dragging each .sql in by hand.
#
# Run from the server repo root (the deploy cd's there). A checksum ledger in
# ~/.applied_custom_sql.sha256 records what's been applied, so only NEW or
# EDITED files run: idempotent files re-running is harmless, and non-idempotent
# ones only run when you actually edited them (= you intend them applied).
#
# FIRST-TIME SEEDING (so already-applied files don't all fire once):
#   cd ~/server && sha256sum modules/custom/sql/*.sql > ~/.applied_custom_sql.sha256
# (the deploy seeds this automatically the first time it sees no ledger.)
#
# NOTE: the sql/zz_*.sql layer (item_mods/latents) is a SEPARATE path handled
# by apply_custom_sql.py / azure-update -- this script only covers
# modules/custom/sql/*.sql.
# ---------------------------------------------------------------------------
set -uo pipefail

REC="$HOME/.applied_custom_sql.sha256"

# First run with no ledger: seed it from the current files (assume already in
# the DB, e.g. from the migration import) so we don't mass-apply the world.
if [ ! -f "$REC" ]; then
  sha256sum modules/custom/sql/*.sql > "$REC" 2>/dev/null || : > "$REC"
  echo "  seeded custom-SQL ledger ($(wc -l < "$REC") files marked applied); nothing to run."
  exit 0
fi

applied=0; failed=0
for f in modules/custom/sql/*.sql; do
  [ -e "$f" ] || continue
  sha="$(sha256sum "$f" | cut -d' ' -f1)"
  rec="$(awk -v p="$f" '$2==p {print $1}' "$REC" | head -1)"
  [ "$sha" = "$rec" ] && continue                       # unchanged -> skip
  if sudo mariadb xidb < "$f"; then
    echo "  applied: $(basename "$f")"
    awk -v p="$f" '$2!=p' "$REC" > "$REC.tmp" && mv -f "$REC.tmp" "$REC"
    printf '%s  %s\n' "$sha" "$f" >> "$REC"
    applied=$((applied+1))
  else
    echo "  FAILED : $(basename "$f")  (not recorded; fix the SQL and re-deploy)"
    failed=$((failed+1))
  fi
done

if [ $applied -eq 0 ] && [ $failed -eq 0 ]; then
  echo "  custom SQL: nothing changed."
else
  echo "  custom SQL: $applied applied, $failed failed."
fi
[ $failed -eq 0 ]
