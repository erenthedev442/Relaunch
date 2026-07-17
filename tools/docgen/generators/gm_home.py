"""Generate GM Home feature reference tables inside docs/progression/gm-home.md.

Reads these catalogs:
  - modules/custom/lua/test_dummy_catalog.lua
  - modules/custom/lua/gil_mystery_box_catalog.lua
  - modules/custom/lua/gil_warp_npc_catalog.lua
  - modules/custom/lua/gil_title_vendor_catalog.lua
  - modules/custom/lua/ExpCamp_Moogle.lua

Marker IDs:
  - "gm-home-test-dummy"    -- Test Dummy tiers table
  - "gm-home-mystery-mog"   -- Mystery Mog pool tables + pull cost summary
  - "gm-home-warpman"       -- Warpman destinations table
  - "gm-home-title-broker"  -- Title Broker tiers + title list
  - "gm-home-exp-camps"     -- EXP Camp Moogle level/destination table
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._bgwiki import urls_for_item

# ---------------------------------------------------------------------------
# Lua helpers (duplicated per the established pattern)
# ---------------------------------------------------------------------------

_QUOTED = r"""'(?:[^'\\]|\\.)*'|"(?:[^"\\]|\\.)*" """


def _quoted_value(s: str) -> str:
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
# Helpers
# ---------------------------------------------------------------------------

def _parse_int(text: str, key: str) -> int | None:
    m = re.search(rf'\b{re.escape(key)}\s*=\s*(\d+)', text)
    return int(m.group(1)) if m else None


def _hp_display(hp: int) -> str:
    m_val = hp // 1_000_000
    if m_val * 1_000_000 == hp:
        return f"{hp:,} ({m_val}M)"
    return f"{hp:,}"


# ---------------------------------------------------------------------------
# Test Dummy parsers
# ---------------------------------------------------------------------------

def _parse_tier_order(text: str, key: str = "tierOrder") -> list[str]:
    m = re.search(rf'\b{re.escape(key)}\s*=\s*\{{', text)
    if not m:
        return []
    for start, end in _balanced_blocks(text[m.start():]):
        block = text[m.start():][start:end]
        return [_quoted_value(q) for q in re.findall(_QUOTED, block)]
    return []


def _parse_test_dummy_tiers(text: str, order: list[str]) -> list[dict]:
    m = re.search(r'\btiers\s*=\s*\{', text)
    if not m:
        return []
    for start, end in _balanced_blocks(text[m.start():]):
        tiers_block = text[m.start():][start:end]
        break
    else:
        return []

    tiers = []
    for name in order:
        tm = re.search(rf'\b{re.escape(name)}\s*=\s*\{{', tiers_block)
        if not tm:
            continue
        sub = tiers_block[tm.start():]
        for ts, te in _balanced_blocks(sub):
            entry = sub[ts:te]
            # label / family are quoted (single OR double -- "World's End"); capture
            # the opening quote and match up to its twin so apostrophes are safe.
            label_m  = re.search(r'''\blabel\s*=\s*(['"])(.*?)\1''', entry)
            family_m = re.search(r'''\bfamily\s*=\s*(['"])(.*?)\1''', entry)
            lvl = _parse_int(entry, "maxLevel")
            if lvl is None:
                lvl = _parse_int(entry, "minLevel")
            tiers.append({
                "key":    name,
                "label":  label_m.group(2) if label_m else name,
                "family": family_m.group(2) if family_m else "",
                "level":  lvl if lvl is not None else "?",
                "hp":     _parse_int(entry, "hp") or 0,
            })
            break

    return tiers


# ---------------------------------------------------------------------------
# Mystery Mog parsers
# ---------------------------------------------------------------------------

