"""Sync docs/endgame/the-gauntlet.md with gauntlet_catalog.lua.

The Gauntlet is a 10-level mandatory solo challenge (no safe path) in
Riverne Site A01. HP grows by a fixed factor (HP_GROWTH) each level;
all NMs are a fixed mob level (NM_LEVEL). Per-level rewards and milestone
bonuses are also catalog-driven.

Markers written:
  gauntlet-levels         — NM roster (name, fixed mob level, HP)
  gauntlet-rewards        — final clear (level-10) jackpot table
  gauntlet-level-rewards  — per-level reward table (levels 1-9 NM kill)
  gauntlet-milestones     — milestone bonus table (levels 3, 6, 9)
"""
from __future__ import annotations

import math
import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import commafy


def _first(pattern: str, text: str, default: str) -> str:
    m = re.search(pattern, text)
    return m.group(1) if m else default


def _int(pattern: str, text: str, default: int) -> int:
    return int(float(_first(pattern, text, str(default))))


def _float(pattern: str, text: str, default: float) -> float:
    return float(_first(pattern, text, str(default)))


def _fmt_hp(hp: int) -> str:
    """Human-readable HP (e.g. 50,000,000 -> '50.0M')."""
    if hp >= 1_000_000:
        return f"{hp / 1_000_000:.1f}M"
    if hp >= 1_000:
        return f"{hp / 1_000:.0f}k"
    return str(hp)


def _fmt_gil(gil: int) -> str:
    if gil >= 1_000_000:
        v = gil / 1_000_000
        if v == int(v):
            return f"{int(v)}M"
        return f"{v:.1f}M"
    if gil >= 1_000:
        return f"{gil // 1_000}k"
    return str(gil)


def _parse(text: str) -> dict:
    c: dict = {}

    c["base_hp"]   = _int(r"NM_BASE_HP\s*=\s*(\d+)", text, 50_000_000)
    c["hp_growth"] = _float(r"HP_GROWTH\s*=\s*([\d.]+)", text, 1.166)
    c["nm_level"]  = _int(r"NM_LEVEL\s*=\s*(\d+)", text, 99)

    # NM pool: [level] = { ..., name = 'Name' }
    nms: dict[int, str] = {}
    for m in re.finditer(r"\[(\d+)\]\s*=\s*\{[^}]*name\s*=\s*'([^']+)'", text):
        nms[int(m.group(1))] = m.group(2)
    c["nms"] = nms

    # Final (level-10) jackpot reward
    rw_blk = re.search(r"FINAL_REWARD\s*=\s*\{([^}]*)\}", text)
    blk = rw_blk.group(1) if rw_blk else ""
    c["final_gil"]    = _int(r"gil\s*=\s*(\d+)", blk, 5_000_000)
    c["final_pp"]     = _int(r"\bpp\s*=\s*(\d+)", blk, 500)
    c["final_infamy"] = _int(r"infamy\s*=\s*(\d+)", blk, 500)

    # LEVEL_REWARD(level): extract the per-unit multipliers
    lr_blk = re.search(
        r"function\s+C\.LEVEL_REWARD\s*\(level\)\s*\n\s*return\s*\{([^}]*)\}",
        text, re.DOTALL,
    )
    lr_text = lr_blk.group(1) if lr_blk else ""
    c["lr_gil"]    = _int(r"gil\s*=\s*level\s*\*\s*(\d+)",    lr_text, 50_000)
    c["lr_infamy"] = _int(r"infamy\s*=\s*level\s*\*\s*(\d+)", lr_text, 10)
    c["lr_pp"]     = _int(r"\bpp\s*=\s*level\s*\*\s*(\d+)",   lr_text, 1)

    # MILESTONE_REWARDS: extract the outer brace block, then parse inner entries.
    # A simple regex scan of everything-after-MILESTONE_REWARDS would also match
    # the holdFireCfg messages table (which has [1]..[10] entries), so we must
    # brace-balance to get only the MILESTONE_REWARDS block.
    milestones: dict[int, dict] = {}
    ms_hdr = re.search(r"C\.MILESTONE_REWARDS\s*=\s*\{", text)
    if ms_hdr:
        i, depth, start = ms_hdr.end() - 1, 0, ms_hdr.end() - 1
        while i < len(text):
            ch = text[i]
            if ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    ms_block = text[start + 1 : i]
                    for blk_m in re.finditer(r"\[(\d+)\]\s*=\s*\{([^}]*)\}", ms_block):
                        lv = int(blk_m.group(1))
                        inner = blk_m.group(2)
                        milestones[lv] = {
                            "gil":    _int(r"gil\s*=\s*(\d+)", inner, 0),
                            "pp":     _int(r"\bpp\s*=\s*(\d+)", inner, 0),
                            "infamy": _int(r"infamy\s*=\s*(\d+)", inner, 0),
                        }
                    break
            i += 1
    c["milestones"] = milestones

    return c


