"""ws_vs_retail — fills the custom-weaponskill table on reference/ws-vs-retail.md.

Companion to gear_vs_retail: where that page diffs item stats against retail
(FFXIAH), this one documents where the server's WEAPON-SKILL mechanics diverge
from retail. The big mechanical divergence (the damage-cap removal) is authored
prose on the page; the part that changes as content is added — the roster of
Prime/custom weapon skills the server lets PLAYERS use that retail ships as
mob-only skills — is generated here from the enabling SQL so it can't drift.

Source of truth: the custom weapon_skills INSERTs. Each row is
`(id, 'name', 0x<jobs>, <type>, ...)` and its preceding `-- Name (Weapon /
Prime weapon)` comment carries the Prime weapon. We read (id, name, type)
from the row (authoritative) and the Prime weapon from the comment
(best-effort; falls back to "—").

FAIL-CLOSED: a parse that finds nothing raises so generate.py keeps the last
good page instead of publishing an empty table.
"""

from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers

# The SQL files that enable Prime/custom weapon skills as PLAYER weapon skills.
_WS_SQL = [
    "modules/custom/sql/prime_weaponskills.sql",
    "modules/custom/sql/prime_gs_axe_ws.sql",
    "modules/custom/sql/maru_kala_ws.sql",
    "modules/custom/sql/tachi_mumei_ws.sql",
]

# weapon_skills.type (LSB SKILLTYPE) -> player-facing weapon category.
_WEAPON = {
    1: "Hand-to-Hand", 2: "Dagger", 3: "Sword", 4: "Great Sword", 5: "Axe",
    6: "Great Axe", 7: "Scythe", 8: "Polearm", 9: "Katana", 10: "Great Katana",
    11: "Club", 12: "Staff", 25: "Archery", 26: "Marksmanship",
}

# WS name token -> display, for the few the generic prettifier can't get right.
_DISPLAY = {
    "tachi_mumei": "Tachi: Mumei",
    "merciless_strike": "Merciless Strike",
}

# WS id -> the Prime weapon that grants it. A MAINTAINED map: the association
# lives only in SQL comments/prose, not a machine-readable column, and parsing
# those comments proved fragile (URLs, header prose). The WS ROSTER itself is
# auto-parsed from the SQL below, so a newly-enabled WS still appears — just
# with a "—" Prime weapon until an entry is added here.
_PRIME_BY_ID = {
    229: "Naegling",        230: "Prime Fists",   232: "Mpu Gandring",
    233: "Prime Sword",     234: "Prime Maul",    235: "Prime Staff",
    94:  "Prime Great Axe", 110: "Prime Scythe",  126: "Prime Lance",
    204: "Prime Bow",       222: "Prime Gun",
    62:  "Prime Blade (Great Sword)", 78: "Prime Pickaxe (Axe)",
    231: "Varga Purnikawa", 159: "Kusanagi-no-Tsurugi",
}

# A data row: (id, 'name', 0x<jobs hex>, <type>, ...)
_ROW_RE = re.compile(r"\(\s*(\d+)\s*,\s*'([a-z0-9_]+)'\s*,\s*0x[0-9a-fA-F]+\s*,\s*(\d+)")


def _display(token: str) -> str:
    if token in _DISPLAY:
        return _DISPLAY[token]
    name = token.replace("_", " ").title()
    # Roman-numeral suffixes the .title() lower-cases.
    name = re.sub(r"\bIi\b", "II", name)
    name = re.sub(r"\bIii\b", "III", name)
    return name


def _parse(text: str) -> list[dict]:
    out: list[dict] = []
    for rm in _ROW_RE.finditer(text):
        wsid, name, wtype = int(rm.group(1)), rm.group(2), int(rm.group(3))
        out.append({
            "id": wsid,
            "name": _display(name),
            "weapon": _WEAPON.get(wtype, f"type {wtype}"),
            "prime": _PRIME_BY_ID.get(wsid, "—"),
        })
    return out


def generate(repo_root: Path, docs_dir: Path) -> None:
    rows: list[dict] = []
    seen: set[int] = set()
    for rel in _WS_SQL:
        src = resolve_source(repo_root, rel)
        if src is None:
            continue
        for r in _parse(src.read_text(encoding="utf-8", errors="replace")):
            if r["id"] in seen:
                continue
            seen.add(r["id"])
            rows.append(r)

    if not rows:
        raise RuntimeError("ws_vs_retail: no custom weapon skills parsed — refusing "
                           "to publish an empty table (check the enabling SQL).")

    rows.sort(key=lambda r: (r["weapon"], r["name"]))
    lines = [
        f"The server enables **{len(rows)} weapon skills** that retail FFXI ships "
        "as monster-only skills — here they are usable by players wielding the "
        "listed Prime weapon. (Stock LandSandBoat leaves these commented out in "
        "`sql/weapon_skills.sql`; the Prime weapon overhaul turns them on.)",
        "",
        "| Weapon skill | Weapon | Prime weapon | On retail | On this server |",
        "|---|---|---|---|---|",
    ]
    for r in rows:
        prime = r["prime"] if r["prime"] != "—" else "—"
        lines.append(
            f"| **{r['name']}** | {r['weapon']} | {prime} | Monster skill only "
            f"| Usable weapon skill |"
        )
    body = "\n".join(lines)

    page = docs_dir / "reference" / "ws-vs-retail.md"
    if write_between_markers(page, "ws-vs-retail-custom", body):
        print(f"[ws_vs_retail] wrote {len(rows)} custom player weapon skills")
    else:
        print(f"[ws_vs_retail] skipped (markers not found in {page})")
