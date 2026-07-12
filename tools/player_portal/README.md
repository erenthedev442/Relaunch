# Legendary FFXI — Player Portal

A small FastAPI service that lets players sign in with their **game account
login + password** and see their characters. It verifies the existing **bcrypt**
password hash from the live `accounts` table and never sees or stores plaintext.

```
Browser ──HTTPS──►  Cloudflare (your Pages site + a Tunnel for /api)
                          │
                          ▼
                   this API (uvicorn, 127.0.0.1:8080)  ──localhost──►  MariaDB xidb
```

The API is **read-only**. The frontend is the single-page `static/index.html`
(works as-is, or drop it into your Cloudflare Pages site).

---

## Step 1 — Create a dedicated READ-ONLY DB user

Do **not** reuse `xiuser`. Column-level grants keep the portal to exactly what it reads:

```sql
CREATE USER 'portal_ro'@'127.0.0.1' IDENTIFIED BY 'CHANGE_ME_strong_db_password';
GRANT SELECT (id, login, password, current_email, timecreate)             ON xidb.accounts       TO 'portal_ro'@'127.0.0.1';
GRANT SELECT (charid, accid, charname, nation, playtime)                  ON xidb.chars          TO 'portal_ro'@'127.0.0.1';
GRANT SELECT (charid, mjob, sjob, mlvl, slvl, hp, mp)                     ON xidb.char_stats     TO 'portal_ro'@'127.0.0.1';
GRANT SELECT (charid, itemId, location, quantity)                         ON xidb.char_inventory TO 'portal_ro'@'127.0.0.1';
GRANT SELECT (charid, enemies_defeated, times_knocked_out, battles_fought) ON xidb.char_history  TO 'portal_ro'@'127.0.0.1';
GRANT SELECT (charid, varname, value)                                     ON xidb.char_vars      TO 'portal_ro'@'127.0.0.1';
FLUSH PRIVILEGES;
```

(The user still reads the bcrypt hash to verify logins, but has no write access and
can't touch any other table/column. These grants cover everything `/api/me` shows:
identity, jobs, gil, playtime, combat history, and Prestige/Rebirth/HL progression.)

## Step 2 — Install & configure

```bash
cd tools/player_portal
python3 -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt

cp .env.example .env
# Edit .env:  set PORTAL_DB_PASS, and generate a secret:
python -c "import secrets; print('PORTAL_JWT_SECRET=' + secrets.token_urlsafe(48))"
```

## Step 3 — Run

```bash
uvicorn app:app --host 127.0.0.1 --port 8080          # dev: add --reload
```

Open `http://127.0.0.1:8080/` (set `PORTAL_COOKIE_SECURE=false` in `.env` for
local http testing; **true** in production).

### systemd (on the box)

```ini
# /etc/systemd/system/ffxi-portal.service
[Unit]
Description=Legendary FFXI Player Portal
After=network.target mariadb.service

[Service]
User=azureuser
WorkingDirectory=/home/azureuser/server/tools/player_portal
ExecStart=/home/azureuser/server/tools/player_portal/.venv/bin/uvicorn app:app --host 127.0.0.1 --port 8080
Restart=on-failure

[Install]
WantedBy=multi-user.target
```
```bash
sudo systemctl enable --now ffxi-portal
```

## Step 4 — Expose it (HTTPS, no open ports)

The app serves **both** the login page and `/api/*` on `:8080`, so a single
tunnel hostname pointed at it is a fully same-origin portal — first-party session
cookie, zero CORS, nothing else to host. Use the ready config in
[`cloudflared/config.yml`](cloudflared/config.yml):

```bash
# on the box, one-time
cloudflared tunnel login
cloudflared tunnel create ffxi-portal                 # note the <UUID> it prints
cloudflared tunnel route dns ffxi-portal portal.yourdomain.com
cp cloudflared/config.yml ~/.cloudflared/config.yml    # fill in <UUID> + your hostname
sudo cloudflared service install                       # run as a service (survives reboot)
```
Keep `PORTAL_COOKIE_SAMESITE=lax` and leave `PORTAL_CORS_ORIGINS` empty, then link
players to `https://portal.yourdomain.com` from the docs site / Discord.

> **A custom domain is required.** A tunnel hostname must live in a Cloudflare
> zone you control — `*.pages.dev` can't host one. If you only have
> legendary-ffxi.pages.dev today, add any cheap domain to your Cloudflare account
> first (and, optionally, point Pages at it too).

**Alternative — split hosting** (frontend on Pages, API on its own host): publish
`static/index.html` to Pages, set `PORTAL_CORS_ORIGINS=https://<your-pages-site>`
and `PORTAL_COOKIE_SAMESITE=none` (requires `PORTAL_COOKIE_SECURE=true`). Same-
origin (above) is simpler and more secure — prefer it unless you have a reason not to.

---

## Endpoints

| Method | Path          | Body                          | Returns                                  |
|--------|---------------|-------------------------------|------------------------------------------|
| POST   | `/api/login`  | `{ "login", "password" }`     | sets `HttpOnly` session cookie           |
| GET    | `/api/me`     | — (cookie)                    | `{ login, email, since, characters[] }`  |
| POST   | `/api/logout` | — (cookie)                    | clears the cookie                        |
| GET    | `/api/health` | —                             | `{ ok: true }`                           |

`characters[]` per character: `name, nation, mainJob, mainLvl, subJob, subLvl,
hp, mp, gil, playtimeH, kills, deaths, battles, hlTier, ascensions, nmKills,
prestigeLvl, rebirthCount` (the last two are for the character's current main job).
To surface more, extend the query in `app.py` (`/api/me`) and add the column to
the read-only grant in Step 1 — the docgen `player_profiles.py` queries are a good
reference for what's available.

## Security checklist

- [x] Verifies against the existing bcrypt hash; plaintext never stored/logged.
- [x] Dedicated **read-only** DB user (Step 1) — not `xiuser`.
- [x] Bind to `127.0.0.1`; reach it **only** via the tunnel (never open the port).
- [x] HTTPS everywhere; `HttpOnly` + `Secure` + `SameSite` session cookie.
- [x] Per-IP login rate limit (scaffold-grade; swap for `slowapi`/redis at scale).
- [x] Constant-time-ish login (dummy bcrypt on unknown accounts) to block user enumeration.
- [ ] Consider a **portal-specific** credential (verify once with the game password,
      then set a portal password/2FA) so the portal isn't an attack surface for
      game accounts. Most private servers reuse the game login — your call.

## Notes / edge cases

- **Legacy accounts:** a stored password that isn't a bcrypt hash (`$2…`, 60 chars)
  is a pre-bcrypt account. Those can't be verified here — have the player log into
  the **game** once first, which re-hashes it to bcrypt.
- **SPOT VM:** if this runs on the game box it goes down during Azure evictions —
  but so does the game, so that's acceptable. Don't host it somewhere that assumes
  the box is always up.
- This is a **standalone service** — it is *not* started by the game deploy/rebuild.
  It ships to the box with `tools/` but you run it separately (systemd above).
