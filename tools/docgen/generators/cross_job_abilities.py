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

# Per-job accent colors (FFXI-flavored). Missing jobs fall back to the theme accent.
_JOB_COLOR = {
    'WAR': '#c0392b', 'MNK': '#e67e22', 'WHM': '#7f8c8d', 'BLM': '#8e44ad',
    'RDM': '#e74c3c', 'THF': '#27ae60', 'PLD': '#2980b9', 'DRK': '#34495e',
    'BST': '#16a085', 'BRD': '#f39c12', 'RNG': '#2ecc71', 'SAM': '#d35400',
    'NIN': '#2c3e50', 'DRG': '#3498db', 'SMN': '#9b59b6', 'BLU': '#2980b9',
    'COR': '#95a5a6', 'PUP': '#7f8c8d', 'DNC': '#e84393', 'SCH': '#1abc9c',
    'GEO': '#16a085', 'RUN': '#0984e3',
}

_CJA_CSS = """<style>
.cja-group{margin:1.6rem 0 .55rem;font-size:1.05rem;font-weight:700;letter-spacing:.01em;
  display:flex;align-items:center;gap:.55rem}
.cja-group::after{content:"";flex:1;height:1px;background:var(--md-default-fg-color--lightest)}
.cja-count{font-size:.72rem;font-weight:600;color:var(--md-default-fg-color--light);
  background:var(--md-default-fg-color--lightest);border-radius:10px;padding:.05rem .5rem}
.cja-grid{display:grid;gap:.7rem;grid-template-columns:repeat(auto-fill,minmax(255px,1fr))}
.cja-card{border:1px solid var(--md-default-fg-color--lightest);border-left:4px solid var(--acc);
  border-radius:9px;padding:.7rem .85rem .75rem;background:var(--md-default-bg-color);
  transition:transform .12s ease,box-shadow .12s ease}
.cja-card:hover{transform:translateY(-2px);box-shadow:0 4px 14px rgba(0,0,0,.14)}
.cja-top{display:flex;align-items:center;justify-content:space-between;gap:.5rem;margin-bottom:.4rem}
.cja-name{font-weight:700;font-size:.96rem;line-height:1.2}
.cja-badges{display:flex;gap:.3rem;flex-shrink:0}
.cja-job{font-size:.64rem;font-weight:700;letter-spacing:.03em;color:#fff;background:var(--acc);
  padding:.12rem .42rem;border-radius:4px}
.cja-lvl{font-size:.64rem;font-weight:700;color:var(--md-default-fg-color--light);
  background:var(--md-default-fg-color--lightest);padding:.12rem .42rem;border-radius:4px;white-space:nowrap}
.cja-eff{margin:0;font-size:.82rem;line-height:1.4;color:var(--md-default-fg-color--light)}
</style>"""


def _esc(s: str) -> str:
    return s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')


def _render_catalog(gil_cost: int, groups: list[dict]) -> str:
    total_abilities = sum(len(g['abilities']) for g in groups)
    out = [
        f'_Each ability costs **{gil_cost:,} gil** — a one-time, per-character, per-ability purchase. '
        f'After buying, activate via macro: `/ja "Ability Name" <me>`. '
        f'Purchased abilities do **not** appear in the in-game Job Abilities menu (the menu is client-side); '
        f'they are enforced server-side and their recast timers work normally._',
        '',
        f'_**{total_abilities} abilities** available across {len(groups)} job groups._',
        '',
        _CJA_CSS,
        '',
    ]

    for group in groups:
        n = len(group['abilities'])
        out.append(f'<div class="cja-group">{_esc(group["name"])}'
                   f'<span class="cja-count">{n} {"ability" if n == 1 else "abilities"}</span></div>')
        out.append('<div class="cja-grid">')
        for ab in group['abilities']:
            acc = _JOB_COLOR.get(ab['job'].upper(), 'var(--md-accent-fg-color,#7c4dff)')
            out.append(
                f'<div class="cja-card" style="--acc:{acc}">'
                f'<div class="cja-top"><span class="cja-name">{_esc(ab["name"])}</span>'
                f'<span class="cja-badges"><span class="cja-job">{_esc(ab["job"])}</span>'
                f'<span class="cja-lvl">Lv.{ab["lvl"]}</span></span></div>'
                f'<p class="cja-eff">{_esc(ab["desc"])}</p></div>'
            )
        out.append('</div>')

    return '\n'.join(out).rstrip() + '\n'


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
