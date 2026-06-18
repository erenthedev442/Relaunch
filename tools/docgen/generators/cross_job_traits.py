"""Sync docs/progression/cross-job-traits.md with cross_job_trait_catalog.lua.

The Cross-Job Trait Trainer (GM Home) sells permanent passive traits that
apply on every job. The flat gil price and the trait list (player-facing name
+ description) come from the catalog, so re-pricing or adding a trait updates
the published page. Only the human-readable name/desc are surfaced — the raw
mod wiring is never published.

Markers written:
  cross-job-traits-cost     — the flat per-trait gil price line
  cross-job-traits-catalog  — the trait table (name + effect) + count
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section, commafy


def _parse_traits(text: str) -> list[dict]:
    """Return traits as ordered dicts {name, desc} from catalog.traits.

    Each entry's `id`/`mods`/`trait` (engine wiring) are intentionally ignored;
    only the player-facing `name` and `desc` are published.
    """
    block = section(text, "catalog.traits")
    if not block:
        return []
    inner = block[1:-1]  # strip the enclosing { }

    traits: list[dict] = []
    # Each trait is its own brace-balanced sub-table; an entry can contain a
    # nested `mods = { ... }`, so balance braces rather than split on commas.
    depth, start = 0, -1
    for i, ch in enumerate(inner):
        if ch == "{":
            if depth == 0:
                start = i
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0 and start != -1:
                entry = inner[start:i + 1]
                name_m = re.search(r"name\s*=\s*'([^']+)'", entry)
                desc_m = re.search(r"desc\s*=\s*'([^']+)'", entry)
                if name_m and desc_m:
                    traits.append({"name": name_m.group(1), "desc": desc_m.group(1)})
                start = -1
    return traits


def _escape_md(s: str) -> str:
    return s.replace("|", "\\|").replace("\n", " ")


# ---------------------------------------------------------------------------

def _render_cost(gil: int) -> str:
    return (f"Each trait costs a flat **{commafy(gil)} gil** — a one-time, "
            f"per-character purchase. Once bought, it's yours for good and "
            f"works on every job, with no macro to press.")


def _render_catalog(traits: list[dict]) -> str:
    n = len(traits)
    word = "trait" if n == 1 else "traits"
    lines = [
        f"_**{n} {word}** available — each one passive, permanent, and active on every job._",
        "",
        "| Trait | What it does |",
        "|---|---|",
    ]
    for t in traits:
        lines.append(f"| **{_escape_md(t['name'])}** | {_escape_md(t['desc'])} |")
    return "\n".join(lines)


# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/cross_job_trait_catalog.lua")
    if src is None:
        print("[cross_job_traits] skip: cross_job_trait_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    m = re.search(r"catalog\.GIL_COST\s*=\s*(\d+)", text)
    gil = int(m.group(1)) if m else 10_000_000
    traits = _parse_traits(text)

    if not traits:
        raise RuntimeError("[cross_job_traits] no traits parsed from catalog")

    page = docs_dir / "progression" / "cross-job-traits.md"
    blocks = [
        ("cross-job-traits-cost", _render_cost(gil)),
        ("cross-job-traits-catalog", _render_catalog(traits)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[cross_job_traits] {written}/{len(blocks)} marker block(s) written "
          f"(traits={len(traits)})")
