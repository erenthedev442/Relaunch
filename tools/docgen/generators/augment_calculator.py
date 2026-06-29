"""Keeps docs/progression/augment-calculator.md in sync with augment_catalog.lua.

Reads every catalog entry that has a `label` field and injects the resulting
JSON array between the augment-calc-data DOCGEN markers.  The JS on the page
reads window._augCalcData so it never has stale augment data.

Marker written:
  augment-calc-data  — the <script> block that sets window._augCalcData
"""
from __future__ import annotations

import json
import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers

_BASE_RE  = re.compile(r"\bbase\s*=\s*(-?\d+)")
_MULT_RE  = re.compile(r"\bmult\s*=\s*(-?\d+)")
_TIER_RE  = re.compile(r"\btier\s*=\s*(\d+)")
_LABEL_RE = re.compile(r"label\s*=\s*'([^']*)'")

_CATALOG_PATH = "modules/custom/lua/augment_catalog.lua"
_OUT = Path("docs/progression/augment-calculator.md")


def generate(repo_root: Path, docs_dir: Path) -> None:
    catalog = resolve_source(repo_root, _CATALOG_PATH)
    if not catalog:
        print(f"  [augment_calculator] skipped — {_CATALOG_PATH} not found")
        return

    entries = []
    seen: set[str] = set()
    with open(catalog, encoding="utf-8") as f:
        for line in f:
            lm = _LABEL_RE.search(line)
            if not lm:
                continue
            label = lm.group(1)
            if label in seen or label == "...":
                continue
            seen.add(label)
            b  = _BASE_RE.search(line)
            mm = _MULT_RE.search(line)
            tm = _TIER_RE.search(line)
            entries.append({
                "label": label,
                "base":  int(b.group(1))  if b  else 0,
                "mult":  int(mm.group(1)) if mm else 1,
                "tier":  int(tm.group(1)) if tm else 0,
            })

    entries.sort(key=lambda x: x["label"])
    json_data = json.dumps(entries, separators=(",", ":"))
    block = f"<script>window._augCalcData={json_data};</script>"

    page = docs_dir / "progression" / "augment-calculator.md"
    wrote = write_between_markers(page, "augment-calc-data", block)
    if wrote:
        print(f"  [augment_calculator] wrote {len(entries)} augments -> augment-calc-data")
    else:
        print(f"  [augment_calculator] marker augment-calc-data not found in {page}")
