"""Generate the Glossary page — docs/reference/glossary.md — from live game code.

FULL-PAGE owner (spells.py idiom): builds the complete markdown and
overwrites the page each run. Every definition that embeds a number, name
list, or zone is parameterized from the live catalogs so it can't drift.

Live sources (all via tools.docgen._paths.resolve_source):
  - modules/custom/lua/reforge_catalog.lua          AF/Relic/Empy pools (labels,
                                                    NM ladders, upgrade costs)
  - modules/custom/lua/daily_board_catalog.lua      slots/day, all-clear rewards,
                                                    currency display names
  - modules/custom/lua/daily_board.lua              UTC-day reset confirmation
  - modules/custom/lua/hunting_league_catalog.lua   currency name, rank ladder,
                                                    medal names + costs
  - modules/custom/lua/Augment_Moogle.lua           GIL_COST, MAX_CATALYST_COUNT,
                                                    TIER_SLICES, TIER_GATES
  - modules/custom/lua/augment_sage_catalog.lua     critChance, rank chain,
                                                    seal-tier labels
  - modules/custom/lua/augment_affinity_catalog.lua affinity gate + row count
  - modules/custom/lua/hunters_guild_catalog.lua    guilds, ladder, capstones
                                                    (entry omitted if missing)
  - modules/custom/lua/weekly_hunts_catalog.lua     slots/week, all-clear bonus
                                                    (entry omitted if missing)
  - modules/custom/lua/game_master_catalog.lua      Wave Master zone
                                                    (entry omitted if missing)
  - modules/custom/lua/{AbysseaMarks,Invasion,RaidBoss,TheGauntlet,Tournament}.lua
                                                    presence scan for Infamy sources

NPC hubs are emitted as {{npc:...}} tokens (daily_board, augment_moogle,
augment_sage, infamy_vendor) and expanded by npc_location_inject, which runs
after all content generators — keep this module registered before it.

Fails closed: if a required source or value can't be parsed, prints a skip
line and returns without writing, keeping the last good page live.
Presence-gated terms (Hunter's Guild, Weekly Hunt Board, Wave Master) simply
drop off the page if their catalog disappears.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen import _site
from tools.docgen._paths import resolve_source


# =========================================================================
# NARRATIVE CONSTANTS — the single editing point for glossary prose that has
# no game-code source. {placeholders} are filled from live parses; literal
# {{npc:...}} tokens are escaped as double braces for str.format.
# =========================================================================

_INTRO = "Server-specific terms, explained in plain language."

# (term, definition-template). Rendered as an MkDocs definition list in this
# order (keep alphabetical). Templates whose facts are missing at run time
# are handled in generate() — required ones fail the page closed, optional
# ones drop the term.
_DEFINITIONS: list[tuple[str, str]] = [
    (
        "AF Marks",
        "Reforge currency earned by killing the {af_label} NM pool — {af_nms} "
        "(ladder order, entry to apex). Used to upgrade AF armor sets from base "
        "through +3.",
    ),
    (
        "Augment",
        "A permanent stat bonus applied to a piece of gear by trading a catalyst "
        "to the Augment Moogle. Augments stack with the gear's base stats; a piece "
        "holds up to {max_catalysts} augment lines, and each line's value is rolled "
        "within your Augment Tier band.",
    ),
    (
        "Augment Sage",
        "A special NPC (in {{{{npc:augment_sage}}}}) whose Mastery ranks improve your "
        "augment *rolls* under the Augment Tier system: each rank (up to "
        "{max_rank}) raises the roll floor by +1 inside your tier's band, and the "
        "chance of a perfect crit roll climbs from {crit_lo} to {crit_hi}. Ranks "
        "unlock automatically at content milestones ({rank_kinds}; nothing "
        "consumed). Per-category NM affinities make matching augments roll twice "
        "and keep the better result — registering one requires Hunting League "
        "Rank {aff_rank}, {aff_cost} Hunt Marks, and the NM's trophy (consumed).",
    ),
    (
        "Augment Tier",
        "The content ladder that gates how strong augment rolls can be. Each of "
        "the {tier_count} tiers owns a band of the 0–{band_max} roll space "
        "({tier_bands}); you sit at the highest gate you've cleared consecutively. "
        "A fresh character is Tier 0 — the Moogle won't augment at all until the "
        "first gate is cleared: {first_gate}. The final gate: {last_gate}.",
    ),
    (
        "Catalyst",
        "An item bought from the Augment Moogle's catalyst shop (`!shop augments "
        "<group>`, flat gil), then traded back to the Moogle (in "
        "{{{{npc:augment_moogle}}}}) to write a specific augment line on your gear — "
        "up to {max_catalysts} catalysts per trade, {moogle_gil} gil flat per trade.",
    ),
    (
        "Daily Board",
        "A {daily_slots}-objective board located in {{{{npc:daily_board}}}} (`!lib`) "
        "that resets {daily_reset} every day. Completing all {daily_slots} "
        "objectives earns a bonus of {daily_reward}.",
    ),
    (
        "Empy Marks",
        "Reforge currency earned by killing the {empy_label} pool — {empy_nms} "
        "(ladder order, entry to apex). Used to upgrade Empyrean armor sets from "
        "base through +3.",
    ),
    (
        "Hunt Marks / HL Points",
        "The primary currency earned by killing Hunting League NMs. Spent at the "
        "Seals NPC on gear upgrades, consumables, and the three League medals — "
        "{medals}.",
    ),
    (
        "Hunter's Guild",
        "A passive reputation layer of {guild_count} guilds ({guild_names}) that "
        "rank up as you hunt each guild's NMs, permanently amplifying the marks "
        "that guild's kills pay — up to +{top_amp} at {top_rank}. Capstones: "
        "{trinity_label} (+{trinity_bonus}, all {trinity_count} Reforge guilds at "
        "{top_rank}) and {apex_label} (+{apex_bonus}, all {guild_count} guilds; "
        "supersedes {trinity_label}).",
    ),
    (
        "Hunting League",
        "The custom {hl_tiers}-tier NM hunting system that drives all long-term "
        "progression on {server_name}. Advance through the ranks {hl_ranks} by "
        "accumulating kills and Hunt Marks.",
    ),
    (
        "Infamy",
        "A premium endgame currency earned across the server's high-end content — "
        "{infamy_sources}. Spent at the Infamy Vendor (in {{{{npc:infamy_vendor}}}}) "
        "for best-in-slot gear found nowhere else.",
    ),
    (
        "NM",
        "Notorious Monster — a named enemy that drops specific loot and earns Hunt "
        "Marks when killed. NMs are the primary activity of the Hunting League and "
        "Reforge systems.",
    ),
    (
        "Relic Marks",
        "Reforge currency earned by killing the {relic_label} pool — {relic_nms} "
        "(ladder order, entry to apex). Used to upgrade Relic armor sets from base "
        "through +3.",
    ),
    (
        "Reforge",
        "The system of killing NM currency ladders to upgrade AF, Relic, or Empy "
        "armor from the base version through +1, +2, and +3 ({upgrade_costs} marks "
        "per piece, in that set's own currency). Each upgrade tier requires more "
        "marks and is visually and statistically distinct.",
    ),
    (
        "Wave Master",
        "An NPC located in {wave_zone} who spawns themed NM waves for solo or "
        "group play. Scales with party size. Rewards Hunt Marks on completion and "
        "is useful for both marks farming and combat practice.",
    ),
    (
        "Weekly Hunt Board",
        "{weekly_slots} rotating objectives that reset {weekly_reset}. Objectives "
        "range from straightforward kill counts to tougher feats like speed kills "
        "and no-death streaks. Completing all {weekly_slots} earns a "
        "{weekly_reward} bonus.",
    ),
]

# Terms whose facts come from OPTIONAL catalogs: if the catalog is missing the
# term drops off the page instead of failing the whole build.
_OPTIONAL_TERMS: dict[str, tuple[str, ...]] = {
    "Hunter's Guild":    ("guild_count",),
    "Wave Master":       ("wave_zone",),
    "Weekly Hunt Board": ("weekly_slots",),
}

# Infamy-awarding systems: module file -> phrase. Presence-scanned so a
# retired system drops out of the definition automatically.
_INFAMY_SOURCES: list[tuple[str, str]] = [
    ("AbysseaMarks.lua", "Abyssea NM hunts"),
    ("Invasion.lua",     "scheduled Invasions"),
    ("RaidBoss.lua",     "the weekly Raid boss"),
    ("TheGauntlet.lua",  "the Gauntlet"),
    ("Tournament.lua",   "the Tournament"),
]

# Raw catalog zone id -> display name (only for zones that aren't simple
# underscore-to-space conversions).
_FRIENDLY_ZONES = {
    "Escha_RuAun": "Escha - Ru'Aun",
    "Escha_ZiTah": "Escha - Zi'Tah",
}


# =========================================================================
# Parsers
# =========================================================================

def _read(repo_root: Path, sub_path: str) -> str | None:
    src = resolve_source(repo_root, sub_path)
    if src is None:
        return None
    return src.read_text(encoding="utf-8", errors="replace").replace("\r\n", "\n")


def _int(pattern: str, text: str) -> int | None:
    m = re.search(pattern, text)
    return int(m.group(1)) if m else None


def _pct(v: float) -> str:
    return f"{v * 100:g}%"


def _join(names: list[str]) -> str:
    if len(names) > 1:
        return ", ".join(names[:-1]) + ", and " + names[-1]
    return names[0] if names else ""


def _parse_reforge(text: str) -> dict[str, object] | None:
    """Pool labels + NM ladders (file order) + upgrade costs."""
    facts: dict[str, object] = {}
    for key in ("af", "relic", "empy"):
        block_m = re.search(
            rf"setKey\s*=\s*'{key}'\s*,\s*label\s*=\s*'([^']+)'\s*,\s*"
            rf"currencyName\s*=\s*'[^']+'(.*?)\n\s*\}},\n",
            text, re.DOTALL,
        )
        if not block_m:
            return None
        nms = re.findall(r"\{\s*name\s*=\s*'([^']+)'\s*,\s*label\s*=", block_m.group(2))
        if not nms:
            return None
        facts[f"{key}_label"] = block_m.group(1)
        facts[f"{key}_nms"] = _join([n.replace("_", " ").strip() for n in nms])
    cost_m = re.search(r"af\s*=\s*\{\s*plus1\s*=\s*(\d+)\s*,\s*plus2\s*=\s*(\d+)\s*,\s*plus3\s*=\s*(\d+)", text)
    if not cost_m:
        return None
    facts["upgrade_costs"] = " → ".join(f"{int(c):,}" for c in cost_m.groups())
    return facts


def _parse_daily(catalog: str, board_lua: str | None) -> dict[str, object] | None:
    slots = _int(r"catalog\.slotsPerDay\s*=\s*(\d+)", catalog)
    if slots is None:
        return None
    reward_block_m = re.search(r"catalog\.allClearedReward\s*=\s*\{(.*?)\n\}", catalog, re.DOTALL)
    if not reward_block_m:
        return None
    rewards = re.findall(r"\{\s*currency\s*=\s*'(\w+)'\s*,\s*amount\s*=\s*(\d+)\s*\}", reward_block_m.group(1))
    if not rewards:
        return None
    cur_names = dict(re.findall(r"(\w+)\s*=\s*\{\s*cv\s*=\s*'[^']+'\s*,\s*(?:name|label)\s*=\s*'([^']+)'", catalog))
    reward_str = " + ".join(f"{int(amt):,} {cur_names.get(code, code.upper())}" for code, amt in rewards)
    # Reset basis: daily_board.lua keys the day off os.date('!...') = UTC.
    reset = "at midnight UTC" if (board_lua and "os.date('!" in board_lua) else "daily"
    return {"daily_slots": slots, "daily_reward": reward_str, "daily_reset": reset}


def _parse_hl(text: str) -> dict[str, object] | None:
    currency = re.search(r"currencyName\s*=\s*'([^']+)'", text)
    ranks = re.findall(r"name\s*=\s*'Rank\s+[IVX]+\s*-\s*([^']+)'", text)
    medals = re.findall(r'\{\s*name\s*=\s*"([^"]+ Medal)"\s*,\s*id\s*=\s*\d+\s*,\s*cost\s*=\s*(\d+)', text)
    if not currency or not ranks or not medals:
        return None
    return {
        "hl_currency": currency.group(1),
        "hl_tiers":    len(ranks),
        "hl_ranks":    " → ".join(ranks),
        "_medals":     medals,  # tier labels attached later from the sage catalog
    }


def _parse_moogle(text: str) -> dict[str, object] | None:
    gil = _int(r"local\s+GIL_COST\s*=\s*(\d+)", text)
    max_cat = _int(r"local\s+MAX_CATALYST_COUNT\s*=\s*(\d+)", text)
    slices = [(int(a), int(b)) for a, b in re.findall(r"\{\s*min\s*=\s*(\d+)\s*,\s*max\s*=\s*(\d+)\s*\}", text)]
    gates = [
        (int(t), sq if sq else dq)
        for t, sq, dq in re.findall(r"\{\s*tier\s*=\s*(\d+)\s*,\s*unlock\s*=\s*(?:'([^']+)'|\"([^\"]+)\")", text)
    ]
    if gil is None or max_cat is None or not slices or len(slices) != len(gates):
        return None
    return {
        "moogle_gil":    f"{gil:,}",
        "max_catalysts": max_cat,
        "tier_count":    len(slices),
        "band_max":      max(b for _, b in slices),
        "tier_bands":    ", ".join(f"T{i + 1} {a}–{b}" for i, (a, b) in enumerate(slices)),
        "first_gate":    gates[0][1],
        "last_gate":     gates[-1][1],
    }


def _parse_sage(text: str) -> dict[str, object] | None:
    crit_m = re.search(r"catalog\.critChance\s*=\s*\{([^}]+)\}", text)
    ranks = re.findall(r"\brank\s*=\s*(\d+)", text)
    if not crit_m or not ranks:
        return None
    crits = [float(v) for v in crit_m.group(1).split(",") if v.strip()]
    if len(crits) < 2:
        return None
    kind_labels = [
        ("hlRank",         "Hunting League rank"),
        ("prestigeLevel",  "Prestige level"),
        ("rebirths",       "Job Rebirths"),
        ("gauntletClears", "Gauntlet clears"),
    ]
    kinds = ", ".join(label for key, label in kind_labels if re.search(rf"\b{key}\s*=\s*\d+", text))
    seal_tiers = {
        name: tier
        for tier, name in re.findall(r"(\w+)\s*=\s*\{\s*id\s*=\s*\d+\s*,\s*name\s*=\s*'([^']+)'\s*\}", text)
    }
    return {
        "max_rank":    max(int(r) for r in ranks),
        "crit_lo":     _pct(crits[0]),
        "crit_hi":     _pct(crits[-1]),
        "rank_kinds":  kinds or "content milestones",
        "_seal_tiers": seal_tiers,
    }


def _parse_guilds(text: str) -> dict[str, object] | None:
    labels = re.findall(r'label\s*=\s*"([^"]+ Guild)"', text)
    ladder = re.findall(r"\{\s*idx\s*=\s*(\d+)\s*,\s*label\s*=\s*'([^']+)'\s*,\s*minRep\s*=\s*\d+\s*,\s*amplifier\s*=\s*([\d.]+)", text)
    if not labels or not ladder:
        return None
    top = max(ladder, key=lambda r: int(r[0]))
    caps: dict[str, tuple[str, str, int]] = {}
    for key in ("trinity", "apex"):
        m = re.search(
            rf"{key}\s*=\s*\{{\s*label\s*=\s*'([^']+)'.*?requires\s*=\s*\{{([^}}]*)\}}.*?bonus\s*=\s*([\d.]+)",
            text, re.DOTALL,
        )
        if not m:
            return None
        caps[key] = (m.group(1), _pct(float(m.group(3))), len(re.findall(r"'\w+'", m.group(2))))
    return {
        "guild_count":   len(labels),
        "guild_names":   _join(labels),
        "top_rank":      top[1],
        "top_amp":       _pct(float(top[2])),
        "trinity_label": caps["trinity"][0],
        "trinity_bonus": caps["trinity"][1],
        "trinity_count": caps["trinity"][2],
        "apex_label":    caps["apex"][0],
        "apex_bonus":    caps["apex"][1],
    }


def _parse_weekly(catalog: str, weekly_lua: str | None) -> dict[str, object] | None:
    slots = _int(r"catalog\.slotsPerWeek\s*=\s*(\d+)", catalog)
    block = re.search(r"catalog\.allClearedReward\s*=\s*\{(.*?)\n\}", catalog, re.DOTALL)
    if slots is None or not block:
        return None
    code_m = re.search(r"currency\s*=\s*'(\w+)'", block.group(1))
    amt = _int(r"amount\s*=\s*(\d+)", block.group(1))
    if not code_m or amt is None:
        return None
    cur_names = dict(re.findall(r"(\w+)\s*=\s*\{\s*cv\s*=\s*'[^']+'\s*,\s*(?:name|label)\s*=\s*'([^']+)'", catalog))
    # weekly_hunts.lua keys the week off os.date('!%G%V') = ISO week, UTC.
    reset = "every Monday at 00:00 UTC" if (weekly_lua and "%G%V" in weekly_lua) else "each week"
    return {
        "weekly_slots":  slots,
        "weekly_reward": f"{amt:,} {cur_names.get(code_m.group(1), code_m.group(1).upper())}",
        "weekly_reset":  reset,
    }


# =========================================================================
# Entry point
# =========================================================================

def generate(repo_root: Path, docs_dir: Path) -> None:
    lua = "modules/custom/lua/"

    required_files = {
        "reforge":  lua + "reforge_catalog.lua",
        "daily":    lua + "daily_board_catalog.lua",
        "hl":       lua + "hunting_league_catalog.lua",
        "moogle":   lua + "Augment_Moogle.lua",
        "sage":     lua + "augment_sage_catalog.lua",
        "affinity": lua + "augment_affinity_catalog.lua",
    }
    texts: dict[str, str] = {}
    for key, sub in required_files.items():
        text = _read(repo_root, sub)
        if text is None:
            print(f"[glossary_page] skip: {sub} not found")
            return
        texts[key] = text

    facts: dict[str, object] = {"server_name": _site.SERVER_NAME}

    parsed = {
        "reforge_catalog.lua pools/costs":    _parse_reforge(texts["reforge"]),
        "daily_board_catalog.lua slots/reward": _parse_daily(texts["daily"], _read(repo_root, lua + "daily_board.lua")),
        "hunting_league_catalog.lua ranks/medals": _parse_hl(texts["hl"]),
        "Augment_Moogle.lua fee/tiers":       _parse_moogle(texts["moogle"]),
        "augment_sage_catalog.lua crit/ranks": _parse_sage(texts["sage"]),
    }
    missing = [name for name, val in parsed.items() if val is None]

    aff_rank = _int(r"catalog\.affinityRankReq\s*=\s*(\d+)", texts["affinity"])
    aff_cost = _int(r"catalog\.affinityMarkCost\s*=\s*(\d+)", texts["affinity"])
    if aff_rank is None or aff_cost is None:
        missing.append("augment_affinity_catalog.lua gate")

    if missing:
        print(f"[glossary_page] skip: could not parse {', '.join(missing)}")
        return

    for chunk in parsed.values():
        facts.update(chunk)  # type: ignore[arg-type]
    facts["aff_rank"] = aff_rank
    facts["aff_cost"] = f"{aff_cost:,}"

    # Medal list, tier-labelled via the sage catalog's seals mapping.
    seal_tiers: dict[str, str] = facts.pop("_seal_tiers")  # type: ignore[assignment]
    medal_rows: list[tuple[str, str]] = facts.pop("_medals")  # type: ignore[assignment]
    parts = []
    for name, cost in medal_rows:
        tier = seal_tiers.get(name)
        parts.append(f"{name} ({tier}, {int(cost)})" if tier else f"{name} ({int(cost)})")
    facts["medals"] = ", ".join(parts) + " — costs in Hunt Marks"

    # ---- optional facts (their terms drop off the page when absent) ------
    guilds_text = _read(repo_root, lua + "hunters_guild_catalog.lua")
    if guilds_text:
        chunk = _parse_guilds(guilds_text)
        if chunk:
            facts.update(chunk)

    weekly_text = _read(repo_root, lua + "weekly_hunts_catalog.lua")
    if weekly_text:
        chunk = _parse_weekly(weekly_text, _read(repo_root, lua + "weekly_hunts.lua"))
        if chunk:
            facts.update(chunk)

    gm_text = _read(repo_root, lua + "game_master_catalog.lua")
    if gm_text:
        zone_m = re.search(r"catalog\.npcPos\s*=\s*\{\s*zone\s*=\s*'(\w+)'", gm_text)
        if zone_m:
            raw = zone_m.group(1)
            facts["wave_zone"] = _FRIENDLY_ZONES.get(raw, raw.replace("_", " "))

    infamy = [phrase for fname, phrase in _INFAMY_SOURCES
              if (t := _read(repo_root, lua + fname)) and re.search(r"setCharVar\(\s*'Infamy'|INFAMY_CV\s*=\s*'Infamy'", t)]
    facts["infamy_sources"] = _join(infamy) if infamy else "high-end custom content"

    # ---- render -----------------------------------------------------------
    lines = ["# Glossary", "", _INTRO, "", "---", ""]
    terms_written = 0
    for term, template in _DEFINITIONS:
        needed = _OPTIONAL_TERMS.get(term)
        if needed and any(key not in facts for key in needed):
            continue  # optional catalog missing -> drop the term
        lines += [term, f":   {template.format(**facts)}", ""]
        terms_written += 1

    page = docs_dir / "reference" / "glossary.md"
    page.parent.mkdir(parents=True, exist_ok=True)
    page.write_text("\n".join(lines), encoding="utf-8")
    print(
        f"[glossary_page] wrote reference/glossary.md ({terms_written} terms; "
        f"tiers T1-T{facts['tier_count']}, {facts['hl_tiers']} HL ranks, "
        f"daily {facts['daily_slots']} slots, medals x{len(medal_rows)})"
    )
