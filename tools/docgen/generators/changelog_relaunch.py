"""Generate docs/changelog.md for the RELAUNCH server.

Shows all player-facing commits on the relaunch branch that are NOT on
the Legendary branch (git log HEAD --not origin/Legendary).  There are no
"Deploy Everything" markers on the relaunch branch, so commits are bucketed
by the day they were written and grouped by calendar week.

This runs on the Azure box because ~/relaunch IS a git worktree — git log
works there — so the changelog auto-updates every hourly cron without any
laptop step.
"""
from __future__ import annotations

import os
import re
import subprocess
from datetime import datetime, timedelta, timezone
from pathlib import Path


# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

_LOOKBACK_DAYS = 90  # show up to 3 months of relaunch history

_DEFAULT_SERVER_ROOT = r"D:\server_relaunch"

_DROP_PREFIXES = ("Merge", "Auto-", "Revert", "wip", "WIP", "fixup", "squash")
_DROP_SUBSTRINGS = ("pre-sync",)

_INTERNAL_TYPES  = {"docs", "chore", "ci", "build", "test", "style", "refactor"}
_INTERNAL_SCOPES = {
    "deploy", "docgen", "docs", "tools", "tool", "ci", "build", "chore",
    "test", "tests", "infra", "site", "repo", "git", "meta", "release",
    "game-master", "gm", "perf",
}

_SCOPE_LABELS = {
    "pup": "PUP", "smn": "SMN", "blm": "BLM", "geo": "GEO", "sch": "SCH",
    "rdm": "RDM", "drg": "DRG", "cor": "COR", "brd": "BRD", "nin": "NIN",
    "war": "WAR", "thf": "THF", "pld": "PLD", "drk": "DRK", "bst": "BST",
    "mnk": "MNK", "whm": "WHM", "blu": "BLU", "run": "RUN", "sam": "SAM",
    "dnc": "DNC",
    "battleutils": "Combat", "combat": "Combat", "magic": "Magic",
    "spell": "Magic", "spells": "Magic", "blue-magic": "Blue Magic",
    "weapon-skill": "Weapon Skills", "weaponskill": "Weapon Skills",
    "ws": "Weapon Skills",
    "augments": "Augments", "augment": "Augments",
    "items": "Items", "item": "Items", "gear": "Gear", "shop": "Shop",
    "trust": "Trusts", "trusts": "Trusts",
    "casino": "Casino", "ascension": "Ascension", "abyssea": "Abyssea",
    "mystats": "Commands", "command": "Commands", "commands": "Commands",
    "mob": "Monsters", "mobs": "Monsters", "nm": "Notorious Monsters",
    "pet": "Pets", "pets": "Pets",
    "hunting-league": "Hunting League", "reforge": "Reforge",
    "prime": "Prime Weapons", "dungeon": "Dungeons", "dungeons": "Dungeons",
    "always-popped-nms": "World NMs", "capacity": "Capacity Points",
    "subjob": "Subjobs", "merit": "Merits", "jobpoint": "Job Points",
    "voidwatch": "Voidwatch", "fellow": "Adventuring Fellow",
    "boom": "Boom Job", "affinity": "Augment Affinity",
    "relaunch": "Relaunch",
}

_CC_RE = re.compile(r"^(?P<type>[a-zA-Z]+)(?:\((?P<scope>[^)]+)\))?:\s*(?P<msg>.+)$")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:  # noqa: ARG001
    server_root = Path(os.environ.get("LEGENDARY_LIVE_ROOT") or _DEFAULT_SERVER_ROOT)

    commits = _fetch_commits(server_root)
    if commits is None:
        print("[changelog_relaunch] skip: git unavailable / not a repo (keeping committed changelog.md)")
        return

    if not commits:
        print("[changelog_relaunch] skip: no relaunch-only commits found")
        return

    updates = _build_updates(commits)
    if not updates:
        print("[changelog_relaunch] skip: no player-facing updates found")
        return

    weeks = _group_by_week(updates)
    md = _render(weeks)

    out = docs_dir / "changelog.md"
    out.write_text(md, encoding="utf-8")
    notes = sum(len(u["notes"]) for u in updates)
    print(f"[changelog_relaunch] wrote {len(weeks)} week(s), {len(updates)} update(s), {notes} notes -> {out}")


# ---------------------------------------------------------------------------
# Git — only commits on relaunch, not in Legendary
# ---------------------------------------------------------------------------

