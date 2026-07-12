"""Generate the Item Database / Drop Finder dataset (docs/assets/item-search-data.json).

Powers the interactive Item Database page (docs/progression/item-database.md +
docs/assets/item-search.js): search any item and see WHERE IT DROPS (mob + zone
+ %) and WHAT IT'S USED FOR (e.g. an Augment Sage catalyst).

Drop data comes from tools/docgen/_item_sources.collect_drop_sources() -- the
SAME source list the Gear Finder uses, so the two pages can never disagree about
where an item comes from. It reads the LIVE DB (mob_droplist -> mob_groups ->
zone_settings) plus the scripted Lua drop tables. Like the leaderboard/player
generators, it SKIPS CLEANLY when the DB is unreachable (CI / a laptop without
the live DB) so the previously published JSON survives; it (re)populates
whenever docgen runs on the box.

"Used for" is parsed from the (gitignored, live-only) Lua catalogs, which works
without the DB. Today that's the Augment Sage catalysts; add more sources here.
"""
from __future__ import annotations

import hashlib
import json
import re
import time
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._item_sources import collect_drop_sources
from tools.docgen.generators.gear_finder import display_name


# ---------------------------------------------------------------------------
# Item display names  (item_basic.sql short name -> "Proper Name +1")
# ---------------------------------------------------------------------------

# INSERT INTO `item_basic` VALUES (883,0,'behemoth_horn','behemoth_horn',...)
_BASIC_RE = re.compile(r"^INSERT INTO `item_basic` VALUES \((\d+),\d+,'([^']*)'")


def _item_names(repo_root: Path) -> dict[int, str]:
    out: dict[int, str] = {}
    p = resolve_source(repo_root, "sql/item_basic.sql")
    if p is None:
        return out
    for ln in p.read_text(encoding="utf-8", errors="replace").splitlines():
        m = _BASIC_RE.match(ln)
        if m:
            out[int(m.group(1))] = m.group(2)
    return out


# ---------------------------------------------------------------------------
# "Used for" reverse-index from the Lua catalogs (no DB needed)
# ---------------------------------------------------------------------------

# augment_catalog.lua:  [2848] = { augId = 291, ..., label = 'Enfb.mag. skill' },
_AUG_CAT_RE = re.compile(r"\[(\d+)\]\s*=\s*\{[^}]*?\blabel\s*=\s*'([^']+)'")


def _used_for(repo_root: Path) -> dict[int, list[str]]:
    """itemId -> list of human 'used for' tags."""
    uses: dict[int, list[str]] = {}
    p = resolve_source(repo_root, "modules/custom/lua/augment_catalog.lua")
    if p:
        text = p.read_text(encoding="utf-8", errors="replace")
        for m in _AUG_CAT_RE.finditer(text):
            uses.setdefault(int(m.group(1)), []).append(
                f"Augment Sage catalyst — {m.group(2)}")
    return uses


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    drops, db_available = collect_drop_sources(repo_root)
    if not db_available:
        print("[drop_finder] skip: no DB connection (LEGENDARY_LIVE_ROOT unset / "
              "DB unreachable) — leaving item-search-data.json as-is")
        return

    names = _item_names(repo_root)
    uses = _used_for(repo_root)

    # Every item that drops from a mob OR is used for something.
    ids = set(drops) | set(uses)
    items = []
    for iid in sorted(ids):
        short = names.get(iid)
        if not short:
            continue  # no item_basic name -> skip (NPC/internal id)
        items.append({
            "i": iid,
            "n": display_name(short),
            "d": drops.get(iid, []),
            "u": uses.get(iid, []),
        })

    payload = {
        "generated_at": time.strftime("%Y-%m-%dT%H:%M:%S"),
        "items": items,
    }
    out = docs_dir / "assets" / "item-search-data.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(payload, separators=(",", ":")), encoding="utf-8")

    n_drop = sum(1 for it in items if it["d"])
    n_use = sum(1 for it in items if it["u"])
    print(f"[drop_finder] wrote {out.name}: {len(items)} items "
          f"({n_drop} with drops, {n_use} with uses, {out.stat().st_size // 1024} KB)")

    # Stamp the live coverage counts into item-database.md. The page is otherwise
    # static widget HTML (the data lives in the JSON above), which froze its
    # "Last updated" stamp -- this marker bumps the content hash whenever the item
    # coverage changes AND tells readers the dataset is regenerated every deploy.
    # The dataset-rev hash (generated_at excluded) catches changes that keep the
    # counts identical, e.g. a drop source moving between mobs.
    page = docs_dir / "progression" / "item-database.md"
    if page.exists():
        rev = hashlib.sha256(json.dumps(
            items, separators=(",", ":")).encode("utf-8")).hexdigest()[:12]
        meta = (
            f"**{len(items):,} items** indexed straight from the live server — "
            f"**{n_drop:,}** with drop sources, **{n_use:,}** with system uses. This "
            f"dataset is **rebuilt from the live database on every deploy**, so it always "
            f"reflects the current server.\n"
            f"<!-- dataset-rev: {rev} -->"
        )
        if write_between_markers(page, "item-database-meta", meta):
            print("[drop_finder] item-database-meta: written")
