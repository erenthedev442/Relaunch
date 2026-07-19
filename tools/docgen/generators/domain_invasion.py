"""Sync docs/endgame/domain-invasion.md with domain_invasion_catalog.lua.

Domain Invasion fires eight times a day in Escha - Zi'Tah (Dahaks + Azi Dahaka)
and Escha - Ru'Aun (Lamiae + Naga Raja) on alternating 3-hour windows. Five
escalating waves culminate in a boss wave with adds. Rewards: Escha Silt,
Escha Beads, Domain Points (daily cap).

Markers written:
  di-schedule   — UTC window table, zone rotation, warn/grace timing
  di-zones      — per-zone wave ladder + boss for both Zi'Tah and Ru'Aun
  di-rewards    — per-wave silt, victory/timeout rewards, daily cap
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section, commafy


def _first(pattern: str, text: str, default: str = "0") -> str:
    m = re.search(pattern, text)
    return m.group(1) if m else default


def _parse(text: str) -> dict:
    c: dict = {}

    c["warn"]       = int(_first(r"catalog\.warnMinutes\s*=\s*(\d+)", text, "5"))
    c["grace"]      = int(_first(r"catalog\.graceMinutes\s*=\s*(\d+)", text, "10"))
    c["time_limit"] = int(_first(r"catalog\.timeLimitSec\s*=\s*(\d+)", text, "600"))

    # Schedule windows.
    win_block = section(text, "catalog.windows")
    c["windows"] = [
        (int(h), int(mn), int(zi))
        for h, mn, zi in re.findall(
            r"hour\s*=\s*(\d+)\s*,\s*min\s*=\s*(\d+)\s*,\s*zoneIdx\s*=\s*(\d+)",
            win_block,
        )
    ]

    # Zones: extract each zone's label, waves, and boss.
    zones_block = section(text, "catalog.zones")
    zones = []
    # Each zone entry has a label = "..." (double-quoted because of apostrophes).
    for lm in re.finditer(r'label\s*=\s*"([^"]+)"', zones_block):
        zone_label = lm.group(1)
        remaining = zones_block[lm.start():]   # text from this zone's label onward

        waves_block = section(remaining, "waves")
        waves = []
        for wm in re.finditer(
            r"label\s*=\s*'([^']+)'\s*,\s*level\s*=\s*(\d+)", waves_block
        ):
            waves.append({"label": wm.group(1), "level": int(wm.group(2))})

        boss_block = section(waves_block, "boss")
        boss_name  = _first(r"name\s*=\s*'([^']+)'", boss_block) if boss_block else None
        boss_level = int(_first(r"level\s*=\s*(\d+)", boss_block, "0")) if boss_block else None

        zones.append({
            "label":      zone_label,
            "waves":      waves,
            "boss_name":  boss_name,
            "boss_level": boss_level,
        })
    c["zones"] = zones

    # Rewards.
    rw = section(text, "catalog.reward")
    c["per_wave_silt"]   = int(_first(r"perWaveSilt\s*=\s*(\d+)",   rw, "75"))
    c["victory_silt"]    = int(_first(r"victorySilt\s*=\s*(\d+)",   rw, "150"))
    c["victory_beads"]   = int(_first(r"victoryBeads\s*=\s*(\d+)",  rw, "3"))
    c["victory_points"]  = int(_first(r"victoryPoints\s*=\s*(\d+)", rw, "30"))
    c["timeout_silt"]    = int(_first(r"timeoutSilt\s*=\s*(\d+)",   rw, "50"))
    c["timeout_beads"]   = int(_first(r"timeoutBeads\s*=\s*(\d+)",  rw, "1"))
    c["timeout_points"]  = int(_first(r"timeoutPoints\s*=\s*(\d+)", rw, "10"))
    c["daily_cap"]       = int(_first(r"dailyPointCap\s*=\s*(\d+)", rw, "80"))
    return c


def _mins(sec: int) -> str:
    n = sec // 60
    return f"{n} minute" + ("s" if n != 1 else "")


def _render_schedule(c: dict) -> str:
    if not c["windows"]:
        return "_Schedule unavailable._"

    zones = c["zones"]
    win   = c["windows"]

    # Build the window → zone label mapping for the table.
    lines = [
        f"Domain Invasion fires **{len(win)} times per day** (every 3 hours), "
        f"alternating between the two Escha zones:",
        "",
        "| UTC time | Zone |",
        "|---:|---|",
    ]
    for h, mn, zi in win:
        label = zones[zi - 1]["label"] if (zi - 1) < len(zones) else f"Zone {zi}"
        lines.append(f"| {h:02d}:{mn:02d} UTC | **{label}** |")

    lines += [
        "",
        f"A server-wide warning broadcasts **{c['warn']} minutes** before each window. "
        f"The event only fires after at least one player explicitly opts in with "
        f"`!diwarp`; merely doing Hunting League content in the zone does not count. "
        f"It waits up to **{c['grace']} minutes** for a volunteer. `!diwarp` moves "
        f"volunteers to the isolated invasion rally point.",
    ]
    return "\n".join(lines)


def _render_zones(c: dict) -> str:
    if not c["zones"]:
        return "_Zone data unavailable._"

    blocks = []
    for z in c["zones"]:
        lines = [
            f"### {z['label']}",
            "",
            "| Wave | Enemy level |",
            "|---|---:|",
        ]
        for w in z["waves"]:
            lines.append(f"| **{w['label']}** | {w['level']} |")
        if z.get("boss_name"):
            lines.append(f"| **{z['boss_name']}** (boss) | {z['boss_level']} |")
        blocks.append("\n".join(lines))

    time_str = _mins(c["time_limit"])
    blocks.append(
        f"Each assault is **five escalating waves**, ending in a boss wave that "
        f"brings adds alongside the named NM. Wave count scales with "
        f"attendance — more defenders means more enemies per wave. "
        f"Clear all five waves within **{time_str}** to claim victory."
    )
    return "\n\n".join(blocks)


def _render_rewards(c: dict) -> str:
    lines = [
        "Rewards go to every player in the zone at the relevant moment. "
        "Domain Points are capped per UTC day — you can keep earning Silt and Beads "
        "after the cap, but no more Domain Points until the next day.",
        "",
        "| Outcome | Escha Silt | Escha Beads | Domain Points |",
        "|---|---:|---:|---:|",
        f"| **Wave clear** (per wave) | {commafy(c['per_wave_silt'])} | — | — |",
        (
            f"| **Victory** (all waves + boss killed) "
            f"| {commafy(c['victory_silt'])} "
            f"| {commafy(c['victory_beads'])} "
            f"| {commafy(c['victory_points'])} |"
        ),
        (
            f"| **Time expired** (consolation) "
            f"| {commafy(c['timeout_silt'])} "
            f"| {commafy(c['timeout_beads'])} "
            f"| {commafy(c['timeout_points'])} |"
        ),
        "",
        f"**Daily Domain Point cap: {commafy(c['daily_cap'])} per character.** "
        f"On a perfect run (victory in both zones per day) you would earn "
        f"{commafy(c['victory_points'] * len(c['windows']) // 2)} — "
        f"well above the cap, so {commafy(c['daily_cap'])} is the real ceiling. "
        f"Spend Domain Points at the Domain Invasion exchange NPC in the hub.",
    ]
    return "\n".join(lines)


# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/domain_invasion_catalog.lua")
    if src is None:
        print("[domain_invasion] skip: domain_invasion_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    c = _parse(text)

    page = docs_dir / "endgame" / "domain-invasion.md"
    blocks = [
        ("di-schedule", _render_schedule(c)),
        ("di-zones",    _render_zones(c)),
        ("di-rewards",  _render_rewards(c)),
    ]
    written = sum(
        1 for marker, content in blocks if write_between_markers(page, marker, content)
    )
    zones_n = len(c["zones"])
    waves_n = sum(len(z["waves"]) for z in c["zones"])
    print(
        f"[domain_invasion] {written}/{len(blocks)} marker block(s) written "
        f"(zones={zones_n}, waves={waves_n}, windows={len(c['windows'])})"
    )
