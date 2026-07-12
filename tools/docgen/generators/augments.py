"""Generate Augment Moogle catalog tables inside docs/progression/augments.md.

Reads `modules/custom/lua/augment_catalog.lua` (catalyst-item-to-augment
mapping), `sql/item_basic.sql` (item-id-to-name lookup), and
`tools/augment_catalog_gaps.json` (items not in any obtainable source).

Drop sources come from `modules/custom/lua/catalyst_warp_table.lua` — the SAME
generated table the in-game !augwarp command uses, built by
tools/gen_catalyst_warp_table.py from augment_catalyst_mobs.lua (the mob the
drop hook actually rolls at DROP_RATE). Re-run that script BEFORE docgen when
the mob map changes. Hunting League trophies and Augmentation Dungeon drops
are layered in from their own runtime catalogs. No live-DB dependency.

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
import math
import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._bgwiki import urls_for_item


# The Augment Moogle's hub is NEVER hardcoded here: it is placed by an
# addOverride in Augment_Moogle.lua, and custom NPCs get consolidated between
# hubs over time (the 2026-07-06 move to Purgonorgo Isle). Emit
# npc_location_inject's token instead; it reads that SAME module (see
# _NPC_FILES["augment_moogle"]) and expands this to the NPC's live zone on every
# build, so the trade line can't drift the way a literal "Leafallia" would.
_MOOGLE_LOC = "{{npc:augment_moogle}}"


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
# Tier-fixed augments (Treasure Hunter, All songs): a single catalyst whose
# value is STEP × the player's Augment Tier -- the band cell shows step × tier,
# no ×5 stack. `true` (legacy) is read as step 1.
_TIERVALUE_RE = re.compile(r"\btierValue\s*=\s*(\d+|true)")
# Tier gate (0-4 = Augment Sage rank required; 0 = free / no gate).
_TIER_RE = re.compile(r"\btier\s*=\s*(\d+)")

# Matches a subcategory header comment, e.g.:
#   -- HP / Regen
#   -- Weapon delay (melee)
# Captures the title text after the `--`.
_HEADER_RE = re.compile(r"^\s*--\s*([A-Za-z][^\n]*?)\s*$", re.MULTILINE)

# Matches the box-drawing cat-group header, e.g.:
#   -- ── cat 1: STR ─────────────────────────────────────────────────
# These start with unicode box chars so _HEADER_RE doesn't match them.
# Captures the stat-family name after "cat N:".
_CAT_HEADER_RE = re.compile(
    r"^\s*--\s*─[^\n]*?cat\s*\d+:\s*([A-Za-z][^─\n]*?)\s*─*\s*$",
    re.MULTILINE,
)

# item_basic INSERT row — capture id and the 3rd field (short_name).
# Example:
#   INSERT INTO `item_basic` VALUES (8704,0,'bismuth_ingot','bismuth_ingot',...
_ITEM_RE = re.compile(
    r"INSERT INTO `item_basic` VALUES\s*\(\s*(\d+)\s*,\s*\d+\s*,\s*'([^']*)'",
)


# Category title -> the `!shop augments <token>` group that sells those catalysts.
# Keep in sync with augmentGroups in scripts/commands/shop.lua (cat 1-13) + the
# POINT_AUGMENTS group ('points') + the 'other' catch-all. Matched on the leading
# stat-family word of each category header. "Corsair (Phantom Roll)" returns None
# on purpose: its two custom catalysts are sold under their OWN stat group
# (Phantom Roll effect -> agi, Spikes Dmg -> int), so it gets a per-item note.
_SHOP_TOKENS = (
    ("strength", "str"), ("dexterity", "dex"), ("vitality", "vit"),
    ("agility", "agi"), ("intelligence", "int"), ("mind", "mnd"),
    ("charisma", "chr"), ("hp", "hp"), ("mp", "mp"), ("pet", "pet"),
    ("elemental", "resist"), ("skill", "skill"), ("weaponskill", "ws"),
    ("progression", "points"), ("other", "other"),
)


# RELAUNCH: all augments are available at every tier — power scales via roll
# bands. The catalog page is grouped by affinity category, not by tier.
# The old _TIER_INFO tier-grouped headings are removed.


def _shop_token(category: str):
    c = category.strip().lower()
    for kw, tok in _SHOP_TOKENS:
        if c.startswith(kw):
            return tok
    return None


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


def _parse_catalog(text: str) -> list[tuple[str, list[tuple[int, int, str, int, int, int, int, int]]]]:
    """Walk the catalog file linearly, tracking the most recent category
    header comment. Returns [(category, [(itemId, augId, label, base, mult, disp, maxBoost, tier), ...]), ...]
    in source order. Entries with no preceding header land in 'Other'.
    `base` defaults to 0, `mult`/`disp` to 1, `maxBoost` to 31 (uncapped), `tier` to 0 when omitted."""
    groups: list[tuple[str, list[tuple[int, int, str, int, int, int, int, int]]]] = []
    current: str = "Other"
    bucket: dict[str, list[tuple[int, int, str, int, int, int, int, int]]] = {}
    order: list[str] = []

    for line in text.splitlines():
        # Primary: box-drawing group header -- ── cat N: StatFamily ──
        # Parsed first so the stat-family name wins over sub-comments.
        g = _CAT_HEADER_RE.match(line)
        if g:
            current = g.group(1).strip()
            continue
        # Secondary: short sub-category comment (e.g. "-- Weapon delay (melee)")
        h = _HEADER_RE.match(line)
        if h:
            title = h.group(1).strip()
            # Skip file-header descriptive lines that aren't category markers:
            # * lines containing "sql/" (e.g. "Generated from sql/augments.sql")
            # * long file-level sentences (≥ 60 chars)
            # * lines starting with "augment_catalog" (the file-name comment)
            if ("sql/" not in title and len(title) <= 60
                    and not title.startswith("augment_catalog")):
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
        tt = _TIER_RE.search(line)
        tier = int(tt.group(1)) if tt else 0
        tv_m = _TIERVALUE_RE.search(line)
        tier_value = (1 if tv_m.group(1) == "true" else int(tv_m.group(1))) if tv_m else 0
        if current not in bucket:
            bucket[current] = []
            order.append(current)
        bucket[current].append((item_id, aug_id, label, base, mult, disp, max_boost, tier, tier_value))

    for cat in order:
        groups.append((cat, bucket[cat]))
    return groups


def _groups_from_json(json_path: Path) -> list[tuple[str, list[tuple[int, int, str, int, int, int, int, int]]]]:
    """Build the same (category, rows) structure `_parse_catalog` returns, but
    from the structured `augment_catalog.json` the catalog generator emits in
    lockstep with the .lua. This is the PREFERRED path: no regex, so a new
    catalog field can never silently drop an entry. Returns [] if the file is
    unreadable so generate() can fall back to the regex parse of the .lua."""
    try:
        data = json.loads(json_path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return []
    groups: list[tuple[str, list[tuple[int, int, str, int, int, int, int, int]]]] = []
    for g in data.get("groups", []):
        rows: list[tuple[int, int, str, int, int, int, int, int]] = []
        for e in g.get("entries", []):
            mb = e.get("maxBoost")
            rows.append((
                int(e["itemId"]), int(e["augId"]), str(e["label"]),
                int(e["base"]), int(e["mult"]), float(e["disp"]),
                int(mb) if mb is not None else 31,
                int(e.get("tier", 0)),
                int(e.get("tierValue", 0) or 0),
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


# ---------------------------------------------------------------------------
# Drop sources. SINGLE SOURCE OF TRUTH: catalyst_warp_table.lua — the same
# generated table the in-game !augwarp command require()s, itself generated
# from augment_catalyst_mobs.lua (the mob the drop hook actually rolls) by
# tools/gen_catalyst_warp_table.py. Reading the SAME file guarantees the
# website, !augwarp, and the on-kill drop all name the same mob at the same
# rate. Secondary sources (Hunting League trophies, Augmentation Dungeons)
# are parsed from THEIR runtime catalogs — no hand-synced tables here.
# ---------------------------------------------------------------------------

# Lua single-quoted string body, escape-aware ('Aern\'s Elemental').
_LQ = r"'((?:[^'\\]|\\.)*)'"


def _lua_unescape(s: str) -> str:
    return s.replace("\\'", "'").replace("\\\\", "\\")


# Each entry: list of display strings, primary first.
_DropList = list[str]


def _warp_table_drops(warp_lua: Path) -> dict[int, _DropList]:
    """catalyst_warp_table.lua -> {itemId: ['Mob (Zone) — N%', alt...]}."""
    out: dict[int, _DropList] = {}
    text = warp_lua.read_text(encoding="utf-8", errors="replace")
    for m in re.finditer(r"\[(\d+)\]\s*=\s*\{([^}]*)\}", text):
        iid, body = int(m.group(1)), m.group(2)

        def f(key: str) -> str | None:
            mm = re.search(rf"\b{key}\s*=\s*" + _LQ, body)
            return _lua_unescape(mm.group(1)) if mm else None

        rate_m = re.search(r"\brate\s*=\s*(\d+)", body)
        pct = int(rate_m.group(1)) / 10 if rate_m else 0
        mob, zone = f("mob"), f("zoneName")
        if not mob:
            continue
        entries = [f"{mob} ({zone}) — {pct:g}%"]
        alt_mob, alt_zone = f("altMob"), f("altZone")
        if alt_mob:
            entries.append(f"{alt_mob} ({alt_zone}) — {pct:g}%")
        out[iid] = entries
    return out


def _hl_trophy_drops(hl_lua: Path | None) -> dict[int, list[str]]:
    """hunting_league_catalog.lua -> {itemId: ['Label (Hunting League) — 100%, ×N per clear']}.
    Trophy drops are guaranteed on each catalog NM kill (HuntingLeague.lua)."""
    out: dict[int, list[str]] = {}
    if hl_lua is None or not hl_lua.exists():
        return out
    label = None
    for line in hl_lua.read_text(encoding="utf-8", errors="replace").splitlines():
        lm = re.search(r"\blabel\s*=\s*" + _LQ, line)
        if lm:
            label = _lua_unescape(lm.group(1))
        if "drops" in line and label:
            for dm in re.finditer(r"\{\s*id\s*=\s*(\d+)\s*,\s*qty\s*=\s*(\d+)\s*\}", line):
                out.setdefault(int(dm.group(1)), []).append(
                    f"{label} (Hunting League) — 100%, ×{dm.group(2)} per kill")
    return out


def _trash_rate(runtime_lua: Path | None, fallback: int = 10) -> int:
    """TRASH_RATE parsed from augment_dungeon_drops.lua (never mirrored here —
    a hardcoded copy is how this generator shipped a stale 30% on 2026-07-11)."""
    if runtime_lua is None or not runtime_lua.exists():
        return fallback
    m = re.search(r"^local\s+TRASH_RATE\s*=\s*(\d+)",
                  runtime_lua.read_text(encoding="utf-8", errors="replace"), re.M)
    return int(m.group(1)) if m else fallback


def _dungeon_drops(data_lua: Path | None, catalog_lua: Path | None,
                   trash_rate: int) -> dict[int, list[str]]:
    """augment_dungeon_drops_data.lua + dungeon_catalog.lua ->
    {itemId: ['<Dungeon label> dungeon — N% (trash) / boss pool']}."""
    out: dict[int, list[str]] = {}
    if data_lua is None or not data_lua.exists():
        return out
    labels: dict[str, str] = {}
    if catalog_lua is not None and catalog_lua.exists():
        text = catalog_lua.read_text(encoding="utf-8", errors="replace")
        starts = [(m.start(), m.group(1))
                  for m in re.finditer(r"^    (\w+) =\s*$", text, flags=re.M)]
        for i, (pos, key) in enumerate(starts):
            end = starts[i + 1][0] if i + 1 < len(starts) else len(text)
            lm = re.search(r"label\s*=\s*([\"'])(.+?)\1", text[pos:end])
            if lm:
                labels[key] = lm.group(2)

    dtext = data_lua.read_text(encoding="utf-8", errors="replace")
    blocks = re.split(r"^    (\w+) =$", dtext, flags=re.M)
    for key, body in zip(blocks[1::2], blocks[2::2]):
        dungeon = labels.get(key, key)
        trash_part, _, boss_part = body.partition("boss =")
        for m in re.finditer(r"\bid\s*=\s*(\d+)", trash_part):
            out.setdefault(int(m.group(1)), []).append(
                f"{dungeon} dungeon trash — {trash_rate}%")
        for m in re.finditer(r"\bid\s*=\s*(\d+)", boss_part):
            out.setdefault(int(m.group(1)), []).append(
                f"{dungeon} dungeon boss pool — guaranteed on clear")
    return out


def _parse_hook_rates(drops_lua: Path | None) -> tuple[int, int]:
    """(DROP_RATE, FALLBACK_RATE) percent from augment_catalyst_drops.lua.
    Parsed live so a balance retune shows up on the next docs build."""
    if drops_lua is None or not drops_lua.exists():
        return 60, 12
    text = drops_lua.read_text(encoding="utf-8", errors="replace")
    d = re.search(r"^local\s+DROP_RATE\s*=\s*(\d+)", text, re.M)
    f = re.search(r"^local\s+FALLBACK_RATE\s*=\s*(\d+)", text, re.M)
    return (int(d.group(1)) if d else 60, int(f.group(1)) if f else 12)


def _drop_cell(sources: _DropList) -> str:
    """Render a drop-source list as a table cell string.

    Single source → plain text.  Multiple → <details> dropdown, primary first.
    """
    if not sources:
        return "—"
    if len(sources) == 1:
        return sources[0]
    rest = "".join(f"<br>{s}" for s in sources[1:])
    return f"<details><summary>{sources[0]}</summary>{rest}</details>"


# The five Augment Tier roll bands (2026-06-30 tier revamp). MUST mirror
# TIER_SLICES in modules/custom/lua/Augment_Moogle.lua.
_TIER_BANDS = [(0, 5), (6, 11), (12, 17), (18, 24), (25, 31)]


def _band_cell(base: int, mult, disp, max_boost: int, band_idx: int, cat_tier: int,
               tier_value: int = 0) -> str:
    """One 'T{n} ×5' table cell: the FULL 5-CATALYST STACK's value range when
    rolled at that Augment Tier. Mirrors the Moogle math per slot --
    floor((base + scale(roll)) * mult / disp + 0.5) -- times 5 slots, where
    scale(roll) = floor(roll * maxBoost / 31 + 0.5) spreads the ceiling across
    all five tiers (Augment_Moogle.lua scaleRoll) so each tier is a distinct step.
    A band below the catalyst's own tier can never be rolled -> em-dash.
    tier_value rows (Treasure Hunter, All songs) are single-catalyst with
    value = tier_value × the Augment Tier: cell = step × tier, no ×5 stack."""
    if (band_idx + 1) < max(cat_tier, 1):
        return "—"
    if tier_value:
        return str(tier_value * (band_idx + 1))
    lo_roll, hi_roll = _TIER_BANDS[band_idx]
    m = mult if mult and mult > 1 else 1
    d = disp if disp and disp > 1 else 1

    def slot(roll: int) -> int:
        scaled = int(math.floor(roll * max_boost / 31 + 0.5))  # mirror Moogle scaleRoll
        return int(math.floor((base + scaled) * m / d + 0.5))

    lo, hi = slot(lo_roll) * 5, slot(hi_roll) * 5
    return str(lo) if lo == hi else f"{lo}–{hi}"


def _render(groups, item_names, gap_set: set[int], drops: dict[int, _DropList] | None = None,
            drop_rate: int = 60, fallback_rate: int = 12) -> str:
    lines: list[str] = []
    total = sum(len(rows) for _, rows in groups)
    gap_count = sum(1 for _, rs in groups for r in rs if r[0] in gap_set)
    lines.append(
        f"_{total} augments across {len(groups)} categories. "
        f"**Every augment is available at every Augment Tier** — your tier determines the "
        f"**power** of the roll, not which augments you can access. "
        f"Trade catalysts to the **Augment Moogle** in {_MOOGLE_LOC} (`!hub`). "
        f"Cost is **10,000 gil flat per trade** plus the catalyst itself. "
        f"Every line is **rolled** within your [Augment Tier's band](augment-sage.md) "
        f"— higher tiers roll strictly higher values. "
        f"The **T1–T5 columns** show the value range of a **full 5-catalyst stack** "
        f"rolled at that Augment Tier (divide by 5 for one catalyst). "
        f"The **Cap** column is the hard engine ceiling for that stat where one exists "
        f"(e.g. Haste caps at 25%, damage-taken floors at -50%), or **no cap** for additive stats._"
    )
    lines.append("")
    lines.append(
        f"!!! info \"How catalysts drop\"\n"
        f"    Each catalyst is assigned to **one specific monster** — the mob in the "
        f"**Drops from** column — which drops it **{drop_rate}%** of the time when you land "
        f"the killing blow. On top of that, **every other non-NM monster** has a "
        f"**{fallback_rate}%** chance to drop a **random** catalyst matched to its level "
        f"band, so any farming yields catalysts. **Notorious Monsters never drop "
        f"catalysts.** A drop announces itself on screen with the catalyst's item name "
        f"and augment. Use **`!augwarp <stat or item>`** in game to warp straight to the "
        f"assigned mob shown here. Catalysts also drop inside "
        f"[Augmentation Dungeons](../endgame/dungeons.md) and from "
        f"[Hunting League](index.md) trophies where listed."
    )
    lines.append("")
    if gap_count > 0:
        lines.append(
            f"!!! warning \"Some catalysts aren't farmable yet ({gap_count} of {total})\"\n"
            f"    Items marked with {_GAP_MARK} don't currently appear in any mob drop, "
            f"synth recipe, vendor inventory, fishing pool, gardening result, or synergy "
            f"recipe in the server's data. For now, ask a GM to spawn them."
        )
        lines.append("")

    for category, rows in groups:
        if not rows:
            continue
        lines.append(f"### {_escape_md(category)}")
        lines.append("")
        cat_gap = sum(1 for row in rows if row[0] in gap_set)
        if cat_gap > 0:
            lines.append(f"_({cat_gap}/{len(rows)} catalysts in this category need GM spawn)_")
            lines.append("")
        lines.append(
            "| Augment | Catalyst | Drops from "
            "| T1 ×5 | T2 ×5 | T3 ×5 | T4 ×5 | T5 ×5 | Cap |"
        )
        lines.append("|---|---|---|--:|--:|--:|--:|--:|:--:|")
        for item_id, aug_id, label, base, mult, disp, max_boost, tier, tier_value in rows:
            name = item_names.get(item_id, f"item_{item_id}")
            readable = _format_item_name(name)
            if name.startswith("item_") and name == f"item_{item_id}":
                display = _escape_md(readable)
            else:
                display = _item_link(readable, item_id)
            if item_id in gap_set:
                display = f"{display} {_GAP_MARK}"
            cap = _CAP_BY_AUG.get(aug_id, "no cap")
            if drops is not None:
                drop_src = _drop_cell(drops.get(item_id, []))
            else:
                drop_src = "—"
            band_cells = " | ".join(
                _band_cell(base, mult, disp, max_boost, band_idx, 0, tier_value)
                for band_idx in range(5)
            )
            lines.append(
                f"| {_escape_md(_truncate_label(label))} "
                f"| {display} "
                f"| {drop_src} "
                f"| {band_cells} "
                f"| {cap} |"
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
    gap_src = resolve_source(repo_root, "tools/augment_catalog_gaps.json", required=False)
    gap_set = _load_gap_set(gap_src)

    text = cat_src.read_text(encoding="utf-8", errors="replace")

    # PREFERRED: read the structured sidecar the catalog generator emits in
    # lockstep with the .lua (single source of truth -- no regex round-trip,
    # so a new field can't silently drop an entry). Fall back to scraping the
    # .lua text only if the JSON is missing (older checkout / hand-built file).
    json_src = resolve_source(repo_root, "modules/custom/lua/augment_catalog.json", required=False)
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

    # Drop sources: warp table (primary, same file !augwarp uses) + HL trophy
    # and Augmentation Dungeon catalogs (secondary, from their runtime data).
    warp_src = resolve_source(repo_root, "modules/custom/lua/catalyst_warp_table.lua", required=False)
    if warp_src is None:
        drops = None
        print("[augments] catalyst_warp_table.lua not found — 'Drops from' column will show '—'")
    else:
        drops = _warp_table_drops(warp_src)
        hl = _hl_trophy_drops(resolve_source(
            repo_root, "modules/custom/lua/hunting_league_catalog.lua", required=False))
        dg = _dungeon_drops(
            resolve_source(repo_root, "modules/custom/lua/augment_dungeon_drops_data.lua", required=False),
            resolve_source(repo_root, "modules/custom/lua/dungeon_catalog.lua", required=False),
            _trash_rate(resolve_source(
                repo_root, "modules/custom/lua/augment_dungeon_drops.lua", required=False)))
        for iid, extras in list(hl.items()) + list(dg.items()):
            drops.setdefault(iid, []).extend(extras)
        print(f"[augments] drop sources: {len(drops)} catalysts from warp table"
              f" (+{sum(len(v) for v in hl.values())} HL, +{sum(len(v) for v in dg.values())} dungeon)")
    drop_rate, fallback_rate = _parse_hook_rates(resolve_source(
        repo_root, "modules/custom/lua/augment_catalyst_drops.lua", required=False))

    page = docs_dir / "progression" / "augments.md"
    content = _render(groups, item_names, gap_set, drops, drop_rate, fallback_rate)
    wrote = write_between_markers(page, "augment-catalog", content)
    if wrote:
        total = sum(len(rs) for _, rs in groups)
        gap_count = sum(1 for _, rs in groups for r in rs if r[0] in gap_set)
        print(f"[augments] augment-catalog: {total} entries across {len(groups)} categories written into markers ({gap_count} flagged as unobtainable) [source: {source}]")
    else:
        print(f"[augments] augment-catalog: skipped (markers not found in {page.name})")
