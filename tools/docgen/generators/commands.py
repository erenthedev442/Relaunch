"""Generate the Player Commands page from scripts/commands/*.lua AND
modules/custom/commands/*.lua.

Lists every command set to `permission = 0` (player-accessible) from
EITHER directory. Custom-module commands get tagged with a `(custom
module)` marker in their detailed section so players can tell at a
glance which commands ship with the server vs. which are bolted on by
Legendary's custom modules.

This generator owns the whole `docs/reference/commands.md` file. To add
hand-written notes that survive regeneration, embed them in marker blocks
inside the rendered template (see _render()) or move them to a sibling
page that links to this one.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source

PARAM_TYPES = {
    "i": "int",
    "I": "int (variadic)",
    "s": "string",
    "S": "string (variadic)",
    "f": "float",
    "b": "bool/raw",
}

# Hand-curated category buckets. Anything unmatched falls into "Misc".
# Matched in order; first prefix that fits wins.
CATEGORIES = [
    ("Movement & Teleport", {"home", "goto", "gotoid", "gotoname", "zone", "pos", "gmhome", "warp"}),
    ("Items & Inventory",   {"additem", "ah", "shop", "delitem", "addkeyitem", "delkeyitem"}),
    ("Spawning",            {"fafnir", "spawnmob", "mobhere", "despawnmob"}),
    ("Buffs & Power",       {"buff", "godmode", "trustengage", "addeffect", "deleffect",
                             "autojp", "automerits", "gainexp"}),  # last three: Legendary custom modules
    ("Information & Debug", {"build", "geteffects", "getstats", "getmod", "getskill", "getfame", "getid", "getpool", "getmobmod", "getmobaction", "getmobflags", "getmobfamily", "getspecies", "getstats", "gettp", "getwspoints", "checkvar", "checklocalvar", "getlocalvars", "pos",
                             "mystats"}),  # mystats: Legendary custom module
]


def generate(repo_root: Path, docs_dir: Path) -> None:
    entries: list[dict] = []
    seen: set[str] = set()    # dedupe by command name (custom would override upstream)
    upstream_count = 0
    custom_count   = 0

    # Pass 1: upstream commands at scripts/commands/
    upstream = resolve_source(repo_root, "scripts/commands")
    if upstream is not None:
        for path in sorted(upstream.glob("*.lua")):
            info = _parse(path)
            if info and info["permission"] == 0:
                info["source"] = "upstream"
                entries.append(info)
                seen.add(info["name"])
                upstream_count += 1

    # Pass 2: Legendary custom modules at modules/custom/commands/. Same
    # name pre-empts upstream so a custom module can override a built-in.
    custom = resolve_source(repo_root, "modules/custom/commands")
    if custom is not None:
        for path in sorted(custom.glob("*.lua")):
            info = _parse(path)
            if not info or info["permission"] != 0:
                continue
            info["source"] = "custom"
            if info["name"] in seen:
                # Replace the upstream entry with the custom override.
                entries = [e for e in entries if e["name"] != info["name"]]
                upstream_count -= 1
            entries.append(info)
            seen.add(info["name"])
            custom_count += 1

    if not entries:
        print("[commands] skip: no permission=0 commands found in either tree")
        return

    out = docs_dir / "reference" / "commands.md"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(_render(entries), encoding="utf-8")
    print(f"[commands] wrote {len(entries)} commands  "
          f"({upstream_count} upstream + {custom_count} custom) -> {out}")


def _parse(path: Path) -> dict | None:
    text = path.read_text(encoding="utf-8", errors="replace")

    # Match permission only on non-comment lines so a stale comment like
    # "-- permission = 0" can't shadow the real cmdprops value.
    perm = re.search(r"^(?!\s*--).*permission\s*=\s*(\d+)", text, re.MULTILINE)
    if not perm:
        return None

    func_m = re.search(r"--\s*func:\s*(.+)", text)
    func = func_m.group(1).strip() if func_m else path.stem

    # Multi-line desc:
    desc_lines = []
    capturing = False
    for line in text.splitlines():
        m = re.match(r"\s*--\s*desc:\s*(.*)", line)
        if m:
            capturing = True
            first = m.group(1).rstrip()
            if first:
                desc_lines.append(first)
            continue
        if capturing:
            stop = (
                re.match(r"\s*--+\s*$", line)
                or re.match(r"\s*--\s*(func|note|usage|@type)\b", line)
                or not re.match(r"\s*--", line)
            )
            cont = re.match(r"\s*--\s+(.+)", line)
            if cont and not stop:
                desc_lines.append(cont.group(1).rstrip())
            else:
                break
    desc = " ".join(l.strip() for l in desc_lines).strip()

    params_m = re.search(r"parameters\s*=\s*'([^']*)'", text)
    params = params_m.group(1) if params_m else ""

    return {
        "name": path.stem,
        "permission": int(perm.group(1)),
        "func": func,
        "desc": desc,
        "parameters": params,
    }


def _format_params(params: str) -> str:
    if not params:
        return "—"
    return ", ".join(PARAM_TYPES.get(c, c) for c in params)


def _categorize(entries: list[dict]) -> dict[str, list[dict]]:
    buckets: dict[str, list[dict]] = {label: [] for label, _ in CATEGORIES}
    buckets["Misc"] = []
    for e in entries:
        placed = False
        for label, names in CATEGORIES:
            if e["name"] in names:
                buckets[label].append(e)
                placed = True
                break
        if not placed:
            buckets["Misc"].append(e)
    return {k: v for k, v in buckets.items() if v}


def _escape_md(s: str) -> str:
    return s.replace("|", "\\|").replace("\n", " ")


def _render(entries: list[dict]) -> str:
    by_cat = _categorize(entries)
    lines = [
        "# Player Commands",
        "",
        "These chat commands are available to every player on Legendary (no GM rank required). "
        "Type them in any chat channel with the `!` prefix.",
        "",
        f"**Total player-accessible commands:** {len(entries)}",
        "",
        "!!! info \"Who can use these\"",
        "    Every command listed here is available to all players. "
        "Some other commands exist but are reserved for GMs; those aren't shown.",
        "",
    ]

    custom_total = sum(1 for e in entries if e.get("source") == "custom")
    if custom_total:
        lines += [
            "!!! note \"Custom commands\"",
            f"    {custom_total} of the commands below are **unique to Legendary** "
            "and won't be found on a standard FFXI server. They're tagged "
            "**:material-puzzle: custom** in the table and their detail section, "
            "and every player can use them.",
            "",
        ]

    # Quick lookup table at top
    lines += [
        "## Quick reference",
        "",
        "| Command | Parameters | Description | Custom? |",
        "|---|---|---|---|",
    ]
    for e in sorted(entries, key=lambda x: x["name"]):
        desc = _escape_md(e["desc"]) or "_(no description)_"
        params = _format_params(e["parameters"])
        src_label = ":material-puzzle: **custom**" if e.get("source") == "custom" else ""
        lines.append(f"| `!{e['name']}` | {params} | {desc} | {src_label} |")
    lines.append("")

    # Detailed sections by category
    for cat, items in by_cat.items():
        lines.append(f"## {cat}")
        lines.append("")
        for e in sorted(items, key=lambda x: x["name"]):
            tag = "  _(custom)_" if e.get("source") == "custom" else ""
            lines.append(f"### `!{e['name']}`{tag}")
            lines.append("")
            if e["desc"]:
                lines.append(e["desc"])
                lines.append("")
            lines.append(f"**Usage:** `{e['func']}`")
            lines.append("")
            params = _format_params(e["parameters"])
            if params != "—":
                lines.append(f"**Parameter types:** {params}")
                lines.append("")

    lines += [
        "---",
        "",
        "_This list reflects the commands currently live on the server._",
        "",
    ]
    return "\n".join(lines)
