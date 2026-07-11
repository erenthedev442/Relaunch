#!/usr/bin/env bash
# ============================================================
# refresh_site_relaunch.sh
#   Regenerate the PRIVATE relaunch docs site and deploy it
#   to Cloudflare Pages (project: fjb-relaunch, private via
#   Cloudflare Access — accessible only to rknutz@gmail.com).
#
#   Mirrors refresh_site_azure.sh but:
#     • DOCS_REPO  = ~/relaunch-docs  (Legendary branch clone)
#     • LIVE_ROOT  = ~/relaunch       (xi_relaunch DB worktree)
#     • CF_PROJECT = fjb-relaunch
#     • MkDocs config = tools/mkdocs_relaunch.yml
#     • Log         = ~/refresh_site_relaunch.log
#
#   SAFE BY DESIGN — only reads xi_relaunch and deploys static
#   files. Does not touch xi_map or any live service.
# ============================================================
set -uo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# ---- CONFIG --------------------------------------------------
DOCS_REPO="${DOCS_REPO:-$HOME/relaunch-docs}"
LIVE_ROOT="${LIVE_ROOT:-$HOME/relaunch}"
CF_PROJECT="${CF_PROJECT:-fjb-relaunch}"
LOG="${LOG:-$HOME/refresh_site_relaunch.log}"
DOCS_VENV="${DOCS_VENV:-$HOME/docs-venv}"
CF_ENV_FILE="${CF_ENV_FILE:-$HOME/.cloudflare_env}"
DOCGEN_CMD="${DOCGEN_CMD:-python3 tools/docgen/generate.py}"
MKDOCS_CFG="${MKDOCS_CFG:-mkdocs_relaunch.yml}"
# --------------------------------------------------------------

exec >>"$LOG" 2>&1
echo "===== $(date '+%F %T')  refresh_site_relaunch START ====="

exec 9>"/tmp/refresh_site_relaunch.lock"
if ! flock -n 9; then
    echo "[skip] previous relaunch refresh still running -- exiting"
    exit 0
fi

cd "$DOCS_REPO" || { echo "[FATAL] DOCS_REPO not found: $DOCS_REPO"; exit 1; }
export LEGENDARY_LIVE_ROOT="$LIVE_ROOT"

_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo Legendary)
echo "[0/4] syncing relaunch-docs to origin/${_branch}..."
if git fetch origin "$_branch" 2>&1 | tail -1 && git reset --hard "origin/${_branch}" 2>&1 | tail -1; then
    echo "[0/4] synced to origin/${_branch}"
else
    echo "[WARN] remote sync failed -- building from current checkout"
fi

if [ -f "$DOCS_VENV/bin/activate" ]; then
    # shellcheck disable=SC1091
    . "$DOCS_VENV/bin/activate"
fi

if [ -f "$CF_ENV_FILE" ]; then
    # shellcheck disable=SC1090
    . "$CF_ENV_FILE"
fi

echo "[info] DOCS_REPO=$DOCS_REPO"
echo "[info] LIVE_ROOT=$LIVE_ROOT (xi_relaunch DB)"
echo "[info] CF_PROJECT=$CF_PROJECT"
echo "[info] venv=$DOCS_VENV  token_set=$([ -n "${CLOUDFLARE_API_TOKEN:-}" ] && echo yes || echo NO)"

echo "[0b/4] syncing Lua modules from relaunch-docs → live server (keeps docgen in sync)..."
rsync -rl "$DOCS_REPO/modules/" "$LIVE_ROOT/modules/" \
    && echo "[0b/4] module sync complete" \
    || echo "[WARN] module sync failed -- docgen may read stale Lua"

echo "[0c/4] regenerating augment catalog from relaunch SQL..."
python3 "$LIVE_ROOT/tools/gen_augment_catalog.py" >> "$LOG" 2>&1 \
    && echo "[0c/4] augment catalog: OK" \
    || echo "[WARN] augment catalog regen failed -- using existing"

echo "[0d/4] regenerating catalyst warp table from augment_catalyst_mobs.lua..."
if python3 tools/gen_catalyst_warp_table.py >> "$LOG" 2>&1; then
    cp modules/custom/lua/catalyst_warp_table.lua "$LIVE_ROOT/modules/custom/lua/catalyst_warp_table.lua" \
        && echo "[0d/4] warp table: OK (deployed to LIVE_ROOT)" \
        || echo "[WARN] warp table: generated but copy to LIVE_ROOT failed"
