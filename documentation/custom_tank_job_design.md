# Custom Tank Job: "Bouncer" — GEO Slot Repurpose (Design Doc)

**Status:** Decisions locked · **Date:** 2026-05-31 · **Slot:** job id **21** (GEO / `char_jobs.geo`)

Turn the Geomancer slot into an original **tank** job — the **Bouncer** — an "active retaliation"
tank built around **enmity generation, damage reflection/spikes, and leech self-sustain**. Distinct
from PLD (shield-block + cure + Invincible) and RUN (runes + elemental resist + evasion). GEO's
gameplay (luopan, Geo-/Indi- auras, Bolster) is fully removed; we keep only the *slot*.

---

## Decisions locked (2026-05-31)

| # | Decision | Choice |
|---|----------|--------|
| 1 | Name & theme | **Bouncer** — active-retaliation enforcer (taunt + reflect + leech) |
| 2 | Weapon | **Polearm** (2-handed → **no shield**; mitigation comes from HP/VIT/DEF + reflect, not block) |
| 3 | Spells in v1 | **None** (MP grade 0) |
| 4 | Client DAT pack | **Job name + icon now**; ability/spell name relabels can follow later |
| 5 | HP | **Higher than MNK** → grade **A** (same base as MNK) **+ an `HPP` job trait** to clear it |
| 6 | Other stats | **Use the recommended grade line** (VIT A, the rest moderate) |
| 7 | Reflect | **Confirmed** — Retaliate **180s duration / 30s recast** (≈permanent uptime); reflect % in §2.7 are balance-pass starting values |

All decisions are locked. The §2.7 reflect/leech **percentages** are starting values to tune during
the balance pass; nothing else is open.

---

## 1. The governing constraint (read this first)

**The client builds the job name and the Job Abilities menu from its own DAT files — the server
cannot add a new job name or a new entry to that menu.** This is already documented in our own code
(`modules/custom/lua/cross_job_ability_catalog.lua:20-23`: borrowed abilities "do NOT appear in the
in-game Job Abilities menu — that menu is built client-side per job from the game DATs").

Consequence: a brand-new server ability id gated to job 21 would be **usable only via `/ja` macros**,
never shown in the menu. Bad UX for a flagship job.

**Therefore the strategy is "same sockets, new content":** we **reuse GEO's existing ability and
spell ids** (the client already knows them for job 21) and **rewrite what they do**. The player sees
the GEO menu structure, but every ability is a tank tool. The client DAT pack then **renames** the
job and (later) its abilities so it reads as the Bouncer. This reconciles "not GEO-based" (true at
the gameplay + presentation layer) with the client's hard limits (we're constrained to GEO's ~14
ability sockets, which is plenty for a tank kit).

Fully ours to change, server-side, no client cooperation:
- All ability **effects, recasts, targets, enmity, animations** (`sql/abilities.sql` + Lua handlers)
- All **traits** (`sql/traits.sql`) — traits need no menu
- **Stats**, **skill ranks**, **equippable gear**, **spells learned**

Requires the client DAT pack (cosmetic only):
- Job **name** ("Geomancer" → "Bouncer") and job **icon** *(committed now)*; ability/spell **names**
  and AF reskin *(optional, later)*. Players without the pack see the original GEO names but get
  identical mechanics.

---

## 2. Job identity & kit

### 2.1 Stat grades — `src/map/grades.cpp:60` (one-line edit, **requires recompile**)

Grade numbers are **1=A (best) … 7=G (worst)**; **0 = none** (e.g. MP for a non-caster).
Reference rows: GEO (line 60) `{ 3, 2, 6, 4, 5, 4, 3, 3, 4 }`; **MNK** (line 41)
`{ 1, 0, 3, 2, 1, 6, 7, 4, 5 }` — MNK HP is grade **A (1)**, the ceiling, with MP **0**.

Recommended Bouncer line:

| Stat | Grade | Rationale |
|------|-------|-----------|
| HP   | **1 (A)** | Match MNK's max grade; the `HPP` trait (§2.4) then pushes effective HP **above** MNK |
| MP   | **0** | No spells |
| STR  | 4 (D) | Moderate offense → enmity-via-damage + polearm WS |
| DEX  | 4 (D) | — |
| VIT  | **1 (A)** | The tank pillar — drives DEF; PLD-tier |
| AGI  | 4 (D) | — |
| INT  | 6 (F) | Dump |
| MND  | 4 (D) | — |
| CHR  | 4 (D) | — |

**Proposed row (line 60):** `{ 1, 0, 4, 4, 1, 4, 6, 4, 4 }`

