# Troll watchlist

Log of IPs, usernames, and remake patterns from the 2026-08 / 2026-09 waves.
The file to edit is **`watchlist.json`**. The check is read-only.

**Richard:** start with **[HISTORY.md](HISTORY.md)** — Bro/High IPs, Kahz/Ririn RDP removal, name-squat deletes, and the live firewall list.

## Run a check (VPS)

Desktop: **Relaunch - Troll Check**

Or:

```powershell
powershell -NoProfile -File C:\server\tools\troll-watch\check_trolls.ps1
powershell -NoProfile -File C:\server\tools\troll-watch\check_trolls.ps1 -Hours 168
```

## What not to touch

- **Katrrine account `1075`** — real player, name collision only.
- **IP `185.124.0.99`** — GM home. A troll used that *string* as a login. Never firewall it.
- **Duda / Sara / Sofia / Thanos** — normal Reforge players.
- **Gaspard on `zogen`** — real player. The squat was **Gaspar** / login `gaspard`.

## After a confirmed hit

Add the new login, char name, and exact IPs to the right cluster in `watchlist.json`.
Do not add a `/24` prefix unless several exact IPs in that block already match.
