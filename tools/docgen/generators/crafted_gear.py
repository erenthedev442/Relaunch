"""Generate docs/economy/crafted-gear.md from the synthesis recipe data.

Crafting is a first-class acquisition path on the relaunch: sql/synth_recipes.sql
ships thousands of active recipes, and enable_craft_only_recipes.sql activates
the escutcheon-master lines (Raetic / Arasy / Was / Oshosi / job staves ...)
that stock LSB comments out. This page is the player-facing index of the
ENDGAME (item level 100+) equipment those recipes produce -- the gear whose
only source is a crafter.

Marker IDs: crafted-intro, crafted-ilvl
"""
from __future__ import annotations

import re
from collections import defaultdict
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._bgwiki import item_anchor

CRAFTS = ['Woodworking', 'Smithing', 'Goldsmithing', 'Clothcraft',
          'Leathercraft', 'Bonecraft', 'Alchemy', 'Cooking']

_ROW = re.compile(
    r"^INSERT INTO `synth_recipes` VALUES \((\d+),(\d+),(\d+),"
    r"(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),"      # 8 craft skills
    r"(?:\d+,){10}"                                           # crystals + ingredients
    r"(\d+),(\d+),(\d+),(\d+),", re.M)


def _recipes(repo_root: Path) -> list[dict]:
    out = []
    for rel in ('sql/synth_recipes.sql',
                'modules/custom/sql/enable_craft_only_recipes.sql'):
        src = resolve_source(repo_root, rel)
        if src is None:
            continue
        for m in _ROW.finditer(src.read_text(encoding='utf-8', errors='replace')):
            skills = {CRAFTS[i]: int(m.group(4 + i))
                      for i in range(8) if int(m.group(4 + i)) > 0}
            nq = int(m.group(12))
            hqs = {int(m.group(g)) for g in (13, 14, 15)} - {0, nq}
            out.append({'skills': skills, 'nq': nq, 'hqs': sorted(hqs)})
    return out


def _equipment(repo_root: Path) -> dict[int, dict]:
    """itemId -> {name, ilvl} for every equippable item."""
    src = resolve_source(repo_root, 'sql/item_equipment.sql')
    basic = resolve_source(repo_root, 'sql/item_basic.sql')
    if src is None or basic is None:
        return {}
    disp = {}
    for m in re.finditer(r"INSERT INTO `item_basic` VALUES \((\d+),\d+,'([^']+)'",
                         basic.read_text(encoding='utf-8', errors='replace')):
        parts = m.group(2).split('_')
        disp[int(m.group(1))] = ' '.join(
            p.capitalize() if not p.startswith('+') else p for p in parts)
    eq = {}
    for m in re.finditer(r"INSERT INTO `item_equipment` VALUES \((\d+),'[^']*',(\d+),(\d+),",
                         src.read_text(encoding='utf-8', errors='replace')):
        iid = int(m.group(1))
        eq[iid] = {'name': disp.get(iid, f'#{iid}'), 'lvl': int(m.group(2)),
                   'il': int(m.group(3))}
    return eq


def _skill_str(skills: dict) -> str:
    return ', '.join(f'{c} {v}' for c, v in sorted(skills.items(), key=lambda kv: -kv[1]))


def generate(repo_root: Path, docs_dir: Path) -> None:
    recipes = _recipes(repo_root)
    eq = _equipment(repo_root)
    if not recipes or not eq:
        print('[crafted_gear] skip: recipe/equipment sources missing')
        return

    # itemId -> (skills, isHq) for the LOWEST-skill recipe producing it
    best: dict[int, tuple[dict, bool]] = {}

    def consider(iid: int, skills: dict, is_hq: bool) -> None:
        it = eq.get(iid)
        if not it or it['il'] < 100:
            return
        cur = best.get(iid)
        if cur is None or max(skills.values(), default=0) < max(cur[0].values(), default=0):
            best[iid] = (skills, is_hq)

    for r in recipes:
        consider(r['nq'], r['skills'], False)
        for hq in r['hqs']:
            consider(hq, r['skills'], True)

    n_recipes = len(recipes)
    n_items = len(best)

    intro = (
        f"Crafting on the relaunch is a real gear pipeline: **{n_recipes:,} synthesis "
        f"recipes** are live, including the retail *escutcheon-master* lines that stock "
        f"data ships disabled — here they are open to anyone at **skill 110** (the "
        f"escutcheon key items are waived). The table below lists every **item level "
        f"100+** piece of equipment a crafter can make — **{n_items:,} items**, many of "
        f"them craft-exclusive (Raetic, Arasy, Was, Oshosi, the job staves and more "
        f"exist nowhere else on the server). HQ tiers come from the same synth at "
        f"higher quality; sub-99 crafted gear is also stocked cheaply by the Auction "
        f"House market-maker."
    )

    by_craft: dict[str, list] = defaultdict(list)
    for iid, (skills, is_hq) in best.items():
        primary = max(skills.items(), key=lambda kv: kv[1])[0] if skills else 'Other'
        by_craft[primary].append((iid, skills, is_hq))

    lines = []
    for craft in CRAFTS:
        rows = by_craft.get(craft)
        if not rows:
            continue
        lines.append(f'### {craft}')
        lines.append('')
        lines.append('| Item | iLvl | Skill | Quality |')
        lines.append('|---|---:|---|---|')
        rows.sort(key=lambda r: (-(eq[r[0]]['il']), eq[r[0]]['name']))
        for iid, skills, is_hq in rows:
            it = eq[iid]
            link = item_anchor(it['name'], item_id=iid)
            lines.append(f"| {link} | {it['il']} | {_skill_str(skills)} | "
                         f"{'HQ' if is_hq else 'NQ'} |")
        lines.append('')

    page = docs_dir / 'economy' / 'crafted-gear.md'
    blocks = [('crafted-intro', intro), ('crafted-ilvl', '\n'.join(lines).rstrip())]
    written = sum(1 for mk, content in blocks if write_between_markers(page, mk, content))
    print(f'[crafted_gear] {written}/{len(blocks)} marker block(s) written '
          f'({n_items} ilvl craftables, {n_recipes} recipes)')
