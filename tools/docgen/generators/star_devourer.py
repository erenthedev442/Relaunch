"""Sync docs/endgame/star-devourer.md with raid_catalog.lua.

The Star-Devourer is a server-shared, multi-phase raid boss at Escha-RuAun with
a weekly reward lockout. The boss scale (level + HP multiplier), the opening
stance dance, the HP-threshold phases (tendril adds, dispel sweep, fury), the
soft-enrage timer, and the weekly/repeat rewards all come from the catalog so
re-tuning any of them updates the published page.

Markers written:
  star-devourer-access     — where/how to start the fight
  star-devourer-scale      — the boss's level + HP scale, in player terms
  star-devourer-mechanics  — stance dance + HP-threshold phases + soft enrage
  star-devourer-rewards    — weekly marks + Infamy, smaller repeat-kill marks
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

    # Boss identity + scale.
    boss = section(text, "catalog.boss")
    c["boss_name"]  = _first(r"name\s*=\s*'([^']+)'", boss, "The Star-Devourer")
    c["boss_level"] = int(_first(r"level\s*=\s*(\d+)", boss, "200"))
    c["boss_hp"]    = float(_first(r"hpMult\s*=\s*([0-9.]+)", boss, "45.0"))

    # Stance dance.
    st = section(text, "catalog.stance")
    c["stance_start"]  = int(_first(r"startHpp\s*=\s*(\d+)", st, "90"))
    c["stance_period"] = int(_first(r"periodSec\s*=\s*(\d+)", st, "45"))

    # HP phases — parse each block's hp + action (+ count where relevant).
    phases_block = section(text, "catalog.phases")
    phases = []
    # Each phase is a top-level { ... } inside the list; pull hp/action/count.
    for pm in re.finditer(r"\{\s*hp\s*=\s*(\d+)\s*,\s*action\s*=\s*'([^']+)'([^}]*)\}",
                          phases_block):
        hp = int(pm.group(1))
        action = pm.group(2)
        tail = pm.group(3)
        cnt_m = re.search(r"count\s*=\s*(\d+)", tail)
        phases.append({
            "hp": hp,
            "action": action,
            "count": int(cnt_m.group(1)) if cnt_m else None,
        })
    c["phases"] = phases

    # Soft enrage.
    se = section(text, "catalog.softEnrage")
    c["enrage_sec"] = int(_first(r"sec\s*=\s*(\d+)", se, "720"))

    # Rewards.
    rw = section(text, "catalog.reward")
    c["weekly_marks"] = int(_first(r"weeklyMarks\s*=\s*(\d+)", rw, "2500"))
    c["weekly_infamy"] = int(_first(r"weeklyInfamy\s*=\s*(\d+)", rw, "500"))
    c["repeat_marks"] = int(_first(r"repeatMarks\s*=\s*(\d+)", rw, "250"))
    return c


def _mins(seconds: int) -> str:
    if seconds % 60 == 0:
        n = seconds // 60
        return f"{n} minute" + ("s" if n != 1 else "")
    return f"{seconds} seconds"


def _g(v: float) -> str:
    return f"{v:g}"


# ---------------------------------------------------------------------------

def _render_access(c: dict) -> str:
    return (
        f"Seek out the **Voidgate Sentinel** in **Escha-RuAun**, standing beside the "
        f"Voidspire Warden. Speak to them to summon **{c['boss_name']}** — the fight is "
        f"server-shared, so anyone in the area can join the brawl. It's a true raid: "
        f"bring a crowd."
    )


def _render_scale(c: dict) -> str:
    return (
        f"**{c['boss_name']}** is a **level {c['boss_level']}** behemoth with a colossal "
        f"health pool — roughly **{_g(c['boss_hp'])}× a normal boss's HP**. This is a "
        f"long, phase-driven endurance fight, not a quick burn — expect to work through "
        f"every stage below."
    )


def _render_mechanics(c: dict) -> str:
    # Map the HP-threshold phases to readable lines.
    tendril_hps = [p["hp"] for p in c["phases"] if p["action"] == "tendrils"]
    dispel = next((p for p in c["phases"] if p["action"] == "dispel"), None)
    fury = next((p for p in c["phases"] if p["action"] == "fury"), None)

    lines = []

    # Stance dance.
    lines.append(
        f"**The stance dance — from {c['stance_start']}% HP.** Once the boss drops to "
        f"{c['stance_start']}% it begins alternating between two stances roughly every "
        f"**{_mins(c['stance_period'])}**:"
    )
    lines.append("")
    lines.append(
        "- **Aegis Stance** — blades glance off (near-immune to physical), but magic "
        "rips through."
    )
    lines.append(
        "- **Umbral Stance** — spells gutter out (near-immune to magic), but steel bites "
        "deep."
    )
    lines.append("")
    lines.append(
        "Watch the on-screen call-out and switch your damage type to match, or your "
        "numbers will vanish."
    )
    lines.append("")

    # Tendril phases.
    if tendril_hps:
        hp_list = " and ".join(f"{h}%" for h in tendril_hps)
        lines.append(
            f"**The tendrils — at {hp_list} HP.** The Devourer spawns **Starspawn "
            f"Tendrils** and starts rapidly healing itself while they live — the "
            f"tendrils feed the maw. Cut them down fast to stop the heal and resume "
            f"your assault."
        )
        lines.append("")

    # Dispel sweep.
    if dispel:
        lines.append(
            f"**Dispel sweep — at {dispel['hp']}% HP.** A wave of unbeing strips "
            f"protective buffs from everyone engaged. Be ready to re-buff and press on."
        )
        lines.append("")

    # Fury.
    if fury:
        lines.append(
            f"**Final fury — at {fury['hp']}% HP.** The boss permanently spikes its "
            f"attack and attack speed for the last stretch — the closing burn is a "
            f"dangerous one."
        )
        lines.append("")

    # Soft enrage.
    lines.append(
        f"**Soft enrage — {_mins(c['enrage_sec'])} in.** If the fight drags on this "
        f"long, a massive permanent buff lands and the encounter becomes a race. Kill "
        f"it before the clock turns the Devourer untouchable."
    )

    return "\n".join(lines)


def _render_rewards(c: dict) -> str:
    return (
        f"Rewards are on a **weekly lockout** (resetting Monday 00:00 UTC):\n\n"
        f"- **First kill of the week:** {commafy(c['weekly_marks'])} Hunt Marks + "
        f"{commafy(c['weekly_infamy'])} Infamy.\n"
        f"- **Repeat kills the same week:** {commafy(c['repeat_marks'])} Hunt Marks as a "
        f"consolation, so it's always worth helping your friends down it again.\n\n"
        f"You must be near the boss when it dies to get credit."
    )


# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/raid_catalog.lua")
    if src is None:
        print("[star-devourer] skip: raid_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    c = _parse(text)

    page = docs_dir / "endgame" / "star-devourer.md"
    blocks = [
        ("star-devourer-access", _render_access(c)),
        ("star-devourer-scale", _render_scale(c)),
        ("star-devourer-mechanics", _render_mechanics(c)),
        ("star-devourer-rewards", _render_rewards(c)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[star-devourer] {written}/{len(blocks)} marker block(s) written "
          f"(level={c['boss_level']}, phases={len(c['phases'])})")
