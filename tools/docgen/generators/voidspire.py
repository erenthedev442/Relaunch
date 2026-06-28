"""Sync docs/endgame/voidspire.md with voidspire_catalog.lua.

The Voidspire is an endless floor-by-floor gauntlet: your deepest floor is the
score. Everything on the page — where it starts, how floors scale, the
difficulty bands, the affix list, per-floor marks, and the depth milestones —
is read from the catalog so re-tuning the run updates the published guide.

Markers written:
  voidspire-access      — Warden NPC + zone line
  voidspire-scaling     — how floors scale + difficulty bands
  voidspire-affixes     — the affix list (start floor / cadence / cap + table)
  voidspire-rewards     — per-floor marks + depth milestones
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section, ints, commafy


def _first(pattern: str, text: str, default: str) -> str:
    m = re.search(pattern, text)
    return m.group(1) if m else default


def _stat(block: str, key: str) -> dict:
    """Pull a `key = { base = .., per = .., cap = .. }` ramp out of a block."""
    sub = section(block, key)
    out = {}
    for field in ("base", "per", "cap"):
        m = re.search(rf"{field}\s*=\s*([0-9.]+)", sub)
        if m:
            out[field] = float(m.group(1))
    return out


def _parse(text: str) -> dict:
    c: dict = {}

    m = re.search(r"zone\s*=\s*'([^']+)'", text)
    c["zone"] = m.group(1).replace("_", "-") if m else "Escha-RuAun"

    scaling = section(text, "catalog.scaling")
    c["level"] = _stat(scaling, "level")
    c["hp"] = _stat(scaling, "hpBoost")
    c["mobsBase"] = int(float(_first(r"mobsBase\s*=\s*(\d+)", scaling, "1")))
    c["mobsStep"] = int(float(_first(r"mobsStep\s*=\s*(\d+)", scaling, "10")))
    c["mobsCap"] = int(float(_first(r"mobsCap\s*=\s*(\d+)", scaling, "5")))

    # Difficulty bands: floors up-to F -> difficulty name.
    bands = section(text, "catalog.bands")
    c["bands"] = []
    for upto, diff in re.findall(
        r"upTo\s*=\s*([\w.]+)\s*,\s*diff\s*=\s*'([^']+)'", bands
    ):
        c["bands"].append((upto, diff))

    c["affixStart"] = int(float(_first(r"catalog\.affixStartFloor\s*=\s*(\d+)", text, "10")))
    c["affixStep"] = int(float(_first(r"catalog\.affixStep\s*=\s*(\d+)", text, "15")))
    c["affixCap"] = int(float(_first(r"catalog\.affixCap\s*=\s*(\d+)", text, "5")))

    # Affixes: PUBLIC-safe label + desc only (mod deltas are scrubbed).
    affixes = section(text, "catalog.affixes")
    c["affixes"] = re.findall(r"label\s*=\s*'([^']+)'\s*,\s*desc\s*=\s*'([^']+)'", affixes)

    c["markBase"] = int(float(_first(r"catalog\.markBase\s*=\s*(\d+)", text, "5")))
    c["markPerFloor"] = int(float(_first(r"catalog\.markPerFloor\s*=\s*(\d+)", text, "2")))

    milestones = section(text, "catalog.milestones")
    c["milestones"] = [
        (int(f), int(m))
        for f, m in re.findall(r"floor\s*=\s*(\d+)\s*,\s*marks\s*=\s*(\d+)", milestones)
    ]
    return c


# ---------------------------------------------------------------------------

def _render_access(c: dict) -> str:
    return (f"Find the **Warden** in **{c['zone']}** and choose to descend. "
            f"The run begins after a short breather, then the floors come one "
            f"after another — clear a floor and the next spawns automatically. "
            f"A single wipe ends the run and locks in your deepest floor.")


def _render_scaling(c: dict) -> str:
    lvl = c["level"]
    hp = c["hp"]
    lines = []
    lines.append("Every floor is tougher than the last. Three things climb as "
                 "you descend:")
    lines.append("")
    if lvl:
        lines.append(f"- **Monster level** starts around **{int(lvl.get('base', 0))}** "
                     f"and rises until it tops out near **{int(lvl.get('cap', 0))}**.")
    if hp:
        lines.append(f"- **Monster HP** begins at roughly **{hp.get('base', 0):g}×** "
                     f"the normal amount and swells up to **{hp.get('cap', 0):g}×** "
                     f"the deeper you go.")
    lines.append(f"- **Pack size** grows from **{c['mobsBase']}** monster, adding "
                 f"one more every **{c['mobsStep']}** floors, up to **{c['mobsCap']}** "
                 f"at once.")
    lines.append("")
    lines.append("Beyond level, the real bite comes from the monsters' offense — "
                 "attack, accuracy and attack speed ramp hard, so deep floors "
                 "overwhelm you with incoming damage rather than turning into "
                 "unkillable sponges.")

    if c["bands"]:
        lines.append("")
        lines.append("The run moves through four difficulty bands as you descend:")
        lines.append("")
        lines.append("| Floors | Difficulty |")
        lines.append("|---|---|")
        prev = 0
        for upto, diff in c["bands"]:
            if upto in ("math.huge", "huge"):
                rng = f"{prev + 1}+"
            else:
                hi = int(upto)
                rng = f"{prev + 1}" if hi == prev + 1 else f"{prev + 1}–{hi}"
                prev = hi
            lines.append(f"| {rng} | **{diff}** |")
    return "\n".join(lines)


def _render_affixes(c: dict) -> str:
    lines = []
    lines.append(f"Starting at **floor {c['affixStart']}**, the Void layers extra "
                 f"modifiers onto every monster. One more affix switches on every "
                 f"**{c['affixStep']}** floors, up to **{c['affixCap']}** at once. "
                 f"The set is rolled fresh for each run and shown to you when you "
                 f"begin, so no two descents play quite the same.")
    if c["affixes"]:
        lines.append("")
        lines.append("| Affix | What it does |")
        lines.append("|---|---|")
        for label, desc in c["affixes"]:
            # The catalog uses ` -- ` as a prose dash inside the flavor text;
            # render it as a real em-dash rather than dropping the tail.
            clean = re.sub(r"\s*--\s*", " — ", desc).strip()
            lines.append(f"| **{label}** | {clean} |")
    return "\n".join(lines)


def _render_rewards(c: dict) -> str:
    lines = []
    lines.append(f"Clearing a floor pays **{c['markBase']} + {c['markPerFloor']} "
                 f"× the floor number** in marks, so deeper floors are worth more "
                 f"each. The Voidspire's real prize, though, is the leaderboard — "
                 f"your deepest floor is your score.")
    if c["milestones"]:
        lines.append("")
        lines.append("Reaching certain depths pays a bonus on top — awarded on "
                     "your **first clear of that floor each UTC week** (tracked "
                     "per character per floor):")
        lines.append("")
        lines.append("| Reach floor | Bonus marks |")
        lines.append("|---:|---:|")
        for floor, marks in c["milestones"]:
            lines.append(f"| {floor} | **{commafy(marks)}** |")
    return "\n".join(lines)


# ---------------------------------------------------------------------------

_PAGE = """# The Voidspire

