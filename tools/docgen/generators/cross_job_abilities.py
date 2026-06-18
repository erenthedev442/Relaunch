"""Generate Cross-Job Abilities catalog table inside docs/progression/cross-job-abilities.md.

Reads:
  modules/custom/lua/cross_job_ability_catalog.lua

Marker filled:
  cross-job-abilities-catalog
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers

_CATALOG = "modules/custom/lua/cross_job_ability_catalog.lua"
_DOC     = "docs/progression/cross-job-abilities.md"


# ---------------------------------------------------------------------------
# Lua helpers (established pattern — duplicated per generator)
# ---------------------------------------------------------------------------

def _balanced_blocks(text: str):
    """Yield (start, end+1) offsets for every top-level {…} block in *text*."""
    depth = 0
    in_single = False
    in_double = False
    start = -1
    i = 0
    while i < len(text):
        c = text[i]
        if not in_single and not in_double and text[i:i+2] == '--':
            end_of_line = text.find('\n', i)
            i = end_of_line + 1 if end_of_line != -1 else len(text)
            continue
        if c == "'" and not in_double:
            in_single = not in_single
        elif c == '"' and not in_single:
            in_double = not in_double
        elif not in_single and not in_double:
            if c == '{':
                if depth == 0:
                    start = i
                depth += 1
            elif c == '}':
                depth -= 1
                if depth == 0 and start != -1:
                    yield (start, i + 1)
                    start = -1
        i += 1


# ---------------------------------------------------------------------------
# Parsers
# ---------------------------------------------------------------------------

def _parse_groups(text: str) -> list[dict]:
    """Return list of {name, abilities:[{id,name,job,lvl,desc}]}."""
    m = re.search(r'catalog\.groups\s*=\s*\{', text)
    if not m:
        return []

    # Extract the outer groups block (the { } that wraps all group entries)
    suffix = text[m.start():]
    outer_block = None
    for s, e in _balanced_blocks(suffix):
        outer_block = suffix[s:e]
        break
    if not outer_block:
        return []

    groups = []
    inner = outer_block[1:-1]  # strip enclosing { }

    for gs, ge in _balanced_blocks(inner):
        group_block = inner[gs:ge]

        # The first name = '...' in the group block is the group name (before any
        # ability names appear inside the abilities sub-block).
        name_m = re.search(r"name\s*=\s*'([^']+)'", group_block)
        if not name_m:
            continue
        group_name = name_m.group(1)

        # Find the abilities = { ... } sub-block
        ab_m = re.search(r'\babilities\s*=\s*\{', group_block)
        if not ab_m:
            continue

        ab_suffix = group_block[ab_m.start():]
        abilities: list[dict] = []

        for abs_, abe in _balanced_blocks(ab_suffix):
            ab_block = ab_suffix[abs_:abe]
            # Each entry inside the abilities block
            ab_inner = ab_block[1:-1]
            for es, ee in _balanced_blocks(ab_inner):
                entry = ab_inner[es:ee]
                id_m   = re.search(r'\bid\s*=\s*(\d+)', entry)
                nm_m   = re.search(r"\bname\s*=\s*'([^']+)'", entry)
                job_m  = re.search(r"\bjob\s*=\s*'([^']+)'", entry)
                lvl_m  = re.search(r'\blvl\s*=\s*(\d+)', entry)
                desc_m = re.search(r"\bdesc\s*=\s*'([^']+)'", entry)
                if not (id_m and nm_m and job_m and lvl_m and desc_m):
                    continue
                abilities.append({
                    'id':   int(id_m.group(1)),
                    'name': nm_m.group(1),
                    'job':  job_m.group(1),
                    'lvl':  int(lvl_m.group(1)),
                    'desc': desc_m.group(1),
                })
            break  # only one abilities block per group

        if abilities:
            groups.append({'name': group_name, 'abilities': abilities})

    return groups


# ---------------------------------------------------------------------------
# Renderer
# ---------------------------------------------------------------------------

def _render_catalog(gil_cost: int, groups: list[dict]) -> str:
    total_abilities = sum(len(g['abilities']) for g in groups)
    lines = [
        f'_Each ability costs **{gil_cost:,} gil** — a one-time, per-character, per-ability purchase. '
        f'After buying, activate via macro: `/ja "Ability Name" <me>`. '
        f'Purchased abilities do **not** appear in the in-game Job Abilities menu (the menu is client-side); '
        f'they are enforced server-side and their recast timers work normally._',
        '',
        f'_**{total_abilities} abilities** available across {len(groups)} job groups._',
        '',
    ]

    for group in groups:
        lines.append(f'**{group["name"]}**')
        lines.append('')
        lines.append('| Ability | Job | Lv. | Effect |')
        lines.append('|---|---|---:|---|')
        for ab in group['abilities']:
            lines.append(f'| {ab["name"]} | {ab["job"]} | {ab["lvl"]} | {ab["desc"]} |')
        lines.append('')

    return '\n'.join(lines).rstrip() + '\n'


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, _CATALOG)
    if src is None:
        print(f"[cross_job_abilities] skip: {_CATALOG} not found")
        return

    page = docs_dir / "progression" / "cross-job-abilities.md"
    if not page.exists():
        print(f"[cross_job_abilities] skip: {page} not found")
        return

    text     = src.read_text(encoding="utf-8", errors="replace")
    gil_cost = int(m.group(1)) if (m := re.search(r'catalog\.GIL_COST\s*=\s*(\d+)', text)) else 10_000_000
    groups   = _parse_groups(text)

    if not groups:
        raise RuntimeError("[cross_job_abilities] no groups parsed from catalog")

    content = _render_catalog(gil_cost, groups)
    wrote   = write_between_markers(page, "cross-job-abilities-catalog", content)

    total = sum(len(g['abilities']) for g in groups)
    if wrote:
        print(f"[cross_job_abilities] catalog: {total} abilities across {len(groups)} groups written into marker")
    else:
        print(f"[cross_job_abilities] marker 'cross-job-abilities-catalog' not found in {page.name}")
