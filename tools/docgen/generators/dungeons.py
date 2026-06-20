"""Infamy-Vendor / dungeon-catalog parsing helpers.

The standalone Dungeons page (docs/progression/dungeons.md) was retired along
with the custom dungeon system, so this module no longer generates any page and
is **not** registered in tools/docgen/generate.py — `generate()` is a no-op.

It survives purely as a parsing-helper library for the live Infamy Vendor: the
extractors below read `modules/custom/lua/dungeon_catalog.lua` (the vendor's
stock + currency still live there) and are imported by:
  - infamy_npc.py  — renders the Infamy Vendor's stock onto gear-vendors.md
  - item_index.py  — folds Infamy-Vendor items into the item-finder table

Re-used symbols: `_quoted_value`, `_CURRENCY_NAME_RE`, `_extract_vendor_items`,
`_extract_vendor_items_block`. The catalog is normally gitignored, so callers
resolve it against `$LEGENDARY_LIVE_ROOT`; CI without that skips cleanly.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._bgwiki import urls_for_item


_QUOTED = r"(?:'((?:[^'\\]|\\.)*)'|\"([^\"]*)\")"


def _quoted_value(m: re.Match) -> str:
    raw = m.group(1) if m.group(1) is not None else m.group(2)
    return raw.replace("\\'", "'").replace('\\"', '"').replace("\\\\", "\\")


def _balanced_blocks(text: str):
    """Yield (start, end_exclusive) for each top-level {...} block.
    Same shape as the helper in hunting_league.py / weekly_hunts.py."""
    depth = 0
    start = None
    i = 0
    n = len(text)
    while i < n:
        c = text[i]
        if c == "-" and i + 1 < n and text[i + 1] == "-":
            nl = text.find("\n", i)
            if nl == -1:
                break
            i = nl + 1
            continue
        if c == "'" or c == '"':
            quote = c
            i += 1
            while i < n:
                cc = text[i]
                if cc == "\\" and i + 1 < n:
                    i += 2
                    continue
                if cc == quote:
                    i += 1
                    break
                i += 1
            continue
        if c == "{":
            if depth == 0:
                start = i
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0 and start is not None:
                yield (start, i + 1)
                start = None
        i += 1


# ============================================================
# Dungeon extraction
# ============================================================
_ID_RE          = re.compile(r"\bid\s*=\s*" + _QUOTED)
_LABEL_RE       = re.compile(r"\blabel\s*=\s*" + _QUOTED)
_DESC_RE        = re.compile(r"\bdescription\s*=\s*" + _QUOTED)
_ZONE_NAME_RE   = re.compile(r"\bzoneName\s*=\s*" + _QUOTED)
_TIME_LIMIT_RE  = re.compile(r"\btimeLimit\s*=\s*(\d+)")
_INFAMY_BASE_RE = re.compile(r"\binfamyBase\s*=\s*(\d+)")
_INFAMY_BONUS_RE= re.compile(r"\binfamySpeedBonus\s*=\s*(\d+)")
_TRASH_COUNT_RE = re.compile(r"\btrashCount\s*=\s*(\d+)")
_TRASH_LEVEL_RE = re.compile(r"\btrashLevel\s*=\s*(\d+)")
_BOSS_LEVEL_RE  = re.compile(r"\bbossLevel\s*=\s*(\d+)")
_BOSS_NAME_RE   = re.compile(r"\bbossName\s*=\s*" + _QUOTED)

# ============================================================
# Vendor inventory extraction
# ============================================================
_VENDOR_ID_RE   = re.compile(r"\bid\s*=\s*(\d+)")
_VENDOR_NAME_RE = re.compile(r"\bname\s*=\s*" + _QUOTED)
_VENDOR_COST_RE = re.compile(r"\bcost\s*=\s*(\d+)")

# ============================================================
# Currency name
# ============================================================
_CURRENCY_NAME_RE = re.compile(r"\bcurrencyName\s*=\s*" + _QUOTED)


# ============================================================
# PHASE 1 — Affix pool extraction (catalog.affixes + .mythicAffixes)
# ============================================================
_AFFIX_KIND_RE = re.compile(r"\bkind\s*=\s*" + _QUOTED)
_REWARD_MULT_RE = re.compile(r"\brewardMult\s*=\s*([\d.]+)")
_APPLY_BOSS_RE = re.compile(r"\bapplyBoss\s*=")
_APPLY_TRASH_RE = re.compile(r"\bapplyTrash\s*=")
_APPLY_SESSION_RE = re.compile(r"\bapplySession\s*=")


def _extract_affix_pool(text: str, anchor_name: str) -> list[dict]:
    """Generic affix-array parser. Pass 'catalog.affixes' or
    'catalog.mythicAffixes' as the anchor."""
    m = re.search(rf"\b{re.escape(anchor_name)}\s*=\s*", text)
    if not m:
        return []
    remaining = text[m.end():]
    outer = next(_balanced_blocks(remaining), None)
    if outer is None:
        return []
    inner = remaining[outer[0] + 1: outer[1] - 1]

    out: list[dict] = []
    for s, e in _balanced_blocks(inner):
        body = inner[s + 1: e - 1]
        id_m  = _ID_RE.search(body)
        lbl_m = _LABEL_RE.search(body)
        if not (id_m and lbl_m):
            continue
        kind_m   = _AFFIX_KIND_RE.search(body)
        desc_m   = _DESC_RE.search(body)
        mult_m   = _REWARD_MULT_RE.search(body)
        scope = []
        if _APPLY_BOSS_RE.search(body):    scope.append("boss")
        if _APPLY_TRASH_RE.search(body):   scope.append("trash")
        if _APPLY_SESSION_RE.search(body): scope.append("session")
        if not scope: scope.append("reward")
        out.append({
            "id":          _quoted_value(id_m),
            "label":       _quoted_value(lbl_m),
            "kind":        _quoted_value(kind_m) if kind_m else "negative",
            "description": _quoted_value(desc_m) if desc_m else "",
            "rewardMult":  float(mult_m.group(1)) if mult_m else 1.0,
            "scope":       "/".join(scope),
        })
    return out


# ============================================================
# PHASE 2 — Tier extraction (catalog.tiers)
# ============================================================
_HP_MULT_RE       = re.compile(r"\bhpMult\s*=\s*([\d.]+)")
_ATT_MULT_RE      = re.compile(r"\battMult\s*=\s*([\d.]+)")
_TIME_MULT_RE     = re.compile(r"\btimeMult\s*=\s*([\d.]+)")
_INFAMY_MULT_RE   = re.compile(r"\binfamyMult\s*=\s*([\d.]+)")
_AFFIX_MIN_RE     = re.compile(r"\baffixCountMin\s*=\s*(\d+)")
_AFFIX_MAX_RE     = re.compile(r"\baffixCountMax\s*=\s*(\d+)")
_MYTHIC_POOL_RE   = re.compile(r"\bmythicAffixPool\s*=\s*(true|false)")
_WEEKLY_RE        = re.compile(r"\bweekly\s*=\s*(true|false)")
_UNLOCK_RE        = re.compile(
    r"\bunlockRequires\s*=\s*\{\s*tier\s*=\s*"
    + _QUOTED
    + r"\s*,\s*clears\s*=\s*(\d+)"
)


def _extract_tiers(text: str) -> list[dict]:
    """Parse the catalog.tiers = { normal = {...}, hard = {...}, mythic = {...} }
    block, returning tier dicts in catalog.tierOrder order if present, else
    pairs() order (non-deterministic — but Lua tables hit it the same way)."""
    m = re.search(r"\bcatalog\.tiers\s*=\s*", text)
    if not m:
        return []
    remaining = text[m.end():]
    outer = next(_balanced_blocks(remaining), None)
    if outer is None:
        return []
    inner = remaining[outer[0] + 1: outer[1] - 1]

    # Find each `<name> = {...}` block by scanning for keyword-equals.
    # Lua tier names are bare identifiers, not quoted, so a small regex
    # locates the named blocks.
    tiers: dict[str, dict] = {}
    for name_m in re.finditer(r"\b([A-Za-z_][A-Za-z_0-9]*)\s*=\s*\{", inner):
        name = name_m.group(1)
        if name not in ("normal", "hard", "mythic"):
            continue
        # Walk balanced from the `{` we just matched.
        depth = 1
        i = name_m.end()
        while i < len(inner) and depth > 0:
            ch = inner[i]
            if ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
            i += 1
        body = inner[name_m.end(): i - 1]

        unlock_m = _UNLOCK_RE.search(body)
        unlock = None
        if unlock_m:
            unlock = {
                "tier":   _quoted_value(unlock_m),
                "clears": int(unlock_m.group(3)),
            }

        tiers[name] = {
            "id":            name,
            "label":         _quoted_value(_LABEL_RE.search(body))
                             if _LABEL_RE.search(body) else name.title(),
            "description":   _quoted_value(_DESC_RE.search(body))
                             if _DESC_RE.search(body) else "",
            "hpMult":        float(_HP_MULT_RE.search(body).group(1))
                             if _HP_MULT_RE.search(body) else 1.0,
            "attMult":       float(_ATT_MULT_RE.search(body).group(1))
                             if _ATT_MULT_RE.search(body) else 1.0,
            "timeMult":      float(_TIME_MULT_RE.search(body).group(1))
                             if _TIME_MULT_RE.search(body) else 1.0,
            "infamyMult":    float(_INFAMY_MULT_RE.search(body).group(1))
                             if _INFAMY_MULT_RE.search(body) else 1.0,
            "affixCountMin": int(_AFFIX_MIN_RE.search(body).group(1))
                             if _AFFIX_MIN_RE.search(body) else 1,
            "affixCountMax": int(_AFFIX_MAX_RE.search(body).group(1))
                             if _AFFIX_MAX_RE.search(body) else 2,
            "mythicAffixPool": bool(_MYTHIC_POOL_RE.search(body)
                                    and _MYTHIC_POOL_RE.search(body).group(1) == "true"),
            "weekly":        bool(_WEEKLY_RE.search(body)
                                  and _WEEKLY_RE.search(body).group(1) == "true"),
            "unlock":        unlock,
        }

    # Preserve the canonical Normal → Hard → Mythic order.
    order = ["normal", "hard", "mythic"]
    return [tiers[name] for name in order if name in tiers]


# ============================================================
# PHASE 3 — Per-dungeon phases extraction
# ============================================================
_PHASE_HP_RE      = re.compile(r"\bhp\s*=\s*(\d+)")
_PHASE_ACTION_RE  = re.compile(r"\baction\s*=\s*" + _QUOTED)
_PHASE_MSG_RE     = re.compile(r"\bmessage\s*=\s*" + _QUOTED)
_PHASE_ATT_RE     = re.compile(r"\batt\s*=\s*(\d+)")
_PHASE_HASTE_RE   = re.compile(r"\bhaste\s*=\s*(\d+)")
_PHASE_PCT_RE     = re.compile(r"\bpct\s*=\s*(\d+)")
_PHASE_COUNT_RE   = re.compile(r"\bcount\s*=\s*(\d+)")
_PHASE_NAME_RE    = re.compile(r"\bname\s*=\s*" + _QUOTED)
_PHASE_DMG_RE     = re.compile(r"\bdamage\s*=\s*(\d+)")
_PHASE_SEC_RE     = re.compile(r"\bsec\s*=\s*(\d+)")


def _parse_phase_row(body: str, is_enrage_after: bool = False) -> dict:
    """Decode one phase-row body into a renderable dict. Captures only
    the fields the docgen wants to render — extra catalog fields are
    ignored, so adding new param fields to a phase row never breaks
    the doc render."""
    out: dict = {
        "action":  _quoted_value(_PHASE_ACTION_RE.search(body))
                   if _PHASE_ACTION_RE.search(body) else "",
        "message": _quoted_value(_PHASE_MSG_RE.search(body))
                   if _PHASE_MSG_RE.search(body) else "",
    }
    if is_enrage_after:
        s = _PHASE_SEC_RE.search(body)
        out["sec"] = int(s.group(1)) if s else 0
    else:
        h = _PHASE_HP_RE.search(body)
        out["hp"] = int(h.group(1)) if h else None
    for key, rx in (
        ("att",    _PHASE_ATT_RE),
        ("haste",  _PHASE_HASTE_RE),
        ("pct",    _PHASE_PCT_RE),
        ("count",  _PHASE_COUNT_RE),
        ("damage", _PHASE_DMG_RE),
    ):
        m = rx.search(body)
        if m:
            out[key] = int(m.group(1))
    n = _PHASE_NAME_RE.search(body)
    if n:
        out["name"] = _quoted_value(n)
    return out


def _extract_dungeon_phases(body: str) -> tuple[list[dict], dict | None]:
    """For one dungeon's body text, pull (phase rows, enrageAfter row)."""
    phases: list[dict] = []
    anchor = re.search(r"\bphases\s*=\s*", body)
    if anchor:
        remaining = body[anchor.end():]
        outer = next(_balanced_blocks(remaining), None)
        if outer is not None:
            inner = remaining[outer[0] + 1: outer[1] - 1]
            for s, e in _balanced_blocks(inner):
                rb = inner[s + 1: e - 1]
                phases.append(_parse_phase_row(rb))

    enrage_after = None
    ea_anchor = re.search(r"\benrageAfter\s*=\s*\{", body)
    if ea_anchor:
        # Walk balanced from the `{` we matched, capture the body.
        depth = 1
        i = ea_anchor.end()
        while i < len(body) and depth > 0:
            ch = body[i]
            if ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
            i += 1
        enrage_after = _parse_phase_row(body[ea_anchor.end(): i - 1],
                                        is_enrage_after=True)
    return phases, enrage_after