A spire bored down into a sealed nightmare, and now it never ends. The
**Voidspire** is an endless, floor-by-floor gauntlet — descend as far as you
can, and your deepest floor is your score on the leaderboard. A single wipe
ends the run, so press your luck.

!!! tip "Summary"
    An endless descent at the Warden in {zone} — clear floor after floor, your
    deepest floor is your leaderboard score, and one wipe ends the run.

## Where to start

<!-- DOCGEN:BEGIN id="voidspire-access" -->
<!-- DOCGEN:END id="voidspire-access" -->

## How the floors scale

<!-- DOCGEN:BEGIN id="voidspire-scaling" -->
<!-- DOCGEN:END id="voidspire-scaling" -->

## Affixes

<!-- DOCGEN:BEGIN id="voidspire-affixes" -->
<!-- DOCGEN:END id="voidspire-affixes" -->

## Rewards

<!-- DOCGEN:BEGIN id="voidspire-rewards" -->
<!-- DOCGEN:END id="voidspire-rewards" -->

Marks spend across the same Hunting League economy as the rest of your
progression. Climb carefully — there is no checkpoint, and the leaderboard only
remembers how deep you dared to go.
"""


def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/voidspire_catalog.lua")
    if src is None:
        print("[voidspire] skip: voidspire_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    c = _parse(text)

    page = docs_dir / "endgame" / "voidspire.md"
    if not page.exists():
        page.parent.mkdir(parents=True, exist_ok=True)
        page.write_text(_PAGE.format(zone=c["zone"]), encoding="utf-8")

    blocks = [
        ("voidspire-access", _render_access(c)),
        ("voidspire-scaling", _render_scaling(c)),
        ("voidspire-affixes", _render_affixes(c)),
        ("voidspire-rewards", _render_rewards(c)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[voidspire] {written}/{len(blocks)} marker block(s) written "
          f"(affixes={len(c['affixes'])}, bands={len(c['bands'])}, "
          f"milestones={len(c['milestones'])})")
