"""Generate Job Rebirth fact-blocks inside docs/progression/job-rebirth.md.

Reads: modules/custom/lua/job_rebirth_catalog.lua

Marker IDs:
  - "rebirth-location"       -- NPC zone + access command
  - "rebirth-how-it-works"   -- 3-step cycle with correct RP grant formula
  - "rebirth-exp-penalty"    -- EXP penalty paragraph + table
"""
from __future__ import annotations

import math
import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
# JobRebirth reuses prestige_catalog.categories verbatim (JobRebirth.lua), so the
# RP spend table is rendered from the SAME parser/renderer as the Prestige AP table.
from tools.docgen.generators.prestige import _parse_categories, _render_ap_table

# ---------------------------------------------------------------------------
# Zone ID → player-facing name (only zones this system ever uses)
# ---------------------------------------------------------------------------

_ZONE_NAMES: dict[int, str] = {
    210: "GM Home",
    243: "RuLude Gardens",
    284: "Celennia Memorial Library",
}

# ---------------------------------------------------------------------------
# Lua helpers
# ---------------------------------------------------------------------------

def _int_val(text: str, key: str) -> int | None:
    """Parse `key = N` from a Lua config block."""
    m = re.search(rf'\b{re.escape(key)}\s*=\s*(\d+)', text)
    return int(m.group(1)) if m else None


def _float_val(text: str, key: str) -> float | None:
    """Parse `key = N.N` from a Lua config block."""
    m = re.search(rf'\b{re.escape(key)}\s*=\s*([0-9.]+)', text)
    return float(m.group(1)) if m else None

# ---------------------------------------------------------------------------
# Curve math (mirrors the Lua engine formulas)
# ---------------------------------------------------------------------------

def _rp_at(count: int, rp_min: int, rp_scale: float, rp_power: float,
           ms_every: int, ms_bonus: int) -> int:
    base = math.floor(rp_min + rp_scale * (count ** rp_power - 1))
    ms = ms_bonus if (ms_every and count % ms_every == 0) else 0
    return max(rp_min, base) + ms


def _penalty_at(count: int, pen_min: int, pen_scale: float, rp_power: float,
                ms_every: int, ms_extra: int, hard_cap: int) -> int:
    base = math.floor(pen_min + pen_scale * (count ** rp_power - 1))
    ms = ms_extra if (ms_every and count % ms_every == 0) else 0
    return min(max(int(pen_min), base) + ms, hard_cap)


def _cap_rebirth(pen_min: int, pen_scale: float, rp_power: float,
                 ms_every: int, ms_extra: int, hard_cap: int) -> int:
    """Return the first rebirth count where the penalty hits hard_cap."""
    for n in range(1, 200):
        if _penalty_at(n, pen_min, pen_scale, rp_power, ms_every, ms_extra, hard_cap) >= hard_cap:
            return n
    return hard_cap

# ---------------------------------------------------------------------------
# Renderers
# ---------------------------------------------------------------------------

_ORDINALS = ["1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th", "9th", "10th"]


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


def _render_how_it_works(jp_req: int, rp_min: int, rp_scale: float, rp_power: float,
                         ms_every: int, ms_bonus: int) -> str:
    r1  = _rp_at(1,  rp_min, rp_scale, rp_power, ms_every, ms_bonus)
    r5  = _rp_at(5,  rp_min, rp_scale, rp_power, ms_every, ms_bonus)
    r10 = _rp_at(10, rp_min, rp_scale, rp_power, ms_every, ms_bonus)
    r20 = _rp_at(20, rp_min, rp_scale, rp_power, ms_every, ms_bonus)

    ms_note = ""
    if ms_bonus and ms_every:
        ms_note = (f" Every {_ordinal(ms_every)} rebirth is a **milestone** and pays a bonus "
                   f"+{ms_bonus} RP on top of the curve value.")

    lines = [
        "Rebirth is a three-step cycle:",
        "",
        f"1. **Master the job** — Reach level 99 and spend all {jp_req:,} Job Points.",
        "2. **Rebirth at the altar** — Choose **Rebirth this job** and confirm. "
        "The job resets to level 1 and its Job Points are fully wiped.",
        "3. **Earn Rebirth Points** — Each rebirth grants RP on an **accelerating curve**: "
        f"your {_ordinal(1)} rebirth pays **{r1} RP**, but later rebirths pay more as the "
        f"curve steepens.{ms_note}",
        "",
        "| Rebirth | RP granted |",
        "|---|---:|",
        f"| 1st | {r1} |",
        f"| 5th | {r5} |",
        f"| 10th _(milestone)_ | {r10} |",
        f"| 20th _(milestone)_ | {r20} |",
        "| 30th+ | keeps growing… |",
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
        "- **Rebirth Points** banked for that job (more per rebirth as you go).",
        "- Spent on **permanent** per-job stat boosts that survive every future rebirth.",
    ]
    return "\n".join(lines)


