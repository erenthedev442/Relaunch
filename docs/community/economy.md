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
| Gil in circulation | **22.12B** gil |
| Players online now | **44** |
| Characters (non-GM) | 410 |
| Active in last 7 days | 347 |
| AH listings (live) | 30,299 |
| Cumulative playtime | 245 days, 7 hours |
<!-- DOCGEN:END id="econ-overview" -->

---

## Gil Supply

<!-- DOCGEN:BEGIN id="econ-gil" -->
Total gil held by player characters — the money supply. Gil sitting in Auction House escrow (unsold listings) and on GM characters is not counted.

| Measure | Value |
|---|---:|
| Total gil in circulation | 22,119,983,597 gil |
| Characters holding gil | 317 |
| Average per character | 69,779,128 gil |
| Median per character | 7,027,310 gil |
| Wealthiest 10% hold | 73.0% of all gil |
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
| Live listings (total) | 30,299 |
| — Market-maker (AH-Jeuno) | 30,272 |
| — Player-listed | 27 |
| Distinct items available | 6,067 |
| Total shelf value (asking) | 14,198,373,254 gil |
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
| Last 24 hours | 1,063 | 561,133,710 gil | 206,680,000 gil |
| Last 7 days | 6,853 | 3,292,584,279 gil | 1,253,369,001 gil |
| Last 30 days | 7,574 | 3,511,107,517 gil | 1,463,589,001 gil |
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
| 1 | Eyra Baghnakhs | 813 | 626,430,381 gil |
| 2 | Gully | 710 | 454,400,000 gil |
| 3 | Yataghan | 265 | 208,927,500 gil |
| 4 | Gleaming Shield | 224 | 164,662,688 gil |
| 5 | Robur Mace | 189 | 149,600,000 gil |
| 6 | Revilers Helm | 143 | 72,740,520 gil |
| 7 | Ash Staff | 128 | 17,920,000 gil |
| 8 | Chirich Ring +1 | 88 | 88,000,000 gil |
| 9 | Mache Earring +1 | 85 | 85,000,000 gil |
| 10 | Jug Of Bug Broth | 85 | 22,036,000 gil |
| 11 | Bomb Arm | 74 | 9,940,900 gil |
| 12 | Moonlight Cape | 61 | 61,000,000 gil |
| 13 | Moonlight Ring | 47 | 47,000,000 gil |
| 14 | Stikini Ring +1 | 47 | 47,000,000 gil |
| 15 | Hermits Ring | 46 | 6,440,000 gil |
<!-- DOCGEN:END id="econ-hot" -->

---

## Population

<!-- DOCGEN:BEGIN id="econ-population" -->
Who's around. **Active** counts characters that logged out within the window (a proxy for recent play); **new** counts characters created in the window.

| Measure | Value |
|---|---:|
| Online right now | 44 |
| Total characters | 410 |
| Active — last 7 days | 347 |
| Active — last 30 days | 410 |
| New — last 7 days | 257 |
| New — last 30 days | 410 |
| Cumulative playtime (all chars) | 245 days, 7 hours |
<!-- DOCGEN:END id="econ-population" -->

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: c0ba4197c862 -->
_Last updated: 2026-06-22 20:59 UTC_
<!-- DOCGEN:END id="last-updated" -->
