# Deploying the Player Portal on the OVH VPS (Windows)

**Goal:** run the portal **entirely on the OVH relaunch VPS**, co-located with the
`xi_relaunch` database, and retire the old Azure deployment. Nothing portal-related
stays on Azure.

Why this is the right move: the portal was first stood up on the Azure box back when
`xi_relaunch` was a second instance *on that same box*, so it read the DB over
`127.0.0.1`. The relaunch server has since moved to this VPS, so the DB is here now —
co-locating the portal with it makes `PORTAL_DB_HOST=127.0.0.1` correct again and keeps
the whole relaunch stack on one machine. The app code doesn't change; only the host,
the process manager (systemd → Scheduled Task), and where the tunnel runs.

**Security shape is unchanged:** the app binds `127.0.0.1` only and is reachable solely
through the Cloudflare tunnel. No inbound firewall ports are opened on the VPS, and the
DB is never exposed off-box.

---

## Prereqs on the VPS
- **Python 3.10+** — `py --version` (install from python.org; tick "Add to PATH").
- **cloudflared.exe** — download the Windows build from Cloudflare; put it on `PATH`.
- **MariaDB running with `xi_relaunch`** and listening on `127.0.0.1:3306` (the relaunch
  game DB — already here post-migration). A DB admin login (root) to create the portal users.
- Admin PowerShell for the Scheduled Task + cloudflared service steps.

---

## Fast path: the one-shot installer (recommended)

`deploy/setup_portal_windows.ps1` does steps 1–6 below (clone/pull, venv, DB users +
tables, `.env` with a fresh JWT secret, the scheduled task, and a health check) in a
single idempotent run. On the VPS, in an **elevated** PowerShell:

```powershell
# grab just the script (or clone the repo first and run it from there)
Set-ExecutionPolicy -Scope Process Bypass -Force
iwr -UseBasicParsing https://raw.githubusercontent.com/richardknutzjr/FFXI-Private-Server-FJB/Legendary/tools/player_portal/deploy/setup_portal_windows.ps1 -OutFile $env:TEMP\setup_portal_windows.ps1
& $env:TEMP\setup_portal_windows.ps1
# it prompts for the two portal DB passwords + the MariaDB root password, then
# stands the portal up on 127.0.0.1:8090 and health-checks it.
```

Add the tunnel once your operator hands you the token:
```powershell
& $env:TEMP\setup_portal_windows.ps1 -TunnelToken '<token-from-the-cloudflare-dashboard>' -SkipApp
```
Re-running is safe. The manual steps below are the same thing broken out, for reference
or troubleshooting.

---

## 1. Get the portal code onto the VPS
The portal lives in the **Relaunch repo** (migrated from FJB/Legendary
2026-07-11) at `tools/player_portal`. Use a sparse, blob-filtered clone so the
box doesn't pull the whole server tree:
```powershell
git clone --branch relaunch --filter=blob:none --sparse https://github.com/richardknutzjr/Relaunch.git C:\ffxi-portal-relaunch
git -C C:\ffxi-portal-relaunch sparse-checkout set tools/player_portal
cd C:\ffxi-portal-relaunch\tools\player_portal
```
(Update later with `C:\ffxi-portal-ops\Deploy-Portal.bat` — it WIP-backs any
local edits, resets to origin/relaunch, syncs pip, and restarts the task.)

