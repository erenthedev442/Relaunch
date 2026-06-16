#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# _apply_changed_sql.sh  —  runs ON the Azure box, called by
# _azure_update_remote.sh after git pull.
#
# Finds ALL SQL files that changed since the previous "Deploy" commit and
# applies them to xidb in one pass. Covers:
#   sql/*.sql             (base tables + zz_* gear/mod override layers)
#   modules/custom/sql/*  (custom content: trusts, mob groups, etc.)
#
# Files are applied in sort order so base files precede their zz_* overrides
# (alphabetically: 'i' < 'z', so item_basic.sql before zz_item_basic.sql).
#
# NON-GIT FALLBACK: the Azure box is tarball-synced, not a git clone.
# In that case we apply all sql/zz_*.sql (idempotent) + sha256 ledger
# for modules/custom/sql/ (same ledger as the old _apply_changed_custom_sql.sh).
# ---------------------------------------------------------------------------
set -uo pipefail

cd "$(dirname "$0")/.."

# ---- Non-git box fallback ----
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "  Not a git repo — fallback: applying sql/zz_*.sql + sha256 ledger for custom SQL"
    applied=0; failed=0

    # zz_*.sql: always apply (full-table replacements, idempotent).
    # These are SCPed fresh by the deploy bat before this script runs.
    shopt -s nullglob
    for f in sql/zz_*.sql; do
        echo "    applying: $f"
        if sudo mariadb xidb < "$f"; then
            applied=$((applied+1))
        else
            echo "    FAILED: $f"
            failed=$((failed+1))
        fi
    done

    # modules/custom/sql: sha256 ledger — only apply files whose hash changed.
    LEDGER="$HOME/.applied_custom_sql.sha256"
    shopt -s nullglob
    custom_files=( modules/custom/sql/*.sql )
    if [ ! -f "$LEDGER" ]; then
        [ ${#custom_files[@]} -gt 0 ] \
            && sha256sum "${custom_files[@]}" > "$LEDGER" 2>/dev/null \
            || : > "$LEDGER"
        echo "  seeded custom-SQL ledger (${#custom_files[@]} files); nothing applied this run."
    else
        cust_applied=0
        for f in "${custom_files[@]}"; do
            sha="$(sha256sum "$f" | awk '{print $1}')"
            rec="$(awk -v p="$f" '$2==p{print $1}' "$LEDGER" | head -1)"
            [ "$sha" = "$rec" ] && continue
            echo "    custom: $f"
            if sudo mariadb xidb < "$f"; then
                awk -v p="$f" '$2!=p' "$LEDGER" > "$LEDGER.tmp" && mv "$LEDGER.tmp" "$LEDGER"
                printf '%s  %s\n' "$sha" "$f" >> "$LEDGER"
                applied=$((applied+1))
                cust_applied=$((cust_applied+1))
            else
                echo "    FAILED: $f"
                failed=$((failed+1))
            fi
        done
        [ "$cust_applied" -eq 0 ] && echo "  custom SQL: nothing changed."
    fi

    echo "  SQL: $applied applied, $failed failed."
    [ "$failed" -eq 0 ]
    exit $?
fi

# ---- Git path: diff since previous deploy commit ----
# Find the second-most-recent deploy commit — that's what was actually live
# before this push.  The most-recent is the commit just made in step 2.
PREV=$(git log --oneline 2>/dev/null \
       | grep -iE " Deploy (Everything|.No Rebuild.)" \
       | sed -n '2p' | awk '{print $1}')

if [ -z "$PREV" ]; then
    # First-ever deploy: diff from the initial commit so nothing is silently skipped.
    PREV=$(git rev-list --max-parents=0 HEAD 2>/dev/null | head -1)
    if [ -z "$PREV" ]; then
        echo "  WARNING: cannot determine base commit; skipping SQL apply."
        exit 0
    fi
    echo "  First deploy — diffing from initial commit ${PREV:0:8}."
else
    echo "  SQL changes since ${PREV}:"
fi

mapfile -t SQL_FILES < <(
    git diff --name-only --diff-filter=ACMR "$PREV"..HEAD \
        -- 'sql/*.sql' 'modules/custom/sql/*.sql' 2>/dev/null \
    | sort
)

if [ ${#SQL_FILES[@]} -eq 0 ]; then
    echo "  SQL: nothing changed."
    exit 0
fi

applied=0; failed=0
for f in "${SQL_FILES[@]}"; do
    if [ ! -f "$f" ]; then
        echo "    SKIP (deleted): $f"
        continue
    fi
    echo "    applying: $f"
    if sudo mariadb xidb < "$f"; then
        applied=$((applied+1))
    else
        echo "    FAILED: $f"
        failed=$((failed+1))
    fi
done

echo "  SQL: $applied applied, $failed failed."
[ $failed -eq 0 ]
