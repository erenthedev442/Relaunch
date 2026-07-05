"""Generate the Subjob EXP Share page — docs/progression/subjob-exp.md —
from the live module.

FULL-PAGE owner (spells.py idiom): builds the complete markdown and
overwrites the page each run.

Live sources (all via tools.docgen._paths.resolve_source):
  - modules/custom/lua/subjob_exp_share.lua
        SHARE_RATE (share of each EXP gain banked to the sub),
        BANK_VAR / BANK_JOB_VAR (charvar names),
        the sub-level-cap guard (subLvl >= mainLvl),
        bank scoping on subjob switch (reset vs carry-over),
        the multi-level catch-up loop,
        the Job Rebirth exclusion,
        the EXP_TO_NEXT curve, and
        the level-up chat message format string.
  - settings/main.lua -> settings/map.lua -> settings/default/main.lua ->
    settings/default/map.lua
        SUBJOB_RATIO (it lives in map.lua; main.lua is checked first per the
        page's history, then the committed defaults keep CI builds working).

The ratio's meaning mirrors the switch in
src/map/entities/battleentity.cpp SetSLevel() (0 = no SJ, 1 = 1/2,
2 = 2/3, 3 = equal).

Fails closed: if the module or a load-bearing value/behavior can't be
parsed, prints a skip line and returns without writing, keeping the last
good page live.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen import _site
from tools.docgen._paths import resolve_source


# =========================================================================
# NARRATIVE CONSTANTS — the single editing point for page prose that has no
# code source. {placeholders} are filled from live parses in generate().
# =========================================================================

_INTRO = (
    "Your subjob levels up in the background while you grind your main. No "
    "party-leader hoops, no separate grinding sessions — just play your main "
    "and your sub catches up."
)

_MECHANIC = (
    "Every EXP gain you earn — mob kills, FoV / GoV books, Records of "
    "Eminence, scripted sources — silently banks **{share_pct}** of that EXP "
    "toward your current subjob, on top of the EXP you already earned. When "
    "the bank crosses the per-level threshold, the sub levels up "
    "automatically with a chat message:\n"
    "\n"
    "> _{example_msg}_\n"
    "\n"
    "The level-up triggers the full stat recalc — skills, traits, abilities, "
    "weapon skills, HP/MP — so the next mob you fight already benefits from "
    "the new sub level."
)

_AFTER_TABLE = (
    "Each sub level costs the **same EXP your main job needs for that "
    "level** (the module mirrors the server's real EXP curve), so the sub "
    "tracks {share_pct} of your main's pace at every level — both ramp "
    "continuously instead of stepping."
)

# SUBJOB_RATIO value -> (cap description, "what the ratio unlocks" phrasing).
# Mirrors src/map/entities/battleentity.cpp SetSLevel().
_RATIO_MEANING: dict[int, str] = {
    0: "subjobs entirely disabled",
    1: "the retail cap — half of main (a 99 main caps the sub at 49)",
    2: "two-thirds of main (a 99 main caps the sub at 66)",
    3: "your main's full level (99 main → sub can be 99 too)",
}

_RATIO_SECTION = (
    "`SUBJOB_RATIO = {ratio}` on {server_name} (see "
    "[Retail Differences](../changes/index.md#subjob)) sets the **effective "
    "sub level cap** to {ratio_meaning} — but that setting doesn't grant "
    "EXP. Without the Subjob EXP Share module, a never-leveled SAM sub on a "
    "WAR/99 main still has actual sub level = 1, and "
    "`min(actual sub level, ratio cap)` is what gets used for stats — the "
    "cap alone does nothing until the sub has real levels.\n"
    "\n"
    "This module is what actually fills the gap: as you play, the sub's real "
    "stored level climbs, and `SUBJOB_RATIO = {ratio}` lets the sub's full "
    "level count once it's there."
)

_TRACKING = (
    "Your banked sub EXP lives in a character variable named `{bank_var}` "
    "(with `{bank_job_var}` recording which subjob the bank belongs to). You "
    "can inspect them with the `!checkvar` GM command (or ask staff if you "
    "don't have GM access)."
)

_SWITCHES_SCOPED = (
    "The bank is **scoped to your active subjob** — switching subs starts "
    "the new sub's bank fresh at 0. If you grind 500 banked EXP toward SAM "
    "and then switch to MNK, that 500 is abandoned; it does *not* carry "
    "over. (One exception: the very first EXP gain under this system adopts "
    "your current sub without wiping anything already banked for it.) If "
    "you care about banked overflow, settle on a sub before a long grind."
)

_SWITCHES_SHARED = (
    "The bank is shared across subjobs — it doesn't reset when you change "
    "your sub. Banked EXP earned toward one sub carries over and counts "
    "toward the next."
)

_DONT_NEED = (
    "- **No party requirement.** Works solo, in a party, or trust grinding.\n"
    "- **No EXP item bands.** EXP rings still help your main, and the sub's "
    "share scales with whatever you actually earned.\n"
    "- **No \"rested EXP\" mechanic.** It's a flat share of whatever you "
    "just earned."
)

_EDGE_CAP = (
    "**Sub at the cap:** once the sub reaches your main's current level, the "
    "share **pauses** — nothing banks while the sub is capped. It resumes as "
    "soon as your main outlevels the sub again. (At main 99 the sub simply "
    "climbs to 99 and stops.)"
)

_EDGE_RAISE = (
    "**Dying and being raised:** raise EXP doesn't bank to sub. Only EXP "
    "you actually earn does."
)

_EDGE_MERIT = (
    "**Limit Break / merit mode:** when main is earning merit points "
    "instead of EXP toward a level, sub still receives its share of the "
    "raw EXP value."
)

_EDGE_REBIRTH = (
    "**Reborn jobs:** a subjob that has been through "
    "[Job Rebirth](job-rebirth.md) is excluded from the share — it's meant "
    "to be re-leveled as a main under its rebirth EXP penalty, so it can't "
    "ride along for free."
)


# =========================================================================
# Parsers
# =========================================================================

def _read(repo_root: Path, sub_path: str) -> str | None:
    src = resolve_source(repo_root, sub_path)
    if src is None:
        return None
    return src.read_text(encoding="utf-8", errors="replace").replace("\r\n", "\n")


def _parse_share_rate(text: str) -> float | None:
    m = re.search(r"local\s+SHARE_RATE\s*=\s*([\d.]+)", text)
    return float(m.group(1)) if m else None


def _parse_var(text: str, name: str) -> str | None:
    m = re.search(rf"local\s+{name}\s*=\s*'([^']+)'", text)
    return m.group(1) if m else None


def _parse_message(text: str) -> str | None:
    """The level-up chat line: a string.format template containing both %s
    (job) and %d (level). Returned with example values substituted."""
    for m in re.finditer(r"string\.format\(\s*'((?:[^'\\]|\\.)*)'", text):
        fmt = m.group(1).replace("\\'", "'")
        if "%s" in fmt and "%d" in fmt:
            return fmt.replace("%s", "WAR").replace("%d", "47")
    return None


def _parse_bank_scoping(text: str) -> bool | None:
    """True  -> bank resets when the subjob changes (per-sub scoping).
    False -> no scoping var at all (bank shared across subs).
    None  -> ambiguous (scoping var exists but no reset found): fail closed,
    the published claim would be a coin flip."""
    has_job_var = re.search(r"local\s+BANK_JOB_VAR\s*=", text) is not None
    resets = re.search(
        r"elseif\s+bankJob\s*~=\s*sjob\s+then.*?setCharVar\(\s*BANK_VAR\s*,\s*0\s*\)",
        text, re.DOTALL,
    ) is not None
    if has_job_var and resets:
        return True
    if not has_job_var:
        return False
    return None


def _parse_subjob_ratio(repo_root: Path) -> int | None:
    """SUBJOB_RATIO lives in settings/map.lua (namespace map.*); main.lua is
    scanned first for history's sake, committed defaults keep CI working."""
    for cand in ("settings/main.lua", "settings/map.lua",
                 "settings/default/main.lua", "settings/default/map.lua"):
        text = _read(repo_root, cand)
        if text is None:
            continue
        m = re.search(r"^\s*SUBJOB_RATIO\s*=\s*(\d+)", text, re.MULTILINE)
        if m:
            return int(m.group(1))
    return None


