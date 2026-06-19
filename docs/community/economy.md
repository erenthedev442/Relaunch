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
| Gil in circulation | **4.45B** gil |
| Players online now | **1** |
| Characters (non-GM) | 326 |
| Active in last 7 days | 325 |
| AH listings (live) | 28,644 |
| Cumulative playtime | 119 days, 23 hours |
<!-- DOCGEN:END id="econ-overview" -->

---

## Gil Supply

<!-- DOCGEN:BEGIN id="econ-gil" -->
Total gil held by player characters — the money supply. Gil sitting in Auction House escrow (unsold listings) and on GM characters is not counted.

| Measure | Value |
|---|---:|
| Total gil in circulation | 4,446,205,486 gil |
| Characters holding gil | 239 |
| Average per character | 18,603,370 gil |
| Median per character | 5,194,444 gil |
| Wealthiest 10% hold | 60.5% of all gil |
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
| Live listings (total) | 28,644 |
| — Market-maker (AH-Jeuno) | 28,601 |
| — Player-listed | 43 |
| Distinct items available | 5,796 |
| Total shelf value (asking) | 13,717,938,820 gil |
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
| Last 24 hours | 195 | 74,272,945 gil | 40,020,000 gil |
| Last 7 days | 2,834 | 1,056,297,715 gil | 657,930,000 gil |
| Last 30 days | 2,834 | 1,056,297,715 gil | 657,930,000 gil |
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
| 1 | Yataghan | 201 | 159,227,500 gil |
| 2 | Revilers Helm | 93 | 40,740,520 gil |
| 3 | Ash Staff | 60 | 8,400,000 gil |
| 4 | Chirich Ring +1 | 53 | 53,000,000 gil |
| 5 | Mache Earring +1 | 43 | 43,000,000 gil |
| 6 | Moonlight Cape | 35 | 35,000,000 gil |
| 7 | Eyra Baghnakhs | 32 | 25,600,000 gil |
| 8 | Gleaming Shield | 30 | 23,202,610 gil |
| 9 | Cassie Earring | 25 | 3,500,000 gil |
| 10 | Moonlight Ring | 24 | 24,000,000 gil |
| 11 | Jug Of Bug Broth | 24 | 6,280,000 gil |
| 12 | Stikini Ring +1 | 23 | 23,000,000 gil |
| 13 | Onion Staff | 23 | 2,814,314 gil |
| 14 | Power Gi | 22 | 3,267,581 gil |
| 15 | Bronze Sword | 21 | 2,433,570 gil |
<!-- DOCGEN:END id="econ-hot" -->

---

## Population

<!-- DOCGEN:BEGIN id="econ-population" -->
Who's around. **Active** counts characters that logged out within the window (a proxy for recent play); **new** counts characters created in the window.

| Measure | Value |
|---|---:|
| Online right now | 1 |
| Total characters | 326 |
| Active — last 7 days | 325 |
| Active — last 30 days | 326 |
| New — last 7 days | 325 |
| New — last 30 days | 326 |
| Cumulative playtime (all chars) | 119 days, 23 hours |
<!-- DOCGEN:END id="econ-population" -->

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 72e878efafc9 -->
_Last updated: 2026-06-19 16:09 UTC_
<!-- DOCGEN:END id="last-updated" -->
