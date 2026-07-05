# SQL archive — completed one-time migrations

Files in this directory are **not** auto-loaded. `modules/init.txt` enables
`custom/sql/` (steady-state, idempotent definitions that re-apply every deploy);
this sibling `custom/sql-archive/` directory is deliberately outside that path so
one-time migrations do not re-run on every deploy.

**Policy**

- `custom/sql/` = repeatable, idempotent, canonical definitions only.
- `custom/sql-archive/` = historical one-time migrations, kept for the record.
  Apply by hand once, against the specific database that needs it, then leave here.

Do not move a file back into `custom/sql/` unless it is fully idempotent and is
the single canonical owner of the rows it touches.

## Contents

### `hunting_league_escha_migration.sql`
One-time move of the Hunting League from Reisenjima Henge (zone 292) to
Escha - Zi'Tah (zone 288). Applied to the live relaunch DB on 2026-06-15.

- The canonical steady-state definition of the zone-288 HL `mob_groups` rows now
  lives in `custom/sql/hunting_league_mobs.sql`, which also performs the
  idempotent "clear native zone-288 spawn points" step (relocated from this
  migration). That file re-applies safely every deploy.
- The only thing unique to this migration is deleting the **old zone-292** HL
  rows. A fresh database never creates zone-292 HL rows, so this step is obsolete
  for new builds and only mattered for the in-place 6/15 move.

There is nothing left here that a fresh build needs; it is retained purely as a
record of the 292→288 relocation.
