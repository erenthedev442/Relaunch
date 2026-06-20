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
| Gil in circulation | **6.49B** gil |
| Players online now | **0** |
| Characters (non-GM) | 360 |
| Active in last 7 days | 359 |
| AH listings (live) | 28,963 |
| Cumulative playtime | 145 days, 2 hours |
<!-- DOCGEN:END id="econ-overview" -->

---

## Gil Supply

<!-- DOCGEN:BEGIN id="econ-gil" -->
Total gil held by player characters — the money supply. Gil sitting in Auction House escrow (unsold listings) and on GM characters is not counted.

| Measure | Value |
|---|---:|
| Total gil in circulation | 6,490,169,596 gil |
| Characters holding gil | 270 |
| Average per character | 24,037,665 gil |
| Median per character | 5,357,198 gil |
| Wealthiest 10% hold | 64.9% of all gil |
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
| Live listings (total) | 28,963 |
| — Market-maker (AH-Jeuno) | 28,925 |
| — Player-listed | 38 |
| Distinct items available | 5,800 |
| Total shelf value (asking) | 13,855,421,820 gil |
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
| Last 24 hours | 1,026 | 619,069,605 gil | 71,040,000 gil |
| Last 7 days | 4,126 | 1,782,879,281 gil | 762,540,000 gil |
| Last 30 days | 4,126 | 1,782,879,281 gil | 762,540,000 gil |
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
| 1 | Eyra Baghnakhs | 546 | 413,170,780 gil |
| 2 | Yataghan | 227 | 178,527,500 gil |
| 3 | Robur Mace | 141 | 112,800,000 gil |
| 4 | Ash Staff | 115 | 16,100,000 gil |
| 5 | Revilers Helm | 98 | 43,940,520 gil |
| 6 | Jug Of Bug Broth | 80 | 20,736,000 gil |
| 7 | Gleaming Shield | 67 | 52,802,610 gil |
| 8 | Chirich Ring +1 | 59 | 59,000,000 gil |
| 9 | Mache Earring +1 | 49 | 49,000,000 gil |
| 10 | Moonlight Cape | 37 | 37,000,000 gil |
| 11 | Onion Staff | 29 | 3,654,314 gil |
| 12 | Hi-Potion | 28 | 10,491 gil |
| 13 | Cassie Earring | 26 | 3,640,000 gil |
| 14 | Moonlight Ring | 25 | 25,000,000 gil |
| 15 | Bronze Sword | 25 | 2,993,570 gil |
<!-- DOCGEN:END id="econ-hot" -->

---

## Population

<!-- DOCGEN:BEGIN id="econ-population" -->
Who's around. **Active** counts characters that logged out within the window (a proxy for recent play); **new** counts characters created in the window.

| Measure | Value |
|---|---:|
| Online right now | 0 |
| Total characters | 360 |
| Active — last 7 days | 359 |
| Active — last 30 days | 360 |
| New — last 7 days | 359 |
| New — last 30 days | 360 |
| Cumulative playtime (all chars) | 145 days, 2 hours |
<!-- DOCGEN:END id="econ-population" -->

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 3ce57361350e -->
_Last updated: 2026-06-20 03:17 UTC_
<!-- DOCGEN:END id="last-updated" -->
