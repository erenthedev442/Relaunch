"""Sync docs/endgame/nyzul-isle.md with armoury_crate.lua and appraisal.lua.

Nyzul Isle NMs spawn treasure coffers on death. Each coffer contains an
UNAPPRAISED item whose type is NM-specific (e.g. Bat Eye always gives an
Unappraised Axe). Taking the unappraised item to an appraiser reveals the
actual gear, drawn from a weighted per-NM loot table in appraisal.lua.

This generator reads both files and renders a combined NM → drop table so
players know which NMs to hunt for their target gear slot.

Markers written:
  nyzul-nm-drops   — NM roster table (name, item type, possible drops + odds)
  nyzul-floor100   — floor-100 boss vigil-weapon pool
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section


# ── Helpers ─────────────────────────────────────────────────────────────────

_LOWER_WORDS = {"of", "no", "the", "to", "in", "a", "an", "and", "for", "s"}

def _titleize(token: str) -> str:
    """TOKEN_NAME -> Token Name (respects small-word list after first word)."""
    parts = token.lower().split("_")
    return " ".join(
        w if (i > 0 and w in _LOWER_WORDS) else w.capitalize()
        for i, w in enumerate(parts)
    )


def _nm_name(token: str) -> str:
    """NYZUL_BAT_EYE -> Bat Eye"""
    t = re.sub(r"^NYZUL_", "", token)
    return _titleize(t)


def _item_name(token: str) -> str:
    """xi.item.GUST_CLAYMORE -> Gust Claymore"""
    t = re.sub(r"^xi\.item\.", "", token).strip()
    return _titleize(t)


def _slot_name(token: str) -> str:
    """UNAPPRAISED_SWORD -> Sword  (the appraisal slot / chest category)"""
    t = re.sub(r"^UNAPPRAISED_", "", token)
    return _titleize(t)


# ── Parsing: armoury_crate.lua (NM -> unappraised type) ────────────────────

def _parse_crate(text: str) -> dict[str, str | list[str]]:
    """Return {NM_KEY: slot_token} from the appraisalItems table.

    NM_KEY is like "NYZUL_BAT_EYE", slot_token is "UNAPPRAISED_AXE"
    (or a list for NMs like Fraelissa that drop two slot types).
    """
    block = section(text, "local appraisalItems")
    if not block:
        block = text  # fallback: scan whole file

    nm_slot: dict[str, str | list[str]] = {}

    # Multi-type: [xi.appraisal.origin.NYZUL_X] = { xi.item.A, xi.item.B },
    # NOTE: armoury_crate.lua pads keys with spaces before ], so \s* is required.
    multi = re.finditer(
        r"\[xi\.appraisal\.origin\.(NYZUL_\w+)\s*\]\s*=\s*\{([^}]+)\}",
        block,
    )
    for m in multi:
        nm = m.group(1)
        inner = m.group(2)
        slots = re.findall(r"xi\.item\.(UNAPPRAISED_\w+)", inner)
        if len(slots) > 1:
            nm_slot[nm] = slots
        elif len(slots) == 1:
            nm_slot[nm] = slots[0]

    # Single-type: [xi.appraisal.origin.NYZUL_X   ] = xi.item.UNAPPRAISED_Y,
    single = re.finditer(
        r"\[xi\.appraisal\.origin\.(NYZUL_\w+)\s*\]\s*=\s*(xi\.item\.UNAPPRAISED_\w+)",
        block,
    )
    for m in single:
        nm = m.group(1)
        if nm not in nm_slot:
            slot = re.sub(r"xi\.item\.", "", m.group(2))
            nm_slot[nm] = slot

    return nm_slot


# ── Parsing: appraisal.lua (NM -> weighted item list) ──────────────────────

def _parse_appraisal(text: str) -> dict[str, list[tuple[int, str]]]:
    """Return {NM_KEY: [(weight, item_display_name), ...]} sorted desc by weight."""
    result: dict[str, list[tuple[int, str]]] = {}

    # Find every [xi.appraisal.origin.NYZUL_X] block.
    # Strategy: scan for the pattern, then brace-balance the inner block.
    pattern = re.compile(
        r"\[xi\.appraisal\.origin\.(NYZUL_\w+)\]\s*=\s*\{"
    )

    for m in pattern.finditer(text):
        nm = m.group(1)
        start = m.end() - 1  # opening brace
        # brace-balance to extract the full block
        depth, i, n = 0, start, len(text)
        while i < n:
            c = text[i]
            if c == "-" and i + 1 < n and text[i + 1] == "-":
                nl = text.find("\n", i)
                i = (nl + 1) if nl != -1 else n
                continue
            if c in ("'", '"'):
                q, i = c, i + 1
                while i < n:
                    if text[i] == "\\" and i + 1 < n:
                        i += 2
                    elif text[i] == q:
                        i += 1
                        break
                    else:
                        i += 1
                continue
            if c == "{":
                depth += 1
            elif c == "}":
                depth -= 1
                if depth == 0:
                    block = text[start:i + 1]
                    break
            i += 1
        else:
            continue

        # Extract items: { weight, xi.item.NAME }
        items: list[tuple[int, str]] = []
        for row in re.finditer(
            r"\{\s*(\d+)\s*,\s*(xi\.item\.\w+)\s*\}",
            block,
        ):
            weight = int(row.group(1))
            name = _item_name(row.group(2))
            items.append((weight, name))

        if items:
            items.sort(key=lambda x: x[0], reverse=True)
            result[nm] = items

    return result


# ── Parsing: nyzul.lua (floor-100 vigil weapons) ───────────────────────────

def _parse_vigil_weapons(text: str) -> list[str]:
    """Return list of job-weapon display names from baseWeapons."""
    block = section(text, "xi.nyzul.baseWeapons")
    if not block:
        return []
    weapons: list[str] = []
    seen: set[str] = set()
    for m in re.finditer(r"xi\.item\.(\w+)", block):
        name = _item_name(f"xi.item.{m.group(1)}")
        if name not in seen:
            seen.add(name)
            weapons.append(name)
    return weapons


# ── Rendering ───────────────────────────────────────────────────────────────

def _pct(w: int, total: int) -> str:
    p = round(100 * w / total) if total else w
    return f"{p}%"


def _render_nm_table(
    nm_slot: dict[str, str | list[str]],
    nm_items: dict[str, list[tuple[int, str]]],
) -> str:
    rows: list[tuple[str, str, str]] = []  # (nm_display, slot_display, drops_str)

    for nm_key, slot in sorted(nm_slot.items(), key=lambda kv: _nm_name(kv[0])):
        nm_display = _nm_name(nm_key)

        if isinstance(slot, list):
            slot_display = " / ".join(_slot_name(s) for s in slot)
        else:
            slot_display = _slot_name(slot)

        items = nm_items.get(nm_key, [])
        if not items:
            drops_str = "—"
        else:
            total = sum(w for w, _ in items)
            parts = [f"{name} ({_pct(w, total)})" for w, name in items]
            drops_str = ", ".join(parts)

        rows.append((nm_display, slot_display, drops_str))

    if not rows:
        return "_No NM data found._\n"

    lines = [
        "| NM | Chest type | Possible drops |",
        "|---|---|---|",
    ]
    for nm_display, slot_display, drops_str in rows:
        lines.append(f"| {nm_display} | {slot_display} | {drops_str} |")

    return "\n".join(lines) + "\n"


def _render_vigil_table(weapons: list[str]) -> str:
    if not weapons:
        return "_Vigil weapon list unavailable._\n"
    items = ", ".join(f"**{w}**" for w in weapons)
    return (
        "On a **floor 100** clear the boss drops one random Vigil Weapon from the "
        f"full pool, plus one targeted to the disk-holder's main job if the party "
        f"doesn't already own it.\n\n"
        f"**Vigil Weapon pool ({len(weapons)} weapons):** {items}\n"
    )


# ── Entry point ─────────────────────────────────────────────────────────────

def generate(repo_root: Path, docs_dir: Path) -> None:
    crate_path  = resolve_source(repo_root, "scripts/globals/nyzul/armoury_crate.lua")
    appr_path   = resolve_source(repo_root, "scripts/globals/appraisal.lua")
    nyzul_path  = resolve_source(repo_root, "scripts/globals/nyzul.lua")
    page_path   = docs_dir / "endgame" / "nyzul-isle.md"

    crate_text = crate_path.read_text(encoding="utf-8")
    appr_text  = appr_path.read_text(encoding="utf-8")
    nyzul_text = nyzul_path.read_text(encoding="utf-8")

    nm_slot  = _parse_crate(crate_text)
    nm_items = _parse_appraisal(appr_text)
    weapons  = _parse_vigil_weapons(nyzul_text)

    drops_md = _render_nm_table(nm_slot, nm_items)
    vigil_md = _render_vigil_table(weapons)

    write_between_markers(page_path, "nyzul-nm-drops", drops_md)
    write_between_markers(page_path, "nyzul-floor100", vigil_md)
