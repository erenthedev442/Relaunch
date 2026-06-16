# Quality of Life Features

Legendary ships with a set of quality-of-life improvements that aren't always obvious when you first log in. This page documents all of them so you don't spend hours discovering what's already there.

---

## Always-Popped NMs

Every named monster (NM) in **Abyssea** (10 zones), **Escha-Ru'Aun**, and **Reisenjima / Sanctorium** (2 zones) is permanently spawned with a 30-second respawn timer.

There is no camping. There is no waiting on a lottery pop. Walk in, kill it, walk back in 30 seconds.

!!! tip "Why does this matter?"
    On retail and most private servers, rare NMs have multi-hour windows, lottery pops, or ToD camps. On Legendary you can chain kills continuously — making skill-ups, drops, and marks farming dramatically faster.

!!! note "Escha - Zi'Tah and Reisenjima Henge excluded"
    Both zones are Hunting League hubs that use on-demand Spawner NPCs instead. Type `!hunt` to warp to the hub, then use the Zone Guide to reach a tier's hunting area.

---

## Character Upgrader NPC

Located in **GM Home** — type `!gmhome` from anywhere to get there.

The Character Upgrader offers individual options or a single **"Give Me Everything"** option that chains all upgrades at once. One confirmation click and you're done.

What it grants:

- All weapon skills unlocked
- All spells learned (job-appropriate)
- All skills capped to your level
- All Trusts activated
- All quests marked completed
- All maps acquired
- All Outpost Warps and conquest points
- All Homepoints and Survival Guides registered
- Maximum Wardrobe slots unlocked

!!! tip
    New characters should hit "Give Me Everything" first. It saves hours of setup grinding and lets you focus on the content that actually matters.

Confirmation menus are shown before applying anything — accidental upgrades are not possible.

---

## Homepoint Healing

Touching any **Homepoint** crystal instantly restores your HP and MP to full. No items needed, no resting, no wait.

This applies to every homepoint in every zone. Use them freely as rest stops while farming.

---

## Records of Eminence

The standard city RoE NPCs found in Bastok, San d'Oria, Windurst, and Jeuno have been removed. To set objectives and collect RoE rewards, speak with the **Eternal Flame** NPC in **Western Adoulin at H-11**.

---

## Mystery Mog (Gil Gacha)

Located in **GM Home** next to the other NPCs.

The Mystery Mog is a weighted gacha that converts excess gil into random rewards — standard and premium pull tiers, with prizes ranging from cure items up to Hunt Mark jackpots and Ascension Points. For live pull costs, the full prize pool, and exact drop odds, see [GM Home → Mystery Mog](gm-home.md#mystery-mog).

!!! info "This is a gil sink, not a farming path"
    The Mystery Mog is not designed to replace NM farming. It exists as a fun outlet for gil you're sitting on. Expect to lose value most pulls — that's the point.

---

## Gil to Marks Exchange

The **Gil Exchange NPC** in GM Home converts raw gil into Hunt Marks in bulk bundles:

<!-- DOCGEN:BEGIN id="server-features-gil-exchange" -->
| Gil | Hunt Marks |
|---:|---:|
| 100,000 | 1 |
| 1,000,000 | 12 |
| 10,000,000 | 150 |
<!-- DOCGEN:END id="server-features-gil-exchange" -->

Bundle rates give modest discounts for larger purchases. This system is intentionally slow — a last resort for players sitting on large gil stacks, not a primary farming path. NM kills will always be faster.

---

## Title Broker

The **Title Broker NPC** in GM Home sells cosmetic titles for gil across several price tiers, from cheap flavor titles up to rare endgame trophies. For the full tier pricing and the complete title list, see [GM Home → Title Broker](gm-home.md#title-broker).

These are display titles — any player can buy any title regardless of whether they've earned it through gameplay.

---

## Always Stocked Auction House

The Auction House is permanently stocked with **every piece of non-iLevel equipment in the game** — weapons, armor, and accessories. You will never find an empty category while leveling a job.

Type `!ah` from anywhere to open the Auction House menu. You don't need to travel to Jeuno, Bastok, or any other AH counter.

**Prices scale by the item's equip level:**

<!-- DOCGEN:BEGIN id="ah-prices" -->
| Equip Level | Price |
|---|---|
| 1–10 | 140,000 gil |
| 11–20 | 170,000 gil |
| 21–30 | 210,000 gil |
| 31–40 | 260,000 gil |
| 41–50 | 330,000 gil |
| 51–60 | 410,000 gil |
| 61–70 | 510,000 gil |
| 71–75 | 640,000 gil |
| 76–98 | 800,000 gil |
| 99 | 1,000,000 gil |
<!-- DOCGEN:END id="ah-prices" -->

### Guaranteed Buy-Back

The same system also **buys this gear back** from you at the exact price in the table above. List a piece of non-iLevel gear at or below its table price and the server purchases it, paying you in full through your delivery box — even if you asked for less than the table price.

This gives every leveling piece a guaranteed gil floor: you can always sell it back for what it's worth, so there's no risk in buying gear to try out a new job. Buy-backs are processed in batches every few minutes, so payment may not be instant.

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

Your subjob gains **0.5× EXP** automatically as you gain EXP on your main job. You never need to grind a subjob separately.

EXP banks across subjob swaps. If you switch subjobs, accumulated EXP carries over to the new one.

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

First Blood moments are real on Legendary. If you're the first person to kill Absolute Virtue or clear a Mythic dungeon, the whole server sees it.

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 7b043bcd19b7 -->
_Last updated: 2026-06-15 21:00 UTC_
<!-- DOCGEN:END id="last-updated" -->