def _parse_pool_entries(text: str, pool_key: str) -> list[dict]:
    m = re.search(rf'\b{re.escape(pool_key)}\s*=\s*\{{', text)
    if not m:
        return []
    for start, end in _balanced_blocks(text[m.start():]):
        pool_block = text[m.start():][start:end]
        break
    else:
        return []

    entries = []
    for es, ee in _balanced_blocks(pool_block[1:]):
        entry = pool_block[1:][es:ee]
        tier_m   = re.search(r'\btier\s*=\s*(' + _QUOTED + r')', entry)
        weight_m = re.search(r'\bweight\s*=\s*(\d+)', entry)
        label_m  = re.search(r'\blabel\s*=\s*(' + _QUOTED + r')', entry)
        if not (tier_m and weight_m and label_m):
            continue
        entries.append({
            "tier":   _quoted_value(tier_m.group(1).strip()),
            "weight": int(weight_m.group(1)),
            "label":  _quoted_value(label_m.group(1).strip()),
        })
    return entries


# ---------------------------------------------------------------------------
# Warp NPC parsers
# ---------------------------------------------------------------------------

def _parse_pricing(text: str) -> dict[str, int]:
    m = re.search(r'\bpricing\s*=\s*\{', text)
    if not m:
        return {}
    for start, end in _balanced_blocks(text[m.start():]):
        block = text[m.start():][start:end]
        pricing = {}
        for pm in re.finditer(r'\b(\w+)\s*=\s*(\d+)', block):
            pricing[pm.group(1)] = int(pm.group(2))
        return pricing
    return {}


def _parse_warp_tiers(text: str, pricing: dict[str, int]) -> list[dict]:
    m = re.search(r'\btiers\s*=\s*\{', text)
    if not m:
        return []
    for start, end in _balanced_blocks(text[m.start():]):
        tiers_block = text[m.start():][start:end]
        break
    else:
        return []

    tiers = []
    for es, ee in _balanced_blocks(tiers_block[1:]):
        entry = tiers_block[1:][es:ee]
        label_m = re.search(r'\blabel\s*=\s*(' + _QUOTED + r')', entry)
        if not label_m:
            continue
        raw_label = _quoted_value(label_m.group(1).strip())

        # Try literal cost first, then catalog.pricing.X reference
        cost_m = re.search(r'\bcost\s*=\s*(\d+)', entry)
        if cost_m:
            cost = int(cost_m.group(1))
        else:
            ref_m = re.search(r'\bcost\s*=\s*catalog\.pricing\.(\w+)', entry)
            cost = pricing.get(ref_m.group(1), 0) if ref_m else 0

        # Parse destinations sub-block
        dest_m = re.search(r'\bdestinations\s*=\s*\{', entry)
        destinations = []
        if dest_m:
            sub = entry[dest_m.start():]
            for ds, de in _balanced_blocks(sub):
                dest_block = sub[ds:de]
                for dds, dde in _balanced_blocks(dest_block[1:]):
                    dest_entry = dest_block[1:][dds:dde]
                    dlabel_m = re.search(r'\blabel\s*=\s*(' + _QUOTED + r')', dest_entry)
                    if dlabel_m:
                        destinations.append(_quoted_value(dlabel_m.group(1).strip()))
                break

        # Strip price suffix like " (5k)" or " (50k)" from tier label
        clean_label = re.sub(r'\s*\(\d+k\)\s*$', '', raw_label).strip()

        tiers.append({
            "label":        clean_label,
            "cost":         cost,
            "destinations": destinations,
        })

    return tiers


# ---------------------------------------------------------------------------
# Renderers
# ---------------------------------------------------------------------------

def _render_test_dummy(tiers: list[dict]) -> str:
    asc   = [t for t in tiers if t["family"] == "asc"]
    aby   = [t for t in tiers if t["family"] == "aby"]
    other = [t for t in tiers if t["family"] not in ("asc", "aby")]

    def _table(title: str, header: str, rows: list[dict]) -> list[str]:
        out = []
        if title:
            out.append(title)
            out.append("")
        out.append(f"| {header} | Level | HP |")
        out.append("|---|---|---|")
        for t in rows:
            out.append(f"| {t['label']} | L{t['level']} | {_hp_display(t['hp'])} |")
        out.append("")
        return out

    lines: list[str] = []
    if asc:
        lines += _table(
            "**Ascension Courts** — each mirrors the toughest boss of that Prestige trial tier (all level 150).",
            "Court", asc)
    if aby:
        lines += _table(
            "**Abyssea NMs** — each mirrors our custom Abyssea notorious-monster defense at that content tier.",
            "NM tier", aby)
    if other:
        lines += _table("", "Target", other)
    return "\n".join(lines).rstrip()


