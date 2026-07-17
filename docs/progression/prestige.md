# Prestige / Ascension System

Prestige is the endgame layer above Legend tier. It is a per-job, infinite progression system inspired by Final Fantasy XI's Job Points — but gated behind real content clears rather than merit grinding.

---

## How to Unlock

Prestige is available the moment you reach **Tier V (Legend)** in the Hunting League. Your League rank never changes — Prestige is a parallel track that sits on top of it.

---

## The Altar

The **Ascension Altar** stands in **Provenance** — the abyssal void at the edge of existence (zone 222). Travel there at any time with the **`!provenance`** command, then examine the Altar to open the Prestige menu.

---

## How Ascension Works

Ascending is a three-step cycle:

1. **Complete the Trial** — Defeat the **Nightmare Court**: three dread superbosses you summon at the Altar itself. Choose **Face the Trial** from the menu and the next unbeaten member materializes before you; slay all three since your last ascension. Each counts the moment it dies, and the Altar tracks your progress.
2. **Pay the Mark cost** — Marks are spent at the Altar. Cost escalates with each ascension but plateaus at a cap — see the economy table below.
3. **Earn Ascension Points (AP)** — Each successful ascension grants AP for the job you are currently playing.

### Ascension Economy

<!-- DOCGEN:BEGIN id="prestige-economy" -->
| Ascension # | Mark cost |
|---|---:|
| 1st | 500 marks |
| 2nd | 1,000 marks |
| 3rd | 1,500 marks |
| 4th | 2,000 marks |
| 5th | 2,500 marks |
| 6th+ ascension | **3,000 marks** (cap) |

The cost **caps at 3,000 marks** — every ascension from the 6th onward costs the same flat 3,000.

_Each ascension awards AP scaled by your Prestige Level: **10 AP** (P.Lv 1–50), **15 AP** (P.Lv 51–80), **20 AP** (P.Lv 81+)._
<!-- DOCGEN:END id="prestige-economy" -->

---

## The Nightmare Court

The Trial is no ordinary fight. Three superbosses — used **nowhere else** on the server — answer the Altar's call, one at a time. They were chosen not just to test your gear, but to test your nerve:

<!-- DOCGEN:BEGIN id="prestige-nightmare-court" -->
| Boss | The Dread |
|---|---|
| **Diabolos, the Dream Devourer** | Weaves **Nightmare** — an area sleep that drags your whole party into the dark, then drains your life while you dream. |
| **Medusa, the Gorgon Queen** | Her **petrifying gaze** turns you to stone where you stand. Frozen, you can only watch as she carves the party apart. |
| **Odin, the Doombringer** | Raises his blade for **Zantetsuken** — a stroke that does not wound. It simply ends you. |
<!-- DOCGEN:END id="prestige-nightmare-court" -->

They rise in turn — Diabolos, then Medusa, then Odin — each stronger than the last, and **every one must fall again each cycle**. There is no shortcut and no carry-over: the Court is reborn every time you return to ascend.

A summoned boss you leave **unengaged** for 20 seconds retreats into the void and frees your summon slot to try again — but it will never retreat out of an **active fight**, even while petrification or other lockouts keep you (or your pet) from landing damage. It also withdraws without credit if it knocks you out.

!!! danger "Come prepared, or do not come at all"
    Odin's Zantetsuken can kill outright. Bring Reraise, bring a plan, and bring friends — the Court was built to break the overconfident.

---

## The Court Grows With You

The Nightmare Court is **not** a fixed wall — the bosses change as you climb in Prestige level **on the job you're ascending**. Early Courts rise gently through the P5, P15, and P30 Sage milestones. The final Celestial Wardens then gain measured empowerment at P80 and P90, making the approach to P100 a full-BiS challenge rather than an early progression wall:

