"""Generate the Augment Sage progression page from the live catalogs.

Reads three sources:
  - `modules/custom/lua/augment_sage_catalog.lua`     (5-rank chain + tables)
  - `modules/custom/lua/augment_affinity_catalog.lua` (13 NM affinities)
  - `modules/custom/lua/augment_catalog.lua`          (catalyst pool per cat,
                                                       used for size context)

Writes into `docs/progression/augment-sage.md` between DOCGEN markers:
  - "sage-location"   — zone + coordinates
  - "sage-formula"    — the multiplier formula at trade time
  - "sage-ranks"      — 5-rank promotion table (mult / crit / requirements)
  - "sage-affinities" — 13-row NM/category/trophy table

The catalogs are gitignored (live-only), so this generator skips cleanly on
CI without `$LEGENDARY_LIVE_ROOT`.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers


_QUOTED = r"(?:'((?:[^'\\]|\\.)*)'|\"([^\"]*)\")"


def _quoted_value(m: re.Match) -> str:
    raw = m.group(1) if m.group(1) is not None else m.group(2)
    return raw.replace("\\'", "'").replace('\\"', '"').replace("\\\\", "\\")


# =========================================================================
# Sage catalog parsers
# =========================================================================

def _parse_vendor_pos(text: str) -> dict | None:
    m = re.search(
        r"catalog\.vendorPos\s*=\s*\{\s*"
        r"x\s*=\s*(-?[\d.]+)\s*,\s*"
        r"y\s*=\s*(-?[\d.]+)\s*,\s*"
        r"z\s*=\s*(-?[\d.]+)\s*,\s*"
        r"rot\s*=\s*(-?\d+)",
        text,
    )
    if not m:
        return None
    return {
        "x":   float(m.group(1)),
        "y":   float(m.group(2)),
        "z":   float(m.group(3)),
        "rot": int(m.group(4)),
    }


def _parse_zone_id(text: str) -> str | None:
    # catalog.zoneId = xi.zone.GM_HOME
    m = re.search(r"catalog\.zoneId\s*=\s*xi\.zone\.([A-Z0-9_]+)", text)
    return m.group(1) if m else None


def _parse_mult_table(text: str, key: str) -> list[float]:
    """catalog.masteryMult = { 1.00, 1.20, ... }"""
    m = re.search(
        rf"catalog\.{re.escape(key)}\s*=\s*\{{\s*([^}}]+)\}}",
        text,
    )
    if not m:
        return []
    return [float(v.strip()) for v in m.group(1).split(",") if v.strip()]


_RANK_BLOCK_RE = re.compile(
    r"\{\s*\n?\s*rank\s*=\s*(\d+)\s*,\s*\n?"
    r"\s*title\s*=\s*'([^']+)'\s*,\s*\n?"
    r"\s*augCount\s*=\s*(\d+)\s*,\s*\n?"
    r"\s*seal\s*=\s*\{\s*tier\s*=\s*'([^']+)'\s*,\s*qty\s*=\s*(\d+)\s*\}\s*,\s*\n?"
    r"\s*trophy\s*=\s*\{\s*id\s*=\s*(\d+)\s*,\s*qty\s*=\s*(\d+)\s*,\s*name\s*=\s*\"?([^'\"]+)\"?\s*\}\s*,\s*\n?"
    r"\s*nm\s*=\s*'([^']+)'",
    re.DOTALL,
)


def _parse_ranks(text: str) -> list[dict]:
    """Parse the 5-row catalog.ranks block. Falls back to a tolerant
    line-by-line search if the strict regex misses (e.g. fields reordered)."""
    rows: list[dict] = []
    # Tolerant approach: find each `{ rank = N, ... }` block by balanced braces
    # then pluck named fields.
    anchor = re.search(r"catalog\.ranks\s*=\s*\{", text)
    if not anchor:
        return rows
    i = anchor.end() - 1  # at the opening `{`
    depth = 0
    n = len(text)
    # Walk over the array; we want each immediate-child block.
    while i < n:
        c = text[i]
        if c == "{":
            if depth == 0:
                # outer array open; descend
                depth = 1
                i += 1
                continue
            # Find the matching close brace from here.
            start = i
            d = 1
            j = i + 1
            while j < n and d > 0:
                if text[j] == "{":
                    d += 1
                elif text[j] == "}":
                    d -= 1
                j += 1
            block = text[start + 1: j - 1]
            row = _row_from_block(block)
            if row:
                rows.append(row)
            i = j
            continue
        if c == "}" and depth == 1:
            break
        i += 1

    # Sanity guard: if catalog.ranks block was found (anchor matched) but we
    # extracted zero rank rows, the per-block field extractor failed on every
    # entry. Could be a renamed field (e.g. rank → tier) or restructured seal
    # /trophy sub-blocks. Raise rather than wiping the published rank table.
    inner_rank_signals = len(re.findall(r"\brank\s*=\s*\d+", text[anchor.end():]))
    if inner_rank_signals > 0 and not rows:
        raise RuntimeError(
            f"catalog.ranks block has {inner_rank_signals} `rank = N` "
            f"signals but _row_from_block extracted zero rows. A required "
            f"field (rank/title/augCount/seal/trophy/nm) was probably "
            f"renamed or restructured. Update _row_from_block in "
            f"{Path(__file__).name}. Refusing to overwrite the rank table."
        )

    rows.sort(key=lambda r: r["rank"])
    return rows


def _row_from_block(block: str) -> dict | None:
    def find(field, pattern=r"=\s*'([^']+)'"):
        m = re.search(rf"\b{re.escape(field)}\b\s*{pattern}", block)
        return m.group(1) if m else None

    rank = find("rank", r"=\s*(\d+)")
    if not rank:
        return None
    title    = find("title")
    augCount = find("augCount", r"=\s*(\d+)")
    nm       = find("nm")
    seal_m   = re.search(
        r"seal\s*=\s*\{\s*tier\s*=\s*'([^']+)'\s*,\s*qty\s*=\s*(\d+)",
        block,
    )
    # Quote-matched: handle "Handful of Nidhogg's Scales" without stopping
    # on the inner apostrophe. \2 is the backreference to the opening quote.
    trophy_m = re.search(
        r"trophy\s*=\s*\{[^}]*?name\s*=\s*(['\"])(.+?)\1",
        block,
    )
    trophy_qty_m = re.search(
        r"trophy\s*=\s*\{\s*id\s*=\s*\d+\s*,\s*qty\s*=\s*(\d+)",
        block,
    )

    return {
        "rank":       int(rank),
        "title":      title or f"Rank {rank}",
        "augCount":   int(augCount) if augCount else 0,
        "seal_tier":  seal_m.group(1) if seal_m else "?",
        "seal_qty":   int(seal_m.group(2)) if seal_m else 0,
        # group(2) is the captured name (group(1) is the quote character).
        "trophy":     trophy_m.group(2) if trophy_m else "?",
        "trophy_qty": int(trophy_qty_m.group(1)) if trophy_qty_m else 1,
        "nm":         nm or "?",
    }


_SEAL_NAME_RE = re.compile(
    r"(\w+)\s*=\s*\{\s*id\s*=\s*\d+\s*,\s*name\s*=\s*'([^']+)'\s*\}",
)


def _parse_seals(text: str) -> dict[str, str]:
    """catalog.seals = { bronze = { ... name = '...' }, ... }"""
    anchor = re.search(r"catalog\.seals\s*=\s*\{", text)
    if not anchor:
        return {}
    rest = text[anchor.end():]
    end = rest.find("}\n")
    if end == -1:
        return {}
    block = rest[:end + 1]
    return {tier: name for tier, name in _SEAL_NAME_RE.findall(block)}


# =========================================================================
# Affinity catalog parser
# =========================================================================

# Named groups so the backreference for the matching quote is obvious and
# we don't have to count parens. Group `q` captures the opening quote (' or
# "), group `name` captures the trophy name (non-greedy until the same
# quote closes via `(?P=q)`). That way "Handful of Nidhogg's Scales" reads
# correctly even though its inner apostrophe would have broken `[^"]+`.
#
# Field-ordering note: cat → bit → label → nm → trophy is the strict order
# the regex requires. If a new field is added to affinity entries, this regex
# stops matching ALL of them and the table goes silently empty (same bug
# that hit augments.py when `cat = N` was added there). _parse_affinities()
# raises loudly if 0 entries match while the source clearly has affinity
# blocks — so the failure is visible and the published page stays alive.
_AFFINITY_BLOCK_RE = re.compile(
    r"\{\s*\n?\s*cat\s*=\s*(?P<cat>\d+)\s*,\s*bit\s*=\s*(?P<bit>\d+)\s*,\s*\n?"
    r"\s*label\s*=\s*'(?P<label>[^']+)'\s*,\s*\n?"
    r"\s*nm\s*=\s*'(?P<nm>[^']+)'\s*,\s*\n?"
    r"\s*trophy\s*=\s*\{\s*id\s*=\s*(?P<trophyId>\d+)\s*,\s*qty\s*=\s*(?P<qty>\d+)\s*,\s*"
    r"name\s*=\s*(?P<q>['\"])(?P<name>.+?)(?P=q)",
    re.DOTALL,
)


def _parse_affinities(text: str) -> list[dict]:
    out: list[dict] = []
    for m in _AFFINITY_BLOCK_RE.finditer(text):
        out.append({
            "cat":      int(m.group("cat")),
            "bit":      int(m.group("bit")),
            "label":    m.group("label"),
            "nm":       m.group("nm"),
            "trophyId": int(m.group("trophyId")),
            "trophy":   m.group("name"),
        })

    # Sanity guard: if the source clearly contains affinity blocks but the
    # strict regex matched zero, raise so the harness skips the write and
    # the published affinities table stays alive.
    #
    # The signal needs to be order-agnostic -- if a field gets reordered,
    # a positional signal like `cat=N, bit=N` would ALSO fail and we'd
    # silently produce 0 entries with no guard fire. Use `trophy = { id = N`
    # as the signal instead: it's the most distinctive substructure of an
    # affinity entry, has no equivalent elsewhere in the file, and survives
    # any reordering of the top-level entry fields.
    block_signals = len(re.findall(r"\btrophy\s*=\s*\{\s*id\s*=\s*\d+", text))
    if block_signals > 0 and not out:
        raise RuntimeError(
            f"augment_affinity_catalog.lua has {block_signals} affinity-block "
            f"signals (trophy={{ id=N ...}} substructures) but "
            f"_AFFINITY_BLOCK_RE matched zero entries. A field probably got "
            f"added, removed, or reordered. Update the regex in "
            f"{Path(__file__).name}. Refusing to overwrite the affinities "
            f"table with an empty list."
        )

    out.sort(key=lambda r: r["cat"])
    return out


def _parse_affinity_mult(text: str) -> float:
    m = re.search(r"catalog\.affinityMult\s*=\s*([\d.]+)", text)
    return float(m.group(1)) if m else 1.5


def _parse_affinity_gate(text: str) -> tuple[int, int]:
    """Registration gate: (rankReq, markCost) from the affinity catalog."""
    r = re.search(r"catalog\.affinityRankReq\s*=\s*(\d+)", text)
    c = re.search(r"catalog\.affinityMarkCost\s*=\s*(\d+)", text)
    return (int(r.group(1)) if r else 3, int(c.group(1)) if c else 1000)


# =========================================================================
# Catalog category counts (for "X catalysts available in this category")
# =========================================================================

def _parse_cat_counts(text: str) -> dict[int, int]:
    """Count entries per `cat = N`. Lightweight scan."""
    counts: dict[int, int] = {}
    for m in re.finditer(r"\bcat\s*=\s*(\d+)\b", text):
        c = int(m.group(1))
        counts[c] = counts.get(c, 0) + 1
    return counts


# =========================================================================
# Renderers
# =========================================================================

_TIER_BADGE = {"bronze": "Bronze", "silver": "Silver", "gold": "Gold"}


def _pretty_zone(zone: str) -> str:
    """Convert xi.zone-style identifiers ('GM_HOME', 'REISENJIMA_HENGE') into
    human zone names. Preserves short all-caps tokens ('GM', 'NPC') as
    abbreviations instead of forcing Title-case ('Gm', 'Npc')."""
    out = []
    for word in zone.replace("_", " ").split():
        if word.isupper() and len(word) <= 3:
            out.append(word)
        else:
            out.append(word.title())
    return " ".join(out)


def _render_location(zone: str | None, pos: dict | None) -> str:
    if not zone or not pos:
        return "_Location data not parsed from the catalog._"
    pretty_zone = _pretty_zone(zone)
    return (
        f"**Zone:** {pretty_zone}  \n"
        f"**Coordinates:** x = {pos['x']:.2f}, y = {pos['y']:.2f}, z = {pos['z']:.2f}  \n"
        f"**Same row as:** the Augment Moogle (talk to either to start a trade or pursue a rank)."
    )


def _render_formula(
    mastery: list[float],
    crit:    list[float],
    affinity_mult: float,
) -> str:
    if not mastery or not crit:
        return "_Formula tables not parsed from the catalog._"
    max_total = mastery[-1] * affinity_mult * 2.0
    lines = [
        "Every successful augment runs through this math at trade time. The three",
        "Sage ingredients combine into an **achievement boost of 0–31** that is",
        "written onto every augment slot in the trade:",
        "",
        "```",
        "mastery   = masteryMult[Augment_Mastery + 1]      -- from Sage rank",
        f"affinity  = hasAffinity(category) ? {affinity_mult:.1f} : 1.0     -- from registered affinities",
        "crit_pct  = critChance[Augment_Mastery + 1]       -- chance per trade",
        "crit      = random() < crit_pct ? 2.0 : 1.0",
        "",
        "totalMult = mastery * affinity * crit",
        f"progress  = (totalMult - 1) / ({max_total:.1f} - 1)        -- 0.0 .. 1.0",
        "boost     = round(progress * 31)                  -- written per slot",
        "",
        "per_slot  = (base + boost) * multiplier           -- the engine formula",
        "```",
        "",
        "**Floor** (rank 0, no affinity, no crit): boost = 0, so each slot lands at",
        "`base × multiplier` — the augment's minimum value.",
        "",
        (
            f"**Cap** (rank {len(mastery) - 1}, affinity held, crit lands): "
            f"`{mastery[-1]} × {affinity_mult} × 2.0 = {max_total:.1f}` maxes the boost at **31**, "
            "so each slot lands at `(base + 31) × multiplier` — the augment's ceiling. "
            "The [catalog table](augments.md#catalyst--augment-catalog) lists every "
            "augment's Fresh (floor) and Max (cap) values per trade size."
        ),
    ]
    return "\n".join(lines)


def _render_ranks(
    ranks:   list[dict],
    mastery: list[float],
    crit:    list[float],
    seals:   dict[str, str],
) -> str:
    if not ranks:
        return "_Rank chain not parsed from the catalog._"
    lines = [
        "| Rank | Title | Mastery × | Crit chance | Augments | Seals | NM Trophy |",
        "|---:|---|---:|---:|---:|---|---|",
    ]
    # Row 0 = unranked starting state.
    lines.append(
        f"| 0 | Unranked | {mastery[0]:.2f}x | {crit[0]*100:.0f}% | — | — | — |"
    )
    for r in ranks:
        idx = r["rank"]
        mult = mastery[idx] if idx < len(mastery) else mastery[-1]
        cpct = crit[idx]    if idx < len(crit)    else crit[-1]
        seal_label = seals.get(r["seal_tier"], r["seal_tier"].title())
        tier_badge = _TIER_BADGE.get(r["seal_tier"], r["seal_tier"].title())
        lines.append(
            f"| {idx} | {r['title']} | {mult:.2f}x | {cpct*100:.0f}% | "
            f"{r['augCount']} lifetime | {r['seal_qty']} × {seal_label} ({tier_badge}) | "
            f"{r['trophy_qty']} × {r['trophy']} (drops from **{r['nm']}**) |"
        )
    lines.append("")
    lines.append(
        "_Augments-required counts the **total lifetime successful augments** "
        "the player has crafted at the Augment Moogle (tracked via "
        "`Augment_Count` charvar). Trophies + seals are **consumed** on promotion._"
    )
    return "\n".join(lines)


def _render_affinities(
    affs:    list[dict],
    counts:  dict[int, int],
    aff_mult: float,
    rank_req: int,
    mark_cost: int,
) -> str:
    if not affs:
        return "_Affinity rows not parsed from the catalog._"
    lines = [
        f"Holding an affinity multiplies augments **in that category** by "
        f"**{aff_mult:.1f}×**. Affinities stack with Sage Mastery and crit. "
        f"Each NM drops a unique trophy; register the affinity at the Augment "
        f"Sage's _Register NM Affinity_ menu — it requires **Hunting League "
        f"Rank {rank_req}** and costs **{mark_cost:,} Hunt Marks**, and the "
        f"trophy is consumed.",
        "",
        "| Cat | Category | NM | Trophy | Catalysts available |",
        "|---:|---|---|---|---:|",
    ]
    for r in affs:
        n = counts.get(r["cat"], 0)
        lines.append(
            f"| {r['cat']} | {r['label']} | {r['nm']} | {r['trophy']} | {n} |"
        )
    return "\n".join(lines)


# =========================================================================
# Entry point
# =========================================================================

def generate(repo_root: Path, docs_dir: Path) -> None:
    sage_src = resolve_source(repo_root, "modules/custom/lua/augment_sage_catalog.lua")
    aff_src  = resolve_source(repo_root, "modules/custom/lua/augment_affinity_catalog.lua")
    cat_src  = resolve_source(repo_root, "modules/custom/lua/augment_catalog.lua")

    if sage_src is None or aff_src is None:
        print("[augment_sage] skip: sage/affinity catalogs not found")
        return

    sage_text = sage_src.read_text(encoding="utf-8", errors="replace")
    aff_text  = aff_src.read_text(encoding="utf-8", errors="replace")
    cat_text  = cat_src.read_text(encoding="utf-8", errors="replace") if cat_src else ""

    # Light parsers (regex match-or-none, no schema regression risk).
    zone     = _parse_zone_id(sage_text)
    pos      = _parse_vendor_pos(sage_text)
    seals    = _parse_seals(sage_text)
    mastery  = _parse_mult_table(sage_text, "masteryMult")
    critPct  = _parse_mult_table(sage_text, "critChance")
    aff_mult = _parse_affinity_mult(aff_text)
    aff_rank, aff_marks = _parse_affinity_gate(aff_text)
    counts   = _parse_cat_counts(cat_text) if cat_text else {}

    # Per-section build: parsers with strict-regex risk (_parse_ranks,
    # _parse_affinities) raise on suspected schema regressions. We catch
    # those here so ONE broken section doesn't skip the writes for the OTHER
    # marker blocks on this page -- the published page keeps as much fresh
    # data as we can give it, and only the regressing section stays at its
    # previous content until a human updates the parser.
    page = docs_dir / "progression" / "augment-sage.md"

    def _section(marker: str, build_content):
        """build_content is a no-arg callable that returns rendered text or
        raises if the underlying parser regressed. On raise: log it loudly,
        skip writing the marker block (existing content survives)."""
        try:
            content = build_content()
        except Exception as e:
            print(f"[augment_sage] {marker}: PARSER REGRESSION -- {e}")
            print(f"[augment_sage] {marker}: keeping existing published content")
            return
        wrote = write_between_markers(page, marker, content)
        if wrote:
            print(f"[augment_sage] {marker}: written into markers")
        else:
            print(f"[augment_sage] {marker}: skipped (markers not found in {page.name})")

    _section("sage-location",   lambda: _render_location(zone, pos))
    _section("sage-formula",    lambda: _render_formula(mastery, critPct, aff_mult))
    _section("sage-ranks",      lambda: _render_ranks(_parse_ranks(sage_text), mastery, critPct, seals))
    _section("sage-affinities", lambda: _render_affinities(_parse_affinities(aff_text), counts, aff_mult, aff_rank, aff_marks))