# ============================================================
# PHASE 4 — Meta config (featured / streak)
# ============================================================
_FEATURED_BONUS_RE = re.compile(r"\bcatalog\.featuredBonus\s*=\s*([\d.]+)")
_STREAK_STEP_RE    = re.compile(r"\bcatalog\.streakStep\s*=\s*([\d.]+)")
_STREAK_CAP_RE     = re.compile(r"\bcatalog\.streakCap\s*=\s*(\d+)")


def _extract_meta(text: str) -> dict:
    fb = _FEATURED_BONUS_RE.search(text)
    ss = _STREAK_STEP_RE.search(text)
    sc = _STREAK_CAP_RE.search(text)
    return {
        "featuredBonus": float(fb.group(1)) if fb else 0.0,
        "streakStep":    float(ss.group(1)) if ss else 0.0,
        "streakCap":     int(sc.group(1))   if sc else 0,
    }


# ============================================================
# Boss roulette extraction (per-dungeon)
# ============================================================
_BOSS_GROUPS_RE = re.compile(r"\bbossGroups\s*=\s*\{([^}]+)\}")
_BOSS_NAMES_RE  = re.compile(r"\bbossNames\s*=\s*\{([^}]+)\}")


def _extract_boss_roster(body: str) -> list[str]:
    """Return the list of possible boss names for one dungeon.
    Singular `bossName = '...'` is the back-compat default; plural
    `bossNames = { 'A', 'B' }` enables roulette."""
    names: list[str] = []
    plural = _BOSS_NAMES_RE.search(body)
    if plural:
        for q in re.finditer(_QUOTED, plural.group(1)):
            names.append(_quoted_value(q))
    if not names:
        single = _BOSS_NAME_RE.search(body)
        if single:
            names.append(_quoted_value(single))
    return names


