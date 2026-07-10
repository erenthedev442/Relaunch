"""Fill the drift-prone numeric tables on docs/getting-started/your-session.md.

The "Your First Session" onboarding page hand-coded three sets of numbers that
have to stay in lockstep with the live catalogs:

  * the starter stipend, daily-login bonus, and login-streak milestones,
  * the personal kill-count achievement rewards, and
  * the Hunting League rank ladder (unlock cost + Hunt Marks per kill).

Rather than re-parse those catalogs here, this generator reuses the parsers the
dedicated pages already rely on (login_rewards / achievements / hunting_league),
so the compact tables on this page can't disagree with the full tables on
login-rewards.md, achievements.md, and progression/index.md.

Marker IDs:
  - "session-rewards"      -- the "Rewards just for showing up" table
  - "session-rank-ladder"  -- rank / unlock cost / marks-per-kill table

Sources are normally gitignored on the Legendary branch (modules/custom/ is not
committed there) and resolved via $LEGENDARY_LIVE_ROOT; the Relaunch branch
commits them, so this runs against the repo copy. Either way, if a source is
missing the affected block is left untouched (its previously published content
stands) instead of publishing a half-filled table.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen.generators import login_rewards as _login
from tools.docgen.generators import achievements as _ach
from tools.docgen.generators import hunting_league as _hl


# ---------------------------------------------------------------------------
# Small parse helper unique to this page (starter stipend)
# ---------------------------------------------------------------------------

def _parse_starter_marks(text: str) -> int | None:
    m = re.search(r"\blocal\s+STARTER_MARKS\s*=\s*(\d+)", text)
    return int(m.group(1)) if m else None


def _read(repo_root: Path, rel: str) -> str | None:
    src = resolve_source(repo_root, rel)
    if src is None:
        return None
    return src.read_text(encoding="utf-8", errors="replace")


# ---------------------------------------------------------------------------
# Renderers
# ---------------------------------------------------------------------------

def _render_rewards(starter: int, daily: int,
                    streak: list[tuple[int, int, str]],
                    kills: list[tuple[int, int, str]]) -> str:
    """kills: list of (kill_count, reward, milestone_title)."""
    lines = [
        "| When | Reward |",
        "|---|---|",
        f"| Create your character | **+{starter}** Hunt Marks (starter stipend) |",
        f"| First login each day (UTC) | **+{daily}** Hunt Marks |",
    ]
    for days, marks, _label in streak:
        lines.append(f"| {days} days logged in a row | **+{marks:,}** Hunt Marks |")
    for num, reward, title in kills:
        ordinal = f"{num:,}{_ach._ordinal_suffix(num)}"
        lines.append(f"| Your {ordinal} NM kill | **+{reward:,}** — *{title}* |")
    return "\n".join(lines)


def _render_ladder(tiers: list[dict]) -> str:
    lines = [
        "| Rank | Unlock cost | Hunt Marks per kill |",
        "|---|---:|---:|",
    ]
    for t in tiers:
        name = t["name"].replace("-", "—").replace("|", "\\|")
        cost = "Free" if t["unlockCost"] == 0 else f"{t['unlockCost']:,}"
        pts_vals = [m["points"] for m in t["mobs"]]
        if not pts_vals:
            pts = "—"
        else:
            lo, hi = min(pts_vals), max(pts_vals)
            pts = f"{lo}" if lo == hi else f"{lo}–{hi}"
        lines.append(f"| {name} | {cost} | {pts} |")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    page = docs_dir / "getting-started" / "your-session.md"
    if not page.exists():
        print(f"[your_session] skip: target page {page} not found")
        return

    # --- Rewards table (starter + daily + streak + kill milestones) ---
    starter_txt = _read(repo_root, "modules/custom/lua/new_char_starter_marks.lua")
    daily_txt   = _read(repo_root, "modules/custom/lua/daily_login_bonus.lua")
    streak_txt  = _read(repo_root, "modules/custom/lua/login_streak.lua")
    ach_txt     = _read(repo_root, "modules/custom/lua/achievements.lua")

    if not all((starter_txt, daily_txt, streak_txt, ach_txt)):
        missing = [n for n, t in (
            ("new_char_starter_marks", starter_txt),
            ("daily_login_bonus", daily_txt),
            ("login_streak", streak_txt),
            ("achievements", ach_txt),
        ) if not t]
        print(f"[your_session] skip rewards: missing source(s) {', '.join(missing)}")
    else:
        starter = _parse_starter_marks(starter_txt)
        daily   = _login._parse_daily_bonus(daily_txt)
        streak  = _login._parse_streak_milestones(streak_txt)

        milestones = _ach._extract_milestones(ach_txt)
        rows = _ach._extract_rows(ach_txt)
        kills: list[tuple[int, int, str]] = []
        for r in rows.get("Hunting Milestones", []):
            ms = milestones.get(r["id"], {})
            kills.append((r["num"], ms.get("reward", 0), ms.get("title") or r["id"]))
        kills.sort(key=lambda k: k[0])

        # Guard: don't publish a stub if a parser silently returned nothing.
        if starter is None or not streak or not kills:
            print("[your_session] skip rewards: a parser returned empty "
                  f"(starter={starter}, streak={len(streak)}, kills={len(kills)}) "
                  "— keeping existing published content")
        else:
            content = _render_rewards(starter, daily, streak, kills)
            if write_between_markers(page, "session-rewards", content):
                print(f"[your_session] rewards: starter +{starter}, daily +{daily}, "
                      f"{len(streak)} streak rows, {len(kills)} kill milestones")
            else:
                print("[your_session] rewards: marker 'session-rewards' not found")

    # --- Rank ladder (unlock cost + marks per kill) ---
    hl_txt = _read(repo_root, "modules/custom/lua/hunting_league_catalog.lua")
    if hl_txt is None:
        print("[your_session] skip ladder: hunting_league_catalog.lua not found")
        return
    tiers = _hl._extract_tiers(hl_txt)
    if not tiers:
        print("[your_session] skip ladder: no tiers parsed — keeping existing content")
        return
    content = _render_ladder(tiers)
    if write_between_markers(page, "session-rank-ladder", content):
        print(f"[your_session] ladder: {len(tiers)} ranks written into marker")
    else:
        print("[your_session] ladder: marker 'session-rank-ladder' not found")
