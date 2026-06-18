"""Generate Daily Board reference tables inside docs/progression/daily-board.md.

Reads: modules/custom/lua/daily_board_catalog.lua

Marker IDs:
  - "daily-board-pool"        -- grouped mini-tables of the full objective pool
  - "daily-board-all-cleared" -- all-cleared bonus reward line
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers

# ---------------------------------------------------------------------------
# Lua helpers (duplicated per the established pattern)
# ---------------------------------------------------------------------------

_QUOTED = r"""'(?:[^'\\]|\\.)*'|"(?:[^"\\]|\\.)*" """


def _quoted_value(s: str) -> str:
    s = s.strip()
    if (s.startswith("'") and s.endswith("'")) or (s.startswith('"') and s.endswith('"')):
        return s[1:-1]
    return s


def _balanced_blocks(text: str):
    """Yield (start, end) character offsets for every top-level {...} block."""
    depth = 0
    in_single = False
    in_double = False
    start = -1
    i = 0
    while i < len(text):
        c = text[i]
        if not in_single and not in_double and text[i:i+2] == '--':
            end_of_line = text.find('\n', i)
            i = end_of_line + 1 if end_of_line != -1 else len(text)
            continue
        if c == "'" and not in_double:
            in_single = not in_single
        elif c == '"' and not in_single:
            in_double = not in_double
        elif not in_single and not in_double:
            if c == '{':
                if depth == 0:
                    start = i
                depth += 1
            elif c == '}':
                depth -= 1
                if depth == 0 and start != -1:
                    yield (start, i + 1)
                    start = -1
        i += 1


# ---------------------------------------------------------------------------
# Currency display names
# ---------------------------------------------------------------------------

_CURRENCY_DISPLAY = {
    "hl":    "Hunt Marks",
    "af":    "AF Marks",
    "relic": "Relic Marks",
    "empy":  "Empy Marks",
}

# Metric display names and units
_METRIC_DISPLAY = {
    "kills":    ("NM Kills (any system)", "kills"),
    "dungeons": ("Dungeon Clears",        "clears"),
    "infamy":   ("Dungeon Infamy",        "Infamy"),
    "waves":    ("Wave Fights",           "wins"),
    "augments": ("Augmentation Trades",   "trades"),
}

_METRIC_ORDER = ["kills", "dungeons", "infamy", "waves", "augments"]


# ---------------------------------------------------------------------------
# Parsers
# ---------------------------------------------------------------------------

def _parse_int(text: str, key: str) -> int | None:
    m = re.search(rf'\b{re.escape(key)}\s*=\s*(\d+)', text)
    return int(m.group(1)) if m else None


def _parse_all_cleared(text: str) -> list[dict] | None:
    """Return every reward in allClearedReward.

    Handles both the current nested format::

        allClearedReward = { rewards = { {currency=,amount=}, ... }, ... }

    and the older flat format::

        allClearedReward = { currency=, amount= }
    """
    m = re.search(r'\ballClearedReward\s*=\s*\{', text)
    if not m:
        return None

    tail = text[m.start():]
    block = None
    for start, end in _balanced_blocks(tail):
        block = tail[start:end]
        break
    if block is None:
        return None

    rewards: list[dict] = []

    # Preferred: a nested `rewards = { {...}, {...} }` array.
    rm = re.search(r'\brewards\s*=\s*\{', block)
    if rm:
        rtail = block[rm.start():]
        for rstart, rend in _balanced_blocks(rtail):
            rewards_block = rtail[rstart:rend]
            for estart, eend in _balanced_blocks(rewards_block[1:]):
                entry = rewards_block[1:][estart:eend]
                cur_m = re.search(r'\bcurrency\s*=\s*(' + _QUOTED + r')', entry)
                amt_m = re.search(r'\bamount\s*=\s*(\d+)', entry)
                if cur_m and amt_m:
                    rewards.append({
                        "currency": _quoted_value(cur_m.group(1).strip()),
                        "amount":   int(amt_m.group(1)),
                    })
            break

    # Fallback: a single flat currency+amount directly on the reward.
    if not rewards:
        cur_m = re.search(r'\bcurrency\s*=\s*(' + _QUOTED + r')', block)
        amt_m = re.search(r'\bamount\s*=\s*(\d+)', block)
        if cur_m and amt_m:
            rewards.append({
                "currency": _quoted_value(cur_m.group(1).strip()),
                "amount":   int(amt_m.group(1)),
            })

    return rewards or None