def _extract_dungeons(text: str) -> list[dict]:
    m = re.search(r"\bcatalog\.dungeons\s*=\s*", text)
    if not m:
        return []
    remaining = text[m.end():]
    outer = next(_balanced_blocks(remaining), None)
    if outer is None:
        return []
    inner = remaining[outer[0] + 1: outer[1] - 1]

    out: list[dict] = []
    for s, e in _balanced_blocks(inner):
        body = inner[s + 1: e - 1]
        id_m   = _ID_RE.search(body)
        lbl_m  = _LABEL_RE.search(body)
        if not (id_m and lbl_m):
            continue
        phases, enrage_after = _extract_dungeon_phases(body)
        out.append({
            "id":          _quoted_value(id_m),
            "label":       _quoted_value(lbl_m),
            "description": (_DESC_RE.search(body) and _quoted_value(_DESC_RE.search(body))) or "",
            "zoneName":    (_ZONE_NAME_RE.search(body) and _quoted_value(_ZONE_NAME_RE.search(body))) or "?",
            "timeLimit":   int((_TIME_LIMIT_RE.search(body) or re.match(r"0", "0")).group(1)) if _TIME_LIMIT_RE.search(body) else 0,
            "infamyBase":  int((_INFAMY_BASE_RE.search(body) or re.match(r"0", "0")).group(1)) if _INFAMY_BASE_RE.search(body) else 0,
            "infamyBonus": int((_INFAMY_BONUS_RE.search(body) or re.match(r"0", "0")).group(1)) if _INFAMY_BONUS_RE.search(body) else 0,
            "trashCount":  int((_TRASH_COUNT_RE.search(body) or re.match(r"0", "0")).group(1)) if _TRASH_COUNT_RE.search(body) else 0,
            "trashLevel":  int((_TRASH_LEVEL_RE.search(body) or re.match(r"0", "0")).group(1)) if _TRASH_LEVEL_RE.search(body) else 0,
            "bossLevel":   int((_BOSS_LEVEL_RE.search(body) or re.match(r"0", "0")).group(1)) if _BOSS_LEVEL_RE.search(body) else 0,
            "bossName":    (_BOSS_NAME_RE.search(body) and _quoted_value(_BOSS_NAME_RE.search(body))) or "?",
            "bossRoster":  _extract_boss_roster(body),    # Phase 1 — boss roulette
            "phases":      phases,                        # Phase 3 — HP triggers
            "enrageAfter": enrage_after,                  # Phase 3 — time enrage
        })
    return out


