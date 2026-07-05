---
title: Weapon Skills vs Retail
---

# Weapon Skills vs Retail

Like [Gear vs Retail](gear-vs-retail.md), this page tracks where the server's
**weapon-skill mechanics** intentionally differ from retail FFXI. Two things
change: how far a weapon skill's damage can go, and which weapon skills you're
allowed to use.

---

## Damage is uncapped for you and your pets

On retail, a single hit — a weapon skill, a melee swing, a pet's attack — can
never register more than **131,071** damage. That's a hard limit of the game's
17-bit damage packet, not a balance choice; anything above it is simply lost.

On this server that ceiling is lifted for **player-controlled** damage:

- **Your weapon skills and melee hits land their full value on the target's
  HP**, even when a hit is worth 200,000, 500,000, or more.
- The same applies to damage from **your pets, trusts, avatars, and
  automatons** — anything whose master is you.
- The **floating number** over the enemy still maxes out at 131,071 (no client
  field is wide enough to draw a bigger one), so the game **whispers the true
  total to you in chat** — a pet or trust hit is prefixed so you know whose it
  was (e.g. `[Automaton WS] 250000`).
- **Enemy damage stays capped.** A monster can't punch through the ceiling onto
  you — the uncap is one-directional, players only.

!!! note "Why the on-screen number looks wrong"
    When a weapon skill over-caps, the big yellow number on the mob is the
    *packet limit*, not what you actually dealt. Trust the chat readout — that's
    the real damage the target lost.

Two related tweaks build on this:

- **Prime Aftermath** grants a *Damage Limit +%* bonus on several Prime
  weapons, which raises the ceiling further before the uncap even matters — see
  [Prime Armory](../progression/prime-armory.md).
- **Automatons** get a flat outgoing-damage multiplier so a level-99-capped
  puppet can still contribute against the server's level-150 NMs. A PUP's
  weapon skills therefore hit far harder here than on retail.

---

## Weapon skills retail won't let you use

Retail ships a number of weapon skills purely as **monster** abilities — the
animations and effects exist, but no player can ever execute them. The Prime
weapon overhaul turns a roster of these on as real **player** weapon skills,
granted by equipping the matching Prime weapon.

<!-- DOCGEN:BEGIN id="ws-vs-retail-custom" -->
The server enables **15 weapon skills** that retail FFXI ships as monster-only skills — here they are usable by players wielding the listed Prime weapon. (Stock LandSandBoat leaves these commented out in `sql/weapon_skills.sql`; the Prime weapon overhaul turns them on.)

| Weapon skill | Weapon | Prime weapon | On retail | On this server |
|---|---|---|---|---|
| **Sarv** | Archery | Prime Bow | Monster skill only | Usable weapon skill |
| **Blitz** | Axe | Prime Pickaxe (Axe) | Monster skill only | Usable weapon skill |
| **Dagda** | Club | Prime Maul | Monster skill only | Usable weapon skill |
| **Merciless Strike** | Dagger | Mpu Gandring | Monster skill only | Usable weapon skill |
| **Disaster** | Great Axe | Prime Great Axe | Monster skill only | Usable weapon skill |
| **Tachi: Mumei** | Great Katana | Kusanagi-no-Tsurugi | Monster skill only | Usable weapon skill |
| **Fimbulvetr** | Great Sword | Prime Blade (Great Sword) | Monster skill only | Usable weapon skill |
| **Dragon Blow** | Hand-to-Hand | Prime Fists | Monster skill only | Usable weapon skill |
| **Maru Kala** | Hand-to-Hand | Varga Purnikawa | Monster skill only | Usable weapon skill |
| **Terminus** | Marksmanship | Prime Gun | Monster skill only | Usable weapon skill |
| **Diarmuid** | Polearm | Prime Lance | Monster skill only | Usable weapon skill |
| **Origin** | Scythe | Prime Scythe | Monster skill only | Usable weapon skill |
| **Oshala** | Staff | Prime Staff | Monster skill only | Usable weapon skill |
| **Fast Blade II** | Sword | Naegling | Monster skill only | Usable weapon skill |
| **Imperator** | Sword | Prime Sword | Monster skill only | Usable weapon skill |
<!-- DOCGEN:END id="ws-vs-retail-custom" -->

Everything else about weapon skills — the fTP tables, hit counts, stat
modifiers, and skillchain properties — follows stock LandSandBoat, which
mirrors retail. Only the two areas above are changed.

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 99c7cd34a1d2 -->
_Last updated: 2026-07-05 07:44 UTC_
<!-- DOCGEN:END id="last-updated" -->