def _parse_objective_pool(text: str) -> list[dict]:
    m = re.search(r'\bobjectivePool\s*=\s*\{', text)
    if not m:
        return []
    for start, end in _balanced_blocks(text[m.start():]):
        pool_block = text[m.start():][start:end]
        break
    else:
        return []

    objectives = []
    for entry_start, entry_end in _balanced_blocks(pool_block[1:]):
        entry = pool_block[1:][entry_start:entry_end]

        label_m  = re.search(r'\blabel\s*=\s*(' + _QUOTED + r')', entry)
        target_m = re.search(r'\btarget\s*=\s*(\d+)', entry)
        metric_m = re.search(r'\bmetric\s*=\s*(' + _QUOTED + r')', entry)

        # reward sub-block
        reward_m = re.search(r'\breward\s*=\s*\{([^}]*)\}', entry)
        if not (label_m and target_m and metric_m and reward_m):
            continue

        reward_text = reward_m.group(1)
        cur_m  = re.search(r'\bcurrency\s*=\s*(' + _QUOTED + r')', reward_text)
        amt_m  = re.search(r'\bamount\s*=\s*(\d+)', reward_text)
        if not (cur_m and amt_m):
            continue

        objectives.append({
            "label":    _quoted_value(label_m.group(1).strip()),
            "target":   int(target_m.group(1)),
            "metric":   _quoted_value(metric_m.group(1).strip()),
            "currency": _quoted_value(cur_m.group(1).strip()),
            "amount":   int(amt_m.group(1)),
        })

    return objectives


# ---------------------------------------------------------------------------
# Renderers
# ---------------------------------------------------------------------------

def _render_pool(objectives: list[dict]) -> str:
    by_metric: dict[str, list[dict]] = {}
    for obj in objectives:
        by_metric.setdefault(obj["metric"], []).append(obj)

    lines = []
    first = True
    for metric in _METRIC_ORDER:
        if metric not in by_metric:
            continue

        if not first:
            lines.append("")
        first = False

        display_name, unit = _METRIC_DISPLAY.get(metric, (metric.title(), metric))
        lines.append(f"**{display_name}**")
        lines.append("")
        lines.append("| Objective | Target | Reward |")
        lines.append("|---|---:|---|")

        for obj in by_metric[metric]:
            currency_display = _CURRENCY_DISPLAY.get(obj["currency"], obj["currency"])
            target_str  = f"{obj['target']} {unit}"
            reward_str  = f"{obj['amount']:,} {currency_display}"
            lines.append(f"| {obj['label']} | {target_str} | {reward_str} |")

    return "\n".join(lines)


def _render_all_cleared(rewards: list[dict], slots_per_day: int) -> str:
    parts = []
    for reward in rewards:
        currency_display = _CURRENCY_DISPLAY.get(reward["currency"], reward["currency"])
        parts.append(f"{reward['amount']:,} {currency_display}")
    reward_str = " + ".join(parts)
    return (
        f"Claim all {slots_per_day} objectives in the same UTC calendar day for a bonus "
        f"**{reward_str}** on top of the individual payouts."
    )


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/daily_board_catalog.lua")
    if src is None:
        print("[daily_board] skip: daily_board_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")

    page = docs_dir / "progression" / "daily-board.md"
    if not page.exists():
        print(f"[daily_board] skip: target page {page} not found")
        return

    objectives   = _parse_objective_pool(text)
    all_cleared  = _parse_all_cleared(text)
    slots_per_day = _parse_int(text, "slotsPerDay") or 3

    # --- pool marker ---
    pool_content = _render_pool(objectives)
    wrote = write_between_markers(page, "daily-board-pool", pool_content)
    if wrote:
        print(f"[daily_board] pool: {len(objectives)} objectives written into marker")
    else:
        print(f"[daily_board] pool: marker 'daily-board-pool' not found in {page.name}")

    # --- all-cleared marker ---
    if all_cleared:
        cleared_content = _render_all_cleared(all_cleared, slots_per_day)
        wrote = write_between_markers(page, "daily-board-all-cleared", cleared_content)
        if wrote:
            print("[daily_board] all-cleared: written into marker")
        else:
            print(f"[daily_board] all-cleared: marker 'daily-board-all-cleared' not found in {page.name}")
    else:
        print("[daily_board] all-cleared: could not parse allClearedReward")
