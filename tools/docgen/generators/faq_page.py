"""Generate the FAQ page — docs/community/faq.md — from live game code.

FULL-PAGE owner (spells.py idiom): builds the complete markdown and
overwrites the page each run, so the FAQ can never drift stale again.

Live sources (all via tools.docgen._paths.resolve_source):
  - modules/custom/lua/new_player_starter.lua       STARTER_GIL (first-login gil gift)
  - modules/custom/lua/new_char_starter_marks.lua   STARTER_MARKS (starter Hunt Marks)
  - modules/custom/lua/Character_Upgrader.lua       first-login auto-grant suite +
                                                    starter Unity Accolades
  - modules/custom/lua/Augment_Moogle.lua           GIL_COST, MAX_CATALYST_COUNT,
                                                    TIER_SLICES, TIER_GATES
  - modules/custom/lua/augment_sage_catalog.lua     critChance curve, rank chain
  - modules/custom/lua/augment_affinity_catalog.lua affinityRankReq, affinityMarkCost
  - modules/custom/lua/reforge_catalog.lua          NM pool -> mark currency mapping
  - modules/custom/lua/hunting_league_catalog.lua   currency name, medal names + costs
  - modules/custom/commands/<cmd>.lua               presence gates for command Q&As
  - settings/main.lua -> settings/map.lua -> settings/default/* (SUBJOB_RATIO)

Links (Discord / repo / server name) come from tools.docgen._site. Rates are
emitted as {{setting:...}} tokens and NPC hubs as {{npc:...}} tokens — the
settings_inject / npc_location_inject passes (registered AFTER all content
generators in generate.py) substitute the live values on the same run, so
this module must stay registered before them.

Fails closed: if a required source or value can't be parsed, prints a skip
line and returns without writing, keeping the last good page live.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen import _site
from tools.docgen._paths import resolve_source


# =========================================================================
# NARRATIVE CONSTANTS — the single editing point for all FAQ prose that has
# no game-code source. Everything in braces is filled from live parses (or
# is a literal {{setting:...}}/{{npc:...}} token, escaped as double braces).
# =========================================================================

_LSB_URL = "https://github.com/LandSandBoat/server"

# Each entry: (question, answer-template, gate) where gate is None (always
# shown) or "cmd:<name>" (shown only if modules/custom/commands/<name>.lua
# resolves — so a removed command drops its Q&A automatically).
_SECTIONS: list[tuple[str, list[tuple[str, str, str | None]]]] = [
    ("Getting Started", [
        (
            "How do I connect to the server?",
            "See [Getting Started → Install the Client](../getting-started/install.md) "
            "and [Connect to Server](../getting-started/connect.md) for the full walkthrough.",
            None,
        ),
        (
            "Do I need a Square Enix account or game license?",
            "No. {server_name_cap} runs against a private server built on "
            "[LandSandBoat](" + _LSB_URL + "). You only need the FFXI client "
            "itself, not an active SE subscription.",
            None,
        ),
        (
            "How do I create a character?",
            "Once connected, the standard FFXI character-creation flow runs as usual. "
            "Your first login then triggers a one-time auto-setup that grants "
            "{grant_list}{trust_exclusion}, plus **{accolades} starter Unity Accolades** "
            "for the Unity Wanted board. You begin with a **{{{{setting:START_GIL:comma}}}} gil** "
            "wallet, and first login adds a **{starter_gil} gil** welcome gift and "
            "**{starter_marks} {hl_currency}** — enough for a "
            "first Bronze-tier weapon. The level cap is {{{{setting:INITIAL_LEVEL_CAP}}}} from "
            "day one (no Limit Break quests); type `!gmhome` to visit the setup Moogles "
            "and start leveling at {{{{setting:map.EXP_RATE}}}}× EXP.",
            None,
        ),
    ]),
    ("Progression & Power", [
        (
            "Why does my character feel weak compared to retail at the same level?",
            "Stats are tuned for this server's faster progression curve, but combat is "
            "balanced around the level-99 cap with rebalanced gear. If you feel weak, "
            "check the [Gear Vendors](../progression/gear-vendors.md) page — the "
            "{hl_currency} currencies are the fastest path to iLvl 119 gear.",
            None,
        ),
        (
            "How do I earn {hl_currency}?",
            "Kill the NMs at the [Hunting League](../progression/index.md) Spawner. "
            "Each NM gives points scaled by tier; higher tiers give more. Unlock tiers "
            "using the **Hub NPC** at the hunt zone.",
            None,
        ),
        (
            "What's the difference between the Hunting League NPC and the Reforge System NPC?",
            "- **[Hunting League](../progression/index.md)** — entry-to-mid-tier gear sold "
            "for {hl_currency} and the three League medals ({medals}).\n"
            "- **[Reforge System](../progression/reforge.md)** — AF/Relic/Empyrean reforge "
            "upgrades. Drops base pieces + currency by killing categorized NMs ({pools}).",
            None,
        ),
        (
            "How does the [Augment Moogle](../progression/augments.md) differ from the "
            "[Augment Sage](../progression/augment-sage.md)?",
            "- **Augment Moogle** (in {{{{npc:augment_moogle}}}}) stamps augments onto gear: "
            "trade one piece + up to {max_catalysts} catalysts ({moogle_gil} gil flat per "
            "trade). Each catalyst writes one augment line, and every line's value is "
            "**rolled** inside your **Augment Tier** band — {tier_count} tiers gated by "
            "content milestones, covering the 0–{band_max} roll space.\n"
            "- **Augment Sage** improves your *rolls* (the old rank multiplier is retired): "
            "each Mastery rank raises the roll floor by +1 (up to +{max_rank}) and lifts "
            "the perfect-roll crit chance from {crit_lo} to {crit_hi}. Ranks unlock "
            "automatically at content milestones ({rank_kinds} — nothing is consumed). "
            "Per-NM **affinities** make matching-category augments roll twice and keep the "
            "better; registering one takes Hunting League Rank {aff_rank}, {aff_cost} "
            "{hl_currency}, and the NM's trophy (consumed). Talk to the Sage to track "
            "and rank up.",
            None,
        ),
    ]),
    ("Custom Commands", [
        (
            "Where's the full list of player commands?",
            "[Reference → Player Commands](../reference/commands.md) — every player "
            "command, with parameter types and descriptions. Each is tagged `upstream` "
            "or `custom` so you can tell which are server-specific.",
            None,
        ),
        (
            "What does `!mystats` show me?",
            "A complete dump of every stat your character has, including bonuses from "
            "gear and active buffs. Useful for verifying that a piece of gear is "
            "actually doing what its tooltip says. See the "
            "[`!mystats` entry](../reference/commands.md#mystats) for the full output format.",
            "cmd:mystats",
        ),
        (
            "Can I auto-spend job points / merits?",
            "Yes — `!autojp` and `!automerits`. Both spread points breadth-first across "
            "categories on your current main job, so no single category gets maxed "
            "before others get a look-in. See [`!autojp`](../reference/commands.md#autojp) "
            "and [`!automerits`](../reference/commands.md#automerits).",
            "cmd:autojp",
        ),
    ]),
    ("Community & Multiplayer", [
        (
            "How do I find other players?",
            "- [Leaderboards](leaderboards.md) — top players by {hl_currency}, NM kills, "
            "lifetime currency earned.\n"
            "- [Player Profiles](players/index.md) — browse individual character pages.\n"
            "- [Discord]({discord}) — live chat, group-up posts, server announcements.",
            None,
        ),
        (
            "Can I play solo?",
            "Yes. Almost all custom content (Hunting League, Reforge System, Weekly "
            "Hunts) can be soloed at the cap. Difficulty is gear-checked, not "
            "group-size-checked.",
            None,
        ),
    ]),
    ("Technical / Server Issues", [
        (
            "The server's down / I can't connect. What do I do?",
            "1. Check the [Discord]({discord}) #server-status channel first — outages "
            "and maintenance windows are announced there.\n"
            "2. If the server is up but you can't connect, verify your client is pointed "
            "at the right login server (see [Connect to Server](../getting-started/connect.md)).",
            None,
        ),
        (
            "I think I found a bug. Where do I report it?",
            "Two options:\n"
            "- **[GitHub Issues]({repo}/issues)** — preferred for reproducible bugs with "
            "clear steps.\n"
            "- **[Discord]({discord}) #bug-reports** — for quick reports or \"is this "
            "intended?\" questions.",
            None,
        ),
        (
            "My character got stuck / I lost an item / something broke. Can a GM help?",
            "Ping a GM in [Discord]({discord}). Specify your character name, what "
            "happened, and roughly when. Most stuck-character and accidental-deletion "
            "situations can be resolved.",
            None,
        ),
    ]),
    ("Server Customizations", [
        (
            "What's different about this server vs. retail / vs. plain LandSandBoat?",
            "The [Retail Differences](../changes/index.md) page is the authoritative "
            "list. Highlights:\n\n"
            "- Faster rates — {{{{setting:map.EXP_RATE}}}}× mob EXP, "
            "{{{{setting:main.CAPACITY_RATE}}}}× capacity points, "
            "{{{{setting:DROP_RATE_MULTIPLIER}}}}× drops (full table on the "
            "[home page](../index.md))\n"
            "- Level cap {{{{setting:INITIAL_LEVEL_CAP}}}} from character creation — no "
            "Limit Break quests\n"
            "- {subjob_bullet}\n"
            "- Everything unlocked at creation: spells, weapon skills, trusts, maps, "
            "outpost warps\n"
            "- Custom Hunting League, Reforge System, Augment Sage, Job Rebirth, and "
            "Weekly Hunt Board systems\n"
            "- Every player command listed in "
            "[Reference → Player Commands](../reference/commands.md)",
            None,
        ),
        (
            "Can I use universal ninjutsu tools with NIN as a subjob?",
            "Yes — at level 75+, the universal tools (Inoshishinofuda, Shikanofuda, "
            "Chonofuda) work with NIN set as your **subjob**, not just as your main "
            "job like on retail. Below 75 you'll still need the regular per-spell "
            "tools (Shihei, Uchitake, and so on) when subbing NIN.",
            None,
        ),
        (
            "Are character files / progress safe? Are there backups?",
            "Yes — daily backups of the character database are taken. In a worst case, "
            "the most you'd lose is a few hours.",
            None,
        ),
    ]),
]

_CLOSING = (
    "_Have a question that should be on this page? Ping a GM in "
    "[Discord]({discord}) and we'll add it._"
)

# giveEverything() component -> human label, in render order. Only components
# actually CALLED in the live giveEverything body make it into the answer.
_GRANT_LABELS: list[tuple[str, str]] = [
    ("giveAllWeaponSkills",   "every weapon skill"),
    ("giveAllSpells",         "every spell"),
    ("capAllSkills",          "capped combat/magic skills"),
    ("giveAllTrusts",         "every trust"),
    ("completeAllQuests",     "all quests flagged complete"),
    ("completeAllMissions",   "all missions flagged complete"),
    ("giveAllKeyItems",       "all key items and maps"),
    ("giveAllOutpostWarps",   "all outpost warps"),
    ("giveAllHomepoints",     "every home point"),
    ("giveAllSurvivalGuides", "all survival guides"),
    ("bumpWardrobeSizes",     "expanded wardrobes"),
    ("giveAllAttachments",    "all automaton attachments"),
]

# map.SUBJOB_RATIO value -> highlight-bullet wording (mirrors the switch in
# src/map/entities/battleentity.cpp SetSLevel).
_SUBJOB_BULLETS = {
    0: "Subjobs disabled (`SUBJOB_RATIO = 0`)",
    1: "Retail subjob ratio (half of main) plus a background "
       "[Subjob EXP Share](../progression/subjob-exp.md)",
    2: "Raised subjob ratio (two-thirds of main) plus a background "
       "[Subjob EXP Share](../progression/subjob-exp.md)",
    3: "Full-level subjob that also "
       "[levels itself in the background](../progression/subjob-exp.md)",
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


def _parse_grants(upgrader: str) -> tuple[list[str], bool, int | None] | None:
    """(labels, excludes_paid_trusts, accolades) from Character_Upgrader.lua's
    giveEverything() body. None if the block can't be found or looks empty."""
    m = re.search(r"local\s+function\s+giveEverything\s*\(player\)(.*?)\nend", upgrader, re.DOTALL)
    if not m:
        return None
    body = m.group(1)
    labels = [label for fn, label in _GRANT_LABELS if re.search(rf"\b{fn}\s*\(", body)]
    if len(labels) < 6:  # suite gutted/renamed -> treat as parse failure
        return None
    excludes = "EXCLUDED_SPELLS" in upgrader
    accolades = _int(r"addCurrency\(\s*'unity_accolades'\s*,\s*(\d+)\s*\)", body)
    return labels, excludes, accolades


