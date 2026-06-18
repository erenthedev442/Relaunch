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
| Gil in circulation | **3.76B** gil |
| Players online now | **35** |
| Characters (non-GM) | 285 |
| Active in last 7 days | 284 |
| AH listings (live) | 593 |
| Cumulative playtime | 96 days, 2 hours |
<!-- DOCGEN:END id="econ-overview" -->

---

## Gil Supply

<!-- DOCGEN:BEGIN id="econ-gil" -->
Total gil held by player characters — the money supply. Gil sitting in Auction House escrow (unsold listings) and on GM characters is not counted.

| Measure | Value |
|---|---:|
| Total gil in circulation | 3,760,503,041 gil |
| Characters holding gil | 203 |
| Average per character | 18,524,645 gil |
| Median per character | 5,392,102 gil |
| Wealthiest 10% hold | 60.4% of all gil |
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
| Live listings (total) | 593 |
| — Market-maker (AH-Jeuno) | 525 |
| — Player-listed | 68 |
| Distinct items available | 348 |
| Total shelf value (asking) | 252,647,955 gil |
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
| Last 24 hours | 129 | 79,863,061 gil | 28,070,000 gil |
| Last 7 days | 1,983 | 696,651,978 gil | 504,920,000 gil |
| Last 30 days | 1,983 | 696,651,978 gil | 504,920,000 gil |
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
| 1 | Revilers Helm | 82 | 33,700,520 gil |
| 2 | Yataghan | 63 | 48,827,500 gil |
| 3 | Chirich Ring +1 | 37 | 37,000,000 gil |
| 4 | Mache Earring +1 | 28 | 28,000,000 gil |
| 5 | Moonlight Cape | 26 | 26,000,000 gil |
| 6 | Moonlight Ring | 22 | 22,000,000 gil |
| 7 | Cassie Earring | 19 | 2,660,000 gil |
| 8 | Copper Ring | 19 | 2,660,000 gil |
| 9 | Aptitude Mantle +1 | 18 | 18,000,000 gil |
| 10 | Hope Earring +1 | 17 | 2,380,000 gil |
| 11 | Onion Staff | 17 | 1,974,314 gil |
| 12 | Hi-Potion | 16 | 7,281 gil |
| 13 | Stikini Ring +1 | 15 | 15,000,000 gil |
| 14 | Copper Hairpin | 15 | 2,100,000 gil |
| 15 | Bronze Sword | 15 | 1,593,570 gil |
<!-- DOCGEN:END id="econ-hot" -->

---

## Population

<!-- DOCGEN:BEGIN id="econ-population" -->
Who's around. **Active** counts characters that logged out within the window (a proxy for recent play); **new** counts characters created in the window.

| Measure | Value |
|---|---:|
| Online right now | 35 |
| Total characters | 285 |
| Active — last 7 days | 284 |
| Active — last 30 days | 285 |
| New — last 7 days | 284 |
| New — last 30 days | 285 |
| Cumulative playtime (all chars) | 96 days, 2 hours |
<!-- DOCGEN:END id="econ-population" -->

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 8a43de93cb3e -->
_Last updated: 2026-06-18 20:56 UTC_
<!-- DOCGEN:END id="last-updated" -->
