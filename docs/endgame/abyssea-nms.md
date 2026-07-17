# Abyssea NMs — Hunt Marks System

Abyssea is home to some of the most powerful Notorious Monsters on the server. Rather than hunting down rare key items to spawn them, the Relaunch server replaces the retail pop system with a **Hunt Marks** spend: find the `???`, pay your marks, and the NM rises right in front of you.

!!! tip "Summary"
    Spend Hunt Marks at any Abyssea `???` to pop its NM on demand. Kill it with your party for a large Infamy and Gil payout — no key items required.

---

## Zones & Difficulty Tiers

Abyssea is divided into three Relic-led difficulty tiers. Every NM is level 99
so level correction and evasion are not the puzzle; higher tiers combine more
telegraphed mechanics and give less room for repeated mistakes.

<!-- DOCGEN:BEGIN id="abyssea-tiers" -->
| Tier | Zones | Mark Cost | Level | HP |
|---|---|---|---|---|
| **Visions** | Konschtat, Tahrongi, La Theine | 200 marks | 99 | 4,000,000 |
| **Scars** | Attohwa, Misareaux, Vunkerl | 350 marks | 99 | 8,000,000 |
| **Heroes** | Altepa, Grauberg, Uleguerand | 500 marks | 99 | 14,000,000 |
<!-- DOCGEN:END id="abyssea-tiers" -->

!!! warning "Relic progression content"
    Visions is the first Relic check. It is intentionally too slow for a
    typical pre-Relic solo build, but a properly enhanced Relic can clear it
    without accuracy frustration. Scars assumes one Atma slot; Heroes assumes
    up to two. One player with Trusts can clear every encounter, while a
    prepared duo or trio gains speed and recovery.

HP scales from the number of real PCs present when the fight starts: **1.0× /
1.55× / 2.1×** for one / two / three-or-more PCs. Defense and evasion never
scale, and 70%/30% phase floors release as soon as the associated mechanic is
resolved.

## How Encounters Work

All **136** logical marks NMs have an individual encounter definition. (There
are 136 rather than the old documented 135: Abyssea-Attohwa contains 17 logical
NMs, including Pallid Percy.) Duplicate `???` locations for flagship NMs are
alternate spawn copies of the same fight.

Each warning has:

1. A forced combat message and a weakness animation.
2. A universal response such as turning, repositioning, pausing attacks,
   recovering HP, breaking a ward, or using a weapon skill.
3. A short defense/evasion vulnerability when answered correctly.
4. Recoverable damage, a brief ailment, and one escalation stack when missed.

Trust attacks do not fail hold-fire mechanics. Mechanics that demand a player
decision select the real player who started the fight, never a Trust. If a
fight runs beyond its tier's pressure ceiling, its attack and casting pressure
begins rising in visible steps; it does not gain passive drain or regeneration.

### Abyssea weaknesses matter again

- **Red:** retains the long retail stagger, removes one escalation stack, and
  preserves the Atma unlock.
- **Yellow:** suppresses the spell sequence and opens a magic-biased
  vulnerability.
- **Blue:** suppresses the TP sequence and opens a physical vulnerability.

Exact procs remain optional mastery goals. No solo clear requires a particular
job, spell, or randomly selected proc.

### Roster and Lunar Abyssite progression

The first clear of each logical NM is recorded once regardless of which
duplicate `???` was used, and refunds half of that tier's pop cost. Completing
all NMs in any one **Visions** zone awards the first Lunar Abyssite/Atma slot;
completing any one **Scars** zone awards the second. Heroes is balanced around
those two slots, not the retail maximum of three.

---

## Getting There

Use the `!abyssea` command to open a zone warp menu:

```
!abyssea
```

A two-tier menu appears — pick the expansion tier, then the specific zone. You'll land at a safe camp near the zone entrance.

---

## Popping an NM

Each Abyssea NM has a `???` landmark somewhere in the zone. Walk up to it and check:

**If you're missing the retail key items** (which you almost certainly are — they've been removed from the game):

1. A menu appears showing the NM name and the Hunt Mark cost.
2. If you have enough marks, a **Pop** button is available — confirm it.
3. Your marks are spent, the NM spawns directly next to you, and it's already claimed to your party.

**If you somehow still have the original retail key items**, the vanilla pop still works — the `???` will handle it as normal.

