"""Generate docs/getting-started/progression-guide.md — the stage-by-stage
progression narrative — entirely from the live catalogs.

FULL-PAGE writer (idiom: spells.py): the narrative frame (stage structure,
headings, the "Short Version" ASCII flow, the Supporting Systems table) is a
template in this module; every rank name, mark value, currency, unlock cost,
NM roster, and zone inside it is parsed from:

  modules/custom/lua/hunting_league_catalog.lua   ranks, marks/kill, unlock
                                                  costs, medal shop, hub zone
  modules/custom/lua/reforge_catalog.lua          3 mark tracks, NM pools,
                                                  marks ladder, upgrade costs
  modules/custom/lua/Augment_Moogle.lua           TIER_GATES / TIER_SLICES
                                                  (the augment tier ladder)
  modules/custom/lua/augment_sage_catalog.lua     mastery rank milestones+crit
  modules/custom/lua/augment_affinity_catalog.lua affinity count / gate / cost
  modules/custom/lua/infamy_vendor_catalog.lua    Infamy currency + stock shape
  modules/custom/lua/prestige_catalog.lua         unlock tier, Court bosses,
                                                  ascension cost curve
  modules/custom/lua/daily_login_bonus.lua        (optional) daily marks
  modules/custom/lua/login_streak.lua             (optional) streak milestones
  modules/custom/lua/weekly_hunts_catalog.lua     (optional) sweep bonus/gates

Parsing reuses the helpers progression_order.py / progression_map.py /
augment_sage.py already run against the same catalogs, so this page cannot
drift from the generated progression map.

Fail-closed: if a required catalog is missing or parses empty/short, print a
skip and leave the existing page untouched. Heading text is kept byte-stable
so existing deep links (#stage-3--reforge-system-mid-to-late etc.) survive.
No last-updated footer — stamp.py owns that.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen.generators.progression_order import (
    _balanced_blocks,
    _parse_hl_tiers,
    _parse_hl_currency,
)
from tools.docgen.generators.progression_map import (
    _parse_aug_tiers,
    _parse_sage_ranks,
)
from tools.docgen.generators.augment_sage import (
    _parse_mult_table,
    _parse_affinity_gate,
)

_TAG = "[progression_guide_page]"

# This generator rewrites the whole page, so — unlike marker-based pages — it
# must emit the last-updated footer marker itself. stamp.py (runs last) strips
# this block, hashes the body, and rewrites it with the real timestamp +
# content-hash, so the placeholder below is only ever seen pre-stamp.
_FOOTER_STUB = (
    "---\n\n"
    '<!-- DOCGEN:BEGIN id="last-updated" -->\n'
    "_Last updated: pending first generation._\n"
    '<!-- DOCGEN:END id="last-updated" -->'
)


# ---------------------------------------------------------------- systems catalog
# The full custom-systems constellation, grouped into filter buckets for the
# interactive card grid (rendered by tools/docgen/templates/progression_systems_widget.html).
# Each entry is a docs page (relative to docs/); its title + blurb are
# AUTO-EXTRACTED from that page's H1 and `!!! "Summary"` admonition at build
# time, so the guide can never drift from the systems' own pages. To add a
# system, drop its page into a group (for anything under endgame/, the
# completeness guard flags it if you forget). "where" is the short command/zone
# shown on the card. Group label = the filter chip + the card's tag.
_CATALOG_GROUPS: list[tuple[str, list[tuple[str, str]]]] = [
    ("Weapons & Mastery", [
        ("progression/prime-armory.md",     "!leaf"),
        ("progression/weapon-forge.md",     "!leaf"),
        ("endgame/job-mastery.md",          "!leaf"),
        ("progression/spell-mastery.md",    "!leaf"),
        ("progression/cross-job-traits.md", "!leaf"),
        ("progression/fellow-companion.md", "!fellow"),
    ]),
    ("Infinite Chases", [
        ("endgame/apex-paragon.md",   "!apex"),
        ("endgame/voidspire.md",      "Escha-RuAun"),
        ("endgame/endless-tower.md",  "!leaf"),
        ("endgame/colosseum.md",      "!leaf"),
    ]),
    ("Bosses & Battlefields", [
        ("endgame/star-devourer.md",          "Escha-RuAun · weekly"),
        ("endgame/the-gauntlet.md",           "Riverne A01"),
        ("endgame/high-tier-battlefields.md", "!leaf"),
        ("endgame/maats-challenge.md",        "Ru'Lude Gardens"),
        ("endgame/nyzul-isle.md",             "Mhaura"),
    ]),
    ("World NMs", [
        ("endgame/voidwatch.md",          "!voidwatch"),
        ("endgame/unity-concord.md",      "!lib"),
        ("endgame/abyssea-nms.md",        "Abyssea"),
        ("endgame/affinity-nms.md",       "overworld"),
        ("endgame/dynamis-divergence.md", "city Dynamis"),
        ("endgame/invasions.md",          "scheduled"),
        ("endgame/domain-invasion.md",    "scheduled"),
        ("endgame/tournament.md",         "!leaf"),
    ]),
    ("Activities", [
        ("endgame/casino.md",               "!gmhome"),
        ("endgame/chocobo-derby.md",        "!lib"),
        ("endgame/treasure-hunts.md",       "overworld"),
        ("endgame/provisioners-league.md",  "!lib"),
        ("endgame/seasonal-events.md",      "seasonal"),
        ("endgame/dungeons.md",             "instanced"),
    ]),
    # The former "Supporting Systems" table — now filterable cards alongside the rest.
    ("Supporting", [
        ("progression/login-rewards.md",       "automatic"),
        ("progression/daily-board.md",         "!lib"),
        ("progression/weekly-hunts.md",        "!lib"),
        ("progression/hunters-guild.md",       "passive"),
        ("progression/game-master.md",         "!wavemaster"),
        ("progression/cross-job-abilities.md", "!leaf"),
        ("progression/achievements.md",        "in-game"),
    ]),
]

# endgame/*.md pages intentionally NOT given their own card because the
# spine/narrative already owns them. Keep in sync so the completeness guard
# below stays quiet for genuinely-covered pages.
_ENDGAME_COVERED_ELSEWHERE = {
    "endgame/index.md",
}


class _Skip(Exception):
    """Raised when a required source is missing/unparseable — fail closed."""


def _read(repo_root: Path, rel: str, required: bool = True) -> str | None:
    src = resolve_source(repo_root, rel)
    if src is None:
        if required:
            raise _Skip(f"source not found: {rel}")
        return None
    return src.read_text(encoding="utf-8", errors="replace")


def _fmt(n: int) -> str:
    return f"{n:,}"


def _plural_medal(name: str) -> str:
    """'Beastmens Medal' -> 'Beastmens Medals' (display convention on this page)."""
    return name if name.endswith("s") else name + "s"


def _zone_from_path(text: str, field: str = "huntZonePath") -> str | None:
    m = re.search(rf"{field}\s*=\s*['\"]xi\.zones\.([^'\"]+)['\"]", text)
    return m.group(1).replace("_", " ") if m else None


# ---------------------------------------------------------------- reforge


def _parse_reforge(text: str) -> dict:
    """catalog.sources: three tracks with label, currencyName, and the NM
    ladder (name, marks). Also upgradeCost plus1/2/3 per set and the zone."""
    anchor = re.search(r"catalog\.sources\s*=", text)
    if not anchor:
        raise _Skip("reforge_catalog.lua: catalog.sources not found")
    block_start = text.find("{", anchor.end())
    span = next(_balanced_blocks(text[block_start:]), None)
    if span is None:
        raise _Skip("reforge_catalog.lua: catalog.sources block unbalanced")
    body = text[block_start + span[0] + 1: block_start + span[1] - 1]

    tracks: list[dict] = []
    for key in ("af", "relic", "empy"):
        km = re.search(rf"\b{key}\s*=\s*", body)
        if not km:
            continue
        sub = body[km.end():]
        inner = next(_balanced_blocks(sub), None)
        if inner is None:
            continue
        tbody = sub[inner[0] + 1: inner[1] - 1]
        label_m = re.search(r"\blabel\s*=\s*'([^']+)'", tbody)
        curr_m = re.search(r"\bcurrencyName\s*=\s*'([^']+)'", tbody)
        mobs = [
            (name, int(marks))
            for name, marks in re.findall(
                r"\{\s*name\s*=\s*'([^']+)'[^\n]*?\bmarks\s*=\s*(\d+)", tbody
            )
        ]
        if not (label_m and curr_m and mobs):
            continue
        tracks.append({
            "key":      key,
            "label":    label_m.group(1),
            "currency": curr_m.group(1),
            "mobs":     [(n.replace("_", " "), p) for n, p in mobs],
        })

    if len(tracks) != 3 or any(len(t["mobs"]) < 3 for t in tracks):
        raise _Skip(
            f"reforge_catalog.lua: expected 3 tracks with NM ladders, "
            f"parsed {len(tracks)}"
        )

    upgrade = {}
    for key, p1, p2, p3 in re.findall(
        r"(af|relic|empy)\s*=\s*\{\s*plus1\s*=\s*(\d+)\s*,\s*plus2\s*=\s*(\d+)\s*,\s*plus3\s*=\s*(\d+)",
        text,
    ):
        upgrade[key] = (int(p1), int(p2), int(p3))

    return {
        "tracks":  tracks,
        "upgrade": upgrade,
        "zone":    _zone_from_path(text) or "Gwora-Corridor",
    }


# ---------------------------------------------------------------- misc parsers


def _parse_seal_names(gear_text: str) -> dict[str, str]:
    """gear_progression_catalog.seals: tier -> medal display name. Scope to the
    `catalog.seals` block FIRST — the tier keys are reused as the weapon tables
    below, so a whole-file scan grabbed the first weapon's name (e.g. "Tokko
    Knife") as the medal, which then failed the HL-shop price lookup."""
    block = re.search(r"catalog\.seals\s*=\s*\{(.*?)\n\}", gear_text, re.DOTALL)
    scope = block.group(1) if block else gear_text
    out = {}
    for tier, name in re.findall(
        r"(bronze|silver|gold)\s*=\s*\{[^}]*?name\s*=\s*['\"]([^'\"]+)['\"]",
        scope,
    ):
        out[tier] = name
    return out