def _fetch_commits(server_root: Path) -> list[dict] | None:
    if not server_root.exists():
        return None

    since = (datetime.now(tz=timezone.utc) - timedelta(days=_LOOKBACK_DAYS)).strftime("%Y-%m-%d")
    try:
        result = subprocess.run(
            [
                "git", "log",
                "HEAD", "--not", "origin/Legendary",
                "--format=%cI|%s",
                "--no-merges",
                f"--since={since}",
            ],
            cwd=str(server_root),
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=30,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return None
    if result.returncode != 0:
        return None

    commits: list[dict] = []
    for line in result.stdout.splitlines():
        line = line.strip()
        if not line or "|" not in line:
            continue
        date_str, subject = line.split("|", 1)
        try:
            dt = datetime.fromisoformat(date_str.strip())
        except ValueError:
            continue
        commits.append({"dt": dt, "subject": subject.strip()})
    return commits


# ---------------------------------------------------------------------------
# Classification + cleaning
# ---------------------------------------------------------------------------

def _is_player_facing(subject: str) -> bool:
    if any(subject.startswith(p) for p in _DROP_PREFIXES):
        return False
    low = subject.lower()
    if any(s in low for s in _DROP_SUBSTRINGS):
        return False
    m = _CC_RE.match(subject)
    if m:
        if m.group("type").lower() in _INTERNAL_TYPES:
            return False
        scope = (m.group("scope") or "").lower()
        # strip "relaunch/" prefix if nested (e.g. "relaunch/voidwatch" -> "voidwatch")
        if "/" in scope:
            scope = scope.split("/", 1)[1]
        if scope in _INTERNAL_SCOPES:
            return False
    return True


def _scope_label(scope: str) -> str:
    # handle "relaunch/voidwatch" -> use the sub-scope
    if "/" in scope:
        scope = scope.split("/", 1)[1]
    s = scope.lower()
    if s in _SCOPE_LABELS:
        return _SCOPE_LABELS[s]
    if len(scope) <= 4:
        return scope.upper()
    return scope.replace("-", " ").replace("_", " ").title()


def _clean(subject: str) -> str:
    m = _CC_RE.match(subject)
    if not m:
        return subject[:1].upper() + subject[1:]
    msg = m.group("msg").strip()
    msg = msg[:1].upper() + msg[1:]
    scope = (m.group("scope") or "").strip()
    if scope:
        return f"**{_scope_label(scope)}** — {msg}"
    return msg


# ---------------------------------------------------------------------------
# Build updates — bucket by commit day (no deploy markers)
# ---------------------------------------------------------------------------

def _build_updates(commits: list[dict]) -> list[dict]:
    buckets: dict[object, dict] = {}
    order: list[object] = []
    for c in commits:
        if not _is_player_facing(c["subject"]):
            continue
        day = c["dt"].date()
        if day not in buckets:
            buckets[day] = {"dt": c["dt"], "notes": []}
            order.append(day)
        note = _clean(c["subject"])
        if note not in buckets[day]["notes"]:
            buckets[day]["notes"].append(note)
    return [buckets[d] for d in order if buckets[d]["notes"]]


# ---------------------------------------------------------------------------
# Group by week + render
# ---------------------------------------------------------------------------

def _week_bounds(dt: datetime):
    monday = dt.date() - timedelta(days=dt.weekday())
    return monday, monday + timedelta(days=6)


def _group_by_week(updates: list[dict]) -> list[dict]:
    weeks: dict[object, dict] = {}
    order: list[object] = []
    for u in updates:
        monday, sunday = _week_bounds(u["dt"])
        if monday not in weeks:
            weeks[monday] = {"monday": monday, "sunday": sunday, "updates": []}
            order.append(monday)
        weeks[monday]["updates"].append(u)
    return [weeks[m] for m in order]


def _fmt_day(dt: datetime) -> str:
    return f"{dt:%A}, {dt:%B} {dt.day}"


def _fmt_week(monday, sunday) -> str:
    if monday.month == sunday.month:
        return f"Week of {monday:%B} {monday.day}–{sunday.day}, {sunday.year}"
    return f"Week of {monday:%B} {monday.day} – {sunday:%B} {sunday.day}, {sunday.year}"


def _render(weeks: list[dict]) -> str:
    lines = [
        "# Server Changelog",
        "",
        "Recent updates to the Relaunch server, newest first.",
        "",
        "---",
        "",
    ]
    for i, wk in enumerate(weeks):
        adm = "!!!" if i == 0 else "???"
        lines.append(f'{adm} note "{_fmt_week(wk["monday"], wk["sunday"])}"')
        for u in wk["updates"]:
            lines.append(f'    **{_fmt_day(u["dt"])}**')
            lines.append("")
            for note in u["notes"]:
                lines.append(f"    - {note}")
            lines.append("")
    return "\n".join(lines).rstrip() + "\n"
