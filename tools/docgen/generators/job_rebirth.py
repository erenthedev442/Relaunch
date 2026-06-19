"""Generate Job Rebirth fact-blocks inside docs/progression/job-rebirth.md.

Reads: modules/custom/lua/job_rebirth_catalog.lua

Marker IDs:
  - "rebirth-location"       -- NPC zone + access command
  - "rebirth-how-it-works"   -- 3-step cycle with correct RP grant formula
  - "rebirth-exp-penalty"    -- EXP penalty paragraph + table
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers

# ---------------------------------------------------------------------------
# Zone ID → player-facing name (only zones this system ever uses)
# ---------------------------------------------------------------------------

_ZONE_NAMES: dict[int, str] = {
    210: "GM Home",
    243: "RuLude Gardens",
}

# ---------------------------------------------------------------------------
# Lua helpers
# ---------------------------------------------------------------------------

def _int_val(text: str, key: str) -> int | None:
    """Parse `key = N` from a Lua config block."""
    m = re.search(rf'\b{re.escape(key)}\s*=\s*(\d+)', text)
    return int(m.group(1)) if m else None

# ---------------------------------------------------------------------------
# Renderers
# ---------------------------------------------------------------------------

_ORDINALS = ["1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th"]


def _ordinal(n: int) -> str:
    if 1 <= n <= len(_ORDINALS):
        return _ORDINALS[n - 1]
    return f"{n}th"


def _render_location(zone_id: int) -> str:
    zone_name = _ZONE_NAMES.get(zone_id, f"zone {zone_id}")
    return (
        f"The **Job Rebirth altar** is in **{zone_name}**, accessible via the "
        f"`!rebirth` command. Speak to it on a qualifying job to rebirth — or "
        f"visit any time to spend Rebirth Points you have already banked."
    )


def _render_how_it_works(jp_req: int, rp_base: int, rp_per_level: int, rp_max: int) -> str:
    rp_range = f"{rp_base}–{rp_max}" if rp_max > rp_base else str(rp_base)
    lines = [
        "Rebirth is a three-step cycle:",
        "",
        f"1. **Master the job** — Reach level 99 and spend all {jp_req:,} Job Points.",
        "2. **Rebirth at the altar** — Choose **Rebirth this job** and confirm. "
        "The job resets to level 1 and its Job Points are fully wiped.",
        f"3. **Earn Rebirth Points** — Each rebirth grants **{rp_range} RP**: "
        f"{rp_base} for your 1st rebirth, +{rp_per_level} per additional rebirth, "
        f"capped at {rp_max}.",
        "",
        '!!! warning "Rebirth is permanent"',
        "    A rebirth cannot be undone. Your level and Job Points on that job are "
        "wiped the moment you confirm. Everything you have bought with Rebirth "
        "Points — and the points themselves — are kept.",
        "",
        "### What a Rebirth Costs You",
        "",
        "- **Level → 1.** You re-level the job from scratch.",
        "- **Job Points wiped.** Every category, gift, and capacity point on that "
        "job is cleared to zero.",
        "- **Only the reborn job is affected.** Your other jobs — their levels, "
        "Job Points, and gear — are untouched.",
        "",
        "### What You Gain",
        "",
        f"- **{rp_range} Rebirth Points** banked for that job "
        f"(base {rp_base}, +{rp_per_level} per rebirth, cap {rp_max}).",
        "- Spent on **permanent** per-job stat boosts that survive every future rebirth.",
    ]
    return "\n".join(lines)


def _render_exp_penalty(penalty_per: int, penalty_cap: int) -> str:
    cap_at = penalty_cap // penalty_per  # rebirth number where cap is first hit
    effective_floor = 100 - penalty_cap

    header_lines = [
        f"Each rebirth stacks a **−{penalty_per}% EXP penalty** on that job, "
        f"capped at **−{penalty_cap}%**. The penalty is **per-job** — it only "
        "slows the job that has been reborn, and disappears the instant you "
        "switch to anything else. You always keep at least "
        f"**{effective_floor}%** of normal EXP, so the climb is always possible "
        "— but a many-times-reborn job is a true endgame grind.",
        "",
        "| Rebirth | EXP Penalty (that job) | Effective EXP |",
        "|---|---:|---:|",
    ]

    rows = []
    for n in range(1, cap_at):   # rows before the cap is first hit
        p = n * penalty_per
        eff = 100 - p
        rows.append(f"| {_ordinal(n)} | −{p}% | {eff}% |")

    # Final row: cap_at-th rebirth is where the cap first applies
    rows.append(
        f"| {_ordinal(cap_at)} and beyond | **−{penalty_cap}%** (cap) | {effective_floor}% |"
    )

    return "\n".join(header_lines + rows)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/job_rebirth_catalog.lua")
    if src is None:
        print("[job_rebirth] skip: job_rebirth_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")

    page = docs_dir / "progression" / "job-rebirth.md"
    if not page.exists():
        print(f"[job_rebirth] skip: {page} not found")
        return

    # Parse catalog values with safe fallbacks matching current defaults
    npc_zone     = _int_val(text, "npcZone")     or 243
    jp_required  = _int_val(text, "jpRequired")  or 2100
    rp_base      = _int_val(text, "rpBase")      or 10
    rp_per_level = _int_val(text, "rpPerLevel")  or 2
    rp_max       = _int_val(text, "rpMax")       or 20
    exp_penalty  = _int_val(text, "expPenaltyPerRebirth") or 15
    exp_cap      = _int_val(text, "expPenaltyCap")        or 90

    results = [
        ("rebirth-location",     _render_location(npc_zone)),
        ("rebirth-how-it-works", _render_how_it_works(jp_required, rp_base, rp_per_level, rp_max)),
        ("rebirth-exp-penalty",  _render_exp_penalty(exp_penalty, exp_cap)),
    ]

    for marker_id, content in results:
        wrote = write_between_markers(page, marker_id, content)
        status = "written" if wrote else f"MARKER NOT FOUND: {marker_id}"
        print(f"[job_rebirth] {marker_id}: {status}")