def _parse_tiers(moogle: str) -> tuple[int, int] | None:
    """(tier_count, band_max) from TIER_SLICES; sanity-checked against
    TIER_GATES so a reshape fails closed instead of publishing wrong bands."""
    slices = re.findall(r"\{\s*min\s*=\s*(\d+)\s*,\s*max\s*=\s*(\d+)\s*\}", moogle)
    gates = re.findall(r"\{\s*tier\s*=\s*(\d+)\s*,\s*unlock\s*=", moogle)
    if not slices or len(slices) != len(gates):
        return None
    return len(slices), max(int(b) for _, b in slices)


def _parse_pools(reforge: str) -> list[tuple[str, str]] | None:
    """[(pool label, currencyName)] in file order from reforge_catalog.sources."""
    pools = re.findall(
        r"setKey\s*=\s*'\w+'\s*,\s*label\s*=\s*'([^']+)'\s*,\s*currencyName\s*=\s*'([^']+)'",
        reforge,
    )
    return pools if len(pools) >= 3 else None


def _parse_medals(hl_catalog: str, sage_catalog: str) -> str | None:
    """Render 'Beastmens (bronze) 5 / ... — costs in Hunt Marks' from the HL
    catalog's Seals stock, tier-labelled via the sage catalog's seals map."""
    rows = re.findall(r'\{\s*name\s*=\s*"([^"]+ Medal)"\s*,\s*id\s*=\s*\d+\s*,\s*cost\s*=\s*(\d+)', hl_catalog)
    if not rows:
        return None
    tier_by_name = {
        name: tier
        for tier, name in re.findall(r"(\w+)\s*=\s*\{\s*id\s*=\s*\d+\s*,\s*name\s*=\s*'([^']+)'\s*\}", sage_catalog)
    }
    parts = []
    for name, cost in rows:
        tier = tier_by_name.get(name)
        parts.append(f"{name} ({tier}) {int(cost)}" if tier else f"{name} {int(cost)}")
    return " / ".join(parts) + " — costs in Hunt Marks"


