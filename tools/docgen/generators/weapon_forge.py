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

_RELIC_COSTS_RE = re.compile(r"catalog\.relicCosts\s*=\s*\{(.+?)\n\}", re.DOTALL)
_STEP_RE = re.compile(r"\{[^}]*\}")


def _parse_relic_gates(text: str) -> list[int]:
    """Return divergenceWins per step from `catalog.relicCosts` (3 entries).

    Reads live so the widget's Relic gate row can't drift from what the
    Weapon Forge NPC actually enforces (WeaponForge_NPC.lua checks
    step.divergenceWins via xi.divergence.uniqueWins).
    """
    m = _RELIC_COSTS_RE.search(text)
    if not m:
        return []
    out: list[int] = []
    for step_m in _STEP_RE.finditer(m.group(1)):
        dw = re.search(r"divergenceWins\s*=\s*(\d+)", step_m.group(0))
        out.append(int(dw.group(1)) if dw else 0)
    return out


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
    # Bound the region at the next table (catalog.forgeMats). The later end
    # anchors (LOOKUP TABLES / catalog.byId) sit *after* catalog.empyreanChains
    # / mythicChains / relicChains, which repeat every weapon type with no
    # s1/s2/s3 subtables and would clobber prime[t] (keyed by type, unguarded),
    # leaving every Prime stage name blank.
    chains_region = _slice(text, "catalog.chains", "catalog.forgeMats")
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

    relic_wins = _parse_relic_gates(text)
    return {
        "prime_cost": prime_cost,
        "aeonic_cost": aeonic_cost,
        "chains": chains,
        "relic_wins": relic_wins,
    }


def _parse_gate_labels(text: str) -> dict:
    """Parse STAGE_GATES labels from weapon_forge_gates.lua.

    Returns {category: {fromStage: label}}. Missing tuples fall through as no
    override. Kept live so the widget can never drift from the labels the
    runtime WeaponForge_NPC preflight and the in-game !forgegates command
    read from the same file.
    """
    out: dict[str, dict[int, str]] = {}
    # Slice each `<category> = { ... }` sub-table out of the STAGE_GATES table.
    body = _slice(text, "M.STAGE_GATES", "\n-- ── Display order")
    for cat_m in re.finditer(r"(\w+)\s*=\s*\{(.*?)\n\s{4}\}", body, re.DOTALL):
        cat = cat_m.group(1)
        cat_body = cat_m.group(2)
        rows: dict[int, str] = {}
        for row in re.finditer(
            r"\[(\d+)\]\s*=\s*\{\s*label\s*=\s*(['\"])(.+?)\2",
            cat_body,
        ):
            rows[int(row.group(1))] = row.group(3)
        if rows:
            out[cat] = rows
    return out