!!! note "Key items from retail"
    If you had any Abyssea pop key items from retail (Tattered Hippogryph Wing, Cracked Wivre Horn, etc.), they were automatically removed from your inventory when you last logged in. They have no function on this server.

---

## Rewards

Killing a marks-popped NM pays out **Infamy** and **Gil** to **every member of your party**. The payout scales with your party composition.

<!-- DOCGEN:BEGIN id="abyssea-rewards" -->
### Base rewards by tier

| Tier | Infamy | Gil |
|---|---|---|
| Visions | 25 | 250,000 |
| Scars | 40 | 500,000 |
| Heroes | 60 | 750,000 |

### Multipliers

Two bonuses can stack on top of the base reward:

| Condition | Multiplier |
|---|---|
| **2 or more real players** in party | ×2.0 |
| **No trusts** in party | ×1.5 |

These multiply together, so a full party of real players with no trusts earns **×3.0**.

### Full reward table

=== "Visions"

    | Scenario | Mult | Infamy | Gil |
    |---|---|---|---|
    | Solo, with trusts | ×1.0 | 25 | 250,000 |
    | Solo, no trusts | ×1.5 | 37 | 375,000 |
    | Party, with trusts | ×2.0 | 50 | 500,000 |
    | Party, no trusts | ×3.0 | 75 | 750,000 |

=== "Scars"

    | Scenario | Mult | Infamy | Gil |
    |---|---|---|---|
    | Solo, with trusts | ×1.0 | 40 | 500,000 |
    | Solo, no trusts | ×1.5 | 60 | 750,000 |
    | Party, with trusts | ×2.0 | 80 | 1,000,000 |
    | Party, no trusts | ×3.0 | 120 | 1,500,000 |

=== "Heroes"

    | Scenario | Mult | Infamy | Gil |
    |---|---|---|---|
    | Solo, with trusts | ×1.0 | 60 | 750,000 |
    | Solo, no trusts | ×1.5 | 90 | 1,125,000 |
    | Party, with trusts | ×2.0 | 120 | 1,500,000 |
    | Party, no trusts | ×3.0 | 180 | 2,250,000 |
<!-- DOCGEN:END id="abyssea-rewards" -->

After the kill a system message confirms your payout and any active multiplier bonus.

---

## What to Spend Infamy On

<!-- DOCGEN:BEGIN id="abyssea-infamy-costs" -->
Infamy is spent at the **Infamy Vendor** in <!--npc:infamy_vendor-->Purgonorgo Isle<!--/npc-->. The full catalog — accessories, best-in-slot armor, and Relic / Mythic / Aeonic weapons — is listed with exact prices on the [Gear Vendors](../progression/gear-vendors.md#infamy-vendor) page. A few reference points, priced against the top **Heroes** payout:

| Reward | Infamy | Heroes kills _(party, no trusts — ×3.0)_ |
|---|---:|---:|
| Cheapest item | 3,000 | 17 kills |
| Standard endgame weapon _(Relic / Mythic / Aeonic)_ | 5,000 | 28 kills |
| Most expensive item | 5,000 | 28 kills |

A full party clearing **Heroes** NMs without trusts earns **180 Infamy per kill** (the ×3.0 rate from the reward table above) — so a standard endgame weapon works out to roughly **28 kills**.
<!-- DOCGEN:END id="abyssea-infamy-costs" -->

---

## Tips

- **Read before bursting.** A 200–300k Relic WS cannot skip the 70% or 30%
  tests. Resolve the warning, then spend the earned vulnerability window.
- **Accuracy is not progression.** If the fight feels like an accuracy wall,
  report the NM and build; the rebuilt tiers intentionally use modest evasion.
- **Bring recovery.** A single failed mechanic is survivable. Repeated failures
  add escalation stacks and are intended to end the attempt.
- **Drop your trusts before the kill.** The ×1.5 no-trust multiplier is free Infamy. Dismiss them once the NM is engaged and you're confident in your party.
- **The NM respawns after a server restart.** If you pop and kill an NM, the `???` is available immediately for the next pop — there's no lockout timer.
- **You need to be the one to land the kill.** Only parties where someone gets the killing blow trigger the reward. Don't let a rogue trust finish it off right as you dismiss them.

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 104f0b54167e -->
_Last updated: 2026-07-17 04:15 PDT_
<!-- DOCGEN:END id="last-updated" -->
