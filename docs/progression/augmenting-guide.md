# Augmenting: Start Here

![Augment gem](../assets/emblems/augment.svg){ .lgnd-emblem }

New to augmenting and not sure where to begin? This is the plain-English guide. The two pages after it — [Augment Moogle](augments.md) and [Augment Sage](augment-sage.md) — are the full reference with every number; **this page is just how to start.**

!!! tip "The one-sentence version"
    Augmenting lets you **stamp custom stat bonuses onto any piece of gear** — up to 5 bonuses per piece — by trading a cheap "catalyst" item to the **Augment Moogle** in {{npc:augment_moogle}}. It's the single biggest source of character power on the Relaunch server.

## What it is & what it does

Every catalyst item maps to **one augment** (a stat bonus). Trade a catalyst to the Augment Moogle along with a piece of gear, and that bonus gets **written onto the gear**. Each piece has **5 augment slots**, so you can stamp up to 5 bonuses on it — and you can stack the **same** catalyst to multiply one stat (5× Attack catalysts = 5 lines of Attack on one piece).

This means **any** gear can become best-in-slot. That ring with no useful stats? Stamp it with +HP, +Attack, +Accuracy — whatever your build wants.

## Your first augment

Let's add some **Attack** to a piece of gear. (Any stat works the same way — this is just an example.)