def _extract_vendor_items_block(text: str, anchor: str) -> list[dict]:
    """Generic extractor — parameterized on which catalog array to pull
    from. Used for BOTH catalog.vendorItems (hand-picked) and
    catalog.vendorItemsAuto (auto-promoted by build_infamy_top_picks.py)."""
    m = re.search(rf"\b{re.escape(anchor)}\s*=\s*", text)
    if not m:
        return []
    remaining = text[m.end():]
    outer = next(_balanced_blocks(remaining), None)
    if outer is None:
        return []
    inner = remaining[outer[0] + 1: outer[1] - 1]

    out: list[dict] = []
    for s, e in _balanced_blocks(inner):
        body = inner[s + 1: e - 1]
        id_m   = _VENDOR_ID_RE.search(body)
        name_m = _VENDOR_NAME_RE.search(body)
        cost_m = _VENDOR_COST_RE.search(body)
        if not (id_m and name_m and cost_m):
            continue
        stats: list[str] = []
        stats_anchor = re.search(r"\bstats\s*=\s*", body)
        if stats_anchor:
            s_remaining = body[stats_anchor.end():]
            s_outer = next(_balanced_blocks(s_remaining), None)
            if s_outer is not None:
                s_inner = s_remaining[s_outer[0] + 1: s_outer[1] - 1]
                for qm in re.finditer(_QUOTED, s_inner):
                    stats.append(_quoted_value(qm))
        out.append({
            "id":    int(id_m.group(1)),
            "name":  _quoted_value(name_m),
            "cost":  int(cost_m.group(1)),
            "stats": stats,
        })
    return out


def _extract_vendor_items(text: str) -> list[dict]:
    """Backwards-compat shim. The real work lives in
    _extract_vendor_items_block so we can also pull the auto block."""
    return _extract_vendor_items_block(text, "catalog.vendorItems")


# ============================================================
# +4 REFORGE SETS — catalog.plus4Sets (accessible via the +4
# Reforge Sets menu option on the Infamy Vendor NPC)
#
# Structure in the catalog:
#   catalog.plus4Sets = {
#       ['BLM'] = {
#           { set = 'Archmages', pieces = { ['head'] = { id, name, stats={...} }, ... } },
#           { set = 'Spaekonas', pieces = { ... } },
#       },
#       ['BLU'] = { ... },
#       ...
#   }
# ============================================================
_PLUS4_COST_RE = re.compile(r"catalog\.plus4Cost\s*=\s*(\d+)")
_PLUS4_JOB_RE  = re.compile(r"\['([A-Z]{3})'\]\s*=\s*\{")
_PLUS4_SET_RE  = re.compile(r"\bset\s*=\s*['\"]([^'\"]+)['\"]")
_PLUS4_PIECE_RE = re.compile(
    r"\['([a-z]+)'\]\s*=\s*\{\s*id\s*=\s*(\d+)\s*,\s*name\s*=\s*['\"]([^'\"]+)['\"]"
)


def _extract_plus4_sets(text: str) -> tuple[int, dict[str, list[dict]]]:
    """Returns (plus4Cost, {job: [{set, pieces:{slot: {id, name}}}, ...]}).
    Plays the same balanced-brace game the other extractors do so we
    handle the nested table-in-table structure correctly."""
    cost_m = _PLUS4_COST_RE.search(text)
    cost = int(cost_m.group(1)) if cost_m else 0

    anchor = re.search(r"catalog\.plus4Sets\s*=\s*", text)
    if not anchor:
        return cost, {}
    remaining = text[anchor.end():]
    outer = next(_balanced_blocks(remaining), None)
    if outer is None:
        return cost, {}
    inner = remaining[outer[0] + 1: outer[1] - 1]

    # Find each ['JOB'] = { ... } block by scanning for the key, then
    # capturing the matching balanced {...} that follows.
    sets_by_job: dict[str, list[dict]] = {}
    for jm in _PLUS4_JOB_RE.finditer(inner):
        job = jm.group(1)
        # Walk balanced braces from the opening `{` we matched.
        depth = 1
        i = jm.end()
        while i < len(inner) and depth > 0:
            ch = inner[i]
            if ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
            i += 1
        job_body = inner[jm.end(): i - 1]

        # Each { set = '...', pieces = { ... } } is a top-level block
        # within job_body. Walk balanced blocks at the top level.
        sets_for_job: list[dict] = []
        for s, e in _balanced_blocks(job_body):
            row = job_body[s + 1: e - 1]
            set_m = _PLUS4_SET_RE.search(row)
            if not set_m:
                continue
            pieces: dict[str, dict] = {}
            for pm in _PLUS4_PIECE_RE.finditer(row):
                slot, pid, pname = pm.group(1), int(pm.group(2)), pm.group(3)
                pieces[slot] = {"id": pid, "name": pname}
            if pieces:
                sets_for_job.append({"set": set_m.group(1), "pieces": pieces})
        if sets_for_job:
            sets_by_job[job] = sets_for_job
    return cost, sets_by_job


