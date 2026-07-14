"""Generate docs/progression/gear-guide.md — "what should I wear right now?" —
entirely from the live vendor catalogs.

FULL-PAGE writer (idiom: spells.py). The stage narrative and section headings
are template constants (heading text is kept byte-stable so deep links like
#silver-tier--mid-range-weapons survive); every currency name, medal price,
weapon cost, item highlight, and zone is parsed from:

  modules/custom/lua/gear_progression_catalog.lua  weapon tiers + seal names +
                                                   per-item costs (the same
                                                   catalog weapons_npc.py reads;
                                                   its regexes are reused here)
  modules/custom/lua/hunting_league_catalog.lua    medal Hunt-Mark prices +
                                                   Sortie earring costs (same
                                                   source armor_npc.py /
                                                   accessories_npc.py parse)
  modules/custom/lua/HuntingLeague.lua             (optional) seal multi-buy
  modules/custom/lua/reforge_catalog.lua           set currencies + upgrade
                                                   costs + hub zone
  modules/custom/lua/infamy_vendor_catalog.lua     Infamy currency + vendor hub
  modules/custom/lua/augment_sage_catalog.lua      sage rank milestones + crit
  modules/custom/lua/augment_affinity_catalog.lua  affinity count

"Selected highlights" per tier = the first three catalog entries per weapon
category (the catalogs are written by the scorer in ranked order), linked via
tools.docgen._bgwiki.urls_for_item keyed on the catalog's item id.

Fail-closed: missing/empty required source -> print skip, leave the page
untouched. No last-updated footer — stamp.py owns that.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._bgwiki import urls_for_item
from tools.docgen.generators import weapons_npc
from tools.docgen.generators.armor_npc import _parse_hl_seal_costs
from tools.docgen.generators.progression_map import _parse_sage_ranks
from tools.docgen.generators.augment_sage import _parse_mult_table

_TAG = "[gear_guide_page]"

_ID_RE = re.compile(r"\bid\s*=\s*(\d+)")

_TIER_LABEL = {"bronze": "Bronze", "silver": "Silver", "gold": "Gold"}


class _Skip(Exception):
    pass


def _read(repo_root: Path, rel: str, required: bool = True) -> str | None:
    src = resolve_source(repo_root, rel)
    if src is None:
        if required:
            raise _Skip(f"source not found: {rel}")
        return None
    return src.read_text(encoding="utf-8", errors="replace")


def _fmt(n: int) -> str:
    return f"{n:,}"


def _plural(name: str) -> str:
    return name if name.endswith("s") else name + "s"


def _escape_md(s: str) -> str:
    return s.replace("|", "\\|").replace("\n", " ")


def _item_link(name: str, wiki: str | None, item_id: int | None) -> str:
    page_url, image_url = urls_for_item(name, wiki, item_id=item_id)
    return (
        f'<a class="item-link" href="{page_url}" '
        f'data-img="{image_url}" target="_blank" rel="noopener">'
        f"{_escape_md(name)}</a>"
    )


# ---------------------------------------------------------------- parsers


def _parse_weapon_tiers(text: str, repo_root: Path) -> dict[str, dict[str, list[dict]]]:
    """Delegates to weapons_npc.parse_weapon_tiers so this guide and the generated
    gear-vendors tables always agree. bronze/silver/gold come from the flat catalog
    (category derived from item skill). include_infamy=False since the 2026-07-06
    Infamy Vendor rework: infamy is accessories-only; weapons/armor moved elsewhere."""
    return weapons_npc.parse_weapon_tiers(text, repo_root, include_infamy=False)


def _tier_cost(items_by_cat: dict[str, list[dict]]) -> tuple[int, int]:
    costs = sorted({it["cost"] for rows in items_by_cat.values() for it in rows})
    if not costs:
        raise _Skip("a weapon tier parsed with zero items")
    return costs[0], costs[-1]


def _parse_sortie_costs(hl_text: str) -> dict[str, int]:
    """{'NQ': 100, '+1': 200} from the HL reward shop's Sortie categories."""
    out: dict[str, int] = {}
    for suffix in ("NQ", "\\+1"):
        m = re.search(
            rf"label\s*=\s*'Sortie:\s*{suffix}'.*?cost\s*=\s*(\d+)",
            hl_text,
            re.DOTALL,
        )
        if m:
            out[suffix.replace("\\", "")] = int(m.group(1))
    return out