1. **Farm the catalysts.** Every catalyst **drops from one specific monster** (~50% per kill) — catalysts are **no longer bought for gil**. The "Attack" catalyst is **Black Tiger Hide**; its assigned mob is **Divine Inciter** (a level ~70 mob) — kill it until you have **5×**. Which catalysts you can trade scales with your progression — see [Catalyst tiers](#catalyst-tiers-what-you-can-trade) below.
2. **Have 10,000 gil** in your inventory (the Augment Moogle's flat trade cost, no matter how many catalysts).
3. **Go to {{npc:augment_moogle}}** and find the **Augment Moogle** (it's in the row of moogles).
4. **Trade** the gear piece **+ your 5 catalysts** to the Moogle. It shows you what's about to be applied.
5. **Confirm.** It takes the 10,000 gil and hands your gear back with **5 lines of Attack** stamped on it.

That's it. You just augmented your first piece. 🎉

!!! warning "Don't panic when the numbers look weird"
    The in-game **item examine window will show garbled/negative values** on augmented gear — that's a known client display quirk, **the stats are really there.** To see your *true* augment values, type **`!augstats`**. (For total gear stats use `!getstats offensive` / `defensive` / `base`.)

## Every augment is a ROLL — the most important thing to understand

Every line the Moogle writes is **rolled** inside your **Augment Tier's band**. Your tier (1–5) is earned through **custom content**, and each tier's band sits strictly above the one below it — a fresh character rolls small numbers, an endgame character rolls huge ones, **on the exact same catalyst**:

| Augment Tier | Roll band (of 0–31) | How you unlock it |
|---|---|---|
| **T1** | 0–5 | slay your first 10 custom NMs ([Hunting League](index.md), Wave Mode, [Voidspire](../endgame/voidspire.md)...) |
| **T2** | 6–11 | reach [Hunting League](index.md) Rank 5 |
| **T3** | 12–17 | clear [Voidspire](../endgame/voidspire.md) floor 10 + every [Game Master](game-master.md) wave difficulty |
| **T4** | 18–24 | clear a [Dynamis - Divergence](../endgame/dynamis-divergence.md) city |
| **T5** | 25–31 | defeat [Maat's Echo](../endgame/maats-challenge.md) (Ru'Lude Gardens, !maat) |

The ladder is **consecutive** — your tier is the highest step you've cleared in order, and a brand-new character is **Tier 0: the Moogle won't augment at all** until the first gate is cleared.

(Trust summon counts climb a **separate** ladder — Unity Concord accolades, Voidwatch rift tiers, and your Adventuring Fellow's level. See the [Trust page](../reference/spells/trust.md).) That +2/slot Attack roll at Tier 1 climbs all the way to **+64/slot** at a max Tier-5 roll (i.e. **+320 Attack** on a 5-slot piece). So:

> **Augment early, augment often, and re-stamp the same gear each time you climb a tier.** Any T3 roll beats every T2 roll — re-rolling after a tier-up is always an upgrade. Within a tier, re-trade to fish for the top of the band.

## How to roll higher (maximizing)

Three things improve your rolls — stack all three to hit the ceiling:

| Booster | What it does | How to get it |
|---|---|---|
| **Sage Mastery rank** | Ranks 1→5 **raise the roll floor** (+1 per rank within your band) and your crit chance (5% → 30%) | Unlocks automatically as you reach the required Hunting League Rank / Prestige Level milestones — nothing is consumed |
| **Category affinity** | **Roll twice, keep the better** for that stat family | Reach **Hunting League Rank 3**, then register the affinity at the Sage with **1,000 Hunt Marks** + that category's **signature NM trophy** (consumed) |
| **Critical augment** | A **PERFECT roll** — every line in the trade lands at the top of your band | Happens randomly each trade (chance rises with your rank). A **Maat's Cap** (from [Maat's Challenge](../endgame/maats-challenge.md)) *guarantees* a crit on your next trade. |

A max-rank, affinity-held **crit at Tier 5** writes the absolute cap: `(base + 31) × multiplier` per slot. The [Augment Sage page](augment-sage.md) has the full formula, rank table, and NM list.

## Re-rolling in place with `!reroll`

Once a piece already has the augment **types** you want, you don't have to re-farm five catalysts just to chase bigger numbers. The **`!reroll`** command re-gambles the *magnitudes* of the augments already on an **equipped** item — the same roll math as the Moogle (your tier band, mastery floor, affinity double-roll, and crits all apply), but it keeps your existing lines and costs only **gil + one catalyst**.

| | Augment Moogle (trade in {{npc:augment_moogle}}) | `!reroll <slot>` (equipped item) |
|---|---|---|
| **Changes** | Overwrites lines with the catalyst **types** you trade | Keeps the types, re-rolls the **numbers** |
| **Cost** | 10,000 gil flat + up to 5 catalysts | Per-tier gil (below) + **1** matching catalyst |
| **Reach for it to** | Add or change *which* stats sit on the gear | Fish for higher rolls on gear you already like |

Both are **rank-floor protected** (never roll below `band min + your mastery rank`) and **capped at your tier band**, so neither can power-creep past your tier's ceiling — reroll is purely a cheaper way to re-fish the numbers you already have.

**How to use it:**

1. **Equip** the item you want to improve.
2. Type **`!reroll <slot>`** (e.g. `!reroll head`) to **preview** — it lists each augment, the roll range, your floor, your crit %, and the cost. Nothing is charged.
3. Type **`!reroll <slot> confirm`** to commit — it charges the gil + 1 catalyst and re-rolls every line at once.
4. **Re-equip** the item to apply the fresh values.

Slots: `main sub ranged ammo head body hands legs feet neck waist ear1 ear2 ring1 ring2 back`. The catalyst it consumes must match **one of the augments already on the item** — and you have to be holding it.

**Reroll cost by Augment Tier** (plus the one matching catalyst):

| Augment Tier | Reroll cost |
|---|---:|
| **T1** | 25,000 gil |
| **T2** | 50,000 gil |
| **T3** | 100,000 gil |
| **T4** | 175,000 gil |
| **T5** | 250,000 gil |

Because every line re-rolls together, a **crit** (or a guaranteed one from a **Maat's Cap**) turns a single reroll into a perfect roll of the *whole piece*. And since rolls are floor-protected, rerolling after a **tier-up** or a **mastery rank-up** only ever lifts your weakest lines — it's the cheap way to keep already-good gear current.

## Catalyst tiers: what you can trade

Separately from the roll band, each **catalyst** has a tier (T0–T5) — the minimum Augment Tier required to trade it. T0/T1 catalysts (132 of them) are open to everyone; the universally-powerful stats (Triple Atk, Quadruple Attack, Damage Taken...) sit at T3–T5, so the strongest *stats* and the strongest *rolls* unlock together as you clear content. The [catalog](augments.md#catalyst--augment-catalog) groups every catalyst by tier (T0 ×19 · T1 ×113 · T2 ×18 · T3 ×17 · T4 ×47 · T5 ×13).

## Good first moves

- **Pick stats you actually use.** DD? Stack **Attack** and **Accuracy**. Tank? **HP**, **Defense**, and the **−Phys. dmg. taken** catalysts. Caster? **Magic Accuracy** / **Magic Atk**.
- **Stack one stat for a big swing.** 5× the same catalyst on one piece concentrates the bonus where you want it.
- **Start the Augment Sage early.** Mastery ranks unlock automatically as you hit Hunting League Rank / Prestige Level milestones — each rank lifts your worst rolls and raises crit chance. Don't wait.
- **Re-augment after every tier-up.** Same gear, same catalysts, a strictly higher band — a tier-up re-roll is never a downgrade.
- **Browse the full catalog** on the [Augment Moogle page](augments.md#catalyst--augment-catalog) — 227 catalysts across a wide range of stat families, each with its full per-trade stat values.

## A few rules to remember

- **5 catalysts max per trade** (5 augment slots per piece).
- **Catalysts are consumed; gear is not** — your gear comes back stamped.
- **Re-augmenting overwrites** the piece's existing augments — that's how you upgrade them as you rank up, but it means you re-apply all 5 lines each time.
- **Cancel any time** during the confirm menu to get everything back.

---

**Ready for the details?** → [Augment Moogle](augments.md) (the full catalyst catalog & exact numbers) · [Augment Sage](augment-sage.md) (ranking up & affinities)

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 2d5ac592d09e -->
_Last updated: 2026-07-05 03:51 PDT_
<!-- DOCGEN:END id="last-updated" -->
