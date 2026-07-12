"""Full-page owner for docs/index.md — the site home page.

Rewritten from scratch on every docgen run: edit THIS module, never the .md
(hand edits are clobbered by design). Everything on the page that can be
derived from the live server is derived, so the home page can never drift:

  Live COUNTS / NAMES (parsed from modules/custom/lua/*):
    hunting_league_catalog.lua  — rank ladder names + tier count
    trust_skoll.lua             — custom-trust unlock rank + marks
    voidwatch_catalog.lua       — rift zone count
    augment_catalog.lua         — augment option count
    achievements.lua            — milestone count

  Live RATES (parsed from settings/main.lua + settings/map.lua):
    EXP / Capacity / Sparks / Gil / WS power / drop rate / level cap / speed /
    starting gil — substituted as REAL NUMBERS (not {{setting:...}} tokens),
    the same way rates_table.py fills the "rates at a glance" table. This is
    self-contained: it does NOT depend on settings_inject running afterwards,
    so the numbers show up even on builds where that pass is skipped.

  Live CONTENT ROSTER (scanned from docs/):
    Every page under endgame/ and economy/, plus a curated set of the
    progression/ system pages, is listed automatically with a one-line blurb
    pulled from the page itself. Add a new endgame or economy page and it
    appears on the home page on the next build — no edit here required.

A `[home_page] UNFEATURED` log line flags any progression/ system page that is
neither rostered nor explicitly ignored, so nothing quietly falls off the map.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source


# ---------------------------------------------------------------------------
# source text helpers
# ---------------------------------------------------------------------------
def _text(repo_root: Path, rel: str) -> str | None:
    src = resolve_source(repo_root, rel)
    return src.read_text(encoding="utf-8", errors="replace") if src else None


# ---------------------------------------------------------------------------
# settings parsing  (mirrors rates_table.py / settings_inject.py)
# ---------------------------------------------------------------------------
_SETTING_LINE = re.compile(r"^\s*([A-Z][A-Z0-9_]+)\s*=\s*(.+)$")


def _parse_settings(text: str) -> dict[str, str]:
    out: dict[str, str] = {}
    for raw in text.splitlines():
        m = _SETTING_LINE.match(raw.rstrip())
        if not m:
            continue
        name, rest = m.group(1), m.group(2)
        value = rest.split("--", 1)[0].strip().rstrip(",").strip()
        if len(value) >= 2 and value[0] in "'\"" and value[-1] == value[0]:
            value = value[1:-1]
        if value:
            out[name] = value
    return out


def _load_settings(repo_root: Path) -> dict[str, dict[str, str]]:
    out: dict[str, dict[str, str]] = {"main": {}, "map": {}}
    root = resolve_source(repo_root, "settings")
    if root is None:
        return out
    for label in ("main", "map"):
        p = root / f"{label}.lua"
        if p.exists():
            out[label] = _parse_settings(p.read_text(encoding="utf-8", errors="replace"))
    return out


def _fmt(raw: str, style: str) -> str:
    try:
        n = float(raw)
    except ValueError:
        return raw
    if style == "comma":
        return f"{int(n):,}" if n == int(n) else f"{n:,}"
    # plain number: 10.000 -> "10", 2.5 -> "2.5"
    return str(int(n)) if n == int(n) else f"{n:g}"


def _rate(settings: dict[str, dict[str, str]], qual: str | None, name: str,
          style: str = "num") -> str:
    """Real value if the setting is present, else the {{setting:...}} token so
    settings_inject can still resolve it as a last resort."""
    order = [qual] if qual else ["main", "map"]
    for q in order:
        raw = settings.get(q, {}).get(name)
        if raw is not None:
            return _fmt(raw, style)
    tok_qual = f"{qual}." if qual else ""
    tok_fmt = ":comma" if style == "comma" else (":int" if style == "int" else "")
    return f"{{{{setting:{tok_qual}{name}{tok_fmt}}}}}"


# ---------------------------------------------------------------------------
# live counts / names
# ---------------------------------------------------------------------------
def _facts(repo_root: Path) -> dict | None:
    hl = _text(repo_root, "modules/custom/lua/hunting_league_catalog.lua")
    if hl is None:
        return None

    f: dict = {}
    names = re.findall(r"name\s*=\s*'Rank [IVXL]+ - ([^']+)'", hl)
    f["ladder"] = " → ".join(names) if names else "Initiate → Legend"
    f["tierCount"] = len(names) or 5
    f["topRank"] = names[-1] if names else "Legend"

    trusts = _text(repo_root, "modules/custom/lua/trust_skoll.lua") or ""
    f["trusts"] = []
    for block in re.split(r"\{\s*\n", trusts):
        n = re.search(r"\bname\s*=\s*'(\w+)'", block)
        r = re.search(r"\brankReq\s*=\s*(\d+)", block)
        c = re.search(r"\b(?:cost|marksReq|markCost|marks)\s*=\s*(\d+)", block)
        if n and r and c:
            f["trusts"].append((n.group(1), int(r.group(1)), int(c.group(1))))

    vw = _text(repo_root, "modules/custom/lua/voidwatch_catalog.lua") or ""
    zone_names: set[str] = set()
    for zlist in re.findall(r"\bzones\s*=\s*\{([^}]*)\}", vw):
        zone_names |= set(re.findall(r"'([^']+)'", zlist))
    f["vwZones"] = len(zone_names)

    aug = _text(repo_root, "modules/custom/lua/augment_catalog.lua") or ""
    f["augCount"] = len(re.findall(r"\baugId\s*=", aug))

    ach = _text(repo_root, "modules/custom/lua/achievements.lua") or ""
    f["achCount"] = len(re.findall(r"\bid\s*=\s*'", ach))
    return f


# ---------------------------------------------------------------------------
# content roster — scanned straight from the docs pages so it self-syncs
# ---------------------------------------------------------------------------

# progression/ mixes systems with guides, tools, NPC pages and reference. The
# roster features the *systems*; everything below is intentionally not rostered
# on the home page (it lives elsewhere in the nav).
_PROG_IGNORE = {
    "index.md", "gear-guide.md", "gear-vendors.md", "gear-finder.md",
    "item-database.md", "item-finder.md", "augmenting-guide.md",
    "augment-calculator.md", "library.md", "hub.md", "leafallia.md",
    "gm-home.md", "title-vendor.md", "corvus.md", "skoll.md", "meat.md",
    "server-features.md", "death-penalty.md", "login-rewards.md",
    "cross-job-traits.md",  # covered by cross-job-abilities.md
    "augment-sage.md",      # covered by augments.md
    "hnm.md",               # covered by hunters-guild.md
    "prime-trials.md", "weapon-forge.md",  # covered by prime-armory.md
    "game-master.md",       # featured as "Wave Master" highlight
}

# Order the curated progression systems get listed in (anything present but not
# named here still appears, appended alphabetically).
_PROG_ORDER = [
    "prestige.md", "job-rebirth.md", "job-mastery.md", "reforge.md",
    "hunters-guild.md", "prime-armory.md", "spell-mastery.md",
    "cross-job-abilities.md", "augments.md", "capacity-farm.md",
    "subjob-exp.md", "weekly-hunts.md", "daily-board.md",
    "fellow-companion.md", "achievements.md",
]


# A `!!! tip "Summary"` (or note/info/...) admonition: capture the indented body.
_SUMMARY_RE = re.compile(
    r'^!!!\s+\w+\s+"Summary".*\n((?:[ \t]+.*\n?|[ \t]*\n)+)',
    re.MULTILINE,
)


def _clean(s: str) -> str:
    """Strip markdown decoration down to readable prose."""
    s = re.sub(r"<!--.*?-->", "", s)                     # html comments
    s = re.sub(r"!?\[([^\]]*)\]\([^)]*\)", r"\1", s)     # images/links -> text
    s = re.sub(r"\{[^}]*\}", "", s)                       # attr-list {...}
    s = s.replace("**", "").replace("*", "").replace("`", "").replace("#", "")
    return " ".join(s.split())


def _h1(text: str) -> str:
    for line in text.splitlines():
        s = line.strip().lstrip("﻿")
        if s.startswith("# "):
            t = _clean(s[2:])
            if t:
                return t
    return ""


def _titleize(stem: str) -> str:
    t = stem.replace("-", " ").replace("_", " ").title()
    return re.sub(r"\bNms\b", "NMs", t)


def _is_prose(s: str) -> bool:
    """A real sentence, not markup/heading/list/table/emblem."""
    if not s or s[0] in "#>|!-+*=[<{":
        return False
    if s.startswith(("---", "```")):
        return False
    if re.match(r"^\d+\.", s):
        return False
    return True


def _short_blurb(text: str) -> str:
    """One tight, clean sentence for a roster line."""
    text = text.lstrip("﻿")
    m = _SUMMARY_RE.search(text)
    if m:
        cand = _clean(m.group(1))
    else:
        cand = ""
        for raw in text.splitlines():
            s = raw.strip().lstrip("﻿")
            if not _is_prose(s):        # test raw line (keeps #, !, | markers)
                continue
            c = _clean(s)
            if c:
                cand = c
                break
    if not cand:
        return ""
    first = re.split(r"(?<=[.!?])\s+", cand)[0].strip()
    if len(first) > 160:
        first = first[:160].rsplit(" ", 1)[0].rstrip() + "…"
    return first


def _page_line(docs_dir: Path, rel: str) -> str | None:
    path = docs_dir / rel
    if not path.exists():
        return None
    text = path.read_text(encoding="utf-8", errors="replace")
    title = _h1(text) or _titleize(path.stem)
    # Escape a stray pipe so a blurb can't break the surrounding markdown.
    blurb = _short_blurb(text).replace("|", "\\|")
    tail = f" — {blurb}" if blurb else ""
    return f"- **[{title}]({rel})**{tail}"


def _section(docs_dir: Path, subdir: str, order: list[str],
             ignore: set[str]) -> tuple[list[str], list[str]]:
    """Return (rendered bullet lines, unfeatured filenames) for a docs subdir."""
    d = docs_dir / subdir
    if not d.is_dir():
        return [], []
    present = {p.name for p in d.glob("*.md")}
    featured = [n for n in order if n in present and n not in ignore]
    extras = sorted(present - set(order) - ignore)
    lines: list[str] = []
    for name in featured + extras:
        ln = _page_line(docs_dir, f"{subdir}/{name}")
        if ln:
            lines.append(ln)
    return lines, extras


def _roster(docs_dir: Path) -> tuple[str, list[str]]:
    """Build the grouped content roster + a list of unfeatured progression pages."""
    blocks: list[str] = []

    # Endgame & events — every page in the folder, auto-synced.
    endgame_lines, _ = _section(docs_dir, "endgame", order=[], ignore=set())
    if endgame_lines:
        blocks.append("### Endgame & events\n\n" + "\n".join(endgame_lines))

    # Core progression systems — curated, with a drift report for the rest.
    prog_lines, prog_extras = _section(docs_dir, "progression",
                                       order=_PROG_ORDER, ignore=_PROG_IGNORE)
    if prog_lines:
        blocks.append("### Core progression systems\n\n" + "\n".join(prog_lines))

    # Economy & services — every page in the folder, auto-synced.
    econ_lines, _ = _section(docs_dir, "economy", order=[], ignore=set())
    if econ_lines:
        blocks.append("### Economy & services\n\n" + "\n".join(econ_lines))

    return "\n\n".join(blocks), prog_extras


# ---------------------------------------------------------------------------
# render
# ---------------------------------------------------------------------------
def _render(f: dict, s: dict[str, dict[str, str]], roster_md: str) -> str:
    trust_costs = "; ".join(
        f"{name}: Rank {rank} + {cost:,}" for name, rank, cost in f["trusts"]
    ) or "unlocked via Hunting League rank + Hunt Marks"
    # Names from the parsed trust_skoll.lua roster so a rename/addition lands
    # here; the flavor line stays hand-tuned copy.
    trust_names = ", ".join(f"**{name}**" for name, _, _ in f["trusts"]) \
        or "**Gemma**, **Meat**, **Corvus**"
    vw_zones = f"{f['vwZones']} overworld zones" if f["vwZones"] else "overworld zones across Vana'diel"
    aug_count = f"{f['augCount']}" if f["augCount"] else "hundreds of"
    ach_count = f"{f['achCount']}" if f["achCount"] else "dozens of"

    # Live rate values (real numbers, with a token fallback baked in).
    exp_mob = _rate(s, "map", "EXP_RATE")
    exp_scr = _rate(s, "main", "EXP_RATE")
    cap_scr = _rate(s, "main", "CAPACITY_RATE")
    sparks = _rate(s, None, "SPARKS_RATE")
    gil = _rate(s, None, "GIL_RATE")
    wspow = _rate(s, "main", "WEAPON_SKILL_POWER", "num")
    drop = _rate(s, None, "DROP_RATE_MULTIPLIER")
    lvlcap = _rate(s, None, "INITIAL_LEVEL_CAP")
    base_spd = _rate(s, None, "BASE_SPEED")
    spd_cap = _rate(s, None, "SPEED_LIMIT")
    start_gil = _rate(s, None, "START_GIL", "comma")

    head = f"""\
