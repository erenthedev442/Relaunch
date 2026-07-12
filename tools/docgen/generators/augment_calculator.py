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
_DISP_RE  = re.compile(r"\bdisp\s*=\s*(\d+)")
_MB_RE    = re.compile(r"\bmaxBoost\s*=\s*(\d+)")
_TIER_RE  = re.compile(r"\btier\s*=\s*(\d+)")
_TV_RE    = re.compile(r"\btierValue\s*=\s*(\d+|true)")
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
            dm = _DISP_RE.search(line)
            xb = _MB_RE.search(line)
            entry = {
                "label": label,
                "base":  int(b.group(1))  if b  else 0,
                "mult":  int(mm.group(1)) if mm else 1,
                "tier":  int(tm.group(1)) if tm else 0,
            }
            # Only carry disp/maxBoost when they matter (keeps the JSON small; the
            # page JS defaults d->1 and mb->31). mb caps + SCALES the roll so each
            # tier is a distinct step (mirrors Augment_Moogle.lua scaleRoll).
            if dm and int(dm.group(1)) > 1:
                entry["d"] = int(dm.group(1))
            if xb and int(xb.group(1)) < 31:
                entry["mb"] = int(xb.group(1))
            # Tier-fixed augments (Treasure Hunter, All songs): single catalyst,
            # value = tv × the player's Augment Tier. The page JS reads `tv`.
            tv = _TV_RE.search(line)
            if tv:
                entry["tv"] = 1 if tv.group(1) == "true" else int(tv.group(1))
            entries.append(entry)

    entries.sort(key=lambda x: x["label"])
    json_data = json.dumps(entries, separators=(",", ":"))

    # Tier constants for the page's calculator JS — parsed from the same Lua
    # the server runs (Augment_Moogle.lua slices/gates, augment_sage_catalog
    # crit ladder) so a tier retune can't silently break the calculator. The
    # static JS reads window._augCalcTiers with its previous values as
    # fallback.
    tiers_js = ""
    moogle = resolve_source(repo_root, "modules/custom/lua/Augment_Moogle.lua")
    sage = resolve_source(repo_root, "modules/custom/lua/augment_sage_catalog.lua")
    if moogle and sage:
        mtext = moogle.read_text(encoding="utf-8", errors="replace")
        stext = sage.read_text(encoding="utf-8", errors="replace")
        slices = [[int(a), int(b)] for a, b in re.findall(
            r"\{\s*min\s*=\s*(\d+),\s*max\s*=\s*(\d+)\s*\}", mtext)]
        unlocks = re.findall(r"\btier\s*=\s*\d+,\s*unlock\s*=\s*(?:'([^']+)'|\"([^\"]+)\")", mtext)
        unlocks = [a or b for a, b in unlocks]
        crit_m = re.search(r"catalog\.critChance\s*=\s*\{([^}]*)\}", stext)
        crit = [float(x) for x in re.findall(r"[\d.]+", crit_m.group(1))] if crit_m else []
        if len(slices) == 5 and len(unlocks) == 5 and len(crit) == 6:
            tiers = {"slices": slices, "unlocks": unlocks, "crit": crit}
            tiers_js = f"<script>window._augCalcTiers={json.dumps(tiers, separators=(',', ':'))};</script>"
        else:
            print(f"  [augment_calculator] WARN: tier parse degraded "
                  f"(slices={len(slices)}, unlocks={len(unlocks)}, crit={len(crit)}) "
                  f"— _augCalcTiers not emitted; page JS falls back to baked-in values")
    block = f"<script>window._augCalcData={json_data};</script>{tiers_js}"

    page = docs_dir / "progression" / "augment-calculator.md"
    wrote = write_between_markers(page, "augment-calc-data", block)
    if wrote:
        print(f"  [augment_calculator] wrote {len(entries)} augments -> augment-calc-data")
    else:
        print(f"  [augment_calculator] marker augment-calc-data not found in {page}")