def _parse_seal_costs(hl_text: str) -> dict[str, int]:
    """Hunt-Mark price per medal from the HL reward shop (name -> cost)."""
    return {
        name: int(cost)
        for name, cost in re.findall(
            r"\{\s*name\s*=\s*['\"]([^'\"]+)['\"]\s*,\s*id\s*=\s*\d+\s*,\s*cost\s*=\s*(\d+)",
            hl_text,
        )
    }


def _parse_prestige(text: str) -> dict:
    def num(pattern: str, what: str) -> int:
        m = re.search(pattern, text)
        if not m:
            raise _Skip(f"prestige_catalog.lua: could not parse {what}")
        return int(m.group(1))

    trial = re.findall(r"\{\s*groupId\s*=\s*\d+\s*,\s*label\s*=\s*'([^']+)'", text)
    if len(trial) < 3:
        raise _Skip(f"prestige_catalog.lua: trial NM labels parsed {len(trial)}")
    mark_name = re.search(r"markName\s*=\s*'([^']+)'", text)
    ap_name = re.search(r"apName\s*=\s*'([^']+)'", text)
    return {
        "unlockTier": num(r"unlockTier\s*=\s*(\d+)", "unlockTier"),
        "costBase":   num(r"markCostBase\s*=\s*(\d+)", "markCostBase"),
        "costCap":    num(r"markCostCap\s*=\s*(\d+)", "markCostCap"),
        "trial":      trial[:3],
        "markName":   mark_name.group(1) if mark_name else "Hunt Marks",
        "apName":     ap_name.group(1) if ap_name else "Ascension Points",
        "zone":       _zone_from_path(text, "zonePath") or "Provenance",
    }