_JOB_DISPLAY_ORDER = (
    "WAR", "MNK", "WHM", "BLM", "RDM", "THF", "PLD", "DRK",
    "BST", "BRD", "RNG", "SAM", "NIN", "DRG", "SMN", "BLU",
    "COR", "PUP", "DNC", "SCH", "GEO", "RUN",
)
_PLUS4_SLOT_ORDER = ("head", "body", "hands", "legs", "feet")


def _render_plus4(cost: int, by_job: dict[str, list[dict]], currency: str) -> str:
    """Compact per-job summary so 22 jobs × 2-3 sets × 5 slots fits on
    one page without overwhelming. Job sub-sections list each set with
    its slot count + lazy-linked piece names."""
    if not by_job:
        return ""

    total_pieces = sum(
        len(s["pieces"]) for sets in by_job.values() for s in sets
    )
    total_sets = sum(len(sets) for sets in by_job.values())

    lines: list[str] = [
        f"### +4 Reforge Sets  ({len(by_job)} jobs, {total_sets} sets, {total_pieces} pieces)",
        "",
        f"_**{cost} {currency} per piece** ({cost * 5} for a full 5-slot set). "
        f"Browse Job → Set → Slot in-game via the **+4 Reforge Sets** menu on "
        f"the Infamy Vendor NPC. Stats are sourced from BG-Wiki._",
        "",
        "| Job | Sets | Slots | Items |",
        "|---|---|---:|---|",
    ]
    for job in _JOB_DISPLAY_ORDER:
        sets = by_job.get(job, [])
        if not sets:
            continue
        set_labels = []
        all_names = []
        slot_total = 0
        for s in sets:
            piece_count = len(s["pieces"])
            slot_total += piece_count
            set_labels.append(f"{s['set']} +4 ({piece_count})")
            # First piece's name minus the set prefix gives the slot
            # examples for the Items column — keeps it compact.
            for slot in _PLUS4_SLOT_ORDER:
                p = s["pieces"].get(slot)
                if p:
                    all_names.append(_item_link(p["name"], p.get("id")))
        sets_cell = ", ".join(set_labels)
        items_cell = ", ".join(all_names)
        lines.append(
            f"| **{job}** | {_escape_md(sets_cell)} | {slot_total} | {items_cell} |"
        )
    return "\n".join(lines)


def _escape_md(s: str) -> str:
    return s.replace("|", "\\|").replace("\n", " ")


def _item_link(name: str, item_id: int | None = None) -> str:
    page_url, image_url = urls_for_item(name, None, item_id)
    img_attr = f' data-img="{image_url}"' if image_url else ""
    return (
        f'<a class="item-link" href="{page_url}"{img_attr} '
        f'target="_blank" rel="noopener">{_escape_md(name)}</a>'
    )


def _fmt_time(seconds: int) -> str:
    if seconds >= 60:
        m, s = divmod(seconds, 60)
        if s == 0:
            return f"{m} min"
        return f"{m}m {s}s"
    return f"{seconds}s"


def _render_ladder(dungeons: list[dict], currency: str) -> str:
    if not dungeons:
        return "_No dungeon entries parsed from the catalog._"
    lines = [
        f"_{len(dungeons)} dungeons in the launch set. Each costs no tokens to enter — "
        "Infamy is paid out on clear, not gated at entry. Failed runs simply earn nothing._",
        "",
        "| Dungeon | Zone | Time | Mob Pop | Boss | Base | Speed Bonus |",
        "|---|---|---:|---:|---|---:|---:|",
    ]
    for d in dungeons:
        zone = d["zoneName"].replace("_", " ")
        mob_pop = f"{d['trashCount']} × Lv{d['trashLevel']}"
        boss = f"{_escape_md(d['bossName'])} (Lv{d['bossLevel']})"
        title = f"**{_escape_md(d['label'])}**"
        if d["description"]:
            title = f"{title}<br><sub>{_escape_md(d['description'])}</sub>"
        lines.append(
            f"| {title} | {_escape_md(zone)} | {_fmt_time(d['timeLimit'])} | "
            f"{mob_pop} | {boss} | {d['infamyBase']:,} {currency} | "
            f"+{d['infamyBonus']:,} (sub-half time) |"
        )
    return "\n".join(lines)


def _kind_marker(kind: str) -> str:
    """Inline marker matching the in-game chat banner (+/-/*)."""
    if kind == "positive": return "**+**"
    if kind == "negative": return "**-**"
    return "**\\***"