else
    echo "[WARN] warp table regen failed -- !augwarp may be stale"
fi

echo "[0e/4] refreshing FFXIAH retail-stats cache (gear-vs-retail page)..."
# The gear-vs-retail generator compares live item_mods to retail item stats
# scraped from FFXIAH. That scrape is heavy (~3.2k il119 items @ 1.5s each), so
# we keep a PERSISTENT master cache in $LIVE_ROOT/tools/ (survives the hourly
# hard-reset of $DOCS_REPO) and only re-hit FFXIAH weekly, capped, incremental.
# A committed baseline lives in the repo as the floor, so the page still renders
# on a fresh box before the first fetch runs.
FFXIAH_MASTER="$LIVE_ROOT/tools/ffxiah_item_cache.json"
# Throttle: only scrape when the master is missing or older than 7 days.
if [ -z "$(find "$FFXIAH_MASTER" -mtime -7 2>/dev/null)" ]; then
    echo "[0e/4] master cache stale/missing -- incremental fetch (cap 600)..."
    python3 "$LIVE_ROOT/tools/fetch_ffxiah_cache.py" \
        --ilevel-min=119 --refresh-days=30 --max-items=600 >> "$LOG" 2>&1 \
        && echo "[0e/4] FFXIAH fetch complete" \
        || echo "[WARN] FFXIAH fetch failed -- using existing cache"
else
    echo "[0e/4] master cache fresh (<7d) -- skip scrape"
fi
# Stage the freshest cache into the docs checkout for docgen. The box-local
# master (kept current above) overrides the committed baseline; this leaves a
# dirty file in $DOCS_REPO which the next run's hard-reset cleans up harmlessly.
if [ -f "$FFXIAH_MASTER" ]; then
    cp "$FFXIAH_MASTER" tools/ffxiah_item_cache.json \
        && echo "[0e/4] cache staged for docgen ($(wc -c < tools/ffxiah_item_cache.json) bytes)" \
        || echo "[WARN] staging cache into docs checkout failed"
else
    echo "[0e/4] no master cache -- generator falls back to committed baseline"
fi

echo "[1/4] docgen (leaderboards + player profiles from xi_relaunch)..."
# shellcheck disable=SC2086
$DOCGEN_CMD || { echo "[FATAL] docgen failed"; exit 1; }

echo "[2/4] mkdocs build (config: $MKDOCS_CFG)..."
mkdocs build --clean -f "$MKDOCS_CFG" || { echo "[FATAL] mkdocs build failed"; exit 1; }

# Count PROFILE pages only: each player renders to community/players/<name>/index.html
# (depth >= 2). The roster placeholder is community/players/index.html (depth 1) and
# is excluded, so this is 0 ONLY when xi_relaunch was unreachable during docgen.
players=$(find site/community/players -mindepth 2 -name '*.html' 2>/dev/null | wc -l)
echo "[info] built $players player profile page(s)"
if [ "$players" -eq 0 ]; then
    # DB was down -> the DB-backed pages (players, leaderboards, status) still hold
    # their last-committed content. Publishing that would republish stale/pre-wipe
    # data. Keep the last-good live site instead and retry next cycle.
    echo "[SKIP] 0 player profiles built -- xi_relaunch DB unreachable. Skipping deploy to"
    echo "       avoid publishing stale data; last-good site stays live. Retrying next cycle."
    exit 0
fi

echo "[2b/4] injecting site-wide auth gate (Basic Auth — all routes)..."
# Protect the entire relaunch site, not just /admin.
# functions/[[path]].js at the project root covers every URL on the site.
mkdir -p functions
cp "tools/pages-functions/relaunch/[[path]].js" "functions/[[path]].js" \
    && echo "[2b/4] site auth gate injected" \
    || echo "[WARN] site auth gate copy failed"

echo "[3/4] deploy to Cloudflare Pages ($CF_PROJECT)..."
npx --yes wrangler pages deploy site --project-name="$CF_PROJECT" --branch=main --commit-dirty=true \
    || { echo "[FATAL] wrangler deploy failed (CLOUDFLARE_API_TOKEN set?)"; exit 1; }

echo "===== $(date '+%F %T')  refresh_site_relaunch DONE ====="
echo
