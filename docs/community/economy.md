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
| Gil in circulation | **19.79B** gil |
| Players online now | **36** |
| Characters (non-GM) | 404 |
| Active in last 7 days | 381 |
| AH listings (live) | 30,293 |
| Cumulative playtime | 225 days, 20 hours |
<!-- DOCGEN:END id="econ-overview" -->

---

## Gil Supply

<!-- DOCGEN:BEGIN id="econ-gil" -->
Total gil held by player characters — the money supply. Gil sitting in Auction House escrow (unsold listings) and on GM characters is not counted.

| Measure | Value |
|---|---:|
| Total gil in circulation | 19,788,293,787 gil |
| Characters holding gil | 311 |
| Average per character | 63,627,954 gil |
| Median per character | 6,964,868 gil |
| Wealthiest 10% hold | 72.8% of all gil |
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
| Live listings (total) | 30,293 |
| — Market-maker (AH-Jeuno) | 30,272 |
| — Player-listed | 21 |
| Distinct items available | 6,068 |
| Total shelf value (asking) | 14,192,813,662 gil |
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
| Last 24 hours | 900 | 393,137,426 gil | 193,380,000 gil |
| Last 7 days | 6,406 | 2,994,800,165 gil | 1,156,179,001 gil |
| Last 30 days | 6,941 | 3,166,900,901 gil | 1,321,149,001 gil |
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
| 2 | Gully | 480 | 307,200,000 gil |
| 3 | Yataghan | 265 | 208,927,500 gil |
| 4 | Gleaming Shield | 197 | 143,062,688 gil |
| 5 | Robur Mace | 189 | 149,600,000 gil |
| 6 | Revilers Helm | 134 | 66,980,520 gil |
| 7 | Ash Staff | 128 | 17,920,000 gil |
| 8 | Jug Of Bug Broth | 85 | 22,036,000 gil |
| 9 | Chirich Ring +1 | 84 | 84,000,000 gil |
| 10 | Mache Earring +1 | 82 | 82,000,000 gil |
| 11 | Bomb Arm | 67 | 8,960,900 gil |
| 12 | Moonlight Cape | 57 | 57,000,000 gil |
| 13 | Moonlight Ring | 45 | 45,000,000 gil |
| 14 | Hermits Ring | 45 | 6,300,000 gil |
| 15 | Hope Earring +1 | 42 | 5,940,000 gil |
<!-- DOCGEN:END id="econ-hot" -->

---

## Population

<!-- DOCGEN:BEGIN id="econ-population" -->
Who's around. **Active** counts characters that logged out within the window (a proxy for recent play); **new** counts characters created in the window.

| Measure | Value |
|---|---:|
| Online right now | 36 |
| Total characters | 404 |
| Active — last 7 days | 381 |
| Active — last 30 days | 404 |
| New — last 7 days | 303 |
| New — last 30 days | 404 |
| Cumulative playtime (all chars) | 225 days, 20 hours |
<!-- DOCGEN:END id="econ-population" -->

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: fb1e3b6defc5 -->
_Last updated: 2026-06-22 06:18 UTC_
<!-- DOCGEN:END id="last-updated" -->