def _render_tiers(tiers: list[dict]) -> str:
    if not tiers:
        return "_No tier data parsed from the catalog._"
    lines = [
        "Every dungeon can be run on any of three tiers. Higher tiers gate on prior clears, scale boss HP/ATT, tighten the timer, and pay proportionally more Infamy.",
        "",
        "| Tier | HP × | ATT × | Time × | Infamy × | Affixes / run | Mythic pool | Gate | Weekly key |",
        "|---|---:|---:|---:|---:|---:|:---:|---|:---:|",
    ]
    for t in tiers:
        if t["unlock"]:
            gate = (f"{t['unlock']['clears']} "
                    f"{t['unlock']['tier'].title()} clear"
                    f"{'s' if t['unlock']['clears'] != 1 else ''}")
        else:
            gate = "always open"
        affix_range = (f"{t['affixCountMin']}"
                       if t["affixCountMin"] == t["affixCountMax"]
                       else f"{t['affixCountMin']}–{t['affixCountMax']}")
        lines.append(
            f"| **{_escape_md(t['label'])}** | {t['hpMult']:.2f} | "
            f"{t['attMult']:.2f} | {t['timeMult']:.2f} | {t['infamyMult']:.2f} | "
            f"{affix_range} | {'yes' if t['mythicAffixPool'] else '—'} | "
            f"{_escape_md(gate)} | {'yes' if t['weekly'] else '—'} |"
        )
    lines.append("")
    lines.append(
        "**Mythic** also rolls from the Tyrannical affix pool (one is guaranteed per run) and burns a one-per-week-per-dungeon key. The key resets every Monday at 00:00 UTC for all players simultaneously."
    )
    return "\n".join(lines)


def _render_affixes(base: list[dict], mythic: list[dict]) -> str:
    if not base and not mythic:
        return "_No affix data parsed from the catalog._"
    lines = [
        "Every run rolls 1–2 affixes from the base pool (2–3 at Mythic). Each affix's reward multiplier compounds with all the others — Voracious + Mighty = 1.15 × 1.20 = **1.38× Infamy** for a sweaty run. Mixed/negative affixes pay more; positive affixes pay less.",
        "",
        "### Base pool",
        "",
        "| Affix | Kind | Effect | Reward × |",
        "|---|:---:|---|---:|",
    ]
    for a in sorted(base, key=lambda r: (-r["rewardMult"], r["label"])):
        lines.append(
            f"| **{_escape_md(a['label'])}** | {_kind_marker(a['kind'])} | "
            f"{_escape_md(a['description'])} | {a['rewardMult']:.2f} |"
        )
    if mythic:
        lines.append("")
        lines.append("### Tyrannical pool (Mythic only)")
        lines.append("")
        lines.append("These are nastier than the base pool. One is guaranteed per Mythic run; the remaining slots draw from the combined pool.")
        lines.append("")
        lines.append("| Affix | Kind | Effect | Reward × |")
        lines.append("|---|:---:|---|---:|")
        for a in sorted(mythic, key=lambda r: (-r["rewardMult"], r["label"])):
            lines.append(
                f"| **{_escape_md(a['label'])}** | {_kind_marker(a['kind'])} | "
                f"{_escape_md(a['description'])} | {a['rewardMult']:.2f} |"
            )
    return "\n".join(lines)


def _phase_summary(phase: dict) -> str:
    """One-line human readable description of a phase row."""
    a = phase["action"]
    bits: list[str] = []
    if a in ("buff", "enrage"):
        if phase.get("att"):   bits.append(f"+{phase['att']} ATT")
        if phase.get("haste"): bits.append(f"+{phase['haste']} Haste")
    elif a == "heal":
        if phase.get("pct"):   bits.append(f"heals {phase['pct']}% HP")
    elif a == "aoe":
        if phase.get("damage"): bits.append(f"{phase['damage']} AoE damage")
    elif a == "dispel":
        if phase.get("count"): bits.append(f"strips {phase['count']} buffs")
    elif a == "add_spawn":
        c = phase.get("count", 1)
        n = phase.get("name", "add")
        bits.append(f"spawns {c} × {n}")
    body = ", ".join(bits) if bits else a
    return body


def _render_mechanics(dungeons: list[dict]) -> str:
    """Per-dungeon HP-phase + enrageAfter table."""
    any_phases = any(d["phases"] or d["enrageAfter"] for d in dungeons)
    if not any_phases:
        return "_No boss-phase data parsed from the catalog._"
    lines = [
        "Boss fights have HP-threshold triggers in addition to the raw stat numbers. Phases fire **once each per run**, in catalog order, and the catalog walks the list every combat tick — a single big hit can fire multiple phases in sequence.",
        "",
    ]
    for d in dungeons:
        if not d["phases"] and not d["enrageAfter"]:
            continue
        lines.append(f"### {_escape_md(d['label'])}")
        lines.append("")
        if d["phases"]:
            lines.append("| Trigger | Action | Effect | Message |")
            lines.append("|---|---|---|---|")
            for p in d["phases"]:
                trigger = (f"at {p['hp']}% HP"
                           if p.get("hp") is not None else "—")
                msg = (f"_{_escape_md(p['message'])}_" if p.get("message") else "—")
                lines.append(
                    f"| {trigger} | `{p['action']}` | {_escape_md(_phase_summary(p))} | "
                    f"{msg} |"
                )
        ea = d["enrageAfter"]
        if ea:
            mins, secs = divmod(ea.get("sec", 0), 60)
            t = f"{mins}m {secs}s" if secs else f"{mins}m"
            lines.append("")
            lines.append(
                f"**Time enrage:** after **{t}** the boss fires "
                f"`{ea['action']}` ({_escape_md(_phase_summary(ea))}). "
                f"_{_escape_md(ea['message'])}_"
            )
        # Boss roulette callout — if there are multiple possible names,
        # surface them so a player who saw "Azathoth" yesterday knows
        # they might face "Paradoxon" today.
        if len(d["bossRoster"]) > 1:
            lines.append("")
            lines.append(
                "**Boss roulette:** each run picks from {" +
                ", ".join(f"_{_escape_md(n)}_" for n in d["bossRoster"]) +
                "}."
            )
        lines.append("")
    return "\n".join(lines).rstrip()


