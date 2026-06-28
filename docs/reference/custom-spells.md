# Custom Spells

Three spells on the Relaunch server do not exist on retail Final Fantasy XI. They are sold by the **[Accessories NPC](../progression/gear-vendors.md)** in Reisenjima Henge — choose its **Spells** option and pay with Hunt Marks. (Note: the similarly-named **Accessory** NPC is a different, medal-paid vendor — the scrolls are on the plural **Accessories** NPC.)

Unlike standard spells, their mechanics are not documented on any external wiki. This page explains exactly what they do.

---

## How to cast

Divine Aegis and Convergence use custom spell IDs that the game client has no data for, so casting them the normal way (`/ma "<name>"`) returns **"a command error occurred."** Cast them with a **chat command** instead — the server runs the real spell for you:

| Spell | Command | Job · MP · Recast | When to use |
|---|---|---|---|
| Divine Aegis | `!aegis` | PLD 50 · 80 MP · 120 s | Anytime — shields you |
| Convergence | `!convergence` | RDM 50 · 60 MP · 45 s | While engaged — hits your current target |
| Silencega | `!silencega` | WHM 40 / RDM 50 / SCH 50 · 32 MP · 20 s | While engaged — hits your target and nearby enemies |

The command enforces the same requirements as a normal cast: you must have **learned the spell** (bought its scroll), be on the listed **job at the required level**, have the **MP**, and wait out the **recast**. There is no casting animation — the effect lands instantly.

!!! tip "Silencega also casts the normal way"
    Silencega uses a standard spell ID, so once you have learned it you can also cast it with `/ma "Silencega" <t>` like any other spell. The `!silencega` command is just a convenience that works identically.

---

## Scroll of Divine Aegis

<!-- DOCGEN:BEGIN id="custom-spell-divine-aegis" -->
**400 Hunt Marks** · White Magic · PLD only · Level 50 · Divine / Enhancing
<!-- DOCGEN:END id="custom-spell-divine-aegis" -->

Divine Aegis is a Paladin-exclusive defensive cooldown that combines a Stoneskin shield with a physical damage reduction buff, then detonates as a Holy AoE when the timer expires.

### Mechanic

**Cast** applies two effects simultaneously:

- **Holy Shield** — a Stoneskin-type barrier that absorbs incoming physical damage.
- **Physical Damage Taken down** — a flat damage reduction buff while the shield is up.

**Shield strength** scales with your stats:

<!-- DOCGEN:BEGIN id="custom-spell-divine-aegis-shield" -->
```
power      = min( 150 + VIT×6 + maxHP×0.12 , 3000 )
PDT buff   = −20% physical damage taken
duration   = 30 seconds
```
<!-- DOCGEN:END id="custom-spell-divine-aegis-shield" -->

At endgame gear levels (VIT ~200, max HP ~5,000): `150 + 1200 + 600 = 1950`. With top-tier VIT and HP augments the cap is reachable.

**Detonation** fires when the timer expires: the shield collapses and converts absorbed damage into a Holy AoE.

<!-- DOCGEN:BEGIN id="custom-spell-divine-aegis-detonation" -->
```
AoE damage = floor( damage_absorbed × 0.85 )
Radius     = 10 yalms  (centered on the caster)
Damage type = Light (Holy)
```
<!-- DOCGEN:END id="custom-spell-divine-aegis-detonation" -->

If you took 1,500 HP of hits during the buff, the detonation deals `floor(1500 × 0.85) = 1,275` Holy damage to every enemy in range. **Clean expiry:** if the shield absorbed zero damage, the detonation fires but deals no damage — buffs still drop cleanly.

### Notes

- **Cannot overlap with Stoneskin** — casting Divine Aegis while Stoneskin is active returns "No effect."
- The PDT buff and Stoneskin are removed at detonation whether or not enemies are nearby.
- The spell can be recasted after its normal recast timer has elapsed.
- Holy damage type means Undead and Shadow-type enemies take bonus damage from the detonation.

---

## Scroll of Convergence

<!-- DOCGEN:BEGIN id="custom-spell-convergence" -->
**350 Hunt Marks** · Enfeebling Magic · RDM only · Level 50
<!-- DOCGEN:END id="custom-spell-convergence" -->

Convergence is a Red Mage-exclusive enfeebling spell that randomly combines elemental damage with a status effect on each cast. Neither the element nor the enfeeble is known in advance — the combination is drawn fresh every time you cast.

### Mechanic

Each cast randomly selects **one pair** from the following:

<!-- DOCGEN:BEGIN id="custom-spell-convergence-pairs" -->
| Roll | Element | Damage type | Status effect | Duration |
|---:|---|---|---|---|
| 1 | Fire | Fire | **Slow** | 90 s |
| 2 | Light | Light | **Blind** | 90 s |
| 3 | Water | Water | **Paralysis** | 90 s |
| 4 | Earth | Earth | **Silence** | 90 s |
| 5 | Wind | Wind | **Gravity** | 90 s |
| 6 | Thunder | Thunder | **Bind** | 30 s |
<!-- DOCGEN:END id="custom-spell-convergence-pairs" -->

The selected element governs both the damage type and the resist check.

**Damage formula:**

<!-- DOCGEN:BEGIN id="custom-spell-convergence-formula" -->
```
base    = floor( INT×2.5 + MND×2.0 + 80 )
damage  = max(1, floor( base × resistRate ))
```
<!-- DOCGEN:END id="custom-spell-convergence-formula" -->

**Enfeeble:** Applied at standard potency, with duration scaled by `resistRate`. A partial resist reduces both damage and enfeeble duration proportionally. A full resist (`resistRate = 0`) returns "Resist" — no damage, no enfeeble.

### Notes

- The random roll happens at **cast time**, not at recast. You cannot predict or influence which pair fires.
- INT drives damage; MND drives the enfeeble resist check (Enfeebling Magic skill).
- Bind is the only effect with a shorter duration (30 s) — its "power" is the target's movement speed rather than a fixed potency, so faster mobs take shorter Binds.
- Best used as a Swiss Army enfeeble when you need a fast debuff but don't know (or don't care) which specific status lands.

---

## Scroll of Silencega

<!-- DOCGEN:BEGIN id="custom-spell-silencega" -->
**200 Hunt Marks** · Enfeebling Magic · WHM 40 / RDM 50 / SCH 50
<!-- DOCGEN:END id="custom-spell-silencega" -->

Silencega is an AoE version of Silence. It applies the standard Silence status effect to all valid enemies in range using the vanilla enfeebling formula — no custom mechanic. It behaves identically to retail Silence, just with an area-of-effect component.

The scroll is sold here because Silencega does not have a normal acquisition path on this server's version of the client database. Buying the scroll teaches the spell exactly like any other scroll.

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 43d47cb73b1c -->
_Last updated: 2026-06-13 22:18 UTC_
<!-- DOCGEN:END id="last-updated" -->
