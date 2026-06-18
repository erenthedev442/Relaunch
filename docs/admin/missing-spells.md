# Missing Spells Audit

This page tracks which custom spells are implemented versus still stubbed. The
stub count and the list of remaining spells below are **auto-generated** by
scanning the live spell scripts under `scripts/actions/spells/` — a stub is any
spell file that still carries the `[spell-stub]` runtime marker (a placeholder
that prints "not yet implemented" on cast). The "What is implemented" table is
hand-maintained.

<!-- DOCGEN:BEGIN id="missing-spells-summary" -->
_All scanned spells are implemented — **0 stubs** remaining._
<!-- DOCGEN:END id="missing-spells-summary" -->

## What is implemented now (20)

| Spell | Folder | Notes |
|---|---|---|
| Sandstorm II | white | Applies SANDSTORM_II effect, mutex with all other storms |
| Rainstorm II | white | Applies RAINSTORM_II effect |
| Windstorm II | white | Applies WINDSTORM_II effect |
| Firestorm II | white | Applies FIRESTORM_II effect |
| Hailstorm II | white | Applies HAILSTORM_II effect |
| Thunderstorm II | white | Applies THUNDERSTORM_II effect |
| Voidstorm II | white | Applies VOIDSTORM_II effect |
| Aurorastorm II | white | Applies AURORASTORM_II effect |
| Enlight II | white | Reuses ENLIGHT effect with stronger power |
| Adloquium | white | SCH stronger Stoneskin |
| Animus Augeo | white | RUN attack-boost buff |
| Animus Minuo | white | RUN debuff (placeholder, generic Addle) |
| Addle II | trust | Stronger ADDLE |
| Full Cure | trust | Heals target to max HP |
| Protected Aria | songs | PROTECT, 5 min |
| Chocobo Hum | songs | Small REGEN, 3 min |
| Moogle Rhapsody | songs | Small REFRESH, 3 min |
| Cactuar Fugue | songs | ATTACK_BOOST, 3 min |
| Jester's Operetta | songs | CHR_BOOST, 3 min |
| Devotee Serenade | songs | MND_BOOST, 3 min |

Each file has a `-- RETAIL FIDELITY NOTE` block at the top explaining what BG-Wiki
says retail does vs. what this server implements. Replace the spell body when you
have authoritative numbers to refine.

Plus 5 trust-dispatch shims (Aspir III, Distract III, Frazzle III, Inundation,
Refresh III) that re-use existing black/white implementations.

---

## Still stubbed

These print `[Spell] "X" is not yet implemented on this server, kupo.` on cast and log
a `[spell-stub]` line server-side. Each BLU spell needs unique parameters from BG-Wiki:
`attribute`, `multiplier`, `tMultiplier`, `attackType`, `damageType`, `duppercap`, and
the seven WSC values (str_wsc..chr_wsc). Implementing them in bulk with default values
would produce functional-but-wrong spells, harder to debug than stubs.

<!-- DOCGEN:BEGIN id="missing-spells-stub-list" -->
Nothing stubbed — every spell script has a real implementation. 🎉
<!-- DOCGEN:END id="missing-spells-stub-list" -->

---

## How to clear an entry from this list

1. Open the spell file at `scripts/actions/spells/blue/<name>.lua` (currently a stub).
2. Look up the spell on BG-Wiki to capture: damage formula, attack/damage type, WSC values, added effect (if any).
3. Replace the stub body with a real `xi.spells.blue.useMagicalSpell` / `usePhysicalSpell` / `useBreathSpell` call with the proper params, plus the added effect.
4. Compare to a peer spell like `blue/blastbomb.lua` for the canonical shape.
5. Removing the `[spell-stub]` marker line is what clears it from the list — the
   next docgen run (`tools/docgen/generators/missing_spells.py`) re-scans the
   spell scripts and updates the count and table above automatically.

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 9961a0aaeed6 -->
_Last updated: 2026-06-14 20:53 UTC_
<!-- DOCGEN:END id="last-updated" -->
