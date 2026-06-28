# Server Status

the server's current state at a glance. Stats update daily via the auto-generation pipeline.

---

## Server Info

| Field | Value |
|---|---|
| **IP Address** | `69.130.180.41` |
| **Port** | `54230` |
| **Timezone** | PST (UTC-7) |

---

## Who's Online

<!-- DOCGEN:BEGIN id="status-online" -->
**1** online · **417** characters · _snapshot from the last site rebuild — the header badge shows live status._
<!-- DOCGEN:END id="status-online" -->

---

## HNM Tracker

Timed HNMs rotate on persistent windows that survive server restarts. This tracker shows each one's respawn window and whether it was up as of the last site rebuild.

<!-- DOCGEN:BEGIN id="status-hnm" -->
_Snapshot taken at build time — timers drift after that. For live status, check in-game or the Discord HNM feed._

| NM | Zone | Respawn window | Status (snapshot) |
|---|---|---:|---|
| **Adamantoise** | Valley of Sorrows | 21–24 h | 🟠 pops in ~15m |
| **Simurgh** | Rolanberry Fields | 6–8 h | 🟠 pops in ~44m |
| **Serket** | Garlaige Citadel | 6–8 h | 🟠 pops in ~1h 24m |
| **Roc** | Sauromugue Champaign | 6–8 h | 🟠 pops in ~2h 3m |
| **Behemoth** | Behemoth's Dominion | 21–24 h | 🟠 pops in ~19h 29m |
| **Fafnir** | Dragon's Aery | 21–24 h | 🟠 pops in ~19h 31m |
| **Spiny Spipi** | East Sarutabaruta | 4–6 h | ⚪ awaiting first spawn |
| **King Arthro** | Jugner Forest | 8–10 h | ⚪ awaiting first spawn |
<!-- DOCGEN:END id="status-hnm" -->

!!! note "HQ Land Kings are on-demand"
    **Nidhogg**, **Aspidochelone**, and **King Behemoth** aren't on a timer — you pop them by trading the right item to the zone's `???` while neither the NQ nor the HQ is up. See [HNM Kings](../progression/hnm.md) for the trade items.

!!! tip "Want live status?"
    This page is a build-time snapshot. For real-time spawns, watch the HNM feed in **Discord** (the notifier posts the moment a King wakes up) or check in-game.

---

## Background Jobs

the Relaunch server runs several unattended jobs — the Auction House market-maker, the two Discord bots, and the nightly database backup. Each writes a heartbeat on every successful pass, and this panel flags any that have gone quiet so a silently-dead task gets noticed.

<!-- DOCGEN:BEGIN id="status-jobs" -->
_Health snapshot from the last site rebuild._ 🟢 OK · 🟠 last run reported errors · 🔴 STALE (may be down) · ⚪ no signal yet.

| Background job | Schedule | Last run | Status (snapshot) |
|---|---|---:|---|
| **Auction House market-maker** | every 15 min | 8d 15h ago | 🔴 **STALE** — no run in 8d 15h |
| **Discord notifier (webhook)** | every 5 min | — | ⚪ no signal yet |
| **Discord bot (slash commands)** | daemon · 5 min beat | — | ⚪ no signal yet |
| **Database backup + verify** | nightly 04:00 | 22d 22h ago | 🔴 **STALE** — no run in 22d 22h |
<!-- DOCGEN:END id="status-jobs" -->

---

## This Week's Featured Hunt

Each week a single NM per Hunting League tier is designated as the Featured Hunt. The first kill of that NM during the ISO week awards **2× Hunt Marks** on top of the normal reward — a meaningful bonus for players who coordinate around it.

The Featured Hunt rotates automatically at the start of each ISO week (Monday 00:00 UTC). To see which NMs are currently featured, use the in-game command:

```
!featured
```

!!! tip "First-Kill Bonus"
    The 2× marks apply to the **first kill only** per week. After that, the NM still drops normal marks — it never goes dry. Clear it early for the bonus, then keep farming.

---

## Active Events

Seasonal **bonus-mark events** multiply the Hunt Marks you earn from kills for a limited window. Only one applies at a time — if two overlap, the higher-priority one wins. For the live bonus, use `!events` in-game.

<!-- DOCGEN:BEGIN id="status-events" -->
_No bonus-mark events are active or scheduled right now. Watch **#announcements** on Discord for the next one._
<!-- DOCGEN:END id="status-events" -->

!!! info "Event Announcements"
    Seasonal events — including double-marks weekends and holiday content — are announced in the **#announcements** channel on Discord before going live. Keep an eye there for upcoming events.

---

## Lifetime Records

Server firsts are tracked in the Hall of Fame.

| Achievement | Holder | Date |
|---|---|---|
| *First Rank V (Legend)* | — | — |
| *First Eternal Throne Mythic Clear* | — | — |
| *First Reforge +3 Full Set* | — | — |
| *First Shinryu Kill* | — | — |

See the full list at [Hall of Fame](highlights.md).

---

## Quick Links

- [Discord](https://discord.gg/the Relaunch server-ffxi) — announcements, #help, #suggestions
- [Getting Started](../getting-started/index.md) — new player guide
- [Hall of Fame](highlights.md) — server firsts and records
- [Leaderboards](leaderboards.md) — live rankings

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 5e67c64612a4 -->
_Last updated: 2026-06-23 10:43 UTC_
<!-- DOCGEN:END id="last-updated" -->
