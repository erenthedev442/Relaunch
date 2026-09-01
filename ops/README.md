# Relaunch VPS — Operations (OVH, self-contained)

Everything to run/rebuild the relaunch server lives here on the VPS (`C:\server`)
and in this repo. **No laptop is involved.** Code comes from GitHub
(`origin/relaunch`) or is edited directly on the VPS in RDP.

## Server host
- OVH VPS, Windows Server 2025, public IP `15.204.112.102`, install `C:\server`.
- MariaDB 10.6, DB `xi_relaunch` (root / `richard`, localhost only).
- Ports: login/data 54230, auth 54231, view 54001, search 54002, map UDP 54230.

## How the servers run
- Scheduled task **`FFXIRelaunch`** (SYSTEM, at startup) runs
  `C:\server\relaunch-supervisor.ps1`, which launches and watches
  `xi_connect` / `xi_world` / `xi_search` / `xi_map` and restarts any that die.
- Survives reboots and crashes. Started/stopped via the desktop bats below.
- NOTE: the repo's `supervisor.ps1`, `relaunch-start.bat`, `kill-servers.bat`
  are STALE Legendary/Azure copies (`D:\server`, `xidb`, azure SSH) — do NOT
  use them here. Use the `Relaunch - *` bats.

## Desktop / Start-menu tools (`Relaunch - *.bat`)
| Tool | Action |
|---|---|
| Status | Which servers + supervisor are up |
| Start Server | Run the FFXIRelaunch task (start all 4) |
| Stop Server | Stop task + kill all 4 |
| Restart Map | Kill xi_map; supervisor relaunches it |
| Map Logs / Other Logs | Tail map / connect+world+search logs |
| Clear Sessions | `DELETE FROM accounts_sessions` (fixes "already logged in") |
| **Troll Check** | Read-only sweep vs `tools/troll-watch/watchlist.json` (IPs, logins, remake patterns). Does not ban. Full write-up: `tools/troll-watch/HISTORY.md`. |
| Deploy | git pull + apply zz_ SQL + restart (Lua/SQL, no C++ build) |
| **Rebuild** | git pull (optional) → stop → SQL → **C++ rebuild** (vcvars64 + cmake/Ninja) → restart. Backs up `xi_*.exe`→`.bak` and restores on build failure. |
| Push to GitHub | Commit + push `C:\server` to `origin/relaunch` (run in RDP) |

## Rebuild details
`Relaunch - Rebuild.bat` → `C:\server\vps-rebuild.ps1`. Windows locks running
`.exe`, so the servers are stopped before compiling. Binaries output to
`C:\server` root (Ninja/MSVC 2022 Release). The Azure `[5]` website-publish
step (www.ffxi-legendary.com) is NOT ported — that was box-side docs infra.

## Git / GitHub
- `git pull` / `git push` work from an **interactive RDP session** (Windows
  Credential Manager). They do NOT work over a headless SSH session.
- Back up with **`Relaunch - Push to GitHub.bat`**.