---
hide:
  - navigation
  - toc
---

<div class="lgnd-hero" markdown="0">
  <h1 class="lgnd-hero__sr">FJB Relaunch — FFXI Private Server</h1>
  <img class="lgnd-hero__crest" src="assets/logo.png" alt="FJB crest">
  <p class="lgnd-hero__subtitle">Fresh Start Server</p>
  <hr class="lgnd-hero__rule">
  <p class="lgnd-hero__tagline">Extreme QoL. Fast progression. No grind tax.</p>
</div>

**Hit 99 today, into real endgame the same day — then chase best-in-slot for months. This is FFXI the way it should feel.**

The Relaunch is a fresh-start FFXI private server built around one idea: the grind should be *fun*, not a wall. We cut the mandatory busywork, kept the depth, and bolted on a deep custom endgame that gives you something real to chase — whether you've been playing for a week or a year. You'll be at the level cap in an afternoon and fighting your first superboss before you log off.

!!! tip "New Player? Start here."
    Don't know where to begin? The **[Getting Started guide](getting-started/index.md)** walks you through installing the client, connecting to the server, and taking your first steps — in about 20 minutes.

!!! note "Already playing? See what's new"
    The **[Changelog](changelog.md)** lists every recent update and balance change, newest first, grouped by week.

---

