"""Generate docs/changelog.md from local git log.

Runs ``git log`` against the server repo (D:\\server or wherever the
generator is pointed) and groups commits by calendar date into collapsible
MkDocs admonition blocks, newest date first.

Filters:
  - Merge commits excluded via ``--no-merges``
  - Subject lines starting with "Merge", "Auto-", or "docs: auto" are
    additionally skipped to catch merge-style messages that slip through
    ``--no-merges`` and automated chore commits.

Output is always a full rewrite of docs/changelog.md — no DOCGEN
markers needed.
"""
from __future__ import annotations

import subprocess
from datetime import datetime, timedelta, timezone
from pathlib import Path


# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

# How far back to look (calendar days from now)
_LOOKBACK_DAYS = 90

# Subjects starting with any of these are silently dropped.
_SKIP_PREFIXES = ("Merge", "Auto-", "docs: auto")

# Subjects CONTAINING any of these are silently dropped -- keeps a retired
# feature out of the public changelog (both its add AND retire commits), so
# players never see churn for something that no longer exists. The short-lived
# "!shop attachments" category was replaced by a free grant at the GM Home
# Unlocker NPC; suppress its add/retire commits here.
_SKIP_SUBSTRINGS = ("!shop attachments",)

# Path to the server repo (git log source). Falls back to LEGENDARY_LIVE_ROOT
# env var, then to D:\server.
_DEFAULT_SERVER_ROOT = r"D:\server"


# ---------------------------------------------------------------------------
# Core
# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:  # noqa: ARG001
    """Entry point called by tools/docgen/generate.py."""
    import os

    server_root = os.environ.get("LEGENDARY_LIVE_ROOT") or _DEFAULT_SERVER_ROOT
    server_root = Path(server_root)

    commits = _fetch_commits(server_root)
    if commits is None:
        print("[changelog] skip: git not available or server repo not found")
        return
    if not commits:
        print("[changelog] skip: no commits found in the last 90 days")
        return

    days = _group_by_date(commits)
    md = _render(days)

    out = docs_dir / "changelog.md"
    out.write_text(md, encoding="utf-8")
    total = sum(len(v) for v in days.values())
    print(f"[changelog] wrote {len(days)} days, {total} commits -> {out.relative_to(docs_dir.parent)}")


# ---------------------------------------------------------------------------
# Git helpers
# ---------------------------------------------------------------------------

def _fetch_commits(server_root: Path) -> list[dict] | None:
    """Return a list of commit dicts, or None if git is unavailable."""
    if not server_root.exists():
        return None

    since = (datetime.now(tz=timezone.utc) - timedelta(days=_LOOKBACK_DAYS)).strftime("%Y-%m-%d")

    try:
        result = subprocess.run(
            ["git", "log", '--format=%ci|%s|%H', "--no-merges", f"--since={since}"],
            cwd=str(server_root),
            capture_output=True,
            text=True,
            timeout=30,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return None

    if result.returncode != 0:
        return None

    commits: list[dict] = []
    for line in result.stdout.splitlines():
        line = line.strip()
        if not line:
            continue
        parts = line.split("|", 2)
        if len(parts) < 3:
            continue
        date_str, subject, sha = parts[0].strip(), parts[1].strip(), parts[2].strip()

        # Filter noisy subjects
        if any(subject.startswith(pfx) for pfx in _SKIP_PREFIXES):
            continue
        if any(sub.lower() in subject.lower() for sub in _SKIP_SUBSTRINGS):
            continue

        try:
            # git --format=%ci → "2026-05-30 13:43:51 -0700"
            # Parse just the date portion
            dt = datetime.strptime(date_str[:10], "%Y-%m-%d").replace(tzinfo=timezone.utc)
        except ValueError:
            continue

        commits.append({"date": dt, "subject": subject, "sha": sha})

    return commits


# ---------------------------------------------------------------------------
# Grouping
# ---------------------------------------------------------------------------

def _group_by_date(commits: list[dict]) -> dict[str, dict]:
    """Group commits by calendar date (YYYY-MM-DD), newest first.

    Returns an ordered dict mapping sort_key → {"date": datetime, "commits": [...]}.
    """
    buckets: dict[str, dict] = {}
    for c in commits:
        key = c["date"].strftime("%Y-%m-%d")
        if key not in buckets:
            buckets[key] = {"date": c["date"], "commits": []}
        buckets[key]["commits"].append(c)

    return dict(sorted(buckets.items(), reverse=True))


def _date_label(dt: datetime) -> str:
    """Return a human-readable label like 'Sunday · June 15, 2026'."""
    return dt.strftime("%A · %B %-d, %Y")


# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------

def _render(days: dict[str, dict]) -> str:
    lines: list[str] = [
        "# Server Changelog",
        "",
        "Recent changes to Legendary. Updated automatically from our development history.",
        "",
        "---",
        "",
    ]

    for i, (_key, info) in enumerate(days.items()):
        label = _date_label(info["date"])
        # Leave the most recent day open, collapse the rest
        admonition = "!!!" if i == 0 else "???"
        lines.append(f'{admonition} note "{label}"')
        for c in info["commits"]:
            subject = c["subject"].replace("`", "'")
            lines.append(f"    - {subject}")
        lines.append("")

    return "\n".join(lines)
