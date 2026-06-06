"""Auto-promote the absolute BiS picks into the Infamy Vendor.

Reads the three scored catalogs:
    modules/custom/lua/armor_catalog.lua          (Armor NPC)
    modules/custom/lua/accessory_catalog.lua      (Accessory NPC)
    modules/custom/lua/gear_progression_catalog.lua (Weapons NPC)

Each scored row carries a trailing comment in the shape:
    -- {DD|TANK|CASTER|HEAL} score N
This script reads the catalog.infamy tier of each catalog — the top 5 per
slot / weapon category that score_armor.py and score_weapons.py skim out
of the gold gear vendor, plus the 22 Sortie JSE +2 earrings from
score_accessories.py — and writes them all as a catalog.vendorItemsAuto
block in dungeon_catalog.lua between the `-- DOCGEN:INFAMY_AUTO:BEGIN` and
`:END` sentinels. Gear is priced by score percentile; earrings flat.

The existing hand-curated catalog.vendorItems list is left untouched —
both lists are concatenated by the Dungeon Infamy Vendor's curated
browser at runtime. Adding new hand-picked items still happens in
dungeon_catalog.lua directly; the auto block is just additional supply.

Re-run after any of:
    * tools/score_armor.py / score_weapons.py / score_accessories.py
    * The TOP_N / cost tiers below
    * The auto-block marker location in dungeon_catalog.lua
"""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(r"D:/server")

ARMOR_LUA       = ROOT / "modules" / "custom" / "lua" / "armor_catalog.lua"
ACCESSORY_LUA   = ROOT / "modules" / "custom" / "lua" / "accessory_catalog.lua"
WEAPONS_LUA     = ROOT / "modules" / "custom" / "lua" / "gear_progression_catalog.lua"
DUNGEON_LUA     = ROOT / "modules" / "custom" / "lua" / "dungeon_catalog.lua"

# The Infamy Vendor's auto-promoted list is bounded by the scorers
# themselves: score_armor.py / score_weapons.py emit the top 5 per slot /
# weapon category into catalog.infamy, and score_accessories.py emits the
# 22 Sortie JSE +2 earrings. So there's NO global TOP_N / per-source cap
# here — we promote everything in the catalog.infamy tier. Gear is priced
# by score percentile (below); the Sortie earrings get a flat price.
EARRING_COST = 300   # flat Infamy price for each Sortie +2 earring
# The 22 Sortie JSE +2 earrings (Boii..Erilaz, ids 25422..25548 step 6). The
# accessory catalog.infamy tier now ALSO carries score-based top-5-per-slot BiS
# accessories, so we tell the earrings (flat price, score-can't-place override)
# apart from scored accessories (priced like gear) by id.
SORTIE_EARRING_IDS = set(range(25422, 25549, 6))

# Infamy cost tiers based on percentile of the picked set.
# Top quintile pays the most because those are the absolute BiS picks
# (Sanctity Necklace tier); bottom quintile is "Gold tier ceiling" and
# costs less.
COST_BY_PERCENTILE = [
    (0.20, 800),   # top 20% — super premium
    (0.50, 500),
    (0.80, 350),
    (1.00, 250),
]

# Catalog row regex. Handles BOTH catalog shapes:
#   table.insert(b.head, { id = ..., name = ..., cost = ..., jobs = ... })  ← armor / accessory
#   table.insert(swords, { id = ..., name = ..., cost = ..., jobs = ... })  ← weapons
# Group 1: var (b/s/g for armor+accessory, weapon-category for weapons).
# Group 2: slot (head/body/...) for armor+accessory; None for weapons.
# Weapons rows: the slot is derived from the var name post-match (var
# `swords` → slot label `Swords`, etc).
# The trailing comment carries role + score and may have extra fields
# (e.g. weapons: "DD score 91, DMG 143/Dly 264") — the regex stops at
# the score number, ignoring anything after.
_ROW_RE = re.compile(
    r"table\.insert\(\s*(\w+)(?:\.(\w+))?\s*,\s*\{\s*"
    r"id\s*=\s*(\d+)\s*,\s*"
    r"name\s*=\s*['\"]([^'\"]+)['\"]\s*,\s*"
    r"cost\s*=\s*\d+\s*,\s*"
    r"jobs\s*=\s*['\"]([^'\"]+)['\"]\s*\}\s*\)"
    r"\s*--\s*(DD|TANK|CASTER|HEAL)\s+score\s+(\d+)",
)
# Match BOTH binding shapes in the wild:
#   local b = catalog.bronze                            ← armor + accessory
#   local swords = cat(catalog.bronze.weapons, 'Swords') ← weapons
# Capture group 1 is the short var name; group 2 is the tier name.
# The `[^=\n]*?` clause tolerates anything between `=` and `catalog.`
# without crossing line boundaries (avoiding false matches across
# multiple bindings).
_BIND_RE = re.compile(r"local\s+(\w+)\s*=[^=\n]*?catalog\.(\w+)\b")


