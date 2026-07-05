"""Sync docs/endgame/dynamis-divergence.md with the Divergence modules.

Two committed sources drive this page:
  modules/custom/lua/Dynamis_Divergence.lua  — the four city entry portals
                                                (instance + label) + the entry toll.
  modules/custom/lua/Divergence_Reforger.lua — the reforge map (traded +1/+2 piece
                                                -> upgraded result, slot, tier) and
                                                the per-tier medal cost.
The wave *structure* (statues -> Mid-Boss -> Mega-Boss -> Disjoined NM, plus the
time-extension rules) is universal and lives in the shared engine
scripts/globals/dynamis_divergence.lua; we read its constants so the published
wave summary tracks any retune.

A third source drives the new per-zone loot table:
  modules/custom/sql/dynamis_divergence.sql — mob_groups (each mob's dropId),
                                               mob_droplist (dropId -> item + rate),
                                               mob_spawn_points (player-facing names).
Item ids are resolved to names via the reforger config first, sql/item_basic.sql
as a fallback, so the loot table follows any drop/boss/zone change on republish.

Markers written:
  divergence-access  — the four city portals + entry cost
  divergence-waves   — the per-run wave structure + time rules
  divergence-loot    — per-city loot table: which mob drops which item (+ rate)
  divergence-reforge — the reforge progression (sets/slots, +1->+2->+3, medal costs)

Player-facing language only: item IDs are translated to the `name=` fields the
configs carry; no .lua names, raw IDs, or charVar jargon reach the page.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section, commafy


# --- slot -> the city whose [D] zone unlocks it (from the reforger header) ---
SLOT_CITY = {
    "feet": "San d'Oria",
    "hands": "Bastok",
    "head": "Windurst",
    "legs": "Jeuno",
}
SLOT_ORDER = ["head", "hands", "legs", "feet", "body"]
SLOT_LABEL = {
    "head": "Head",
    "hands": "Hands",
    "legs": "Legs",
    "feet": "Feet",
    "body": "Body",
}


# ---------------------------------------------------------------------------
# Parsing
# ---------------------------------------------------------------------------

def _parse_portals(text: str) -> dict:
    c: dict = {}

    cost = section(text, "ENTRY_COST")
    qty = re.search(r"qty\s*=\s*(\d+)", cost)
    name = re.search(r"name\s*=\s*'([^']+)'", cost)
    c["cost_qty"] = int(qty.group(1)) if qty else 1
    c["cost_name"] = name.group(1) if name else "Dynamis currency"

    # Each portal row carries a label="...City [D]". Rows also nest a pos = {...}
    # table, so match the label fields directly rather than per-row brace-slicing.
    block = section(text, "PORTALS")
    # Quote-aware: labels like "San d'Oria [D]" hold an apostrophe inside double
    # quotes, so anchor the close on the *same* quote char (backref), not either.
    portals = [t.strip() for _, t in
               re.findall(r"label\s*=\s*([\"'])(.*?)\1", block)]
    c["portals"] = portals

    # instanceId -> label, so the loot section can map a mob's zoneid to its
    # city. The [D] instance ids are 294xx/295xx/... and the mobs' zoneid is that
    # prefix (29400 -> zone 294), which is how we join the two.
    zone_labels: dict = {}
    for m in re.finditer(
        r"instanceId\s*=\s*(\d+)\s*,\s*label\s*=\s*([\"'])(.*?)\2", block
    ):
        zone_labels[int(m.group(1)) // 100] = m.group(3).strip()
    c["zone_labels"] = zone_labels
    return c


def _parse_reforge(text: str) -> dict:
    c: dict = {}

    # REFORGE: [tradedId] = { result, slot, tier, name }
    block = section(text, "REFORGE")
    entries = []
    for m in re.finditer(
        r"\[\s*\d+\s*\]\s*=\s*\{([^{}]*)\}", block
    ):
        body = m.group(1)
        slot = re.search(r"slot\s*=\s*'([^']+)'", body)
        tier = re.search(r"tier\s*=\s*(\d+)", body)
        name = re.search(r"name\s*=\s*'([^']+)'", body)
        if slot and tier and name:
            entries.append({
                "slot": slot.group(1),
                "tier": int(tier.group(1)),
                "name": name.group(1).strip(),
            })
    c["reforge"] = entries

    # COST: [tier] = { { id, qty, name }, ... }. Each tier's value is a
    # brace-balanced table (tier 3 holds two inner cost tables), so walk braces
    # per tier rather than relying on a non-greedy regex.
    costs: dict = {}
    cost_block = section(text, "COST")
    for tm in re.finditer(r"\[\s*(\d+)\s*\]\s*=\s*\{", cost_block):
        tier = int(tm.group(1))
        body = _balanced(cost_block, tm.end() - 1)
        parts = []
        # Quote-aware name: "Beastmen's Medal" holds an apostrophe inside double
        # quotes -- anchor the close on the same quote char via backref.
        for cm in re.finditer(
            r"qty\s*=\s*(\d+)\s*,\s*name\s*=\s*([\"'])(.*?)\2", body
        ):
            parts.append((int(cm.group(1)), cm.group(3).strip()))
        if parts:
            costs[tier] = parts
    c["costs"] = costs

    # id -> player-facing name, harvested from every { id=, ..., name= } the
    # COST tables carry (the medals). These names have proper apostrophes
    # ("Beastmen's Medal") that item_basic lacks, so they win in the loot table.
    id_names: dict = {}
    for m in re.finditer(
        r"id\s*=\s*(\d+)\s*,\s*qty\s*=\s*\d+\s*,\s*name\s*=\s*([\"'])(.*?)\2",
        cost_block
    ):
        id_names[int(m.group(1))] = m.group(3).strip()
    c["id_names"] = id_names
    return c


def _balanced(text: str, open_idx: int) -> str:
    """Return the substring from the brace at `open_idx` to its match."""
    depth, i, n = 0, open_idx, len(text)
    while i < n:
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                return text[open_idx:i + 1]
        i += 1
    return text[open_idx:]


def _parse_engine(text: str) -> dict:
    c: dict = {}
    cap = re.search(r"TIME_CAP_MIN\s*=\s*(\d+)", text)
    statue = re.search(r"STATUE_EXTEND\s*=\s*(\d+)", text)
    boss = re.search(r"BOSS_EXTEND\s*=\s*(\d+)", text)
    c["time_cap"] = int(cap.group(1)) if cap else 120
    c["statue_extend"] = int(statue.group(1)) if statue else 1
    c["boss_extend"] = int(boss.group(1)) if boss else 30
    return c


# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------

def _render_access(c: dict) -> str:
    qty = c["cost_qty"]
    name = c["cost_name"]
    toll = f"{qty} {name}" if qty != 1 else f"a {name}"
    lines = [
        "A **Divergence Portal** stands at each city's Dynamis entrance. Trade the "
        f"toll, confirm, and you're warped — solo is fine — into that city's "
        "alternate-timeline instance:",
        "",
        "| Portal | Unlocks (Reforge slot) |",
        "|---|---|",
    ]
    for label in c["portals"]:
        city = _city_of_label(label)
        slot = _slot_for_city(city)
        unlock = SLOT_LABEL.get(slot, "—") if slot else "—"
        lines.append(f"| **{label}** | {unlock} |")
    lines.append("")
    lines.append(f"**Entry toll:** {toll} per run.")
    return "\n".join(lines)


def _render_waves(c: dict) -> str:
    cap = c["time_cap"]
    statue = c["statue_extend"]
    boss = c["boss_extend"]
    return "\n".join([
        "Each run is a timed push through escalating waves. The clock can be "
        "extended by clearing optional targets, up to a hard cap of "
        f"**{cap} minutes**:",
        "",
        "1. **Wave 1 — Squadron.** Trash mobs, optional **time-extension statues** "
        f"(each one felled adds **+{statue} min**), and the **Mid-Boss**.",
        f"2. **Wave 2 — Regiment.** Felling the Mid-Boss advances the wave (**+{boss} "
        "min**): fresh trash plus the **Mega-Boss**.",
        "3. **Wave 3 — The Disjoined.** In zones that have one, the **Disjoined NM** "
        "manifests at the elemental circle after the Mega-Boss falls. No more time "
        "can be gained here — finish it to win.",
        "",
        "Clearing the run unlocks that city's Reforge slot. Beastmen's, Kindred's, and "
        "Demon's Medals drop from the mobs inside — bank them for the smith.",
    ])


def _render_reforge(c: dict) -> str:
    costs = c["costs"]
    by_slot: dict = {}
    sets = set()
    for e in c["reforge"]:
        # "Boii Mask +1" -> set name "Boii", base piece "Mask"
        base = re.sub(r"\s*\+\d+\s*$", "", e["name"])
        m = re.match(r"(\S+)\s+(.*)", base)
        if m:
            sets.add(m.group(1))
        by_slot.setdefault(e["slot"], set()).add(e["tier"])

    lines = [
        "Clear a city's zone to unlock its armor slot; clear **all four** to unlock "
        "**Body**. Then bring the **Divergence Smith** in Southern San d'Oria a "
        "Reforged Artifact, Relic, or Empyrean piece and the medals to push it up a "
        "tier — **+1 → +2 → +3**.",
        "",
        "**Slots, and the city that unlocks each:**",
        "",
        "| Slot | Unlocked by |",
        "|---|---|",
    ]
    for slot in SLOT_ORDER:
        if slot not in by_slot:
            continue
        if slot == "body":
            unlock = "Clearing **all four** city zones"
        else:
            city = SLOT_CITY.get(slot, "—")
            unlock = f"{city} [D]"
        lines.append(f"| **{SLOT_LABEL[slot]}** | {unlock} |")

    lines.append("")
    lines.append("**Medal cost per upgrade:**")
    lines.append("")
    lines.append("| Upgrade | Cost |")
    lines.append("|---|---|")
    for tier in sorted(costs):
        cost_str = ", ".join(f"{qty}× {name}" for qty, name in costs[tier])
        lines.append(f"| **→ +{tier}** | {cost_str} |")

    return "\n".join(lines)


# ---------------------------------------------------------------------------

# --- loot: which mob in which [D] zone drops which item -----------------------
# The drop plumbing (modules/custom/sql/dynamis_divergence.sql):
#   mob_groups   : per zone, each mob's dropId lives in the 7th column
#   mob_droplist : dropId -> (itemId, rate); rates are @ALWAYS/@COMMON/... macros
#   mob_spawn_points : the mob's player-facing name (4th column)
# A mob's ROLE is read off the last two digits of its dropId (x01 Mid-Boss,
# x02 Squadron trash, x03 Regiment trash, x04 Mega-Boss, x05 Disjoined NM);
# statues carry dropId 0 (no loot, they only extend the clock). This keeps the
# section wired to the live SQL: retune a drop, rename a boss, or add a zone and
# the table follows on the next publish.
_ROLE_BY_DROP = {1: "Mid-Boss", 2: "Wave 1 — Squadron", 3: "Wave 2 — Regiment",
                 4: "Mega-Boss", 5: "Disjoined NM"}
_ROLE_ORDER = {"Mid-Boss": 0, "Wave 1 — Squadron": 1, "Time-extension statue": 2,
               "Wave 2 — Regiment": 3, "Mega-Boss": 4, "Disjoined NM": 5}


def _humanize_mob(internal: str) -> str:
    """Fallback display for a mob with no mob_spawn_points name: drop trailing
    variant/[D]-instance tokens ('Disjoined_Elvaan_D' -> 'Disjoined Elvaan')."""
    parts = internal.split("_")
    while len(parts) > 1 and parts[-1] in {"D", "A", "B", "C"}:
        parts.pop()
    return " ".join(parts).strip() or internal


def _parse_loot(sql_text: str, id_to_name, statue_extend: int, zone_labels: dict) -> list:
    """Return [{label, mobs:[{role, name, drops:[(item, pct)]}]}] per city zone."""
    # Rate macros: SET @ALWAYS = 1000; ... (percent = value / 10).
    macros = {name: int(val) for name, val in
              re.findall(r"SET\s+@(\w+)\s*=\s*(\d+)", sql_text)}

    # dropId -> {itemId: best_rate_value}. Row layout:
    # (dropId, droptype, groupid, grouprate, itemId, itemRate). itemRate is a
    # macro token (@ALWAYS) or a literal; keep the highest rate per item.
    drops: dict = {}
    for m in re.finditer(
        r"INTO\s+`mob_droplist`\s+VALUES\s*\(\s*(\d+)\s*,\s*\d+\s*,\s*\d+\s*,"
        r"\s*\d+\s*,\s*(\d+)\s*,\s*@?(\w+)\s*\)", sql_text
    ):
        drop_id, item_id, rate_tok = int(m.group(1)), int(m.group(2)), m.group(3)
        rate = macros.get(rate_tok, int(rate_tok) if rate_tok.isdigit() else 0)
        bucket = drops.setdefault(drop_id, {})
        bucket[item_id] = max(bucket.get(item_id, 0), rate)

    # internal mob name -> player-facing display (first spawn point wins).
    display: dict = {}
    for m in re.finditer(
        r"INTO\s+`mob_spawn_points`\s+VALUES\s*\(\s*\d+\s*,\s*\d+\s*,\s*"
        r"'([^']*)'\s*,\s*'((?:[^'\\]|\\.)*)'", sql_text
    ):
        display.setdefault(m.group(1), m.group(2).replace("\\'", "'"))

    # mob_groups: (groupid, poolid, zoneid, 'name', min, max, dropId, ...).
    # Whitespace-tolerant: the columns are space-aligned in the source.
    by_zone: dict = {}
    for m in re.finditer(
        r"INTO\s+`mob_groups`\s+VALUES\s*\(\s*\d+\s*,\s*\d+\s*,\s*(\d+)\s*,\s*"
        r"'([^']*)'\s*,\s*\d+\s*,\s*\d+\s*,\s*(\d+)\s*,", sql_text
    ):
        zone, internal, drop_id = int(m.group(1)), m.group(2), int(m.group(3))
        role = ("Time-extension statue" if drop_id == 0
                else _ROLE_BY_DROP.get(drop_id % 100, "Enemy"))
        name = display.get(internal) or _humanize_mob(internal)
        loot = []
        for item_id, rate in sorted(drops.get(drop_id, {}).items(),
                                    key=lambda kv: -kv[1]):
            item_name = id_to_name(item_id)
            if item_name:
                loot.append((item_name, round(rate / 10)))
        by_zone.setdefault(zone, []).append({"role": role, "name": name, "drops": loot})

    cities = []
    for zone in sorted(by_zone):
        # Collapse the A/B/C trash variants (same display, role, drops).
        seen, mobs = set(), []
        for mob in sorted(by_zone[zone], key=lambda x: _ROLE_ORDER.get(x["role"], 9)):
            key = (mob["role"], mob["name"], tuple(mob["drops"]))
            if key in seen:
                continue
            seen.add(key)
            mobs.append(mob)
        cities.append({"label": zone_labels.get(zone, f"Zone {zone}"), "mobs": mobs})
    return cities


def _render_loot(cities: list, statue_extend: int) -> str:
    if not cities:
        return ("Loot data is generated from the live drop tables and will appear here "
                "once the Divergence zones are seeded.")
    lines = [
        "Every mob inside a Divergence run drops toward the medals you spend at the "
        "**Divergence Smith**. Each zone reuses the same six-role chain — only the "
        "Beastmen change — so here is exactly who drops what, city by city. "
        "Percentages are the live drop rates.",
        "",
    ]
    for city in cities:
        lines.append(f"### {city['label']}")
        lines.append("")
        lines.append("| Mob | Role | Drops |")
        lines.append("|---|---|---|")
        for mob in city["mobs"]:
            if mob["drops"]:
                drops = ", ".join(f"{name} ({pct}%)" for name, pct in mob["drops"])
            elif mob["role"] == "Time-extension statue":
                drops = f"— (fell it for **+{statue_extend} min** on the clock)"
            else:
                drops = "—"
            boss = mob["role"] in ("Mid-Boss", "Mega-Boss", "Disjoined NM")
            name = f"**{mob['name']}**" if boss else mob["name"]
            lines.append(f"| {name} | {mob['role']} | {drops} |")
        lines.append("")
    lines.append("Bank the medals, then take a Reforged Artifact, Relic, or Empyrean "
                 "piece to the smith — see **Reforging your armor** below.")
    return "\n".join(lines).rstrip()


def _make_id_to_name(reforge_cfg: dict, item_basic_text: str):
    """id -> player-facing item name. Prefer the exact names the reforger config
    already carries (proper apostrophes); fall back to item_basic (title-cased)."""
    id_name: dict = {}
    id_name.update(reforge_cfg.get("id_names", {}))

    basic: dict = {}
    if item_basic_text:
        for m in re.finditer(
            r"INSERT INTO `item_basic` VALUES\s*\(\s*(\d+)\s*,\s*\d+\s*,\s*'([^']*)'",
            item_basic_text
        ):
            basic[int(m.group(1))] = m.group(2).replace("_", " ").title()

    def lookup(item_id: int):
        return id_name.get(item_id) or basic.get(item_id)
    return lookup


def _city_of_label(label: str) -> str:
    # "San d'Oria [D]" -> "San d'Oria"; "Jeuno [D]" -> "Jeuno"
    return re.sub(r"\s*\[D\]\s*$", "", label).strip()


def _slot_for_city(city: str) -> str | None:
    for slot, c in SLOT_CITY.items():
        if c.lower() == city.lower():
            return slot
    return None


# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    portals_src = resolve_source(repo_root, "modules/custom/lua/Dynamis_Divergence.lua")
    if portals_src is None:
        print("[dynamis_divergence] skip: Dynamis_Divergence.lua not found")
        return
    reforge_src = resolve_source(repo_root, "modules/custom/lua/Divergence_Reforger.lua")
    engine_src = resolve_source(repo_root, "scripts/globals/dynamis_divergence.lua")

    c: dict = {}
    c.update(_parse_portals(portals_src.read_text(encoding="utf-8", errors="replace")))
    if reforge_src is not None:
        c.update(_parse_reforge(reforge_src.read_text(encoding="utf-8", errors="replace")))
    else:
        c.setdefault("reforge", [])
        c.setdefault("costs", {})
    if engine_src is not None:
        c.update(_parse_engine(engine_src.read_text(encoding="utf-8", errors="replace")))
    else:
        c.update(_parse_engine(""))  # defaults

    # Loot: which mob in which [D] zone drops which item. Reads the live drop
    # tables (mob_groups/mob_droplist/mob_spawn_points) and resolves item ids to
    # names (reforger config first, item_basic fallback). Skips cleanly if the
    # SQL isn't present, leaving the loot marker's prior content intact.
    loot_src = resolve_source(repo_root, "modules/custom/sql/dynamis_divergence.sql")
    item_basic_src = resolve_source(repo_root, "sql/item_basic.sql")
    cities = []
    if loot_src is not None:
        sql_text = loot_src.read_text(encoding="utf-8", errors="replace")
        item_basic_text = (item_basic_src.read_text(encoding="utf-8", errors="replace")
                           if item_basic_src is not None else "")
        id_to_name = _make_id_to_name(c, item_basic_text)
        cities = _parse_loot(sql_text, id_to_name, c["statue_extend"], c.get("zone_labels", {}))

    page = docs_dir / "endgame" / "dynamis-divergence.md"
    blocks = [
        ("divergence-access", _render_access(c)),
        ("divergence-waves", _render_waves(c)),
        ("divergence-loot", _render_loot(cities, c["statue_extend"])),
        ("divergence-reforge", _render_reforge(c)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    mob_total = sum(len(city["mobs"]) for city in cities)
    print(f"[dynamis_divergence] {written}/{len(blocks)} marker block(s) written "
          f"(portals={len(c.get('portals', []))}, reforge entries={len(c.get('reforge', []))}, "
          f"cost tiers={len(c.get('costs', {}))}, loot cities={len(cities)}, mobs={mob_total})")
