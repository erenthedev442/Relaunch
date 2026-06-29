"""Generate prestige (Ascension) reference tables inside docs/progression/prestige.md.

Reads: modules/custom/lua/prestige_catalog.lua

Marker IDs:
  - "prestige-economy"       -- mark cost escalation table + cap description
  - "prestige-nightmare-court" -- three Trial boss table
  - "prestige-ap-table"      -- full AP spend table, organised by section
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers

# ---------------------------------------------------------------------------
# Lua helpers (duplicated per the established pattern)
# ---------------------------------------------------------------------------

_QUOTED = r"""'(?:[^'\\]|\\.)*'|"(?:[^"\\]|\\.)*" """

# Robust single/double-quoted string matcher. Unlike _QUOTED (a shared
# constant with a trailing-space quirk in its double-quote branch), this
# matches a double-quoted literal regardless of the following character —
# needed for values like name = "The World's End", whose closing quote is
# immediately followed by a comma.
_QSTR = r"""(?:'(?:[^'\\]|\\.)*'|"(?:[^"\\]|\\.)*")"""


def _quoted_value(s: str) -> str:
    """Strip surrounding quotes from a Lua string literal."""
    s = s.strip()
    if (s.startswith("'") and s.endswith("'")) or (s.startswith('"') and s.endswith('"')):
        return s[1:-1]
    return s


def _balanced_blocks(text: str):
    """Yield (start, end) character offsets for every top-level {...} block."""
    depth = 0
    in_single = False
    in_double = False
    start = -1
    i = 0
    while i < len(text):
        c = text[i]
        # Handle Lua single-line comments
        if not in_single and not in_double and text[i:i+2] == '--':
            end_of_line = text.find('\n', i)
            i = end_of_line + 1 if end_of_line != -1 else len(text)
            continue
        if c == "'" and not in_double:
            in_single = not in_single
        elif c == '"' and not in_single:
            in_double = not in_double
        elif not in_single and not in_double:
            if c == '{':
                if depth == 0:
                    start = i
                depth += 1
            elif c == '}':
                depth -= 1
                if depth == 0 and start != -1:
                    yield (start, i + 1)
                    start = -1
        i += 1

# ---------------------------------------------------------------------------
# Hardcoded dread descriptions keyed by groupId
# ---------------------------------------------------------------------------

_DREAD = {
    11370: "Weaves **Nightmare** — an area sleep that drags your whole party into the dark, then drains your life while you dream.",
    11373: "Her **petrifying gaze** turns you to stone where you stand. Frozen, you can only watch as she carves the party apart.",
    11372: "Raises his blade for **Zantetsuken** — a stroke that does not wound. It simply ends you.",
}

# ---------------------------------------------------------------------------
# AP-table sections: (section_name, list_of_category_ids)
# ---------------------------------------------------------------------------

_SECTIONS = [
    ("Base Stats",        ["STR", "DEX", "VIT", "AGI", "INT", "MND", "CHR", "HP", "MP"]),
    ("Melee & Magic",     ["ACC", "ATT", "DEF", "EVA", "MACC", "MATT"]),
    ("Combat Traits",     ["STP", "TPBON", "QA", "CRIT", "CRITDMG", "CTR", "PARRY", "SBL", "WSDMG", "DW", "SCDMG"]),
    ("Ranged",            ["RACC", "RATT"]),
    ("Mitigation",        ["PDT", "MDT", "HASTE"]),
    ("Magic Support",     ["INTP", "FCAST", "ENSP", "CURE", "RFSH", "MDMG"]),
    ("Utility",           ["TH", "GIL"]),
    ("Resistances & Skills", ["STRES", "ELRES", "SKILL"]),
    ("Pet Boost",         ["PET"]),
]

# ---------------------------------------------------------------------------
# Ordinal helper
# ---------------------------------------------------------------------------