def parse_catalog(path: Path, source_label: str) -> list[dict]:
    """Return one dict per scored row in the catalog.infamy tier."""
    if not path.exists():
        print(f"  [skip] {path.name}: file not found")
        return []
    text = path.read_text(encoding="utf-8", errors="replace")

    # var → tier name (e.g. "g" → "gold").
    var_to_tier: dict[str, str] = {}
    for m in _BIND_RE.finditer(text):
        var_to_tier[m.group(1)] = m.group(2)

    rows: list[dict] = []
    for m in _ROW_RE.finditer(text):
        var, slot = m.group(1), m.group(2)
        tier = var_to_tier.get(var)
        if tier != "infamy":
            continue
        # Slot derivation:
        #   * Armor/Accessory rows: group(2) captured the explicit slot
        #     (head/body/.../neck/back) — use it as-is.
        #   * Weapons rows: group(2) is None and the var IS the weapon
        #     category. Convert "swords" → "Swords", "greatswords" →
        #     "Great Swords", "h2h" → "H2H", "gkatana" → "Great Katana"
        #     so the rendered Infamy Vendor entry reads naturally.
        if slot is None:
            # cat() call's second arg carries the human-readable label,
            # but we don't have it captured. Fall back to var-name
            # heuristics. Hand-map the common cases that don't camelize
            # cleanly from snake_case.
            slot_special = {
                "h2h":         "H2H",
                "gkatana":     "Great Katana",
                "greatswords": "Great Swords",
                "greataxes":   "Great Axes",
            }
            # Infamy weapon vars carry an 'inf_' prefix (see score_weapons.py)
            # to stay unambiguous; strip it before deriving the label.
            base_var = var[4:] if var.startswith("inf_") else var
            slot = slot_special.get(base_var, base_var.title())
        rows.append({
            "id":     int(m.group(3)),
            "name":   m.group(4),
            "slot":   slot,
            "jobs":   m.group(5),
            "role":   m.group(6),
            "score":  int(m.group(7)),
            "source": source_label,
        })
    print(f"  {path.name}: {len(rows)} Infamy-tier rows parsed")
    return rows


def compute_cost(rank: int, total: int) -> int:
    """Bucket the rank/total ratio into COST_BY_PERCENTILE bands."""
    if total <= 0:
        return COST_BY_PERCENTILE[-1][1]
    pct = rank / total
    for threshold, cost in COST_BY_PERCENTILE:
        if pct <= threshold:
            return cost
    return COST_BY_PERCENTILE[-1][1]


def lua_q(s: str) -> str:
    return "'" + s.replace("\\", "\\\\").replace("'", "\\'") + "'"


