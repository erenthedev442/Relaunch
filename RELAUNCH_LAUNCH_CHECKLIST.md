# Relaunch — First Playtest Launch Checklist

> Goal: bring the **relaunch** instance up on the Azure box for a controlled first playtest, without touching the live Legendary server. The relaunch runs as a *separate* instance: own DB (`xi_relaunch`), own ports (+10, MAP_PORT 54240), own services (`xi_*_relaunch`), own dir (`/home/azureuser/relaunch`). Starting it does **not** affect live.

## Current state (verified on the box 2026-06-25 ~16:51 UTC)

| Piece | State |
|---|---|
| C++ build (`xi_map`, `xi_connect`) | ✅ present, built **today 03:49** |
| DB `xi_relaunch` | ✅ **131 tables**, GEO spells (26) ✓, mastery respawn SQL ✓ |
| Config | ✅ `SQL_DATABASE=xi_relaunch`, `MAP_PORT=54240` (+10) |
| Services `xi_*_relaunch` (world/connect/map/search) | ✅ **all ACTIVE** — started ~16:35 UTC, restarted 16:51 after code sync |
| Code on box | ✅ synced to branch HEAD `819935937b` via `git archive + rsync` |
| New modules loaded | ✅ `augment_catalyst_drops`, `spell_skill_mastery`, `job_mastery` |

**Bottom line: server is UP.** Smoke-test (Steps 0–2 complete) → run Step 3 to gate human playtest.

---

## ✅ Step 0 — Sync the latest relaunch code  *(DONE 2026-06-25)*

Code on the box is at HEAD `819935937b`. Sync command (established as the standard deploy path):

```bash
# From D:\server_relaunch on the laptop:
git archive HEAD modules/custom/ | ssh -i "C:/Users/richa/Downloads/ffxi-server_key.pem" azureuser@172.215.213.23 \
  "mkdir -p /tmp/rlstage && tar -C /tmp/rlstage -xf - && rsync -a --delete /tmp/rlstage/modules/custom/ ~/relaunch/modules/custom/ && rm -rf /tmp/rlstage && echo SYNC OK"
# Then restart xi_map_relaunch if new addOverride modules were added:
ssh ... "sudo systemctl restart xi_map_relaunch"
```

`git archive HEAD` reads only committed state, so parallel-session WIP files never leak to the box.

---

## ✅ Step 1 — Apply DB migrations to `xi_relaunch`  *(DONE — confirmed)*

- **`restore_geo_retail.sql`** ✅ applied — 26 GEO spells confirmed in `spell_list`
- **`mastery_rotation_respawns.sql`** ✅ applied — Jaggedy-Eared Jack `respawntime=1800, spawntype=0` confirmed

To apply a SQL file in future (e.g. new custom SQL after a playtest fix):
```bash
PW=$(grep -iE SQL_PASSWORD ~/relaunch/settings/network.lua | sed -E "s/.*'([^']*)'.*/\1/")
mysql -u xiuser -p"$PW" xi_relaunch < ~/relaunch/modules/custom/sql/<file>.sql
```

---

## ✅ Step 2 — Start the services  *(DONE 2026-06-25 ~16:35 UTC)*

```
sudo systemctl start xi_world_relaunch
sudo systemctl start xi_connect_relaunch
sudo systemctl start xi_map_relaunch
sudo systemctl start xi_search_relaunch
# (xi_relaunch.service may be an umbrella that pulls these in — try it first if so)
```

**Verified (2026-06-25 16:51 UTC):** all 4 services active, `The map-server is ready to work`, 118 NMs spawned, 0 Lua errors. Services remain **disabled** (won't auto-start on reboot) — keep it this way for controlled playtest.

```bash
# Re-start after a box reboot:
sudo systemctl start xi_world_relaunch xi_connect_relaunch xi_map_relaunch xi_search_relaunch
```

---

## Step 3 — Smoke test (the playtest gate)

**Client access:** testers point their client at the relaunch **connect/login port (+10 from live)**. Confirm one tester can reach the lobby before inviting more.

Run through, watching `~/relaunch/log/map-server.log` for errors the whole time:

- [ ] **New character** → confirm the onboarding grants fire: **300k gil**, **25 Hunt Marks**, all spells/trusts/maps/missions (Character_Upgrader, ~3 s after login), **8 full wardrobes** (the conflict fix), **RUN + GEO** selectable in the Mog House.
- [ ] **GEO has MP** (the `restore_geo_retail` check) — make a GEO, confirm MP > 0. If 0, the SQL didn't apply or the build's `grades.cpp` isn't stock.
- [ ] **Hunting League** — `!hunt` → hub loads, spawn a Rank-I NM, kill it, confirm marks awarded + tier-unlock menu works.
- [ ] **Economy** — buy a Beastmens Medal with marks, buy a Bronze armor piece with the medal.
- [ ] **Commands** — `!buff`, `!shop`, `!apex`, `!tower`, and the new **`!aoews <name>`** (unlock at the Rupture Sage first, then bind a WS — confirm the splash fires).
- [ ] **Tournament** (optional, GM) — run a quick `!tournament` and confirm the **champion reward** (2,500 marks + 500 Infamy) pays out.
- [ ] **No crashes / no Lua errors** in the map log across all of the above.

---

## Step 4 — C++ rebuild bundle (NOT blocking this playtest)

Status of the three known C++ gaps:

| Gap | Status | Action |
|---|---|---|
| **Barrage** no-per-shot-consume | ✅ already in the C++ (`battleentity.cpp:3340`) — in the 03:49 build | none |
| **GEO 0-MP** | SQL fix (`restore_geo_retail.sql`) + stock `grades.cpp` (inherited from base) | apply the SQL (Step 1) — not a rebuild |
| **MaxSC** leaderboard stat | ❌ `getAddEffectParam` not exposed in `lua_baseentity.cpp`; `combat_records.lua` safe-fails | defer to a future rebuild — purely a stat, not a blocker |

So **no rebuild is required to start the playtest.** Bundle MaxSC into the next routine relaunch rebuild whenever one happens.

---

## Step 5 — Stop / rollback

```
sudo systemctl stop xi_map_relaunch xi_connect_relaunch xi_search_relaunch xi_world_relaunch
```
Live Legendary is unaffected throughout (separate DB, ports, services, dir). To wipe a bad playtest and reseed, restore `xi_relaunch` from a fresh dump of the intended seed.

---

## Open items / risks

- **No reproducible deploy path** for the relaunch dir (not git, no script found). Establishing one is the single biggest gap for ongoing playtest iteration. *(Recommended next infra task.)*
- **Client config for testers** — they need a bootloader/pol pointed at the relaunch port; document the exact tester setup so onboarding playtesters is one-step.
- **Playtest economy/difficulty tune** — the Phase 1/2 nerfs are in but unplaytested; expect to adjust mark faucets and NM stats after the first session.
