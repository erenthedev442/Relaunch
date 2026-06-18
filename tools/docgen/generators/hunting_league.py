"""Generate Hunting League tables inside docs/progression/index.md.

Reads `modules/custom/lua/hunting_league_catalog.lua` and emits two table
blocks into marker IDs:
  - "hunting-league-tiers"   — tier list with mobs and point values
  - "hunting-league-rewards" — reward shop

The catalog file is normally gitignored (modules/custom/ is not committed),
so this generator usually runs against `$LEGENDARY_LIVE_ROOT`. CI without
that env var will skip cleanly.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers


# Captures a Lua string literal in single OR double quotes, handling backslash
# escapes inside single-quoted strings (e.g. 'Epona\'s Ring').
_QUOTED = r"(?:'((?:[^'\\]|\\.)*)'|\"([^\"]*)\")"
_CURRENCY_RE = re.compile(r"\bcurrencyName\s*=\s*" + _QUOTED)


def _quoted_value(m: re.Match) -> str:
    raw = m.group(1) if m.group(1) is not None else m.group(2)
    return raw.replace("\\'", "'").replace('\\"', '"').replace("\\\\", "\\")


def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/hunting_league_catalog.lua")
    if src is None:
        print("[hunting_league] skip: hunting_league_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    cm = _CURRENCY_RE.search(text)
    currency = _quoted_value(cm) if cm else "Marks"

    page = docs_dir / "progression" / "index.md"

    # Per-section build with sanity guards. If a parser silently returns an
    # empty result while the source clearly has entry-shaped content, raise
    # so the broken section keeps its existing published content instead of
    # publishing "_No ... parsed from the catalog._" as a regression.

    def _build_tiers():
        tiers = _extract_tiers(text)
        # Signal: count `tier = N` field appearances. If the file has tier
        # entries but we extracted zero, a required field name probably
        # changed (e.g. `unlockCost` → `unlockPrice`).
        tier_signals = len(re.findall(r"\btier\s*=\s*\d+", text))
        if tier_signals > 0 and not tiers:
            raise RuntimeError(
                f"hunting_league_catalog.lua has {tier_signals} `tier = N` "
                f"signals but _extract_tiers returned zero ranks. A required "
                f"field (tier/name/unlockCost/mobs) was probably renamed -- "
                f"update _extract_tiers in this generator."
            )
        return _render_tiers(tiers, currency), tiers

    def _build_rewards():
        categories = _extract_rewards(text)
        total_items = sum(len(c["items"]) for c in categories)
        # Signal: the `rewardCategories` anchor plus `cost = N` entries. If
        # the catalog clearly has priced items but we extracted none, a field
        # name probably changed (rewardCategories/label/items/cost).
        reward_signals = len(re.findall(r"\bcost\s*=\s*\d+", text))
        if "rewardCategories" in text and reward_signals > 0 and total_items == 0:
            raise RuntimeError(
                f"hunting_league_catalog.lua has a rewardCategories section "
                f"with {reward_signals} `cost = N` signals but _extract_rewards "
                f"returned zero items. Reward entry field names probably "
                f"changed -- update _extract_rewards."
            )
        return _render_rewards(categories, currency), categories

    def _section(marker: str, build_content):
        try:
            content, parsed = build_content()
        except Exception as e:
            print(f"[hunting_league] {marker}: PARSER REGRESSION -- {e}")
            print(f"[hunting_league] {marker}: keeping existing published content")
            return None
        wrote = write_between_markers(page, marker, content)
        if not wrote:
            print(f"[hunting_league] {marker}: skipped (markers not found in {page.name})")
        return parsed if wrote else None

    tiers_parsed = _section("hunting-league-tiers", _build_tiers)
    rewards_parsed = _section("hunting-league-rewards", _build_rewards)

    if tiers_parsed is not None:
        total_mobs = sum(len(t["mobs"]) for t in tiers_parsed)
        print(
            f"[hunting_league] tiers: {len(tiers_parsed)} ranks, "
            f"{total_mobs} mobs written into markers"
        )
    if rewards_parsed is not None:
        total_items = sum(len(c["items"]) for c in rewards_parsed)
        print(
            f"[hunting_league] rewards: {len(rewards_parsed)} categories, "
            f"{total_items} items written into markers"
        )


def _balanced_blocks(text: str):
    """Yield (start, end_exclusive) for each top-level {...} block in text.

    Handles nested braces, Lua `--` line comments, and both single- and
    double-quoted strings (with backslash escapes)."""
    depth = 0
    start = None
    i = 0
    n = len(text)
    while i < n:
        c = text[i]
        # Lua line comment: skip to end of line. (Doesn't handle Lua's long
        # comments `--[[ ... ]]` — none in the catalog.)
        if c == "-" and i + 1 < n and text[i + 1] == "-":
            nl = text.find("\n", i)
            if nl == -1:
                break
            i = nl + 1
            continue
        # Quoted string: skip until matching close quote, respecting escapes
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


def _extract_tiers(text: str) -> list[dict]:
    m = re.search(r"\btiers\s*=\s*", text)
    if not m:
        return []
    remaining = text[m.end():]
    outer = next(_balanced_blocks(remaining), None)
    if outer is None:
        return []
    tiers_block = remaining[outer[0] + 1: outer[1] - 1]

    tiers = []
    name_re = re.compile(r"\bname\s*=\s*" + _QUOTED)
    label_re = re.compile(r"\blabel\s*=\s*" + _QUOTED)
    for ts, te in _balanced_blocks(tiers_block):
        body = tiers_block[ts + 1: te - 1]
        tier_num = re.search(r"\btier\s*=\s*(\d+)", body)
        tier_name = name_re.search(body)
        unlock = re.search(r"\bunlockCost\s*=\s*(\d+)", body)
        if not (tier_num and tier_name and unlock):
            continue

        mobs_match = re.search(r"\bmobs\s*=\s*", body)
        mobs = []
        if mobs_match:
            mobs_remaining = body[mobs_match.end():]
            mobs_outer = next(_balanced_blocks(mobs_remaining), None)
            if mobs_outer is not None:
                mobs_inner = mobs_remaining[mobs_outer[0] + 1: mobs_outer[1] - 1]
                for ms, me in _balanced_blocks(mobs_inner):
                    mob_body = mobs_inner[ms + 1: me - 1]
                    nm = name_re.search(mob_body)
                    lbl = label_re.search(mob_body)
                    pts = re.search(r"\bpoints\s*=\s*(\d+)", mob_body)
                    if nm and lbl and pts:
                        mobs.append({
                            "name": _quoted_value(nm).replace("_", " "),
                            "label": _quoted_value(lbl),
                            "points": int(pts.group(1)),
                        })

        tiers.append({
            "tier": int(tier_num.group(1)),
            "name": _quoted_value(tier_name),
            "unlockCost": int(unlock.group(1)),
            "mobs": mobs,
        })
    tiers.sort(key=lambda t: t["tier"])
    return tiers


def _extract_rewards(text: str) -> list[dict]:
    """Parse `rewardCategories = { {label=..., items={...}}, ... }`.

    The Hub reward shop is organized into named categories (Seals,
    Sortie: NQ/+1/+2, ...). Returns them in catalog order:
        [{'label': str, 'items': [{'name': str, 'cost': int}]}]

    Mirrors accessories_npc._extract_categories, but keeps only the two
    fields this page's compact per-category summary needs (name + cost).
    NOTE: the field is `rewardCategories`, not `rewards` — the older name
    silently produced an empty shop block here until this was fixed.
    """
    m = re.search(r"\brewardCategories\s*=\s*", text)
    if not m:
        return []
    remaining = text[m.end():]
    outer = next(_balanced_blocks(remaining), None)
    if outer is None:
        return []
    outer_inner = remaining[outer[0] + 1: outer[1] - 1]

    name_re = re.compile(r"\bname\s*=\s*" + _QUOTED)
    label_re = re.compile(r"\blabel\s*=\s*" + _QUOTED)
    cost_re = re.compile(r"\bcost\s*=\s*(\d+)")

    categories: list[dict] = []
    for cs, ce in _balanced_blocks(outer_inner):
        cat_body = outer_inner[cs + 1: ce - 1]
        label_m = label_re.search(cat_body)
        if not label_m:
            continue
        label = _quoted_value(label_m)

        items: list[dict] = []
        items_m = re.search(r"\bitems\s*=\s*", cat_body)
        if items_m:
            items_remaining = cat_body[items_m.end():]
            items_outer = next(_balanced_blocks(items_remaining), None)
            if items_outer is not None:
                items_inner = items_remaining[items_outer[0] + 1: items_outer[1] - 1]
                for is_, ie in _balanced_blocks(items_inner):
                    ibody = items_inner[is_ + 1: ie - 1]
                    nm = name_re.search(ibody)
                    cost = cost_re.search(ibody)
                    if nm and cost:
                        items.append({
                            "name": _quoted_value(nm),
                            "cost": int(cost.group(1)),
                        })
        categories.append({"label": label, "items": items})
    return categories


def _escape_md(s: str) -> str:
    return s.replace("|", "\\|").replace("\n", " ")


def _render_tiers(tiers: list[dict], currency: str) -> str:
    if not tiers:
        return "_No tier data parsed from the catalog._"
    lines = []
    for t in tiers:
        lines.append(f"### {t['name']}")
        lines.append("")
        unlock_line = f"**Unlock cost:** {t['unlockCost']} {currency}"
        if t["mobs"]:
            per_kill = t["mobs"][0]["points"]
            if all(m["points"] == per_kill for m in t["mobs"]):
                unlock_line += f"  ·  **{currency} per kill:** {per_kill}"
        lines.append(unlock_line)
        lines.append("")
        if t["mobs"]:
            lines.append("| NM | Points |")
            lines.append("|---|---:|")
            for m in t["mobs"]:
                lines.append(f"| {_escape_md(m['label'])} | {m['points']} |")
        lines.append("")
    return "\n".join(lines).rstrip()


def _render_rewards(categories: list[dict], currency: str) -> str:
    if not categories:
        return "_No reward shop data parsed from the catalog._"

    total_items = sum(len(c["items"]) for c in categories)
    lines = [
        f"The reward shop is organized into {len(categories)} categories — "
        f"{total_items} purchasable entries in all, every price in {currency}. "
        f"The **Seals** category converts marks into the Bronze/Silver/Gold "
        f"seals you spend at the Armor and Weapons vendors, while the "
        f"**Sortie** categories sell job earrings. The full per-item earring "
        f"list lives on the [Gear Vendors](gear-vendors.md) page.",
        "",
        f"| Category | Items | Cost each ({currency}) |",
        "|---|---:|---:|",
    ]
    for cat in categories:
        items = cat["items"]
        if not items:
            lines.append(f"| {_escape_md(cat['label'])} | 0 | — |")
            continue
        costs = [it["cost"] for it in items]
        lo, hi = min(costs), max(costs)
        cost_str = f"{lo:,}" if lo == hi else f"{lo:,}–{hi:,}"
        lines.append(f"| {_escape_md(cat['label'])} | {len(items)} | {cost_str} |")
    return "\n".join(lines)
