"""Marker-based content replacement.

Generators that augment a hand-written page (rather than owning the whole
file) write their output between sentinel comments:

    <!-- DOCGEN:BEGIN id="my-section" -->
    ...generated content...
    <!-- DOCGEN:END id="my-section" -->

`write_between_markers()` replaces only what's between matching markers.
Hand-written content outside the markers is preserved verbatim. If markers
aren't present, the generator skips without modifying the file.
"""
from __future__ import annotations

import re
from pathlib import Path


def write_between_markers(path: Path, marker_id: str, content: str) -> bool:
    if not path.exists():
        return False
    text = path.read_text(encoding="utf-8")
    pattern = (
        rf'(<!--\s*DOCGEN:BEGIN\s+id="{re.escape(marker_id)}"\s*-->)'
        rf'.*?'
        rf'(<!--\s*DOCGEN:END\s+id="{re.escape(marker_id)}"\s*-->)'
    )
    replacement = r"\1" + "\n" + content.rstrip() + "\n" + r"\2"
    new_text, n = re.subn(pattern, replacement, text, count=1, flags=re.DOTALL)
    if n == 0:
        return False
    if new_text != text:
        path.write_text(new_text, encoding="utf-8")
    return True
