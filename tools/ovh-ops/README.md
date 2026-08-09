# OVH relaunch support jobs

Backup copies of the 3 relaunch support jobs that were **migrated off the Azure
crons onto the OVH VPS (15.204.112.102) on 2026-07-06**. They now run as Windows
**Scheduled Tasks** (as SYSTEM) reading the **live DB over localhost** — no more
remote/stale DB.

The LIVE copies run from `C:\relaunch-ops\` on the OVH box (out of the git tree
so deploys can't clobber them). These are version-controlled backups.

| Scheduled Task | Schedule | Script | Purpose |
|---|---|---|---|
| `Relaunch-DocsRefresh` | :15 hourly | `refresh_site_relaunch.ps1` | docgen from live `C:\server` + `xi_relaunch` → mkdocs → wrangler deploy `fjb-relaunch` |
| `Relaunch-AHBot` | :30 hourly | `run_ah_market_maker.ps1` → `C:\server\tools\ah_market_maker.py --commit` | market-make the live AH |
| `Relaunch-DriftMonitor` | :20 / :50 | `run_site_drift_monitor.ps1` → `site_drift_monitor_relaunch.py` | dead-man switch for `fjb-relaunch`; alerts Discord |

**All three self-lower to IDLE_PRIORITY_CLASS at startup — added 2026-08-08.** These
are CPU/disk-heavy batch jobs (git fetch, mkdocs build, wrangler upload, docgen
sync_audit, AH DB writes) sharing the single `C:` drive with the game + MariaDB. At
normal priority they periodically starved the game's main tick (CPU) and its
synchronous fsync (disk), tripping the map inactivity watchdog — several trips
correlated with these tasks' slots (18:20 = :20 drift, 00:16 = :15 docs). Each script
now runs `(Get-Process -Id $PID).PriorityClass = 'Idle'` near the top; the heavy
children (git/python/mkdocs/wrangler) INHERIT IDLE from the parent, so the game wins
the CPU and disk. NOTE: this is done IN-SCRIPT on purpose — the Task Scheduler
"Priority" field (even set to 10) does NOT yield IDLE_PRIORITY_CLASS on this box
(verified 2026-08-08: a priority-10 task still launched its process at Normal), so
don't rely on the task Priority setting for this. Do NOT lower `FFXIRelaunch` (the
game supervisor) or the game processes.

Also here (manual, not a scheduled task): `gen-discord-changelog.ps1` — turns
recent `C:\server` commits into a player-friendly Discord changelog (desktop
shortcut on the box). Classifies conventional `type(scope):` subjects AND
plain collaborator subjects via a leading-verb fallback. Not in the
OPS-SELFSYNC whitelist — update `C:\relaunch-ops\` copy AND this repo copy
together when editing.

## Box-only files (NOT committed — secrets / box paths)
- `C:\relaunch-ops\.cloudflare_env` — `CLOUDFLARE_API_TOKEN=...` (wrangler auth)
- `C:\relaunch-ops\.discord_webhook` — Discord webhook URL for drift alerts
- `C:\relaunch-docs\` — docs build workspace = `git clone --no-hardlinks C:\server`
- `C:\relaunch-ops\logs\` — per-job logs

## Prereqs on OVH
- Python 3.12 + `mkdocs mkdocs-material pymysql pyyaml requests regex colorama gitpython tzdata`
  (`tzdata` is REQUIRED on Windows — `stamp.py` uses `ZoneInfo("America/Los_Angeles")`).
- Node (`npx --yes wrangler`), Git, MariaDB 10.6.

## Security
OVH MariaDB (`root`/`richard`, localhost) was internet-exposed; **firewalled to
localhost 2026-07-06** (disabled the mysqld allow rule + added block rule
`Relaunch-Block-MariaDB-External`). Loopback is exempt, so the server + jobs are
unaffected.

See the `reference-ovh-relaunch-ops` auto-memory for the full runbook.
