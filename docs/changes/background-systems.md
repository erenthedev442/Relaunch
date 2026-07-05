# Background Systems

These are server-level systems that run silently in the background — no NPC to talk to, no command to type. Most players encounter them indirectly: you zone into an endgame zone and an NM is already up, or you get stuck in a cutscene loop and zoning fixes it.

This page explains what each system does so you know what's happening when you run into it.

---

## Always-Popped NMs { #abyssea-always-popped }

Every NM in **Reisenjima** and **Reisenjima Sanctorium** auto-spawns at server start and respawns **30 seconds** after death.

No pop requirements. No trade items. No key items. Just walk in and start fighting — if the NM you want is down, it'll be back in half a minute.

Abyssea NMs are **not** blanket-spawned: they're popped on demand at their ??? points with Hunt Marks — see [Abyssea NMs](../endgame/abyssea-nms.md).

!!! note "Hunting League hubs excluded"
    Reisenjima Henge and Escha - Zi'Tah are deliberately outside the auto-pop list — their tier Spawner NPCs pop NMs on demand, so the always-up system would fight the "spawn in front of you" flow.

---

## Unlimited Visitant

In retail Abyssea, Visitant status has a time limit — your clock ticks down, and when it runs out you get ejected. On this server, every player receives **permanent Visitant status** the moment they zone into any Abyssea area — including entries via the `!abyssea` warp command.

No timer. No decay. No Traverser Stones. Zone in and stay as long as you want.

---

## Auto-Unstick

A server-side watchdog runs whenever you zone into the **10 starting-city zones** (Southern San d'Oria, Northern San d'Oria, Port San d'Oria, Bastok Mines, Bastok Markets, Port Bastok, Windurst Waters, Windurst Walls, Port Windurst, Windurst Woods). 3 seconds after zone-in, if your character is still flagged "in an event" (a cutscene loop or stuck event state), the watchdog force-releases you — no GM needed.

It also pre-sets the Mog House second-floor unlock flag, which breaks the classic flower-quest cutscene loop that used to re-trap characters on every login.

So if you're ever locked in a cutscene loop, the fix is simple:

1. Zone (or log out and back in) into one of the starting cities.
2. Wait a moment — the watchdog fires after zone-in and releases the stuck state.

!!! tip
    Logging out and back in inside a starting city counts as a full zone-in cycle and always triggers the watchdog.

---

## Zone-In Cutscenes Disabled

Auto-cutscenes that fire when you zone into a mission-heavy area are suppressed — server-wide, in every zone. If you've ever had the game lock you into a five-minute cutscene just because you walked through a zone line, you know why this exists.

Any side effects the cutscene would have produced — position resets, mission-flag updates, key item grants — still happen. Only the video playback is skipped.

If you want to watch a specific cutscene, talk to the relevant NPC manually — the suppression only covers the auto-trigger-on-zone-in path.

---

## World-First Announcements

When a player achieves a server-first milestone, the server broadcasts it to everyone online. Tracked milestones include:

- **First player death** on the server (yes, this one is tracked)
- **First level-up** (and, less gloriously, the first level *down*)
- **Per-job level milestones** — first of each job to reach level 10, 20, 30, 40, 50, 60, 70, 75, 80, 90 and 99
- **First kill of every NM** — each notorious monster's first defeat is announced

These are stored permanently in server variables — a first stays attributed to the correct player even after server restarts. If you're racing for a world-first, everyone will know when it happens.

---

## Chocobo Raising

Chocobo raising is tuned for faster results:

- **Faster growth** — chick in 2 days, adolescent in 7, full adult in 14 (retail: 4 / 19 / 29)
- **Higher speed cap** — raised riding speed up to **120** (retail clamps at 100)
- **Longer riding time** — up to **60 minutes** in the saddle

If you want a high-stat mount, raising is worth the investment.

---

## SoA Imprimatur Gate Removed

Seekers of Adoulin missions no longer require **Imprimatur** currency or fame to progress — the gate check always passes. Just talk to the NPC and accept the mission.

If you've ever hit the Imprimatur wall on retail (or on a standard private server), this won't be a problem here.

---

## Conquest Regional NPCs Always Up

The **regional merchant NPCs** in **Port Bastok**, **Southern San d'Oria** and **Windurst Woods** are permanently visible, regardless of which nation holds conquest standing in each region.

On retail, these NPCs disappear when their nation loses the region — leaving you to come back next week. On this server, they're always there (Nokkhi Jinjahl, Ominous Cloud, Valeriano, Mokop-Sankop, Cheh Raihah, Nalta, Dahjal).

---

## Double-Duration Enhancing Magic

Every Enhancing Magic spell lasts **twice as long** as it normally would. The 2× is applied on top of all the usual modifiers — gear "Enhancing Magic Duration", RDM merits and job points, Composure, Perpetuance, and Embolden all stack first, then the result is multiplied.

- A 5-minute Protect becomes **10 minutes**.
- A Composure'd 5-minute buff (already ×3) becomes **30 minutes**.

No NPC, no gear requirement — it applies to every player casting any enhancing spell.

---

## Blue Mage Auto-Learns Spells

Blue Mage never has to hunt down and learn spells the hard way. As your BLU levels up, every spell it would normally have to learn from a monster (all **194** of them) is **granted automatically** at the appropriate level. Logging in also runs a full catch-up, so a BLU is always holding the complete spell list for its current level.

This covers **/BLU as a subjob** too — the sub's spell list fills in as your main level (and with it the sub level) rises.

You still set and arrange your own spells — this only removes the chore of farming each one off a mob.

---

## Auto-Buff at the Hunting League Hub

Zone into **Escha - Zi'Tah** (the Hunting League hub, reached with `!hunt`) and the server applies your buffs automatically — the same package as the [`!buff`](../progression/server-features.md#the-buff-command) command: a regional buff plus Refresh (10% of max MP per tick), Regen (10% of max HP per tick) and Regain (1 per 10 levels), for **5 hours**.

You can start hunting the moment you arrive without typing anything. If the buffs drop mid-session, `!buff` re-applies them anywhere.

---

## Al Zahbi Loot Fountain

Every monster killed in **Al Zahbi** drops one extra random item, rolled from across the whole item database, on top of its normal loot. It is pure novelty — you never know what you'll get — and it stacks with the [Scheduled Invasions](../endgame/invasions.md) that also take place there.

---

## GM Home Seal Drops

Monsters killed inside **GM Home** (where the [Test Dummy](../progression/gm-home.md#test-dummy) lives) drop **gear-vendor seals** every kill — the currency the [Gear Vendors](../progression/gear-vendors.md) accept.

- **Tier scales with mob level** — below level 90 drops Beastmens Medals, level 90+ drops Kindreds Medals, and **NMs bump one tier higher** (so a 90+ NM yields Demons Medals).
- **Quantity varies per kill** — every kill yields at least one; 50% for 2+, 33% for 3+, 25% for 4+; and a 5% shot at the **10-seal jackpot**.

It's a small bonus faucet for testing your damage on something that fights back.

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 01ef803a1c5e -->
_Last updated: 2026-07-05 07:37 UTC_
<!-- DOCGEN:END id="last-updated" -->
