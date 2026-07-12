"""Sync docs/endgame/ambuscade.md numbers with scripts/globals/ambuscade.lua.

The Ambuscade economy lives as literals in ambuscade.lua: the monthly Hallmark
cap, the per-clear Hallmark and Gallantry tables, the armor voucher prices, the
armor-upgrade material cost + quantities, the Abdhaljs Seal (price / weekly
claim / effect), and the Gallantry shop. Surface the player-facing numbers into
marker blocks on the hand-written page so tuning a value in the Lua updates the
docs on the next build instead of leaving them to drift (which is exactly how
the monthly cap ended up hard-duplicated in two spots).

Markers written:
  amb-cap        - monthly Hallmark cap bullet
  amb-rewards    - Hallmarks-per-clear table by mode/difficulty (+ Gallantry note)
  amb-vouchers   - armor voucher price table (NQ / +1)
  amb-armor-sets - job -> set mapping + per-set piece tables with item links
                   (from ARMOR_SETS/JOB_SETS, so the armor names/ids can't drift)
  amb-materials  - armor upgrade material cost + trade table
  amb-seal       - Abdhaljs Seal (cost, weekly claim, effect)
  amb-galshop    - Gallantry shop price table
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section
from tools.docgen._bgwiki import urls_for_item
from tools.docgen.generators.gear_finder import display_name


def _c(n: int) -> str:
    return f"{n:,}"


def _int(pattern: str, text: str, default: int = 0) -> int:
    m = re.search(pattern, text)
    return int(m.group(1)) if m else default


def _idx_map(block: str) -> dict:
    return {int(k): int(v) for k, v in re.findall(r"\[(\d+)\]\s*=\s*(\d+)", block)}


def _rows(block: str):
    # Shop rows are { itemId, 'label', cost }.
    return [(int(i), lbl, int(cost)) for i, lbl, cost in
            re.findall(r"\{\s*(\d+)\s*,\s*'([^']+)'\s*,\s*(\d+)\s*\}", block)]


def _parse_armor_sets(text: str) -> tuple[dict, list]:
    """ARMOR_SETS -> {key: {label, mat, nq: [5 ids]}}; JOB_SETS -> [(job, l1, l2)]."""
    sets: dict = {}
    for m in re.finditer(
        r"(\w+)\s*=\s*\{\s*label\s*=\s*(?:'([^']*)'|\"([^\"]*)\")\s*,"
        r"\s*mat\s*=\s*MAT_(\w+)\s*,\s*nq\s*=\s*\{([\d\s,]+)\}",
        section(text, "ARMOR_SETS"),
    ):
        sets[m.group(1)] = {
            "label": m.group(2) or m.group(3),
            "mat":   m.group(4).capitalize(),
            "nq":    [int(x) for x in re.findall(r"\d+", m.group(5))],
        }
    jobs = re.findall(
        r"\[xi\.job\.(\w+)\]\s*=\s*\{\s*line1\s*=\s*'(\w+)'\s*,\s*line2\s*=\s*'(\w+)'",
        section(text, "JOB_SETS"),
    )
    return sets, jobs


def _parse(text: str) -> dict:
    c: dict = {}
    c["cap"] = _int(r"MONTHLY_HM_CAP\s*=\s*(\d+)", text, 45000)
    c["sets"], c["job_sets"] = _parse_armor_sets(text)
    c["hm"]  = _idx_map(section(text, "HALLMARKS"))
    c["gal"] = _idx_map(section(text, "GALLANTRY_PER_EXTRA"))

    shop = _rows(section(text, "HM_SHOP"))
    c["vouchers"] = {lbl: cost for _, lbl, cost in shop if lbl.startswith("Vou.")}
    c["material"] = next((cost for _, lbl, cost in shop if lbl == "Metal"), 100)

    c["galshop"] = [(lbl, cost) for _, lbl, cost in _rows(section(text, "GAL_SHOP"))]

    c["seal_cost"]   = _int(r"SEAL_HM_COST\s*=\s*(\d+)", text, 2000)
    c["seal_weekly"] = _int(r"SEAL_WEEKLY\s*=\s*(\d+)", text, 2)

    # Armor upgrade quantities from the UPGRADES build loop (NQ->+1, +1->+2).
    c["qty_p1"] = _int(r"nq\[i\]\][^\n]*qty\s*=\s*(\d+)", text, 5)
    c["qty_p2"] = _int(r"p1\[i\]\][^\n]*qty\s*=\s*(\d+)", text, 10)
    return c


# ---------------------------------------------------------------------------

def _render_cap(c: dict) -> str:
    return (f"- **Monthly cap:** {_c(c['cap'])} Hallmarks per calendar month "
            f"(Gallantry is uncapped).")


# Difficulty index layout in the Lua tables: Intense 1-5, Regular 6-10, Light
# 11-15, each VD/D/N/E/VE. (Set in DIFF_NAME.)
_MODES = [("Intense", 1), ("Regular", 6), ("Light", 11)]


def _render_rewards(c: dict) -> str:
    hm = c["hm"]
    lines = ["| Mode | VD | D | N | E | VE |", "|---|--:|--:|--:|--:|--:|"]
    for name, base in _MODES:
        cells = " | ".join(_c(hm.get(base + i, 0)) for i in range(5))
        lines.append(f"| **{name}** | {cells} |")
    vd = c["gal"].get(1, 0)
    lines.append("")
    lines.append(f"*Gallantry is a party reward: an **Intense VD** clear pays "
                 f"**{vd}** per extra party member (scaling down with difficulty); "
                 f"solo clears pay 0.*")
    return "\n".join(lines)


# Voucher label (in the Lua) -> display slot, split into the NQ and +1 columns.
_VOUCHER_SLOTS = [
    ("Head",  "Vou.Head",  "Vou.Hd+1"),
    ("Body",  "Vou.Body",  "Vou.Bd+1"),
    ("Hands", "Vou.Hands", "Vou.Hnd+1"),
    ("Legs",  "Vou.Legs",  "Vou.Lg+1"),
    ("Feet",  "Vou.Feet",  "Vou.Ft+1"),
]


def _render_vouchers(c: dict) -> str:
    v = c["vouchers"]
    lines = ["| Voucher | Cost (HM) | Voucher | Cost (HM) |",
             "|---|---:|---|---:|"]
    for slot, nq_key, p1_key in _VOUCHER_SLOTS:
        nq = v.get(nq_key)
        p1 = v.get(p1_key)
        if nq is None or p1 is None:
            continue
        lines.append(f"| {slot} | {_c(nq)} | {slot} +1 | {_c(p1)} |")
    return "\n".join(lines)


_SLOTS = ["Head", "Body", "Hands", "Legs", "Feet"]


def _item_link(name: str, item_id: int) -> str:
    """FFXIAH link with a data-img hover icon, matching the vendor tables."""
    page_url, image_url = urls_for_item(name, None, item_id=item_id)
    return (
        f'<a class="item-link" href="{page_url}" '
        f'data-img="{image_url}" target="_blank" rel="noopener">{name}</a>'
    )


def _load_item_names(repo_root: Path, ids: set[int]) -> dict[int, str]:
    """id -> display name for just the ids we need, from sql/item_basic.sql."""
    src = resolve_source(repo_root, "sql/item_basic.sql")
    names: dict[int, str] = {}
    if src is None:
        return names
    for m in re.finditer(r"VALUES \((\d+),\d+,'([^']+)'",
                         src.read_text(encoding="utf-8", errors="replace")):
        iid = int(m.group(1))
        if iid in ids:
            names[iid] = display_name(m.group(2))
    return names


def _render_armor_sets(c: dict, item_names: dict[int, str]) -> str:
    sets, job_sets = c["sets"], c["job_sets"]

    # Job -> set-pair mapping, grouping jobs that share the same pair.
    grouped: dict[tuple, list[str]] = {}
    for job, l1, l2 in job_sets:
        grouped.setdefault((l1, l2), []).append(job)
    lines = ["| Job | Set 1 (upgrades w/ Metal) | Set 2 (upgrades w/ Fiber) |",
             "|---|---|---|"]
    for (l1, l2), jobs in grouped.items():
        s1 = sets.get(l1, {}).get("label", l1)
        s2 = sets.get(l2, {}).get("label", l2)
        lines.append(f"| {' / '.join(jobs)} | {s1} | {s2} |")

    # Per-set pieces (NQ ids; +1/+2 share the names) with item links.
    lines += ["", "### The pieces", "",
              "| Set | " + " | ".join(_SLOTS) + " |",
              "|---|" + "---|" * len(_SLOTS)]
    for key in sorted(sets, key=lambda k: (sets[k]["mat"], sets[k]["label"])):
        s = sets[key]
        cells = []
        for iid in s["nq"]:
            name = item_names.get(iid)
            cells.append(_item_link(name, iid) if name else f"item {iid}")
        lines.append(f"| **{s['label']}** ({s['mat']}) | " + " | ".join(cells) + " |")
    lines += ["", "*Links show the NQ piece — the +1/+2 upgrades keep the same "
              "name and are made by trade (below).*"]
    return "\n".join(lines)


def _render_materials(c: dict) -> str:
    return (
        f"Trade the armor piece to **Gorpa-Masorpa** with its line's Abdhaljs "
        f"material (sold in the Hallmark shop for **{_c(c['material'])} HM** each):\n\n"
        f"| Trade | Result |\n"
        f"|---|---|\n"
        f"| NQ piece + **{c['qty_p1']}×** Abdhaljs Metal/Fiber | **+1** piece |\n"
        f"| +1 piece + **{c['qty_p2']}×** Abdhaljs Metal/Fiber | **+2** piece |\n\n"
        f"Set 1 pieces use **Abdhaljs Metal**, Set 2 pieces use **Abdhaljs Fiber**. "
        f"A +1 bought directly with a +1 voucher upgrades to +2 the same way."
    )


def _render_seal(c: dict) -> str:
    return (
        f"The **Abdhaljs Seal** triples the Gallantry from your next **party** "
        f"clear — solo runs pay no Gallantry, so a held Seal is never wasted, and "
        f"it is consumed automatically on the clear it benefits. Manage them from "
        f"the **Seals** menu at Gorpa-Masorpa:\n\n"
        f"- **Buy:** one per calendar month for **{_c(c['seal_cost'])} Hallmarks**.\n"
        f"- **Weekly:** claim **{c['seal_weekly']}** free per calendar week."
    )


def _render_galshop(c: dict) -> str:
    lines = ["| Item | Cost (Gallantry) |", "|---|---:|"]
    for label, cost in c["galshop"]:
        lines.append(f"| {label} | {_c(cost)} |")
    return "\n".join(lines)


# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "scripts/globals/ambuscade.lua")
    if src is None:
        print("[ambuscade] skip: ambuscade.lua not found")
        return

    page = docs_dir / "endgame" / "ambuscade.md"
    if not page.exists():
        print("[ambuscade] skip: ambuscade.md not found")
        return

    c = _parse(src.read_text(encoding="utf-8", errors="replace"))
    nq_ids = {iid for s in c["sets"].values() for iid in s["nq"]}
    item_names = _load_item_names(repo_root, nq_ids)

    blocks = [
        ("amb-cap",       _render_cap(c)),
        ("amb-rewards",   _render_rewards(c)),
        ("amb-vouchers",  _render_vouchers(c)),
        ("amb-armor-sets", _render_armor_sets(c, item_names)),
        ("amb-materials", _render_materials(c)),
        ("amb-seal",      _render_seal(c)),
        ("amb-galshop",   _render_galshop(c)),
    ]
    written = sum(1 for marker, content in blocks
                  if write_between_markers(page, marker, content))
    print(f"[ambuscade] {written}/{len(blocks)} marker block(s) written "
          f"(cap={c['cap']}, seal={c['seal_cost']}HM/{c['seal_weekly']}wk)")
