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
| Gil in circulation | **2.83B** gil |
| Players online now | **32** |
| Characters (non-GM) | 273 |
| Active in last 7 days | 272 |
| AH listings (live) | 28,963 |
| Cumulative playtime | 86 days, 14 hours |
<!-- DOCGEN:END id="econ-overview" -->

---

## Gil Supply

<!-- DOCGEN:BEGIN id="econ-gil" -->
Total gil held by player characters — the money supply. Gil sitting in Auction House escrow (unsold listings) and on GM characters is not counted.

| Measure | Value |
|---|---:|
| Total gil in circulation | 2,834,851,309 gil |
| Characters holding gil | 193 |
| Average per character | 14,688,348 gil |
| Median per character | 5,469,589 gil |
| Wealthiest 10% hold | 50.1% of all gil |
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
| — Market-maker (AH-Jeuno) | 28,923 |
| — Player-listed | 40 |
| Distinct items available | 5,804 |
| Total shelf value (asking) | 13,850,460,903 gil |
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
| Last 24 hours | 434 | 183,761,727 gil | 123,460,000 gil |
| Last 7 days | 1,761 | 571,361,957 gil | 441,810,000 gil |
| Last 30 days | 1,761 | 571,361,957 gil | 441,810,000 gil |
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
| 1 | Revilers Helm | 78 | 31,140,520 gil |
| 2 | Chirich Ring +1 | 33 | 33,000,000 gil |
| 3 | Mache Earring +1 | 24 | 24,000,000 gil |
| 4 | Moonlight Cape | 21 | 21,000,000 gil |
| 5 | Yataghan | 20 | 14,427,500 gil |
| 6 | Copper Ring | 19 | 2,660,000 gil |
| 7 | Aptitude Mantle +1 | 18 | 18,000,000 gil |
| 8 | Moonlight Ring | 18 | 18,000,000 gil |
| 9 | Cassie Earring | 18 | 2,520,000 gil |
| 10 | Hope Earring +1 | 17 | 2,380,000 gil |
| 11 | Onion Staff | 16 | 1,834,314 gil |
| 12 | Hi-Potion | 16 | 7,281 gil |
| 13 | Copper Hairpin | 15 | 2,100,000 gil |
| 14 | Power Gi | 14 | 1,907,581 gil |
| 15 | Stikini Ring +1 | 13 | 13,000,000 gil |
<!-- DOCGEN:END id="econ-hot" -->

---

## Population

<!-- DOCGEN:BEGIN id="econ-population" -->
Who's around. **Active** counts characters that logged out within the window (a proxy for recent play); **new** counts characters created in the window.

| Measure | Value |
|---|---:|
| Online right now | 32 |
| Total characters | 273 |
| Active — last 7 days | 272 |
| Active — last 30 days | 273 |
| New — last 7 days | 272 |
| New — last 30 days | 273 |
| Cumulative playtime (all chars) | 86 days, 14 hours |
<!-- DOCGEN:END id="econ-population" -->

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 0a785a86a720 -->
_Last updated: 2026-06-17 17:57 UTC_
<!-- DOCGEN:END id="last-updated" -->
