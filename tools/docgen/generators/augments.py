"""Generate Augment Moogle catalog tables inside docs/progression/augments.md.

Reads `modules/custom/lua/augment_catalog.lua` (catalyst-item-to-augment
mapping), `sql/item_basic.sql` (item-id-to-name lookup), and
`tools/augment_catalog_gaps.json` (items not in any obtainable source).

Emits one table per stat-family category between DOCGEN markers, with a
warning marker on each row whose catalyst doesn't appear in any in-game
obtainable source (mob drops, synth, shops, fishing, gardening, synergy).

Marker IDs:
  - "augment-catalog"  — the full thematic table, grouped by category

The catalog is normally gitignored, so this generator runs against
`$LEGENDARY_LIVE_ROOT`. CI without that env var skips cleanly.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._bgwiki import urls_for_item


# Marker used in the markdown to flag unobtainable items.
_GAP_MARK = "⚠"


# Matches a single catalog entry line. We only care about `augId` and `label`;
# any number of other fields (`base`, `cat`, future additions) are tolerated
# between them. Historical formats this has matched:
#   [8704] = { augId = 1, label = 'HP+1' },
#   [8704] = { augId = 1, base = 1, label = 'HP+1' },
#   [858]  = { augId = 25, base = 1, cat = 1, label = 'Attack+1' },  <- current
#
# When a new field is added to the catalog (e.g. for Augment Sage), the table
# previously went silently empty because the regex required label to come
# immediately after the optional base. The `(?:\w+\s*=\s*[^,}]+,\s*)*` arm now
# absorbs zero-or-more intermediate `field = value,` pairs BEFORE label, and the
# trailing `(?:\s*,\s*\w+\s*=\s*[^,}]+)*` arm absorbs any fields AFTER label too
# (e.g. `maxBoost`, added 2026-06-19 — it silently dropped 'All songs' from the
# page until this arm was added). Together they let the parser survive a field
# appearing in any position. The `generate()` function also asserts non-zero
# matches to fail loudly if THIS regex ever stops matching too.
_ENTRY_RE = re.compile(
    r"\[\s*(\d+)\s*\]\s*=\s*\{\s*augId\s*=\s*(\d+)\s*,\s*"
    r"(?:\w+\s*=\s*[^,}]+,\s*)*"
    r"label\s*=\s*'((?:[^'\\]|\\.)*)'"
    r"(?:\s*,\s*\w+\s*=\s*[^,}]+)*"
    r"\s*\}",
)

# Pulled separately from the body so the parser keeps working if `base`
# moves around inside the entry. Used to scale per-catalyst stat values
# in the rendered table (×1 / ×2 / ×3 / ×4 columns).
_BASE_RE = re.compile(r"\bbase\s*=\s*(-?\d+)")
# Effective engine multiplier — added when the catalog moved to base+mult so the
# Moogle, !augstats, and these docs all show the same (base+boost)*mult ceiling.
_MULT_RE = re.compile(r"\bmult\s*=\s*(-?\d+)")
# Display divisor — mods stored at xN are divided by this so the table shows the
# meaningful number (matches the Moogle / !augstats). Defaults to 1.
_DISP_RE = re.compile(r"\bdisp\s*=\s*(-?\d+(?:\.\d+)?)")
# Per-entry boost ceiling (0-31). When set, the Max column uses this instead of
# 31 so nerfed augments (e.g. All songs maxBoost=1) show their true max.
_MAXBOOST_RE = re.compile(r"\bmaxBoost\s*=\s*(\d+)")

# Matches a category header comment, e.g.:
#   -- HP / Regen
# Captures the title text after the `--`.
_HEADER_RE = re.compile(r"^\s*--\s*([A-Za-z][^\n]*?)\s*$", re.MULTILINE)

# item_basic INSERT row — capture id and the 3rd field (short_name).
# Example:
#   INSERT INTO `item_basic` VALUES (8704,0,'bismuth_ingot','bismuth_ingot',...
_ITEM_RE = re.compile(
    r"INSERT INTO `item_basic` VALUES\s*\(\s*(\d+)\s*,\s*\d+\s*,\s*'([^']*)'",
)


def _unescape(s: str) -> str:
    return s.replace("\\'", "'").replace("\\\\", "\\")


def _load_item_names(item_sql: Path) -> dict[int, str]:
    names: dict[int, str] = {}
    with item_sql.open(encoding="utf-8", errors="replace") as f:
        for line in f:
            m = _ITEM_RE.search(line)
            if m:
                names[int(m.group(1))] = m.group(2)
    return names


def _parse_catalog(text: str) -> list[tuple[str, list[tuple[int, int, str, int, int, int, int]]]]:
    """Walk the catalog file linearly, tracking the most recent category
    header comment. Returns [(category, [(itemId, augId, label, base, mult, disp, maxBoost), ...]), ...]
    in source order. Entries with no preceding header land in 'Other'.
    `base` defaults to 0, `mult`/`disp` to 1, `maxBoost` to 31 (uncapped) when omitted."""
    groups: list[tuple[str, list[tuple[int, int, str, int, int, int, int]]]] = []
    current: str = "Other"
    bucket: dict[str, list[tuple[int, int, str, int, int, int, int]]] = {}
    order: list[str] = []

    for line in text.splitlines():
        h = _HEADER_RE.match(line)
        if h:
            title = h.group(1).strip()
            # Skip file-header descriptive comments (not category markers).
            # Real category headers are short — stat family names. The file
            # header lines are long sentences. Pick a length cutoff.
            if len(title) <= 60 and not title.startswith("augment_catalog"):
                current = title
            continue
        m = _ENTRY_RE.search(line)
        if not m:
            continue
        item_id = int(m.group(1))
        aug_id = int(m.group(2))
        label = _unescape(m.group(3))
        # `base` is captured by a separate regex on the same line — keeps
        # the main _ENTRY_RE forgiving of field-ordering changes.
        b = _BASE_RE.search(line)
        base = int(b.group(1)) if b else 0
        mm = _MULT_RE.search(line)
        mult = int(mm.group(1)) if mm else 1
        dd = _DISP_RE.search(line)
        disp = float(dd.group(1)) if dd else 1
        mb = _MAXBOOST_RE.search(line)
        max_boost = int(mb.group(1)) if mb else 31
        if current not in bucket:
            bucket[current] = []
            order.append(current)
        bucket[current].append((item_id, aug_id, label, base, mult, disp, max_boost))

    for cat in order:
        groups.append((cat, bucket[cat]))
    return groups


def _groups_from_json(json_path: Path) -> list[tuple[str, list[tuple[int, int, str, int, int, int, int]]]]:
    """Build the same (category, rows) structure `_parse_catalog` returns, but
    from the structured `augment_catalog.json` the catalog generator emits in
    lockstep with the .lua. This is the PREFERRED path: no regex, so a new
    catalog field can never silently drop an entry. Returns [] if the file is
    unreadable so generate() can fall back to the regex parse of the .lua."""
    try:
        data = json.loads(json_path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return []
    groups: list[tuple[str, list[tuple[int, int, str, int, int, int, int]]]] = []
    for g in data.get("groups", []):
        rows: list[tuple[int, int, str, int, int, int, int]] = []
        for e in g.get("entries", []):
            mb = e.get("maxBoost")
            rows.append((
                int(e["itemId"]), int(e["augId"]), str(e["label"]),
                int(e["base"]), int(e["mult"]), float(e["disp"]),
                int(mb) if mb is not None else 31,
            ))
        groups.append((str(g.get("category", "Other")), rows))
    return groups


def _format_item_name(name: str) -> str:
    """Convert snake_case to Title Case for display.

    item_basic.sql stores names as lowercase_with_underscores (e.g.
    "wolf_hide"). Both BG-Wiki display titles and BG-Wiki image
    filenames use Title Case ("Wolf_Hide_description.png"). Since the
    MD5 hash that determines an image's storage path is case-sensitive,
    we must title-case before slugging or every tooltip 404s silently.
    The search-redirect link works either way (MediaWiki search is
    case-insensitive), but matching case keeps the popup image alive.
    """
    return name.replace("_", " ").title()


def _escape_md(s: str) -> str:
    return s.replace("|", "\\|").replace("\n", " ")


def _item_link(name: str, item_id: int | None = None) -> str:
    """Render a catalyst name as an FFXIAH link with a hover-image tooltip.

    Wraps the display name in an <a class="item-link" data-img="..."> so the
    site-wide item-tooltip.js picks it up. urls_for_item resolves the link +
    icon from the item id (passed here from the augment row); a missing id
    falls back to a BG-Wiki search link with no hover image.
    """
    page_url, image_url = urls_for_item(name, None, item_id)
    img_attr = f' data-img="{image_url}"' if image_url else ""
    return (
        f'<a class="item-link" href="{page_url}"{img_attr} '
        f'target="_blank" rel="noopener">{_escape_md(name)}</a>'
    )


# Matches every signed integer in a label (e.g. "+1", "-33", "+1%").
# Used by `_scale_label` to multiply each numeric stat value by the
# catalyst count so the table can show stacking results. Pattern is
# anchored to a `+` or `-` followed by digits so we don't accidentally
# scale arbitrary numbers elsewhere in the label text.
_SIGNED_NUM_RE = re.compile(r"([+\-])(\d+)")


def _scale_label(label: str, multiplier: int) -> str:
    """Return `label` with every `+N` or `-N` token multiplied by `multiplier`.

    Works for both simple labels ("HP+97" -> "HP+388" at x4) and
    compound labels with multiple stats ("Pet: STR+1 DEX+1 VIT+1" ->
    "Pet: STR+4 DEX+4 VIT+4" at x4). The sign character is preserved
    so "Enmity-1" -> "Enmity-4", "Phys.dmg.taken -1%" -> "-4%", etc.

    For multiplier=1 the label is returned unchanged.
    """
    if multiplier == 1:
        return label

    def _scale_one(m: re.Match) -> str:
        sign = m.group(1)
        value = int(m.group(2)) * multiplier
        return f"{sign}{value}"

    return _SIGNED_NUM_RE.sub(_scale_one, label)


def _truncate_label(label: str, max_len: int = 80) -> str:
    """Catalog labels are SQL comments verbatim; some are very long.
    Truncate at the first parenthesis or period after the stat name."""
    if len(label) <= max_len:
        return label
    # Cut at first ' (' or '. ' if present
    for cut in (" (", ". "):
        idx = label.find(cut)
        if 0 < idx <= max_len:
            return label[:idx].rstrip()
    return label[:max_len].rstrip() + "..."


def _load_gap_set(gap_json_path: Path | None) -> set[int]:
    """Load the set of itemIds flagged as not-in-obtainable-union.
    Returns an empty set if the JSON isn't available — generator still
    emits the table, just without gap markers."""
    if gap_json_path is None or not gap_json_path.exists():
        return set()
    try:
        data = json.loads(gap_json_path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return set()
    return {int(entry["itemId"]) for entry in data.get("items", []) if "itemId" in entry}


# In-engine caps for the "Cap" column, keyed by augId. Mirrors the Augment
# Moogle's CAPPED_MOD_AUGS so the docs match what the engine actually enforces;
# any augId not listed shows "no cap" (additive stats like Attack / HP / Acc).
_CAP_BY_AUG = {
    49: "+25%", 50: "+25%",                 # Haste (gear) cap +25%
    54: "-50%", 1155: "-50%",               # Phys. dmg. taken (floor)
    71: "-50%",                             # Dmg. taken (floor)
    55: "-50%", 1156: "-50%",               # Magic dmg. taken (floor)
    56: "-50%",                             # Breath dmg. taken (floor)
    334: "+40%",                            # Magic Burst Bonus
    328: "+100%",                           # Crit. hit damage
    41: "100%/swing",                       # Crit hit rate
    132: "100%/swing", 143: "100%/swing",   # Double Attack
    144: "100%/swing",                      # Triple Attack
    354: "100%/swing",                      # Quad. Attack
}


def _render(groups, item_names, gap_set: set[int]) -> str:
    lines: list[str] = []
    total = sum(len(rows) for _, rows in groups)
    gap_count = sum(1 for _, rs in groups for r in rs if r[0] in gap_set)
    lines.append(
        f"_{total} catalyst items across {len(groups)} categories. "
        f"Trade the catalyst to the Augment Moogle to apply the matching augment. "
        f"Cost is **10,000 gil flat per trade** plus the catalyst items themselves._"
    )
    lines.append("")
    lines.append(
        "Each augment **scales with [Augment Sage](augment-sage.md) progress** and "
        "with how many catalysts you trade (**×N** = that many, 1–5; an item has 5 "
        "augment slots). **Fresh ×N** is a brand-new augment with **no Sage "
        "progress**; **Max ×N** is the ceiling at **rank-5 mastery + full affinity + "
        "a crit**. Your live value starts near Fresh and climbs toward Max as you "
        "rank Augment Sage up. Percentage augments (damage-taken, haste, etc.) "
        "show the raw value; the **Cap** column is the hard in-game ceiling for "
        "that stat (e.g. Phys. dmg. taken floors at -50%), or **no cap** for "
        "additive stats like Attack/HP — values above the Cap can't be reached no "
        "matter how many catalysts you stack."
    )
    lines.append("")
    if gap_count > 0:
        lines.append(
            f"!!! warning \"Some catalysts aren't farmable yet ({gap_count} of {total})\"\n"
            f"    Items marked with {_GAP_MARK} don't currently appear in any mob drop, "
            f"synth recipe, vendor inventory, fishing pool, gardening result, or synergy "
            f"recipe in the server's data. For now, ask a GM to spawn them. "
            f"This list will shrink as drops are filled in upstream."
        )
        lines.append("")

    for category, rows in groups:
        if not rows:
            continue
        cat_gap = sum(1 for r in rows if r[0] in gap_set)
        if cat_gap > 0:
            lines.append(f"### {category}  _({cat_gap}/{len(rows)} need GM spawn)_")
        else:
            lines.append(f"### {category}")
        lines.append("")
        lines.append("| Catalyst | Item ID | Augment | Fresh ×1 | ×2 | ×3 | ×4 | ×5 | Max ×1 | ×2 | ×3 | ×4 | ×5 | Cap |")
        lines.append("|---|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|:--:|")
        for item_id, aug_id, label, base, mult, disp, max_boost in rows:
            name = item_names.get(item_id, f"item_{item_id}")
            readable = _format_item_name(name)
            # Fall back to plain text for items without a name lookup —
            # the "item_<id>" placeholder isn't a real BG-Wiki page.
            if name.startswith("item_") and name == f"item_{item_id}":
                display = _escape_md(readable)
            else:
                display = _item_link(readable, item_id)
            if item_id in gap_set:
                display = f"{display} {_GAP_MARK}"
            # Power at each trade size for 1–5 catalysts (= 1–5 augment slots).
            # Fresh = no Sage (boost 0); Max = full Sage (boost max_boost, where
            # 31 = fully uncapped and lower values reflect a catalog maxBoost cap).
            # Per slot = (base + boost) * mult / display-scale; N catalysts sum N.
            # int(x + 0.5) = round-half-up, matching the Lua math.floor(x+0.5).
            m = mult if mult > 1 else 1
            d = disp if disp > 1 else 1
            fresh = [int(n * base * m / d + 0.5) for n in (1, 2, 3, 4, 5)]
            maxv  = [int(n * (base + max_boost) * m / d + 0.5) for n in (1, 2, 3, 4, 5)]
            cells = " | ".join(str(v) for v in (fresh + maxv))
            cap = _CAP_BY_AUG.get(aug_id, "no cap")
            lines.append(
                f"| {display} "
                f"| {item_id} "
                f"| {_escape_md(_truncate_label(label))} "
                f"| {cells} | {cap} |"
            )
        lines.append("")

    return "\n".join(lines).rstrip()


def generate(repo_root: Path, docs_dir: Path) -> None:
    cat_src = resolve_source(repo_root, "modules/custom/lua/augment_catalog.lua")
    if cat_src is None:
        print("[augments] skip: augment_catalog.lua not found")
        return

    item_src = resolve_source(repo_root, "sql/item_basic.sql")
    if item_src is None:
        print("[augments] skip: sql/item_basic.sql not found")
        return

    # Gap list is optional — generator works without it (just no warning marks).
    gap_src = resolve_source(repo_root, "tools/augment_catalog_gaps.json")
    gap_set = _load_gap_set(gap_src)

    text = cat_src.read_text(encoding="utf-8", errors="replace")

    # PREFERRED: read the structured sidecar the catalog generator emits in
    # lockstep with the .lua (single source of truth -- no regex round-trip,
    # so a new field can't silently drop an entry). Fall back to scraping the
    # .lua text only if the JSON is missing (older checkout / hand-built file).
    json_src = resolve_source(repo_root, "modules/custom/lua/augment_catalog.json")
    if json_src is not None and (groups := _groups_from_json(json_src)):
        source = f"json ({json_src.name})"
    else:
        groups = _parse_catalog(text)
        source = "regex(.lua)"
    total = sum(len(rs) for _, rs in groups)

    # Strict reconciliation: the number of entries we ended up with MUST equal
    # the number of entry-shaped lines in the runtime .lua. This is the guard
    # that catches BOTH failure modes that silently wiped/holed this table
    # before:
    #   * regex path drops one entry (a field after `label` -> 'All songs'
    #     vanished 2026-06-19) -> total < entry_lines
    #   * JSON path is stale vs the .lua (regen didn't run) -> mismatch too
    # On mismatch we RAISE; generate.py catches it, prints the traceback, and
    # leaves the existing markdown intact so the live table stays correct until
    # a human reconciles the source. (Was previously `total == 0`, which only
    # fired when EVERY entry failed -- a single drop sailed straight through.)
    entry_lines = sum(
        1 for ln in text.splitlines() if re.match(r"\s*\[\s*\d+\s*\]\s*=", ln)
    )
    if entry_lines > 0 and total != entry_lines:
        raise RuntimeError(
            f"augment catalog out of sync: parsed {total} entries via {source} "
            f"but augment_catalog.lua has {entry_lines} entry-shaped lines. "
            f"If using the .json, it's stale -- re-run tools/gen_augment_catalog.py. "
            f"If using regex, the .lua grew a field _ENTRY_RE can't handle -- fix "
            f"the pattern in {Path(__file__).name}. Refusing to publish a catalog "
            f"table that's missing {abs(entry_lines - total)} augment(s)."
        )

    item_names = _load_item_names(item_src)

    page = docs_dir / "progression" / "augments.md"
    content = _render(groups, item_names, gap_set)
    wrote = write_between_markers(page, "augment-catalog", content)
    if wrote:
        total = sum(len(rs) for _, rs in groups)
        gap_count = sum(1 for _, rs in groups for r in rs if r[0] in gap_set)
        print(f"[augments] augment-catalog: {total} entries across {len(groups)} categories written into markers ({gap_count} flagged as unobtainable) [source: {source}]")
    else:
        print(f"[augments] augment-catalog: skipped (markers not found in {page.name})")
