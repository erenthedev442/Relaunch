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
| Gil in circulation | **23.87B** gil |
| Players online now | **0** |
| Characters (non-GM) | 417 |
| Active in last 7 days | 347 |
| AH listings (live) | 30,293 |
| Cumulative playtime | 258 days, 1 hour |
<!-- DOCGEN:END id="econ-overview" -->

---

## Gil Supply

<!-- DOCGEN:BEGIN id="econ-gil" -->
Total gil held by player characters — the money supply. Gil sitting in Auction House escrow (unsold listings) and on GM characters is not counted.

| Measure | Value |
|---|---:|
| Total gil in circulation | 23,869,319,228 gil |
| Characters holding gil | 324 |
| Average per character | 73,670,738 gil |
| Median per character | 7,126,686 gil |
| Wealthiest 10% hold | 71.9% of all gil |
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
| — Market-maker (AH-Jeuno) | 30,274 |
| — Player-listed | 19 |
| Distinct items available | 6,064 |
| Total shelf value (asking) | 14,199,550,950 gil |
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
| Last 24 hours | 1,077 | 619,252,095 gil | 237,220,000 gil |
| Last 7 days | 6,999 | 3,516,062,784 gil | 1,285,339,001 gil |
| Last 30 days | 8,099 | 3,831,332,996 gil | 1,567,899,001 gil |
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
| 1 | Gully | 980 | 627,200,000 gil |
| 2 | Eyra Baghnakhs | 813 | 626,430,381 gil |
| 3 | Yataghan | 266 | 209,727,500 gil |
| 4 | Gleaming Shield | 231 | 170,262,688 gil |
| 5 | Robur Mace | 189 | 149,600,000 gil |
| 6 | Revilers Helm | 143 | 72,740,520 gil |
| 7 | Ash Staff | 128 | 17,920,000 gil |
| 8 | Mache Earring +1 | 93 | 93,000,000 gil |
| 9 | Chirich Ring +1 | 92 | 92,000,000 gil |
| 10 | Jug Of Bug Broth | 85 | 22,036,000 gil |
| 11 | Bomb Arm | 75 | 10,080,900 gil |
| 12 | Moonlight Cape | 67 | 67,000,000 gil |
| 13 | Moonlight Ring | 51 | 51,000,000 gil |
| 14 | Stikini Ring +1 | 51 | 51,000,000 gil |
| 15 | Hermits Ring | 49 | 6,920,000 gil |
<!-- DOCGEN:END id="econ-hot" -->

---

## Population

<!-- DOCGEN:BEGIN id="econ-population" -->
Who's around. **Active** counts characters that logged out within the window (a proxy for recent play); **new** counts characters created in the window.

| Measure | Value |
|---|---:|
| Online right now | 0 |
| Total characters | 417 |
| Active — last 7 days | 347 |
| Active — last 30 days | 417 |
| New — last 7 days | 239 |
| New — last 30 days | 417 |
| Cumulative playtime (all chars) | 258 days, 1 hour |
<!-- DOCGEN:END id="econ-population" -->

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 847b7a3d0cde -->
_Last updated: 2026-06-23 08:54 UTC_
<!-- DOCGEN:END id="last-updated" -->