def _build_real(c: dict, gate_labels: dict | None = None) -> dict:
    pc, ac = c["prime_cost"], c["aeonic_cost"]
    gate_labels = gate_labels or {}
    prime_gates = gate_labels.get("prime", {})
    aeonic_gates = gate_labels.get("aeonic", {})
    # Prime widget forge[0] (Stage I -> Stage II) mirrors prime STAGE_GATES[1].
    # Prime widget forge[1] (Stage II -> Stage III) mirrors prime STAGE_GATES[2]
    # -- if unset, keep the catalog-derived HL Rank + Trials gate.
    if 1 in prime_gates:
        gate_p2 = prime_gates[1]
    else:
        gate_p2 = "Hunting League " + RANKS.get(pc["s2"]["rank"], f"Rank {pc['s2']['rank']}")
    if 2 in prime_gates:
        gate_p3 = prime_gates[2]
    else:
        gate_p3 = "Hunting League " + RANKS.get(pc["s3"]["rank"], f"Rank {pc['s3']['rank']}")
        if pc["s3"].get("trials"):
            gate_p3 += " · All 5 Prime Armory Trials"
    ae_rank = ac.get("rank", 0)
    fallback_ae = ("Hunting League " + RANKS.get(ae_rank, f"Rank {ae_rank}")
                   if ae_rank else "Materials only — no rank gate")
    gate_ae_0 = aeonic_gates.get(0, fallback_ae)
    gate_ae_1 = aeonic_gates.get(1, fallback_ae)
    gate_ae_2 = aeonic_gates.get(2, fallback_ae)

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
                              [_qty(ac["s1"]["boulder"]), "Riftborn Boulder"]], "gate": gate_ae_0},
                    {"mats": [[_qty(ac["s2"]["att"]), att],
                              [_qty(ac["s2"]["boulder"]), "Riftborn Boulder"],
                              [_qty(ac["s2"]["silt"]), "Escha Silt"]], "gate": gate_ae_1},
                    {"mats": [[_qty(ac["s3"]["att"]), att],
                              [_qty(ac["s3"]["boulder"]), "Riftborn Boulder"],
                              [_qty(ac["s3"]["silt"]), "Escha Silt"],
                              [_num(ac["s3"]["marks"]), "Reforge Marks"]], "gate": gate_ae_2},
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
    relic_wins: list[int] = []
    gates_src = resolve_source(repo_root, "modules/custom/lua/weapon_forge_gates.lua", required=False)
    gate_labels: dict = {}
    if gates_src is not None:
        gate_labels = _parse_gate_labels(gates_src.read_text(encoding="utf-8", errors="replace"))
    if src is not None:
        parsed = _parse(src.read_text(encoding="utf-8", errors="replace"))
        real = _build_real(parsed, gate_labels)
        relic_wins = parsed.get("relic_wins", [])
        n_p, n_a = len(real["prime"]), len(real["aeonic"])
        print(f"[weapon_forge] parsed catalog: {n_p} prime + {n_a} aeonic real chains"
              f" · relic gates: {relic_wins}")
        if not n_p:
            print("[weapon_forge] warning: no prime chains parsed — check catalog format")
    else:
        print("[weapon_forge] warning: catalog not found — widget uses generic model only")

    payload = json.dumps(real, ensure_ascii=False, separators=(",", ":"))
    if "/*__REAL_DATA__*/ {}" in widget:
        widget = widget.replace("/*__REAL_DATA__*/ {}", payload, 1)
    else:
        print("[weapon_forge] warning: REAL_DATA placeholder not found in template")

    # Resolve the Relic step gate placeholders from the LIVE catalog. The
    # widget's Relic section is hand-authored HTML (the runtime doesn't
    # produce a `relicChains` shape the widget can consume), so we can't
    # feed it via REAL_DATA -- but the gate STRINGS get rendered from the
    # runtime divergenceWins values so they can't drift from what the
    # forge NPC actually enforces (see WeaponForge_NPC.lua step.divergenceWins).
    def _gate_str(wins: int) -> str:
        if wins <= 0:
            return "HL Rank V (Legend)"
        noun = "win" if wins == 1 else "wins"
        return (f"HL Rank V (Legend) · {wins} unique Dynamis - Divergence city "
                f"{noun} (same city counts once)")
    for i in range(3):
        placeholder = f"__RELIC_GATE_S{i + 1}__"
        wins = relic_wins[i] if i < len(relic_wins) else 0
        widget = widget.replace(placeholder, _gate_str(wins))

    # Live iterated-gate target counts. Mirrors the runtime values exposed
    # via xi.geasFete.uniqueNmCount / xi.voidwatch.uniqueNmCount /
    # xi.dungeonInstances.uniqueDungeonCount and the Portal's parse. The
    # widget's gate strings embed these so a player reading the docs sees
    # "(N of N)" progress framing without needing to visit the Portal.
    def _count(rel: str, pattern: str, block_re: str | None = None) -> int:
        src = resolve_source(repo_root, rel, required=False)
        if src is None:
            return 0
        text = src.read_text(encoding="utf-8", errors="replace")
        if block_re:
            m = re.search(block_re, text, re.DOTALL | re.MULTILINE)
            if not m:
                return 0
            text = m.group(1)
        return len(re.findall(pattern, text, re.MULTILINE))

    gf_total = _count(
        "modules/custom/lua/Geas_Fete.lua", r"gid\s*=\s*\d+",
        block_re=r"^local NM_CATALOG = \{(.*?)\n\}\n",
    )
    vw_names: set[str] = set()
    vw_src = resolve_source(repo_root, "modules/custom/lua/voidwatch_catalog.lua", required=False)
    if vw_src is not None:
        vw_text = vw_src.read_text(encoding="utf-8", errors="replace")
        strata = re.search(r"C\.STRATA\s*=\s*\{(.*?)\n\}", vw_text, re.DOTALL)
        if strata:
            for r in re.findall(r"roster\s*=\s*\{(.*?)\}\s*\}", strata.group(1), re.DOTALL):
                for n in re.findall(r"name\s*=\s*'([^']+)'", r):
                    vw_names.add(n)
    dungeon_total = _count(
        "modules/custom/lua/dungeon_catalog.lua",
        r"^\s+instanceId\s*=\s*\d",
    )
    for tok, val in (
        ("__GF_TOTAL__", str(gf_total or "?")),
        ("__VW_TOTAL__", str(len(vw_names) or "?")),
        ("__DUNGEON_TOTAL__", str(dungeon_total or "?")),
    ):
        widget = widget.replace(tok, val)

    page = docs_dir / "progression" / "weapon-forge.md"
    ok = write_between_markers(page, "weapon-forge-widget", widget)
    print(f"[weapon_forge] {'widget written' if ok else 'marker not found — skipped'}")

    ws_md = _ws_enhancement_md(repo_root)
    if ws_md:
        ok2 = write_between_markers(page, "weapon-forge-ws-enhancement", ws_md)
        print(f"[weapon_forge] {'ws-enhancement written' if ok2 else 'ws-enhancement marker not found — skipped'}")