**Beating MNK on HP:** both jobs at grade A share the identical base from `HPScale` row A
`{19, 9, 1, 3, 3}` — grade alone can't exceed it. So we add a **job-21 `HPP` trait** (mod id **3**,
HP %). E.g. `HPP +10` ⇒ Bouncer max HP ≈ MNK base × 1.10, guaranteed above MNK at every level.
Optionally stack flat **`HP` (mod 2)** "Max HP Boost" tiers at higher levels for an even deeper pool.
This is pure SQL (§2.4) — no extra recompile.

### 2.2 Weapon & skills — `sql/skill_ranks.sql` (edit the **`geo` column**)

Layout: one **row per skill** (`skillid` + `name`), one **column per job**; we edit the `geo`
column. **Scale is inverted: lower number = higher rank** (`1` ≈ A+, up to `~11` ≈ G; `0` = no
access). Verified: DRG polearm = `1`, PLD polearm = `10`; PLD sword = `1`, THF sword = `9`.
`skill_caps.sql` is job-agnostic, so no caps edit is needed.

| Skill (`skillid`) | Current `geo` | New `geo` | Note |
|-------------------|---------------|-----------|------|
| **Polearm (8)**   | 0 | **1** | Match DRG (A+) — our only weapon, also the enmity-via-damage engine |
| **Parrying (31)** | 0 | **1** | Match RUN (A) — 2-handers parry; core tank defense |
| Evasion (29)      | 9 | 7 | Slight bump to PLD/WAR tier (heavy tank, evasion is minor) |
| Shield (30)       | 0 | **0** | **Leave 0** — polearm is 2-handed, no shield |
| Sword (3) / Great Sword (4) | 0 | 0 | Leave 0 — polearm only |

GEO's old Club/Staff/Handbell ranks can be left as-is or zeroed; harmless once spells/luopan are
stripped. C++ clamps the loaded value (`battleutils.cpp:153`).

**Identity note (no shield):** without block, Bouncer mitigation = **deep HP pool + A-grade VIT/DEF +
defensive traits (Damage Taken −%, Defense Bonus) + Parrying + the active reflect/leech kit**. That
is deliberately *different* from PLD's block-and-cure and RUN's magic-evasion — it's an HP-and-
retaliation tank. The polearm doubles as the enmity engine (hitting hard = holding hate).

### 2.3 Job abilities — reuse GEO donor sockets, rewrite handlers

Mechanism (confirmed): an `abilities.sql` row's **`name`** column maps to
`scripts/actions/abilities/<name>.lua` (`luautils.cpp` `OnAbilityUse`/`OnAbilityCheck`), which
delegates to a util function (today `scripts/globals/job_utils/geomancer.lua`). We keep the **ids**,
repoint handlers to a new **`scripts/globals/job_utils/bouncer.lua`**, and tune each SQL row's
`recastTime`, `validTarget`, `CE`/`VE` (built-in cumulative/volatile **enmity**), and `animation`.

Proposed mapping (GEO donor → Bouncer tool). **Display names** come from the DAT pack later; internal
handler names stay neutral.

| Donor (id) | Bouncer tool (display) | Effect sketch | Key SQL knobs |
|------------|------------------------|---------------|---------------|
| **Bolster (343)** | **"Last Call"** (2-hour/SP) | 30s: reflect **100%** of all damage to attackers + **cannot drop below 1 HP** + huge enmity | reuse id ⇒ **no `ability.cpp` edit** (§2.6) |
| Full Circle (345) | **Step Outside** (ST taunt) | Provoke-equivalent: high `VE`, short recast | `validTarget=enemy`, big `VE` |
| Radial Arcana (355) | **Crowd Control** (AoE taunt) | Flash/AoE-provoke; hate from a group | `isAOE=1`, big `VE` |
| Life Cycle (349) | **Retaliate** | 180s self-buff, 30s recast (~permanent uptime): reflect phys dmg as spikes + leech a share (§2.7) | self buff |
| Blaze of Glory (350) | **Brace** | 30s: flat damage-taken −% | self buff |
| Ecliptic Attrition (347) | **Bloodbind** | Convert a portion of recently-taken damage → HP (drain burst) | self |
| Collimated Fervor (348) | **Bodyguard** | Redirect an ally's incoming damage to you for Xs (Cover-like) | `validTarget=ally` (already ally-targeted) |
| Theurgic Focus (352) | **Sucker Punch** | Short-cd single-target stun (tank utility) | `validTarget=enemy` |
| Dematerialize (351) | **Hold the Line** | Brief invuln/guard window | self |
| Lasting Emanation (346), Concentric Pulse (353), Mending Halation (354), Widened Compass (377), Entrust (386) | spare | Hate-dump for a DD, shield-bash analog, TP tool, or leave disabled | — |

Enmity is largely `CE`/`VE` on the ability row + the `ENMITY` mod (mod id **27**) from traits — so
"taunts" are mostly data (high `VE`), not new code.

### 2.4 Traits — `sql/traits.sql` (pure SQL, `job=21` rows, **no menu, no recompile**)