def _render_mystery_mog(
    pull_cost: int,
    triple_cost: int,
    deca_cost: int,
    premium_cost: int,
    pool: list[dict],
    premium_pool: list[dict],
) -> str:
    lines = []

    # Pull cost summary
    lines.append("| Pull type | Cost |")
    lines.append("|---|---:|")
    lines.append(f"| Single | {pull_cost:,} gil |")
    lines.append(f"| Triple (10% off) | {triple_cost:,} gil |")
    lines.append(f"| 10× pull | {deca_cost:,} gil |")
    lines.append(f"| Premium | {premium_cost:,} gil |")
    lines.append("")

    # Standard pool
    total_weight = sum(e["weight"] for e in pool)
    lines.append(f"_Standard pull: **{pull_cost:,} gil** per pull._")
    lines.append("")
    lines.append("| Rarity | Prize | Approx. Chance |")
    lines.append("|---|---|---:|")
    for entry in pool:
        chance = entry["weight"] / total_weight * 100
        lines.append(
            f"| {entry['tier'].capitalize()} | {entry['label']} | {chance:.1f}% |"
        )

    lines.append("")

    # Premium pool
    total_premium = sum(e["weight"] for e in premium_pool)
    lines.append(f"_Premium pull: **{premium_cost:,} gil** per pull. No commons — higher odds on rare+ prizes._")
    lines.append("")
    lines.append("| Rarity | Prize | Approx. Chance |")
    lines.append("|---|---|---:|")
    for entry in premium_pool:
        chance = entry["weight"] / total_premium * 100
        lines.append(
            f"| {entry['tier'].capitalize()} | {entry['label']} | {chance:.1f}% |"
        )

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Title Broker parsers
# ---------------------------------------------------------------------------

def _parse_title_tiers(text: str) -> list[dict]:
    """Return list of {label, cost, titles:[str]} from catalog.tiers."""
    m = re.search(r'\btiers\s*=\s*\{', text)
    if not m:
        return []
    suffix = text[m.start():]
    outer_block = None
    for s, e in _balanced_blocks(suffix):
        outer_block = suffix[s:e]
        break
    if not outer_block:
        return []

    tiers = []
    inner = outer_block[1:-1]
    for ts, te in _balanced_blocks(inner):
        tier_block = inner[ts:te]

        label_m = re.search(r"\blabel\s*=\s*'([^']+)'", tier_block)
        cost_m  = re.search(r'\bcost\s*=\s*(\d+)', tier_block)
        if not (label_m and cost_m):
            continue

        tier_label = label_m.group(1)
        cost       = int(cost_m.group(1))

        # Parse titles sub-block
        titles_m = re.search(r'\btitles\s*=\s*\{', tier_block)
        titles: list[str] = []
        if titles_m:
            ts_suffix = tier_block[titles_m.start():]
            for tls, tle in _balanced_blocks(ts_suffix):
                titles_block = ts_suffix[tls:tle]
                for es, ee in _balanced_blocks(titles_block[1:-1]):
                    entry = titles_block[1:-1][es:ee]
                    tlabel_m = re.search(r"\blabel\s*=\s*'([^']+)'", entry)
                    if tlabel_m:
                        titles.append(tlabel_m.group(1))
                break

        if titles:
            tiers.append({'label': tier_label, 'cost': cost, 'titles': titles})

    return tiers


