# Relaunch Custom DAT Manifest

This manifest tracks every client DAT override included in the Relaunch Custom
DATs pack.

## Included DATs

No edited DAT binaries are included yet.

The repository does not contain the retail client DAT file for item `26169`, so
the binary override must be exported/edited from a local FFXI client install
first (see below).

## Planned Overrides

| Item ID | Retail Name  | Relaunch Name  | Status            | Notes |
|--------:|--------------|----------------|-------------------|-------|
| `26169` | Reraise Ring | Legendary Ring | Pending DAT export | Functional Legacy migration reward. |

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

## Server-Side Source Of Truth

The server-side behavior lives in:

- `modules/custom/sql/legendary_ring.sql`  (item_basic / item_equipment / item_mods)
- `modules/custom/lua/legacy_ring_grant.lua`  (login grant)

The DAT pack is visual only. If DAT text disagrees with the server, the server
wins.
