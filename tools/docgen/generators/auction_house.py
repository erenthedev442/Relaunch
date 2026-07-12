"""Generate docs/economy/auction-house.md from the live market-maker config.

The relaunch Auction House is bot-run: tools/ah_market_maker.py (hourly at :30
via the Relaunch-AHBot task) keeps every non-iLevel piece of gear stocked at a
level-bracket price, keeps a hand-picked list of items (furniture etc.)
listed, and buys back player listings -- gear at its own table price, and ANY
other auctionable item at a layered floor (sale_fraction x recent market, else
npc_multiplier x vendor value). Everything on this page parses from
tools/ah_market_maker_config.json so the published numbers can never drift
from what the bot actually does (progression/server-features.md's smaller
ah-prices block reads the same file).

Markers: ah-overview, ah-gear-prices, ah-stocked-items, ah-buyback
"""
from __future__ import annotations

import json
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._bgwiki import item_anchor
from tools.docgen.generators.gear_finder import display_name


def _gear_rule(cfg: dict) -> dict | None:
    for r in cfg.get("rules", []):
        if r.get("type") == "non_ilvl_gear":
            return r
    return None


def _bracket_rows(rule: dict) -> list[tuple[str, int]]:
    mult = float(rule.get("price_multiplier", 1.0))
    rows, lo = [], 1
    for hi, price in rule.get("level_price_brackets", []):
        label = str(hi) if hi == lo else f"{lo}–{hi}"
        rows.append((label, int(price * mult)))
        lo = hi + 1
    return rows


def _overview(cfg: dict, rule: dict) -> str:
    maxlvl = rule.get("max_equip_level", 99)
    tq = rule.get("target_qty", 5)
    return (
        "Type **`!ah`** anywhere to open the Auction House — no trip to Jeuno "
        "required. On relaunch the AH is run by a **market-maker bot** (hourly "
        "restock pass) with three jobs:\n\n"
        f"1. **Always-stocked leveling gear** — every auctionable non-iLevel "
        f"weapon, armor, and accessory up to **level {maxlvl}** is kept listed "
        f"({tq} copies each) at the level-bracket prices below. No empty "
        "categories while leveling, ever.\n"
        "2. **Always-stocked specialty items** — a hand-picked list "
        "(furniture and more) stays on the boards at fixed prices.\n"
        "3. **Guaranteed buy-back** — the bot *buys* player listings too, so "
        "everything you farm has a price floor (details below).\n\n"
        "Bot listings you buy are a pure **gil sink** (no player is paid); "
        "when the bot buys *your* listing, the gil arrives in your **delivery "
        "box**. iLevel 119 endgame gear is not sold here — that's the "
        "[Gear Vendors](../progression/gear-vendors.md)."
    )


def _gear_prices(rule: dict) -> str:
    lines = ["The bot sells **and buys back** this gear at the same price — "
             "one number per equip-level bracket:", "",
             "| Equip Level | Price (buy or sell-back) |", "|---|---:|"]
    for label, price in _bracket_rows(rule):
        lines.append(f"| {label} | {price:,} gil |")
    return "\n".join(lines)


def _stocked_items(cfg: dict, repo_root: Path) -> str:
    id_names = _load_item_names(cfg, repo_root)
    lines = ["Beyond the gear rule, these items are kept listed at fixed "
             "prices (singles unless noted):", "",
             "| Item | Price |", "|---|---:|"]
    for it in sorted(cfg.get("items", []), key=lambda i: (i["sell_price"], i["name"])):
        name = id_names.get(it["itemid"], display_name(it["name"]))
        link = item_anchor(name, item_id=it["itemid"])
        stack = " (stack)" if it.get("stack") else ""
        lines.append(f"| {link}{stack} | {it['sell_price']:,} gil |")
    return "\n".join(lines)


def _load_item_names(cfg: dict, repo_root: Path) -> dict[int, str]:
    ids = {it["itemid"] for it in cfg.get("items", [])}
    names: dict[int, str] = {}
    src = resolve_source(repo_root, "sql/item_basic.sql", required=False)
    if src is None:
        return names
    import re
    for m in re.finditer(r"VALUES \((\d+),\d+,'([^']+)'",
                         src.read_text(encoding="utf-8", errors="replace")):
        iid = int(m.group(1))
        if iid in ids:
            names[iid] = display_name(m.group(2))
    return names


def _buyback(cfg: dict, rule: dict) -> str:
    ub = cfg.get("universal_buyback", {}) or {}
    maxlvl = rule.get("max_equip_level", 99)
    frac = ub.get("sale_fraction", 0.6)
    mins = ub.get("min_sales", 3)
    npc_mult = ub.get("npc_multiplier", 2.0)
    floor = ub.get("no_data_floor", 1000)
    lines = [
        f"**Leveling gear (≤ level {maxlvl}):** list a piece at or below its "
        "table price above and the bot buys it, paying the full table price — "
        "even if you asked less. Every leveling piece has a guaranteed floor, "
        "so trying gear for a new job is risk-free.",
        "",
    ]
    if ub.get("enabled", True):
        lines += [
            "**Everything else:** the bot also buys back **any other "
            "auctionable item** at a layered floor price — whichever of these "
            "resolves first:",
            "",
            f"1. **Market floor** — if the item has at least {mins} recent "
            f"player sales, the bot pays **{frac:.0%} of its average sale "
            "price**.",
            f"2. **Vendor floor** — otherwise **{npc_mult:g}× its NPC sell "
            "value**.",
            f"3. **Minimum** — never less than **{floor:,} gil**.",
            "",
            "List at or below the floor and the bot takes it on its next "
            "hourly pass, paying to your delivery box. Ask more than the "
            "floor and your listing simply stays up for players.",
        ]
    return "\n".join(lines)


def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "tools/ah_market_maker_config.json")
    if src is None:
        print("[auction_house] skip: ah_market_maker_config.json not found")
        return
    try:
        cfg = json.loads(src.read_text(encoding="utf-8-sig"))
    except ValueError as exc:
        print(f"[auction_house] skip: config unreadable ({exc})")
        return
    rule = _gear_rule(cfg)
    if rule is None:
        print("[auction_house] skip: no non_ilvl_gear rule in config")
        return

    page = docs_dir / "economy" / "auction-house.md"
    blocks = [
        ("ah-overview",      _overview(cfg, rule)),
        ("ah-gear-prices",   _gear_prices(rule)),
        ("ah-stocked-items", _stocked_items(cfg, repo_root)),
        ("ah-buyback",       _buyback(cfg, rule)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[auction_house] {written}/{len(blocks)} blocks "
          f"({len(cfg.get('items', []))} stocked items, "
          f"{len(rule.get('level_price_brackets', []))} price brackets)")