def _nm_hp(c: dict, level: int) -> int:
    return math.floor(c["base_hp"] * (c["hp_growth"] ** (level - 1)))


def _render_levels(c: dict) -> str:
    nms      = c["nms"]
    nm_level = c["nm_level"]
    n_levels = max(nms.keys()) if nms else 10

    lines = [
        "| Level | NM | Mob level | HP |",
        "|---:|---|---:|---:|",
    ]
    for lv in range(1, n_levels + 1):
        name   = nms.get(lv, f"Level {lv} NM")
        hp     = _nm_hp(c, lv)
        label  = " *(final)*" if lv == n_levels else ""
        lines.append(f"| {lv} | **{name}**{label} | {nm_level} | {_fmt_hp(hp)} |")

    growth_pct = (c["hp_growth"] - 1) * 100
    lines.append("")
    lines.append(
        f"HP grows **{growth_pct:.1f}%** each level. "
        f"Every NM is **Lv{nm_level}**; difficulty scales through stats and hardcore mechanics."
    )
    return "\n".join(lines)


def _render_rewards(c: dict) -> str:
    gil_str = f"{commafy(c['final_gil'])} ({_fmt_gil(c['final_gil'])})"
    lines = [
        "| Reward | Amount |",
        "|---|---:|",
        f"| **Gil** | {gil_str} |",
        f"| **Paragon Points** | {c['final_pp']:,} |",
        f"| **Infamy** | {c['final_infamy']:,} |",
        "| **Hall of Champions NPC** | Permanent |",
    ]
    return "\n".join(lines)


def _render_level_rewards(c: dict) -> str:
    nms      = c["nms"]
    n_levels = max(nms.keys()) if nms else 10
    n_fights = n_levels - 1  # levels 1-9 (level 10 pays final reward)
    milestones = c["milestones"]

    lines = [
        "| Level | NM | Gil | PP | Infamy | Milestone bonus |",
        "|---:|---|---:|---:|---:|---|",
    ]
    for lv in range(1, n_fights + 1):
        name = nms.get(lv, f"Level {lv}")
        gil    = lv * c["lr_gil"]
        pp     = lv * c["lr_pp"]
        infamy = lv * c["lr_infamy"]
        ms = milestones.get(lv)
        if ms:
            ms_str = (
                f"+{_fmt_gil(ms['gil'])} gil, "
                f"+{ms['pp']} PP, "
                f"+{ms['infamy']} Infamy"
            )
        else:
            ms_str = "—"
        lines.append(
            f"| {lv} | {name} | {_fmt_gil(gil)} | {pp} | {infamy} | {ms_str} |"
        )

    lines.append("")
    lines.append(
        "Each NM kill in levels 1–9 grants a per-level reward. "
        "Milestone bonuses stack on top at levels 3, 6, and 9."
    )
    return "\n".join(lines)


def _render_milestones(c: dict) -> str:
    milestones = c["milestones"]
    nms = c["nms"]
    if not milestones:
        return "_No milestone data found._\n"

    lines = [
        "| Milestone | NM | Bonus gil | Bonus PP | Bonus Infamy |",
        "|---:|---|---:|---:|---:|",
    ]
    for lv in sorted(milestones.keys()):
        ms   = milestones[lv]
        name = nms.get(lv, f"Level {lv}")
        lines.append(
            f"| Level {lv} | {name} | {_fmt_gil(ms['gil'])} | {ms['pp']} | {ms['infamy']} |"
        )
    lines.append("")
    lines.append(
        "Milestone bonuses are paid immediately after the per-level reward "
        "when you defeat the milestone NM."
    )
    return "\n".join(lines)


