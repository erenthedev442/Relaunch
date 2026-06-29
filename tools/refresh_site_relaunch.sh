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

echo "[1/4] docgen (leaderboards + player profiles from xi_relaunch)..."
# shellcheck disable=SC2086
$DOCGEN_CMD || { echo "[FATAL] docgen failed"; exit 1; }

echo "[2/4] mkdocs build (config: $MKDOCS_CFG)..."
mkdocs build --clean -f "$MKDOCS_CFG" || { echo "[FATAL] mkdocs build failed"; exit 1; }

players=$(find site -path '*community/players*' -name '*.html' 2>/dev/null | wc -l)
echo "[info] built $players player page(s)"
if [ "$players" -eq 0 ]; then
    echo "[WARN] 0 player pages -- xi_relaunch DB unreachable or LIVE_ROOT wrong"
    echo "[WARN] deploying anyway for doc-only changes"
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