## What makes this server different

Retail FFXI is a masterpiece buried under 20 years of time-gating. Most private servers swing the other direction and trivialize everything. This server splits the difference:

- **Fast leveling, real endgame.** {exp_mob}× mob EXP (plus {exp_scr}× from books, FoV/GoV & Records of Eminence) gets you to 99 in an afternoon, not months. Then the *actual* game begins — dozens of custom systems built for the long haul.
- **Everything unlocked at creation.** Advanced jobs, all outpost warps, all maps, full inventory, subjob ready to go — no arbitrary gates.
- **Best-in-slot is earnable, not bought.** Reforge ladders, augments, and Prime weapons put the top gear at the end of a hunt, not a paywall.
- **No dead content.** Daily and weekly objectives, rotating events, always-popped NMs, and a market-maker economy mean there's always a reason to log in.
- **A small, friendly community.** No drama, no gatekeeping — just people who like this game.
"""

    highlights = f"""\
## Feature highlights

:crossed_swords: **Hunting League** — A custom {f['tierCount']}-rank NM hunting ladder. Fight your way from {f['ladder']}, unlocking gear, titles, and HL Points at every tier.

:crown: **Ascension** — The endgame *above* the endgame. Reaching {f['topRank']} opens a per-job, no-cap prestige track: re-clear the escalating Nightmare Court to bank Ascension Points and pour them into permanent stat boosts. The roster gets deadlier every 10 ascensions, so the climb never goes stale.