Insert `job=21` rows whose `modifier` is a mod id and `value` the magnitude. Core set:

- **HP %** — `HPP` (mod **3**), e.g. `+10` → the "above MNK" guarantee (§2.1).
- **Enmity+** — `ENMITY` (mod **27**) — all actions generate more hate.
- **Defense Bonus** (`DEF`, mod **1`) and **VIT Bonus** (`VIT`, mod **10**) tiers.
- **Damage Taken −%**, **innate Counter** (`COUNTER`, mod **291**), **Subtle Blow**, **Resist** tiers.
- Optional **"Tactician"** (TP when taking damage) for flavor.

**Remove** GEO's existing `job=21` trait rows (MP boost, Conserve MP, Clear Mind, Cardinal Chant, etc.).

### 2.5 Spells — **none in v1**

Zero **byte index 21** of the `jobs` `binary(22)` blob on every Geo-/Indi- row in
`sql/spell_list.sql` (skill = Geomancy 44) so the slot learns no GEO magic; also neutralize the
casting/luopan logic in `geomancer.lua`. MP grade is already `0`. (Future: a small self-buff "spell"
set could reuse Indi-/Geo- ids the same way — deferred.)

### 2.6 2-hour

`src/map/ability.cpp:473` already does `case JOB_GEO: return GetAbility(ABILITY_BOLSTER)`. By reusing
the Bolster id for **"Last Call,"** we avoid touching `ability.cpp` entirely — just rewrite
`bolster.lua` to call the new handler. (Only a brand-new 2hr id would force an edit/recompile here.)

### 2.7 Reflect / leech math (proposed defaults — decision #7)

The signature mechanic. Proposed v1 numbers, all tunable:

- **Retaliate** (Life Cycle id 349) — **180s (3-min) self-buff, 30s recast** ⇒ effectively
  **permanent uptime** (the buff outlasts the recast 6×, so you refresh long before it lapses and the
  30s recast just removes any lockout). Reflect **25%** of physical damage taken back to the attacker
  as spike damage, and **heal the Bouncer for 50% of the reflected amount** (the leech). Modeled as a
  physical **Spikes** status effect (reuses the existing Spikes machinery; `SPIKES` = mod **342**
  stores the active spike type). *Balance note: at ~100% uptime this is a near-constant passive —
  expect to dial the 25%/50% at the balance pass.*
- **Last Call** (2-hour, Bolster id 343) — 30s. **Cannot be reduced below 1 HP** + reflect **100%**
  of all damage taken back to attackers + a large enmity spike. The "everybody out" button.
- **Bloodbind** (Ecliptic Attrition id 347) — instant. Convert **20%** of damage taken in the last
  ~10s into HP (capped), for a clutch self-heal burst.
- **Party benefit:** in v1 reflect/leech is **self-only**; the party benefits **indirectly** through
  **Bodyguard** (redirect an ally's hit onto the Bouncer, who then reflects it). A party-wide spikes
  aura is a possible later toggle, not v1.

Implementation note: physical spikes + leech is largely **data + the existing Spikes effect handler**.
If we want reflect to scale off *post-mitigation* damage or to interact with multi-hit precisely, a
small custom C++ damage-reaction hook may be cleaner (see §5 for the module pattern, §8 for the
open verify).

---

## 3. Itemization — `sql/item_equipment.sql`

`jobs` is a bitmask, **bit = `1 << (jobid − 1)`**. Verified: **GEO = bit 20 = `1048576`** (GEO
jobid 21). Relevant donor bits: **DRG (jobid 14) = `8192`**, **WAR (jobid 1) = `1`**, PLD
(jobid 7) = `64`.

To let the Bouncer equip polearms + heavy armor, bulk-OR bit 20 onto the gear classes DRG/WAR use
(DRG gives us polearms + 2-handed-friendly armor; WAR adds heavy armor — neither implies a shield):

```sql
-- conceptual; re-verify donor bits against the JOBTYPE enum order first
UPDATE item_equipment SET jobs = jobs | 1048576 WHERE jobs & 8192;  -- everything DRG can wear (polearms + armor)
UPDATE item_equipment SET jobs = jobs | 1048576 WHERE jobs & 1;     -- WAR heavy armor (optional, broadens choices)
```

A handful of `UPDATE`s by gear class, not per-row edits. Size it first:
`SELECT COUNT(*) FROM item_equipment WHERE jobs & 1048576;` (current GEO-gear count) and the DRG/WAR
equivalents. Do **not** flag shields (no shield skill).

**Artifact armor:** GEO's AF/relic/empyrean are the Geomancy / Azimuth / Bagua sets. Either let the
Bouncer wear existing tank/DD AF, or repoint/reskin these via the DAT pack (reuse existing armor
*models* — do **not** model new gear).

---

## 4. Change surface at a glance

| Layer | File(s) | Change | Recompile? |
|-------|---------|--------|------------|
| Stats | `src/map/grades.cpp:60` | overwrite GEO grade row → `{ 1, 0, 4, 4, 1, 4, 6, 4, 4 }` | **Yes** |
| 2hr   | `src/map/ability.cpp:473` | none if reusing Bolster id | No (avoided) |
| JP cleanup | `src/map/job_points.cpp:395` | remove GEO elemental-V grant | Yes (fold into the grades build) |
| Abilities | `sql/abilities.sql` + `scripts/actions/abilities/*.lua` + new `scripts/globals/job_utils/bouncer.lua` | rewrite GEO ability effects | No |
| Traits | `sql/traits.sql` | swap GEO traits → tank traits (`job=21`), incl. the `HPP` trait | No |
| Skills | `sql/skill_ranks.sql` (`geo` col) | Polearm `1`, Parrying `1`, Evasion `7` | No |
| Spells | `sql/spell_list.sql` (byte 21) + `geomancer.lua` | strip GEO magic | No |
| Gear  | `sql/item_equipment.sql` | bulk equip-flag polearms + heavy armor | No |
| Cosmetic | client DAT pack | **job name + icon now**; ability names + AF reskin later | N/A (client) |

**Net:** exactly **one** required recompile (grades + the small `job_points.cpp` cleanup). Everything
else is SQL + Lua, hot-reloadable.

We do **not** touch GEO on mobs/trusts — mob GEO AI (`mobutils.cpp`, `petentity.cpp`,
`mob_spell_container.cpp`, `gambits_container.h`) is independent of the player job and stays as-is.

---

## 5. Synergy with existing custom systems (free wins)

- **Prestige_System is per-main-job** (`Prestige_*_<jobId>` charvars) → the Bouncer **automatically
  gets its own Ascension track** the moment it exists. No extra work.
- **Hunting League**, **subjob_exp_share**, **Reforge** all key off main job → they just work.
- The **cross-job ability** system (`modules/custom/cpp/cross_job_ability_bindings.cpp`) is **not
  needed** here (job-21-gated abilities are auto-granted by `BuildingCharAbilityTable`), but its
  `CPPModule` + `REGISTER_CPP_MODULE` + `modules/init.txt` pattern is the template if a Bouncer tool
  ever needs a custom engine hook (e.g. the signature reflect formula in §2.7).

---

## 6. Implementation phases

0. **Prep** — back up DB; make a test char job 21; create a worktree.
1. **Chassis (feel it)** — `grades.cpp` tank line + `skill_ranks` Polearm/Parrying/Evasion +
   equip-flag a starter polearm + heavy-armor set + the `HPP` trait. Recompile.
   *Outcome: GEO is now a high-HP polearm bruiser that out-HPs MNK.*
2. **Strip GEO** — zero `spell_list` byte 21 for Geo-/Indi-; neutralize `geomancer.lua` luopan/casting;
   remove `job_points.cpp:395` grant.
3. **Tank kit** — write `bouncer.lua`; repoint the donor `scripts/actions/abilities/*.lua`; tune
   `abilities.sql` rows (recast/target/CE/VE/animation). Start with **Last Call** (2hr),
   **Step Outside** (taunt), **Retaliate** (reflect/leech).
4. **Traits** — insert `job=21` defensive/enmity/spikes rows (incl. `HPP`); remove GEO traits.
5. **Itemization** — bulk equip-flag polearms + heavy armor; choose/relabel AF.
6. **Client DAT pack** — rename job + icon now (cheap, high impact); ability names + AF reskin later.
7. **Polish** — JP/merit effect repointing, balance pass, Prestige tuning.

Each phase is independently testable; 1–5 are server-side and reversible.

---

## 7. Status: design locked

Retaliate timing is set: **180s duration / 30s recast** (≈permanent uptime). The reflect/leech
**percentages** (Retaliate 25% / 50% leech; Last Call 100% + can't-die; Bloodbind 20%) stand as
**starting values** for the balance pass. Design is locked — ready for Phase 1.

## 8. Risks / things to verify before coding

- **Equip-bit order** — re-confirm DRG (`8192`) / WAR (`1`) bits against the `JOBTYPE` enum
  (`battleentity.h`) before any bulk `UPDATE item_equipment` (the GEO=`2^20` check already validates
  the `1 << (jobid−1)` formula).
- **Client JA-menu reuse** — verify in-game that a reused-id ability with a changed `validTarget`
  still presents/targets correctly (expected fine; ids unchanged).
- **Gear count** — run the `COUNT(*)`s to size the itemization pass.
- **Reflect/spikes path** — confirm the existing **Spikes** status effect can carry "reflect a % of
  physical damage taken + leech," or decide a custom C++ damage-reaction hook is warranted for the
  signature mechanic (§2.7).
