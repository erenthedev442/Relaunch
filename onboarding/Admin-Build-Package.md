# Building the Legendary launcher zip (admin)

Goal: a single **`Legendary-Launcher.zip`** a new player can unzip and run with
zero configuration. You make it **once**, test it, and re-upload it whenever
Ashita updates.

## What goes in it
A copy of **Ashita v4**, pre-pointed at our server, plus `Play Legendary.bat`.
You do **NOT** put any FFXI game files in it — that's Square Enix's property and
players supply their own client. We only distribute the launcher + our config.

## Steps
1. Download **Ashita v4** from the official site (ashitaxi.com) and extract it to
   a clean folder, e.g. `Legendary-Launcher\`.
2. Run the Ashita v4 launcher GUI and **create a boot configuration** (call it
   **`Legendary`**) with:
   - **Server Address:** `172.215.213.23`
   - **Everything else: default** — our server uses the standard LSB ports, so
     you don't override any port.
   - Keep the addon/plugin list minimal for newcomers (the defaults are fine).
3. **Click Play and confirm it works** — you should reach the login, be able to
   create a fresh test account (account creation is ON), and zone in. This proves
   the saved config is correct.
4. Copy **`Play Legendary.bat`** (from this folder) into the root of the
   `Legendary-Launcher\` folder, next to `Ashita.exe`.
5. Select everything **inside** `Legendary-Launcher\` and **zip it** as
   `Legendary-Launcher.zip`. (Zip the contents so the player's unzip gives them a
   ready-to-run folder.)
6. Upload it to your Discord **#downloads** and paste that link into
   `Player-Install-Guide.md` (Step 2) and the guide on the docs site.

## Why Ashita for newcomers (even though you two use Windower)
The server accepts **both** clients at once — it's the same protocol. Ashita v4
is the only one where the server address bakes into a config you can ship, so
the player types nothing. Keep using Windower yourselves; hand newcomers Ashita.

## Maintenance
- When Ashita v4 publishes an update, rebuild the zip (re-download, re-apply the
  `Legendary` config, re-test, re-zip). A stale launcher is a common "can't
  connect" cause after a client patch.

---

## Connection reference (for troubleshooting / docs)

| Setting | Value |
|---|---|
| Server address | `172.215.213.23` |
| Login (view) port | 54001 |
| Login (auth) port | 54231 |
| Login (data) port | 54230 |
| Login (config) port | 51220 |
| Map port | 54230 |
| Search port | 54002 |
| Account creation | **Enabled** (self-serve on first login) |

These are the LSB defaults, which is why a player only needs the **server
address** set. Your Azure ports are already proven reachable from the public
internet (you and your brother both connect from separate home networks), so no
firewall/NSG changes are needed for new external players.