def _render_warpman(tiers: list[dict]) -> str:
    lines = [
        "| Tier | Cost | Destinations |",
        "|---|---:|---|",
    ]
    for t in tiers:
        dests = " · ".join(t["destinations"])
        lines.append(f"| {t['label']} | {t['cost']:,} gil | {dests} |")
    return "\n".join(lines)


def _render_title_broker(tiers: list[dict]) -> str:
    lines: list[str] = []
    for tier in tiers:
        # Strip the "(cost)" suffix from tier labels like "Cheap (10k)" for cleaner headers
        clean = re.sub(r'\s*\(\d+[kKmM]?\)\s*$', '', tier['label']).strip()
        lines.append(f"**{clean}** — {tier['cost']:,} gil each")
        lines.append("")
        lines.append("| Title |")
        lines.append("|---|")
        for title in tier['titles']:
            lines.append(f"| {title} |")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


# ---------------------------------------------------------------------------
# Gil Exchange parsers + renderer (writes into server-features.md)
# ---------------------------------------------------------------------------

def _parse_gil_exchange_bundles(text: str) -> list[dict]:
    """Return list of {gil, marks} from config.bundles in gil_exchange_npc.lua."""
    m = re.search(r'\bbundles\s*=\s*\{', text)
    if not m:
        return []
    for start, end in _balanced_blocks(text[m.start():]):
        bundles_block = text[m.start():][start:end]
        break
    else:
        return []

    bundles = []
    for es, ee in _balanced_blocks(bundles_block[1:-1]):
        entry = bundles_block[1:-1][es:ee]
        gil_m   = re.search(r'\bgil\s*=\s*(\d+)', entry)
        marks_m = re.search(r'\bmarks\s*=\s*(\d+)', entry)
        if not (gil_m and marks_m):
            continue
        bundles.append({"gil": int(gil_m.group(1)), "marks": int(marks_m.group(1))})
    return bundles


def _render_gil_exchange(bundles: list[dict]) -> str:
    lines = [
        "| Gil | Hunt Marks |",
        "|---:|---:|",
    ]
    for b in bundles:
        lines.append(f"| {b['gil']:,} | {b['marks']} |")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# EXP Camp Moogle parser + renderer
# ---------------------------------------------------------------------------

def _parse_exp_camps(text: str) -> list[dict]:
    """Return [{level, dest}] from the `camps = { {label=...}, ... }` table in
    ExpCamp_Moogle.lua. Each label is 'NN-MM Zone Name'; split the leading
    level range off the destination. Handles single- AND double-quoted labels
    (e.g. "Crawler's Nest")."""
    m = re.search(r'\bcamps\s*=\s*\{', text)
    if not m:
        return []
    for start, end in _balanced_blocks(text[m.start():]):
        camps_block = text[m.start():][start:end]
        break
    else:
        return []

    camps: list[dict] = []
    for es, ee in _balanced_blocks(camps_block[1:-1]):
        entry = camps_block[1:-1][es:ee]
        label_m = re.search(r'''\blabel\s*=\s*(['"])(.*?)\1''', entry)
        if not label_m:
            continue
        label = label_m.group(2)
        lvl_m = re.match(r'\s*(\d+\s*-\s*\d+)\s+(.*)', label)
        if lvl_m:
            camps.append({"level": lvl_m.group(1).replace(" ", ""), "dest": lvl_m.group(2).strip()})
        else:
            camps.append({"level": "", "dest": label})
    return camps


