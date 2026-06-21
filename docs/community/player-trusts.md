# Player Trusts

Party with someone for long enough and you both unlock each other as a personal **Trust** — a permanent in-game bond that you can summon for a stat boost, and upgrade over time.

!!! tip "Summary"
    Party up with another character. Stay in the same zone. Once your shared party time reaches **30 minutes**, you both automatically unlock each other as Trusts. Talk to the **Companion Master** at GM Home to summon any unlocked friend, or spend gil to upgrade their tier.

## How unlocking works

The friendship counter increments **once per minute**, but only while ALL of these are true:

- Both characters are online
- Both are in the **same party** (any role, leader doesn't matter)
- Both are in the **same zone**

The counter does **not** decrement when conditions stop being met — it just pauses. You can leave each other's party, log out, take a week off, then resume; your accumulated minutes wait for you.

At <!-- DOCGEN:BEGIN id="pt-unlock-minutes" -->
**30 minutes** of shared party-in-zone time
<!-- DOCGEN:END id="pt-unlock-minutes" -->, both characters get an unlock notification:

> `[Companion Master] You have unlocked Jbae as a Trust, kupo! Visit the Companion Master at GM Home.`

The unlock is permanent. Logout/zone changes don't undo it.

## The Companion Master NPC

<!-- DOCGEN:BEGIN id="pt-npc-location" -->
At GM Home, position **(x = 7.500, y = 0.000, z = -10.000, rot = 128)**.
<!-- DOCGEN:END id="pt-npc-location" -->

Talk to them to see a menu:

```
Companion Master
  Jbae [Bronze]
  Bdr [Silver]
  Wanheda [Gold]
  Close
```

Each entry shows the friend's name and their current Trust tier. Pick one to enter a sub-menu:

```
Jbae [Bronze]
  Set as Active Trust
  Quick Buff (30min stat boost)
  Upgrade to Silver (500,000 gil)
  << Back
```

## How to upgrade

Upgrades happen at the Companion Master, paid in gil, and bump a friend's tier one step at a time (Bronze → Silver → Gold → Platinum → Mythic). Each step:

1. Pick the friend from the Companion Master's roster — their tier is shown next to the name.
2. Choose `Upgrade to <next tier>` from the sub-menu.
3. The transaction is **atomic**: if you have enough gil, the tier bumps and the gil leaves your wallet in the same instant. If you don't, you get a "You need N gil" message and **nothing is charged.**
4. Each upgrade is independent per friend — maxing Jbae costs you nothing toward Bdr.

**The gil ladder per friend:**

| Step | Cost | Cumulative |
|---|---:|---:|
| Bronze (auto on unlock) | — | 0 |
| → Silver | 500,000 | 500,000 |
| → Gold | 1,500,000 | 2,000,000 |
| → Platinum | 4,000,000 | 6,000,000 |
| → Mythic | 10,000,000 | 16,000,000 |

So **a Mythic Trust represents 16M gil sunk into one friendship.** With Legendary's 100× quest gil and 10× mob gil rates, that's achievable but meaningful — not a casual purchase.

### Where the upgrade actually goes

This is the part that confuses people. The Trust system has **two summon modes**, and each tier bump improves **both at once**, but on different entities:

| Catalog field | Buffs… | When it applies |
|---|---|---|
| `statBonus`, `hpBonus`, `mpBonus`, `buffDurationMin` | **You** (the casting player) | Only when you pick **Quick Buff** at the NPC — a status-effect-style flat bonus on your character |
| `trustMult` (multiplies `trustBaseMods`) | **The summoned Trust mob** | Only when you cast the slot's spell to summon the real follower |

Concretely: upgrade Jbae to Mythic →
- Casting Quick Buff on yourself: **you** get +20 to all stats, +250 HP, +125 MP, 2 hour duration.
- Summoning Jbae as a real Trust: **the spawned mob** gets every base mod (HPP / DEF / MEVA / ATT / ACC / MATT / MACC / Haste / STR / DEX / VIT auras) multiplied by 2.0× — so the follower hits harder, lives longer, and projects a bigger stat aura onto you.

The Quick Buff and the real Trust are mutually exclusive moments — you cast one or the other — but a higher-tier friend strengthens whichever path you choose at cast time.

## Two ways to summon

### As a real Trust (recommended)

You have **five Trust slots**. Each slot maps to a specific hijacked Trust spell in your spell book. Assign a friend to a slot via the Companion Master, then cast that slot's spell to summon them.

<!-- DOCGEN:BEGIN id="pt-slots-table" -->
| Slot | Cast this spell to summon your assigned friend |
|---:|---|
| 1 | Trust: Kuyin Hathdenna |
| 2 | Trust: Rosulatia |
| 3 | Trust: Teodor |
| 4 | Trust: King Of Hearts |
| 5 | Trust: Morimar |
<!-- DOCGEN:END id="pt-slots-table" -->

The mob that spawns:

- Wears your friend's race (captured the moment you first unlocked each other)
- Displays your friend's character name above its head
- Has combat AI just like any Trust — follows you, attacks what you fight, despawns on zone change
- Has tier-scaled stats — see the table below

**You can have all five slots filled at once.** Cast multiple spells and you get a full alliance of friend-Trusts. Each slot tracks its own friend assignment; switching a friend between slots is free at the Companion Master.

> Why those weird spell names? Engine-side, we hijack five obscure Walk of Echoes / Records of Eminence Trusts (none of which players normally obtain) to run our own logic — those spells are the "slots" all your friend-Trusts use. The mob you actually summon is fully customized; only the spell's listed name in your book is fixed. **Pro tip:** rename your macros to "Summon Bdr" / "Summon Jbae" / etc. instead of using the default spell names.

### Quick buff

Pick **Quick Buff** on a friend for a low-effort, no-cast stat boost (the old v1 behavior, kept around). Immediate, lasts 30-120 minutes depending on tier, applies flat bonuses:

- **+stat** to all 7 main stats (STR/DEX/VIT/AGI/INT/MND/CHR)
- **+HP** flat health
- **+MP** flat magic

Only one Quick Buff can be active at a time — re-summoning replaces it. No visible buff icon; the chat message tells you the duration and bonuses.

## Upgrade tiers

Five tiers per friend. Upgrade costs are paid in gil at the Companion Master and are independent per friend — maxing Jbae costs you nothing toward Bdr.

### Cost and duration ladder

<!-- DOCGEN:BEGIN id="pt-cost-ladder" -->
| Tier | Duration (Quick Buff) | Gil from previous tier | Cumulative |
|---|---:|---:|---:|
| Bronze | 30 min | (free on unlock) | 0 |
| Silver | 45 min | 500,000 | 500,000 |
| Gold | 60 min | 1,500,000 | 2,000,000 |
| Plat. | 90 min | 4,000,000 | 6,000,000 |
| Mythic | 120 min | 10,000,000 | 16,000,000 |
<!-- DOCGEN:END id="pt-cost-ladder" -->

### Full Quick Buff ledger

Picking **Quick Buff** at the Companion Master applies these 9 mods to **you** (the casting player) for the duration above. The `statBonus` field is a single value that lifts all 7 main stats simultaneously — at Mythic that's +20 to every one of STR / DEX / VIT / AGI / INT / MND / CHR.

<!-- DOCGEN:BEGIN id="pt-quick-buff" -->
| Mod on caster | Bronze | Silver | Gold | Plat. | Mythic |
|---|---:|---:|---:|---:|---:|
| **STR** | +3 | +6 | +10 | +14 | +20 |
| **DEX** | +3 | +6 | +10 | +14 | +20 |
| **VIT** | +3 | +6 | +10 | +14 | +20 |
| **AGI** | +3 | +6 | +10 | +14 | +20 |
| **INT** | +3 | +6 | +10 | +14 | +20 |
| **MND** | +3 | +6 | +10 | +14 | +20 |
| **CHR** | +3 | +6 | +10 | +14 | +20 |
| **HP** (flat) | +20 | +50 | +100 | +150 | +250 |
| **MP** (flat) | +10 | +25 | +50 | +75 | +125 |
<!-- DOCGEN:END id="pt-quick-buff" -->

Only one Quick Buff can be active at a time across all your friends — casting a different friend's Quick Buff replaces the active one.

## Leaderboard credit

Each unlock bumps your `Trusts_Unlocked` counter, which feeds a future "Most Friends" leaderboard slot. Mythic-tier upgrades don't add extra credit there — every friend counts once, regardless of tier — but they do reflect on your wallet.

## Tier scaling for the Trust mob

When you summon the **real Trust** (not the Quick Buff), the spawned follower mob gets every mod in `catalog.trustBaseMods` multiplied by the friend's tier. Eleven mods total, four functional groups:

<!-- DOCGEN:BEGIN id="pt-mob-scaling" -->
| Mod on the Trust mob | Bronze (1×) | Silver (1.25×) | Gold (1.5×) | Plat. (1.75×) | Mythic (2×) |
|---|---:|---:|---:|---:|---:|
| **HPP** (% extra HP on the mob) | +20% | +25% | +30% | +35% | +40% |
| **DEF** | +50 | +62.5 | +75 | +87.5 | +100 |
| **MEVA** (magic evasion) | +30 | +37.5 | +45 | +52.5 | +60 |
| **ATT** | +50 | +62.5 | +75 | +87.5 | +100 |
| **ACC** | +30 | +37.5 | +45 | +52.5 | +60 |
| **MATT** (magic attack) | +30 | +37.5 | +45 | +52.5 | +60 |
| **MACC** (magic accuracy) | +30 | +37.5 | +45 | +52.5 | +60 |
| **HASTE_GEAR** (1/1024ths) | 150 (~14.6%) | 188 (~18.3%) | 225 (~22.0%) | 262 (~25.6%) | 300 (~29.3%) |
| **STR** (aura — buffs you too) | +15 | +18.75 | +22.5 | +26.25 | +30 |
| **DEX** (aura) | +15 | +18.75 | +22.5 | +26.25 | +30 |
| **VIT** (aura) | +15 | +18.75 | +22.5 | +26.25 | +30 |
<!-- DOCGEN:END id="pt-mob-scaling" -->

The three stat mods at the bottom act as **auras**: they buff both the Trust and any party member in range — so they stack on top of any STR/DEX/VIT you already have from gear and buffs.

## Power budget at a glance

If you'd rather skim than read the cells:

<!-- DOCGEN:BEGIN id="pt-power-budget" -->
| Tier | Quick Buff sum (7 stats / HP / MP) | Real Trust combined power |
|---|---:|---:|
| Bronze | +21 / +20 / +10 | baseline |
| Silver | +42 / +50 / +25 | ~1.6× Bronze |
| Gold | +70 / +100 / +50 | ~2.2× Bronze |
| Plat. | +98 / +150 / +75 | ~3.1× Bronze |
| Mythic | +140 / +250 / +125 | ~4.0× Bronze |
<!-- DOCGEN:END id="pt-power-budget" -->

The real-Trust path scales faster than its `trustMult` suggests because the multiplier compounds across HPP (more HP to start with), ATT (more damage per hit), Haste (more hits per second), and the aura stat stick — each one boosts the next.

## What's NOT scaled by the tier upgrade

Worth knowing what you're _not_ buying:

- **Job, AI, and spell repertoire.** The mob's job is locked to whichever underlying Trust got hijacked for that slot (slot 1 = GEO, slot 5 = BST, etc.). A Mythic Trust doesn't gain new spells — it casts the same spells harder.
- **AGI / INT / MND / CHR auras.** Only STR/DEX/VIT are in `trustBaseMods`. The mob's own stats still benefit from the per-tier multiplier on its base values, but those four don't project onto you as auras. If you want a mage-oriented Trust to push INT/MND onto the party, add lines to `trustBaseMods` in the catalog.
- **Friendship unlock state.** The original 30-min unlock work is a one-time event; tiers are a separate `PT_Tier_<id>` CharVar that starts at 1 (Bronze) on unlock.
- **Spell name in your book.** Engine-side limitation — the cast bar still says "Trust: Kuyin Hathdenna" even after Jbae is in that slot. Rename your macros to your friends' names; the floating nameplate above the spawned mob shows the friend correctly.

## Known limitations

- **Spell names in your book are fixed.** Engine doesn't expose per-cast spell renaming — the client looks display names up from its own DAT files. Workaround: rename your macros to your friends' names, and rely on the floating name above the mob (which IS the friend's name) for visual identification. With 5 slots assigned to 5 friends, the cast bar text becomes muscle memory anyway.
- **Face capture is recorded but not yet applied.** We store the friend's face number at unlock time (`PT_Face_<id>` CharVar) but `setModelId` uses race-based whole-body models. A future tweak could construct a full look hex via `setLook` to use the exact face — left for a future iteration.
- **Cross-zone unlock progress.** The 30-min counter requires both characters in the same zone every minute. Spreading the time across multiple zones doesn't accumulate.

## Tuning knobs

All in [`modules/custom/lua/player_trusts_catalog.lua`](https://github.com/richardknutzjr/FFXI-Private-Server-FJB/tree/main/):

- `unlockMinutes` — change the friendship threshold (default 30)
- `tickIntervalSec` — how often we re-check parties (default 60s)
- `tiers` — full table of tier bonuses, durations, and gil costs
- `npcPos` — where the Companion Master stands

Reload the module after editing — no server restart required.

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: fa8185e923d4 -->
_Last updated: 2026-06-21 03:39 UTC_
<!-- DOCGEN:END id="last-updated" -->
