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

# cron runs with a minimal PATH; node/npx (NodeSource) live in /usr/bin. Make
# PATH explicit so mkdocs (venv, added below) and wrangler resolve under cron.
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

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

# Python venv holding mkdocs + pymysql (the box's system python3 lacks them).
DOCS_VENV="${DOCS_VENV:-$HOME/docs-venv}"

# Cloudflare API token is sourced from this env file if present, so the token
# stays OUT of this script and out of the crontab. Create it once with:
#   printf 'export CLOUDFLARE_API_TOKEN=%s\n' 'YOUR_TOKEN' > ~/.cloudflare_env
#   chmod 600 ~/.cloudflare_env
CF_ENV_FILE="${CF_ENV_FILE:-$HOME/.cloudflare_env}"
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

echo "[0/4] syncing docs to remote (hard reset; generated files are rebuilt below)..."
# Use fetch + reset --hard, NOT `git pull --ff-only`. This DOCS_REPO tracks
# GENERATED output (docs/ + site/) in git, so every regen leaves the working tree
# dirty -> a fast-forward pull SILENTLY fails and the site FREEZES on a stale
# checkout (found 57 commits behind on 2026-06-21, publishing months-old docs). A
# hard reset to the remote always wins; the dirty generated files are regenerated
# immediately below, and the canonical config (mkdocs.yml/overrides) comes from
# the repo. Robust to the blobless partial clone (reset fetches only HEAD blobs).
_lc_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo Legendary)
if git fetch origin "$_lc_branch" 2>&1 | tail -1 && git reset --hard "origin/${_lc_branch}" 2>&1 | tail -1; then
    echo "[0/4] synced to origin/${_lc_branch}"
else
    echo "[WARN] remote sync failed -- building from current checkout"
fi

# Activate the docs venv so `python3` and `mkdocs` resolve to the ones that
# have mkdocs + pymysql installed.
if [ -f "$DOCS_VENV/bin/activate" ]; then
    # shellcheck disable=SC1091
    . "$DOCS_VENV/bin/activate"
fi

# Load the Cloudflare API token (CLOUDFLARE_API_TOKEN) for the deploy step.
if [ -f "$CF_ENV_FILE" ]; then
    # shellcheck disable=SC1090
    . "$CF_ENV_FILE"
fi

echo "[info] DOCS_REPO=$DOCS_REPO"
echo "[info] LEGENDARY_LIVE_ROOT=$LEGENDARY_LIVE_ROOT"
echo "[info] venv=$DOCS_VENV  token_file=$CF_ENV_FILE  token_set=$([ -n "${CLOUDFLARE_API_TOKEN:-}" ] && echo yes || echo NO)"

echo "[0c/4] regenerating augment catalog from live SQL..."
python3 "$LIVE_ROOT/tools/gen_augment_catalog.py" >> "$LOG" 2>&1 \
    && echo "[0c/4] augment catalog: OK" \
    || echo "[WARN] augment catalog regen failed — using existing (see $LOG)"

echo "[1/4] docgen (leaderboards + player profiles read the live DB)..."
# shellcheck disable=SC2086
$DOCGEN_CMD || { echo "[FATAL] docgen failed"; exit 1; }

echo "[2/4] mkdocs build..."
mkdocs build --clean || { echo "[FATAL] mkdocs build failed"; exit 1; }

# De-silence the "DB unreachable -> generators skip quietly" failure mode:
# if no player pages got built, the live DB wasn't read this run.
players=$(find site -path '*community/players*' -name '*.html' 2>/dev/null | wc -l)
echo "[info] built $players player page(s)"
if [ "$players" -eq 0 ]; then
    echo "[WARN] 0 player pages -- live DB unreachable or LEGENDARY_LIVE_ROOT wrong;"
    echo "[WARN] leaderboards/player pages are STALE this run (deploying anyway for doc-only changes)."
fi

echo "[3/4] deploy to Cloudflare Pages ($CF_PROJECT)..."
# --branch=main maps to Cloudflare's PRODUCTION environment (legendary-ffxi.pages.dev).
# WITHOUT it, wrangler tags the deploy with the box's checked-out git branch
# ("Legendary") and Cloudflare treats that as a PREVIEW deployment
# (legendary.legendary-ffxi.pages.dev) -- production never updates. That froze the
# public site "since 6/19" until diagnosed 2026-06-20; do not remove this flag.
npx --yes wrangler pages deploy site --project-name="$CF_PROJECT" --branch=main --commit-dirty=true \
    || { echo "[FATAL] wrangler deploy failed (CLOUDFLARE_API_TOKEN set?)"; exit 1; }

echo "===== $(date '+%F %T')  refresh_site DONE ====="
echo
