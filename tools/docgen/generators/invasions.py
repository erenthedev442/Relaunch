"""Sync docs/endgame/invasions.md with invasion_catalog.lua.

Scheduled Invasions are a Besieged-style outpost defense in Al Zahbi: twice a
day the Voidsent assault the hub in escalating waves that scale with how many
defenders turn up, capped by a boss. The schedule (UTC windows), the warn/grace
timing, the wave ladder (label + level), the time limit, and the mark/Infamy/
seal rewards all come from the catalog so re-tuning any of them updates the page.

Markers written:
  invasions-schedule  — the daily UTC windows + warn/grace timing
  invasions-waves     — the wave ladder (label + level) ending in the boss
  invasions-scaling   — attendance scaling + the overall time limit
  invasions-rewards   — marks per wave, victory marks + Infamy, the gold-seal chance
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section, ints, commafy


def _first(pattern: str, text: str, default: str):
    m = re.search(pattern, text)
    return m.group(1) if m else default


def _parse(text: str) -> dict:
    c: dict = {}

    # Schedule windows: list of { hour = H, min = M }.
    win = section(text, "catalog.windows")
    c["windows"] = [(int(h), int(mn)) for h, mn in
                    re.findall(r"hour\s*=\s*(\d+)\s*,\s*min\s*=\s*(\d+)", win)]
    c["warn"]  = int(_first(r"catalog\.warnMinutes\s*=\s*(\d+)", text, "5"))
    c["grace"] = int(_first(r"catalog\.graceMinutes\s*=\s*(\d+)", text, "10"))
    c["time_limit"] = int(_first(r"catalog\.timeLimitSec\s*=\s*(\d+)", text, "900"))

    # Waves: each block carries label, level, base/perDefender, and an optional
    # nested boss. We only surface label + level + boss to players.
    waves_block = section(text, "catalog.waves")
    waves = []
    for wm in re.finditer(r"label\s*=\s*'([^']+)'\s*,\s*level\s*=\s*(\d+)", waves_block):
        waves.append({"label": wm.group(1), "level": int(wm.group(2))})
    c["waves"] = waves

    boss = section(waves_block, "boss")
    if boss:
        c["boss_name"] = _first(r"name\s*=\s*'([^']+)'", boss, "Voidsent Warlord")
        c["boss_level"] = int(_first(r"level\s*=\s*(\d+)", boss, "165"))
    else:
        c["boss_name"], c["boss_level"] = None, None

    # Rewards.
    rw = section(text, "catalog.reward")
    c["per_wave"]    = int(_first(r"perWaveMarks\s*=\s*(\d+)", rw, "200"))
    c["victory"]     = int(_first(r"victoryMarks\s*=\s*(\d+)", rw, "1500"))
    c["infamy"]      = int(_first(r"victoryInfamy\s*=\s*(\d+)", rw, "400"))
    c["fail"]        = int(_first(r"failMarks\s*=\s*(\d+)", rw, "200"))

    gold = section(rw, "victoryGoldSeal")
    c["gold_chance"] = int(_first(r"chancePercent\s*=\s*(\d+)", gold, "20")) if gold else None
    return c


def _fmt_window(h: int, m: int) -> str:
    return f"{h:02d}:{m:02d} UTC"


def _mins(seconds: int) -> str:
    if seconds % 60 == 0:
        n = seconds // 60
        return f"{n} minute" + ("s" if n != 1 else "")
    return f"{seconds} seconds"


# ---------------------------------------------------------------------------

def _render_schedule(c: dict) -> str:
    if not c["windows"]:
        return "_Schedule unavailable._"
    times = " and ".join(_fmt_window(h, m) for h, m in c["windows"])
    lines = [
        f"The Voidsent strike **{_count_word(len(c['windows']))} a day**, at "
        f"**{times}**.",
        "",
        f"- A server-wide warning shouts **{c['warn']} minutes** before each window "
        f"so you can rally at Al Zahbi.",
        f"- The assault only fires if **at least one defender** is standing in Al Zahbi "
        f"when the window opens — it stays armed for up to **{c['grace']} minutes** "
        f"waiting for someone to show. No defenders, no invasion.",
    ]
    return "\n".join(lines)


def _count_word(n: int) -> str:
    return {1: "once", 2: "twice", 3: "three times"}.get(n, f"{n} times")


def _render_waves(c: dict) -> str:
    lines = [
        "| Wave | Enemy level |",
        "|---|---:|",
    ]
    for w in c["waves"]:
        lines.append(f"| **{w['label']}** | {w['level']} |")
    if c.get("boss_name"):
        lines.append(f"| **{c['boss_name']}** (boss) | {c['boss_level']} |")
    return "\n".join(lines)


def _render_scaling(c: dict) -> str:
    return (
        f"The more defenders who answer the call, the **larger each wave** — bring "
        f"friends and the horde swells to match. The whole assault, from the first "
        f"wave to the boss, must be cleared within **{_mins(c['time_limit'])}**. Hold "
        f"the line and fell the boss before the clock runs out to claim victory."
    )


def _render_rewards(c: dict) -> str:
    lines = [
        f"Every defender present is paid out — credit goes to anyone in Al Zahbi at the "
        f"relevant moment:",
        "",
        f"- **{commafy(c['per_wave'])} Hunt Marks** for each wave cleared.",
        f"- **{commafy(c['victory'])} Hunt Marks + {commafy(c['infamy'])} Infamy** on a "
        f"full victory (the boss falls). This is one of the few sources of Infamy "
        f"outside the dungeons.",
        f"- **{commafy(c['fail'])} Hunt Marks** as a consolation if the clock beats the "
        f"defense.",
    ]
    lines.append("")
    if c.get("gold_chance") and c["gold_chance"] >= 100:
        medal_text = ("Victory also drops gear-vendor **medals** — a guaranteed Kindreds Medal "
                      "haul, plus a **guaranteed Demons Medal** drop.")
    elif c.get("gold_chance"):
        medal_text = (f"Victory also drops gear-vendor **medals** — a guaranteed Kindreds Medal "
                      f"haul, plus a **~1-in-{_one_in(c['gold_chance'])}** chance at a Demons Medal "
                      f"for the very best gear.")
    else:
        medal_text = ("Victory also drops gear-vendor **medals** — a guaranteed Kindreds Medal haul.")
    lines.append(medal_text)
    return "\n".join(lines)


def _one_in(chance_pct: int) -> int:
    return max(1, round(100 / chance_pct)) if chance_pct else 5


# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/invasion_catalog.lua")
    if src is None:
        print("[invasions] skip: invasion_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    c = _parse(text)

    page = docs_dir / "endgame" / "invasions.md"
    blocks = [
        ("invasions-schedule", _render_schedule(c)),
        ("invasions-waves", _render_waves(c)),
        ("invasions-scaling", _render_scaling(c)),
        ("invasions-rewards", _render_rewards(c)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[invasions] {written}/{len(blocks)} marker block(s) written "
          f"(windows={len(c['windows'])}, waves={len(c['waves'])}+boss)")