def _render_meta(meta: dict, dungeons: list[dict]) -> str:
    if not meta or (meta["featuredBonus"] == 0 and meta["streakCap"] == 0):
        return "_No meta-progression config parsed from the catalog._"
    streak_max = 1.0 + meta["streakCap"] * meta["streakStep"]
    lines = [
        "Three login hooks layered on top of the reward path:",
        "",
        "**1. Daily featured dungeon** — One dungeon per UTC day pays "
        f"**+{meta['featuredBonus'] * 100:.0f}% Infamy** flat. Rotation is deterministic "
        "(`floor(epoch / 86400) % #dungeons`), so the same dungeon is featured for every "
        "player on the server. Resets at 00:00 UTC; shown with a `*` in the dungeon menu.",
        "",
        "**2. Streak bonus** — Consecutive non-abort clears bump `Dungeon_Streak`. "
        f"Each step grants **+{meta['streakStep'] * 100:.0f}% Infamy**, capped at "
        f"**{meta['streakCap']} (×{streak_max:.2f} max)**. **Any abort, death, or timeout resets to 0.**",
        "",
        "**3. Mythic weekly key** — Each player gets one Mythic clear per dungeon per week. "
        "Resets every **Monday 00:00 UTC** server-wide. The dungeon menu shows the countdown "
        "(e.g. `Mythic key resets in 2d 14h`) when the key is currently consumed.",
        "",
        "### The complete reward stack",
        "",
        "Applied in order on every clear:",
        "",
        "```",
        "infamy  =  base",
        "         + (clear within first half of timer ? speedBonus : 0)",
        "         * tier.infamyMult         ← Phase 2  (Normal 1.0 / Hard 2.0 / Mythic 5.0)",
        "         * Π affix.rewardMult      ← Phase 1  (product of all rolled affixes)",
        f"         * (featured ? {1 + meta['featuredBonus']:.2f} : 1.00)        ← Phase 4  (daily rotation)",
        f"         * (1 + streak × {meta['streakStep']:.2f})        ← Phase 4  (up to ×{streak_max:.2f} at streak {meta['streakCap']})",
        "```",
    ]
    return "\n".join(lines)


# ============================================================
# Infamy Vendor inventory — grouped by equipment slot so the page
# is reviewable at a glance (the +4 reforge sets stay in their own
# section via _render_plus4). The slot / weapon-type for EVERY item
# comes from catalog.itemTypeMap (what the in-game vendor groups by);
# role / score / description come from each item's `stats` strings.
# ============================================================
_VENDOR_SLOT_ORDER = [
    ("Head",         "Head"),
    ("Neck",         "Neck"),
    ("Ear",          "Earrings"),
    ("Body",         "Body"),
    ("Hands",        "Hands"),
    ("Ring",         "Rings"),
    ("Back",         "Back"),
    ("Waist",        "Waist"),
    ("Legs",         "Legs"),
    ("Feet",         "Feet"),
    ("Hand-to-Hand", "Weapon - Hand-to-Hand"),
    ("Dagger",       "Weapon - Dagger"),
    ("Sword",        "Weapon - Sword"),
    ("Great Sword",  "Weapon - Great Sword"),
    ("Axe",          "Weapon - Axe"),
    ("Great Axe",    "Weapon - Great Axe"),
    ("Scythe",       "Weapon - Scythe"),
    ("Polearm",      "Weapon - Polearm"),
    ("Katana",       "Weapon - Katana"),
    ("Great Katana", "Weapon - Great Katana"),
    ("Club",         "Weapon - Club"),
    ("Staff",        "Weapon - Staff"),
    ("Archery",      "Weapon - Archery"),
    ("Marksmanship", "Weapon - Marksmanship"),
    ("Ammo",         "Ammo"),
    ("Grip-Shield",  "Weapon - Grip / Shield"),
    ("Instrument",   "Weapon - Instrument"),
]
_VENDOR_SLOT_DISPLAY = {k: v for k, v in _VENDOR_SLOT_ORDER}
_VENDOR_SLOT_RANK = {k: i for i, (k, _) in enumerate(_VENDOR_SLOT_ORDER)}

_VENDOR_SLOT_RE  = re.compile(r"top-5\s*\(([^)]+)\)")
_VENDOR_SCORE_RE = re.compile(r"\b(DPS|WS|TANK|CASTER|HEAL)\s+score\s+(\d+)")
_TYPEMAP_ROW_RE  = re.compile(r"\[(\d+)\]\s*=\s*'([^']+)'")

# Map the slot wording used in `stats` ("Armor top-5 (legs)",
# "Weapons top-5 (Swords)") to the itemTypeMap's singular keys, for the rare
# item missing from the typemap.
_STATS_TO_TYPEMAP = {
    "head": "Head", "neck": "Neck", "ear": "Ear", "ears": "Ear",
    "body": "Body", "hands": "Hands", "ring": "Ring", "rings": "Ring",
    "back": "Back", "waist": "Waist", "legs": "Legs", "feet": "Feet",
    "Swords": "Sword", "Daggers": "Dagger", "Clubs": "Club", "Staves": "Staff",
    "Scythes": "Scythe", "Polearms": "Polearm", "Axes": "Axe",
    "Great Axes": "Great Axe", "Great Swords": "Great Sword",
    "H2H": "Hand-to-Hand",
}


