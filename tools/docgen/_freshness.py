"""Post-docgen freshness gate.

Two silent-drift signals the old build ignored:

  1. A generator that "succeeded" but wrote an EMPTY marker block (e.g. its
     source parsed to nothing) — the page ships with a blank section.
  2. (handled in _paths.py) a generator whose required source went missing —
     it raises SourceMissing, is caught as a failure, and this gate's caller
     fails the build.

`find_empty_marker_blocks()` scans every generated page for DOCGEN marker
blocks that are empty/whitespace. The stamp footer (id="last-updated") is
never a content block, so it's excluded.
"""
from __future__ import annotations

import re
from pathlib import Path

# Matches: <!-- DOCGEN:BEGIN id="X" -->  ...body...  <!-- DOCGEN:END id="X" -->
_BLOCK_RE = re.compile(
    r'<!--\s*DOCGEN:BEGIN\s+id="(?P<id>[^"]+)"\s*-->'
    r'(?P<body>.*?)'
    r'<!--\s*DOCGEN:END\s+id="(?P=id)"\s*-->',
    re.DOTALL,
)

# Marker ids that are structural, not content (never expected to hold prose).
_EXCLUDED_IDS = {"last-updated"}


def find_empty_marker_blocks(docs_dir: Path) -> list[tuple[str, str]]:
    """Return [(page_relpath, marker_id), ...] for every DOCGEN block whose
    body is empty or only whitespace/HTML-comment noise."""
    empties: list[tuple[str, str]] = []
    for path in sorted(docs_dir.rglob("*.md")):
        try:
            text = path.read_text(encoding="utf-8")
        except OSError:
            continue
        for m in _BLOCK_RE.finditer(text):
            mid = m.group("id")
            if mid in _EXCLUDED_IDS:
                continue
            body = m.group("body")
            # Strip HTML comments (e.g. a leftover content-hash) before judging.
            body = re.sub(r"<!--.*?-->", "", body, flags=re.DOTALL).strip()
            if not body:
                empties.append((path.relative_to(docs_dir).as_posix(), mid))
    return empties
