# Relaunch Custom DAT Manifest

This manifest tracks every client DAT override included in the Relaunch Custom
DATs pack.

## Included DATs

| File | Overrides | Notes |
|------|-----------|-------|
| `ROM/286/73.DAT` | item `26169` name + description | Only 114 bytes differ from retail (record #3129); every other item in the file is byte-identical. |

The edit was made by decoding the retail item block (FFXI items are ROR-5
bit-rotated), rewriting the four strings in place, and re-encoding. The retail
`Reraise Ring` name/help text became the Legendary Ring text below; nothing else
in the 17 MB file changed.

## Overrides

| Item ID | Retail Name  | Relaunch Name  | Status | Notes |
|--------:|--------------|----------------|--------|-------|
| `26169` | Reraise Ring | Legendary Ring | Done (`ROM/286/73.DAT`) | Functional Legacy migration reward. |

## Required Display Text

Suggested player-facing text for item `26169` (matches the server-side stats in
`modules/custom/sql/legendary_ring.sql`):

```text
Legendary Ring
[Ring] All Races
Capacity Points Boost +50%
Experience Points Boost +50%
Auto Reraise Effect
Lv.1 All Jobs
```

Name string: `Legendary Ring`

The `[Ring] All Races` and `Lv.1 All Jobs` header lines are auto-rendered by the
client from the item's binary attributes (slot=Rings, races=All, level 1, jobs
All) — already correct on item 26169, so only the name + the three effect lines
above are stored as edited text.

## Server-Side Source Of Truth

The server-side behavior lives in:

- `modules/custom/sql/legendary_ring.sql`  (item_basic / item_equipment / item_mods)
- `modules/custom/lua/legacy_ring_grant.lua`  (login grant)

The DAT pack is visual only. If DAT text disagrees with the server, the server
wins.