def _render_exp_penalty(pen_min: int, pen_scale: float, rp_power: float,
                        ms_every: int, ms_extra: int, hard_cap: int) -> str:
    cap_at = _cap_rebirth(pen_min, pen_scale, rp_power, ms_every, ms_extra, hard_cap)

    p1  = _penalty_at(1,  pen_min, pen_scale, rp_power, ms_every, ms_extra, hard_cap)
    p5  = _penalty_at(5,  pen_min, pen_scale, rp_power, ms_every, ms_extra, hard_cap)
    p10 = _penalty_at(10, pen_min, pen_scale, rp_power, ms_every, ms_extra, hard_cap)
    p20 = _penalty_at(20, pen_min, pen_scale, rp_power, ms_every, ms_extra, hard_cap)

    header_lines = [
        f"Each rebirth deepens a **multiplicative EXP cut** on that job — a *true* "
        "reduction taken **after** all of your gear, food, and augment EXP bonuses, so "
        "no amount of +EXP augments can cancel it. The cut starts small and grows on an "
        f"accelerating curve, capping at **−{hard_cap}%** (reached around your "
        f"{_ordinal(cap_at)} rebirth). The cut is "
        "**per-job** — it only slows the job that has been reborn, and disappears the "
        "instant you switch to anything else. A job can never be locked out: EXP is "
        "always floored at **5%** of base, so the climb stays possible — but a "
        "many-times-reborn job is a true endgame grind.",
        "",
        "| Rebirth | EXP Cut (that job) | EXP kept |",
        "|---|---:|---:|",
    ]

    rows = [
        f"| 1st | −{p1}% | {100 - p1}% |",
        f"| 5th | −{p5}% | {100 - p5}% |",
        f"| 10th _(milestone)_ | −{p10}% | {100 - p10}% |",
        f"| 20th _(milestone)_ | −{p20}% | {100 - p20}% |",
        f"| {_ordinal(cap_at)}+ | **−{hard_cap}%** _(cap)_ | {100 - hard_cap}% |",
    ]

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

    # Parse catalog values — use actual key names from job_rebirth_catalog.lua
    npc_zone     = _int_val(text, "npcZone")           or 284
    jp_required  = _int_val(text, "jpRequired")        or 2100

    rp_min        = _int_val(text,   "rpMin")          or 10
    rp_scale      = _float_val(text, "rpScale")        or 1.3
    rp_power      = _float_val(text, "rpPower")        or 1.3
    ms_every      = _int_val(text,   "rpMilestoneEvery")  or 10
    ms_bonus      = _int_val(text,   "rpMilestoneBonus")  or 30

    pen_min       = _int_val(text,   "expPenaltyMin")           or 4
    pen_scale     = _float_val(text, "expPenaltyScale")         or 1.1
    ms_extra      = _int_val(text,   "expPenaltyMilestoneExtra") or 8
    hard_cap      = _int_val(text,   "expPenaltyHardCap")        or 90

    # RP spend table — rendered from the shared prestige_catalog categories with an
    # RP cost label, so caps/costs can never drift from what the code actually grants.
    prestige_src = resolve_source(repo_root, "modules/custom/lua/prestige_catalog.lua")
    rp_cats = _parse_categories(prestige_src.read_text(encoding="utf-8", errors="replace")) \
        if prestige_src is not None else []

    results = [
        ("rebirth-location",
         _render_location(npc_zone)),
        ("rebirth-how-it-works",
         _render_how_it_works(jp_required, rp_min, rp_scale, rp_power, ms_every, ms_bonus)),
        ("rebirth-exp-penalty",
         _render_exp_penalty(pen_min, pen_scale, rp_power, ms_every, ms_extra, hard_cap)),
    ]
    if rp_cats:
        results.append(("rebirth-rp-table", _render_ap_table(rp_cats, cost_label="RP")))

    for marker_id, content in results:
        wrote = write_between_markers(page, marker_id, content)
        status = "written" if wrote else f"MARKER NOT FOUND: {marker_id}"
        print(f"[job_rebirth] {marker_id}: {status}")