def _ordinal(n: int) -> str:
    if 11 <= (n % 100) <= 13:
        suffix = "th"
    else:
        suffix = {1: "st", 2: "nd", 3: "rd"}.get(n % 10, "th")
    return f"{n}{suffix}"


# ---------------------------------------------------------------------------
# Parsers
# ---------------------------------------------------------------------------

def _parse_scalar(text: str, key: str) -> int | None:
    """Parse a top-level integer scalar from a Lua table text."""
    m = re.search(rf'\b{re.escape(key)}\s*=\s*(\d+)', text)
    return int(m.group(1)) if m else None


def _parse_ap_tiers(text: str) -> list[dict]:
    """Parse apTiers = { {minLevel=N, ap=N}, ... } from the catalog."""
    m = re.search(r'\bapTiers\s*=\s*\{', text)
    if not m:
        return []
    sub = text[m.end() - 1:]
    block = None
    for start, end in _balanced_blocks(sub):
        block = sub[start:end]
        break
    if not block:
        return []
    tiers = []
    for em in re.finditer(r'\{\s*minLevel\s*=\s*(\d+)\s*,\s*ap\s*=\s*(\d+)\s*\}', block):
        tiers.append({"minLevel": int(em.group(1)), "ap": int(em.group(2))})
    return tiers


def _parse_nms(text: str) -> list[dict]:
    """Parse the trial.nms array entries."""
    # Find the trial block first
    m = re.search(r'\btrial\s*=\s*\{', text)
    if not m:
        return []
    for start, end in _balanced_blocks(text[m.start():]):
        trial_block = text[m.start():][start:end]
        break
    else:
        return []

    nms = []
    for nm_match in re.finditer(r'\{\s*groupId\s*=\s*(\d+)\s*,\s*label\s*=\s*(' + _QUOTED + r')\s*\}', trial_block):
        nms.append({
            "groupId": int(nm_match.group(1)),
            "label": _quoted_value(nm_match.group(2).strip()),
        })
    return nms


def _parse_categories(text: str) -> list[dict]:
    """Parse the categories array entries."""
    m = re.search(r'\bcategories\s*=\s*\{', text)
    if not m:
        return []
    for start, end in _balanced_blocks(text[m.start():]):
        cats_block = text[m.start():][start:end]
        break
    else:
        return []

    cats = []
    # Each category starts with { id = '...', label = '...', ...
    for entry_start, entry_end in _balanced_blocks(cats_block[1:]):  # skip outer {
        entry = cats_block[1:][entry_start:entry_end]
        id_m = re.search(r'\bid\s*=\s*(' + _QUOTED + r')', entry)
        label_m = re.search(r'\blabel\s*=\s*(' + _QUOTED + r')', entry)
        cap_m = re.search(r'\bcap\s*=\s*(\d+)', entry)
        ap_m = re.search(r'\bapCost\s*=\s*(\d+)', entry)
        note_m = re.search(r'\bnote\s*=\s*(' + _QUOTED + r')', entry)

        if not (id_m and label_m and cap_m and ap_m and note_m):
            continue

        cats.append({
            "id":     _quoted_value(id_m.group(1).strip()),
            "label":  _quoted_value(label_m.group(1).strip()),
            "cap":    int(cap_m.group(1)),
            "apCost": int(ap_m.group(1)),
            "note":   _quoted_value(note_m.group(1).strip()),
        })

    return cats


def _extract_block(text: str, key: str) -> str | None:
    """Return the text of the first top-level `{...}` assigned to `key = {`."""
    m = re.search(rf'\b{re.escape(key)}\s*=\s*\{{', text)
    if not m:
        return None
    # Search from the '{' the assignment opens, so the first balanced block is it.
    sub = text[m.end() - 1:]
    for start, end in _balanced_blocks(sub):
        return sub[start:end]
    return None


