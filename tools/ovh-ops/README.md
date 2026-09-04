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

## Crash investigation

Three layers, because no single one sees every way xi_map can die.

| Layer | What it catches | Where |
|---|---|---|
| Wheaty (in-process) | most crashes, with its own symbolised report + flight recorder | `C:\server\dmp\*.log` |
| WER (kernel) | crashes Wheaty cannot survive long enough to report — e.g. stack overflow | `C:\server\dmp\wer\*.dmp` |
| Supervisor log | restarts, hung-map force-kills, and silent deaths inferred from them | `C:\server\relaunch-supervisor.log` |

| Scheduled Task | Schedule | Script | Purpose |
|---|---|---|---|
| `Relaunch-CrashWatcher` | every 1 min | `run_crash_watcher_relaunch.ps1` -> `tools/crash-watcher/crash_watcher_relaunch.py` | fast Discord post of a new Wheaty report or supervisor hang-kill |
| `Relaunch-CrashTriage` | every 10 min | `run_crash_triage_relaunch.ps1` -> `triage_dump.ps1` | slow cdb post-mortem + SILENT DEATH alerts |

**Ask "why did the server go down":**

```powershell
C:\relaunch-ops\crash_report.ps1 -Hours 24             # timeline, causes, repeat offenders
C:\relaunch-ops\crash_report.ps1 -Hours 24 -Context 10 # + map log before each death
C:\relaunch-ops\triage_dump.ps1                        # cdb the newest dump
C:\relaunch-ops\triage_dump.ps1 -All                   # cdb everything not yet triaged
```

`crash_report.ps1` groups repeats by **source file**, not by frame: one broken data
structure surfaces through several functions (treasure_pool.cpp crashed once in
`delMember` and once in `checkTreasureItem` on 2026-09-01/02), and per-frame grouping
hides exactly that. It also separates deliberate restarts (supervisor cold start, or a
rebuild near the restart time) from genuine silent deaths, so a deploy is not reported
as a crash.

### Debugging Tools for Windows (installed 2026-09-02)

`cdb.exe` lives at `C:\Program Files (x86)\Windows Kits\10\Debuggers\x64`. Installed with:

```
curl.exe -L -o C:\Temp\winsdksetup.exe "https://go.microsoft.com/fwlink/?linkid=2272610"
C:\Temp\winsdksetup.exe /features OptionId.WindowsDesktopDebuggers /quiet /norestart
```

Why it earns its place: Wheaty only names frames it has PDBs for. The 2026-09-01
18:55 crash came out of Wheaty as `?trim@SQLString@sql@@...+52FF`; cdb rendered it as
`mariadbcpp!sql::SQLString::trim+0x52ff` executing `lock xadd dword ptr [rdi+8],eax`
with `rdi=0x00000000bee5a4e0` — an interlocked refcount decrement through a junk
pointer, i.e. a use-after-free inside the MariaDB connector. That is a diagnosis; the
Wheaty line was not.

Three hard-won details are baked into `triage_dump.ps1`; do not "simplify" them away:

1. **Commands go in on stdin, not `-c`.** With only stdout redirected, cdb blocks
   forever at the `0:000>` prompt under SSH or Task Scheduler. With `-c` *and* a `q`
   on stdin it races the two and quits after the first command, writing an empty
   report. The whole script on stdin, ending in `q`, is deterministic.
2. **No `.reload /f`.** Forcing every module's symbols wedged cdb past 420s here.
   Deferred loading fetches only what the stack touches.
3. **Local symbols by default.** This box can barely reach `msdl.microsoft.com`;
   local-only finishes in ~6s. The cost is that `!analyze -v` blames
   `ntdll_wrong_symbols` — ignore its verdict and read `faulting`/`instr` and the
   stack, which are correct. `-WithSymbolServer` gets a real `!analyze` if you wait.

**Symbol archiving.** Every rebuild overwrites `xi_map.pdb`, which would make older
dumps permanently unreadable. `triage_dump.ps1` runs `symstore add` on each pass, so
`C:\symbols\local` keeps one copy per build signature and old dumps stay analysable.

**WER local dumps** were enabled 2026-09-02 for the silent deaths Wheaty misses
(a real one happened 2026-09-01 07:15:43: no dump, no watchdog line, no force-kill):

```
HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\xi_map.exe
  DumpFolder = C:\server\dmp\wer   DumpType = 2 (full)   DumpCount = 5
```

Full dumps are ~600 MB each, hence the count of 5. To undo, delete that key.

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