_ROMAN = {1: "I", 2: "II", 3: "III", 4: "IV", 5: "V"}


def _roman(n: int) -> str:
    return _ROMAN.get(n, str(n))


# ------------------------------------------------------ endgame page extraction


def _clean_blurb(text: str) -> str:
    """Make a page summary safe + compact for a link list here:
    - collapse resolved  <!--npc:KEY-->ZONE<!--/npc-->  to just ZONE
    - drop any leftover {{setting:...}}/{{npc:...}} tokens' wrappers to text
    - strip markdown links to their text (their relative paths are relative to
      the SOURCE page and would break when quoted from getting-started/)
    - collapse whitespace; keep the first 1–2 sentences.
    """
    text = re.sub(r"<!--npc:[^>]*?-->(.*?)<!--/npc-->", r"\1", text)
    text = re.sub(r"\{\{npc:([^}|]+)(?:\|[^}]*)?\}\}", "", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)   # [text](url) -> text
    text = re.sub(r"\s+", " ", text).strip().lstrip("﻿").strip()
    # Trim to the first two sentences so the list stays scannable.
    parts = re.split(r"(?<=[.!?])\s+", text)
    if len(parts) > 2:
        text = " ".join(parts[:2])
    return text


def _extract_page_summary(docs_dir: Path, rel: str) -> tuple[str, str] | None:
    """Return (title, blurb) for a docs page, or None if the file is absent.

    title = first `# ` heading. blurb = the `!!! ... "Summary"` admonition body
    if present, else the first prose paragraph after the H1.
    """
    page = docs_dir / rel
    if not page.exists():
        return None
    raw = page.read_text(encoding="utf-8", errors="replace")

    title_m = re.search(r"^﻿?#\s+(.+?)\s*$", raw, re.M)
    title = title_m.group(1).strip() if title_m else Path(rel).stem.replace("-", " ").title()

    # Primary: the Summary admonition (indented lines right after the marker).
    blurb = ""
    adm = re.search(r'^!!!\s+\w+\s+"Summary"\s*$', raw, re.M)
    if adm:
        body_lines = []
        for line in raw[adm.end():].splitlines()[1:]:
            if line.strip() == "":
                if body_lines:
                    break
                continue
            if line.startswith("    ") or line.startswith("\t"):
                body_lines.append(line.strip())
            else:
                break
        blurb = " ".join(body_lines)

    # Fallback: first prose paragraph after the H1 (skip blanks/markers/tables).
    if not blurb:
        start = title_m.end() if title_m else 0
        para: list[str] = []
        for line in raw[start:].splitlines():
            s = line.strip()
            if not s:
                if para:
                    break
                continue
            if s.startswith(("#", "---", "<!--", "|", "!!!", "```", "![", "<div")):
                if para:
                    break
                continue
            para.append(s)
        blurb = " ".join(para)

    return title, _clean_blurb(blurb)


