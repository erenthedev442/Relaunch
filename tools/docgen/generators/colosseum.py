"""Sync docs/endgame/colosseum.md with colosseum_catalog.lua.

The Colosseum is an asynchronous ranked arena in Leafallia: enroll a champion,
then duel level-scaled AI replicas of other champions to climb an Elo ladder.
The NPC placement, the Elo numbers (start/floor), the duel rules (countdown,
time limit, once-per-day), and the Hunt Mark payouts all come from the catalog
so re-tuning any of them updates the published page.

Markers written:
  colosseum-access   — NPC + zone line
  colosseum-duel     — how a duel works (countdown, time limit, daily limit)
  colosseum-ladder   — the Elo rating system + replica scaling, in player terms
  colosseum-rewards  — Hunt Mark win/loss payouts
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

    # NPC name is hard-coded in the module, not the catalog; the catalog only
    # carries placement. The Arena Herald is the fixed name (see the header).
    c["npc"] = "Arena Herald"

    # Elo ladder.
    elo = section(text, "catalog.elo")
    c["elo_start"] = int(_first(r"start\s*=\s*(\d+)", elo, "1200"))
    c["elo_floor"] = int(_first(r"floor\s*=\s*(\d+)", elo, "800"))

    # Replica scaling — we only surface the readable extremes, never the mod rows.
    rep = section(text, "catalog.replica")
    c["lvl_base"]   = int(_first(r"levelBase\s*=\s*(\d+)", rep, "99"))
    c["lvl_cap"]    = int(_first(r"levelCap\s*=\s*(\d+)", rep, "205"))
    c["hp_min"]     = float(_first(r"hpMin\s*=\s*([0-9.]+)", rep, "2.0"))
    c["hp_max"]     = float(_first(r"hpMax\s*=\s*([0-9.]+)", rep, "10.0"))

    # Duel rules.
    duel = section(text, "catalog.duel")
    c["countdown"]  = int(_first(r"countdownSec\s*=\s*(\d+)", duel, "3"))
    c["time_limit"] = int(_first(r"timeLimitSec\s*=\s*(\d+)", duel, "300"))
    c["per_day"]    = bool(re.search(r"perOpponentPerDay\s*=\s*true", duel))

    # Rewards (Hunt Marks).
    rw = section(text, "catalog.reward")
    c["win_marks"]  = int(_first(r"winBase\s*=\s*(\d+)", rw, "150"))
    c["loss_marks"] = int(_first(r"lossMarks\s*=\s*(\d+)", rw, "25"))
    c["underdog"]   = bool(re.search(r"underdogDiv\s*=\s*\d+", rw))
    return c


def _mins(seconds: int) -> str:
    if seconds % 60 == 0:
        m = seconds // 60
        return f"{m} minute" + ("s" if m != 1 else "")
    return f"{seconds} seconds"


# ---------------------------------------------------------------------------

def _render_access(c: dict) -> str:
    return (f"The **{c['npc']}** stands in **Leafallia** (`!leaf`) — talk to them to enroll "
            f"your champion on the ladder, browse the roster of rivals, and "
            f"accept a duel.")


def _render_duel(c: dict) -> str:
    lines = [
        f"When you challenge a champion, you fight a level-scaled **replica** of "
        f"them — an AI stand-in, so the rival doesn't need to be online.",
        "",
        f"- A **{c['countdown']}-second** countdown gives you a moment to ready up "
        f"before the replica appears.",
        f"- You have **{_mins(c['time_limit'])}** to win. Run out the clock and the "
        f"duel is forfeit.",
    ]
    if c.get("per_day"):
        lines.append(
            "- You can challenge each champion **once per day** (resets at "
            "00:00 UTC) — pick your matches and come back tomorrow for a rematch."
        )
    return "\n".join(lines)


def _render_ladder(c: dict) -> str:
    return (
        f"Every champion starts at a rating of **{commafy(c['elo_start'])}** and can "
        f"never fall below **{commafy(c['elo_floor'])}**. Win a duel and your rating "
        f"climbs while your opponent's slips; the ladder is zero-sum, so the only way "
        f"up is through other champions.\n\n"
        f"A replica scales to the **rival's rating**, not their gear — a higher-rated "
        f"champion is proof of a dangerous fighter. The tougher the rating, the higher "
        f"the replica's **level** (from {c['lvl_base']} up to a cap of {c['lvl_cap']}) "
        f"and the deeper its **HP pool** ({_g(c['hp_min'])}× to {_g(c['hp_max'])}× a "
        f"normal mob's health). Climbing the ladder literally makes your own champion "
        f"harder for others to beat."
    )


def _render_rewards(c: dict) -> str:
    lines = [
        f"Duels pay out in **Hunt Marks**, the server's main currency:",
        "",
        f"- **Win:** {commafy(c['win_marks'])} marks"
        + (" — plus a bonus for **punching up** and beating a higher-rated champion."
           if c.get("underdog") else "."),
        f"- **Loss:** {commafy(c['loss_marks'])} marks as a consolation, so a defeat "
        f"is never a total loss.",
    ]
    return "\n".join(lines)


def _g(v: float) -> str:
    return f"{v:g}"


# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/colosseum_catalog.lua")
    if src is None:
        print("[colosseum] skip: colosseum_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    c = _parse(text)

    page = docs_dir / "endgame" / "colosseum.md"
    blocks = [
        ("colosseum-access", _render_access(c)),
        ("colosseum-duel", _render_duel(c)),
        ("colosseum-ladder", _render_ladder(c)),
        ("colosseum-rewards", _render_rewards(c)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[colosseum] {written}/{len(blocks)} marker block(s) written "
          f"(start={c['elo_start']}, floor={c['elo_floor']})")
