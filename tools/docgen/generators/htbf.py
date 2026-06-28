"""Sync docs/endgame/high-tier-battlefields.md with htbf_catalog.lua.

The High-Tier Battlefields (HTBF) system reuses retail story-boss battlefields,
re-gates them on a bought-for-gil Phantom Gem key item, and offers each as three
scaled difficulty tiers (I / II / III). Everything published here -- the gem
prices, the expansion groupings, the per-tier scaling and rewards, and the full
fight roster -- is read straight from the catalog so the page can't drift.

Markers written:
  htbf-access  -- the gem vendor NPC + where/how to buy Phantom Gems
  htbf-gems    -- the 16 gems grouped by expansion, with gil price each
  htbf-tiers   -- the 3 difficulty tiers (scaling + gil/Hunt-Mark rewards)
  htbf-fights  -- the 21 fights (label + zone + gem/expansion)
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section, commafy


# ── Zone token -> player-facing name ────────────────────────────────────────
# The catalog stores zones as `xi.zone.<TOKEN>`; the enum tokens lose the
# apostrophes/connectives, so fix the ones HTBF uses up to read naturally.
_ZONE_PRETTY = {
    "CLOISTER_OF_FLAMES":   "Cloister of Flames",
    "CLOISTER_OF_FROST":    "Cloister of Frost",
    "CLOISTER_OF_GALES":    "Cloister of Gales",
    "CLOISTER_OF_TREMORS":  "Cloister of Tremors",
    "CLOISTER_OF_STORMS":   "Cloister of Storms",
    "CLOISTER_OF_TIDES":    "Cloister of Tides",
    "MONARCH_LINN":         "Monarch Linn",
    "SEALIONS_DEN":         "Sealion's Den",
    "BONEYARD_GULLY":       "Boneyard Gully",
    "JADE_SEPULCHER":       "Jade Sepulcher",
    "TALACCA_COVE":         "Talacca Cove",
    "THRONE_ROOM":          "Throne Room",
    "STELLAR_FULCRUM":      "Stellar Fulcrum",
    "THE_CELESTIAL_NEXUS":  "The Celestial Nexus",
    "LALOFF_AMPHITHEATER":  "La'Loff Amphitheater",
}


def _titleize(token: str) -> str:
    return token.replace("_", " ").title()


def _zone_name(token: str) -> str:
    return _ZONE_PRETTY.get(token, _titleize(token))


# ── Parse ───────────────────────────────────────────────────────────────────

def _parse(text: str) -> dict:
    c: dict = {}

    # gemName: ki token -> display name. Values may be single- OR double-quoted
    # AND contain the *other* quote (e.g. "Savage's Phantom Gem"), so match the
    # opening quote type and read to its matching close -- a plain [^'"] class
    # would truncate "Savage's..." at the apostrophe.
    name_block = section(text, "catalog.gemName")
    gem_name = {tok: (sq or dq) for tok, sq, dq in
                re.findall(r"xi\.ki\.(\w+)\s*\]\s*=\s*(?:'([^']*)'|\"([^\"]*)\")",
                           name_block)}
    c["gem_name"] = gem_name

    # gemPrice: ki token -> gil.
    price_block = section(text, "catalog.gemPrice")
    gem_price = {tok: int(p) for tok, p in
                 re.findall(r"xi\.ki\.(\w+)\s*\]\s*=\s*(\d+)", price_block)}
    c["gem_price"] = gem_price

    # gemCategories: ordered list of { label, [gem tokens] }.
    cat_block = section(text, "catalog.gemCategories")
    cats = []
    for label, gems_chunk in re.findall(
            r"label\s*=\s*['\"]([^'\"]+)['\"]\s*,\s*gems\s*=\s*\{([^}]*)\}", cat_block):
        toks = re.findall(r"xi\.ki\.(\w+)", gems_chunk)
        cats.append({"label": label, "gems": toks})
    c["categories"] = cats

    # gem token -> its category label (for the fights table).
    gem_to_cat = {}
    for cat in cats:
        for tok in cat["gems"]:
            gem_to_cat[tok] = cat["label"]
    c["gem_to_cat"] = gem_to_cat

    # tierScale: [n] = { name, lvl, hp, att, def, macc, meva }.
    scale_block = section(text, "catalog.tierScale")
    tiers = {}
    for idx, body in re.findall(r"\[(\d+)\]\s*=\s*\{([^}]*)\}", scale_block):
        d = {}
        mn = re.search(r"name\s*=\s*['\"]([^'\"]+)['\"]", body)
        d["name"] = mn.group(1) if mn else idx
        for fld in ("lvl", "hp", "att", "def", "macc", "meva"):
            mf = re.search(rf"\b{fld}\s*=\s*([0-9.]+)", body)
            d[fld] = float(mf.group(1)) if mf else 0.0
        tiers[int(idx)] = d
    c["tiers"] = tiers

    # tierReward: [n] = { gil, marks }.
    reward_block = section(text, "catalog.tierReward")
    rewards = {}
    for idx, body in re.findall(r"\[(\d+)\]\s*=\s*\{([^}]*)\}", reward_block):
        mg = re.search(r"\bgil\s*=\s*(\d+)", body)
        mk = re.search(r"\bmarks\s*=\s*(\d+)", body)
        rewards[int(idx)] = {
            "gil": int(mg.group(1)) if mg else 0,
            "marks": int(mk.group(1)) if mk else 0,
        }
    c["rewards"] = rewards

    # fights: each top-level entry inside catalog.fights with zone/gem/label.
    fights_block = section(text, "catalog.fights")
    c["fights"] = _parse_fights(fights_block)

    return c


def _parse_fights(block: str) -> list[dict]:
    """Pull (label, zone token, gem token) for each fight entry. Entries are
    keyed by a bare identifier ( `the_savage = { ... }` )."""
    fights = []
    # Find each "<key> =" at the start of an entry, then slice its braced body.
    for m in re.finditer(r"(?m)^\s{4}(\w+)\s*=\s*\{", block):
        key = m.group(1)
        body = section(block[m.start():], key)
        if not body:
            continue
        # label may be single- or double-quoted and contain the other quote
        # ("The Warrior's Path") -- match the opening quote type, not [^'"].
        ml = re.search(r"label\s*=\s*(?:'([^']*)'|\"([^\"]*)\")", body)
        mz = re.search(r"zone\s*=\s*xi\.zone\.(\w+)", body)
        mg = re.search(r"\bgem\s*=\s*xi\.ki\.(\w+)", body)
        label = (ml.group(1) or ml.group(2)) if ml else _titleize(key)
        fights.append({
            "key": key,
            "label": label,
            "zone": mz.group(1) if mz else "",
            "gem": mg.group(1) if mg else "",
        })
    return fights


# ── Render ──────────────────────────────────────────────────────────────────

def _render_access(c: dict) -> str:
    return (
        "Buy your **Phantom Gem** from the **Phantom Gems** vendor in "
        "**Leafallia** (the relaunch hub). Each gem is a key item bought with "
        "gil; the vendor's menu is grouped by expansion so you can browse the "
        "full roster. Once you hold a gem, travel to that battlefield's zone, "
        "trade the gem at the entrance, and pick a difficulty tier (I / II / "
        "III).\n\n"
        "You can only hold one gem of a given type at a time, and entering a "
        "battlefield consumes it -- buy a fresh gem for each attempt."
    )


def _render_gems(c: dict) -> str:
    rows = [
        "| Expansion | Phantom Gem | Price |",
        "|---|---|---|",
    ]
    for cat in c["categories"]:
        for tok in cat["gems"]:
            name = c["gem_name"].get(tok, _titleize(tok))
            price = c["gem_price"].get(tok)
            price_s = f"{commafy(price)} gil" if price is not None else "—"
            rows.append(f"| {cat['label']} | **{name}** | {price_s} |")
    return "\n".join(rows)


def _render_tiers(c: dict) -> str:
    rows = [
        "| Tier | Difficulty | Reward |",
        "|---|---|---|",
    ]
    descriptions = {
        1: "A lightly-buffed take on the base fight — the entry tier.",
        2: "A serious step up in toughness and incoming damage.",
        3: "The wall — vastly more HP and punishing offense.",
    }
    for idx in sorted(c["tiers"]):
        t = c["tiers"][idx]
        r = c["rewards"].get(idx, {})
        hp_mult = t["hp"]
        hp_s = f"{hp_mult:g}× HP"
        desc = descriptions.get(idx, "")
        reward_bits = []
        if r.get("gil"):
            reward_bits.append(f"{commafy(r['gil'])} gil")
        if r.get("marks"):
            reward_bits.append(f"{r['marks']} Hunt Marks")
        reward_s = " + ".join(reward_bits) if reward_bits else "—"
        rows.append(
            f"| **Tier {t['name']}** | {desc} (~{hp_s}) | {reward_s} |"
        )
    return "\n".join(rows)


def _render_fights(c: dict) -> str:
    rows = [
        "| Battlefield | Zone | Phantom Gem (expansion) |",
        "|---|---|---|",
    ]
    for f in c["fights"]:
        zone = _zone_name(f["zone"]) if f["zone"] else "—"
        gem_name = c["gem_name"].get(f["gem"], _titleize(f["gem"])) if f["gem"] else "—"
        cat = c["gem_to_cat"].get(f["gem"], "")
        gem_s = f"{gem_name}" + (f" *({cat})*" if cat else "")
        rows.append(f"| **{f['label']}** | {zone} | {gem_s} |")
    return "\n".join(rows)


# ── Entry point ─────────────────────────────────────────────────────────────

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/htbf_catalog.lua")
    if src is None:
        print("[htbf] skip: htbf_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    c = _parse(text)

    page = docs_dir / "endgame" / "high-tier-battlefields.md"
    blocks = [
        ("htbf-access", _render_access(c)),
        ("htbf-gems", _render_gems(c)),
        ("htbf-tiers", _render_tiers(c)),
        ("htbf-fights", _render_fights(c)),
    ]
    written = sum(1 for marker, content in blocks
                  if write_between_markers(page, marker, content))
    print(f"[htbf] {written}/{len(blocks)} marker block(s) written "
          f"(gems={len(c['gem_price'])}, fights={len(c['fights'])}, "
          f"tiers={len(c['tiers'])})")