def _parse_reforge_bits(text: str) -> dict:
    currencies = re.findall(r"currencyName\s*=\s*'([^']+)'", text)
    up = re.search(
        r"af\s*=\s*\{\s*plus1\s*=\s*(\d+)\s*,\s*plus2\s*=\s*(\d+)\s*,\s*plus3\s*=\s*(\d+)",
        text,
    )
    zone_m = re.search(r"huntZonePath\s*=\s*['\"]xi\.zones\.([^'\"]+)['\"]", text)
    return {
        "currencies": currencies,
        "upgrade": tuple(int(g) for g in up.groups()) if up else None,
        "zone": zone_m.group(1).replace("_", " ") if zone_m else "Gwora-Corridor",
    }


def _zone_display(gear_text: str) -> str:
    m = re.search(r"catalog\.zonePath\s*=\s*['\"]xi\.zones\.([^'\"]+)['\"]", gear_text)
    return m.group(1).replace("_", " ") if m else "Escha ZiTah"


# ---------------------------------------------------------------- rendering


def _render_highlights(items_by_cat: dict[str, list[dict]], per_cat: int = 3) -> list[str]:
    lines = [
        "### Selected highlights",
        "",
        "| Category | Standout picks | Jobs |",
        "|---|---|---|",
    ]
    order = list(weapons_npc._CATEGORY_ORDER) + [
        c for c in items_by_cat if c not in weapons_npc._CATEGORY_ORDER
    ]
    for category in order:
        rows = items_by_cat.get(category) or []
        if not rows:
            continue
        picks = rows[:per_cat]
        links = ", ".join(_item_link(r["name"], r["wiki"], r["id"]) for r in picks)
        # Union of the picks' job lists (order-preserving, capped) so the cell
        # covers all listed items, not just the first.
        tokens: list[str] = []
        for p in picks:
            for tok in (p["jobs"] or "").split("/"):
                if tok and tok not in tokens:
                    tokens.append(tok)
        if not tokens:
            jobs = "all"
        elif len(tokens) > 8:
            jobs = "/".join(tokens[:8]) + "/…"
        else:
            jobs = "/".join(tokens)
        lines.append(f"| {category} | {links} | {_escape_md(jobs)} |")
    lines.append("")
    return lines


