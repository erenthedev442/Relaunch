"""Generate login reward reference tables inside docs/progression/login-rewards.md.

Reads:
  - modules/custom/lua/daily_login_bonus.lua
  - modules/custom/lua/login_streak.lua

Marker IDs:
  - "login-daily-bonus"       -- daily bonus amount line
  - "login-streak-milestones" -- streak milestone table
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
# Parsers
# ---------------------------------------------------------------------------

def _parse_daily_bonus(text: str) -> int:
    """Parse `local DAILY_BONUS = N` from the module file."""
    m = re.search(r'\blocal\s+DAILY_BONUS\s*=\s*(\d+)', text)
    return int(m.group(1)) if m else 10


def _parse_streak_milestones(text: str) -> list[tuple[int, int, str]]:
    """Parse STREAK_MILESTONES positional tuples {days, marks, label}.

    Returns list of (days, marks, label).
    """
    pattern = r'\{\s*(\d+)\s*,\s*(\d+)\s*,\s*(' + _QUOTED + r')\s*\}'
    milestones = []
    for m in re.finditer(pattern, text):
        days  = int(m.group(1))
        marks = int(m.group(2))
        label = _quoted_value(m.group(3).strip())
        milestones.append((days, marks, label))
    return milestones


# ---------------------------------------------------------------------------
# Renderers
# ---------------------------------------------------------------------------

def _render_daily_bonus(bonus: int) -> str:
    return (
        f"Every day you log in, you receive **+{bonus} Hunt Marks** automatically. "
        f"The bonus fires once per UTC day."
    )


def _render_streak_milestones(milestones: list[tuple[int, int, str]]) -> str:
    lines = [
        "| Streak | One-Time Bonus |",
        "|---|---|",
    ]
    for days, marks, _label in milestones:
        lines.append(f"| {days} days in a row | +{marks} Hunt Marks |")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    page = docs_dir / "progression" / "login-rewards.md"
    if not page.exists():
        print(f"[login_rewards] skip: target page {page} not found")
        return

    # --- daily bonus ---
    daily_src = resolve_source(repo_root, "modules/custom/lua/daily_login_bonus.lua")
    if daily_src is None:
        print("[login_rewards] skip daily-bonus: daily_login_bonus.lua not found")
    else:
        daily_text  = daily_src.read_text(encoding="utf-8", errors="replace")
        daily_bonus = _parse_daily_bonus(daily_text)
        bonus_content = _render_daily_bonus(daily_bonus)
        wrote = write_between_markers(page, "login-daily-bonus", bonus_content)
        if wrote:
            print(f"[login_rewards] daily-bonus: +{daily_bonus} marks written into marker")
        else:
            print(f"[login_rewards] daily-bonus: marker 'login-daily-bonus' not found in {page.name}")

    # --- streak milestones ---
    streak_src = resolve_source(repo_root, "modules/custom/lua/login_streak.lua")
    if streak_src is None:
        print("[login_rewards] skip streak-milestones: login_streak.lua not found")
    else:
        streak_text = streak_src.read_text(encoding="utf-8", errors="replace")
        milestones  = _parse_streak_milestones(streak_text)
        streak_content = _render_streak_milestones(milestones)
        wrote = write_between_markers(page, "login-streak-milestones", streak_content)
        if wrote:
            print(f"[login_rewards] streak-milestones: {len(milestones)} milestones written into marker")
        else:
            print(f"[login_rewards] streak-milestones: marker 'login-streak-milestones' not found in {page.name}")
