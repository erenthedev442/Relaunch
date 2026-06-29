"""Source-path resolution for docgen generators.

A generator's source may live in the repo (committed and visible to CI) or
only on the live server's checkout (gitignored). `resolve_source()` checks
the repo first, then `$LEGENDARY_LIVE_ROOT` if set.

CI never sees `$LEGENDARY_LIVE_ROOT`, so it only generates pages whose source
is committed. Generators gracefully skip when their source isn't available
rather than writing an empty/wrong page.
"""
from __future__ import annotations

import os
from pathlib import Path


def resolve_source(repo_root: Path, sub_path: str) -> Path | None:
    """Prefer the committed repo file so docs always reflect what's in GitHub.
    Falls back to LEGENDARY_LIVE_ROOT only for files not tracked in the repo
    (e.g. gitignored settings/*.lua). CI never sets the env var so it always
    uses repo content."""
    repo_path = repo_root / sub_path
    if repo_path.exists():
        return repo_path
    live = os.environ.get("LEGENDARY_LIVE_ROOT")
    if live:
        live_path = Path(live) / sub_path
        if live_path.exists():
            return live_path
    return None