def _render_mechanics(text: str, c: dict) -> str:
    """Shared combat kit table with the tuned numbers pulled from the catalog
    (enrage window, stance/ranged reductions, drain cadence and scaling), so
    a combat retune lands on the page automatically."""
    enrages = [int(x) for x in re.findall(r"enrage\s*=\s*\{\s*sec\s*=\s*(\d+)", text)]
    drain = re.search(r"drain\s*=\s*\{\s*periodSec\s*=\s*(\d+),\s*heal\s*=\s*level\s*\*\s*(\d+)", text)
    stance_pct = re.search(r"DMGPHYS\]\s*=\s*-(\d+)", text)
    ranged = re.search(r"RANGED_DAMAGE_REDUCTION\s*=\s*-(\d+)", text)
    if not (enrages and drain and stance_pct and ranged):
        raise RuntimeError(
            "gauntlet mechanics parse degraded -- gauntlet_catalog.lua "
            "enrage/drain/stance/ranged format changed, update _render_mechanics."
        )
    n_levels = max(c["nms"]) if c["nms"] else 10
    period, heal_per = int(drain.group(1)), int(drain.group(2))
    sp = int(stance_pct.group(1)) // 100
    rp = int(ranged.group(1)) // 100
    rows = [
        ("Massive stats", "ATT, ACC, DEF, MDEF, and MEVA all scale steeply per "
         "level. Even gear-capped characters will feel the wall."),
        ("Enrage timer", f"After a set time the boss gains additional ATT and "
         f"haste permanently. Ranges from ~{max(enrages)}s at low levels to "
         f"~{min(enrages)}s at level {n_levels}."),
        ("Stance cycling", f"The boss periodically shifts between a "
         f"physical-resist stance (-{sp}% physical damage) and a magic-resist "
         f"stance (-{sp}% magic damage). Watch the chat log and adapt."),
        ("Hold-fire windows", "A warning announces a danger period. If you deal "
         "damage during it, you take a status effect penalty (curse, poison, or "
         "blind depending on the boss). Wait for the window to expire to earn a "
         "defense-down bonus on the boss."),
        ("Crowd control", "Periodic Terror or Silence pulses. Duration scales "
         "with level."),
        ("Self-heal drain", f"The boss heals itself every {period} seconds. "
         f"Heal amount scales from {heal_per // 1000}k at level 1 to "
         f"{heal_per * n_levels // 1000}k at level {n_levels}."),
        ("Phase actions", "At HP thresholds the boss dispels your buffs or "
         "enters a fury state (more ATT + haste). Higher levels have more phases."),
        ("Ranged penalty", f"Ranged damage is reduced by {rp}% outside of "
         f"hold-fire weakness windows. Physical ranged is the intended way to "
         f"use hold-fire timing."),
    ]
    out = ["Every Gauntlet NM has the same shared hardcore kit, scaled by "
           "level. All of these are real combat interactions — no invisible "
           "phantom damage.", "",
           "| Mechanic | What it does |", "|---|---|"]
    for name, desc in rows:
        out.append(f"| **{name}** | {desc} |")
    # Silence-resistance callout from C.SILENCE_RES_DOWN ([level] = -pct).
    sil = re.findall(r"\[(\d+)\]\s*=\s*(-\d+),?\s*--", text)
    sil_rows = [(int(lv), int(pct)) for lv, pct in sil if int(pct) < 0 and int(lv) in c["nms"]]
    if sil_rows:
        names = " and ".join(f"{c['nms'][lv]} ({lv})" for lv, _ in sil_rows)
        pcts = {pct for _, pct in sil_rows}
        pct_txt = "/".join(f"{p}%" for p in sorted(pcts))
        out += ["", f'!!! warning "Silence on {names}"',
                f"    Both bosses have reduced Silence resistance ({pct_txt}). "
                f"Silence is the intended way to interrupt their spell rotations."
                if len(sil_rows) > 1 else
                f"    This boss has reduced Silence resistance ({pct_txt}). "
                f"Silence is the intended way to interrupt its spell rotation."]
    return "\n".join(out)