def _render(d: dict) -> str:
    zone       = d["zone"]
    currency   = d["currency"]                     # 'Hunt Marks'
    seals      = d["seals"]                        # tier -> medal name
    seal_cost  = d["seal_costs"]                   # medal name -> marks each
    tiers      = d["tiers"]                        # tier -> {cat: [items]}
    rf         = d["reforge"]
    infamy     = d["infamy_name"]
    sortie     = d["sortie"]                       # {'NQ': 100, '+1': 200}
    multi_buy  = d["seal_multi_buy"]
    sage       = d["sage"]
    crit       = d["crit"]
    aff_count  = d["aff_count"]

    def medal(tier: str) -> str:
        return seals[tier]

    def marks_per(tier: str, qty: int) -> int:
        return qty * seal_cost[medal(tier)]

    cost = {t: _tier_cost(tiers[t]) for t in ("bronze", "silver", "gold")}

    def cost_str(tier: str) -> str:
        lo, hi = cost[tier]
        return str(lo) if lo == hi else f"{lo}–{hi}"

    def marks_str(tier: str) -> str:
        lo, hi = cost[tier]
        if lo == hi:
            return f"{_fmt(marks_per(tier, lo))} {currency} per weapon"
        return f"{_fmt(marks_per(tier, lo))}–{_fmt(marks_per(tier, hi))} {currency} per weapon"

    def tier_stats(tier: str) -> tuple[int, int]:
        n = sum(len(rows) for rows in tiers[tier].values())
        cats = sum(1 for rows in tiers[tier].values() if rows)
        return n, cats

    def count_phrase(n: int, cats: int) -> str:
        return (f"{n} weapon{'s' if n != 1 else ''} across "
                f"{cats} categor{'ies' if cats != 1 else 'y'}")

    _ALL_JOBS = {"WAR", "MNK", "WHM", "BLM", "RDM", "THF", "PLD", "DRK",
                 "BST", "BRD", "RNG", "SAM", "NIN", "DRG", "SMN", "BLU",
                 "COR", "PUP", "DNC", "SCH", "GEO", "RUN"}

    def jobs_covered(tier: str) -> set[str]:
        covered: set[str] = set()
        for rows in tiers[tier].values():
            for r in rows:
                j = (r.get("jobs") or "").strip()
                if j.lower() == "all":
                    return set(_ALL_JOBS)
                covered |= {p.strip().upper() for p in j.split("/") if p.strip()}
        return covered & _ALL_JOBS

    n_cats_stocked = max(tier_stats(t)[1] for t in ("bronze", "silver", "gold"))

    rf_currs = " / ".join(rf["currencies"][:3]) if rf["currencies"] else "Reforge marks"
    up = rf["upgrade"]
    up_txt = (
        f"+1 {_fmt(up[0])} / +2 {_fmt(up[1])} / +3 {_fmt(up[2])} marks per piece, "
        f"in that set's own currency" if up else "escalating per upgrade step"
    )

    crit_r1 = f"{crit[1] * 100:.0f}%" if len(crit) > 1 else "10%"
    crit_hi = f"{crit[-1] * 100:.0f}%" if crit else "30%"
    sage1 = sage[0] if sage else {"title": "Augment Initiate", "reqs": ["HL R2"]}
    sage_top = sage[-1]["title"] if sage else "Augment Archon"
    sage1_req = sage1["reqs"][0] if sage1.get("reqs") else "HL R2"
    sage1_hl = re.sub(r"\D", "", sage1_req) or "2"

    L: list[str] = []
    A = L.append

    A("# Gear Progression Guide")
    A("")
    A(
        "New to the Relaunch server and wondering what to wear? This page answers "
        "\"what gear should I be targeting right now?\" at each stage of your "
        "character's journey."
    )
    A("")
    A('!!! info "Weapons come from the Weapons Vendor. Armor comes from Reforge and infamy vendors."')
    A(
        f"    This page focuses on the **weapon progression** sold by the Weapons "
        f"Vendor at {zone}, and explains where armor fits in. For the full armor "
        f"catalog, see [Gear Vendors](gear-vendors.md). For Reforge (AF/Relic/Empy "
        f"sets), see [Reforge System](reforge.md)."
    )
    A("")
    A("---")
    A("")

    # ---- at a glance --------------------------------------------------
    A("## Gear sources at a glance")
    A("")
    A("| Source | What it gives | How you access it |")
    A("|---|---|---|")
    A(
        f"| **Weapons Vendor** | Weapons in three tiers (Bronze / Silver / Gold) "
        f"| {currency} → convert to medals at the Seals NPC |"
    )
    A(
        "| **Armor Vendor / Accessories Vendor** | Body armor and accessories in "
        "three tiers | Same medal system as weapons |"
    )
    A(
        f"| **Reforge System** | AF/Relic/Empy armor sets, base through +3 | "
        f"{rf_currs} from Reforge NMs in {rf['zone']} |"
    )
    A(
        f"| **Infamy Vendor** | Best-in-slot armor and weapons found nowhere else "
        f"| {infamy} earned from Abyssea NM hunts, Invasions, and the weekly Raid |"
    )
    A(
        f"| **Augmented gear** | Any piece with extra stats from the "
        f"[Augment Moogle](augmenting-guide.md) | Catalyst drops from assigned "
        f"mobs + a flat gil fee per trade |"
    )
    A(
        f"| **Hunting League rewards** | Currency and access to all of the above "
        f"| Participate in Hunt spawns at {zone} |"
    )
    A("")
    A("---")
    A("")

    # ---- currency ------------------------------------------------------
    A("## Currency: how to turn Hunt Marks into medals")
    A("")
    A(
        f"All vendor gear (weapons and armor) is purchased with three medal tiers. "
        f"You exchange {currency} at the **Seals NPC** at {zone}:"
    )
    A("")
    A("| Medal | Cost | Tier unlocked |")
    A("|---|---:|---|")
    for tier in ("bronze", "silver", "gold"):
        name = medal(tier)
        A(
            f"| {name} ({_TIER_LABEL[tier]}) | {seal_cost[name]} {currency} each "
            f"| {_TIER_LABEL[tier]} weapons and armor |"
        )
    A("")
    bulk = (
        " The Seals NPC supports bulk purchases — use **Buy 10** or **Buy max** "
        "when stocking up." if multi_buy else ""
    )
    A(
        f"{currency} come from participating in [Hunting League](index.md) spawns "
        f"at {zone}.{bulk}"
    )
    A("")
    A("---")
    A("")

    # ---- vendor --------------------------------------------------------
    A("## The Weapons Vendor")
    A("")
    A(f"**Location:** {zone} — next to the Hunting League NPCs  ")
    A(
        f"This NPC sells weapons in {n_cats_stocked} categories across three "
        f"tiers. All items are ilvl 119 and available immediately to any job that "
        f"can equip them. Browse the menu by weapon type; the NPC filters to "
        f"categories relevant to your current job."
    )
    A("")
    A("---")
    A("")

    # ---- bronze ---------------------------------------------------------
    n_b, cats_b = tier_stats("bronze")
    lo_b, _ = cost["bronze"]
    A("## Bronze Tier — entry-level weapons")
    A("")
    A(f"**Currency:** {cost_str('bronze')} {_plural(medal('bronze'))} each (= {marks_str('bronze')})  ")
    A("**For:** new characters who just hit level 99, or anyone who needs a solid baseline weapon fast.")
    A("")
    cov_b = jobs_covered("bronze")
    cov_txt = (
        "Every job has at least one option."
        if cov_b >= _ALL_JOBS else
        f"Current stock covers {len(cov_b)} of {len(_ALL_JOBS)} jobs — everyone "
        f"else gears up via the Infamy picks, the forge paths, or Silver."
    )
    A(
        f"Bronze weapons are curated for vendor exclusivity — the NPC stocks "
        f"only gear you can't earn elsewhere ({count_phrase(n_b, cats_b)}). "
        f"{cov_txt}"
    )
    A("")
    L.extend(_render_highlights(tiers["bronze"]))
    A(f'!!! tip "{marks_per("bronze", lo_b)} {currency} per weapon"')
    A(
        f"    At Bronze tier, {_fmt(marks_per('bronze', lo_b))} {currency} = "
        f"{lo_b} {_plural(medal('bronze'))} = one weapon. A typical Hunting League "
        f"session yields enough to buy one or two weapons. Prioritize your main "
        f"weapon first, then fill in an offhand or ranged slot."
    )
    A("")
    A("---")
    A("")

    # ---- silver ----------------------------------------------------------
    n_s, cats_s = tier_stats("silver")
    A("## Silver Tier — mid-range weapons")
    A("")
    A(f"**Currency:** {cost_str('silver')} {_plural(medal('silver'))} each (= {marks_str('silver')})  ")
    A("**For:** characters with Hunting League Rank I–III who want a significant step up from Bronze.")
    A("")
    A(
        f"Silver weapons have higher base damage and often better weapon skills or "
        f"secondary stats ({count_phrase(n_s, cats_s)}), with a wider selection "
        f"than Bronze."
    )
    A("")
    L.extend(_render_highlights(tiers["silver"]))
    A('!!! info "Silver is the sweet spot for mid-progression"')
    A(
        "    Silver weapons represent a major power jump over Bronze and are "
        "within reach after a few weeks of regular Hunting League participation. "
        "Many players stay on Silver weapons for quite a while while building out "
        "their armor sets via Reforge."
    )
    A("")
    A("---")
    A("")

    # ---- gold -------------------------------------------------------------
    n_g, cats_g = tier_stats("gold")
    lo_g, _ = cost["gold"]
    A("## Gold Tier — endgame weapons")
    A("")
    A(f"**Currency:** {cost_str('gold')} {_plural(medal('gold'))} each (= {marks_str('gold')})  ")
    A("**For:** players with Hunting League Rank IV–V who are approaching or in endgame content.")
    A("")
    A(
        f"Gold weapons are the top-end purchases from the vendor system "
        f"({count_phrase(n_g, cats_g)}), priced for players deep into the "
        f"Hunting League ladder."
    )
    A("")
    L.extend(_render_highlights(tiers["gold"]))
    A('!!! warning "Gold weapons are a large Hunt Mark investment"')
    A(
        f"    {lo_g} {_plural(medal('gold'))} = {_fmt(marks_per('gold', lo_g))} "
        f"{currency} per weapon. Plan your spending carefully — fill in Silver "
        f"weapons for secondary jobs first, and save Gold purchases for your main "
        f"job's primary weapon. The armor in the Armor Vendor's Gold tier competes "
        f"for the same {_plural(medal('gold'))}."
    )
    A("")
    A("---")
    A("")

    # ---- armor overview -----------------------------------------------------
    A("## Armor: a brief overview")
    A("")
    A("Armor does not come from the Weapons Vendor — it comes from two other sources:")
    A("")
    A(
        f"**Gear Vendors ({zone}):** The Armor Vendor and Accessories Vendor at "
        f"the same cluster sell body armor and accessories using the same three "
        f"medal tiers. See [Gear Vendors](gear-vendors.md) for the full catalog."
    )
    A("")
    A(
        f"**Reforge System:** AF, Relic, and Empyrean armor sets are upgraded from "
        f"base through +3 using Reforge marks earned from spawner NMs in "
        f"{rf['zone']} ({up_txt}). This is your primary armor progression path "
        f"alongside the medal vendors. See [Reforge System](reforge.md)."
    )
    A("")
    A(
        f"**Infamy accessories:** BiS neck / ear / ring / waist / back are sold by the "
        f"[Infamy Vendor](gear-vendors.md#infamy-vendor) for **{infamy}** earned "
        f"from endgame content. As of 2026-07-06 the vendor is **accessories-only** — "
        f"weapons and armor moved to Voidwatch NM loot, and **+4 Reforge sets** are "
        f"crafted at the [+3 → +4 Forge](../endgame/dynamis-divergence.md#the-3-4-forge) "
        f"in Dynamis-Divergence (paid in Rusted / Black ID Cards + Paragon Cards)."
    )
    A("")
    A("---")
    A("")

    # ---- timeline -------------------------------------------------------------
    A("## Progression timeline")
    A("")
    A(
        "Use this as a rough roadmap. Time estimates assume regular play (several "
        "sessions per week), not speed-running."
    )
    A("")
    A("### Fresh character — first days")
    A("")
    A("- Reach level 99 via EXP camps or [Subjob EXP Share](subjob-exp.md).")
    A(
        f"- Start collecting {currency} by participating in "
        f"[Hunting League](index.md) spawns at {zone}."
    )
    A(
        f"- Convert early marks to {_plural(medal('bronze'))} and grab a **Bronze "
        f"weapon** ({_fmt(marks_per('bronze', lo_b))} {currency} all-in) for your "
        f"main job."
    )
    A("- Pick up bronze-tier armor pieces from the Armor Vendor in the slots you're missing.")
    A("")
    A("### Hunting League Rank I (first week–two)")
    A("")
    A("- You have enough Hunting League experience to be earning marks consistently.")
    A("- Prioritize filling out your **Bronze weapon** (if not done) and a secondary slot.")
    sortie_txt = ""
    if sortie:
        nq = sortie.get("NQ")
        p1 = sortie.get("+1")
        if nq and p1:
            sortie_txt = f" (NQ {nq} / +1 {p1} each)"
        elif nq:
            sortie_txt = f" (NQ {nq} each)"
    A(
        f"- Grab per-job **Sortie earrings** from the Hunt Accessories NPC — paid "
        f"directly in {currency}{sortie_txt} — and start saving "
        f"{_plural(medal('bronze'))} for accessories from the medal-paid "
        f"Accessories Vendor. Earrings and a back piece are efficient early "
        f"purchases."
    )
    A(
        "- Begin hunting Reforge NMs to accumulate AF Marks for your first base "
        "Reforge armor pieces."
    )
    A("")
    A("### Rank II–III (second to fourth week)")
    A("")
    lo_s, _ = cost["silver"]
    A(
        f"- **Transition your main weapon to Silver tier.** "
        f"{_fmt(marks_per('silver', lo_s))} {currency} per weapon is achievable "
        f"with consistent play."
    )
    A(
        "- Focus Reforge marks on upgrading your armor set from base to +1 or +2 "
        "in your most impactful slots (typically body and head)."
    )
    A(
        f"- Start saving {_plural(medal('silver'))} for Silver armor pieces in "
        f"slots where Reforge hasn't caught up yet."
    )
    A(
        f"- The [Augment Sage](augment-sage.md)'s first mastery rank "
        f"(**{sage1['title']}**) unlocks automatically at Hunting League Rank "
        f"{sage1_hl} — nothing is consumed. It lifts your augment roll floor and "
        f"raises crit chance to {crit_r1}, and applies to every augment from here "
        f"on."
    )
    A("")
    A("### Rank IV–V (one to two months)")
    A("")
    A(
        f"- **Gold tier weapons** become the next major weapon goal. At "
        f"{_fmt(marks_per('gold', lo_g))} {currency} each, budget accordingly — "
        f"main job main-hand first."
    )
    A("- Reforge sets should be approaching +2/+3 in key slots by now.")
    A(
        f"- Earn **{infamy}** from endgame content and spend it at the "
        f"[Infamy Vendor](gear-vendors.md#infamy-vendor) — its pieces fill slots "
        f"where Reforge lags, or upgrade over +3 in select slots."
    )
    A(
        "- Register [Augment Sage](augment-sage.md) NM affinities for your main "
        "augment categories; the deeper mastery ranks unlock later through "
        "Prestige and Rebirth milestones."
    )
    A("")
    A("### Endgame")
    A("")
    A("- Full Gold-tier weapons across main and offhand.")
    A(
        "- Reforge +3 armor in all five slots (head/body/hands/legs/feet) for "
        "your main set."
    )
    A("- Infamy Vendor pieces in slots where they beat Reforge +3.")
    A(
        f"- Augment Moogle with rank-5 **{sage_top}** mastery (max roll floor, "
        f"{crit_hi} crit chance) and all {aff_count} NM affinities registered."
    )
    A(
        "- Register for [Hunter's Guild](hunters-guild.md) rep on all four guilds "
        "to maximize mark yield from future farming."
    )
    A("")
    A("---")
    A("")

    # ---- quick reference ---------------------------------------------------
    A("## Quick reference: weapon cost in Hunt Marks")
    A("")
    A(f"| Tier | Medal cost | {currency} cost |")
    A("|---|---:|---:|")
    for tier in ("bronze", "silver", "gold"):
        lo, hi = cost[tier]
        medals = (
            f"{lo} {_plural(medal(tier))}"
            if lo == hi
            else f"{lo}–{hi} {_plural(medal(tier))}"
        )
        marks = (
            f"{_fmt(marks_per(tier, lo))} {currency}"
            if lo == hi
            else f"{_fmt(marks_per(tier, lo))}–{_fmt(marks_per(tier, hi))} {currency}"
        )
        A(f"| {_TIER_LABEL[tier]} | {medals} | {marks} |")
    A("")
    A("---")
    A("")
    A('!!! tip "One weapon at a time"')
    A(
        f"    Do not try to gear every job simultaneously. Pick your main job, get "
        f"its weapon to Gold, and build the armor set around it. Then move on to a "
        f"second job. {currency} are a finite resource per session — focus pays "
        f"off faster than spreading thin."
    )
    A("")

    return "\n".join(L)


