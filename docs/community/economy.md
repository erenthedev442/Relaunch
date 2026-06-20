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
| Gil in circulation | **8.59B** gil |
| Players online now | **41** |
| Characters (non-GM) | 370 |
| Active in last 7 days | 369 |
| AH listings (live) | 28,994 |
| Cumulative playtime | 158 days, 21 hours |
<!-- DOCGEN:END id="econ-overview" -->

---

## Gil Supply

<!-- DOCGEN:BEGIN id="econ-gil" -->
Total gil held by player characters — the money supply. Gil sitting in Auction House escrow (unsold listings) and on GM characters is not counted.

| Measure | Value |
|---|---:|
| Total gil in circulation | 8,592,550,005 gil |
| Characters holding gil | 277 |
| Average per character | 31,020,036 gil |
| Median per character | 5,460,559 gil |
| Wealthiest 10% hold | 68.2% of all gil |
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
| Live listings (total) | 28,994 |
| — Market-maker (AH-Jeuno) | 28,926 |
| — Player-listed | 68 |
| Distinct items available | 5,805 |
| Total shelf value (asking) | 13,865,775,603 gil |
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
| Last 24 hours | 1,674 | 1,009,560,249 gil | 196,366,000 gil |
| Last 7 days | 4,777 | 2,174,649,925 gil | 889,146,000 gil |
| Last 30 days | 4,777 | 2,174,649,925 gil | 889,146,000 gil |
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
| 1 | Eyra Baghnakhs | 696 | 532,830,381 gil |
| 2 | Yataghan | 263 | 207,327,500 gil |
| 3 | Robur Mace | 189 | 149,600,000 gil |
| 4 | Gleaming Shield | 151 | 106,262,688 gil |
| 5 | Ash Staff | 115 | 16,100,000 gil |
| 6 | Revilers Helm | 114 | 54,180,520 gil |
| 7 | Jug Of Bug Broth | 80 | 20,736,000 gil |
| 8 | Chirich Ring +1 | 69 | 69,000,000 gil |
| 9 | Mache Earring +1 | 60 | 60,000,000 gil |
| 10 | Moonlight Cape | 43 | 43,000,000 gil |
| 11 | Copy Of Noilluries Log | 32 | 32,000 gil |
| 12 | Stikini Ring +1 | 31 | 31,000,000 gil |
| 13 | Cassie Earring | 30 | 4,200,000 gil |
| 14 | Onion Staff | 30 | 3,794,314 gil |
| 15 | Moonlight Ring | 29 | 29,000,000 gil |
<!-- DOCGEN:END id="econ-hot" -->

---

## Population

<!-- DOCGEN:BEGIN id="econ-population" -->
Who's around. **Active** counts characters that logged out within the window (a proxy for recent play); **new** counts characters created in the window.

| Measure | Value |
|---|---:|
| Online right now | 41 |
| Total characters | 370 |
| Active — last 7 days | 369 |
| Active — last 30 days | 370 |
| New — last 7 days | 369 |
| New — last 30 days | 370 |
| Cumulative playtime (all chars) | 158 days, 21 hours |
<!-- DOCGEN:END id="econ-population" -->

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: a38c07ae0c1b -->
_Last updated: 2026-06-20 03:55 UTC_
<!-- DOCGEN:END id="last-updated" -->
