# Relaunch player launcher

Install the official **Ashita v4** or **Windower 4** client hook, point it at Relaunch, and launch. Built so a new player can start from this folder without touching an existing Windower install.

## What it does

1. Finds your `FINAL FANTASY XI` folder (`FFXiMain.dll`).
2. Downloads, on demand:
   - [Ashita v4](https://github.com/AshitaXI/Ashita-v4beta) snapshot (`main.zip`, GPLv3)
   - [Windower 4](https://files.windower.net/4/live/Windower.exe) from windower.net
   - [xiloader](https://github.com/LandSandBoat/xiloader/releases/latest) (`xiloader.exe`, GPLv3)
3. Writes a **Relaunch** profile (server `15.204.112.102`, resolution, window mode).
4. Copies Relaunch addons and a startup script.
5. **Play** boots Ashita (`ashita-cli.exe relaunch.ini`) or opens Windower so you can pick the Relaunch profile.

Everything lands in `%LOCALAPPDATA%\Relaunch`. Your current Windower/Ashita folders are not modified.

This does **not** install the FFXI client. You still need a legal retail install that has been updated at least once.

## New-player test (Ashita)

You already play on Windower. Use this path to pretend you have never installed Ashita:

1. Double-click `Launch Relaunch.bat`.
2. Confirm the detected FFXI folder (Browse if Detect is wrong).
3. Leave **Ashita v4** selected.
4. Click **Install / Update**. Wait for the zip extract.
5. If xiloader fails to start later, click **VC++ x86 redist** once.
6. Set resolution / Borderless if you want.
7. Click **Play**.
8. In the xiloader console: `2` to create an account, or `1` to log in with your existing Relaunch login.
9. You should land in game with Ashita (Insert opens the Ashita menu). A `[relaunch]` welcome line means the helper addon loaded.

Leave your usual Windower shortcut alone. Close Ashita when you are done and play Windower as before. Ashita is configured with `sandbox = 1` so it should not stomp retail/Windower registry settings.

## Licenses (do not freeze old copies)

| Piece | Source | License / rule |
|---|---|---|
| Ashita | Official GitHub snapshot, refreshed on Install | GPLv3 — keep current; do not ship a stale zip |
| Windower | Official `Windower.exe` | Their binary; it self-updates |
| xiloader | LSB latest release | GPLv3 |
| FFXI | Player's own install | Square Enix — never bundled |

Relaunch-authored addons in this folder are ours.

## Files

| Path | Role |
|---|---|
| `Launch Relaunch.bat` | Double-click entry |
| `RelaunchLauncher.ps1` | UI + download + config |
| `addons/ashita/relaunch/` | Ashita welcome addon |
| `%LOCALAPPDATA%\Relaunch\launcher.json` | Your last settings |
