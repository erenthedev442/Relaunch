# Player Guide addon (paused)

**Status:** Paused 2026-08-14. Do not start implementation until after public launch.

**Goal:** An in-game tabbed guide that works on both **Ashita v4** and **Windower 4**. Static Relaunch content first; live per-character progression added in smaller follow-up slices.

**Conversation:** [Player guide design](aa7262ca-5fb7-4ec0-b1c5-a239d6457b85)

---

## Why this exists

Players need one place to browse custom content and see “what do I do next?” without Discord, the website, or chat walls.

Native FFXI `customMenu` cannot do this. It is ~8 options and has no real tabs. The product is a client addon with a server progress dump.

Existing Windower addons already prove the pattern:

- `tools/windower/augment_browser/`
- `tools/windower/augment_trade/`

Those use the Windower `texts` library and parse server output. The guide should follow the same contract, not invent a second one.

---

## Player experience

Open with `//relaunch` or `//guide`. One resizable window, same information and layout on both clients.

Left-rail navigation:

| Section | Kind | First-pass content |
| --- | --- | --- |
| Home | Static | Welcome, how to use the guide, current weekly highlight |
| My Progress | Live | Snapshot of hunts, marks, currencies, unlocks, active sessions |
| Weapons & REMA | Mixed | Pilgrimage stages, next objective, eligible families, forge gates |
| Armor & Augments | Mixed | Augment ranks, catalog, owned catalysts |
| Custom Content | Static | HTBF, Voidwatch, Domain, Tower, Gauntlet, Apex, dungeons |
| Weekly Activities | Mixed | Weekly hunts, resets, rewards |
| Systems & Help | Static | Commands, hub/warp, glossary, troubleshooting |

A REMA page should look like:

> Caladbolg — Chapter II
> Defeat 100 qualifying Beasts, Dragons, or Vermin with a Final Haven killing blow.
> Progress: 42/100
> Eligible families, HP floor, suggested camps, previous/next chapter, costs, NPC.

Static knowledge sits beside live counters. Players should not need an external guide to understand the next step.

---

## Architecture

Windower 4 and Ashita v4 cannot share UI code. They **can** share everything that matters.

```text
Relaunch server
    !guide sync / !guide dump <section>
    tagged, versioned chat lines
        |
        v
Shared content + view model
    generated catalogs, nav, labels, schema version
        |
        +-- Windower 4 renderer  (texts / primitives, like AugmentBrowser)
        +-- Ashita v4 renderer   (ImGui via require 'imguidef')
```

### Shared (one source of truth)

- Navigation structure and page IDs
- Static page copy
- Objective definitions and labels
- Generated catalogs from server Lua
- Schema / protocol version
- Visual spec (colors, tab names, wording)

### Not shared

- Window drawing
- Input / click handling
- Client-specific settings files

### Static vs live

**Static (bundled with each addon release):**

- Guides, costs, NPC locations, unlock paths
- Loot explanations, glossary, troubleshooting
- Generate from server catalogs wherever possible so the addons do not drift

**Live (small snapshots, not a stream):**

- Current chapter, counters, currencies
- Weekly status, active objectives, unlock flags
- Next recommended action

Refresh only:

- When the window opens
- On manual refresh
- On zone-in
- Every 3–5 minutes while visible

Do **not** poll constantly. Do **not** scrape ordinary chat.

---

## Server contract (to build later)

New player command, permission 0, something like:

```text
!guide sync
!guide dump rema
!guide dump weekly
!guide dump progress
```

Return tagged lines the addons can parse, for example:

```text
[GUIDE] v1 rema begin
[GUIDE] weapon=Caladbolg chapter=2 count=42 need=100
[GUIDE] objective=Final Haven killing blows
[GUIDE] families=Beast,Dragon,Vermin hp=150000
[GUIDE] v1 rema end
```

Existing server pieces to reuse, not rewrite:

| System | Where to start |
| --- | --- |
| REMA / pilgrimage next-step | `modules/custom/lua/LegendaryWeaponPilgrimage.lua` |
| Pilgrimage catalog | `modules/custom/lua/legendary_pilgrimage_catalog.lua` |
| `!progress` | `modules/custom/commands/progress.lua` |
| `!forgegates` | `modules/custom/commands/forgegates.lua` |
| `!empyaby` | `modules/custom/commands/empyaby.lua` |
| Augment catalog (already shipped to Windower) | `tools/windower/augment_browser/` |

---

## Delivery order

Build the full architecture immediately. Add live sections incrementally.

1. **Foundation** — schema, tagged server responses, shared generated content, settings and updater contract.
2. **REMA vertical slice** — both clients show the same pilgrimage, forge gates, costs, eligible targets, and live counters. This is the proof the contract works.
3. **Progress dashboard** — hunts, weekly, mastery, reforge, currencies, achievements, active sessions.
4. **Knowledge base** — custom content guides, NPCs, entry rules, rewards, search, cross-links.
5. **Polish** — cache, version-mismatch warnings, updater packages, keyboard/controller nav, QA on both clients.

Later, optional: click-to-open `!warp` choices or “find NPC”. Not required for v1.

---

## Confidence (as of 2026-08-14)

| Piece | Likelihood | Note |
| --- | --- | --- |
| Server data layer | 90–95% | Most progress already exists as catalogs and charVars |
| Ashita v4 UI | 85–90% | ImGui can do a tabbed app |
| Windower 4 UI | 75–85% | No native ImGui; custom texts/primitives renderer |
| Functional parity | ~85% | Same information and navigation, not pixel-identical |
| Full polished product | ~82% | Content authoring is the long pole, not progress retrieval |

**Raises success:** one schema, generated static data, tagged responses, coarse refreshes, REMA-first, two thin renderers.

**Lowers success:** duplicating business logic in addons, scraping chat, constant polling, client-specific feature creep, hand-duplicated content.

Pixel-perfect Ashita/Windower matching is not a goal.

---

## Pickup checklist

When we resume after launch:

1. Confirm players are actually on both Ashita v4 and Windower 4.
2. Re-read this file and the REMA pilgrimage + `!progress` commands — they may have changed.
3. Implement `!guide dump` / `!guide sync` on the server first.
4. Ship a REMA-only window on **both** clients before adding more tabs.
5. Generate static catalogs from server Lua; do not copy numbers by hand.
6. Keep docs updates in **Relaunch-Docs**, not this repo.
