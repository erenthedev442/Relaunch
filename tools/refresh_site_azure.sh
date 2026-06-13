#!/usr/bin/env bash
# ============================================================
# refresh_site_azure.sh
#   Regenerate the docs site (incl. LIVE leaderboards + player
#   profiles) and deploy it to Cloudflare Pages. Meant to run on
#   the Azure box from cron.
#
# SAFE BY DESIGN -- this only READS the database and builds/deploys
# STATIC files. It never calls systemctl and never touches xi_map /
# xi_world. Running it will NOT restart or disturb the live game
# server. It also does NOT re-score gear catalogs (that stays a
# manual step in refresh-site.bat), so it can't churn committed
# catalog files.
#
# Why it must run ON THE BOX: the docgen leaderboard/player
# generators read the live DB via settings/network.lua, which is
# SQL_HOST=127.0.0.1. On Azure that IS the live DB; run from the
# laptop it would read the laptop's empty DB instead.
# ============================================================
set -uo pipefail

# ---- CONFIG: set these to the box's real layout ------------------
# Docs checkout that has tools/docgen/, mkdocs.yml and docs/.
# (On the laptop this is the "legendary-logo" git worktree.)
DOCS_REPO="${DOCS_REPO:-$HOME/legendary-docs}"

# Live server checkout (its settings/network.lua points docgen at the
# local live DB). The core-patches notes use ~/server on Azure.
LIVE_ROOT="${LEGENDARY_LIVE_ROOT:-$HOME/server}"

# docgen entry point -- the generator that emits leaderboards +
# player_profiles. Match your docs branch (generate.py here; the old
# laptop refresh-site.bat called generate_docs.py).
DOCGEN_CMD="${DOCGEN_CMD:-python3 tools/docgen/generate.py}"

# Cloudflare Pages project. The deploy needs CLOUDFLARE_API_TOKEN in
# the environment (set it in the crontab line or an env file -- do
# NOT hardcode a token in this script).
CF_PROJECT="${CF_PROJECT:-legendary-ffxi}"

LOG="${LOG:-$HOME/refresh_site.log}"
# ------------------------------------------------------------------

exec >>"$LOG" 2>&1
echo "===== $(date '+%F %T')  refresh_site START ====="

# Single-instance lock: a slow run can't overlap the next cron tick.
exec 9>"/tmp/refresh_site.lock"
if ! flock -n 9; then
    echo "[skip] previous refresh still running -- exiting"
    exit 0
fi

cd "$DOCS_REPO" || { echo "[FATAL] DOCS_REPO not found: $DOCS_REPO"; exit 1; }
export LEGENDARY_LIVE_ROOT="$LIVE_ROOT"
echo "[info] DOCS_REPO=$DOCS_REPO"
echo "[info] LEGENDARY_LIVE_ROOT=$LEGENDARY_LIVE_ROOT"

echo "[1/3] docgen (leaderboards + player profiles read the live DB)..."
# shellcheck disable=SC2086
$DOCGEN_CMD || { echo "[FATAL] docgen failed"; exit 1; }

echo "[2/3] mkdocs build..."
mkdocs build --clean || { echo "[FATAL] mkdocs build failed"; exit 1; }

# De-silence the "DB unreachable -> generators skip quietly" failure mode:
# if no player pages got built, the live DB wasn't read this run.
players=$(find site -path '*community/players*' -name '*.html' 2>/dev/null | wc -l)
echo "[info] built $players player page(s)"
if [ "$players" -eq 0 ]; then
    echo "[WARN] 0 player pages -- live DB unreachable or LEGENDARY_LIVE_ROOT wrong;"
    echo "[WARN] leaderboards/player pages are STALE this run (deploying anyway for doc-only changes)."
fi

echo "[3/3] deploy to Cloudflare Pages ($CF_PROJECT)..."
npx --yes wrangler pages deploy site --project-name="$CF_PROJECT" --commit-dirty=true \
    || { echo "[FATAL] wrangler deploy failed (CLOUDFLARE_API_TOKEN set?)"; exit 1; }

echo "===== $(date '+%F %T')  refresh_site DONE ====="
echo
