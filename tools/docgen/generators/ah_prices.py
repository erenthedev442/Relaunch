"""Generate the Always-Stocked Auction House price table on
docs/progression/server-features.md from the LIVE market-maker config
(tools/ah_market_maker_config.json), so the published prices can never drift
from what the bot actually lists. (They had drifted ~100-280x before this.)

Marker: id="ah-prices"
"""
from __future__ import annotations

import json
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers


def _level_label(lo: int, hi: int) -> str:
    # en-dash range, matching the rest of the docs (e.g. "11–20")
    return str(lo) if lo == hi else f"{lo}–{hi}"


def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "tools/ah_market_maker_config.json")
    if src is None:
        print("[ah_prices] skip: ah_market_maker_config.json not found")
        return

    try:
        # utf-8-sig: tolerate a BOM if the config was saved on Windows.
        cfg = json.loads(src.read_text(encoding="utf-8-sig"))
    except (OSError, ValueError) as e:
        print(f"[ah_prices] skip: could not parse config ({e})")
        return

    # The non_ilvl_gear rule carries the equip-level -> price brackets that the
    # bot lists (and buys back) the always-stocked leveling gear at.
    brackets = None
    price_multiplier = 1.0
    for rule in cfg.get("rules", []):
        if rule.get("type") == "non_ilvl_gear" and rule.get("level_price_brackets"):
            brackets = rule["level_price_brackets"]
            price_multiplier = float(rule.get("price_multiplier", 1.0))
            break

    if not brackets:
        # Loud failure rather than silently blanking a published table.
        raise RuntimeError(
            "[ah_prices] no non_ilvl_gear level_price_brackets found in "
            "ah_market_maker_config.json — config shape changed, check parser")

    # Each bracket is [max_level, price]; an item is priced at the first bracket
    # whose max_level >= its equip level, so the displayed range for bracket i is
    # (prev_max + 1) .. max_level.
    lines = ["| Equip Level | Price |", "|---|---|"]
    prev = 0
    for maxlvl, price in brackets:
        hi = int(maxlvl)
        actual = round(price * price_multiplier)
        lines.append(f"| {_level_label(prev + 1, hi)} | {actual:,} gil |")
        prev = hi

    content = "\n".join(lines)
    page = docs_dir / "progression" / "server-features.md"
    if write_between_markers(page, "ah-prices", content):
        print(f"[ah_prices] wrote {len(brackets)} price brackets into server-features.md")
    else:
        print('[ah_prices] marker id="ah-prices" not found in server-features.md — skipped')
