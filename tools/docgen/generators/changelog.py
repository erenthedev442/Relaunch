"""Generate docs/changelog.md — player-facing patch notes, grouped by week.

Reads ``git log`` from the server repo (D:\\server, or ``LEGENDARY_LIVE_ROOT``)
and turns it into a readable changelog:

  * "Deploy Everything" / "Live update" commits are treated as **deploy
    markers** — each one shipped everything committed since the previous
    marker, so they delimit one live UPDATE.
  * Only **player-facing** changes are kept (internal tooling — deploy,
    docgen, docs, tools, chore/ci/build/test — is dropped).
  * Conventional-commit subjects (``fix(pup): ...``) are cleaned into
    ``**PUP** — ...`` notes.
  * Updates are bucketed by the deploy DAY and grouped by WEEK, newest first,
    in collapsible MkDocs admonitions (latest week open).

On the Azure box ``LEGENDARY_LIVE_ROOT`` points at ``~/server``, which is NOT a
git checkout, so ``git log`` fails and this generator SKIPS — leaving the
committed changelog.md in place. The changelog is therefore generated on the
laptop (which has the history) and published as-is by the box. See
[[reference_deploy_watermark]] / [[reference_docs_site]].

TIMING: this generator drops commits NEWER than the latest "Deploy Everything"
marker (the not-live-yet guard in ``_build_updates``). So it MUST be run AFTER
the current deploy's marker commit exists, or that deploy's own changes lag by
one deploy. ``deploy-everything.bat`` step [2b] (``tools/regen_changelog.py``)
re-runs it post-marker for exactly this reason; running it in [1/5] alone is a
bug.
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

# How far back to look (calendar days).
_LOOKBACK_DAYS = 30


_DEFAULT_SERVER_ROOT = r"D:\server"

# A commit whose subject starts with one of these is a DEPLOY MARKER — it
# delimits a live update (everything older, back to the previous marker, went
# live with it). Never shown as a note itself.
_MARKER_PREFIXES = ("Deploy Everything", "Live update")

# Subjects starting with these are never player-facing.
_DROP_PREFIXES = ("Merge", "Auto-", "Revert", "wip", "WIP", "fixup", "squash")

# Conventional-commit TYPE in here -> internal, dropped (regardless of scope).
_INTERNAL_TYPES = {"docs", "chore", "ci", "build", "test", "style", "refactor"}

# Conventional-commit SCOPE in here -> internal tooling, dropped.
_INTERNAL_SCOPES = {
    "deploy", "docgen", "docs", "tools", "tool", "ci", "build", "chore",
    "test", "tests", "infra", "site", "repo", "git", "meta", "release",
    "game-master", "gm", "perf",
}

# Subjects CONTAINING any of these are dropped (retired-feature churn etc.).
_DROP_SUBSTRINGS = ("!shop attachments",)

# conventional-commit scope -> friendly category label shown to players.
_SCOPE_LABELS = {
    # jobs
    "pup": "PUP", "smn": "SMN", "blm": "BLM", "geo": "GEO", "sch": "SCH",
    "rdm": "RDM", "drg": "DRG", "cor": "COR", "brd": "BRD", "nin": "NIN",
    "war": "WAR", "thf": "THF", "pld": "PLD", "drk": "DRK", "bst": "BST",
    "mnk": "MNK", "whm": "WHM", "blu": "BLU", "run": "RUN", "sam": "SAM",
    "dnc": "DNC",
    # systems
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
}

_CC_RE = re.compile(r"^(?P<type>[a-zA-Z]+)(?:\((?P<scope>[^)]+)\))?:\s*(?P<msg>.+)$")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:  # noqa: ARG001
    server_root = Path(os.environ.get("LEGENDARY_LIVE_ROOT") or _DEFAULT_SERVER_ROOT)

    commits = _fetch_commits(server_root)
    if commits is None:
        print("[changelog] skip: git unavailable / not a repo (keeping committed changelog.md)")
        return

    updates = _build_updates(commits)
    if not updates:
        print("[changelog] skip: no player-facing updates in the window")
        return

    weeks = _group_by_week(updates)
    md = _render(weeks)

    out = docs_dir / "changelog.md"
    out.write_text(md, encoding="utf-8")
    notes = sum(len(u["notes"]) for u in updates)
    print(f"[changelog] wrote {len(weeks)} week(s), {len(updates)} update(s), {notes} notes -> {out}")


# ---------------------------------------------------------------------------
# Git
# ---------------------------------------------------------------------------

def _fetch_commits(server_root: Path) -> list[dict] | None:
    """Return commits (newest first) as {dt, subject}, or None if git is N/A."""
    if not server_root.exists():
        return None

    since = (datetime.now(tz=timezone.utc) - timedelta(days=_LOOKBACK_DAYS)).strftime("%Y-%m-%d")
    try:
        result = subprocess.run(
            ["git", "log", "--format=%cI|%s", "--no-merges", f"--since={since}"],
            cwd=str(server_root),
            capture_output=True,
            text=True,
            encoding="utf-8",      # decode git output as UTF-8 (Windows default cp1252 mangles → and —)
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

def _is_marker(subject: str) -> bool:
    return any(subject.startswith(p) for p in _MARKER_PREFIXES)


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
        if scope in _INTERNAL_SCOPES:
            return False
    return True


def _scope_label(scope: str) -> str:
    s = scope.lower()
    if s in _SCOPE_LABELS:
        return _SCOPE_LABELS[s]
    if len(scope) <= 4:
        return scope.upper()
    return scope.replace("-", " ").replace("_", " ").title()


def _clean(subject: str) -> str:
    """Turn a commit subject into a player-readable note."""
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
# Build updates (deploy-marker delimited, bucketed by day)
# ---------------------------------------------------------------------------

def _build_updates(commits: list[dict]) -> list[dict]:
    """One update per deploy DAY, holding the player-facing notes that shipped.

    commits are newest-first. Each marker opens an update dated by the marker;
    subsequent (older) player-facing commits attach to it until the next
    marker. Commits newer than the most recent marker are not live yet → skipped.
    """
    buckets: dict[object, dict] = {}
    order: list[object] = []
    current_day = None
    saw_marker = False

    for c in commits:
        subj = c["subject"]
        if _is_marker(subj):
            saw_marker = True
            current_day = c["dt"].date()
            if current_day not in buckets:
                buckets[current_day] = {"dt": c["dt"], "notes": []}
                order.append(current_day)
            continue
        if not _is_player_facing(subj):
            continue
        if current_day is None:
            continue  # newer than the latest deploy — not live yet
        note = _clean(subj)
        if note not in buckets[current_day]["notes"]:
            buckets[current_day]["notes"].append(note)

    # Fallback: a repo with NO deploy markers at all — bucket by commit day so
    # the changelog still renders something useful.
    if not saw_marker:
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
        "Recent updates to Legendary, newest first — generated from our live deploy history.",
        "",
        "---",
        "",
    ]
    for i, wk in enumerate(weeks):
        adm = "!!!" if i == 0 else "???"   # latest week open, older collapsed
        lines.append(f'{adm} note "{_fmt_week(wk["monday"], wk["sunday"])}"')
        for u in wk["updates"]:
            lines.append(f'    **{_fmt_day(u["dt"])}**')
            lines.append("")
            notes = u["notes"]
            for note in notes:
                lines.append(f"    - {note}")
            lines.append("")
    return "\n".join(lines).rstrip() + "\n"
