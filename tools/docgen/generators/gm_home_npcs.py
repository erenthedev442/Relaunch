"""Generate the GM Home NPCs table for docs/changes/index.md.

Parses NPC position data directly from the catalog Lua files so the table
stays accurate when NPCs are moved or added. Descriptions and cluster
assignments are maintained here — they don't change often and are easier
to curate as prose than to extract from Lua comments.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers


_MARKER_ID = "gm-home-npcs"

# ─── Cluster metadata (insertion order = table section order) ─────────────────
_CLUSTER_NOTES: dict[str, str] = {
    "Progression cluster": "gear upgrades and augments (z ≈ −7)",
    "Utility cluster":     "one-time character setup (z ≈ −14)",
    "Activities cluster":  "ongoing gameplay systems (z ≈ −21)",
    "Admin cluster":       "testing and meta systems (z ≈ −28)",
    "Commerce row":        "gil sinks and convenience services (z ≈ −35)",
}

# ─── NPC manifest ─────────────────────────────────────────────────────────────
# For each NPC:
#   cluster    : key in _CLUSTER_NOTES (determines grouping and section order)
#   display    : human-readable name for the table
#   file       : Lua source path (relative to repo root or LEGENDARY_LIVE_ROOT)
#   pos_field  : name of the Lua position-table field to parse (e.g. "npcPos").
#                Tries catalog.*, config.* prefixes automatically.
#                Set to None to parse position from the first NPC
#                insertDynamicEntity block in the file instead.
#   desc       : short description of what the NPC does

_NPCS: list[dict] = [
    # ── Progression cluster (z ≈ −7) ──────────────────────────────────────────
    {
        "cluster":   "Progression cluster",
        "display":   "Gear Moogle",
        "file":      "modules/custom/lua/gear_moogle.lua",
        "pos_field": None,
        "desc":      "One-time starter gear kit for new characters (once per character)",
    },
    {
        "cluster":   "Progression cluster",
        "display":   "Mog Moogle",
        "file":      "modules/custom/lua/mog_moogle.lua",
        "pos_field": None,   # parse position from the insertDynamicEntity NPC block
        "desc":      "Delivery Box access plus change to any of the 22 jobs on the spot",
    },
    {
        "cluster":   "Progression cluster",
        "display":   "Augment Moogle",
        "file":      "modules/custom/lua/Augment_Moogle.lua",
        "pos_field": None,
        "desc":      "Trade one equipment piece + 1–4 catalyst crystals for stacking augments",
    },
    {
        "cluster":   "Progression cluster",
        "display":   "Augment Sage",
        "file":      "modules/custom/lua/augment_sage_catalog.lua",
        "pos_field": "vendorPos",
        "desc":      "Augment affinity system — unlock passive stat bonuses by spending hunt marks",
    },
    # ── Utility cluster (z ≈ −14) ──────────────────────────────────────────────
    {
        "cluster":   "Utility cluster",
        "display":   "Character Upgrader",
        "file":      "modules/custom/lua/Character_Upgrader.lua",
        "pos_field": None,
        "desc":      "Menu-driven: grants all weapon skills, spells, trusts, capped skills, outpost warps",
    },
    {
        "cluster":   "Utility cluster",
        "display":   "Key Item Moogle",
        "file":      "modules/custom/lua/KeyItem_Moogle.lua",
        "pos_field": None,
        "desc":      "Grants all ~4,000 key items in one transaction (single-use, once per character)",
    },
    {
        "cluster":   "Utility cluster",
        "display":   "Mission Moogle",
        "file":      "modules/custom/lua/Mission_Moogle.lua",
        "pos_field": None,
        "desc":      "Skip all missions at once, or per-expansion (RoZ, CoP, ToAU, Wings, SoA, RoV)",
    },
    # ── Activities cluster (z ≈ −21) ──────────────────────────────────────────
    {
        "cluster":   "Activities cluster",
        "display":   "EXP Camp Moogle",
        "file":      "modules/custom/lua/ExpCamp_Moogle.lua",
        "pos_field": None,
        "desc":      "Warp to one of 12 fixed EXP camp locations (Lv 10–75 tier list)",
    },
    {
        "cluster":   "Activities cluster",
        "display":   "Hunt Board",
        "file":      "modules/custom/lua/weekly_hunts_catalog.lua",
        "pos_field": "npcPos",
        "desc":      "Weekly hunt board — pick up and turn in weekly NM target bounties for marks",
    },
    {
        "cluster":   "Activities cluster",
        "display":   "Infamy Vendor",
        "file":      "modules/custom/lua/infamy_vendor_catalog.lua",
        "pos_field": "npcPos",
        "desc":      "Spend infamy currency earned from Abyssea NM hunts, Invasions, and the weekly Raid on gear and rewards",
    },
    # ── Admin cluster (z ≈ −28) ───────────────────────────────────────────────
    {
        "cluster":   "Admin cluster",
        "display":   "Game Master",
        "file":      "modules/custom/lua/game_master_catalog.lua",
        "pos_field": "npcPos",
        "desc":      "Wave-based fight challenge (Easy → Insane); earn hunt marks on full clear",
    },
    {
        "cluster":   "Admin cluster",
        "display":   "Companion Master",
        "file":      "modules/custom/lua/player_trusts_catalog.lua",
        "pos_field": "npcPos",
        "desc":      "Player companion system — link friends and summon them as trusts in your party",
    },
    {
        "cluster":   "Admin cluster",
        "display":   "Test Dummy",
        "file":      "modules/custom/lua/test_dummy_catalog.lua",
        "pos_field": "npcPos",
        "desc":      "Interactive combat dummy for testing DPS and skill rotations",
    },
    # ── Commerce row (z ≈ −35) ────────────────────────────────────────────────
    {
        "cluster":   "Commerce row",
        "display":   "Warpman",
        "file":      "modules/custom/lua/gil_warp_npc_catalog.lua",
        "pos_field": "npcPos",
        "desc":      "Paid warp service to city hubs (San d'Oria, Bastok, Windurst, Jeuno, and more)",
    },
    {
        "cluster":   "Commerce row",
        "display":   "Mystery Mog",
        "file":      "modules/custom/lua/gil_mystery_box_catalog.lua",
        "pos_field": "npcPos",
        "desc":      "Gacha box — spend hunt marks for a random pull from the reward table",
    },
    {
        "cluster":   "Commerce row",
        "display":   "Title Broker",
        "file":      "modules/custom/lua/gil_title_vendor_catalog.lua",
        "pos_field": "npcPos",
        "desc":      "Buy cosmetic titles for gil; cheap flavor titles to rare endgame trophies",
    },
    {
        "cluster":   "Commerce row",
        "display":   "Gil Exchange",
        "file":      "modules/custom/lua/gil_exchange_npc.lua",
        "pos_field": "npcPos",
        "desc":      "Trade hunt marks for gil in bulk",
    },
]


# ─── Position parsers ─────────────────────────────────────────────────────────

def _parse_pos_field(
    text: str, field: str
) -> tuple[float, float, float] | None:
    """Extract (x, y, z) from a Lua position table named `field`.

    Tries two forms:
    1. `<prefix>.<field> = { x = ..., z = ... }` — top-level assignment
       with `catalog`, `config`, or `sage` prefix.
    2. `<field> = { x = ..., z = ... }` — field embedded inside another
       table (e.g. `local config = { ..., npcPos = { x = ... }, ... }`).

    The brace block must be single-level (no nested braces) — all existing
    position definitions in the catalog files match this constraint.
    """
    single_brace = re.compile(
        rf'\b{re.escape(field)}\s*=\s*\{{([^}}]*)\}}',
        re.DOTALL,
    )

    # Try prefixed form first (more specific).
    for prefix in ("catalog", "config", "sage"):
        pat = re.compile(
            rf'\b{prefix}\.{re.escape(field)}\s*=\s*\{{([^}}]*)\}}',
            re.DOTALL,
        )
        m = pat.search(text)
        if m:
            block = m.group(1)
            xm = re.search(r'\bx\s*=\s*([-\d.]+)', block)
            ym = re.search(r'\by\s*=\s*([-\d.]+)', block)
            zm = re.search(r'\bz\s*=\s*([-\d.]+)', block)
            if xm and zm:
                return (
                    float(xm.group(1)),
                    float(ym.group(1)) if ym else 0.0,
                    float(zm.group(1)),
                )

    # Fallback: bare `<field> = { ... }` anywhere in the file.
    m = single_brace.search(text)
    if m:
        block = m.group(1)
        xm = re.search(r'\bx\s*=\s*([-\d.]+)', block)
        ym = re.search(r'\by\s*=\s*([-\d.]+)', block)
        zm = re.search(r'\bz\s*=\s*([-\d.]+)', block)
        if xm and zm:
            return (
                float(xm.group(1)),
                float(ym.group(1)) if ym else 0.0,
                float(zm.group(1)),
            )

    return None


def _parse_npc_entity(text: str) -> tuple[float, float, float] | None:
    """Extract (x, y, z) from the first insertDynamicEntity block that
    contains `xi.objType.NPC`. Uses balanced-brace matching to isolate each
    block, so destination/spawn coordinates elsewhere in the file are not
    mistakenly matched.
    """
    for m in re.finditer(r'insertDynamicEntity\s*\(\s*\{', text):
        start = m.end() - 1  # position of the opening {
        depth = 0
        end = start
        for i in range(start, len(text)):
            if text[i] == '{':
                depth += 1
            elif text[i] == '}':
                depth -= 1
                if depth == 0:
                    end = i
                    break
        block = text[start: end + 1]
        if 'xi.objType.NPC' not in block:
            continue
        xm = re.search(r'\bx\s*=\s*([-\d.]+)', block)
        ym = re.search(r'\by\s*=\s*([-\d.]+)', block)
        zm = re.search(r'\bz\s*=\s*([-\d.]+)', block)
        if xm and zm:
            return (
                float(xm.group(1)),
                float(ym.group(1)) if ym else 0.0,
                float(zm.group(1)),
            )
    return None


# ─── Rendering ────────────────────────────────────────────────────────────────

def _fmt_coord(v: float) -> str:
    """Format one coordinate value: drop trailing `.0` for whole numbers."""
    s = f"{v:.1f}"
    return s[:-2] if s.endswith(".0") else s


def _fmt_pos(x: float, y: float, z: float) -> str:
    return f"({_fmt_coord(x)}, {_fmt_coord(y)}, {_fmt_coord(z)})"


def _render(resolved: list[dict]) -> str:
    if not resolved:
        return "_No NPC data could be parsed from the Lua catalog._"

    lines: list[str] = [
        "_All NPCs are in **GM Home** (zone 210). Positions shown as (x, y, z)._",
        "",
    ]

    current_cluster: str | None = None
    for entry in resolved:
        cluster = entry["cluster"]
        if cluster != current_cluster:
            if current_cluster is not None:
                lines.append("")  # blank line between cluster sections
            current_cluster = cluster
            note = _CLUSTER_NOTES.get(cluster, "")
            heading = f"**{cluster}**"
            if note:
                heading += f" — {note}"
            lines.append(heading)
            lines.append("")
            lines.append("| NPC | Position | What it does |")
            lines.append("|---|---|---|")

        pos = entry.get("_pos")
        pos_str = f"`{_fmt_pos(*pos)}`" if pos else "_unknown_"
        desc = entry["desc"].replace("|", "\\|")
        lines.append(f"| **{entry['display']}** | {pos_str} | {desc} |")

    return "\n".join(lines)


# ─── Main entrypoint ──────────────────────────────────────────────────────────

def generate(repo_root: Path, docs_dir: Path) -> None:
    """Standard generator entrypoint called by tools/docgen/generate.py."""
    resolved: list[dict] = []
    pos_missing: list[str] = []

    for spec in _NPCS:
        src = resolve_source(repo_root, spec["file"])
        if src is None:
            pos_missing.append(spec["display"])
            resolved.append({**spec, "_pos": None})
            continue

        text = src.read_text(encoding="utf-8", errors="replace")

        if spec["pos_field"] is not None:
            pos = _parse_pos_field(text, spec["pos_field"])
        else:
            pos = _parse_npc_entity(text)

        resolved.append({**spec, "_pos": pos})
        if pos is None:
            pos_missing.append(spec["display"])

    page = docs_dir / "changes" / "index.md"
    content = _render(resolved)
    wrote = write_between_markers(page, _MARKER_ID, content)

    if not wrote:
        print(
            f'[gm_home_npcs] skip: markers \'<!-- DOCGEN:BEGIN id="{_MARKER_ID}" -->\''
            f" not found in {page.name}"
        )
        return

    parsed_count = sum(1 for e in resolved if e.get("_pos") is not None)
    print(
        f"[gm_home_npcs] {parsed_count}/{len(_NPCS)} NPC positions parsed, "
        f"table written to {page.name}"
    )
    if pos_missing:
        print(f"[gm_home_npcs] position unknown for: {', '.join(pos_missing)}")
