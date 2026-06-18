"""Generate the stub-spell audit on docs/admin/missing-spells.md.

Scans the live spell scripts under scripts/actions/spells/ and classifies each
spell file as IMPLEMENTED or STUB. A STUB is an auto-generated placeholder that
still carries the `[spell-stub]` runtime marker -- it prints a "not yet
implemented" message on cast and applies no effect. Implemented spells call into
the real damage/effect helpers (e.g. xi.spells.blue.useMagicalSpell) and have no
such marker.

The stub files embed everything needed for the table, e.g.:

    print('[spell-stub] cast of "acrid_stream" (id 656, group 3) -- not implemented; ...')
    caster:printToPlayer(
        '[Spell] "Acrid Stream" is not yet implemented on this server, kupo.', ...)

so the spell ID, internal name (file stem), display name, and group are all read
straight from the file -- no DB lookup required.

Reads:  scripts/actions/spells/<group>/*.lua  (via LEGENDARY_LIVE_ROOT)
Fills:  docs/admin/missing-spells.md

Marker IDs:
  - "missing-spells-summary"   -- one-line headline count
  - "missing-spells-stub-list" -- per-group breakdown + full stub table
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers

# The single reliable marker that distinguishes a stub from a real spell: every
# auto-generated stub prints this tag on cast, and no implemented spell does.
STUB_MARKER = "[spell-stub]"

# Pull "(id 656, group 3)" out of the stub's print line.
_ID_GROUP_RE = re.compile(r"\(id\s+(\d+),\s*group\s+(\d+)\)")

# Pull the display name out of '[Spell] "Acrid Stream" is not yet implemented'.
_DISPLAY_RE = re.compile(r"\[Spell\]\s+\"([^\"]+)\"\s+is not yet implemented")

# Friendly label for each group folder (folder name -> display label). Mirrors
# the GROUPS map in spells.py but keyed by folder so it works without the DB.
GROUP_LABELS = {
    "songs":     "Songs",
    "black":     "Black Magic",
    "blue":      "Blue Magic",
    "ninjutsu":  "Ninjutsu",
    "summoning": "Summoning",
    "white":     "White Magic",
    "geomancy":  "Geomancy",
    "trust":     "Trust",
}


def _escape_md(s: str) -> str:
    return s.replace("|", "\\|")


def _pretty_name(stem: str) -> str:
    """Fallback display name from the file stem (only used if the printToPlayer
    line is missing for some reason)."""
    romans = {"i", "ii", "iii", "iv", "v", "vi", "vii", "viii", "ix", "x"}
    parts = stem.split("_")
    out = [p.upper() if p in romans else p.capitalize() for p in parts]
    return " ".join(out) if out else stem


def _scan_stubs(spells_dir: Path) -> list[dict]:
    """Return one dict per stub file: {id, internal, display, group}."""
    stubs: list[dict] = []
    for lua in spells_dir.glob("*/*.lua"):
        try:
            text = lua.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        if STUB_MARKER not in text:
            continue

        group_folder = lua.parent.name
        internal = lua.stem

        id_m = _ID_GROUP_RE.search(text)
        spell_id = int(id_m.group(1)) if id_m else None

        disp_m = _DISPLAY_RE.search(text)
        display = disp_m.group(1) if disp_m else _pretty_name(internal)

        stubs.append({
            "id": spell_id,
            "internal": internal,
            "display": display,
            "group": group_folder,
        })
    return stubs


def _render_summary(stubs: list[dict], by_group: dict[str, int]) -> str:
    total = len(stubs)
    if total == 0:
        return "_All scanned spells are implemented — **0 stubs** remaining._"

    # Name the group(s) the stubs live in, for a readable one-liner.
    labels = [GROUP_LABELS.get(g, g) for g, _ in
              sorted(by_group.items(), key=lambda kv: (-kv[1], kv[0]))]
    if len(labels) == 1:
        where = f"(all {labels[0]})"
    else:
        where = "(" + ", ".join(labels) + ")"

    noun = "stub" if total == 1 else "stubs"
    return f"_Down to **{total} {noun}** remaining {where}._"


def _render_stub_list(stubs: list[dict], by_group: dict[str, int]) -> str:
    total = len(stubs)
    if total == 0:
        return "Nothing stubbed — every spell script has a real implementation. 🎉"

    noun = "spell" if total == 1 else "spells"
    lines = [
        f"**{total} {noun} still stubbed**, broken down by group:",
        "",
        "| Group | Stubs |",
        "|---|---:|",
    ]
    for group, count in sorted(by_group.items(), key=lambda kv: (-kv[1], kv[0])):
        lines.append(f"| {GROUP_LABELS.get(group, group)} | {count} |")

    lines += [
        "",
        "| Spell ID | Internal name | Display name | Group |",
        "|---:|---|---|---|",
    ]
    # Sort by id (None last), then internal name, for a stable diff-friendly order.
    for s in sorted(stubs, key=lambda s: (s["id"] is None, s["id"] or 0, s["internal"])):
        sid = s["id"] if s["id"] is not None else "—"
        lines.append(
            f"| {sid} | `{s['internal']}` | {_escape_md(s['display'])} | {s['group']} |"
        )
    return "\n".join(lines)


def generate(repo_root: Path, docs_dir: Path) -> None:
    spells_dir = resolve_source(repo_root, "scripts/actions/spells")
    if spells_dir is None:
        print("[missing_spells] skip: scripts/actions/spells not found")
        return

    page = docs_dir / "admin" / "missing-spells.md"
    if not page.exists():
        print(f"[missing_spells] skip: target page {page} not found")
        return

    stubs = _scan_stubs(spells_dir)

    by_group: dict[str, int] = {}
    for s in stubs:
        by_group[s["group"]] = by_group.get(s["group"], 0) + 1

    summary = _render_summary(stubs, by_group)
    stub_list = _render_stub_list(stubs, by_group)

    wrote_summary = write_between_markers(page, "missing-spells-summary", summary)
    wrote_list = write_between_markers(page, "missing-spells-stub-list", stub_list)

    breakdown = ", ".join(
        f"{g}={c}" for g, c in sorted(by_group.items(), key=lambda kv: (-kv[1], kv[0]))
    ) or "none"
    print(f"[missing_spells] scanned {spells_dir}: {len(stubs)} stubs ({breakdown})")
    if not wrote_summary:
        print("[missing_spells] WARN: marker 'missing-spells-summary' not found")
    if not wrote_list:
        print("[missing_spells] WARN: marker 'missing-spells-stub-list' not found")
