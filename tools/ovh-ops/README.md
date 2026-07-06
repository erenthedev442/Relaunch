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
