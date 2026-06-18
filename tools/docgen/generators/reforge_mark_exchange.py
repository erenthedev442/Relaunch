"""Sync docs/economy/reforge-mark-exchange.md with the Reforge Mark Exchange.

The NPC's conversions live in reforge_mark_exchange_catalog.lua as
`catalog.exchanges = { { fromName, toName, rate }, ... }` where `rate` is how
many source marks buy one target mark (so the published ratio is rate:1). The
batch sizes the menu offers come from `catalog.batchSizes`. Both are read from
the catalog so re-tuning a rate updates the page.

Markers written:
  reforge-mark-exchange-access   — NPC + zone line
  reforge-mark-exchange-rates    — the conversion table (which mark -> which)
  reforge-mark-exchange-batches  — batch sizes available per trade
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section, ints


# Turn an engine zone constant ('Reisenjima_Henge') into a readable place name.
def _zone_label(raw: str) -> str:
    return raw.replace("_", " ").strip()


def _parse(text: str) -> dict:
    c: dict = {"exchanges": []}

    m = re.search(r"zone\s*=\s*'([^']+)'", text)
    c["zone"] = _zone_label(m.group(1)) if m else "Reisenjima Henge"

    block = section(text, "catalog.exchanges")
    # Each exchange is its own { ... } sub-table; pull the three fields we show.
    for m in re.finditer(r"\{(.*?)\}", block, flags=re.DOTALL):
        body = m.group(1)
        frm = re.search(r"fromName\s*=\s*'([^']+)'", body)
        to = re.search(r"toName\s*=\s*'([^']+)'", body)
        rate = re.search(r"rate\s*=\s*(\d+)", body)
        if frm and to and rate:
            c["exchanges"].append({
                "from": frm.group(1),
                "to": to.group(1),
                "rate": int(rate.group(1)),
            })

    sizes = section(text, "catalog.batchSizes")
    c["batches"] = ints(sizes)
    return c


# ---------------------------------------------------------------------------

def _render_access(c: dict) -> str:
    return (f"The **Reforge Exchange** stands at **{c['zone']}**, right beside "
            f"the Gear Vendors — the same spot where you turn marks into upgrades.")


def _render_rates(c: dict) -> str:
    lines = [
        "Each conversion charges a small tax, so trading down a surplus costs "
        "you a little but never trivializes a track:",
        "",
        "| You spend | You receive | Rate |",
        "|---|---|---|",
    ]
    for ex in c["exchanges"]:
        lines.append(f"| {ex['rate']} {ex['from']} | 1 {ex['to']} | {ex['rate']}:1 |")
    return "\n".join(lines)


def _render_batches(c: dict) -> str:
    sizes = ", ".join(str(b) for b in c["batches"])
    return (f"Each visit you can convert in batches of **{sizes}** target marks "
            f"at once (you'll only be offered batches you can afford), so a large "
            f"surplus can be moved over in a few clicks.")


# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/reforge_mark_exchange_catalog.lua")
    if src is None:
        print("[reforge_mark_exchange] skip: reforge_mark_exchange_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    c = _parse(text)

    page = docs_dir / "economy" / "reforge-mark-exchange.md"
    blocks = [
        ("reforge-mark-exchange-access", _render_access(c)),
        ("reforge-mark-exchange-rates", _render_rates(c)),
        ("reforge-mark-exchange-batches", _render_batches(c)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[reforge_mark_exchange] {written}/{len(blocks)} marker block(s) written "
          f"(conversions={len(c['exchanges'])}, batches={len(c['batches'])})")
