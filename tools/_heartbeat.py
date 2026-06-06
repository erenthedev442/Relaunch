"""Tiny shared heartbeat writer/reader for Legendary background jobs.

A "dead man's switch": every scheduled or long-running job calls
``write_heartbeat(repo_root, "<job>", ok=True)`` after a successful pass.
It drops a small JSON file at

    <repo_root>/tools/heartbeats/<job>.json

recording the last-success time. A monitor (the docs status-page generator)
reads this directory and flags any job whose heartbeat is older than its
expected cadence as STALE — so a silently-dead cron/daemon gets *noticed*
instead of failing in the dark.

Design notes:
  * stdlib only, import-light — any job can adopt it with zero new deps.
  * Writes are atomic (tmp + os.replace) so a reader never sees a partial file.
  * Never raises: a heartbeat failure must not take down the job it monitors.
    Every public function swallows OSError and returns a falsy/empty value.

The docs generator lives on a different git branch (the worktree) where this
file is absent, so it re-implements the trivial read itself rather than
importing this module — mirroring the _db.py duplication convention. This
module is the canonical copy for base-branch jobs.
"""
from __future__ import annotations

import json
import os
import time
from pathlib import Path


def heartbeat_dir(repo_root) -> Path:
    return Path(repo_root) / "tools" / "heartbeats"


def write_heartbeat(repo_root, name: str, ok: bool = True, detail: str = "") -> bool:
    """Record a last-success (or last-failure) heartbeat for job ``name``.

    Returns True on success, False if the write failed for any reason (the
    caller should not care — a missing heartbeat just shows up as STALE,
    which is the safe direction to fail).
    """
    d = heartbeat_dir(repo_root)
    try:
        d.mkdir(parents=True, exist_ok=True)
        now = time.time()
        payload = {
            "job": str(name),
            "ts": round(now, 3),
            "iso": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(now)),
            "ok": bool(ok),
            "detail": str(detail)[:300],
        }
        tmp = d / (str(name) + ".json.tmp")
        final = d / (str(name) + ".json")
        tmp.write_text(json.dumps(payload), encoding="utf-8")
        os.replace(tmp, final)
        return True
    except OSError:
        return False


def read_heartbeats(repo_root) -> dict:
    """Return ``{job_name: payload}`` for every heartbeat file present.

    Tolerant of a missing directory and of corrupt/partial JSON files —
    bad entries are simply skipped.
    """
    d = heartbeat_dir(repo_root)
    out: dict = {}
    try:
        files = sorted(d.glob("*.json"))
    except OSError:
        return out
    for f in files:
        try:
            data = json.loads(f.read_text(encoding="utf-8"))
        except (OSError, ValueError):
            continue
        if isinstance(data, dict) and data.get("job"):
            out[str(data["job"])] = data
    return out
