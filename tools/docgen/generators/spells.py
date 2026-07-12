"""Generate spells reference pages from sql/spell_list.sql.

The Trust page is a special case: instead of the mechanical spell columns
(Skill/Element/MP/Cast/Recast/Jobs) it shows each alter ego's BG-wiki
behavior/role (Tank, Healer, Melee Fighter, ...), read from
tools/docgen/data/trust_behaviors.json.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

# Trust behaviors live in a committed data file next to the generators, keyed by
# the trust's DISPLAY name (same string _pretty_name produces). Missing/renamed
# entries fall back to "—" rather than erroring.
_TRUST_BEHAVIORS_PATH = Path(__file__).resolve().parent.parent / "data" / "trust_behaviors.json"


def _load_trust_behaviors() -> dict[str, str]:
    if not _TRUST_BEHAVIORS_PATH.exists():
        print(f"[spells] note: {_TRUST_BEHAVIORS_PATH.name} not found — Behaviors show as '—'")
        return {}
    try:
        data = json.loads(_TRUST_BEHAVIORS_PATH.read_text(encoding="utf-8"))
    except (ValueError, OSError) as exc:
        print(f"[spells] WARN: could not read {_TRUST_BEHAVIORS_PATH.name}: {exc}")
        return {}
    # Accept either a flat {name: role} map or {"behaviors": {...}, ...}.
    return data.get("behaviors", data) if isinstance(data, dict) else {}

ELEMENTS = {
    0: "None", 1: "Fire", 2: "Ice", 3: "Wind", 4: "Earth",
    5: "Thunder", 6: "Water", 7: "Light", 8: "Dark",
}

SKILLS = {
    0: "—", 32: "Divine", 33: "Healing", 34: "Enhancing", 35: "Enfeebling",
    36: "Elemental", 37: "Dark", 38: "Summoning", 39: "Ninjutsu",
    40: "Singing", 43: "Blue", 44: "Geomancy",
}

GROUPS = {
    1: ("songs",     "Songs"),
    2: ("black",     "Black Magic"),
    3: ("blue",      "Blue Magic"),
    4: ("ninjutsu",  "Ninjutsu"),
    5: ("summoning", "Summoning"),
    6: ("white",     "White Magic"),
    7: ("geomancy",  "Geomancy"),
    8: ("trust",     "Trust"),
}

# Blob byte 0..21 maps to jobs WAR..RUN. See src/map/spell.cpp:491
# (tempJobs[0..21] copied into jobs[1..22] where 1=WAR..22=RUN).
JOB_BLOB_ORDER = [
    "WAR", "MNK", "WHM", "BLM", "RDM", "THF", "PLD", "DRK",
    "BST", "BRD", "RNG", "SAM", "NIN", "DRG", "SMN", "BLU",
    "COR", "PUP", "DNC", "SCH", "GEO", "RUN",
]

SPELL_COLS = [
    "spellid", "name", "jobs", "group", "family", "element", "zonemisc",
    "validTargets", "skill", "mpCost", "castTime", "recastTime",
    "message", "magicBurstMessage", "animation", "animationTime",
    "AOE", "base", "multiplier", "CE", "VE", "requirements",
    "spell_range", "radius", "content_tag",
]


def parse_sql(text: str):
    text = re.sub(r"/\*![^*]*\*+(?:[^/*][^*]*\*+)*/", "", text, flags=re.DOTALL)
    text = re.sub(r"--[^\n]*", "", text)

    variables: dict[str, str] = {}
    for m in re.finditer(r"SET\s+@(\w+)\s*=\s*([^;]+);", text):
        variables[m.group(1)] = m.group(2).strip()

    rows: list[list] = []
    for ins in re.finditer(r"INSERT\s+INTO\s+`?\w+`?\s+VALUES\s+(.+?);", text, re.DOTALL):
        for tup in _split_tuples(ins.group(1)):
            rows.append(_tokenize_tuple(tup, variables))
    return variables, rows


def _split_tuples(body: str):
    depth = 0
    in_quote = False
    start = 0
    i = 0
    while i < len(body):
        c = body[i]
        if in_quote:
            if c == "\\":
                i += 2
                continue
            if c == "'":
                in_quote = False
        else:
            if c == "'":
                in_quote = True
            elif c == "(":
                if depth == 0:
                    start = i + 1
                depth += 1
            elif c == ")":
                depth -= 1
                if depth == 0:
                    yield body[start:i]
        i += 1


def _tokenize_tuple(tup: str, variables: dict[str, str]):
    tokens = []
    buf = []
    in_quote = False
    i = 0
    while i < len(tup):
        c = tup[i]
        if in_quote:
            if c == "\\" and i + 1 < len(tup):
                buf.append(tup[i:i + 2])
                i += 2
                continue
            buf.append(c)
            if c == "'":
                in_quote = False
        else:
            if c == "'":
                in_quote = True
                buf.append(c)
            elif c == ",":
                tokens.append(_convert("".join(buf).strip(), variables))
                buf = []
            else:
                buf.append(c)
        i += 1
    if buf:
        tokens.append(_convert("".join(buf).strip(), variables))
    return tokens


def _convert(tok: str, variables: dict[str, str]):
    if tok == "NULL":
        return None
    if tok.startswith("'") and tok.endswith("'"):
        return tok[1:-1].replace("\\'", "'").replace("\\\\", "\\")
    if tok.startswith(("0x", "0X")):
        return bytes.fromhex(tok[2:])
    if tok.startswith("@"):
        return _convert(variables.get(tok[1:], tok), variables)
    try:
        return float(tok) if "." in tok else int(tok)
    except ValueError:
        return tok


def _format_jobs(blob: bytes) -> str:
    parts = []
    for i, name in enumerate(JOB_BLOB_ORDER):
        lvl = blob[i] if i < len(blob) else 0
        if lvl > 0:
            parts.append(f"{name} {lvl}")
    return " / ".join(parts) if parts else "—"


def _ms(value: int) -> str:
    return "—" if value == 0 else f"{value / 1000:.1f}s"


def _pretty_name(raw: str) -> str:
    romans = {"i", "ii", "iii", "iv", "v", "vi", "vii", "viii", "ix", "x"}
    parts = raw.split("_")
    out = []
    for p in parts:
        if p in romans:
            out.append(p.upper())
        else:
            out.append(p.capitalize())
    return " ".join(out) if out else raw


def _escape_md(s: str) -> str:
    return s.replace("|", "\\|")


def generate(repo_root: Path, docs_dir: Path) -> None:
    sql_path = repo_root / "sql" / "spell_list.sql"
    if not sql_path.exists():
        print(f"[spells] skip: {sql_path} not found")
        return

    text = sql_path.read_text(encoding="utf-8", errors="replace")
    _, rows = parse_sql(text)

    spells = [dict(zip(SPELL_COLS, r)) for r in rows if len(r) >= len(SPELL_COLS)]

    out_dir = docs_dir / "reference" / "spells"
    out_dir.mkdir(parents=True, exist_ok=True)

    by_group: dict[int, list[dict]] = {}
    for s in spells:
        by_group.setdefault(s["group"], []).append(s)

    index_lines = [
        "# Spells",
        "",
        "_Search the site (top right) to find a spell by name._",
        "",
        f"**Total spells in database:** {len(spells)}",
        "",
        "| Category | Spells |",
        "|---|---:|",
    ]
    for gid in sorted(by_group):
        if gid not in GROUPS:
            continue
        slug, label = GROUPS[gid]
        # Trust lives under Progression (owner request 2026-07-12) -- it is a
        # progression system on relaunch (summon-count ladder, vendor unlocks),
        # not spell reference material.
        target = "../../progression/trusts.md" if slug == "trust" else f"{slug}.md"
        index_lines.append(f"| [{label}]({target}) | {len(by_group[gid])} |")
    index_lines.append("")
    (out_dir / "index.md").write_text("\n".join(index_lines), encoding="utf-8")

    for gid, group_spells in by_group.items():
        if gid not in GROUPS:
            continue
        slug, label = GROUPS[gid]
        if slug == "trust":
            _write_group_page(docs_dir / "progression" / "trusts.md", label, group_spells)
        else:
            _write_group_page(out_dir / f"{slug}.md", label, group_spells)

    # Redirect stub at the old trust URL so bookmarks and external links keep
    # working (the site has no redirects plugin; a body meta-refresh works in
    # every browser). Generator-owned so sync_audit sees an owner.
    (out_dir / "trust.md").write_text(
        "# Trust\n\n"
        '<meta http-equiv="refresh" content="0; url=../../progression/trusts/">\n\n'
        "This page moved to **[Progression → Trusts](../../progression/trusts.md)** "
        "— you will be redirected automatically.\n",
        encoding="utf-8")

    print(f"[spells] wrote {len(spells)} spells across {len(by_group)} groups -> {out_dir} "
          f"(trust -> progression/trusts.md + redirect stub)")


# Relaunch-specific per-page notes, keyed by page slug (path stem). Rendered as
# an admonition directly under the page title.
#
# The trust note is a DOCGEN marker SLOT, not a static string: the trust_tiers
# generator (registered after spells) fills it with the live summon-count
# ladder + the locked custom-trust table, parsed from trust_progression_cap.lua
# + trust_skoll.lua so it can't drift. The text below is a fallback that only
# survives if trust_tiers fails to parse.
PAGE_NOTES = {
    "trusts": (   # progression/trusts.md (moved out of reference/spells 2026-07-12)
        '<!-- DOCGEN:BEGIN id="trust-tiers" -->\n'
        '!!! info "Trust progression"\n'
        "    Every trust is learnable from day 1; how many you can field at once "
        "climbs its own ladder, and a few marquee trusts are unlocked at a vendor. "
        "See `trust_progression_cap.lua` / `trust_skoll.lua`.\n"
        '<!-- DOCGEN:END id="trust-tiers" -->'
    ),
}


def _write_group_page(path: Path, label: str, spells: list[dict]) -> None:
    lines = [
        f"# {label}",
        "",
    ]
    note = PAGE_NOTES.get(path.stem)
    if note:
        lines.extend([note, ""])
    lines.extend([
        "_Spells are sorted by ID._",
        "",
        f"**Spells in this category:** {len(spells)}",
        "",
    ])

    if path.stem == "trusts":
        # Trust page: drop the mechanical spell columns; show each alter ego's
        # BG-wiki behavior/role instead. Behaviors keyed by display name.
        behaviors = _load_trust_behaviors()
        matched = 0
        lines.extend([
            "| ID | Name | Behaviors |",
            "|---:|---|---|",
        ])
        for s in sorted(spells, key=lambda s: s["spellid"]):
            pretty = _pretty_name(s["name"])
            beh = behaviors.get(pretty) or behaviors.get(s["name"]) or "—"
            if beh != "—":
                matched += 1
            lines.append(f"| {s['spellid']} | {_escape_md(pretty)} | {_escape_md(beh)} |")
        print(f"[spells] trust: {matched}/{len(spells)} behaviors matched")
    else:
        lines.extend([
            "| ID | Name | Skill | Element | MP | Cast | Recast | Jobs |",
            "|---:|---|---|---|---:|---:|---:|---|",
        ])
        for s in sorted(spells, key=lambda s: s["spellid"]):
            jobs_blob = s["jobs"] if isinstance(s["jobs"], (bytes, bytearray)) else b""
            mp = s["mpCost"] if s["mpCost"] else "—"
            skill_id = s["skill"]
            elem_id = s["element"]
            skill = SKILLS.get(skill_id, f"#{skill_id}")
            element = ELEMENTS.get(elem_id, f"#{elem_id}")
            pretty = _escape_md(_pretty_name(s["name"]))
            lines.append(
                f"| {s['spellid']} | {pretty} | {skill} | {element} | {mp} "
                f"| {_ms(s['castTime'])} | {_ms(s['recastTime'])} | {_format_jobs(jobs_blob)} |"
            )

    lines.append("")
    path.write_text("\n".join(lines), encoding="utf-8")
