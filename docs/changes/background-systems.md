# Background Systems

These are server-level systems that run silently in the background — no NPC to talk to, no command to type. Most players encounter them indirectly: you zone into Abyssea and an NM is already up, or you get stuck in a cutscene loop and zoning out fixes it.

This page explains what each system does so you know what's happening when you run into it.

---

## Abyssea Always-Popped

Every NM across **all ten Abyssea zones**, **Escha** (Zi'Tah + Ru'Aun), **Reisenjima**, and **Reisenjima Sanctorium** auto-spawns at server start and respawns **30 seconds** after death.

No pop requirements. No trade items. No key items. No atmacite. No cruor threshold. Just walk in and start fighting.

This covers HNMs and wave bosses in those zones as well. If you're looking for a specific Abyssea NM, it's already up — or it'll be back in half a minute.

!!! note "Escha ZiTah excluded"
    The hub itself is excluded from the always-pop system so the Hunting League's on-demand Spawner keeps working correctly.

---

## Unlimited Visitant

In retail Abyssea, Visitant status has a time limit — your clock ticks down, and when it runs out you get ejected. On this server, every player receives **permanent Visitant status** the moment they zone into any Abyssea area.

No timer. No decay. No atma farming just to stay inside. Zone in and stay as long as you want.

---

## Auto-Unstick

A server-side watchdog clears stuck event state whenever you zone in. If your character is locked in a cutscene loop or stuck in a "still in event" state, the fix is simple:

1. Zone out (walk to a zone line, or use any teleport command).
2. Zone back in.
3. The watchdog fires on zone-in and releases the stuck state.

!!! tip
    If zoning once doesn't clear it, log out and back in — that's a full zone-in cycle and always triggers the watchdog.

---

## Zone-In Cutscenes Disabled

Auto-cutscenes that fire when you zone into a mission-heavy area are suppressed. If you've ever had the game lock you into a five-minute cutscene just because you walked through a zone line, you know why this exists.

Any side effects that the cutscene would have produced — position resets, charvar updates, key item grants — still happen. Only the video playback is skipped.

If you want to watch a specific cutscene, talk to the relevant NPC manually.

---

## World-First Announcements

When a player achieves a server-first milestone, the server broadcasts it to everyone online. Tracked milestones include:

- **First player death** on the server (yes, this one is tracked)
- **First level-up to 99** per job (e.g., "First WAR to hit 99")
- **First kills** of tracked HNMs

These are stored permanently — a title stays attributed to the correct player even after server restarts. If you're racing for a world-first, everyone will know when it happens.

---

## Chocobo Raising

Chocobo raising is tuned for faster results:

- **2-day chick cycle** (faster than retail)
- **Higher stat caps** — riding speed up to 120, higher endurance ceiling
- Active raising is balanced around the faster growth curve

If you want a high-stat mount, raising is worth the investment.

---

## SoA Imprimatur Gate Removed

Seekers of Adoulin missions no longer require **Imprimatur** currency or fame to progress. Just talk to the NPC and accept the mission.

If you've ever hit the Imprimatur wall on retail (or on a standard private server), this won't be a problem here.

---

## Conquest Regional NPCs Always Up

Bastok, Windurst, and San d'Oria **regional NPCs** are permanently visible, regardless of which nation holds conquest standing in each region.

On retail, regional NPCs disappear when their nation loses the region — leaving you to come back next week. On this server, they're always there.

---

## Double-Duration Enhancing Magic

Every Enhancing Magic spell lasts **twice as long** as it normally would. The 2× is applied on top of all the usual modifiers — gear "Enhancing Magic Duration", RDM merits and job points, Composure, Perpetuance, and Embolden all stack first, then the result is doubled.

- A 5-minute Protect becomes **10 minutes**.
- A Composure'd 5-minute buff (already ×3) becomes **30 minutes**.

No NPC, no gear requirement — it applies to every player casting any enhancing spell.

---

## Blue Mage Auto-Learns Spells

Blue Mage never has to hunt down and learn spells the hard way. As your BLU levels up, every spell it would normally have to learn from a monster is **granted automatically** at the appropriate level. Logging in also runs a full catch-up, so a BLU is always holding the complete spell list for its current level.

You still set and arrange your own spells — this only removes the chore of farming each one off a mob.

---

## Auto-Buff at the Hunting League Hub

Zone into **Escha - Zi'Tah** (the Hunting League hub, reached with `!hunt`) and the server applies your buffs automatically — the same package as the [`!buff`](../progression/server-features.md#the-buff-command) command: a regional buff plus Refresh, Regen, and Regain, for 30 minutes.

You can start hunting the moment you arrive without typing anything. If the buffs drop mid-session, `!buff` re-applies them anywhere.

---

## Al Zahbi Loot Fountain

Every monster killed in **Al Zahbi** drops one extra random item, rolled from across the whole item database, on top of its normal loot. It is pure novelty — you never know what you'll get — and it stacks with the [Scheduled Invasions](../endgame/invasions.md) that also take place there.

---

## GM Home Seal Drops

Monsters killed inside **GM Home** (where the [Test Dummy](../progression/gm-home.md#test-dummy) lives) drop **gear-vendor seals** every kill — the currency the [Gear Vendors](../progression/gear-vendors.md) accept. The seal tier scales with the mob's level, NMs drop a tier higher, and the quantity varies per kill (with the occasional jackpot stack). It's a small bonus faucet for testing your damage on something that fights back.

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: fec38e575fc2 -->
_Last updated: 2026-06-29 04:19 UTC_
<!-- DOCGEN:END id="last-updated" -->
