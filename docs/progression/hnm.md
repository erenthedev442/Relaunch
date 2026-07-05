# HNM Kings

![King's crown](../assets/emblems/hnm.svg){ .lgnd-emblem }

the Relaunch server runs a custom **HNM pop system** that keeps the classic Kings — plus a roster of lower-tier HNMs — available without the era-style waiting and placeholder camping that made retail painful.

---

## The Land Kings

<!-- DOCGEN:BEGIN id="hnm-kings" -->
| Zone | NQ King | HQ King | HQ pop item | Respawn window |
|---|---|---|---|---|
| Dragon's Aery | **Fafnir** | **Nidhogg** | <a class="item-link" href="https://www.ffxiah.com/item/3340" data-img="https://static.ffxiah.com/images/icon/3340.png" target="_blank" rel="noopener">Cup of Sweet Tea</a> | 21–24 h |
| Valley of Sorrows | **Adamantoise** | **Aspidochelone** | <a class="item-link" href="https://www.ffxiah.com/item/3344" data-img="https://static.ffxiah.com/images/icon/3344.png" target="_blank" rel="noopener">Clump of Red Pondweed</a> | 21–24 h |
| Behemoth's Dominion | **Behemoth** | **King Behemoth** | <a class="item-link" href="https://www.ffxiah.com/item/3342" data-img="https://static.ffxiah.com/images/icon/3342.png" target="_blank" rel="noopener">Savory Shank</a> | 21–24 h |
<!-- DOCGEN:END id="hnm-kings" -->

!!! note "Nidhogg and King Behemoth in the Hunting League"
    Nidhogg and King Behemoth also appear as **Rank IV Hunting League targets** (38 Hunt Marks per kill). Killing them for the Hunting League and for HNM loot happens at the same time — one kill counts for both.

---

## Lower-Tier HNMs

<!-- DOCGEN:BEGIN id="hnm-lower" -->
| NM | Zone | Respawn window |
|---|---|---|
| **Spiny Spipi** | East Sarutabaruta | 4–6 h |
| **Roc** | Sauromugue Champaign | 6–8 h |
| **Serket** | Garlaige Citadel | 6–8 h |
| **Simurgh** | Rolanberry Fields | 6–8 h |
| **King Arthro** | Jugner Forest | 8–10 h |
<!-- DOCGEN:END id="hnm-lower" -->

---

## How the Pop System Works

the Relaunch server uses a **hybrid timed/QM system** rather than pure lottery windows or pure placeholder camping:

- **NQ kings** (the timed column above) rotate on a persistent window. The respawn clock is saved to disk via ServerVar — a crash or restart doesn't reset it.
- **HQ kings** are popped on demand: trade the listed item to the zone's `???` while **neither** the NQ nor the HQ is currently up.
- **Lower-tier HNMs** are timed-only, on shorter windows.

Exact respawn windows live in the tables above — they're generated straight from the server's HNM module, so they're always current.

In practice: check the zone. If the NM is up, fight it. If it's not, it'll be back within its window.

---

## Checking What's Up

To see which HNMs are currently spawned, check the [Player Commands reference](../reference/commands.md) for any live-status command (such as `!reforged` or a dedicated HNM status command). The command list is the authoritative source — HNM tracking commands may be updated as the system evolves.

You can also just ask in **Discord** — someone usually knows.

---

## World-First Kill Tracking

The first time any HNM is killed on the server, a broadcast goes out to everyone online. Kill achievements are stored permanently, so the world-first attribution survives restarts.

If you're in the running for a world-first king kill, move fast — once it's gone, it's gone.

---

## Loot

HNM loot is standard retail drop tables at the server's global **3× drop rate multiplier**. You're not getting anything that didn't exist on retail, but you're significantly more likely to see it.

Notable drops by target:

| NM | Notable loot |
|---|---|
| Fafnir / Nidhogg | Ridill, Defending Ring, Wyvern Scales |
| Behemoth / King Behemoth | Behemoth Tongue, Gaiters, Behemoth Hide |
| Aspidochelone / Adamantoise | Damascene Cloth, Life Belt, Wyrm Beard |

---

## Tips

!!! warning "Don't solo these"
    The Kings are genuinely difficult. Bring at least one other player — a party is strongly recommended. Even with this server's boosted player power (2× WS damage, 2× cure, 6 Blink shadows), a King can wipe a solo player who isn't geared for it.

- **Check the zone first.** Walk in, look around. If it's up, engage. If not, set a timer and come back.
- **Nidhogg and King Behemoth count for Hunting League Rank IV credit** — you're efficiently grinding two systems at once.
- **HQ kings are harder than NQ kings** and have better loot. Plan accordingly.
- **World-first kills get announced.** If you want credit, make sure you're in the zone when it dies.

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 57259a29c678 -->
_Last updated: 2026-07-05 07:37 UTC_
<!-- DOCGEN:END id="last-updated" -->