# ---------------------------------------------------------------------------
# Native weapon-skill enhancement (REMA tiers + Prime over-cap).
# Sources: modules/custom/lua/rema_ws_tier_catalog.lua (tier scales, tuned-WS
# roster; engine = REMAWeaponskillEnhancement.lua) and
# modules/custom/lua/prime_ws_tuning_catalog.lua (job-tier caps, +WS% layer;
# engine = PrimeWeaponskillTuning.lua). All values parsed live.

def _ws_enhancement_md(repo_root: Path) -> str | None:
    rema_src = resolve_source(repo_root, "modules/custom/lua/rema_ws_tier_catalog.lua", required=False)
    prime_src = resolve_source(repo_root, "modules/custom/lua/prime_ws_tuning_catalog.lua", required=False)
    if rema_src is None or prime_src is None:
        return None
    rema = rema_src.read_text(encoding="utf-8", errors="replace")
    prime = prime_src.read_text(encoding="utf-8", errors="replace")

    bench_m = re.search(r"PRIME_EQUIVALENT_BONUS\s*=\s*([\d.]+)", rema)
    scales = dict(re.findall(r"(RELIC|EMPYREAN|MYTHIC|AEONIC)\s*=\s*([\d.]+)", rema))
    tuning_block = rema.split("catalog.REMA_WS_TUNING", 1)[-1]
    rema_ws_count = len(re.findall(r"\[xi\.weaponskill\.\w+\]\s*=\s*[\d.]+", tuning_block))

    ws_bonus_m = re.search(r"catalog\.WS_DAMAGE_BONUS\s*=\s*(\d+)", prime)
    caps = dict(re.findall(r"(SUPPORT|HYBRID|DAMAGE)\s*=\s*(\d+)", prime))
    jobs_by_tier: dict[str, list[str]] = {"SUPPORT": [], "HYBRID": [], "DAMAGE": []}
    for job, tier in re.findall(r"\[xi\.job\.(\w+)\]\s*=\s*catalog\.DAMAGE_CAPS\.(\w+)", prime):
        jobs_by_tier.setdefault(tier, []).append(job)
    prime_ws_count = len(re.findall(r"\bftpScale\s*=\s*[\d.]+", prime))

    if not bench_m or len(scales) != 4 or not ws_bonus_m or len(caps) != 3:
        print("[weapon_forge] WARN: ws-enhancement parse degraded — block not rewritten")
        return None

    cap_label = "universal damage cap"
    settings = resolve_source(repo_root, "settings/default/map.lua", required=False)
    if settings is not None:
        cap_m = re.search(r"GLOBAL_HP_DAMAGE_CAP\s*=\s*(\d+)", settings.read_text(encoding="utf-8", errors="replace"))
        if cap_m:
            cap_label = f"universal {int(cap_m.group(1)):,} damage cap"

    bench = float(bench_m.group(1))
    bench_pct = int(round(bench * 100))
    order = [("RELIC", "Relic"), ("EMPYREAN", "Empyrean"), ("MYTHIC", "Mythic"), ("AEONIC", "Aeonic")]
    tier_rows = "\n".join(
        f"| {label} | ×{float(scales[key]):.2f} | +{int(round(float(scales[key]) * bench * 100))}% |"
        for key, label in order)
    cap_rows = "\n".join(
        f"| {label} | {int(caps[key]):,} | {', '.join(jobs_by_tier.get(key, []))} |"
        for key, label in (("SUPPORT", "Support"), ("HYBRID", "Hybrid"), ("DAMAGE", "Damage")))

    return f"""Finishing a weapon does more than raise its stats — **final REMA and Prime weapons supercharge their native weapon skill**.

**Relic / Empyrean / Mythic / Aeonic (final stage only)** — the weapon's signature WS ({rema_ws_count} weapon skills tuned individually) gains a damage bonus benchmarked against Prime's +{bench_pct}%, scaled by family:

| Family | Tier scale | Native WS bonus |
|---|---|---|
{tier_rows}

The native hit count, damage path, crit rules, and utility effects are preserved — only the damage budget grows.

**Prime (final stage)** — the {prime_ws_count} Prime-native weapon skills receive a **+{int(ws_bonus_m.group(1))}% weapon-skill damage layer** and are the only attacks allowed to break the [{cap_label}](server-features.md#universal-damage-cap), up to a ceiling set by your job's role:

| Role tier | Per-WS damage ceiling | Jobs |
|---|---|---|
{cap_rows}

Ordinary uses of shared weapon skills (a Resolution from a non-Prime greatsword, for example) are completely unchanged."""
