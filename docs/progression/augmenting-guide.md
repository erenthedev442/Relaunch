# Augmenting: Start Here

![Augment gem](../assets/emblems/augment.svg){ .lgnd-emblem }

New to augmenting and not sure where to begin? This is the plain-English guide. The two pages after it — [Augment Moogle](augments.md) and [Augment Sage](augment-sage.md) — are the full reference with every number; **this page is just how to start.**

!!! tip "The one-sentence version"
    Augmenting lets you **stamp custom stat bonuses onto any piece of gear** — up to 5 bonuses per piece — by trading a cheap "catalyst" item to the **Augment Moogle** in GM Home. It's the single biggest source of character power on Legendary.

## What it is & what it does

Every catalyst item maps to **one augment** (a stat bonus). Trade a catalyst to the Augment Moogle along with a piece of gear, and that bonus gets **written onto the gear**. Each piece has **5 augment slots**, so you can stamp up to 5 bonuses on it — and you can stack the **same** catalyst to multiply one stat (5× Attack catalysts = 5 lines of Attack on one piece).

This means **any** gear can become best-in-slot. That ring with no useful stats? Stamp it with +HP, +Attack, +Accuracy — whatever your build wants.

## Your first augment, in 60 seconds

Let's add some **Attack** to a piece of gear. (Any stat works the same way — this is just an example.)

1. **Buy the catalysts.** Type `!shop augments str` and buy **5× Black Tiger Hide** (the "Attack" catalyst). Catalysts are cheap.
2. **Have 10,000 gil** in your inventory (flat cost per trade, no matter how many catalysts).
3. **Go to GM Home** and find the **Augment Moogle** (it's in the row of moogles).
4. **Trade** the gear piece **+ your 5 catalysts** to the Moogle. It shows you what's about to be applied.
5. **Confirm.** It takes the 10,000 gil and hands your gear back with **5 lines of Attack** stamped on it.

That's it. You just augmented your first piece. 🎉

!!! warning "Don't panic when the numbers look weird"
    The in-game **item examine window will show garbled/negative values** on augmented gear — that's a known client display quirk, **the stats are really there.** To see your *true* augment values, type **`!augstats`**. (For total gear stats use `!getstats offensive` / `defensive` / `base`.)

## Why your first augment feels small — the most important thing to understand

A brand-new augment lands at its **floor** (the minimum value). That Attack line might only be **+2 per slot** at first. **That's intentional, not broken.**

On Legendary, augment power is **earned** through the **[Augment Sage](augment-sage.md)** (the NPC right next to the Moogle). As you progress with him, *the exact same catalyst* writes bigger and bigger numbers — that +2/slot Attack climbs all the way to **+64/slot** (i.e. **+320 Attack** on a 5-slot piece). So:

> **Augment early, augment often, and re-augment the same gear as you grow.** Your gear gets stronger every time you re-stamp it after a Sage rank-up.

## How to make them stronger (maximizing)

Three things multiply your augment power — stack all three to hit the ceiling:

| Booster | What it is | How to get it |
|---|---|---|
| **Sage Mastery rank** | Ranks 1→5; the global multiplier (×1.2 → ×2.0) and your crit chance (5% → 20%) | Craft augments + turn in seals & a signature NM trophy at the Augment Sage |
| **Category affinity** | A +50% bonus for one stat family | Defeat that category's **signature NM** and register the affinity at the Sage |
| **Critical augment** | A per-trade roll that **doubles** the boost | Happens randomly each trade (chance rises with your rank). A **Maat's Blessing** (from [Maat's Challenge](../endgame/maats-challenge.md)) *guarantees* a crit on your next trade. |

A fresh augment sits at the floor; a **rank-5, affinity-unlocked, critical** augment hits the cap. The [Augment Sage page](augment-sage.md) has the full rank table and NM list.

## Good first moves

- **Pick stats you actually use.** DD? Stack **Attack** and **Accuracy**. Tank? **HP**, **Defense**, and the **−Phys. dmg. taken** catalysts. Caster? **Magic Accuracy** / **Magic Atk**.
- **Stack one stat for a big swing.** 5× the same catalyst on one piece concentrates the bonus where you want it.
- **Start the Augment Sage early.** Every augment you craft counts toward your Mastery ranks — so just *using* the Moogle is progress. Don't wait.
- **Re-augment after every rank-up.** Same gear, same catalysts, bigger numbers.
- **Browse the full catalog** on the [Augment Moogle page](augments.md#catalyst--augment-catalog) — ~300 catalysts across 16 stat families, each with a `!shop augments <family>` command to buy it.

## A few rules to remember

- **5 catalysts max per trade** (5 augment slots per piece).
- **Catalysts are consumed; gear is not** — your gear comes back stamped.
- **Re-augmenting overwrites** the piece's existing augments — that's how you upgrade them as you rank up, but it means you re-apply all 5 lines each time.
- **Cancel any time** during the confirm menu to get everything back.

---

**Ready for the details?** → [Augment Moogle](augments.md) (the full catalyst catalog & exact numbers) · [Augment Sage](augment-sage.md) (ranking up & affinities)

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 55a85bf8681f -->
_Last updated: 2026-06-22 20:44 UTC_
<!-- DOCGEN:END id="last-updated" -->
