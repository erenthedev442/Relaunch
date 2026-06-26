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

## Phase 1 — BUILT (all no-rebuild: Lua + one SQL)

- `modules/custom/lua/boom_job_catalog.lua` — ALL tuning (traits, spell set, detonation chance/damage).
- `modules/custom/lua/BoomJob.lua` — applies job traits on login (gated on SMN = MAIN job), grants the spells, and runs the detonation via a `MAGIC_USE` listener.
- `modules/custom/sql/boom_job_spells.sql` — sets the SMN learn-level byte (byte 15 of `spell_list.jobs`) so the slot can cast the 6 nukes. Pattern from `restore_geo_retail.sql`.
- `modules/custom/lua/unlock_adoulin_jobs.lua` — SMN added to the auto-unlock list so Boom is selectable by everyone (toggle: remove it to gate behind the retail unlock).
- **Removed** the retail-SMN custom modules (avatars are gone): `smn_avatar_boost.lua`, `bp_delay_uncap.lua`, `smn_avatar_gear_mods.sql`.

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
- **Job-swap caveat:** traits apply on login/zone while SMN is main job. Switching jobs
  mid-session without zoning won't re-apply/clear until the next zone (same limitation as
  the other onGameIn systems). A `onJobChange` hook is the proper fix (Phase 2).
- **`grades.cpp` base-stat re-rank** — clean per-level scaling (currently compensated by
  trait mods). C++ rebuild.
- **AF/Empy/Prime re-stat** (item_mods: summoning → melee).
- **DAT reskin / rename** "Summoner" → "Boom" client-side (cosmetic, separate distribution).
