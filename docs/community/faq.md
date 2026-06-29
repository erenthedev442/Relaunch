# FAQ

Common questions about playing on the Relaunch server FFXI. If you have a question that isn't answered here, ask in our [Discord](https://discord.gg/ZKdYbAJF) or open an issue on the [project repo](https://github.com/richardknutzjr/FFXI-Private-Server-FJB).

## Getting Started

### How do I connect to the server?

See [Getting Started → Install the Client](../getting-started/install.md) and [Connect to Server](../getting-started/connect.md) for the full walkthrough.

### Do I need a Square Enix account or game license?

No. the Relaunch server runs against a private server built on [LandSandBoat](https://github.com/LandSandBoat/server). You only need the FFXI client itself, not an active SE subscription.

### How do I create a character?

Once connected, the standard FFXI character-creation flow runs as usual. Every new character starts at the configured starting level, full inventory, all maps + outpost warps, and the starting gil bundle listed on the [home page](../index.md).

---

## Progression & Power

### Why does my character feel weak compared to retail at the same level?

Stats are tuned for this server's faster progression curve, but combat is balanced around the level-99 cap with rebalanced gear. If you feel weak, check the [Gear Vendors](../progression/gear-vendors.md) page — the Hunt Mark currencies are the fastest path to iLvl 119 gear.

### How do I earn Hunt Marks?

Kill the NMs at the [Hunting League](../progression/index.md) Spawner. Each NM gives points scaled by tier; higher tiers give more. Unlock tiers using the **Hub NPC** at the hunt zone.

### What's the difference between the Hunting League NPC and the Reforge System NPC?

- **[Hunting League](../progression/index.md)** — entry-to-mid-tier gear sold for Hunt Marks (Bronze/Silver/Gold seals).
- **[Reforge System](../progression/reforge.md)** — AF/Relic/Empyrean reforge upgrades. Drops base pieces + currency by killing categorized NMs (Sky Gods → AF Marks, Unity NMs → Relic Marks, Abyssea NMs → Empyrean Marks).

### How does the [Augment Moogle](../progression/augments.md) differ from the [Augment Sage](../progression/augment-sage.md)?

- **Augment Moogle** stamps a single augment from a catalyst item onto a piece of gear. One catalyst, one augment.
- **Augment Sage** is a Mastery rank system that *multiplies* augment values (up to 2× at rank 5) plus per-NM affinity bonuses. Mastery ranks unlock at Hunting League Rank + Prestige Level milestones (nothing consumed); per-NM affinities require Hunting League Rank 3, 1,000 Hunt Marks, and the NM's trophy (consumed). Talk to the Sage to track and rank up.

---

## Custom Commands

### Where's the full list of player commands?

[Reference → Player Commands](../reference/commands.md) — every player command, with parameter types and descriptions. Each is tagged `upstream` or `custom` so you can tell which are server-specific.

### What does `!mystats` show me?

A complete dump of every stat your character has, including bonuses from gear and active buffs. Useful for verifying that a piece of gear is actually doing what its tooltip says. See the [`!mystats` entry](../reference/commands.md#mystats) for the full output format.

### Can I auto-spend job points / merits?

Yes — `!autojp` and `!automerits`. Both spread points breadth-first across categories on your current main job, so no single category gets maxed before others get a look-in. See [`!autojp`](../reference/commands.md#autojp) and [`!automerits`](../reference/commands.md#automerits).

---

## Community & Multiplayer

### How do I find other players?

- [Leaderboards](leaderboards.md) — top players by Hunt Marks, NM kills, lifetime currency earned.
- [Player Profiles](players/index.md) — browse individual character pages.
- [Discord](https://discord.gg/ZKdYbAJF) — live chat, group-up posts, server announcements.

### Can I play solo?

Yes. Almost all custom content (Hunting League, Reforge System, Weekly Hunts) can be soloed at the cap. Difficulty is gear-checked, not group-size-checked.

---

## Technical / Server Issues

### The server's down / I can't connect. What do I do?

1. Check the [Discord](https://discord.gg/ZKdYbAJF) #server-status channel first — outages and maintenance windows are announced there.
2. If the server is up but you can't connect, verify your client is pointed at the right login server (see [Connect to Server](../getting-started/connect.md)).

### I think I found a bug. Where do I report it?

Two options:
- **[GitHub Issues](https://github.com/richardknutzjr/FFXI-Private-Server-FJB/issues)** — preferred for reproducible bugs with clear steps.
- **[Discord](https://discord.gg/ZKdYbAJF) #bug-reports** — for quick reports or "is this intended?" questions.

### My character got stuck / I lost an item / something broke. Can a GM help?

Ping a GM in [Discord](https://discord.gg/ZKdYbAJF). Specify your character name, what happened, and roughly when. Most stuck-character and accidental-deletion situations can be resolved.

---

## Server Customizations

### What's different about this server vs. retail / vs. plain LandSandBoat?

The [What's Custom](../changes/index.md) page is the authoritative list. Highlights:

- Faster EXP / CP / drop rates (current multipliers shown on the [home page](../index.md))
- Full subjob from character creation
- 99 starting level cap, all maps + outpost warps granted at creation
- Custom Hunting League, Reforge System, Augment Sage, Job Rebirth, and Weekly Hunt Board systems
- Every player command listed in [Reference → Player Commands](../reference/commands.md)

### Are character files / progress safe? Are there backups?

Yes — daily backups of the character database are taken. In a worst case, the most you'd lose is a few hours.

---

_Have a question that should be on this page? Ping a GM in [Discord](https://discord.gg/ZKdYbAJF) and we'll add it._

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 040cf919fcbf -->
_Last updated: 2026-06-29 04:19 UTC_
<!-- DOCGEN:END id="last-updated" -->
