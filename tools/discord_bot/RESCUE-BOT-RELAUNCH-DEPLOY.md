# `!rescue` on Relaunch 2.0 (#rescue-me)

Make `!rescue <charname>` in the **#rescue-me** channel unstick a player on the
**Relaunch 2.0** server, the same way it already does on Azure 1.0.

## What it does
`rescue_bot.py` mirrors the engine's offline rescue
(`CLuaBaseEntity::resetPlayer`): for the named character it clears the
`accounts_sessions` row and moves them to **Lower Jeuno** (zone 245, the exact
coordinate the C++ uses), so a player stuck on a broken/instance zone or blocked
by a stale "already logged in" session can log right back in.

- **2.0-only.** It runs on the OVH box against localhost `xi_relaunch`. The 1.0
  Azure rescue bot is **left running and untouched** — one `!rescue` in
  #rescue-me is handled by both bots, each resetting its own server. (This is
  required: `xi_relaunch` is localhost-only, so the 2.0 reset must run on OVH.)
- **A separate Discord bot.** A second gateway connection can't share the 1.0
  bot's token, so this needs its own Discord application/token. Both bots sit in
  the same channel and each posts its own confirmation.

## Live steps on the OVH box

### 1. Files (committed — land on the next game deploy, or scp now)
- `tools/discord_bot/rescue_bot.py`
- `tools/discord_bot/_db.py` (already present — the xi_relaunch connector)
- `tools/ovh-ops/run_rescue_bot_relaunch.ps1` (daemon wrapper: restart loop, IDLE
  priority, log rotation)

### 2. Install discord.py (once)
```
& "C:\Program Files\Python312\python.exe" -m pip install -U discord.py
```

### 3. Create the Discord bot (Discord side, ~3 min)
1. <https://discord.com/developers/applications> → **New Application** (e.g.
   "Relaunch Rescue").
2. **Bot** tab → **Reset Token** → **Copy** — this is `RESCUE_BOT_TOKEN`.
3. On the same Bot tab, turn **Message Content Intent** **ON** (required — it
   reads the text of `!rescue`). Presence / Server Members can stay off.
4. **OAuth2 → URL Generator**: scopes **`bot`**; permissions **View Channels** +
   **Send Messages** + **Read Message History**. Open the URL, add it to your
   server.

### 4. Configure (box, gitignored `config.py`)
`config.py` lives at `C:\server\tools\discord_bot\config.py` (copy from
`config.example.py` if it doesn't exist yet). Set:
```python
RESCUE_BOT_TOKEN  = "<the token from step 3>"
RESCUE_CHANNEL_ID = 123456789012345678   # #rescue-me channel ID (Developer Mode → right-click → Copy Channel ID)
RESCUE_ALLOWED_ROLE_ID = ""              # "" = anyone in the channel (matches 1.0); or a role ID to restrict
```

### 5. Register + start the daemon task
```
schtasks /Create /TN "Relaunch-RescueBot" ^
  /TR "powershell -NoProfile -ExecutionPolicy Bypass -File C:\server\tools\ovh-ops\run_rescue_bot_relaunch.ps1" ^
  /SC ONSTART /RL HIGHEST /F /RU SYSTEM
```
Make it unlimited + non-time-killed (matches the portal / LS-bridge daemons so
the scheduler never terminates it), then start it:
```
Set-ScheduledTask -TaskName Relaunch-RescueBot -Settings (New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -ExecutionTimeLimit ([TimeSpan]::Zero) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries)
schtasks /Run /TN "Relaunch-RescueBot"
```

## Verify
- `C:\relaunch-ops\logs\rescue_bot.log` shows `rescue bot online as <name>; watching channel <id>`.
- In #rescue-me, type `!rescue <a stuck 2.0 char>` → the bot replies
  `✅ <Name> rescued on Relaunch 2.0 → Lower Jeuno…` and that char can log in.
- The log records every invocation (who ran it, target, ok/fail) for audit.

## Notes / knobs
- **Rescue destination** is Lower Jeuno, hard-matched to the engine. To change it,
  edit the `ZONE_LOWER_JEUNO` / `RESCUE_*` constants at the top of `rescue_bot.py`.
- **Who can rescue:** default is anyone in #rescue-me (parity with 1.0). Set
  `RESCUE_ALLOWED_ROLE_ID` to gate it behind a role — recommended if you're
  worried about someone `!rescue`-ing an online player to bounce them (the reset
  deletes their session; for a truly-online player that can force a reconnect).
- **Online vs offline:** like the engine's offline path and `_rescue_jbae.py`,
  the reset is unconditional (that's what clears a *stale* stuck session). The
  position change only takes hold on the player's next login, so it's meant for
  stuck/offline characters.
