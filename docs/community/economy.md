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
| Gil in circulation | **14.68B** gil |
| Players online now | **2** |
| Characters (non-GM) | 403 |
| Active in last 7 days | 380 |
| AH listings (live) | 29,988 |
| Cumulative playtime | 217 days, 8 hours |
<!-- DOCGEN:END id="econ-overview" -->

---

## Gil Supply

<!-- DOCGEN:BEGIN id="econ-gil" -->
Total gil held by player characters — the money supply. Gil sitting in Auction House escrow (unsold listings) and on GM characters is not counted.

| Measure | Value |
|---|---:|
| Total gil in circulation | 14,682,746,013 gil |
| Characters holding gil | 310 |
| Average per character | 47,363,696 gil |
| Median per character | 6,801,929 gil |
| Wealthiest 10% hold | 66.7% of all gil |
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
| Live listings (total) | 29,988 |
| — Market-maker (AH-Jeuno) | 29,970 |
| — Player-listed | 18 |
| Distinct items available | 6,065 |
| Total shelf value (asking) | 14,049,711,062 gil |
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
| Last 24 hours | 618 | 223,349,234 gil | 153,670,000 gil |
| Last 7 days | 6,092 | 2,813,598,395 gil | 1,112,079,001 gil |
| Last 30 days | 6,619 | 2,985,472,397 gil | 1,276,879,001 gil |
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
| 2 | Gully | 320 | 204,800,000 gil |
| 3 | Yataghan | 265 | 208,927,500 gil |
| 4 | Robur Mace | 189 | 149,600,000 gil |
| 5 | Gleaming Shield | 162 | 115,062,688 gil |
| 6 | Revilers Helm | 134 | 66,980,520 gil |
| 7 | Ash Staff | 128 | 17,920,000 gil |
| 8 | Jug Of Bug Broth | 85 | 22,036,000 gil |
| 9 | Chirich Ring +1 | 80 | 80,000,000 gil |
| 10 | Mache Earring +1 | 79 | 79,000,000 gil |
| 11 | Bomb Arm | 67 | 8,960,900 gil |
| 12 | Moonlight Cape | 57 | 57,000,000 gil |
| 13 | Moonlight Ring | 44 | 44,000,000 gil |
| 14 | Hope Earring +1 | 42 | 5,940,000 gil |
| 15 | Stikini Ring +1 | 41 | 41,000,000 gil |
<!-- DOCGEN:END id="econ-hot" -->

---

## Population

<!-- DOCGEN:BEGIN id="econ-population" -->
Who's around. **Active** counts characters that logged out within the window (a proxy for recent play); **new** counts characters created in the window.

| Measure | Value |
|---|---:|
| Online right now | 2 |
| Total characters | 403 |
| Active — last 7 days | 380 |
| Active — last 30 days | 403 |
| New — last 7 days | 302 |
| New — last 30 days | 403 |
| Cumulative playtime (all chars) | 217 days, 8 hours |
<!-- DOCGEN:END id="econ-population" -->

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 509d1014da9a -->
_Last updated: 2026-06-22 05:55 UTC_
<!-- DOCGEN:END id="last-updated" -->