def main() -> None:
    print("Parsing the catalog.infamy tier of each scored catalog...")
    rows: list[dict] = []
    rows += parse_catalog(ARMOR_LUA,     "Armor")
    rows += parse_catalog(ACCESSORY_LUA, "Accessory")
    rows += parse_catalog(WEAPONS_LUA,   "Weapons")

    if not rows:
        print("\nNo Infamy-tier rows found in any catalog. Did you run "
              "tools/rebalance_all.bat (the score_*.py scorers emit the "
              "catalog.infamy blocks)? Refusing to write an empty auto block.")
        return

    # Dedupe by item id (an item can't be promoted twice). Order-independent.
    seen_ids: set[int] = set()
    deduped: list[dict] = []
    for r in rows:
        if r["id"] in seen_ids:
            continue
        seen_ids.add(r["id"])
        deduped.append(r)

    # Skip anything already in the hand-curated catalog.vendorItems list so the
    # Infamy vendor never shows the same item twice (curated + auto). The
    # curated list is authoritative for whatever it already includes. We read
    # only the vendorItems block (up to the auto sentinel) so the previous run's
    # auto ids don't count as "curated".
    dtext = DUNGEON_LUA.read_text(encoding="utf-8")
    vi = re.search(r"catalog\.vendorItems\s*=", dtext)
    curated_ids: set[int] = set()
    if vi:
        stop = dtext.find("-- DOCGEN:INFAMY_AUTO:BEGIN", vi.end())
        if stop == -1:
            stop = dtext.find("catalog.vendorItemsAuto", vi.end())
        block = dtext[vi.end(): stop if stop != -1 else len(dtext)]
        curated_ids = {int(m.group(1)) for m in re.finditer(r"\bid\s*=\s*(\d+)", block)}
    n_before = len(deduped)
    deduped = [r for r in deduped if r["id"] not in curated_ids]
    if n_before != len(deduped):
        print(f"  Skipped {n_before - len(deduped)} item(s) already in the "
              f"curated vendorItems list.")

    # Split scored gear (Armor/Weapons, top-5-per-slot) from the Sortie
    # earrings (Accessory). Gear is priced by score percentile — premium for
    # the absolute peak picks. The Sortie +2 earrings score 0–63 on the role
    # algorithm (BiS for one job, not high on a generic scale), so they get a
    # flat mid price instead of being dumped into the cheapest band.
    gear = sorted(
        (r for r in deduped if r["source"] in ("Armor", "Weapons")
         or (r["source"] == "Accessory" and r["id"] not in SORTIE_EARRING_IDS)),
        key=lambda r: -r["score"])
    earrings = [r for r in deduped
                if r["source"] == "Accessory" and r["id"] in SORTIE_EARRING_IDS]

    final: list[dict] = []
    for i, r in enumerate(gear):
        r = dict(r); r["cost"] = compute_cost(i, len(gear))
        final.append(r)
    for r in earrings:
        r = dict(r); r["cost"] = EARRING_COST
        final.append(r)

    print(f"\nInfamy auto-promotion: {len(gear)} gear (top-5/slot) + "
          f"{len(earrings)} Sortie earrings = {len(final)} items")
    for r in final:
        print(f"  {r['cost']:>4} Infamy  {r['source']:9s}  "
              f"{r['name']:34s}  {r['role']}={r['score']}  ({r['slot']})")

    # ----------------------------------------------------------------
    # Build the Lua block.
    # ----------------------------------------------------------------
    lines = [
        "-- DOCGEN:INFAMY_AUTO:BEGIN",
        "-- catalog.vendorItemsAuto",
        "--",
        "-- AUTO-GENERATED by tools/build_infamy_top_picks.py — do NOT",
        "-- hand-edit. To refresh after re-scoring any gear catalog:",
        "--     python tools/build_infamy_top_picks.py",
        "-- Or run tools/rebalance_all.bat to re-rank every catalog AND",
        "-- this auto-promoted Infamy Vendor list in one shot.",
        "--",
        "-- Sourced from the catalog.infamy tier of each scored catalog:",
        "--   * Armor / Weapons: top 5 per slot / weapon category (the",
        "--     'best options in game', skimmed out of the gold gear vendor).",
        "--   * Accessory: the 22 Sortie JSE +2 earrings (Infamy exclusive).",
        "-- The hand-curated catalog.vendorItems list above is left untouched.",
        f"-- {len(gear)} gear + {len(earrings)} Sortie earrings = {len(final)} items.",
        "catalog.vendorItemsAuto =",
        "{",
    ]
    for r in final:
        if r["source"] == "Accessory" and r["id"] in SORTIE_EARRING_IDS:
            stats = [
                "Sortie JSE +2 earring",
                f"Best-in-slot for {r['jobs']}",
                f"Jobs: {r['jobs']}",
            ]
        else:
            stats = [
                f"{r['role']} score {r['score']}",
                f"{r['source']} top-5 ({r['slot']})",
                f"Jobs: {r['jobs']}",
            ]
        stats_str = ", ".join(lua_q(s) for s in stats)
        lines.append(
            f"    {{ id = {r['id']:>6}, "
            f"name = {lua_q(r['name']):<36s}, "
            f"cost = {r['cost']:>4}, "
            f"stats = {{ {stats_str} }} }},"
        )
    lines.append("}")
    lines.append("-- DOCGEN:INFAMY_AUTO:END")
    block = "\n".join(lines)

    # ----------------------------------------------------------------
    # Splice into dungeon_catalog.lua between sentinel comments. If
    # the sentinels aren't present yet, insert the block immediately
    # after the catalog.vendorItems = { ... } closing brace.
    # ----------------------------------------------------------------
    text = DUNGEON_LUA.read_text(encoding="utf-8")
    sentinel_re = re.compile(
        r"-- DOCGEN:INFAMY_AUTO:BEGIN.*?-- DOCGEN:INFAMY_AUTO:END",
        re.DOTALL,
    )
    if sentinel_re.search(text):
        # Replace via a function so backslashes/group-refs in item names
        # (lua_q escapes apostrophes as \') aren't reinterpreted by re.sub.
        new_text = sentinel_re.sub(lambda _m: block, text)
        action = "replaced existing auto block"
    else:
        # First-time install: append after the catalog.vendorItems
        # closing brace. Find the `}` that closes the vendorItems
        # array by depth-counting from `catalog.vendorItems =`.
        anchor = re.search(r"catalog\.vendorItems\s*=\s*", text)
        if not anchor:
            raise RuntimeError(
                "dungeon_catalog.lua has no `catalog.vendorItems = ...` "
                "block. Where should the auto-promoted list go?"
            )
        i = anchor.end()
        # Skip to the opening `{`.
        while i < len(text) and text[i] != "{":
            i += 1
        if i >= len(text):
            raise RuntimeError(
                "No `{` found after `catalog.vendorItems =`. "
                "Unexpected catalog shape."
            )
        depth = 0
        while i < len(text):
            ch = text[i]
            if ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    break
            i += 1
        # i now sits on the closing `}`. Walk past the following `}`
        # and any trailing newline so the insertion lands cleanly
        # after the vendorItems definition.
        i += 1
        # Skip to next newline so insertion starts on its own line.
        nl = text.find("\n", i)
        if nl == -1:
            nl = len(text)
        new_text = text[:nl + 1] + "\n" + block + "\n" + text[nl + 1:]
        action = "inserted new auto block after vendorItems"

    DUNGEON_LUA.write_text(new_text, encoding="utf-8")
    print(f"\nWrote {DUNGEON_LUA.name} — {action}.")
    print(f"  {len(final)} auto-promoted items now live in "
          f"catalog.vendorItemsAuto.")


if __name__ == "__main__":
    main()
