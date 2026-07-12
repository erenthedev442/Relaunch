"""Sync docs/endgame/chocobo-derby.md with chocobo_derby_catalog.lua.

Bet on chocobo races at the Race Caller in the Celennia Memorial Library; if your own raised chocobo
is strong enough, enter it as a runner. The bet tiers, the field, the
house cut / payout floor, the own-bird requirement + win bonus, and the race
length all come from the catalog so re-tuning the derby updates the guide.

Markers written:
  chocobo-derby-access   — Race Caller NPC + zone line
  chocobo-derby-betting  — bet tiers + how odds/payouts work
  chocobo-derby-field    — field size + stable names + race length
  chocobo-derby-ownbird  — entering your own raised chocobo
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


def _parse(text: str) -> dict:
    c: dict = {}

    bets = section(text, "catalog.bets")
    c["bets"] = ints(bets)

    c["fieldSize"] = int(float(_first(r"catalog\.fieldSize\s*=\s*(\d+)", text, "6")))

    stable = section(text, "catalog.stable")
    c["stable"] = re.findall(r"'([^']+)'", stable)

    own = section(text, "catalog.ownBird")
    c["minStage"] = int(float(_first(r"minStage\s*=\s*(\d+)", own, "3")))
    c["winBonus"] = int(float(_first(r"winBonusPct\s*=\s*([0-9.]+)", own, "25")))

    c["houseFactor"] = float(_first(r"catalog\.houseFactor\s*=\s*([0-9.]+)", text, "0.85"))
    c["minPayout"] = float(_first(r"catalog\.minPayout\s*=\s*([0-9.]+)", text, "1.15"))

    race = section(text, "catalog.race")
    c["ticks"] = int(float(_first(r"ticks\s*=\s*(\d+)", race, "4")))
    c["tickSec"] = int(float(_first(r"tickSec\s*=\s*(\d+)", race, "5")))
    return c


_STAGES = {1: "hatchling", 2: "colt", 3: "adolescent", 4: "adult"}


def _stage_name(n: int) -> str:
    return _STAGES.get(n, f"stage {n}")


# ---------------------------------------------------------------------------

def _render_access(c: dict) -> str:
    return ("The **Race Caller** stands in **{{npc:chocobo_derby}}** (`!hub`). "
            "Step up to check the odds board, place a bet, and watch the race "
            "play out.")


def _render_betting(c: dict) -> str:
    tiers = " / ".join(commafy(b) for b in c["bets"])
    house_cut = round((1.0 - c["houseFactor"]) * 100)
    lines = []
    lines.append(f"**Stakes:** {tiers} gil.")
    lines.append("")
    lines.append("Each runner carries odds set by its hidden strength: the "
                 "long-shots pay the most, the favourites the least. The house "
                 f"keeps about **{house_cut}%** of the fair payout as its cut, and "
                 f"even a heavy favourite always returns at least "
                 f"**{c['minPayout']:g}×** your stake when it wins. Back the wrong "
                 "bird and you lose your bet.")
    return "\n".join(lines)


def _render_field(c: dict) -> str:
    lines = []
    runners = c["fieldSize"]
    lines.append(f"Every race fields **{runners} runners**. If you aren't racing "
                 f"a chocobo of your own, they're all from the house stable; if "
                 f"you are, your bird takes one of the gates. The stable regulars "
                 f"are drawn from this roster:")
    lines.append("")
    cols = 3
    row = []
    for i, name in enumerate(c["stable"], start=1):
        row.append(name)
        if i % cols == 0:
            lines.append("- " + " · ".join(row))
            row = []
    if row:
        lines.append("- " + " · ".join(row))
    secs = c["ticks"] * c["tickSec"]
    lines.append("")
    lines.append(f"A race runs about **{secs} seconds** of live commentary before "
                 f"the winner crosses the line.")
    return "\n".join(lines)


def _render_ownbird(c: dict) -> str:
    stage = _stage_name(c["minStage"])
    lines = []
    lines.append(f"Raised a chocobo of your own? Once it reaches the **{stage}** "
                 f"stage (or older) you can enter it as a runner instead of just "
                 f"betting on the stable.")
    lines.append("")
    lines.append("Your bird races on its real ability — its strength, endurance, "
                 "and how much affection you've raised it with all feed its hidden "
                 "racing form, so a well-loved, well-trained chocobo genuinely "
                 "out-classes the house runners and races at shorter odds.")
    lines.append("")
    lines.append(f"And there's a reason to root for your own: winning a race on "
                 f"**your** chocobo pays an extra **{c['winBonus']}%** on top of the "
                 f"normal payout.")
    return "\n".join(lines)


# ---------------------------------------------------------------------------

_PAGE = """# Chocobo Derby

In **{{npc:chocobo_derby}}**, the **Race Caller** runs the races. Put gil on a runner and
watch it play out — and if you've raised a chocobo of your own that's tough
enough, line it up at the gate and bet on yourself.

!!! tip "Summary"
    Bet gil on chocobo races at the Race Caller in {{npc:chocobo_derby}}; raise a strong
    enough chocobo of your own and you can enter it as a runner for a bigger
    payout.

## Where to play

<!-- DOCGEN:BEGIN id="chocobo-derby-access" -->
<!-- DOCGEN:END id="chocobo-derby-access" -->

## Placing a bet

<!-- DOCGEN:BEGIN id="chocobo-derby-betting" -->
<!-- DOCGEN:END id="chocobo-derby-betting" -->

## The field

<!-- DOCGEN:BEGIN id="chocobo-derby-field" -->
<!-- DOCGEN:END id="chocobo-derby-field" -->

## Racing your own chocobo

<!-- DOCGEN:BEGIN id="chocobo-derby-ownbird" -->
<!-- DOCGEN:END id="chocobo-derby-ownbird" -->

Like the casino, the derby is a long-run gil sink — the house keeps its cut
over time — but a well-judged bet, or a champion bird of your own, can still pay
off big on the day.
"""


def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/chocobo_derby_catalog.lua")
    if src is None:
        print("[chocobo-derby] skip: chocobo_derby_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    c = _parse(text)

    page = docs_dir / "endgame" / "chocobo-derby.md"
    if not page.exists():
        page.parent.mkdir(parents=True, exist_ok=True)
        page.write_text(_PAGE, encoding="utf-8")

    blocks = [
        ("chocobo-derby-access", _render_access(c)),
        ("chocobo-derby-betting", _render_betting(c)),
        ("chocobo-derby-field", _render_field(c)),
        ("chocobo-derby-ownbird", _render_ownbird(c)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[chocobo-derby] {written}/{len(blocks)} marker block(s) written "
          f"(bets={len(c['bets'])}, stable={len(c['stable'])}, field={c['fieldSize']})")