# ---------------------------------------------------------------- entry point


def generate(repo_root: Path, docs_dir: Path) -> None:
    try:
        gear_text = _read(repo_root, "modules/custom/lua/gear_progression_catalog.lua")
        hl_text = _read(repo_root, "modules/custom/lua/hunting_league_catalog.lua")
        rf_text = _read(repo_root, "modules/custom/lua/reforge_catalog.lua")
        inf_text = _read(repo_root, "modules/custom/lua/infamy_vendor_catalog.lua")
        sage_text = _read(repo_root, "modules/custom/lua/augment_sage_catalog.lua", required=False)
        aff_text = _read(repo_root, "modules/custom/lua/augment_affinity_catalog.lua", required=False)
        hl_module = _read(repo_root, "modules/custom/lua/HuntingLeague.lua", required=False)

        tiers = _parse_weapon_tiers(gear_text, repo_root)
        for t in ("bronze", "silver", "gold"):
            if not any(tiers[t].values()):
                raise _Skip(f"gear_progression_catalog.lua: {t} tier parsed empty")

        seals = weapons_npc._parse_tier_currency(gear_text)
        if set(seals) < {"bronze", "silver", "gold"}:
            raise _Skip(f"gear_progression_catalog.lua: seal names incomplete ({seals})")

        seal_costs = _parse_hl_seal_costs(hl_text)
        missing = [seals[t] for t in ("bronze", "silver", "gold") if seals[t] not in seal_costs]
        if missing:
            raise _Skip(
                f"hunting_league_catalog.lua: no Hunt-Mark price for medal(s) {missing} "
                f"(shop rows parsed: {sorted(seal_costs)})"
            )

        curr_m = re.search(r"currencyName\s*=\s*['\"]([^'\"]+)['\"]", hl_text)
        inf_curr = re.search(r"currencyCv\s*=\s*['\"]([^'\"]+)['\"]", inf_text)

        sage = _parse_sage_ranks(sage_text) if sage_text else []
        crit = _parse_mult_table(sage_text, "critChance") if sage_text else []
        aff_count = (
            len(re.findall(r"\btrophy\s*=\s*\{\s*id\s*=", aff_text)) if aff_text else 0
        ) or 24

        data = {
            "zone":           _zone_display(gear_text),
            "currency":       curr_m.group(1) if curr_m else "Hunt Marks",
            "seals":          seals,
            "seal_costs":     seal_costs,
            "tiers":          tiers,
            "sortie":         _parse_sortie_costs(hl_text),
            "seal_multi_buy": bool(hl_module and "Buy 10  [" in hl_module and "isSealsCat" in hl_module),
            "reforge":        _parse_reforge_bits(rf_text),
            "infamy_name":    inf_curr.group(1) if inf_curr else "Infamy",
            "sage":           sage,
            "crit":           crit,
            "aff_count":      aff_count,
        }
    except (_Skip, RuntimeError, ValueError) as e:
        # RuntimeError/ValueError = a reused parser's own schema-regression
        # guard fired. Same fail-closed handling: keep the published page.
        print(f"{_TAG} skip: {e}")
        return

    content = _render(data)
    page = docs_dir / "progression" / "gear-guide.md"
    page.parent.mkdir(parents=True, exist_ok=True)
    page.write_text(content, encoding="utf-8")

    counts = {
        t: sum(len(rows) for rows in data["tiers"][t].values())
        for t in ("bronze", "silver", "gold")
    }
    medal_px = {t: data["seal_costs"][data["seals"][t]] for t in ("bronze", "silver", "gold")}
    print(
        f"{_TAG} wrote progression/gear-guide.md "
        f"(weapons {counts['bronze']}/{counts['silver']}/{counts['gold']} per tier, "
        f"medal prices {medal_px['bronze']}/{medal_px['silver']}/{medal_px['gold']} marks, "
        f"sortie {data['sortie']}, multi-buy={data['seal_multi_buy']})"
    )
