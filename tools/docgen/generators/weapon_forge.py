"""Write the interactive Weapon Forge widget to docs/progression/weapon-forge.md.

The widget markup/JS lives in tools/docgen/templates/weapon_forge_widget.html.
This generator:
  1. Parses modules/custom/lua/weapon_forge_catalog.lua for the two *implemented*
     forge paths (Prime and Aeonic) — real item names, real per-step costs, real
     gates (verified against WeaponForge_NPC.lua).
  2. Injects that data into the template's `/*__REAL_DATA__*/ {}` placeholder so
     the widget renders the exact catalog chain for those two categories. The other
     four categories (Relic/Empyrean/Mythic/Ergon) are not backed by server items
     and fall back to the widget's generic retail-tier display model.
  3. Writes the finished HTML into the weapon-forge-widget DOCGEN marker.

Prime  = 3 stages / 2 forge steps  (Ajja 119I -> Kaja 119II -> final 119III).
Aeonic = 4 stages / 3 forge steps  (Malformed -> 119I -> 119II -> Aeonic final).
"""
from __future__ import annotations

import json
import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers


# ---------------------------------------------------------------------------
# Parsing helpers

RANKS = {
    1: "Rank I (Initiate)",
    2: "Rank II (Hunter)",
    3: "Rank III (Elite)",
    4: "Rank IV (Champion)",
    5: "Rank V (Legend)",
}


def _qty(n: int) -> str:
    return f"{n:,}×"          # 10000 -> "10,000×"


def _num(n: int) -> str:
    return f"{n:,}"                # 2000 -> "2,000"  (no ×, for Reforge Marks)


def _slice(text: str, start_anchor: str, *end_anchors: str) -> str:
    """Return the substring from start_anchor up to the first end_anchor."""
    i = text.find(start_anchor)
    if i < 0:
        return ""
    rest = text[i + len(start_anchor):]
    cut = len(rest)
    for a in end_anchors:
        j = rest.find(a)
        if 0 <= j < cut:
            cut = j
    return rest[:cut]


def _s(block: str, field: str) -> str:
    m = re.search(rf"{re.escape(field)}\s*=\s*'([^']*)'", block)
    return m.group(1) if m else ""


def _i(block: str, field: str) -> int:
    m = re.search(rf"{re.escape(field)}\s*=\s*(\d+)", block)
    return int(m.group(1)) if m else 0


def _name_in(block: str, sub: str) -> str:
    """Name of the `sub = { ... name = '...' }` inline table within block."""
    m = re.search(rf"{re.escape(sub)}\s*=\s*\{{[^}}]*name\s*=\s*'([^']+)'", block)
    return m.group(1) if m else ""


def _id_in(block: str, sub: str) -> int:
    """ID of the `sub = { id = NNN, ... }` inline table within block."""
    m = re.search(rf"{re.escape(sub)}\s*=\s*\{{[^}}]*\bid\s*=\s*(\d+)", block)
    return int(m.group(1)) if m else 0


# ---------------------------------------------------------------------------

def _parse(text: str) -> dict:
    # --- Prime costs (catalog.costs) ---
    costs_region = _slice(text, "catalog.costs", "catalog.markVars", "catalog.aeonicCosts")
    to2 = _slice(costs_region, "toStage2", "toStage3")
    to3 = _slice(costs_region, "toStage3", "\n}")
    prime_cost = {
        "s2": {"rank": _i(to2, "hlRank"), "med": _s(to2, "name"), "qty": _i(to2, "qty")},
        "s3": {"rank": _i(to3, "hlRank"), "med": _s(to3, "name"), "qty": _i(to3, "qty"),
               "marks": _i(to3, "reforgeMarks"), "gil": _i(to3, "gil"),
               "trials": "requireTrials" in to3},
    }

    # --- Aeonic costs (catalog.aeonicCosts) ---
    ac_region = _slice(text, "catalog.aeonicCosts", "WEAPON CHAINS", "catalog.chains")
    a1 = _slice(ac_region, "toStage1", "toStage2")
    a2 = _slice(ac_region, "toStage2", "toStage3")
    a3 = _slice(ac_region, "toStage3", "\n}")
    aeonic_cost = {
        "rank": _i(a1, "hlRank"),
        "s1": {"att": _i(a1, "attestations"), "boulder": _i(a1, "riftbornBoulders")},
        "s2": {"att": _i(a2, "attestations"), "boulder": _i(a2, "riftbornBoulders"),
               "silt": _i(a2, "eschaSilt")},
        "s3": {"att": _i(a3, "attestations"), "boulder": _i(a3, "riftbornBoulders"),
               "silt": _i(a3, "eschaSilt"), "marks": _i(a3, "reforgeMarks")},
    }

    # --- chains ---
    chains_region = _slice(text, "catalog.chains", "LOOKUP TABLES", "catalog.byId")
    starts = [m.start() for m in re.finditer(r"type\s*=\s*'", chains_region)]
    chains = []
    for idx, s in enumerate(starts):
        e = starts[idx + 1] if idx + 1 < len(starts) else len(chains_region)
        block = chains_region[s:e]
        ae_block = _slice(block, "aeonic", "\n    }")
        chains.append({
            "type":       _s(block, "type"),
            "s1":         _name_in(block, "s1"),
            "s1_id":      _id_in(block, "s1"),
            "s2":         _name_in(block, "s2"),
            "s2_id":      _id_in(block, "s2"),
            "s3":         _name_in(block, "s3"),
            "s3_id":      _id_in(block, "s3"),
            "ae_base":    _name_in(ae_block, "base"),
            "ae_base_id": _id_in(ae_block, "base"),
            "ae_att":     _s(ae_block, "attestationName"),
            "ae_s3":      _name_in(ae_block, "s3"),
            "ae_s3_id":   _id_in(ae_block, "s3"),
        })

    return {"prime_cost": prime_cost, "aeonic_cost": aeonic_cost, "chains": chains}


