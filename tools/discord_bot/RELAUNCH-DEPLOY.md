# Point #linkshell at Relaunch (OVH box)

The `#linkshell` channel is fed by a Discord **webhook** (the "Legendary
Linkshell" poster). Today `ls_bridge.py` runs on the **Azure 1.0 box** (systemd
`ls_bridge.service`), tailing that box's `audit_chat` — which is why the channel
shows **1.0** linkshell chat. To show **Relaunch 2.0** chat, run the same bridge
on the **OVH box** against `xi_relaunch`, posting to the **same webhook**, and
turn the Azure one off. The bridge is DB-agnostic — no code fork needed.

Files (committed):
- `tools/discord_bot/ls_bridge.py` — the bridge (already on the box at
  `C:\server\tools\discord_bot\ls_bridge.py`).
- `tools/ovh-ops/run_ls_bridge_relaunch.ps1` — supervisor wrapper (restart loop,
  IDLE priority, log rotation). Tracked, so it lands at
  `C:\server\tools\ovh-ops\` on the next game deploy (or scp it over).

## Already confirmed on the box (2026-08-27)
- `audit_chat` exists in `xi_relaunch`; the in-game linkshell is named
  **"Legendary"** → `LS_BRIDGE_NAME = "Legendary"`.
- `ls_bridge.py` and `tools/docgen/_db.py` are present.
- **Chat audit is OFF** (`AUDIT_CHAT`/`AUDIT_LINKSHELL = false` in
  `C:\server\settings\map.lua`); newest `audit_chat` row is **2026-07-05**, so
  nothing is being logged now. Step 1 re-enables it (needs a map restart).

## Live steps on the OVH box

### 1. Turn chat audit back on  ⚠️ game-affecting (map restart)
In `C:\server\settings\map.lua`:
```
AUDIT_CHAT      = true,
AUDIT_LINKSHELL = true,
```
Restart the map server (audit is read at boot). After the restart, in-game
"Legendary" linkshell lines start landing in `audit_chat` again. This is the
only game-affecting step — pick your restart window.

### 2. Create the bridge config (webhook + LS name)
```
copy C:\server\tools\discord_bot\config.example.py C:\server\tools\discord_bot\config.py
```
Edit `config.py` and set:
- `LS_BRIDGE_WEBHOOK_URL` = the **#linkshell** webhook. **Reuse the SAME one** the
  Azure bridge uses (copy it from the Azure box's `config.py`), or make a fresh
  one: Discord → #linkshell → Edit Channel → Integrations → Webhooks. One URL.
- `LS_BRIDGE_NAME = "Legendary"`

`config.py` is gitignored, so the webhook never lands in git. Smoke test (prints a
baseline line, posts nothing historical):
```
& "C:\Program Files\Python312\python.exe" C:\server\tools\discord_bot\ls_bridge.py --once
```

### 3. Register the daemon task
```
schtasks /Create /TN "Relaunch-LSBridge" ^
  /TR "powershell -NoProfile -ExecutionPolicy Bypass -File C:\server\tools\ovh-ops\run_ls_bridge_relaunch.ps1" ^
  /SC ONSTART /RL HIGHEST /F /RU SYSTEM
```
Make it unlimited + non-time-killed (matches the portal tasks — the scheduler
must never terminate the long-lived daemon), then start it:
```
Set-ScheduledTask -TaskName Relaunch-LSBridge -Settings (New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -ExecutionTimeLimit ([TimeSpan]::Zero) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries)
schtasks /Run /TN "Relaunch-LSBridge"
```

### 4. Disable the Azure 1.0 bridge
On the Azure box, so 1.0 stops posting to #linkshell:
```
sudo systemctl disable --now ls_bridge.service
```

## Verify
- `C:\relaunch-ops\logs\ls_bridge.log` shows `baseline at lineID N` then clean polls.
- A line typed in the in-game **Legendary** linkshell shows up in #linkshell
  within a few seconds, posted by "Legendary Linkshell".
- No more posts originate from the Azure box.

## Notes
- One-way (game → Discord), webhook-only, no bot token. Tails `audit_chat` by
  auto-increment `lineID`, baselining at the newest row — it never replays the
  old 1.0 history sitting in the table.
- All Discord mentions are neutralized (`allowed_mentions parse=[]`), so a player
  typing `@everyone` in linkshell can't ping Discord.
- Cursor state: `C:\server\tools\discord_bot\ls_bridge_state.json` (re-baselines
  if deleted). `config.py` is untracked — recreate it if the checkout is wiped.
