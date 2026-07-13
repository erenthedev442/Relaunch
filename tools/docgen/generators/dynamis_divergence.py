"""Sync docs/endgame/dynamis-divergence.md with the Divergence modules.

Dynamis-Divergence is the **+3 -> +4 Forge**: the tail of the reforged-armor
ladder. The base Reforge System (docs/progression/reforge.md) takes armor to +3
with marks; Dynamis-D takes a reforged **+3** AF/Relic piece to **+4** using
materials farmed inside the [D] zones. (The old "Divergence Smith" that made
+1/+2/+3 for medals was retired — that overlapped the Reforge System.)

Committed sources that drive this page:
  modules/custom/lua/Dynamis_Divergence.lua   — the four city entry portals
                                                 (instance + label) + the entry toll.
  modules/custom/lua/Dynamis_Plus4_Forge.lua  — the "Divergence Forge" NPC: the
                                                 recipe knobs (Paragon Card + Rusted/
                                                 Black ID Card quantities, body tax)
                                                 and the mega-boss Paragon-Card hook.
  modules/custom/lua/reforge_plus4_map.lua     — the 220 reforged +3 -> +4 pairs
                                                 (job/slot per entry) that gate what
                                                 the forge accepts. Empyrean is absent
                                                 by design (retail caps Empy at +3).
The wave *structure* (statues -> Mid-Boss -> Mega-Boss -> Disjoined NM, plus the
time-extension rules) is universal and lives in the shared engine
scripts/globals/dynamis_divergence.lua; we read its constants so the published
wave summary tracks any retune.

Two SQL sources drive the per-zone loot table:
  modules/custom/sql/dynamis_divergence.sql        — mob_groups (each mob's dropId),
                                                      mob_droplist (dropId -> item),
                                                      mob_spawn_points (mob names).
  modules/custom/sql/dynamis_plus4_materials.sql   — the additive Rusted/Black ID
                                                      Card rows hung on the same [D]
                                                      dropIds (the +4 forge materials).
Item ids are resolved to names via sql/item_basic.sql, so the loot table follows
any drop/boss/zone change on republish.

Markers written:
  divergence-access  — the four city portals + entry cost
  divergence-waves   — the per-run wave structure + time rules
  divergence-loot    — per-city loot table: which mob drops which item (+ rate)
  divergence-reforge — the +3 -> +4 Forge: recipe, [D] materials, Empy-capped note

Player-facing language only: item IDs are translated to the `name=` fields the
configs carry; no .lua names, raw IDs, or charVar jargon reach the page.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section


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


def _parse_forge(forge_text: str, map_text: str) -> dict:
    """Read the +3 -> +4 Forge recipe knobs from Dynamis_Plus4_Forge.lua and the
    covered job/slot counts from reforge_plus4_map.lua."""
    c: dict = {}

    def _knob(name: str, default: int) -> int:
        m = re.search(rf"\b{name}\s*=\s*(\d+)", forge_text)
        return int(m.group(1)) if m else default

    c["pcard_qty"]       = _knob("PCARD_QTY", 3)
    c["pcard_qty_body"]  = _knob("PCARD_QTY_BODY", 6)
    c["rusted_qty"]      = _knob("RUSTED_QTY", 12)
    c["rusted_qty_body"] = _knob("RUSTED_QTY_BODY", 24)
    c["black_qty"]       = _knob("BLACK_QTY", 6)
    c["black_qty_body"]  = _knob("BLACK_QTY_BODY", 12)

    # Map coverage: how many +3 -> +4 pairs, and which slots/jobs they span.
    # Each entry line: [id] = { result=..., slot='body', job='WAR', pcard=..., name=... }
    entries = re.findall(
        r"slot\s*=\s*'([a-z]+)'\s*,\s*job\s*=\s*'([A-Z]{3})'", map_text
    )
    c["pair_count"] = len(entries)
    c["slots"] = sorted({s for s, _ in entries})
    c["jobs"]  = sorted({j for _, j in entries})
    return c


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
    portals = " · ".join(f"**{label}**" for label in c["portals"]) if c["portals"] else "the four city instances"
    lines = [
        "A **Divergence Portal** stands at each city's Dynamis entrance. Pay the "
        f"toll from the portal's menu — solo is fine — and you're warped into "
        "that city's alternate-timeline instance:",
        "",
        portals + ".",
        "",
        f"**Entry toll:** {toll} per run. Marks come from the "
        "[Reforge System](../progression/reforge.md) — farm any of its three NM "
        "pools (Sky Gods / Unity NMs / Abyssea NMs) and pick your currency at the "
        "portal. There is no rank or slot gate — the only gate on the +4 upgrade "
        "is farming the [D] materials (below).",
    ]
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
        "The mobs inside drop the **+4 Forge materials**: **Rusted ID Cards** off wave "
        "trash and **Black ID Cards** off the bosses. Felling the **Mega-Boss** also "
        "hands the killer their **main-job Paragon Card** — the job-matched key the "
        "forge needs. (The Beastmen's / Kindred's / Demon's Medals that also drop are "
        "the Gear-Vendor Seals, not a Divergence currency.)",
    ])


def _render_forge(c: dict) -> str:
    """The +3 -> +4 Divergence Forge: recipe (from the forge knobs) + [D] materials,
    with the Empyrean-capped-at-+3 note."""
    pcard, pcard_b   = c.get("pcard_qty", 3), c.get("pcard_qty_body", 6)
    rusted, rusted_b = c.get("rusted_qty", 12), c.get("rusted_qty_body", 24)
    black, black_b   = c.get("black_qty", 6), c.get("black_qty_body", 12)
    pairs = c.get("pair_count", 0)
    jobs  = len(c.get("jobs", []))

    coverage = ""
    if pairs and jobs:
        coverage = (f" The forge covers **{pairs} pieces** — every AF and Relic slot "
                    f"across all {jobs} jobs.")

    lines = [
        "Dynamis-Divergence is the **+3 → +4 Forge**. The base [Reforge System]"
        "(../progression/reforge.md) takes armor to **+3** with marks; the "
        "**Divergence Forge** (an NPC in **Southern San d'Oria**, where the old "
        "Divergence Smith stood) takes a reforged **+3** piece the rest of the way "
        "to **+4**." + coverage,
        "",
        "Trade a reforged **+3 AF or Relic** piece together with the materials below, "
        "and it comes back **+4**:",
        "",
        "| Material | Non-body | Body |",
        "|---|---:|---:|",
        f"| Your job's **Paragon Card** | {pcard}× | {pcard_b}× |",
        f"| **Rusted ID Card** | {rusted}× | {rusted_b}× |",
        f"| **Black ID Card** | {black}× | {black_b}× |",
        "",
        "**Where the materials come from** — all inside the [D] zones:",
        "",
        "- **Rusted ID Card** — drops off wave-trash mobs.",
        "- **Black ID Card** — drops off the bosses (mid-boss and mega-boss).",
        "- **Paragon Card** — the **Mega-Boss** hands the killer their own main-job "
        "card, so bring the job you want to upgrade.",
        "",
        "!!! warning \"Empyrean has no +4\"",
        "    Only **AF and Relic** armor reach +4. Empyrean armor caps at +3 in the "
        "game data (matching retail), so there is no Empyrean +4 to forge here — "
        "finish Empyrean sets on the [Reforge System](../progression/reforge.md).",
    ]
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
        "Every zone reuses the same six-role chain — only the Beastmen change. The "
        "**Rusted** and **Black ID Cards** here are the +4 Forge materials; the "
        "Beastmen's / Kindred's / Demon's Medals are the Gear-Vendor Seals. Here is "
        "exactly who drops what, city by city — percentages are the live drop rates.",
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
    lines.append("Collect the Rusted/Black ID Cards and your Mega-Boss Paragon Card, then "
                 "take a reforged +3 AF/Relic piece to the Divergence Forge — see "
                 "**The +3 → +4 Forge** below.")
    return "\n".join(lines).rstrip()


# Friendly names for the two +4-material item ids, so the loot table reads well
# even if sql/item_basic.sql only has the underscored internal name.
_MATERIAL_NAMES = {
    9538: "Rusted ID Card",
    9540: "Black ID Card",
}


def _make_id_to_name(item_basic_text: str):
    """id -> player-facing item name from sql/item_basic.sql (title-cased),
    with friendly overrides for the +4-material cards."""
    basic: dict = {}
    if item_basic_text:
        for m in re.finditer(
            r"INSERT INTO `item_basic` VALUES\s*\(\s*(\d+)\s*,\s*\d+\s*,\s*'([^']*)'",
            item_basic_text
        ):
            basic[int(m.group(1))] = m.group(2).replace("_", " ").title()

    def lookup(item_id: int):
        return _MATERIAL_NAMES.get(item_id) or basic.get(item_id)
    return lookup


def _city_of_label(label: str) -> str:
    # "San d'Oria [D]" -> "San d'Oria"; "Jeuno [D]" -> "Jeuno"
    return re.sub(r"\s*\[D\]\s*$", "", label).strip()


# ---------------------------------------------------------------------------

def _render_su5(engine_text: str) -> str:
    """Superior Lv5 Mega-Boss weapon pool from SU5_WEAPONS in the engine
    (scripts/globals/dynamis_divergence.lua) — parsed, never mirrored."""
    m = re.search(r"SU5_WEAPONS\s*=\s*\n\{(.*?)\n\}", engine_text, re.DOTALL)
    rows = re.findall(
        r"\{\s*id\s*=\s*(\d+),\s*name\s*=\s*'([^']+)',\s*slot\s*=\s*'([^']+)',\s*job\s*=\s*'([^']+)'",
        m.group(1)) if m else []
    if not rows:
        raise RuntimeError("SU5_WEAPONS not parsed from dynamis_divergence.lua "
                           "— table moved/reshaped, update _render_su5.")
    per = re.search(r"SU5_DROPS_PER_KILL\s*=\s*(\d+)", engine_text)
    per_kill = int(per.group(1)) if per else 1
    n = per_kill
    lines = [
        f"Every **Mega-Boss kill** drops **{n} random Superior Lv5 weapon{'s' if n != 1 else ''}** "
        f"from the pool below (one per job) into the treasure pool — the whole run can lot it. "
        f"Any city, every clear.",
        "",
        "| Job | Weapon | Type |",
        "|---|---|---|",
    ]
    for iid, name, slot, job in sorted(rows, key=lambda r: r[3]):
        lines.append(f"| {job} | [{name}](https://www.ffxiah.com/item/{iid}) | {slot} |")
    return "\n".join(lines)


def generate(repo_root: Path, docs_dir: Path) -> None:
    portals_src = resolve_source(repo_root, "modules/custom/lua/Dynamis_Divergence.lua")
    if portals_src is None:
        print("[dynamis_divergence] skip: Dynamis_Divergence.lua not found")
        return
    # The +3 -> +4 Forge recipe knobs + the covered job/slot map (retired the old
    # Divergence_Reforger.lua +1/+2/+3 smith source).
    forge_src = resolve_source(repo_root, "modules/custom/lua/Dynamis_Plus4_Forge.lua")
    map_src   = resolve_source(repo_root, "modules/custom/lua/reforge_plus4_map.lua")
    engine_src = resolve_source(repo_root, "scripts/globals/dynamis_divergence.lua")

    c: dict = {}
    c.update(_parse_portals(portals_src.read_text(encoding="utf-8", errors="replace")))
    forge_text = forge_src.read_text(encoding="utf-8", errors="replace") if forge_src else ""
    map_text   = map_src.read_text(encoding="utf-8", errors="replace") if map_src else ""
    c.update(_parse_forge(forge_text, map_text))
    if engine_src is not None:
        c.update(_parse_engine(engine_src.read_text(encoding="utf-8", errors="replace")))
    else:
        c.update(_parse_engine(""))  # defaults

    # Loot: which mob in which [D] zone drops which item. Reads the live drop
    # tables (mob_groups/mob_droplist/mob_spawn_points) from BOTH the base
    # dynamis_divergence.sql (medals/gear) and the additive dynamis_plus4_materials.sql
    # (the Rusted/Black ID Card rows), so the +4 materials show up alongside the
    # medals. Resolves item ids to names via item_basic. Skips cleanly if the SQL
    # isn't present, leaving the loot marker's prior content intact.
    loot_src = resolve_source(repo_root, "modules/custom/sql/dynamis_divergence.sql")
    mats_src = resolve_source(repo_root, "modules/custom/sql/dynamis_plus4_materials.sql")
    item_basic_src = resolve_source(repo_root, "sql/item_basic.sql")
    cities = []
    if loot_src is not None:
        sql_text = loot_src.read_text(encoding="utf-8", errors="replace")
        if mats_src is not None:
            sql_text += "\n" + mats_src.read_text(encoding="utf-8", errors="replace")
        item_basic_text = (item_basic_src.read_text(encoding="utf-8", errors="replace")
                           if item_basic_src is not None else "")
        id_to_name = _make_id_to_name(item_basic_text)
        cities = _parse_loot(sql_text, id_to_name, c["statue_extend"], c.get("zone_labels", {}))

    page = docs_dir / "endgame" / "dynamis-divergence.md"
    blocks = [
        ("divergence-access", _render_access(c)),
        ("divergence-waves", _render_waves(c)),
        ("divergence-loot", _render_loot(cities, c["statue_extend"])),
        ("divergence-su5", _render_su5(engine_src.read_text(encoding="utf-8", errors="replace")
                                       if engine_src is not None else "")),
        ("divergence-reforge", _render_forge(c)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    mob_total = sum(len(city["mobs"]) for city in cities)
    print(f"[dynamis_divergence] {written}/{len(blocks)} marker block(s) written "
          f"(portals={len(c.get('portals', []))}, +4 pairs={c.get('pair_count', 0)}, "
          f"jobs={len(c.get('jobs', []))}, loot cities={len(cities)}, mobs={mob_total})")