def _render_boss_overrides(text: str, c: dict) -> str:
    """Level-specific TP-move override table from C.bossOverrides in the
    catalog (hoisted out of TheGauntlet.lua 2026-07-11 so tuning lives in
    data, and this page can't drift from it)."""
    blk = re.search(r"C\.bossOverrides\s*=\s*\{(.*?)\n\}", text, re.DOTALL)
    if not blk:
        raise RuntimeError("C.bossOverrides not found in gauntlet_catalog.lua "
                           "-- update _render_boss_overrides.")
    body = blk.group(1)

    def entry(key: str) -> dict[str, str]:
        m = re.search(rf"{key}\s*=\s*\{{([^{{}}]*(?:\{{[^}}]*\}}[^{{}}]*)*)\}}", body)
        if not m:
            raise RuntimeError(f"bossOverrides.{key} missing -- update "
                               f"_render_boss_overrides.")
        fields = dict(re.findall(r"(\w+)\s*=\s*([\d.]+)", m.group(1)))
        lv = re.search(r"levels\s*=\s*\{\s*([\d,\s]+)\}", m.group(1))
        if lv:
            fields["levels"] = [int(x) for x in re.findall(r"\d+", lv.group(1))]
        return fields

    eb = entry("earthbreaker")
    sf = entry("spikeFlail")
    at = entry("absoluteTerror")
    me = entry("meteor")
    sb = entry("sableBreath")
    ks = entry("kirinSpellCap")
    mj = entry("medusaJavelin")

    def fmt(n: str) -> str:
        return f"{int(float(n)):,}"

    by_level: dict[int, list[str]] = {}

    def add(level: int, txt: str) -> None:
        by_level.setdefault(level, []).append(txt)

    add(int(eb["level"]), f"Earthbreaker → magical earth damage + stun "
                          f"({eb['stunSec']}s), capped at {fmt(eb['damageCap'])}")
    for lv in sf.get("levels", []):
        add(lv, f"Spike Flail → 3-hit physical, minimum {fmt(sf['damageFloor'])} per use")
    add(int(at["level"]), f"Absolute Terror → {at['terrorMinSec']}–{at['terrorMaxSec']}s Terror")
    add(int(me["level"]), f"Meteor → magical damage capped at {fmt(me['damage'])}, "
                          f"on a {me['recastSec']}s recast")
    add(int(sb["level"]), f"Sable Breath → dark breath damage to the front arc "
                          f"(~{int(float(sb['hpPct']) * 100)}% max HP), capped at {fmt(sb['damageCap'])}")
    add(int(ks["level"]), f"Deadly Hold and Tail-type moves bypass parry; "
                          f"Stonega IV / Stone V / Quake capped at {fmt(ks['damageCap'])}")
    add(int(mj["level"]), f"Medusa Javelin → physical + Bind {mj['bindSec']}s "
                          f"(replaces retail Petrify)")

    out = ["Some levels also override specific TP moves:", "",
           "| Level | NM | Notable override |", "|---|---|---|"]
    for lv in sorted(by_level):
        name = c["nms"].get(lv, f"Level {lv}")
        out.append(f"| {lv} | {name} | " + "; ".join(by_level[lv]) + " |")
    return "\n".join(out)


def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/gauntlet_catalog.lua")
    if src is None:
        print("[gauntlet] skip: gauntlet_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    c = _parse(text)

    page = docs_dir / "endgame" / "the-gauntlet.md"
    if not page.exists():
        print(f"[gauntlet] skip: {page} not found")
        return

    blocks = [
        ("gauntlet-levels",        _render_levels(c)),
        ("gauntlet-rewards",       _render_rewards(c)),
        ("gauntlet-level-rewards", _render_level_rewards(c)),
        ("gauntlet-milestones",    _render_milestones(c)),
        ("gauntlet-mechanics",     _render_mechanics(text, c)),
        ("gauntlet-boss-overrides", _render_boss_overrides(text, c)),
    ]
    written = sum(
        1 for marker, content in blocks
        if write_between_markers(page, marker, content)
    )
    print(
        f"[gauntlet] {written}/{len(blocks)} marker block(s) written "
        f"(nms={len(c['nms'])}, base_hp={c['base_hp']:,}, "
        f"hp_growth={c['hp_growth']}, nm_level={c['nm_level']})"
    )