def _parse_trial_boss_labels(text: str) -> list[str]:
    """Top-level Nightmare Court bosses, in trialBossOrder, as labels.

    Used for tier 0 (which has no roster and falls back to these)."""
    order_m = re.search(r'\btrialBossOrder\s*=\s*\{([^}]*)\}', text)
    order = [int(n) for n in re.findall(r'\d+', order_m.group(1))] if order_m else []

    bosses_block = _extract_block(text, "trialBosses")
    labels_by_id: dict[int, str] = {}
    if bosses_block:
        # Each entry: [<id>] = { ... label = '...' ... }
        for entry_m in re.finditer(r'\[\s*(\d+)\s*\]\s*=\s*\{', bosses_block):
            bid = int(entry_m.group(1))
            sub = bosses_block[entry_m.end() - 1:]
            for s, e in _balanced_blocks(sub):
                label_m = re.search(r'\blabel\s*=\s*(' + _QSTR + r')', sub[s:e])
                if label_m:
                    labels_by_id[bid] = _quoted_value(label_m.group(1).strip())
                break

    if order:
        return [labels_by_id[i] for i in order if i in labels_by_id]
    return list(labels_by_id.values())


def _parse_scaling_tiers(text: str, court0_bosses: list[str]) -> list[dict]:
    """Parse trialScaling.tiers into an ascending list of tier dicts.

    Each: {minLevel, mult, name, bosses=[label,...], uses_top_court: bool}.
    Tier 0 has no roster -> bosses come from `court0_bosses` (the top-level
    Nightmare Court) and uses_top_court is True.
    """
    scaling_block = _extract_block(text, "trialScaling")
    if scaling_block is None:
        return []
    tiers_block = _extract_block(scaling_block, "tiers")
    if tiers_block is None:
        return []

    tiers: list[dict] = []
    # Walk each top-level entry inside the tiers array (skip the outer braces).
    for entry_start, entry_end in _balanced_blocks(tiers_block[1:-1]):
        entry = tiers_block[1:-1][entry_start:entry_end]
        # The tier's own fields sit before its `roster`; clip there so a
        # boss's `name = '...'` inside the roster can never be mistaken for
        # the tier name.
        roster_at = re.search(r'\broster\s*=', entry)
        head = entry[:roster_at.start()] if roster_at else entry

        min_m  = re.search(r'\bminLevel\s*=\s*(\d+)', head)
        mult_m = re.search(r'\bmult\s*=\s*([\d.]+)', head)
        name_m = re.search(r'\bname\s*=\s*(' + _QSTR + r')', head)
        if not (min_m and name_m):
            continue

        min_level = int(min_m.group(1))
        mult = float(mult_m.group(1)) if mult_m else 1.0
        name = _quoted_value(name_m.group(1).strip())

        # Roster bosses, in `order`, by label. Tier 0 has no roster.
        roster_block = _extract_block(entry, "roster")
        bosses: list[str] = []
        uses_top_court = False
        if roster_block is not None:
            order_m = re.search(r'\border\s*=\s*\{([^}]*)\}', roster_block)
            order = [int(n) for n in re.findall(r'\d+', order_m.group(1))] if order_m else []
            labels_by_id: dict[int, str] = {}
            bosses_block = _extract_block(roster_block, "bosses")
            if bosses_block:
                for boss_m in re.finditer(r'\[\s*(\d+)\s*\]\s*=\s*\{', bosses_block):
                    bid = int(boss_m.group(1))
                    sub = bosses_block[boss_m.end() - 1:]
                    for s, e in _balanced_blocks(sub):
                        label_m = re.search(r'\blabel\s*=\s*(' + _QSTR + r')', sub[s:e])
                        if label_m:
                            labels_by_id[bid] = _quoted_value(label_m.group(1).strip())
                        break
            bosses = [labels_by_id[i] for i in order if i in labels_by_id] or list(labels_by_id.values())
        else:
            bosses = list(court0_bosses)
            uses_top_court = True

        tiers.append({
            "minLevel": min_level,
            "mult": mult,
            "name": name,
            "bosses": bosses,
            "uses_top_court": uses_top_court,
        })

    tiers.sort(key=lambda t: t["minLevel"])
    return tiers


