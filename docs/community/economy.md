# Server Economy

A live, anonymous snapshot of Legendary's economy and population — how much
gil is in circulation, how busy the Auction House is, and how many hunters
are around.

!!! info "How fresh is this?"
    These figures are a **build-time snapshot**, refreshed every time the
    site is rebuilt — not a live ticker. For the real-time online count,
    watch the status badge in the site header or ask in Discord. No
    individual player is named here; this is a macro view, and GM / test
    characters are excluded so the numbers reflect the real player economy.

## At a Glance

<!-- DOCGEN:BEGIN id="econ-overview" -->
A live snapshot of the server economy and population. All figures exclude GM / test characters and refresh each time the site is rebuilt.

| Metric | Value |
|---|---:|
| Gil in circulation | **11.99B** gil |
| Players online now | **1** |
| Characters (non-GM) | 384 |
| Active in last 7 days | 374 |
| AH listings (live) | 898 |
| Cumulative playtime | 186 days, 1 hour |
<!-- DOCGEN:END id="econ-overview" -->

---

## Gil Supply

<!-- DOCGEN:BEGIN id="econ-gil" -->
Total gil held by player characters — the money supply. Gil sitting in Auction House escrow (unsold listings) and on GM characters is not counted.

| Measure | Value |
|---|---:|
| Total gil in circulation | 11,985,014,115 gil |
| Characters holding gil | 290 |
| Average per character | 41,327,634 gil |
| Median per character | 6,696,420 gil |
| Wealthiest 10% hold | 71.3% of all gil |
<!-- DOCGEN:END id="econ-gil" -->

The gap between the **average** and the **median** is the inequality signal:
when the average sits far above the median, a handful of wealthy hunters are
pulling the mean up while most players hold far less.

---

## Auction House Depth

<!-- DOCGEN:BEGIN id="econ-ah" -->
Open Auction House listings right now. The market-maker (an NPC seller, **AH-Jeuno**) keeps a price floor and a deep catalog of gear on the shelf; player listings are everything posted by real characters.

| Measure | Value |
|---|---:|
| Live listings (total) | 898 |
| — Market-maker (AH-Jeuno) | 889 |
| — Player-listed | 9 |
| Distinct items available | 550 |
| Total shelf value (asking) | 426,495,990 gil |
<!-- DOCGEN:END id="econ-ah" -->

The market-maker exists to keep gear **available** and to set a **price
floor** so player listings can't be undercut into the ground. It's a one-way
shelf: players buy from it, which steadily drains gil out of the economy.

---

## Market Velocity

<!-- DOCGEN:BEGIN id="econ-velocity" -->
Completed Auction House sales over recent windows. **Gil volume** is the total that changed hands; **gil sunk** is the portion spent buying from the market-maker, which removes that gil from the economy for good.

| Window | Lots sold | Gil volume | Gil sunk to AH |
|---|---:|---:|---:|
| Last 24 hours | 1,006 | 477,491,634 gil | 181,940,001 gil |
| Last 7 days | 5,661 | 2,594,931,559 gil | 1,014,156,001 gil |
| Last 30 days | 5,783 | 2,652,141,559 gil | 1,071,086,001 gil |
<!-- DOCGEN:END id="econ-velocity" -->

A healthy economy needs **gil sinks** — ways for gil to leave circulation so
prices stay meaningful. Every purchase from the market-maker is a sink, which
is why we track it separately from player-to-player volume.

---

## Hot Items (Last 30 Days)

<!-- DOCGEN:BEGIN id="econ-hot" -->
The most actively traded items on the Auction House over the last 30 days, by number of lots sold.

| # | Item | Lots sold | Gil volume |
|---:|---|---:|---:|
| 1 | Eyra Baghnakhs | 797 | 613,630,381 gil |
| 2 | Yataghan | 265 | 208,927,500 gil |
| 3 | Gully | 240 | 153,600,000 gil |
| 4 | Robur Mace | 189 | 149,600,000 gil |
| 5 | Gleaming Shield | 151 | 106,262,688 gil |
| 6 | Ash Staff | 128 | 17,920,000 gil |
| 7 | Revilers Helm | 124 | 60,580,520 gil |
| 8 | Jug Of Bug Broth | 85 | 22,036,000 gil |
| 9 | Chirich Ring +1 | 74 | 74,000,000 gil |
| 10 | Mache Earring +1 | 69 | 69,000,000 gil |
| 11 | Moonlight Cape | 50 | 50,000,000 gil |
| 12 | Bomb Arm | 42 | 5,460,900 gil |
| 13 | Moonlight Ring | 35 | 35,000,000 gil |
| 14 | Stikini Ring +1 | 33 | 33,000,000 gil |
| 15 | Cassie Earring | 32 | 4,480,000 gil |
<!-- DOCGEN:END id="econ-hot" -->

---

## Population

<!-- DOCGEN:BEGIN id="econ-population" -->
Who's around. **Active** counts characters that logged out within the window (a proxy for recent play); **new** counts characters created in the window.

| Measure | Value |
|---|---:|
| Online right now | 1 |
| Total characters | 384 |
| Active — last 7 days | 374 |
| Active — last 30 days | 384 |
| New — last 7 days | 341 |
| New — last 30 days | 384 |
| Cumulative playtime (all chars) | 186 days, 1 hour |
<!-- DOCGEN:END id="econ-population" -->

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: acc25252552f -->
_Last updated: 2026-06-21 03:39 UTC_
<!-- DOCGEN:END id="last-updated" -->