def _render_exp_camps(camps: list[dict]) -> str:
    lines = [
        "| Level | Camp |",
        "|---|---|",
    ]
    for c in camps:
        lines.append(f"| {c['level']} | {c['dest']} |")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Welcome Moogle (modules/custom/lua/welcome_moogle_catalog.lua +
# modules/custom/lua/Welcome_Moogle.lua). Full linked stock listing: the free
# starter-gift set, then every level-gated ware with its two fixed augments.
# ---------------------------------------------------------------------------

_WM_AUG_RE = re.compile(
    r"(\w+)\s*=\s*function\(\)\s*return\s*\{\s*id\s*=\s*\d+,\s*value\s*=\s*\d+,\s*label\s*=\s*'([^']+)'\s*\}")
_WM_ITEM_RE = re.compile(
    r"item\(\s*(\d+)\s*,\s*(?:'([^']+)'|\"([^\"]+)\")\s*,\s*'(\w+)'\s*,\s*'(\w+)'\s*\)")
_WM_GIFT_RE = re.compile(
    r"\{\s*id\s*=\s*(\d+),\s*name\s*=\s*(?:'([^']+)'|\"([^\"]+)\")\s*\}")
_WM_CAT_RE = re.compile(r"^( {8})(\w+) =\s*$")
_WM_SUB_RE = re.compile(r"^( {12})(?:(\w+)|\['([^']+)'\]) =\s*$")


def _parse_welcome_moogle(cat_text: str, npc_text: str) -> dict | None:
    augs = dict(_WM_AUG_RE.findall(cat_text))
    price_m = re.search(r"price\s*=\s*(\d+)", cat_text)
    lvl_m = re.search(r"MIN_LEVEL\s*=\s*(\d+)", npc_text)
    if not augs or not price_m or not lvl_m:
        return None

    gifts_block = cat_text.split("starterGifts", 1)[-1].split("categoryOrder", 1)[0]
    gifts = [(int(g[0]), g[1] or g[2]) for g in _WM_GIFT_RE.findall(gifts_block)]

    # Walk the wares table line-by-line, tracking the current category (8-space
    # indent) and subcategory (12-space indent) headers above each item() row.
    wares_block = cat_text.split("wares =", 1)[-1]
    sections: list[tuple[str, str, list]] = []   # (category, subcategory, items)
    cat = sub = None
    for line in wares_block.splitlines():
        cm = _WM_CAT_RE.match(line)
        if cm:
            cat = cm.group(2)
            continue
        sm = _WM_SUB_RE.match(line)
        if sm:
            sub = sm.group(2) or sm.group(3)
            sections.append((cat, sub, []))
            continue
        im = _WM_ITEM_RE.search(line)
        if im and sections:
            item_id = int(im.group(1))
            name = im.group(2) or im.group(3)
            a1, a2 = augs.get(im.group(4)), augs.get(im.group(5))
            if a1 is None or a2 is None:
                return None      # unknown augment key -> fail closed
            sections[-1][2].append((item_id, name, a1, a2))

    total = sum(len(s[2]) for s in sections)
    if len(gifts) < 3 or total < 20:
        return None
    return {
        "gifts": gifts, "sections": sections, "total": total,
        "price": int(price_m.group(1)), "min_level": int(lvl_m.group(1)),
        "exp_count": sum(1 for s in sections for it in s[2] if "EXP" in it[2] or "EXP" in it[3]),
    }


def _wm_link(item_id: int, name: str) -> str:
    page_url, image_url = urls_for_item(name, None, item_id=item_id)
    return (f'<a class="item-link" href="{page_url}" data-img="{image_url}" '
            f'target="_blank" rel="noopener">{name.replace("|", "&#124;")}</a>')


def _render_welcome_moogle(d: dict) -> str:
    gift_links = ", ".join(f"**{_wm_link(i, n)}**" for i, n in d["gifts"])
    out = [
        f"The festive **Welcome Moogle** is the first stop for a new character. The "
        f"first time you speak to it — at any level — it hands over a free gift set: "
        f"{gift_links}. Once per character; if your inventory is full, make room and "
        f"speak to it again.",
        "",
        f"Return on a main job of **level {d['min_level']} or higher** to browse its "
        f"starter racks: **{d['total']} curated pieces**, every one "
        f"**{d['price']:,} gil**, each with exactly **two fixed, low-tier augments**. "
        f"Pick a category and section to open the standard buy/sell shop window; hover "
        f"an item there to inspect its normal equipment stats. The shop only shows "
        f"equipment that the character's current main job can use, so change jobs "
        f"before speaking to the moogle to browse another job's set. {d['exp_count']} "
        f"accessories carry **EXP +15%** as a leveling teaser. All wares are Rare/Ex "
        f"— they cannot be traded, auctioned, delivered, sent to another character, "
        f"or sold back to an NPC.",
    ]
    for cat, sub, items in d["sections"]:
        if not items:
            continue
        out += ["", f"**{cat} — {sub}**", "", "| Item | Fixed augments |", "|---|---|"]
        for item_id, name, a1, a2 in items:
            out.append(f"| {_wm_link(item_id, name)} | {a1} · {a2} |")
    return "\n".join(out)


def generate(repo_root: Path, docs_dir: Path) -> None:
    page = docs_dir / "progression" / "gm-home.md"
    if not page.exists():
        print(f"[gm_home] skip: target page {page} not found")
        return

    # --- Welcome Moogle ---
    wm_cat = resolve_source(repo_root, "modules/custom/lua/welcome_moogle_catalog.lua", required=False)
    wm_npc = resolve_source(repo_root, "modules/custom/lua/Welcome_Moogle.lua", required=False)
    if wm_cat is None or wm_npc is None:
        print("[gm_home] skip welcome-moogle: catalog or NPC lua not found")
    else:
        wm = _parse_welcome_moogle(
            wm_cat.read_text(encoding="utf-8", errors="replace"),
            wm_npc.read_text(encoding="utf-8", errors="replace"))
        if wm is None:
            print("[gm_home] WARN welcome-moogle: parse failed or degraded — block not rewritten")
        elif write_between_markers(page, "gm-home-welcome-moogle", _render_welcome_moogle(wm)):
            print(f"[gm_home] welcome-moogle: {len(wm['gifts'])} gifts + {wm['total']} wares written into marker")
        else:
            print(f"[gm_home] welcome-moogle: marker 'gm-home-welcome-moogle' not found in {page.name}")

    # --- Test Dummy ---
    dummy_src = resolve_source(repo_root, "modules/custom/lua/test_dummy_catalog.lua", required=False)
    if dummy_src is None:
        print("[gm_home] skip test-dummy: test_dummy_catalog.lua not found")
    else:
        dummy_text  = dummy_src.read_text(encoding="utf-8", errors="replace")
        # Catalog now splits targets into two ordered families (ascension +
        # abyssea); concatenate them in display order. (Old single tierOrder
        # was replaced 2026-06-19.)
        order = (_parse_tier_order(dummy_text, "ascensionOrder")
                 + _parse_tier_order(dummy_text, "abysseaOrder"))
        dummy_tiers = _parse_test_dummy_tiers(dummy_text, order)
        dummy_content = _render_test_dummy(dummy_tiers)
        wrote = write_between_markers(page, "gm-home-test-dummy", dummy_content)
        if wrote:
            print(f"[gm_home] test-dummy: {len(dummy_tiers)} tiers written into marker")
        else:
            print(f"[gm_home] test-dummy: marker 'gm-home-test-dummy' not found in {page.name}")

    # --- Mystery Mog ---
    mog_src = resolve_source(repo_root, "modules/custom/lua/gil_mystery_box_catalog.lua", required=False)
    if mog_src is None:
        print("[gm_home] skip mystery-mog: gil_mystery_box_catalog.lua not found")
    else:
        mog_text     = mog_src.read_text(encoding="utf-8", errors="replace")
        pull_cost    = _parse_int(mog_text, "pullCost")    or 100000
        triple_cost  = _parse_int(mog_text, "tripleCost")  or 270000
        deca_cost    = _parse_int(mog_text, "decaCost")    or 900000
        premium_cost = _parse_int(mog_text, "premiumCost") or 500000
        pool         = _parse_pool_entries(mog_text, "pool")
        premium_pool = _parse_pool_entries(mog_text, "premiumPool")
        mog_content  = _render_mystery_mog(pull_cost, triple_cost, deca_cost, premium_cost, pool, premium_pool)
        wrote = write_between_markers(page, "gm-home-mystery-mog", mog_content)
        if wrote:
            print(f"[gm_home] mystery-mog: {len(pool)} standard + {len(premium_pool)} premium entries written into marker")
        else:
            print(f"[gm_home] mystery-mog: marker 'gm-home-mystery-mog' not found in {page.name}")

    # --- Warpman ---
    warp_src = resolve_source(repo_root, "modules/custom/lua/gil_warp_npc_catalog.lua", required=False)
    if warp_src is None:
        print("[gm_home] skip warpman: gil_warp_npc_catalog.lua not found")
    else:
        warp_text    = warp_src.read_text(encoding="utf-8", errors="replace")
        pricing      = _parse_pricing(warp_text)
        warp_tiers   = _parse_warp_tiers(warp_text, pricing)
        warp_content = _render_warpman(warp_tiers)
        wrote = write_between_markers(page, "gm-home-warpman", warp_content)
        if wrote:
            print(f"[gm_home] warpman: {len(warp_tiers)} tiers written into marker")
        else:
            print(f"[gm_home] warpman: marker 'gm-home-warpman' not found in {page.name}")

    # --- Title Broker ---
    title_src = resolve_source(repo_root, "modules/custom/lua/gil_title_vendor_catalog.lua", required=False)
    if title_src is None:
        print("[gm_home] skip title-broker: gil_title_vendor_catalog.lua not found")
    else:
        title_text    = title_src.read_text(encoding="utf-8", errors="replace")
        title_tiers   = _parse_title_tiers(title_text)
        title_content = _render_title_broker(title_tiers)
        wrote = write_between_markers(page, "gm-home-title-broker", title_content)
        if wrote:
            total = sum(len(t['titles']) for t in title_tiers)
            print(f"[gm_home] title-broker: {total} titles across {len(title_tiers)} tiers written into marker")
        else:
            print(f"[gm_home] title-broker: marker 'gm-home-title-broker' not found in {page.name}")

    # --- EXP Camp Moogle ---
    camp_src = resolve_source(repo_root, "modules/custom/lua/ExpCamp_Moogle.lua", required=False)
    if camp_src is None:
        print("[gm_home] skip exp-camps: ExpCamp_Moogle.lua not found")
    else:
        camp_text    = camp_src.read_text(encoding="utf-8", errors="replace")
        camps        = _parse_exp_camps(camp_text)
        camp_content = _render_exp_camps(camps)
        wrote = write_between_markers(page, "gm-home-exp-camps", camp_content)
        if wrote:
            print(f"[gm_home] exp-camps: {len(camps)} camps written into marker")
        else:
            print(f"[gm_home] exp-camps: marker 'gm-home-exp-camps' not found in {page.name}")

    # --- Gil Exchange (writes into the server-features overview page) ---
    # The Gil Exchange rate bundles live only in gil_exchange_npc.lua and have
    # no section on gm-home.md, so the overview page (server-features.md) is the
    # single authoritative home for them. Generate the rate table there to keep
    # it from drifting away from the Lua catalog.
    features_page = docs_dir / "progression" / "server-features.md"
    gil_src = resolve_source(repo_root, "modules/custom/lua/gil_exchange_npc.lua", required=False)
    if gil_src is None:
        print("[gm_home] skip gil-exchange: gil_exchange_npc.lua not found")
    elif not features_page.exists():
        print(f"[gm_home] skip gil-exchange: target page {features_page} not found")
    else:
        gil_text     = gil_src.read_text(encoding="utf-8", errors="replace")
        gil_bundles  = _parse_gil_exchange_bundles(gil_text)
        gil_content  = _render_gil_exchange(gil_bundles)
        wrote = write_between_markers(features_page, "server-features-gil-exchange", gil_content)
        if wrote:
            print(f"[gm_home] gil-exchange: {len(gil_bundles)} bundles written into {features_page.name}")
        else:
            print(f"[gm_home] gil-exchange: marker 'server-features-gil-exchange' not found in {features_page.name}")