## 2. Python venv + dependencies
```powershell
py -m venv .venv
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

## 3. Create the DB users + tables (on `xi_relaunch`)
Edit `sql\portal_setup_windows.sql` and replace the two `CHANGE_ME` passwords, then run it
against the local DB as admin:
```powershell
mysql -h 127.0.0.1 -u root -p xi_relaunch < sql\portal_setup_windows.sql
```
This creates `portal_ro` (read) + `portal_rw` (write) scoped to `127.0.0.1`, plus the
`portal_item_log` (discard-recovery) and `portal_vault` tables. Idempotent — safe to re-run.

## 4. Write the `.env`
```powershell
Copy-Item .env.example .env
notepad .env
```
Set:
```
PORTAL_DB_HOST=127.0.0.1          # DB is local on this VPS now
PORTAL_DB_PORT=3306
PORTAL_DB_USER=portal_ro
PORTAL_DB_PASS=<the read password from step 3>
PORTAL_DB_NAME=xi_relaunch
PORTAL_DB_WRITE_USER=portal_rw
PORTAL_DB_WRITE_PASS=<the write password from step 3>
PORTAL_JWT_SECRET=<see note>
PORTAL_COOKIE_SECURE=true
```
- **JWT secret:** to keep existing logins valid, copy `PORTAL_JWT_SECRET` from the old
  Azure `.env`. To force everyone to re-log in (clean cut), generate a fresh one:
  `.\.venv\Scripts\python.exe -c "import secrets; print(secrets.token_urlsafe(48))"`.
- `.env` is gitignored — it never leaves this box.

## 5. Smoke-test in the foreground
```powershell
.\.venv\Scripts\python.exe -m uvicorn app:app --host 127.0.0.1 --port 8090
# in another shell:
curl http://127.0.0.1:8090/api/health      # -> {"ok":true}
```
Ctrl-C once health is green.

## 6. Run it as a Scheduled Task (survives reboot)
Uses `deploy\portal-supervisor.ps1` (a restart loop that runs uvicorn and logs to
`portal-supervisor.log`), mirroring the game's `relaunch-supervisor.ps1`. In an **admin**
PowerShell:
```powershell
$ps = 'C:\ffxi-portal\tools\player_portal\deploy\portal-supervisor.ps1'
$action    = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ps`""
$trigger   = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
$settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1)
Register-ScheduledTask -TaskName 'FFXIPortal' -Action $action -Trigger $trigger -Principal $principal -Settings $settings
Start-ScheduledTask -TaskName 'FFXIPortal'
Start-Sleep 5; curl http://127.0.0.1:8090/api/health
```
Logs: `Get-Content C:\ffxi-portal\tools\player_portal\portal-supervisor.log -Tail 30 -Wait`.
Restart after an update: `Stop-ScheduledTask -TaskName FFXIPortal; Start-ScheduledTask -TaskName FFXIPortal`.

## 7. Move the Cloudflare tunnel to the VPS
`portal.ffxi-legendary.com` already routes to the `ffxi-portal-relaunch` tunnel — reuse it
so there's **no DNS change**. A tunnel can only run in one place at a time, so:

1. **On Azure — stop it first:** `sudo cloudflared service uninstall` (or `systemctl stop cloudflared-portal`).
2. **Copy the credentials file** `~/.cloudflared/<UUID>.json` from Azure to the VPS at
   `C:\Users\Administrator\.cloudflared\<UUID>.json`.
3. **Place the config:** copy `cloudflared\config.windows.yml` to
   `C:\Users\Administrator\.cloudflared\config.yml` and fill in `<UUID>` (it already points
   at `127.0.0.1:8090`).
4. **Install + start the service**, passing the config explicitly (the Windows service runs
   as LocalSystem, which otherwise looks in `C:\Windows\System32\config\systemprofile\.cloudflared\`):
   ```powershell
   cloudflared.exe --config C:\Users\Administrator\.cloudflared\config.yml service install
   Start-Service cloudflared
   ```

**Fresh-tunnel alternative** (if you'd rather not copy creds): this step is interactive —
`cloudflared tunnel login` opens a browser to *your* Cloudflare account, so **you** must run it:
```powershell
cloudflared tunnel login
cloudflared tunnel create ffxi-portal-vps
cloudflared tunnel route dns --overwrite-dns ffxi-portal-vps portal.ffxi-legendary.com
# set tunnel:/credentials-file in config.yml to the new name/UUID, then service install as above
```

## 8. Verify
Open **https://portal.ffxi-legendary.com**, log in with a relaunch account, and confirm you
see **live VPS data** (inventory/status reflect the current relaunch server, not the frozen
Azure snapshot). Test **Inventory → Manage items** to confirm the write path (move/discard/vault)
works against `xi_relaunch` here.

---

## 9. Decommission Azure (nothing portal stays there)
Once the VPS portal is verified:
```bash
# on the Azure box
sudo systemctl disable --now ffxi-portal-relaunch
sudo cloudflared service uninstall            # if not already removed in step 7.1
# drop the now-unused portal users from the OLD (frozen) Azure relaunch DB:
mysql -u root -p -e "DROP USER IF EXISTS 'portal_ro'@'127.0.0.1','portal_rw'@'127.0.0.1';"
```
The stale Azure `xi_relaunch` DB is no longer read by anything after this — retire it per your
Azure teardown plan. The portal now lives entirely on the OVH VPS.

---

## Notes
- **No inbound ports** are opened on the VPS — the app stays on `127.0.0.1` and is reachable
  only via the tunnel, exactly as before.
- **Recover a discarded item:** it's in `xi_relaunch.portal_item_log` (full row incl. the `extra`
  augment blob) — re-insert into `char_inventory` while the character is offline.
- **`localhost` vs `127.0.0.1`:** the app connects via TCP to `127.0.0.1`, which MariaDB matches to
  `user@'127.0.0.1'` — that's why the grants use `'127.0.0.1'`, not `'localhost'` (the socket/pipe
  identity). Keep them aligned if you change `PORTAL_DB_HOST`.
- The Linux/systemd runbook (original Azure deployment) is preserved in `DEPLOY.md` for reference.