def _build_systems_widget(repo_root: Path, docs_dir: Path) -> str | None:
    """Build the interactive systems card-grid widget: JSON data (one card per
    system, auto-extracted title/blurb) injected into the shared widget template.

    Runs a completeness guard: any endgame/*.md page not placed in a group (and
    not covered elsewhere) prints a WARN so a newly-added system can't silently
    miss the guide. Returns the widget HTML, or None if the template is missing
    (caller falls back to a plain list so the page is never left widget-less).
    """
    listed = {rel for _chip, rows in _CATALOG_GROUPS for rel, _where in rows}
    for page in sorted((docs_dir / "endgame").glob("*.md")):
        rel = f"endgame/{page.name}"
        if rel not in listed and rel not in _ENDGAME_COVERED_ELSEWHERE:
            print(f"{_TAG} WARN: {rel} is in neither a catalog group nor the "
                  f"covered-elsewhere set — it will be missing from the guide.")

    cards: list[dict] = []
    for chip, rows in _CATALOG_GROUPS:
        for rel, where in rows:
            got = _extract_page_summary(docs_dir, rel)
            if got is None:
                continue  # page absent this run — skip rather than emit a dead card
            title, blurb = got
            cards.append({
                "groupLabel": chip,
                "tag":        chip,
                "name":       title,
                "blurb":      blurb,
                "where":      where,
                "href":       f"../{rel}",
            })

    template = repo_root / "tools" / "docgen" / "templates" / "progression_systems_widget.html"
    if not template.exists() or not cards:
        return None
    html = template.read_text(encoding="utf-8")
    payload = json.dumps(cards, ensure_ascii=False, separators=(",", ":"))
    if "/*__DATA__*/ []" not in html:
        print(f"{_TAG} WARN: DATA placeholder not found in widget template")
        return None
    return html.replace("/*__DATA__*/ []", payload, 1)


def _fallback_systems_list(docs_dir: Path) -> list[str]:
    """Plain grouped link-list — used only if the widget template is missing, so
    the systems catalog is never dropped entirely."""
    L: list[str] = ["## Endgame Content — What to Chase at the Top", ""]
    for chip, rows in _CATALOG_GROUPS:
        L += [f"### {chip}", ""]
        for rel, where in rows:
            got = _extract_page_summary(docs_dir, rel)
            if got is None:
                continue
            title, blurb = got
            tail = f" _({where})_" if where else ""
            L.append(f"- **[{title}](../{rel})** — {blurb}{tail}")
        L.append("")
    L += ["---", ""]
    return L


def _rank_word(tier: dict) -> str:
    """'Rank V - Legend' -> 'Legend' (the bare title used in prose)."""
    name = tier["name"]
    return name.split("-", 1)[1].strip() if "-" in name else name


# ---------------------------------------------------------------- render