def _extract_type_map(text: str) -> dict:
    """Parse catalog.itemTypeMap = { [id] = 'Category/Subtype', ... } into
    {id: 'Subtype'} — the authoritative per-item slot / weapon-type (built by
    build_infamy_typemap.py from item_equipment.slot + item_weapon.skill), so
    even curated items with free-text stats get grouped correctly."""
    anchor = re.search(r"catalog\.itemTypeMap\s*=\s*", text)
    if not anchor:
        return {}
    remaining = text[anchor.end():]
    outer = next(_balanced_blocks(remaining), None)
    if outer is None:
        return {}
    inner = remaining[outer[0] + 1: outer[1] - 1]
    out: dict = {}
    for m in _TYPEMAP_ROW_RE.finditer(inner):
        cat_sub = m.group(2)
        out[int(m.group(1))] = (cat_sub.split("/", 1)[1] if "/" in cat_sub else cat_sub).strip()
    return out


def _vendor_item_facets(it: dict) -> dict:
    """role + score (for sort/display) and the leftover descriptive stats
    (everything except the redundant 'top-5 (slot)' tag the heading already
    shows). Curated items keep their hand-written description in `notes`."""
    role, score, notes_bits = "", 0, []
    for s in it.get("stats", []):
        if _VENDOR_SLOT_RE.search(s):
            continue
        if not role:
            m = _VENDOR_SCORE_RE.search(s)
            if m:
                role, score = m.group(1), int(m.group(2))
        notes_bits.append(s)
    return {"role": role, "score": score, "notes": ", ".join(notes_bits)}


def _vendor_item_slot(it: dict, type_map: dict) -> str:
    """Authoritative slot from itemTypeMap; fall back to the stats wording
    (normalized), then 'Other' so nothing is dropped."""
    s = type_map.get(it.get("id", -1))
    if s:
        return s
    for stat in it.get("stats", []):
        m = _VENDOR_SLOT_RE.search(stat)
        if m:
            key = m.group(1).strip()
            return _STATS_TO_TYPEMAP.get(key, key)
    return "Other"


def _render_vendor(items: list[dict], auto_items: list[dict],
                   plus4_cost: int, plus4_by_job: dict[str, list[dict]],
                   currency: str, type_map: dict | None = None) -> str:
    if not items and not auto_items and not plus4_by_job:
        return "_No vendor inventory parsed from the catalog._"
    type_map = type_map or {}

    # Merge hand-picked (Curated) + auto-promoted (BiS). Deduped upstream, so
    # each item appears once; the Pick column preserves the source.
    merged: list[dict] = []
    for it in items:
        merged.append({**it, "_source": "Curated"})
    for it in auto_items:
        merged.append({**it, "_source": "BiS"})
    for it in merged:
        it["_facets"] = _vendor_item_facets(it)
        it["_slot"] = _vendor_item_slot(it, type_map)

    buckets: dict[str, list[dict]] = {}
    for it in merged:
        buckets.setdefault(it["_slot"], []).append(it)

    def _slot_sort_key(slot: str):
        # Known slots in equipment order; anything else alphabetical at the end.
        return (_VENDOR_SLOT_RANK.get(slot, len(_VENDOR_SLOT_RANK)), slot.lower())

    lines: list[str] = []
    if merged:
        lines.append(f"### Gear by slot  ({len(merged)} items)")
        lines.append("")
        lines.append(
            f"_Every Infamy Vendor item except the +4 reforge sets, grouped by the slot it "
            f"fills (the same grouping the in-game vendor uses) and sorted by cost then "
            f"score. Costs are in {currency}. **Pick**: Curated = hand-picked, BiS = "
            f"auto-promoted best-in-slot. Item names link to BG-Wiki._"
        )
        lines.append("")
        for slot in sorted(buckets, key=_slot_sort_key):
            rows = sorted(
                buckets[slot],
                key=lambda r: (-r["cost"], -r["_facets"]["score"], r["name"].lower()),
            )
            display = _VENDOR_SLOT_DISPLAY.get(slot, slot)
            lines.append(f"#### {display}  ({len(rows)})")
            lines.append("")
            lines.append("| Item | Cost | Pick | Notes |")
            lines.append("|---|---:|---|---|")
            for it in rows:
                lines.append(
                    f"| {_item_link(it['name'], it.get('id'))} | {it['cost']:,} {currency} | "
                    f"{it['_source']} | {_escape_md(it['_facets']['notes'])} |"
                )
            lines.append("")
    if plus4_by_job:
        # _render_plus4 already builds its own ### header, so append as-is.
        lines.append(_render_plus4(plus4_cost, plus4_by_job, currency))
        lines.append("")
    return "\n".join(lines).rstrip()


def generate(repo_root: Path, docs_dir: Path) -> None:
    """No-op: the standalone Dungeons page was retired with the dungeon system.

    This module is intentionally **not** registered in tools/docgen/generate.py
    anymore — it no longer writes any page. It survives only as a parsing-helper
    library: ``infamy_npc.py`` and ``item_index.py`` import its vendor-item
    extractors (``_extract_vendor_items`` / ``_extract_vendor_items_block`` /
    ``_CURRENCY_NAME_RE`` / ``_quoted_value``) to read the Infamy Vendor's stock
    out of the catalog. Keeping this entry point as a harmless stub means that if
    the module is ever re-registered by mistake it does nothing rather than
    trying to write a page that no longer exists.
    """
    return