def _parse_subjob_ratio(repo_root: Path) -> int | None:
    """map.SUBJOB_RATIO: live settings first, stock defaults as fallback."""
    for cand in ("settings/main.lua", "settings/map.lua",
                 "settings/default/main.lua", "settings/default/map.lua"):
        text = _read(repo_root, cand)
        if text is None:
            continue
        m = re.search(r"^\s*SUBJOB_RATIO\s*=\s*(\d+)", text, re.MULTILINE)
        if m:
            return int(m.group(1))
    return None


def _pct(v: float) -> str:
    return f"{v * 100:g}%"


# =========================================================================
# Entry point
# =========================================================================

def generate(repo_root: Path, docs_dir: Path) -> None:
    sources = {
        "starter":  "modules/custom/lua/new_player_starter.lua",
        "marks":    "modules/custom/lua/new_char_starter_marks.lua",
        "upgrader": "modules/custom/lua/Character_Upgrader.lua",
        "moogle":   "modules/custom/lua/Augment_Moogle.lua",
        "sage":     "modules/custom/lua/augment_sage_catalog.lua",
        "affinity": "modules/custom/lua/augment_affinity_catalog.lua",
        "reforge":  "modules/custom/lua/reforge_catalog.lua",
        "hl":       "modules/custom/lua/hunting_league_catalog.lua",
    }
    texts: dict[str, str] = {}
    for key, sub in sources.items():
        text = _read(repo_root, sub)
        if text is None:
            print(f"[faq_page] skip: {sub} not found")
            return
        texts[key] = text

    # --- required live values (any miss -> fail closed) -------------------
    starter_gil   = _int(r"local\s+STARTER_GIL\s*=\s*(\d+)", texts["starter"])
    starter_marks = _int(r"local\s+STARTER_MARKS\s*=\s*(\d+)", texts["marks"])
    grants        = _parse_grants(texts["upgrader"])
    moogle_gil    = _int(r"local\s+GIL_COST\s*=\s*(\d+)", texts["moogle"])
    max_catalysts = _int(r"local\s+MAX_CATALYST_COUNT\s*=\s*(\d+)", texts["moogle"])
    tiers         = _parse_tiers(texts["moogle"])
    pools         = _parse_pools(texts["reforge"])
    medals        = _parse_medals(texts["hl"], texts["sage"])
    aff_rank      = _int(r"catalog\.affinityRankReq\s*=\s*(\d+)", texts["affinity"])
    aff_cost      = _int(r"catalog\.affinityMarkCost\s*=\s*(\d+)", texts["affinity"])

    crit_m = re.search(r"catalog\.critChance\s*=\s*\{([^}]+)\}", texts["sage"])
    crits = [float(v) for v in crit_m.group(1).split(",") if v.strip()] if crit_m else []
    ranks = re.findall(r"\brank\s*=\s*(\d+)", texts["sage"])

    hl_currency_m = re.search(r"currencyName\s*=\s*'([^']+)'", texts["hl"])

    required = {
        "STARTER_GIL (new_player_starter.lua)": starter_gil,
        "STARTER_MARKS (new_char_starter_marks.lua)": starter_marks,
        "giveEverything grants (Character_Upgrader.lua)": grants,
        "GIL_COST (Augment_Moogle.lua)": moogle_gil,
        "MAX_CATALYST_COUNT (Augment_Moogle.lua)": max_catalysts,
        "TIER_SLICES/TIER_GATES (Augment_Moogle.lua)": tiers,
        "sources pools (reforge_catalog.lua)": pools,
        "medal stock (hunting_league_catalog.lua)": medals,
        "affinityRankReq (augment_affinity_catalog.lua)": aff_rank,
        "affinityMarkCost (augment_affinity_catalog.lua)": aff_cost,
        "critChance (augment_sage_catalog.lua)": crits or None,
        "ranks (augment_sage_catalog.lua)": ranks or None,
        "currencyName (hunting_league_catalog.lua)": hl_currency_m,
    }
    missing = [name for name, val in required.items() if val is None]
    if missing:
        print(f"[faq_page] skip: could not parse {', '.join(missing)}")
        return

    grant_labels, excludes_paid, accolades = grants
    tier_count, band_max = tiers

    # Which rank-requirement kinds exist in the live sage rank chain.
    kind_labels = [
        ("hlRank",         "Hunting League rank"),
        ("prestigeLevel",  "Prestige level"),
        ("rebirths",       "Job Rebirths"),
        ("gauntletClears", "Gauntlet clears"),
    ]
    rank_kinds = ", ".join(label for key, label in kind_labels
                           if re.search(rf"\b{key}\s*=\s*\d+", texts["sage"])) or "content milestones"

    ratio = _parse_subjob_ratio(repo_root)
    subjob_bullet = _SUBJOB_BULLETS.get(
        ratio if ratio is not None else -1,
        "Raised subjob ratio plus a background "
        "[Subjob EXP Share](../progression/subjob-exp.md)",
    )

    facts = {
        "server_name":     _site.SERVER_NAME,
        "server_name_cap": _site.SERVER_NAME[:1].upper() + _site.SERVER_NAME[1:],
        "discord":         _site.DISCORD_URL,
        "repo":            _site.REPO_URL,
        "starter_gil":     f"{starter_gil:,}",
        "starter_marks":   f"{starter_marks:,}",
        "hl_currency":     hl_currency_m.group(1),
        "grant_list":      ", ".join(grant_labels[:-1]) + ", and " + grant_labels[-1]
                           if len(grant_labels) > 1 else grant_labels[0],
        "trust_exclusion": " (the paid Void Keeper trusts stay locked)" if excludes_paid else "",
        "accolades":       f"{accolades:,}" if accolades is not None else "starter",
        "moogle_gil":      f"{moogle_gil:,}",
        "max_catalysts":   max_catalysts,
        "tier_count":      tier_count,
        "band_max":        band_max,
        "max_rank":        max(int(r) for r in ranks),
        "crit_lo":         _pct(crits[0]),
        "crit_hi":         _pct(crits[-1]),
        "rank_kinds":      rank_kinds,
        "aff_rank":        aff_rank,
        "aff_cost":        f"{aff_cost:,}",
        "medals":          medals,
        "pools":           ", ".join(f"{label} → {cur}" for label, cur in pools),
        "subjob_bullet":   subjob_bullet,
    }

    def gate_ok(gate: str | None) -> bool:
        if gate is None:
            return True
        if gate.startswith("cmd:"):
            return resolve_source(repo_root, f"modules/custom/commands/{gate[4:]}.lua", required=False) is not None
        return True

    lines: list[str] = [
        "# FAQ",
        "",
        f"Common questions about playing on {_site.SERVER_NAME}. If you have a "
        f"question that isn't answered here, ask in our [Discord]({_site.DISCORD_URL}) "
        f"or open an issue on the [project repo]({_site.REPO_URL}).",
    ]
    qa_count = 0
    for section, entries in _SECTIONS:
        shown = [(q, a) for q, a, gate in entries if gate_ok(gate)]
        if not shown:
            continue
        lines += ["", f"## {section}"]
        for q, a in shown:
            lines += ["", f"### {q.format(**facts)}", "", a.format(**facts)]
            qa_count += 1
        lines += ["", "---"]
    lines += ["", _CLOSING.format(**facts), ""]

    page = docs_dir / "community" / "faq.md"
    page.parent.mkdir(parents=True, exist_ok=True)
    page.write_text("\n".join(lines), encoding="utf-8")
    print(
        f"[faq_page] wrote community/faq.md ({qa_count} Q&As; starter gil "
        f"{starter_gil:,}, marks {starter_marks}, {len(grant_labels)} auto-grants, "
        f"moogle {moogle_gil:,} gil x{max_catalysts} catalysts, {tier_count} tiers)"
    )