:shield: **Reforge system** — Three parallel NM mark ladders (AF, Relic, Empy) that upgrade full armor sets from base all the way to +3. Best-in-slot is earnable, not bought.

:crossed_swords: **Prime Armory** — Forge the server's top weapon tier. Clear the Prime Trials, then claim a Prime weapon built for your job — an apex chase for every DD, mage, and support.

:gem: **Augment Moogle** — {aug_count} augment options. Trade catalysts from NM kills to permanently customize your gear in ways retail never allowed, then push them further with the Augment Sage.

:trophy: **Wave Master** — An NPC arena in Escha - Ru'Aun that spawns themed NM waves for solo or group practice. Earn Hunt Marks. Flex on your friends.

:dart: **Hunter's Guild** — Four hunting guilds that rank up as you kill their NMs, permanently boosting the marks every kill pays out. Hit Grandmaster across all of them for the Trinity and Apex Hunter titles.

:boom: **Voidwatch** — Examine Planar Rifts scattered across {vw_zones}, fight tier-scaled Voidwalker NMs, and probe their hidden weaknesses to shape your rewards.

:sparkles: **Adventuring Fellow** — A personal companion any job can summon. It levels from your kills, and you build it however you like by spending its stat points.

:star: **Reimagined retail endgame** — Ambuscade, Dynamis – Divergence, Nyzul Isle, High-Tier Battlefields, Domain Invasion, Unity, Geas Fete and Abyssea — the classic battle content, retuned for a fresh-start server.

