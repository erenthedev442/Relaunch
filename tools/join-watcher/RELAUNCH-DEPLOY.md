# Point #player-logins at Relaunch (OVH box)

The `#player-logins` channel is fed by a Discord **webhook**. Today the poster is
`ffxi_join_watcher.py` running on the **Azure 1.0 box**, reading that box's local
DB — which is why the channel shows 1.0 logins. To show **Relaunch** logins, run
the Relaunch port (`ffxi_join_watcher_relaunch.py`) on the **OVH box** against
`xi_relaunch`, posting to the **same webhook**, and turn the Azure one off.

The code is committed:
- `tools/join-watcher/ffxi_join_watcher_relaunch.py` — the watcher (rides the
  server repo to `C:\server`; runs in-place so it can import `tools/docgen/_db.py`
  and read the live Lua). No edits needed on the box.
- `tools/ovh-ops/run_join_watcher_relaunch.ps1` — the 1-minute task wrapper
  (IDLE priority, log rotation), deployed to `C:\relaunch-ops\` by the ops
  self-sync (or copy it there by hand).

## One-time setup on the OVH box (3 live steps)

### 1. Prereq: a DB driver for the task's Python
The wrapper calls `C:\Program Files\Python312\python.exe`. Make sure it has a
driver (same one docgen uses). If in doubt:
```
& "C:\Program Files\Python312\python.exe" -m pip install pymysql
```
Quick smoke test (should print rows, not an error):
```
& "C:\Program Files\Python312\python.exe" "C:\server\tools\join-watcher\ffxi_join_watcher_relaunch.py"
```
On first run with no state it posts a one-time **“Join watcher armed”** message
and nothing else (it does NOT spam everyone currently online).

### 2. Drop the webhook secret
Put the **#player-logins** webhook URL (one line) in:
```
C:\relaunch-ops\.join_webhook
```
Reuse the SAME webhook the channel already uses — copy it from the Azure box's
`/etc/ffxi-join-watcher/webhook.url`, or grab a fresh one from Discord
(channel → Edit Channel → Integrations → Webhooks). One line, no quotes.

_(Optional)_ For the achievement / HL-rank / ascension feed, put a second
channel's webhook in `C:\relaunch-ops\.join_ach_webhook`. Omit the file and that
feed simply stays off.

### 3. Register the 1-minute task, then stop the Azure one
```
schtasks /Create /TN "Relaunch-JoinWatcher" ^
  /TR "powershell -NoProfile -ExecutionPolicy Bypass -File C:\relaunch-ops\run_join_watcher_relaunch.ps1" ^
  /SC MINUTE /MO 1 /RL HIGHEST /F /RU SYSTEM
```
Use the same account your other `Relaunch-*` tasks run as (SYSTEM is fine — the
DB connection uses the TCP creds from `network.lua`, not Windows auth).

Then **disable the Azure poster** so 1.0 logins stop:
```
sudo systemctl disable --now ffxi-join-watcher.timer
```

## Verify
- `C:\relaunch-ops\logs\join_watcher.log` shows a poll line each minute, no errors.
- A real login on Relaunch posts `Name logged in — N online` to #player-logins.
- No more posts originate from the Azure box.

## Notes
- Read-only SELECTs on `accounts` / `chars` / `accounts_sessions` / `char_vars`;
  touches zero game code and can't slow the map server.
- State (high-water marks + online set) lives in
  `C:\relaunch-ops\join-watcher\state.json`. Delete it to re-bootstrap.
- Achievement titles / HL tier names are parsed live from the server's own Lua,
  so new in-game content posts correctly with no maintenance here.