def _build_real(c: dict) -> dict:
    pc, ac = c["prime_cost"], c["aeonic_cost"]
    gate_p2 = "Hunting League " + RANKS.get(pc["s2"]["rank"], f"Rank {pc['s2']['rank']}")
    gate_p3 = "Hunting League " + RANKS.get(pc["s3"]["rank"], f"Rank {pc['s3']['rank']}")
    if pc["s3"].get("trials"):
        gate_p3 += " · All 5 Prime Armory Trials"
    ae_rank = ac.get("rank", 0)
    gate_ae = ("Hunting League " + RANKS.get(ae_rank, f"Rank {ae_rank}")
               if ae_rank else "Materials only — no rank gate")

    prime, aeonic = {}, {}
    for ch in c["chains"]:
        t = ch["type"]
        if not t:
            continue

        # --- Prime: Ajja 119I -> Kaja 119II -> final 119III (3 stages / 2 steps) ---
        p3_mats = [[_qty(pc["s3"]["qty"]), pc["s3"]["med"]]]
        if pc["s3"]["marks"]:
            p3_mats.append([_num(pc["s3"]["marks"]), "Reforge Marks"])
        if pc["s3"].get("gil"):
            p3_mats.append([_num(pc["s3"]["gil"]), "gil"])
        prime[t] = {
            "names":  [ch["s1"], ch["s2"], ch["s3"]],
            "labels": ["Base · 119 I", "119 II", "119 III · Final"],
            "id":     ch["s3_id"] or None,
            "ids":    [ch["s1_id"] or None, ch["s2_id"] or None, ch["s3_id"] or None],
            "forge": [
                {"mats": [[_qty(pc["s2"]["qty"]), pc["s2"]["med"]]], "gate": gate_p2},
                {"mats": p3_mats, "gate": gate_p3},
            ],
        }

        # --- Aeonic: Malformed -> 119I -> 119II -> Aeonic (4 stages / 3 steps) ---
        att = ch["ae_att"] or "Attestation"
        if ch["ae_base"] and ch["ae_s3"]:
            aeonic[t] = {
                "names":  [ch["ae_base"], ch["s1"], ch["s2"], ch["ae_s3"]],
                "labels": ["Base · Malformed", "119 I", "119 II", "119 III · Aeonic"],
                "id":     ch["ae_s3_id"] or None,
                "ids":    [ch["ae_base_id"] or None, ch["s1_id"] or None, ch["s2_id"] or None, ch["ae_s3_id"] or None],
                "forge": [
                    {"mats": [[_qty(ac["s1"]["att"]), att],
                              [_qty(ac["s1"]["boulder"]), "Riftborn Boulder"]], "gate": gate_ae},
                    {"mats": [[_qty(ac["s2"]["att"]), att],
                              [_qty(ac["s2"]["boulder"]), "Riftborn Boulder"],
                              [_qty(ac["s2"]["silt"]), "Escha Silt"]], "gate": gate_ae},
                    {"mats": [[_qty(ac["s3"]["att"]), att],
                              [_qty(ac["s3"]["boulder"]), "Riftborn Boulder"],
                              [_qty(ac["s3"]["silt"]), "Escha Silt"],
                              [_num(ac["s3"]["marks"]), "Reforge Marks"]], "gate": gate_ae},
                ],
            }

    return {"prime": prime, "aeonic": aeonic}


# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    template = repo_root / "tools" / "docgen" / "templates" / "weapon_forge_widget.html"
    if not template.exists():
        print("[weapon_forge] skip: weapon_forge_widget.html template not found")
        return

    widget = template.read_text(encoding="utf-8")

    src = resolve_source(repo_root, "modules/custom/lua/weapon_forge_catalog.lua")
    real = {}
    if src is not None:
        parsed = _parse(src.read_text(encoding="utf-8", errors="replace"))
        real = _build_real(parsed)
        n_p, n_a = len(real["prime"]), len(real["aeonic"])
        print(f"[weapon_forge] parsed catalog: {n_p} prime + {n_a} aeonic real chains")
        if not n_p:
            print("[weapon_forge] warning: no prime chains parsed — check catalog format")
    else:
        print("[weapon_forge] warning: catalog not found — widget uses generic model only")

    payload = json.dumps(real, ensure_ascii=False, separators=(",", ":"))
    if "/*__REAL_DATA__*/ {}" in widget:
        widget = widget.replace("/*__REAL_DATA__*/ {}", payload, 1)
    else:
        print("[weapon_forge] warning: REAL_DATA placeholder not found in template")

    page = docs_dir / "progression" / "weapon-forge.md"
    ok = write_between_markers(page, "weapon-forge-widget", widget)
    print(f"[weapon_forge] {'widget written' if ok else 'marker not found — skipped'}")