def _render(d: dict, docs_dir: Path, widget_html: str | None) -> str:
    hl        = d["hl"]                      # list of tier dicts (progression_order shape)
    currency  = d["currency"]                # 'Hunt Marks'
    hub       = d["hub_zone"]                # 'Escha ZiTah'
    seals     = d["seals"]                   # tier -> medal name
    seal_cost = d["seal_costs"]              # medal name -> marks
    rf        = d["reforge"]
    gates     = d["gates"]                   # [(tier, unlock text)]
    sage      = d["sage"]                    # rank dicts from progression_map
    crit      = d["crit"]                    # critChance list
    aff       = d["aff"]                     # dict: count, rankReq, markCost, sample
    prest     = d["prestige"]
    daily     = d["daily"]                   # int | None
    streaks   = d["streaks"]                 # [days,...] | None
    weekly    = d["weekly"]                  # dict | None

    t = {x["tier"]: x for x in hl}
    bronze = _plural_medal(seals.get("bronze", "Beastmens Medal"))
    gold   = _plural_medal(seals.get("gold", "Demons Medal"))

    def pts(tier_no: int) -> int:
        mobs = t[tier_no]["mobs"]
        return mobs[0]["points"] if mobs else 0

    # Rank V is heterogeneous (a boss NM can pay more): common value + outliers.
    t5_counts: dict[int, int] = {}
    for m in t[5]["mobs"]:
        t5_counts[m["points"]] = t5_counts.get(m["points"], 0) + 1
    t5_common = max(t5_counts, key=lambda p: t5_counts[p])
    t5_specials = [(m["label"], m["points"]) for m in t[5]["mobs"] if m["points"] != t5_common]
    t5_special_txt = (
        " (" + ", ".join(f"{lbl} pays {p}" for lbl, p in t5_specials) + ")"
        if t5_specials else ""
    )

    t4_labels = ", ".join(m["label"] for m in t[4]["mobs"])
    legend    = _rank_word(t[5])

    # Reforge marks ladder (identical across tracks by design; describe the range).
    all_marks = sorted({p for trk in rf["tracks"] for _, p in trk["mobs"]})
    rf_lo, rf_hi = all_marks[0], all_marks[-1]
    up = rf["upgrade"].get("af")

    streak_txt = "/".join(str(s) for s in streaks) if streaks else "7/14/21/30"
    daily_txt  = f"+{daily}" if daily is not None else "bonus"

    crit_lo = f"{crit[0] * 100:.0f}%" if crit else "5%"
    crit_hi = f"{crit[-1] * 100:.0f}%" if crit else "30%"
    sage_top = sage[-1]["title"] if sage else "Augment Archon"

    aff_sample = ", ".join(aff["sample"])

    # Tier-2 augment gate is worth calling out at Rank V (it's the HL payoff).
    # Only claimed while the live gate actually keys off HL Rank 5.
    gate2 = next((u for g, u in gates if g == 2), None)
    rank5_gate_note = (
        f" Reaching Rank {_ROMAN[5]} is also an **Augment Tier key** — it opens "
        f"the Tier 2 roll band at the Augment Moogle."
        if gate2 and "Rank 5" in gate2 else ""
    )

    weekly_note = ""
    if weekly and weekly.get("sweep"):
        weekly_note = (
            f" Sweeping all 5 in one week pays a **{_fmt(weekly['sweep'])} {currency}** bonus."
        )

    L: list[str] = []
    A = L.append

    A("# Progression Guide")
    A("")
    A(
        "This page maps the full the Relaunch server progression arc from a new "
        "character to endgame Prestige. If you haven't done setup yet, start with "
        "[First Steps](first-steps.md) — this guide picks up after your character "
        "is ready and you've made your first Hunting League kills."
    )
    A("")
    A("---")
    A("")
    A("## The Short Version")
    A("")
    A("```")
    A("Setup → Hunting League (Rank I–V) → Reforge System")
    A("     → Augmenting → Infamy & Endgame → Prestige (infinite)")
    A("```")
    A("")
    A(
        "Every system on this server feeds marks into that path. The Hunting League "
        "is the spine; everything else branches off it. Once you're geared and "
        "into Prestige, the **[Endgame Content](#endgame-content)** section below "
        "is the full catalog of what to chase — apex weapons, infinite "
        "leaderboard climbs, raid bosses, and world-NM systems."
    )
    A("")
    A("---")
    A("")

    # ---- Stage 1 ------------------------------------------------------
    A("## Stage 1 — Hunting League Rank I–III (Early)")
    A("")
    A(f"**Goal:** Accumulate {currency} and unlock Rank {_ROMAN[3]}.")
    A("")
    A(
        f"The Hunting League is a ladder of NM-hunting ranks at "
        f"[{hub}](../progression/index.md), from {_rank_word(t[1])} up to "
        f"{legend}. Each rank unlocks stronger NMs, better gear vendors, and "
        f"higher marks-per-kill ({pts(1)} per kill at Rank {_ROMAN[1]}, rising to "
        f"{t5_common} at Rank {_ROMAN[5]}). Your first priority is climbing ranks "
        f"quickly so the marks-per-hour improves — Rank {_ROMAN[2]} unlocks at "
        f"**{_fmt(t[2]['unlockCost'])}** lifetime marks and Rank {_ROMAN[3]} at "
        f"**{_fmt(t[3]['unlockCost'])}**. The full rank list — each rank's NMs, "
        f"marks-per-kill, and unlock cost — is in "
        f"[The Ranks](../progression/index.md#the-ranks)."
    )
    A("")
    A(
        f"**What to buy early:** The Bronze gear tier ({bronze}, "
        f"{seal_cost[seals['bronze']]} {currency} each) from the "
        f"[Gear Vendors](../progression/gear-vendors.md) at {hub}. Bronze pieces "
        f"are inexpensive and cover the gear gap until you have Silver and Gold."
    )
    A("")
    A("**Parallel tracks to start now:**")
    A("")
    A(
        f"- **[Login Rewards](../progression/login-rewards.md)** — log in daily for "
        f"{daily_txt} marks, hit {streak_txt}-day streaks for bonuses."
    )
    A(
        "- **[Daily Board](../progression/daily-board.md)** — the NPC at "
        "{{npc:daily_board}} (`!lib`) gives 3 daily objectives. Complete them for "
        "extra marks and a full-clear bonus."
    )
    A("")
    A("---")
    A("")

    # ---- Stage 2 ------------------------------------------------------
    A("## Stage 2 — Hunting League Rank IV–V (Mid)")
    A("")
    A(f"**Goal:** Reach Rank {_ROMAN[5]} ({legend}) and start farming {t5_common}-mark kills.")
    A("")
    A(
        f"At Rank {_ROMAN[4]} (**{_fmt(t[4]['unlockCost'])}** lifetime marks) you "
        f"unlock King-class HNMs — {t4_labels}. These are significantly harder than "
        f"mid-tier NMs but drop much better and pay **{pts(4)} marks** each. Party "
        f"up if possible."
    )
    A("")
    A(
        f"At **Rank {_ROMAN[5]}** (**{_fmt(t[5]['unlockCost'])}** lifetime marks) "
        f"you're at the top of the Hunting League. Rank {_ROMAN[5]} NMs pay "
        f"**{t5_common} marks** each{t5_special_txt} and your gear vendor unlocks "
        f"Gold-tier items ({gold}). More importantly, **Prestige unlocks** — see "
        f"Stage 6.{rank5_gate_note}"
    )
    A("")
    A(
        f"**What to buy at {_ROMAN[5]}:** Gold gear ({gold}, "
        f"{seal_cost[seals['gold']]} {currency} each) from the "
        f"vendor. This is your gear floor while you pursue Reforge and Augments."
    )
    A("")
    A(
        f"**Weekly Hunts:** Each week a fresh set of objectives rotates in (kill "
        f"NMs, partied kills, speed kills, no-death streaks). The board is open at "
        f"any rank, but each objective is gated by its own Hunting League rank "
        f"requirement — the hardest need Rank {_ROMAN[5]}, so the full sweep is a "
        f"{legend}-tier feat.{weekly_note} See "
        f"[Weekly Hunt Board](../progression/weekly-hunts.md)."
    )
    A("")
    A("---")
    A("")

    # ---- Stage 3 ------------------------------------------------------
    A("## Stage 3 — Reforge System (Mid to Late)")
    A("")
    A(
        "**Goal:** Earn AF, Relic, and Empyrean marks from their respective NM "
        "systems and build per-job gear sets."
    )
    A("")
    A(f"The [Reforge System](../progression/reforge.md) runs on three separate mark currencies:")
    A("")
    A("| Currency | NM family | The ladder |")
    A("|---|---|---|")
    for trk in rf["tracks"]:
        ladder = " → ".join(n for n, _ in trk["mobs"])
        A(f"| {trk['currency']} | {trk['label']} ({rf['zone']}) | {ladder} |")
    A("")
    A(
        f"Each track is a five-step difficulty ladder: entry NMs pay **{rf_lo} "
        f"marks** per kill and the apex NM of each track pays **{rf_hi}** — the "
        f"highest marks-per-kill content on the server."
    )
    A("")
    up_txt = (
        f" (+1 costs {_fmt(up[0])}, +2 {_fmt(up[1])}, +3 {_fmt(up[2])} of that "
        f"set's marks per piece)" if up else ""
    )
    A(
        f"Spend marks at the Reforge NPCs in {rf['zone']} to get job-specific "
        f"AF/Relic/Empy gear sets at IL (item level) scaling, upgraded from base "
        f"through +3{up_txt}."
    )
    A("")
    A(
        "**Hunter's Guild builds here.** Killing Reforge NMs builds "
        "[Hunter's Guild](../progression/hunters-guild.md) reputation in the "
        "matching guild (AF / Relic / Empy). Higher guild rank means more marks "
        "per kill from that guild — it's a passive multiplier that snowballs over "
        "time."
    )
    A("")
    A("---")
    A("")

    # ---- Stage 4 ------------------------------------------------------
    A("## Stage 4 — Augmenting (Late)")
    A("")
    A("**Goal:** Stamp custom augments onto your gear to push stats past their base caps.")
    A("")
    A(
        "The [Augment Moogle](../progression/augments.md) in {{npc:augment_moogle}} "
        "(`!leaf`) lets you trade catalyst items to apply custom stat augments to "
        "any piece of equipment. Hundreds of augment types are available across "
        "many stat families — Attack, Accuracy, Crit, TP Bonus, Cure Potency, and "
        "more. The full "
        "[catalyst → augment catalog](../progression/augments.md#catalyst-augment-catalog) "
        "lists every one."
    )
    A("")
    A(
        f"Every augment line is **rolled**, and your roll band is gated by content: "
        f"the **Augment Tier ladder** (Tiers 1–{len(gates)}) runs from your first "
        f"custom NM kills to the endgame super-fights, and each tier's rolls sit "
        f"strictly above the last. The "
        f"[Augmenting guide](../progression/augmenting-guide.md) walks the whole "
        f"ladder."
    )
    A("")
    A("**The Augment Sage** sits next to the Moogle and adds two roll boosters:")
    A("")
    A(
        f"- **Mastery ranks:** Unlock automatically at content milestones "
        f"(Hunting League Rank, Prestige Level, Rebirths — nothing is consumed). "
        f"Each rank raises your roll floor by +1 inside your tier's band and lifts "
        f"your critical-augment chance from {crit_lo} to {crit_hi} — a crit makes "
        f"every line in the trade land at the top of your band."
    )
    A(
        f"- **NM Affinities:** Kill specific Vana'diel NMs ({aff_sample}, and more "
        f"— {aff['count']} in all) for their unique trophies, then register each "
        f"at the Augment Sage (Hunting League Rank {aff['rankReq']} + "
        f"{_fmt(aff['markCost'])} {currency} per affinity) to **roll twice and "
        f"keep the better** result in that stat category."
    )
    A("")
    A(
        f"Stack a max-rank crit with an affinity at the top Augment Tier and a "
        f"line writes its absolute cap — the {sage_top} ceiling."
    )
    A("")
    A(
        "See [Augment Sage](../progression/augment-sage.md) for the full rank "
        "requirements, NM list, and roll math."
    )
    A("")
    A("---")
    A("")

    # ---- Stage 5 ------------------------------------------------------
    A("## Stage 5 — Infamy & Endgame (Late)")
    A("")
    A(f"**Goal:** Earn {d['infamy_name']} from endgame content and spend it at the Infamy Vendor.")
    A("")
    A(
        f"**{d['infamy_name']}** is earned across the server's endgame — Abyssea "
        f"NM hunts, scheduled Invasions, and the weekly Raid, among others. Spend "
        f"it at the [Infamy Vendor](../progression/gear-vendors.md#infamy-vendor) "
        f"in {{{{npc:infamy_vendor}}}}, which sells gear found nowhere else: "
        f"relic-tier weapons, bard instruments, best-in-slot armor, and per-job "
        f"+4 Reforge Sets."
    )
    A("")
    A("---")
    A("")

    # ---- Stage 6 ------------------------------------------------------
    A("## Stage 6 — Prestige / Ascension (Endgame · Infinite)")
    A("")
    A(
        f"**Goal:** Unlock Prestige at Rank {_roman(prest['unlockTier'])}, clear "
        f"the Nightmare Court, and accumulate per-job {prest['apName']}."
    )
    A("")
    A(
        f"[Prestige](../progression/prestige.md) is an infinite per-job progression "
        f"layer that unlocks the moment you reach Hunting League "
        f"**Tier {_roman(prest['unlockTier'])} ({legend})**. Travel to the "
        f"Ascension Altar in {prest['zone']} (`!provenance`) to begin."
    )
    A("")
    A("**Each ascension cycle:**")
    A("")
    boss_bits = " · ".join(f"**{b}**" for b in prest["trial"])
    A(
        f"1. **Clear the Nightmare Court** — three superbosses summoned one at a "
        f"time at the Altar: {boss_bits}. All three must be killed on every cycle; "
        f"kills don't carry over (and the Court's roster deepens as your Prestige "
        f"Level climbs)."
    )
    A(
        f"2. **Pay the Mark cost** — it starts at {_fmt(prest['costBase'])} "
        f"{prest['markName']}, rises by {_fmt(prest['costBase'])} with each "
        f"ascension, and plateaus at a {_fmt(prest['costCap'])} cap (see the "
        f"[Ascension Economy](../progression/prestige.md#ascension-economy))."
    )
    A(f"3. **Earn {prest['apName']} (AP)** for your current main job.")
    A("")
    A(
        "**Spend AP** at the Altar on permanent per-job stat boosts: base stats, "
        "combat traits, magic support, mitigation, utility. Every stat has a level "
        "cap, and there's a wide spread of purchasable categories — see the "
        "[AP Spend Table](../progression/prestige.md#ap-spend-table). With "
        "infinite ascensions at the capped cost each, this is the true long-term "
        "chase."
    )
    A("")
    A("---")
    A("")

    # ---- Systems catalog: the interactive filter-chip card grid (matches the
    # Weapon Forge widget's design language). The former "Supporting Systems"
    # table is folded in as its own filter group, so it's gone from here. ----
    A("## Endgame Content — What to Chase at the Top { #endgame-content }")
    A("")
    A(
        "The spine above (Hunting League → Reforge → Augments → Prestige) is the "
        "backbone. The top of the server is a whole constellation of custom "
        "systems — **filter by kind below, then pick one** to read what it is and "
        "where to start. Each card links to its own page, where the numbers are "
        "generated live."
    )
    A("")
    if widget_html:
        A(widget_html)
    else:
        L.extend(_fallback_systems_list(docs_dir))
    A("")
    A("---")
    A("")

    # ---- Marks economy (constant frame, owning-page links) ------------
    A("## Quick Reference — Marks Economy")
    A("")
    A(
        "Marks flow in from every system on this page, and a couple of sinks pull "
        "them back out. Rather than restate the numbers here (where they could "
        "drift), each lives on its owning page:"
    )
    A("")
    A(
        f"- **Hunting League kills** scale up with rank ({pts(1)} → {t5_common} "
        f"marks) — see [The Ranks](../progression/index.md#the-ranks)."
    )
    A(
        f"- **Reforge NM kills** climb a per-track ladder ({rf_lo} → {rf_hi} "
        f"marks) — the top NMs are the highest marks-per-kill content — see "
        f"[NM pools and rewards](../progression/reforge.md#nm-pools-and-rewards)."
    )
    A(
        "- **Daily login + streak milestones** — see "
        "[Login Rewards](../progression/login-rewards.md)."
    )
    A(
        "- **Daily Board** and **Weekly Hunt Board** sweeps — see "
        "[Daily Board](../progression/daily-board.md) and "
        "[Weekly Hunt Board](../progression/weekly-hunts.md)."
    )
    A(
        "- **Sinks:** the Hunting League reward shop, rank unlocks, and each "
        "Prestige ascension (see the "
        "[Ascension Economy](../progression/prestige.md#ascension-economy))."
    )
    A("")
    A(
        "On top of all of it, your "
        "**[Hunter's Guild](../progression/hunters-guild.md)** rank multiplies "
        "every kill's marks — at Grandmaster a Legend kill pays roughly double, "
        "and the Apex Hunter capstone pushes it higher still. The guild track is "
        "a long grind but the payoff is real."
    )
    A("")

    return "\n".join(L)


