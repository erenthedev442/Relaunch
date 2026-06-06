"""dpscalc -- DPS / Weaponskill damage estimator for the Legendary server.

Reverse-engineers the server's ACTUAL melee + weaponskill damage model (the
custom Lua formulas under scripts/globals/combat/, not retail FFXI) and ranks
gear/augment combinations to maximise damage against the Hunting League NMs.

Design principle: the server is the source of truth.
  * Mod ids are parsed from scripts/enum/mod.lua (never hardcoded).
  * Item + augment mods are read from the live `xidb` database.
  * The non-gear baseline (base stats + traits + merits + job points + the
    custom Prestige system) is ANCHORED on a real `!mystats` snapshot rather
    than re-derived, because the engine computes those at runtime and they are
    not stored in the DB. Gear swaps are then applied as exact deltas.

Run pieces with e.g.  `python -m tools.dpscalc.gear 1`  from the repo root.
"""
