# Adventuring Fellow

Your **Adventuring Fellow** is a personal companion ANY job can summon — not a pet you rent, but one you build. It levels from your kills and you spend the points on the stats you choose. Give it a name, pick its look, and bring it into every fight.

!!! tip "Summary"
    Use `!fellow` to open the Fellow menu — summon/dismiss, allocate stat points, choose a role, set a name and appearance. Your Fellow earns XP from kills while it is out, levels up, and hands you stat points to spend however you like.

## Starting out

Type `!fellow` at any time to open the main menu. Your Fellow doesn't exist until you first interact with it — the menu walks you through creation.

| Command | What it does |
|---|---|
| `!fellow` | Open the Fellow menu |
| `!fellow summon` | Call your Fellow |
| `!fellow dismiss` | Send it to rest |
| `!fellow status` | Chat dump of level, XP, points, and allocation |
| `!fellowname <name>` | Give your Fellow a custom name (letters and spaces, max 15 chars) |

## Leveling and stat points

<!-- DOCGEN:BEGIN id="fellow-progression" -->
Your Fellow earns XP from kills **while it is summoned**. XP per kill scales with the slain foe's level (a floor of 5, capped at 200).

It levels up to **120**, and each level grants **3 stat points** to spend. You start with **6 points** when your Fellow is first created.

If you are in a party, every party member who has their Fellow out earns XP from every kill in the same zone — so grinding in a zone levels everyone's companion at once.
<!-- DOCGEN:END id="fellow-progression" -->

Spend points through the **Allocate Points** menu — pick the stat you want to grow. Allocation applies instantly to the live companion.

Each stat track adds its own bundle of bonuses per point:

<!-- DOCGEN:BEGIN id="fellow-stats" -->
| Stat track | Each point grants |
|---|---|
| **STR** | +6 STR, +12 Attack |
| **DEX** | +6 DEX, +10 Accuracy |
| **VIT** | +6 VIT, +10 Defense |
| **AGI** | +6 AGI, +10 Evasion |
| **INT** | +6 INT, +10 Magic Attack |
| **MND** | +6 MND, +10 Magic Defense |
| **Ferocity** | +1% Attack |
| **Critical** | +1% Critical Hit Rate |
| **Frenzy** | +1% Double Attack |
| **Onslaught** | +1% Triple Attack, +3 Store TP |
| **Sorcery** | +12 Magic Attack, +6 Magic Accuracy |
| **Celerity** | +8% Attack Speed (Haste) |
| **Warding** | -20 Physical Damage Taken, -20 Magic Damage Taken |
| **Vigor** | +3 HP Regen, +1 MP Refresh |
<!-- DOCGEN:END id="fellow-stats" -->

## Roles

Each Fellow follows a combat role that shapes how it fights. Every role still melee-assists and uses its signature TP move; the role layers extra stats (and, for some, a battle behaviour) on top:

<!-- DOCGEN:BEGIN id="fellow-roles" -->
| Role | Behaviour |
|---|---|
| **Vanguard** | Balanced melee damage dealer. |
| **Berserker** | All-out melee offense; takes a bit more damage. |
| **Bulwark** | Tank: more DEF, less damage taken, holds hate. |
| **Oracle** | Battle-healer: fights and mends your wounds when hurt. |
| **Magus** | Battle-mage: fights and hurls elemental magic at your foe. |
| **Hunter** | Ranger: fights and adds ranged strikes to your target. |
<!-- DOCGEN:END id="fellow-roles" -->

Switch roles at any time through the menu; the change takes effect when you next summon.

## Name and appearance

Set your Fellow's displayed name with the **`!fellowname <name>`** command (letters and spaces, up to 15 characters, run through a language filter). Pick its look through **Appearance** — each form carries its own signature TP move. Apply an **Outfit** for a job-themed humanoid look; an outfit overrides the Appearance pick. Appearance and outfit changes apply the next time you summon; a name change applies instantly if your Fellow is out.

<!-- DOCGEN:BEGIN id="fellow-customization" -->
**Names** — set a custom name with the `!fellowname <name>` command (letters and spaces, up to 15 characters, run through a language filter). It applies instantly if your Fellow is out and persists across sessions.

**Appearances** — **12** forms to pick from, each with its own signature TP move:

| Appearance | Signature move |
|---|---|
| Moogle | Meteorite |
| Mandragora | Aero IV |
| Coeurl | Charged Whisker |
| Sabotender | Thousand Needles |
| Cardian | Fire IV |
| Goblin | Bomb Toss |
| Yagudo | Dancing Edge |
| Tonberry | Cursed Sphere |
| Antican | Rock Buster |
| Boggart | Blizzard IV |
| Goobbue | Auroral Uppercut |
| Adventurer | Crescent Fang |

**Outfits** — **10** job-themed humanoid looks that override the chosen appearance when set: Thief, Monk, Red Mage, Ranger, Dark Knight, Warrior, Paladin, Black Mage, Scholar, Bard.
<!-- DOCGEN:END id="fellow-customization" -->

## Party XP

With `Party-wide XP` enabled (the default), any party member who has their Fellow out earns Fellow XP from every kill in the same zone — not just the killing player. Running content in a group levels everyone's companion faster.

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: b06b3d37228c -->
_Last updated: 2026-06-29 04:19 UTC_
<!-- DOCGEN:END id="last-updated" -->
