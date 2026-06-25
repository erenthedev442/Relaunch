# Relaunch — First Playtest Launch Checklist

> Goal: bring the **relaunch** instance up on the Azure box for a controlled first playtest, without touching the live Legendary server. The relaunch runs as a *separate* instance: own DB (`xi_relaunch`), own ports (+10, MAP_PORT 54240), own services (`xi_*_relaunch`), own dir (`/home/azureuser/relaunch`). Starting it does **not** affect live.

## Current state (verified on the box 2026-06-25)

| Piece | State |
|---|---|
| C++ build (`xi_map`, `xi_connect`) | ✅ present, built **today 03:49** |
| DB `xi_relaunch` | ✅ exists, **131 tables**, populated |
| Config | ✅ `SQL_DATABASE=xi_relaunch`, `MAP_PORT=54240` (+10) |
| Services `xi_*_relaunch` (world/connect/map/search) | ⚠ defined but **disabled + inactive** (not started) |
| `/home/azureuser/relaunch` | ⚠ **NOT a git checkout** — code is synced by your deploy process, not `git pull` |

**Bottom line:** the instance is provisioned and built. Launch = sync latest code → (apply DB) → start services → smoke-test.

---

## Step 0 — Sync the latest relaunch code  ⚠ do this first

The box's Lua is frozen at the 03:49 build. Everything committed to `fjb/relaunch` **after** that is NOT on the box yet (the dir isn't git, so nothing auto-pulls). Pending sync:

- **New:** `modules/custom/commands/aoews.lua`
- **Modified:** `endless_tower.lua`, `weekly_recap.lua`, `auto_buff_henge.lua`, `daily_login_bonus.lua`, `gainexp.lua`, `Tournament.lua`, `new_char_wardrobe_sizes.lua`
- **Removed:** `modules/custom/lua/mission_wardrobe_unlocks.lua`  ← must be deleted on the box too, not just added
- **Parallel session:** the Spell & Skill Mastery system (`spell_skill_mastery_catalog.lua` + its module/`!empower` command)

Sync the **whole `modules/custom/` tree** from the latest `relaunch` branch via your deploy/sync path (e.g. `deploy-everything-sync.bat`, or an `rsync -a --delete` of `modules/custom/` to `/home/azureuser/relaunch/modules/custom/`). The `--delete`/explicit removal matters so `mission_wardrobe_unlocks.lua` actually leaves the box.

> Recommendation: make `/home/azureuser/relaunch` a real git checkout of the `relaunch` branch (or document the rsync) so future syncs are one command and deletions propagate. Right now there's no reproducible deploy path for this instance.

---

## Step 1 — Apply DB migrations to `xi_relaunch`

`sql/zz_*.sql` and `modules/custom/sql/` apply on a normal deploy. For a first playtest, the one that matters:

- **`modules/custom/sql/restore_geo_retail.sql`** → apply to `xi_relaunch`, or GEO mains have **0 MP**. (GEO also needs the build's `grades.cpp` to be stock/retail — the relaunch build inherits this from base; verify in Step 3.)

```
PW=$(grep -iE SQL_PASSWORD ~/relaunch/settings/network.lua | sed -E "s/.*'([^']*)'.*/\1/")
mysql -u xiuser -p"$PW" xi_relaunch < ~/relaunch/modules/custom/sql/restore_geo_retail.sql
```

---

## Step 2 — Start the services (does not touch live)

```
sudo systemctl start xi_world_relaunch
sudo systemctl start xi_connect_relaunch
sudo systemctl start xi_map_relaunch
sudo systemctl start xi_search_relaunch
# (xi_relaunch.service may be an umbrella that pulls these in — try it first if so)
```

Verify:
```
systemctl is-active xi_world_relaunch xi_connect_relaunch xi_map_relaunch xi_search_relaunch
tail -n 50 ~/relaunch/log/map-server.log          # expect the startup banner + module-load lines, 0 Lua errors
grep -iE "lua_error|\.lua:|attempt to|traceback" ~/relaunch/log/map-server.log | tail
```

> Keep the services **disabled** (don't `systemctl enable`) for a controlled playtest — that way a box reboot won't auto-launch relaunch alongside live until you're ready.

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
