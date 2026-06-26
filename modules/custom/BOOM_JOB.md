# Custom Job: "Boom" (relaunch — repurposed SMN slot)

A pet-less melee / hybrid DD built on the **Summoner job slot (job id 15)**. You
cannot truly delete a job or add a 23rd — the FFXI client has 22 fixed slots — so
"Boom" *repurposes* the SMN shell. The client still calls it "Summoner," shows the
Summoning-Magic category, and uses SMN AF models/animations; everything behind that
is server-side.

**Theme:** the summoner who stopped summoning — channels avatar power into staff and
body. Signature: a handful of elemental nukes that have a small chance to **DETONATE**
for big bonus damage.

Decisions (owner, 2026-06-25): name **Boom**, weapon **Staff**, magic = **a few
spells with a chance to explode for significant damage**.

---

## Phase 1 — BUILT

Lua + SQL (no rebuild) EXCEPT the job-change hook (C++ — needs `relaunch-rebuild.bat`).

- `modules/custom/lua/boom_job_catalog.lua` — ALL tuning (traits, spell set, detonation chance/damage, abilities).
- `modules/custom/lua/BoomJob.lua` — applies job traits while SMN is MAIN job, grants the spells, runs the detonation (`MAGIC_USE` listener), exposes the abilities (`xi.boomJob.*`), and reconciles traits instantly on job change.
- `modules/custom/commands/overload.lua` + `ignite.lua` — the two signature abilities (see below).
- `modules/custom/sql/boom_job_spells.sql` — sets the SMN learn-level byte (byte 15 of `spell_list.jobs`) so the slot can cast the 6 nukes. Pattern from `restore_geo_retail.sql`.
- `modules/custom/lua/unlock_adoulin_jobs.lua` — SMN added to the auto-unlock list so Boom is selectable by everyone (toggle: remove it to gate behind the retail unlock).
- **Removed** the retail-SMN custom modules (avatars are gone): `smn_avatar_boost.lua`, `bp_delay_uncap.lua`, `smn_avatar_gear_mods.sql`.

**Signature abilities** (delivered as commands — the avatar JA buttons are inert; gated on Boom = MAIN job, charVar cooldowns):
- **`!overload`** — Astral-Flow ultimate: one massive elemental detonation on your target + AoE blast (×5 a normal detonation), long cooldown.
- **`!ignite`** — coats your staff: a visible elemental enspell (melee add) + a window where your spells detonate far more often (15% → 45%).

**Instant job swap (C++ hook, REBUILD):** added a generic `onJobChange` event —
`luautils::OnJobChange` called from `0x100_myroom_job.cpp` (before `UpdateHealth`),
the `xi.player.onJobChange` global stub in `scripts/globals/player.lua`, and
`BoomJob.lua` overrides it to addMod-on-enter / delMod-on-leave (in-memory `applied`
flag handles the zone-wipe). So Boom's traits apply/clear the instant you /job swap,
not at next zone. **This is a core C++ patch — add to the core-patches checklist.**

**Statline (no rebuild):** combat/magic power comes from trait `addMod`s — Staff skill
(`xi.mod.STAFF`) + Elemental skill (`xi.mod.ELEM`) are granted directly, so we never
touch `skill_caps`/`grades.cpp`. STR/HP/Attack%/Acc/DA/Store TP/M.Atk/Fast Cast all
via `addMod`. Re-applied on `onGameIn` (deferred 3s), same as the Cross-Job Trait Trainer.

**Detonation:** `BoomJob.lua` registers a `MAGIC_USE` listener (signature
`caster,target,spell,action`). When a Boom (main job 15) casts one of the listed
spells, `boom.chance`% of the time it deals a big bonus magic hit of the spell's
element to the target (optional AoE), with enmity. Single per-cast hook, fully tunable.

**The handful (tier-III elemental nukes):** Stone III (146), Water III (151),
Aero III (156), Fire III (161), Blizzard III (166), Thunder III (171).

### Apply
Lua hot-reloads on save; the spell-access SQL + auto-unlock + module removal need the
**relaunch map restart** (override modules + SQL). Balance is placeholder.

---

## Deferred (later phases / flagged)

- **Disable summon spell access** (clear SMN byte on summon spell ids): belt-and-
  suspenders only — the relaunch is a fresh wipe so no character knows any summon, and
  with no avatar the Blood Pact / Astral Flow buttons are inert. Add when convenient.
- **`mystats.lua`** still has a SMN "Avatar (Pet)" readout block — harmless, strip later.
- **`grades.cpp` base-stat re-rank** — clean per-level scaling (currently compensated by
  trait mods). C++ rebuild.
- **AF/Empy/Prime re-stat** (item_mods: summoning → melee).
- **DAT reskin / rename** "Summoner" → "Boom" client-side (cosmetic, separate distribution).
