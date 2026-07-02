"""Sync docs/endgame/affinity-nms.md with augment_affinity_catalog.lua.

Parses the 24 affinity NM rows so re-ordering or renaming entries auto-updates
the docs page.

Marker written:
  affinity-nm-roster — 24 NM rows: name, zone, trophy, augment category
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers


def _qstr(text: str, key: str) -> str | None:
    """Extract value of `key='...'` or `key="..."` from a Lua table string."""
    m = re.search(r'\b' + re.escape(key) + r"""=(?:'([^']*)'|"([^"]*)")""", text)
    if not m:
        return None
    return m.group(1) if m.group(1) is not None else m.group(2)


def _parse(text: str) -> list[dict]:
    rows = []
    for line in text.splitlines():
        line = line.strip()
        if not line.startswith('{ cat='):
            continue
        cat_m = re.search(r'cat=(\d+)', line)
        if not cat_m:
            continue

        label   = _qstr(line, 'label')
        nm_raw  = _qstr(line, 'nm')
        nm_zone = _qstr(line, 'nmZone')

        # trophy name is inside trophy={...}; extract that sub-string first
        trophy_blk_m = re.search(r'trophy=\{([^}]*)\}', line)
        trophy_blk   = trophy_blk_m.group(1) if trophy_blk_m else ''
        trophy_name  = _qstr(trophy_blk, 'name')

        if not all([label, nm_raw, nm_zone, trophy_name]):
            continue

        nm_display = nm_raw.replace('_', ' ')
        rows.append({
            'cat':    int(cat_m.group(1)),
            'nm':     nm_display,
            'zone':   nm_zone,
            'trophy': trophy_name,
            'label':  label,
        })

    rows.sort(key=lambda r: r['cat'])
    return rows


def _render(rows: list[dict]) -> str:
    lines = [
        '| NM | Zone | Trophy Item | Augment Category |',
        '|---|---|---|---|',
    ]
    for r in rows:
        lines.append(f"| {r['nm']} | {r['zone']} | {r['trophy']} | {r['label']} |")
    return '\n'.join(lines)


def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, 'modules/custom/lua/augment_affinity_catalog.lua')
    if src is None:
        print('[affinity_nms] skip: augment_affinity_catalog.lua not found')
        return

    text = src.read_text(encoding='utf-8', errors='replace')
    rows = _parse(text)

    page = docs_dir / 'endgame' / 'affinity-nms.md'
    if not page.exists():
        print(f'[affinity_nms] skip: {page} not found')
        return

    written = write_between_markers(page, 'affinity-nm-roster', _render(rows))
    print(f'[affinity_nms] {"1/1 marker written" if written else "0/1 markers (already up-to-date)"} '
          f'(rows={len(rows)})')