# ---------------------------------------------------------------------------
# Renderers
# ---------------------------------------------------------------------------

def _render_economy(mark_cost_base: int, mark_cost_cap: int, ap_tiers: list[dict]) -> str:
    lines = []
    lines.append("| Ascension # | Mark cost |")
    lines.append("|---|---:|")

    cap_hit_at = None
    n = 1
    rows = []
    while True:
        cost = min(mark_cost_base * n, mark_cost_cap)
        if cost >= mark_cost_cap and cap_hit_at is None:
            cap_hit_at = n
            rows.append(f"| {_ordinal(n)} | {cost:,} marks |")
            break
        rows.append(f"| {_ordinal(n)} | {cost:,} marks |")
        n += 1

    lines.extend(rows)
    if cap_hit_at is not None:
        # Replace the last data row with the cap note
        lines[-1] = f"| {_ordinal(cap_hit_at)}+ ascension | **{mark_cost_cap:,} marks** (cap) |"

    lines.append("")
    lines.append(
        f"The cost **caps at {mark_cost_cap:,} marks** — every ascension from the "
        f"{_ordinal(cap_hit_at)} onward costs the same flat {mark_cost_cap:,}."
    )
    lines.append("")
    if ap_tiers and len(ap_tiers) > 1:
        parts = []
        for i, t in enumerate(ap_tiers):
            lo = t["minLevel"] if t["minLevel"] > 0 else 1
            if i + 1 < len(ap_tiers):
                hi = ap_tiers[i + 1]["minLevel"] - 1
                parts.append(f"**{t['ap']} AP** (P.Lv {lo}–{hi})")
            else:
                parts.append(f"**{t['ap']} AP** (P.Lv {lo}+)")
        lines.append(f"_Each ascension awards AP scaled by your Prestige Level: {', '.join(parts)}._")
    elif ap_tiers:
        lines.append(f"_Each ascension awards **{ap_tiers[0]['ap']} AP** for your current main job._")
    else:
        lines.append("_Each ascension awards **10 AP** for your current main job._")
    return "\n".join(lines)


def _render_nightmare_court(nms: list[dict]) -> str:
    lines = []
    lines.append("| Boss | The Dread |")
    lines.append("|---|---|")
    for nm in nms:
        dread = _DREAD.get(nm["groupId"], "_Unknown_")
        lines.append(f"| **{nm['label']}** | {dread} |")
    return "\n".join(lines)


def _render_scaling(tiers: list[dict]) -> str:
    """Render the Court-rotation table from trialScaling.tiers.

    Per tier: Ascension range (this minLevel .. one below the next tier's
    minLevel; last tier is "N+"), the Court name, and its three bosses.

    If every tier's mult is 1.0 the difficulty lives entirely in the roster
    rotation, so no multiplier column is shown. A "Stat scaling (×mult)"
    column is only added when some tier's mult is meaningfully > 1.0.
    """
    if not tiers:
        return ""

    show_mult = any(t["mult"] > 1.001 for t in tiers)

    if show_mult:
        header = "| Ascensions (that job) | Court | Bosses you face | Stat scaling |"
        sep = "|---|---|---|---:|"
    else:
        header = "| Ascensions (that job) | Court | Bosses you face |"
        sep = "|---|---|---|"

    lines = [header, sep]
    for i, t in enumerate(tiers):
        lo = t["minLevel"]
        if i + 1 < len(tiers):
            rng = f"{lo}–{tiers[i + 1]['minLevel'] - 1}"
        else:
            rng = f"{lo}+"

        bosses = " &bull; ".join(t["bosses"]) if t["bosses"] else "_(top-level Nightmare Court)_"
        if t["uses_top_court"]:
            bosses += " _(the top-level Nightmare Court)_"

        if show_mult:
            lines.append(f"| **{rng}** | {t['name']} | {bosses} | ×{t['mult']:g} |")
        else:
            lines.append(f"| **{rng}** | {t['name']} | {bosses} |")

    return "\n".join(lines)


