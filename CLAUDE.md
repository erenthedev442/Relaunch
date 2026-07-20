# Relaunch — game server repository

This repo is the **game server** half of the Relaunch project. The website /
docs were split into **richardknutzjr/Relaunch-Docs** on 2026-07-19.

## Boundary (hard rule)
- Work here on **gameplay / server** only: `src/`, `scripts/`, `modules/`,
  `sql/`, `settings/`, and the server/admin tools under `tools/`.
- The **docs live in richardknutzjr/Relaunch-Docs** — `docs/`, `mkdocs*.yml`,
  and `overrides/` are no longer in this repo. If a change needs docs updated,
  make the server change here, then update docs in the Relaunch-Docs repo (its
  generator reads THIS repo live via `LEGENDARY_LIVE_ROOT` — no cross-checkout
  needed).
- `tools/docgen/` here now holds ONLY the shared helpers server-admin tools import
  (`_db`, `_paths`, `_item_sources`, `_lua_consts`, `_markers`, and
  `generators/gear_finder.py`) — used by `_audit_gear*`, `fetch_ffxiah_cache`,
  `_rescue_jbae`, the `tools/balance/*` scripts, and the discord bots. The 135
  docs-page generators + `generate.py` were REMOVED 2026-07-19 (they were dead
  here — the LIVE docs build runs the copies in **Relaunch-Docs**). Do NOT re-add
  a docs generator here or edit these for docs output; author docs generators in
  Relaunch-Docs.

## Cross-repo spider-web
A player/content change is not done until it's reflected on the site. Post-split
that means: land the server change here, then regenerate the affected page(s) in
Relaunch-Docs (sync_audit there guards server<->docs consistency, reading this
repo via LEGENDARY_LIVE_ROOT).

## Deploy
`deploy-relaunch.ps1` rebuilds + restarts the server and, in step [B], triggers
the docs refresh task on the box (which builds + publishes from Relaunch-Docs).
The deploy commits only the "Relaunch Deploy" marker here; the changelog is
regenerated into Relaunch-Docs.