<!-- DOCGEN:BEGIN id="prestige-scaling" -->
| Ascensions (that job) | Court | Bosses you face | Stat scaling |
|---|---|---|---:|
| **0–9** | The Nightmare Court | Diabolos, the Dream Devourer &bull; Medusa, the Gorgon Queen &bull; Odin, the Doombringer _(the top-level Nightmare Court)_ | ×1 |
| **10–19** | The Voidwalkers | Sarameya, the Abyssal Hound &bull; Kaggen, the Devouring Swarm &bull; Qilin, the Tempest Beast | ×1 |
| **20–29** | The Jailers | Jailer of Justice &bull; Jailer of Fortitude &bull; Jailer of Temperance | ×1 |
| **30–39** | The Voidwalker Lords | Kreutzet, the Skydark &bull; Raja, the Voidfang &bull; Maere, the Living Nightmare | ×1 |
| **40–59** | The World's End | Omega, the Final Engine &bull; Ultima, the First Weapon &bull; The Provenance Watcher | ×1 |
| **60–79** | The Celestial Wardens | Tiamat, the Planar Destroyer &bull; Kirin, the Celestial Sovereign &bull; Absolute Virtue, the Eternal Judge | ×1 |
| **80–89** | The Celestial Wardens (Empowered) | Tiamat, the Planar Destroyer &bull; Kirin, the Celestial Sovereign &bull; Absolute Virtue, the Eternal Judge | ×1.12 |
| **90+** | The Celestial Wardens (Ascendant) | Tiamat, the Planar Destroyer &bull; Kirin, the Celestial Sovereign &bull; Absolute Virtue, the Eternal Judge | ×1.25 |
<!-- DOCGEN:END id="prestige-scaling" -->

The Altar **announces** the Court you face, and its Status menu shows your current tier. P0–P30 is tuned for ordinary post-Legend progression; P40–P79 expects increasingly complete endgame sets. The P80–P100 Wardens are the final test: full BiS, deliberate gear swaps, and the strongest weapon available before the P100 gate are the intended benchmark.

Reaching **P100 on one job** gates **Aeonic Stage I → Stage II** at the Weapon Forge. It is not one of the five Prime Armory trials; Prime progression later accepts a completed final Aeonic (or another final REMA) as one of its entry routes.

---

## Ascension Points (AP)

AP is a per-job currency. Every job has its own AP pool and its own stat purchases. Switching main jobs switches which pool is active — boosts apply only while that job is your main.

Spend AP at the Altar on any of the categories below.

---

## AP Spend Table

!!! tip "Reading your stats: your points go into the green **+N**, not the base number"
    FFXI shows every attribute as **base + bonus** — for example, `STR 125 +135`.

    - The **base** (the first number, `125`) comes from your level, job, and race. It **never** moves — not from Ascension, gear, food, or buffs.
    - Every bonus — gear, food, **and the points you buy here** — stacks into the green **+N** on the right.

    So buying **1 level of Strength** changes `STR 125 +134` into `STR 125 +135`, and your **total** STR (the number that actually drives Attack and damage) goes from **259 → 260**. If a stat looks unchanged right after you spend AP, check the green **+N** — that's where your points land.

<!-- DOCGEN:BEGIN id="prestige-ap-table" -->
<div class="milestone-grid" markdown="1">

#### Base Stats

| Stat | Per Level | Max Levels | AP Cost | Max Total |
|---|---|---:|---:|---|
| Strength | +1 STR / level (max +50) [1 AP] | 50 | 1 AP | — |
| Dexterity | +1 DEX / level (max +50) [1 AP] | 50 | 1 AP | — |
| Vitality | +1 VIT / level (max +50) [1 AP] | 50 | 1 AP | — |
| Agility | +1 AGI / level (max +50) [1 AP] | 50 | 1 AP | — |
| Intelligence | +1 INT / level (max +50) [1 AP] | 50 | 1 AP | — |
| Mind | +1 MND / level (max +50) [1 AP] | 50 | 1 AP | — |
| Charisma | +1 CHR / level (max +50) [1 AP] | 50 | 1 AP | — |
| Max HP | +20 HP / level (max +1000) [1 AP] | 50 | 1 AP | — |
| Max MP | +20 MP / level (max +500) [1 AP] | 25 | 1 AP | — |

#### Melee & Magic

| Stat | Per Level | Max Levels | AP Cost | Max Total |
|---|---|---:|---:|---|
| Accuracy | +10 Accuracy / level (max +500) [1 AP] | 50 | 1 AP | — |
| Attack | +20 Attack / level (max +1000) [1 AP] | 50 | 1 AP | — |
| Defense | +5 Defense / level (max +250) [1 AP] | 50 | 1 AP | — |
| Evasion | +5 Evasion / level (max +250) [1 AP] | 50 | 1 AP | — |
| Magic Acc | +20 Mag.Acc / level (max +1000) [1 AP] | 50 | 1 AP | — |
| Magic Atk | +20 Mag.Atk / level (max +1000) [1 AP] | 50 | 1 AP | — |

#### Combat Traits