def _render_ap_table(cats: list[dict]) -> str:
    cats_by_id = {c["id"]: c for c in cats}
    lines = ['<div class="milestone-grid" markdown="1">', ""]
    first_section = True

    for section_name, ids in _SECTIONS:
        section_cats = [cats_by_id[i] for i in ids if i in cats_by_id]
        if not section_cats:
            continue

        if not first_section:
            lines.append("")
        first_section = False

        lines.append(f"#### {section_name}")
        lines.append("")
        lines.append("| Stat | Per Level | Max Levels | AP Cost | Max Total |")
        lines.append("|---|---|---:|---:|---|")

        for cat in section_cats:
            note = cat["note"].strip()
            note_m = re.match(r'^(.*?)\s*/\s*level\s*\(max\s*(.*?)\)\s*$', note, re.IGNORECASE)
            if note_m:
                per_level = note_m.group(1).strip()
                max_total = note_m.group(2).strip()
            else:
                per_level = note
                max_total = "—"

            lines.append(
                f"| {cat['label']} | {per_level} | {cat['cap']} "
                f"| {cat['apCost']} AP | {max_total} |"
            )

    lines.append("")
    lines.append("</div>")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/prestige_catalog.lua")
    if src is None:
        print("[prestige] skip: prestige_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")

    page = docs_dir / "progression" / "prestige.md"
    if not page.exists():
        print(f"[prestige] skip: target page {page} not found")
        return

    # Sanity check for categories
    has_ap_cost = bool(re.search(r'\bapCost\s*=\s*\d+', text))
    cats = _parse_categories(text)
    if has_ap_cost and not cats:
        raise RuntimeError("[prestige] apCost fields found but categories list parsed empty — check parser")

    mark_cost_base = _parse_scalar(text, "markCostBase") or 500
    mark_cost_cap  = _parse_scalar(text, "markCostCap")  or 3000
    ap_tiers       = _parse_ap_tiers(text)

    nms = _parse_nms(text)

    court0_bosses = _parse_trial_boss_labels(text)
    scaling_tiers = _parse_scaling_tiers(text, court0_bosses)

    # --- economy marker ---
    economy_content = _render_economy(mark_cost_base, mark_cost_cap, ap_tiers)
    wrote = write_between_markers(page, "prestige-economy", economy_content)
    if wrote:
        print("[prestige] economy: written into marker")
    else:
        print(f"[prestige] economy: marker 'prestige-economy' not found in {page.name}")

    # --- nightmare court marker ---
    court_content = _render_nightmare_court(nms)
    wrote = write_between_markers(page, "prestige-nightmare-court", court_content)
    if wrote:
        print("[prestige] nightmare court: written into marker")
    else:
        print(f"[prestige] nightmare court: marker 'prestige-nightmare-court' not found in {page.name}")

    # --- court scaling / rotation marker ---
    if scaling_tiers:
        scaling_content = _render_scaling(scaling_tiers)
        wrote = write_between_markers(page, "prestige-scaling", scaling_content)
        if wrote:
            print(f"[prestige] court scaling: {len(scaling_tiers)} tiers written into marker")
        else:
            print(f"[prestige] court scaling: marker 'prestige-scaling' not found in {page.name}")
    else:
        print("[prestige] court scaling: trialScaling.tiers parsed empty — marker left untouched")

    # --- AP table marker ---
    ap_content = _render_ap_table(cats)
    wrote = write_between_markers(page, "prestige-ap-table", ap_content)
    if wrote:
        print(f"[prestige] AP table: {len(cats)} categories written into marker")
    else:
        print(f"[prestige] AP table: marker 'prestige-ap-table' not found in {page.name}")