:game_die: **Something for every night** — A weekly raid boss, an endless gauntlet tower, a colosseum, a casino, chocobo derby, treasure hunts, scheduled invasions and seasonal events. Full list below.

:calendar: **No dead content** — A five-objective Weekly Hunt Board and a three-objective Daily Board reset on a clock, so there's always a fresh reason to log in.

:wolf: **Custom Trusts** — Allies you won't find on retail: {trust_names} — from a full healer / buffer / debuffer in a deceptively small package to an unkillable wall that never drops aggro, each earned through Hunting League progression.

:coin: **Living economy** — The auction house is never empty: a market-maker keeps thousands of gear listings stocked around the clock — a built-in price floor and gil sink — so you can actually *buy* your upgrades.

:medal: **Achievements & Leaderboards** — {ach_count} milestones that pay bonus marks and titles as you rack up first kills, tier climbs, and lifetime records — plus live server leaderboards (top hunters, fastest clears, most augments) to climb.
"""

    rates = f"""\
## Server rates

| Setting | Rate |
|---|---|
| EXP (mob kills) | {exp_mob}× |
| EXP (scripted: books, FoV/GoV, RoE) | {exp_scr}× |
| Capacity Points (scripted) | {cap_scr}× |
| Sparks | {sparks}× |
| Gil from quests | {gil}× |
| Magic / WS power | {wspow}× |
| Mob drop rate | {drop}× |
| Starting level cap | {lvlcap} (no Limit Break needed) |
| Run speed | {base_spd} base / {spd_cap} cap |
| Content | Through Seekers of Adoulin + Abyssea + all add-ons |

---

!!! note "These docs reflect the live Relaunch server"
    Every number on this page — server rates, augment counts, Hunting League tiers, the endgame roster below — is **generated straight from the Relaunch server's own data and page set** on each refresh, so what you read here is what's actually running in-game. Spot something that's drifted out of date? Flag it on Discord and it'll be fixed.
"""

    bonuses = f"""\
## New character bonuses

Every new character starts with:

- :moneybag: **{start_gil} Gil** in your wallet
- :school_satchel: **80 inventory slots** (the maximum)
- :world_map: **All maps** for every zone
- :round_pushpin: **All outpost warps** already unlocked
- :sparkles: **Advanced jobs unlocked** — no quest required
- :star: **Subjob unlocked** — use it at full level immediately
"""

    endgame = f"""\
## The full content roster

!!! info "The real game starts at 99."
    Most servers have nothing to do after you level cap. This one was built around that problem. Every system below is custom to the Relaunch — pick a thread and pull.

{roster_md}

---

*Think this sounds good? [Get started now.](getting-started/index.md) Or read [Retail Differences](changes/index.md) for the full breakdown — and check the [Changelog](changelog.md) for the latest updates.*
"""

    return "\n---\n\n".join([head, highlights, rates, bonuses, endgame])


def generate(repo_root: Path, docs_dir: Path) -> None:
    f = _facts(repo_root)
    if f is None:
        print("[home_page] skip: hunting_league_catalog.lua not found")
        return
    settings = _load_settings(repo_root)
    roster_md, prog_extras = _roster(docs_dir)
    (docs_dir / "index.md").write_text(_render(f, settings, roster_md), encoding="utf-8")

    rate_ok = bool(settings["main"] or settings["map"])
    print(f"[home_page] wrote index.md (ranks={f['tierCount']}, augs={f['augCount']}, "
          f"ach={f['achCount']}, vwZones={f['vwZones']}, trusts={len(f['trusts'])}, "
          f"rates={'live' if rate_ok else 'TOKENS (settings not found)'})")
    if prog_extras:
        print(f"[home_page] UNFEATURED progression pages (add to _PROG_ORDER or "
              f"_PROG_IGNORE in home_page.py): {', '.join(prog_extras)}")