| Stat | Per Level | Max Levels | AP Cost | Max Total |
|---|---|---:|---:|---|
| Store TP | +2 Store TP / level (max +100) [2 AP] | 50 | 2 AP | — |
| TP Bonus | +10 TP Bonus / level (max +500) [2 AP] | 50 | 2 AP | — |
| Quad Atk | +1% Quad.Atk / level (max 50%) [2 AP] | 50 | 2 AP | — |
| Crit Rate | +1% Crit / level (max 20%) [2 AP] | 20 | 2 AP | — |
| Crit Dmg | +2% Crit Dmg / level (max 40%) [3 AP] | 20 | 3 AP | — |
| Counter | +1 Counter / level (max +50) [2 AP] | 50 | 2 AP | — |
| Parry Rate | +1% Parry / level (max 25%) [1 AP] | 25 | 1 AP | — |
| Subtle Blow | +1 Subtle Blow / level (max +50) [1 AP] | 50 | 1 AP | — |
| WS Dmg | +2% WS Dmg / level (max 40%) [3 AP] | 20 | 3 AP | — |
| Dual Wield | +1% Dual Wield / level (max 25%) [2 AP] | 25 | 2 AP | — |
| SC Dmg | +2% Skillchain Dmg / level (max 40%) [3 AP] | 20 | 3 AP | — |

#### Ranged

| Stat | Per Level | Max Levels | AP Cost | Max Total |
|---|---|---:|---:|---|
| Ranged Acc | +10 R.Acc / level (max +500) [1 AP] | 50 | 1 AP | — |
| Ranged Att | +20 R.Att / level (max +1000) [1 AP] | 50 | 1 AP | — |

#### Mitigation

| Stat | Per Level | Max Levels | AP Cost | Max Total |
|---|---|---:|---:|---|
| Phys.DT- | -1% Phys.DT / level (max -15%) [3 AP] | 15 | 3 AP | — |
| Mag.DT- | -1% Mag.DT / level (max -15%) [3 AP] | 15 | 3 AP | — |
| Haste | +1% Haste / level (max 15%) [3 AP] | 15 | 3 AP | — |

#### Magic Support

| Stat | Per Level | Max Levels | AP Cost | Max Total |
|---|---|---:|---:|---|
| Spell Intp | +1% SIRD / level (max 50%) [2 AP] | 50 | 2 AP | — |
| Fast Cast | +1% Fast Cast / level (max 30%) [2 AP] | 30 | 2 AP | — |
| Enspell Dmg | +10 Enspell Dmg / level (max +500) [2 AP] | 50 | 2 AP | — |
| Cure Potency | +2% Cure Pot. / level (max +50%) [2 AP] | 25 | 2 AP | — |
| Refresh | +1 Refresh / level (max +10 MP/tick) [3 AP] | 10 | 3 AP | — |
| Magic Dmg | +10 Magic Dmg / level (max +250) [2 AP] | 25 | 2 AP | — |

#### Utility

| Stat | Per Level | Max Levels | AP Cost | Max Total |
|---|---|---:|---:|---|
| Treas.Hunter | +1 TH / level (max +50) [2 AP] | 50 | 2 AP | — |
| Gilfinder | +2% Gilfinder / level (max +100%) [1 AP] | 50 | 1 AP | — |

#### Resistances & Skills

| Stat | Per Level | Max Levels | AP Cost | Max Total |
|---|---|---:|---:|---|
| Status Res | +2 Status Res. / level (max +100) [1 AP] | 50 | 1 AP | — |
| Ele. Resist | +10 Ele.Resist / level (max +500 each) [1 AP] | 50 | 1 AP | — |
| All Skills | +2 All Skills / level (max +100 each) [1 AP] | 50 | 1 AP | — |

#### Pet Boost

| Stat | Per Level | Max Levels | AP Cost | Max Total |
|---|---|---:|---:|---|
| Pet Boost | +40 all Pet stats / level (Atk/Def/Acc/Eva/MAtk/MAcc/Attr/TP, max +2000 each) [2 AP] | 50 | 2 AP | — |

</div>
<!-- DOCGEN:END id="prestige-ap-table" -->

Boosts are **permanent and stacking** — they re-apply automatically every time you zone in or change main jobs.

---

## Important Notes

- **Prestige never resets your Hunting League rank.** Your tier, gear, marks, and kill records are untouched.
- **The Nightmare Court must be re-cleared each cycle.** A kill from a previous ascension does not carry over.
- **Per-job isolation.** AP earned on Warrior stays on Warrior; AP earned on Black Mage stays on Black Mage. You cannot transfer AP between jobs.
- **Boosts apply on main job only.** Set your Prestige job as main before zoning in to activate its bonuses.
- **No level cap.** Prestige is an infinite long-term chase. The mark cost plateaus at the cap shown in the economy table above, so the commitment per cycle is steady indefinitely.

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 4094c2238a21 -->
_Last updated: 2026-07-12 21:15 PDT_
<!-- DOCGEN:END id="last-updated" -->
