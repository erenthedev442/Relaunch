# Deploying the Player Portal (relaunch test → portal.ffxi-legendary.com)

> **⚠ Current deployment = the OVH VPS (Windows). See [DEPLOY_WINDOWS.md](DEPLOY_WINDOWS.md).**
> The relaunch server (and its `xi_relaunch` DB) moved off Azure to the OVH VPS on
> 2026-07-06, and the portal now runs **there**, co-located with the DB. This
> Linux/systemd guide describes the retired Azure deployment and is kept for
> reference only.

The portal is a **standalone FastAPI service** — it is *not* part of the game
deploy/rebuild and does not need the game checkout. It runs on the box behind a
Cloudflare Tunnel. Target here: the **relaunch** box, reading the **xi_relaunch**
DB, served at **https://portal.ffxi-legendary.com**.

You run these — the tunnel login opens a browser to *your* Cloudflare account, so
it can't be scripted. Everything else is one script.

## Prereqs on the box
- Python 3.10+ (`python3 --version`)
- `cloudflared` installed ([Cloudflare docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/))
- `ffxi-legendary.com` is a zone in your Cloudflare account
- A MySQL/MariaDB admin login for the relaunch DB (to create the portal users)

## 1. Get the portal code onto the box
The portal lives in the **Relaunch repo** (migrated from FJB/Legendary
2026-07-11) at `tools/player_portal`. Sparse-clone it to its own directory
(keeps it clear of the game checkout):
```bash
git clone --branch relaunch --filter=blob:none --sparse https://github.com/richardknutzjr/Relaunch.git ~/ffxi-portal-relaunch
git -C ~/ffxi-portal-relaunch sparse-checkout set tools/player_portal
cd ~/ffxi-portal-relaunch/tools/player_portal
```
(To update later: `cd ~/ffxi-portal-relaunch && git pull`.)

## 2. Run the setup script
Creates the venv, the scoped `portal_ro`/`portal_rw` DB users, the recoverable
`portal_item_log` table, a `.env` (with a generated JWT secret, `COOKIE_SECURE=true`),
and a systemd service on **127.0.0.1:8090**. It prompts for the DB admin password
and lets you set the two portal user passwords.
```bash
bash deploy/setup_portal.sh
# defaults: DB_NAME=xi_relaunch, PORT=8090, SERVICE_NAME=ffxi-portal-relaunch
# override like: DB_NAME=xi_relaunch PORT=8090 bash deploy/setup_portal.sh
```
At the end it curls `/api/health` — you should see `{"ok":true}`.

## 3. Stand up the named tunnel → portal.ffxi-legendary.com
```bash
cloudflared tunnel login                                   # interactive: pick the ffxi-legendary.com zone
cloudflared tunnel create ffxi-portal-relaunch             # prints <UUID>, writes ~/.cloudflared/<UUID>.json
cloudflared tunnel route dns ffxi-portal-relaunch portal.ffxi-legendary.com
```
Write `~/.cloudflared/config.yml` (fill in `<UUID>` and your home dir):
```yaml
tunnel: ffxi-portal-relaunch
credentials-file: /home/YOUR_USER/.cloudflared/<UUID>.json
ingress:
  - hostname: portal.ffxi-legendary.com
    service: http://127.0.0.1:8090
  - service: http_status:404
```
Run it as a service (survives reboot):
```bash
sudo cloudflared service install
```

## 4. Test
Open **https://portal.ffxi-legendary.com** and log in with an account that exists
on relaunch (if xi_relaunch mirrors live, your **rknutz3** works → you'll see Jbae).
Then: **Inventory → Manage items** to test offline move/discard (writes hit
xi_relaunch only, never live).

## Operate
```bash
sudo systemctl status ffxi-portal-relaunch      # app logs: journalctl -u ffxi-portal-relaunch -f
sudo systemctl restart ffxi-portal-relaunch     # after a `git pull`
```

## Roll back / tear down
```bash
sudo systemctl disable --now ffxi-portal-relaunch
sudo cloudflared tunnel route dns --overwrite-dns ffxi-portal-relaunch portal.ffxi-legendary.com  # or delete the DNS record in the dashboard
sudo cloudflared service uninstall
# DB: DROP USER 'portal_ro'@'127.0.0.1', 'portal_rw'@'127.0.0.1';  (portal_item_log can stay)
```

## Notes
- **Recover a discarded item:** it's in `xi_relaunch.portal_item_log` (full row incl. `extra`
  augment blob) — re-insert into `char_inventory` while the character is offline.
- **Going to production (live xidb) later:** re-run the script with `DB_NAME=xidb` and a
  distinct `SERVICE_NAME`/`PORT`, and a separate tunnel/hostname. Keep relaunch and live apart.
- **Security:** binds to 127.0.0.1 only (never expose the port); reachable solely via the tunnel;
  read paths use `portal_ro`, writes use `portal_rw`; passwords are bcrypt-verified, never stored.