# ---------------------------------------------------------------- entry point


def generate(repo_root: Path, docs_dir: Path) -> None:
    try:
        hl_text = _read(repo_root, "modules/custom/lua/hunting_league_catalog.lua")
        rf_text = _read(repo_root, "modules/custom/lua/reforge_catalog.lua")
        moogle_text = _read(repo_root, "modules/custom/lua/Augment_Moogle.lua")
        sage_text = _read(repo_root, "modules/custom/lua/augment_sage_catalog.lua")
        aff_text = _read(repo_root, "modules/custom/lua/augment_affinity_catalog.lua")
        inf_text = _read(repo_root, "modules/custom/lua/infamy_vendor_catalog.lua")
        prest_text = _read(repo_root, "modules/custom/lua/prestige_catalog.lua")
        gear_text = _read(repo_root, "modules/custom/lua/gear_progression_catalog.lua")

        hl = _parse_hl_tiers(hl_text)
        if len(hl) != 5:
            raise _Skip(
                f"expected exactly 5 Hunting League tiers, parsed {len(hl)} — "
                "the stage narrative assumes 5; restage the template by hand."
            )

        slices, gates = _parse_aug_tiers(moogle_text)
        sage = _parse_sage_ranks(sage_text)
        crit = _parse_mult_table(sage_text, "critChance")

        aff_rank, aff_marks = _parse_affinity_gate(aff_text)
        aff_rows = re.findall(r"\bnm\s*=\s*'([^']+)'", aff_text)
        aff_count = len(re.findall(r"\btrophy\s*=\s*\{\s*id\s*=", aff_text))
        if aff_count == 0:
            raise _Skip("augment_affinity_catalog.lua: no affinity rows parsed")

        inf_m = re.search(r"currencyCv\s*=\s*['\"]([^'\"]+)['\"]", inf_text)

        daily_text = _read(repo_root, "modules/custom/lua/daily_login_bonus.lua", required=False)
        streak_text = _read(repo_root, "modules/custom/lua/login_streak.lua", required=False)
        weekly_text = _read(repo_root, "modules/custom/lua/weekly_hunts_catalog.lua", required=False)

        daily = None
        if daily_text:
            m = re.search(r"DAILY_BONUS\s*=\s*(\d+)", daily_text)
            daily = int(m.group(1)) if m else None
        streaks = None
        if streak_text:
            rows = re.findall(r"\{\s*(\d+)\s*,\s*\d+\s*,", streak_text)
            streaks = [int(x) for x in rows] or None
        weekly = None
        if weekly_text:
            m = re.search(
                r"allClearedReward\s*=\s*\{[^}]*?amount\s*=\s*(\d+)", weekly_text, re.DOTALL
            )
            weekly = {"sweep": int(m.group(1))} if m else None

        seals = _parse_seal_names(gear_text)
        seal_costs = _parse_seal_costs(hl_text)
        for t in ("bronze", "gold"):
            if seals.get(t) not in seal_costs:
                raise _Skip(
                    f"medal price lookup failed: seals[{t!r}]={seals.get(t)!r} "
                    f"not in HL shop rows {sorted(seal_costs)}"
                )

        data = {
            "hl":          hl,
            "currency":    _parse_hl_currency(hl_text),
            "hub_zone":    _zone_from_path(hl_text) or "Escha ZiTah",
            "seals":       seals,
            "seal_costs":  seal_costs,
            "reforge":     _parse_reforge(rf_text),
            "gates":       gates,
            "sage":        sage,
            "crit":        crit,
            "aff": {
                "count":    aff_count,
                "rankReq":  aff_rank,
                "markCost": aff_marks,
                "sample":   [n.replace("_", " ") for n in aff_rows[:3]],
            },
            "infamy_name": inf_m.group(1) if inf_m else "Infamy",
            "prestige":    _parse_prestige(prest_text),
            "daily":       daily,
            "streaks":     streaks,
            "weekly":      weekly,
        }
    except (_Skip, RuntimeError, ValueError) as e:
        # RuntimeError/ValueError = a reused parser's own schema-regression
        # guard fired. Same fail-closed handling: keep the published page.
        print(f"{_TAG} skip: {e}")
        return

    widget_html = _build_systems_widget(repo_root, docs_dir)
    content = _render(data, docs_dir, widget_html).rstrip() + "\n\n" + _FOOTER_STUB + "\n"
    page = docs_dir / "getting-started" / "progression-guide.md"
    page.parent.mkdir(parents=True, exist_ok=True)
    page.write_text(content, encoding="utf-8")
    rf_tracks = data["reforge"]["tracks"]
    print(
        f"{_TAG} wrote getting-started/progression-guide.md "
        f"(5 HL ranks, {len(rf_tracks)} reforge tracks, {len(data['gates'])} augment tiers, "
        f"{len(data['sage'])} sage ranks, {data['aff']['count']} affinities, "
        f"prestige unlock tier {data['prestige']['unlockTier']})"
    )