# =========================================================================
# Entry point
# =========================================================================

def generate(repo_root: Path, docs_dir: Path) -> None:
    module_path = "modules/custom/lua/subjob_exp_share.lua"
    text = _read(repo_root, module_path)
    if text is None:
        print(f"[subjob_exp_page] skip: {module_path} not found")
        return

    share_rate   = _parse_share_rate(text)
    bank_var     = _parse_var(text, "BANK_VAR")
    bank_job_var = _parse_var(text, "BANK_JOB_VAR")
    example_msg  = _parse_message(text)
    cap_guard    = re.search(r"subLvl\s*>=\s*mainLvl\s+then\s+return", text) is not None
    scoped       = _parse_bank_scoping(text)
    ratio        = _parse_subjob_ratio(repo_root)

    required = {
        "SHARE_RATE": share_rate,
        "BANK_VAR": bank_var,
        "level-up message format": example_msg,
        "sub-level cap guard (subLvl >= mainLvl)": cap_guard or None,
        "bank scoping behavior": scoped,  # None = ambiguous -> skip
        "SUBJOB_RATIO (settings)": ratio,
    }
    missing = [name for name, val in required.items() if val is None]
    if missing:
        print(f"[subjob_exp_page] skip: could not parse {', '.join(missing)}")
        return

    share_pct  = f"{share_rate * 100:g}%"
    multi_level = re.search(r"while\s+subLvl\s*<\s*mainLvl", text) is not None
    has_curve   = re.search(r"EXP_TO_NEXT\s*=\s*\{", text) is not None
    excludes_rebirth = "Rebirth_Count_" in text

    numbers_rows = [
        ("Sub EXP per main EXP", f"**{share_rate:g}× ({share_pct})**"),
    ]
    if has_curve:
        numbers_rows.append(
            ("EXP per sub level", "Same as your main job needs for that level"))
    numbers_rows += [
        ("Cap", "Sub never exceeds main job's current level"),
        ("EXP sources", "Anything that awards main EXP — kills, books, ROE"),
        ("Auto level-up",
         "Yes — a big gain can clear several levels at once" if multi_level
         else "Yes, in the background"),
        ("Banked EXP",
         f"`{bank_var}` char variable" + (f" (+ `{bank_job_var}`, per-subjob)"
                                          if scoped and bank_job_var else "")),
    ]

    facts = {
        "server_name":   _site.SERVER_NAME,
        "share_pct":     share_pct,
        "example_msg":   example_msg,
        "bank_var":      bank_var,
        "bank_job_var":  bank_job_var or "—",
        "ratio":         ratio,
        "ratio_meaning": _RATIO_MEANING.get(ratio, f"ratio mode {ratio}"),
    }

    lines: list[str] = [
        "# Subjob EXP Share",
        "",
        _INTRO,
        "",
        "## The mechanic",
        "",
        _MECHANIC.format(**facts),
        "",
        "## The numbers",
        "",
        "| | Value |",
        "|---|---|",
    ]
    for label, value in numbers_rows:
        lines.append(f"| {label} | {value} |")
    lines += [
        "",
        _AFTER_TABLE.format(**facts),
        "",
        "## How this differs from `SUBJOB_RATIO`",
        "",
        _RATIO_SECTION.format(**facts),
        "",
        "## Tracking your sub's progress",
        "",
        _TRACKING.format(**facts),
        "",
        "## Subjob switches",
        "",
        (_SWITCHES_SCOPED if scoped else _SWITCHES_SHARED).format(**facts),
        "",
        "## What you don't need to do",
        "",
        _DONT_NEED,
        "",
        "## Edge cases",
        "",
        f"- {_EDGE_CAP}",
        f"- {_EDGE_RAISE}",
        f"- {_EDGE_MERIT}",
    ]
    if excludes_rebirth:
        lines.append(f"- {_EDGE_REBIRTH}")
    lines.append("")

    page = docs_dir / "progression" / "subjob-exp.md"
    page.parent.mkdir(parents=True, exist_ok=True)
    page.write_text("\n".join(lines), encoding="utf-8")
    print(
        f"[subjob_exp_page] wrote progression/subjob-exp.md (share {share_pct}, "
        f"bank {'per-subjob reset' if scoped else 'shared'}, "
        f"SUBJOB_RATIO={ratio}, rebirth exclusion={'yes' if excludes_rebirth else 'no'})"
    )
