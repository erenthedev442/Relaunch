# Quality of Life Features

the Relaunch server ships with a set of quality-of-life improvements that aren't always obvious when you first log in. This page documents all of them so you don't spend hours discovering what's already there.

---

## Always-Popped NMs

Every named monster (NM) in **Reisenjima** and the **Reisenjima Sanctorium** (2 zones) is permanently spawned with a 30-second respawn timer. (Abyssea NMs are popped on demand by spending Hunt Marks at the zone `???` — see [Abyssea NMs](../endgame/abyssea-nms.md) — and Escha - Zi'Tah is the Hunting League hub.)

There is no camping. There is no waiting on a lottery pop. Walk in, kill it, walk back in 30 seconds.

!!! tip "Why does this matter?"
    On retail and most private servers, rare NMs have multi-hour windows, lottery pops, or ToD camps. on the Relaunch server you can chain kills continuously — making skill-ups, drops, and marks farming dramatically faster.

!!! note "Escha ZiTah is excluded"
    The Hunting League spawner at Escha ZiTah uses a separate on-demand pop system by design. Those NMs are managed through the Hunt Spawner NPC (`!hunt` to warp there).

---

## Character Upgrader (Automatic)

There is no setup NPC to visit. Every new character is fully provisioned **automatically on first login** — no interaction required.

What is granted automatically:

- All weapon skills unlocked
- All spells learned (job-appropriate)
- All skills capped to your level
- All Trusts activated
- All quests marked completed
- All maps acquired
- All Outpost Warps and conquest points
- All Homepoints and Survival Guides registered
- Maximum Wardrobe slots unlocked

---

## Homepoint Healing

Touching any **Homepoint** crystal instantly restores your HP and MP to full. No items needed, no resting, no wait.

This applies to every homepoint in every zone. Use them freely as rest stops while farming.

---

## Mystery Mog (Gil Gacha)

Located in the **Purgonorgo Isle** (`!hub`).

The Mystery Mog is a weighted gacha that converts excess gil into random rewards — standard and premium pull tiers, with prizes ranging from cure items up to Hunt Mark jackpots and Ascension Points. For live pull costs, the full prize pool, and exact drop odds, see [Mystery Mog](gm-home.md#mystery-mog).

!!! info "This is a gil sink, not a farming path"
    The Mystery Mog is not designed to replace NM farming. It exists as a fun outlet for gil you're sitting on. Expect to lose value most pulls — that's the point.

---

## Gil to Marks Exchange

The **Gil Exchange NPC** in the **Purgonorgo Isle** (`!hub`) converts raw gil into Hunt Marks in bulk bundles:

<!-- DOCGEN:BEGIN id="server-features-gil-exchange" -->
| Gil | Hunt Marks |
|---:|---:|
| 2,000,000 | 5 |
| 40,000,000 | 100 |
| 200,000,000 | 500 |
<!-- DOCGEN:END id="server-features-gil-exchange" -->

Bundle rates give modest discounts for larger purchases. This system is intentionally slow — a last resort for players sitting on large gil stacks, not a primary farming path. NM kills will always be faster.

---

## Title Broker

The **Title Broker NPC** in the **Purgonorgo Isle** (`!hub`) sells cosmetic titles for gil across several price tiers, from cheap flavor titles up to rare endgame trophies. For the full tier pricing and the complete title list, see [GM Home → Title Broker](gm-home.md#title-broker).

These are display titles — any player can buy any title regardless of whether they've earned it through gameplay.

---

## Always Stocked Auction House

See the full **[Auction House page](../economy/auction-house.md)** for everything the market maker does. In short: the Auction House is permanently stocked with **every piece of non-iLevel equipment in the game** — weapons, armor, and accessories. You will never find an empty category while leveling a job.

Type `!ah` from anywhere to open the Auction House menu. You don't need to travel to Jeuno, Bastok, or any other AH counter.

**Prices scale by the item's equip level:**

<!-- DOCGEN:BEGIN id="ah-prices" -->
| Equip Level | Price |
|---|---|
| 1–10 | 14,000 gil |
| 11–20 | 17,000 gil |
| 21–30 | 21,000 gil |
| 31–40 | 26,000 gil |
| 41–50 | 33,000 gil |
| 51–60 | 41,000 gil |
| 61–70 | 51,000 gil |
| 71–75 | 64,000 gil |
| 76–90 | 80,000 gil |
<!-- DOCGEN:END id="ah-prices" -->

### Guaranteed Buy-Back

The same system also **buys this gear back** from you at the exact price in the table above. List a piece of non-iLevel gear at or below its table price and the server purchases it, paying you in full through your delivery box — even if you asked for less than the table price.

This gives every leveling piece a guaranteed gil floor: you can always sell it back for what it's worth, so there's no risk in buying gear to try out a new job. Buy-backs are processed on the market maker's hourly pass, so payment may not be instant.

!!! note "Endgame iLevel gear is not included"
    Item-level 119 endgame gear is handled separately by the [Gear Vendors](gear-vendors.md), not the Auction House. This system covers the classic level 1–99 equipment you use while leveling.

---

## Auto-Unstick Watchdog

If you get stuck in an NPC dialogue, event sequence, or cutscene lock:

```
!unstick
```

This command self-rescues you from any frozen state. The server also runs an automatic watchdog that detects and resolves stuck states without player input — so even if you log out mid-event, the server cleans up on your behalf.

---

## Subjob EXP Share

Your subjob gains **0.25× (25%) EXP** automatically as you gain EXP on your main job. You never need to grind a subjob separately.

Banked EXP is per-subjob: if you switch subjobs, the new sub's bank starts fresh — accumulated EXP does **not** carry over.

For full details, see [Subjob EXP Share](subjob-exp.md).

---

## The !buff Command

Type `!buff` anywhere to instantly receive:

- The appropriate regional buff for your current zone (Signet, Sanction, Sigil, or Ionis)
- **Refresh** — restores 10% of your max MP per tick
- **Regen** — restores 10% of your max HP per tick
- **Regain** — TP regeneration that scales with your level
- **Composure** — boosts your accuracy and makes your self-cast enhancing magic last longer

No NPC visit required. Use it whenever the buffs drop.

!!! tip
    `!buff` is especially useful right after zoning or logging in, when your regional buff hasn't been applied yet.

---

## World First & Login Announcements

The server broadcasts a server-wide message when:

- Any NM is killed for the **first time** on the server (World First)
- Any job reaches a significant **level milestone**
- A player **logs in** — so you always know who's online

First Blood moments are real on the Relaunch server. If you're the first person to kill Absolute Virtue or land a server-first NM kill, the whole server sees it.

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 135415054a39 -->
_Last updated: 2026-07-11 21:16 PDT_
<!-- DOCGEN:END id="last-updated" -->
