#!/usr/bin/env python3
"""Regenerate docs/changelog.md from the current git history.

Run this AFTER the "Relaunch Deploy" marker commit exists (see
relaunch-rebuild.bat). The changelog generator drops commits that are NEWER
than the latest deploy marker ("not live yet"), so regenerating the page
BEFORE the current deploy's marker is committed makes every deploy's own
changes lag by one deploy. Running it here -- once the marker is in history --
puts this update on the page immediately.
"""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]          # tools/ -> repo root
sys.path.insert(0, str(ROOT / "tools" / "docgen"))  # so `generators` imports

from generators import changelog  # noqa: E402

changelog.generate(ROOT, ROOT / "docs")
