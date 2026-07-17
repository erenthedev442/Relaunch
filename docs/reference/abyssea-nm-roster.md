# Abyssea NM Owner Reference

The sortable source-of-truth export is
[`abyssea-nm-roster.csv`](abyssea-nm-roster.csv). It contains one row for each
of the 136 logical Hunt Marks encounters and is intended for server-owner
support, balance review, and player questions.

Open the CSV in Excel, LibreOffice, or Google Sheets and enable filters on the
header row. Useful filters include:

- `Boss` or `Zone` to answer questions about a specific encounter.
- `TierName` and `Difficulty` to compare content bands.
- `CustomClimax = Yes` to find flagship fights with a bespoke 30% mechanic.
- `RepeatType`, `Phase70Type`, or `Phase30Type` to find all bosses using a
  particular counter such as `hold`, `burst`, or `far`.
- `RepeatFailStatus`, `Phase70FailStatus`, or `Phase30FailStatus` to audit
  Doom, Terror, Petrification, and other punishments.

## Reading an encounter row

Every fight has a repeating signature plus tests at 70% and 30% HP:

- **Visions:** the same teaching mechanic repeats at both phase floors.
- **Scars:** the 70% floor repeats the signature; the 30% floor reverses it.
- **Heroes:** standard encounters reverse the signature at 70%, then reverse
  it again at 30%.
- **Custom climax:** flagship encounters repeat their signature at 70%, then
  switch to the named bespoke climax at 30%.

`RepeatCounter`, `Phase70Counter`, and `Phase30Counter` are the operator-facing
solutions. Burst counters include the exact damage required at the solo,
two-player, and three-or-more-player HP scales.

`*FailDamagePctMaxHP` is damage dealt to the fight owner when a mechanic is
missed. The accompanying status, duration, message, and escalation are shown
in adjacent columns. Successful counters open the exact DEF/EVA/MDEF
vulnerability shown in `*SuccessReward` and remove one escalation stack.

The `ATT_Add`, `DEF_Add`, `WeaponDMG_Add`, and similar stat columns are
**additive modifiers** applied after the mob is normalized to its tier level
(120 / 130 / 150). They are not guaranteed final sheet totals because each
retail mob keeps its native base profile, skill list, and script behavior.

## Rules that apply to every row

- Only the player who popped the NM is evaluated for encounter counters.
- Trust attacks do not cause a hold-fire mechanic to fail.
- HP scales to 1.0x / 1.55x / 2.10x for one / two / three-or-more real PCs.
- DEF, EVA, and other combat modifiers do not scale with party size.
- The 70% and 30% HP floors remain locked until their mechanic resolves.
- Repeated failures add tier-scaled ATT and MATT escalation.
- Passing the pressure time adds recurring ATT, MATT, and Haste stacks.
- Red weakness removes an escalation stack; Yellow suppresses the spell
  sequence and opens magic vulnerability; Blue suppresses the TP sequence and
  opens physical vulnerability.
- First logical clear refunds half the pop cost. Two or more real players give
  2x Gil/Infamy; no Trusts gives 1.5x; both stack to 3x.

## Where to rebalance

- Boss mechanics, tells, timings, and phase structure:
  `modules/custom/lua/abyssea_marks_catalog.lua`
- HP and intended clear-time contracts:
  `modules/custom/lua/abyssea_marks_balance.lua`
- Tier stats, pop costs, and base rewards:
  `modules/custom/lua/AbysseaMarks.lua`
- Counter evaluation, punishment, vulnerability, escalation, and pressure:
  `modules/custom/lua/abyssea_marks_mechanics.lua`

After changing the Lua catalog or tier configuration, regenerate the CSV from
the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\export_abyssea_nm_csv.ps1
```

The exporter refuses to write unless it finds exactly 136 encounters with the
expected 45 / 49 / 42 tier split, preventing a partial reference export.
