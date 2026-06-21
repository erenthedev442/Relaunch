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
| Gil in circulation | **12.72B** gil |
| Players online now | **31** |
| Characters (non-GM) | 386 |
| Active in last 7 days | 375 |
| AH listings (live) | 28,938 |
| Cumulative playtime | 191 days, 10 hours |
<!-- DOCGEN:END id="econ-overview" -->

---

## Gil Supply

<!-- DOCGEN:BEGIN id="econ-gil" -->
Total gil held by player characters — the money supply. Gil sitting in Auction House escrow (unsold listings) and on GM characters is not counted.

| Measure | Value |
|---|---:|
| Total gil in circulation | 12,716,837,299 gil |
| Characters holding gil | 292 |
| Average per character | 43,550,812 gil |
| Median per character | 6,434,808 gil |
| Wealthiest 10% hold | 70.3% of all gil |
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
| Live listings (total) | 28,938 |
| — Market-maker (AH-Jeuno) | 28,923 |
| — Player-listed | 15 |
| Distinct items available | 5,794 |
| Total shelf value (asking) | 13,849,285,996 gil |
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
| Last 24 hours | 1,065 | 528,447,252 gil | 195,150,001 gil |
| Last 7 days | 5,802 | 2,682,247,284 gil | 1,052,066,001 gil |
| Last 30 days | 5,953 | 2,746,477,284 gil | 1,110,246,001 gil |
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
| 2 | Gully | 320 | 204,800,000 gil |
| 3 | Yataghan | 265 | 208,927,500 gil |
| 4 | Robur Mace | 189 | 149,600,000 gil |
| 5 | Gleaming Shield | 151 | 106,262,688 gil |
| 6 | Ash Staff | 128 | 17,920,000 gil |
| 7 | Revilers Helm | 125 | 61,220,520 gil |
| 8 | Jug Of Bug Broth | 85 | 22,036,000 gil |
| 9 | Chirich Ring +1 | 75 | 75,000,000 gil |
| 10 | Mache Earring +1 | 72 | 72,000,000 gil |
| 11 | Moonlight Cape | 52 | 52,000,000 gil |
| 12 | Bomb Arm | 43 | 5,600,900 gil |
| 13 | Moonlight Ring | 39 | 39,000,000 gil |
| 14 | Stikini Ring +1 | 35 | 35,000,000 gil |
| 15 | Hermits Ring | 35 | 4,900,000 gil |
<!-- DOCGEN:END id="econ-hot" -->

---

## Population

<!-- DOCGEN:BEGIN id="econ-population" -->
Who's around. **Active** counts characters that logged out within the window (a proxy for recent play); **new** counts characters created in the window.

| Measure | Value |
|---|---:|
| Online right now | 31 |
| Total characters | 386 |
| Active — last 7 days | 375 |
| Active — last 30 days | 386 |
| New — last 7 days | 336 |
| New — last 30 days | 386 |
| Cumulative playtime (all chars) | 191 days, 10 hours |
<!-- DOCGEN:END id="econ-population" -->

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: f2e5f542a2e6 -->
_Last updated: 2026-06-21 07:51 UTC_
<!-- DOCGEN:END id="last-updated" -->
