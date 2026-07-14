"""Docs sync audit (relaunch) — ENFORCES the owner rule that every server fact
on the player site is emitted by a doc generator, so custom-content changes
auto-populate the site and pages never silently drift.

Two checks, both WARN-loud at the end of every docgen run (same contract as
coverage_check — a human reads the run log; nothing here fails the build):

1. PAGE OWNERSHIP — every published page must be one of:
     * rewritten whole-file by a generator (WHOLE_PAGE below), or
     * marker-based: holds at least one content DOCGEN block, or
     * allowlisted in PAGE_ALLOWLIST (redirect stubs etc.).
   Anything else prints a loud [sync_audit] UNOWNED-PAGE warning.

2. NAKED FACTS — on marker-based pages, hand prose OUTSIDE the DOCGEN blocks
   is scanned for drift-prone server facts: currency amounts (gil / marks /
   beads / silt / accolades / points / sigils / hallmarks / gallantry),
   rate multipliers (Nx), and large tunable numbers. Each hit warns unless
   (page, snippet) is allowlisted in FACT_ALLOWLIST with a reason.
   When you tune content, the number must move INSIDE a generator block —
   extend the page's generator, use a {{setting:...}} token, or genericize
   the prose ("see the table below").

3. MIRROR CONSTANTS — a generator that re-defines a runtime Lua knob as a
   module-level numeric constant (e.g. `TRASH_RATE = 30` shadowing
   `local TRASH_RATE = 30` in modules/custom/lua) is invisible to check 2
   (its output IS a generator block — just wrong after a retune). This bit
   twice on 2026-07-11: dungeons.md claimed "treasure pool"/x5 boss loot and
   affinity-nms.md a "15-minute" respawn, all from stale mirrors. Generators
   must PARSE the runtime value (patterns: augment_dungeon_drops.py _KNOB_RE,
   affinity_nms.py RESPAWN_SECONDS); any name collision warns unless
   allowlisted in MIRROR_ALLOWLIST with a reason.

Pages excluded from the published site (mkdocs_relaunch.yml exclude_docs) and
generated per-player profile pages are skipped.
"""
from __future__ import annotations

import re
from pathlib import Path

# Pages rewritten WHOLE-FILE by a generator each run (no markers needed —
# their prose IS generator output). Keep in sync when adding a full-page
# owner; an unlisted whole-page-generated page will warn as UNOWNED-PAGE,
# which is the prompt to classify it here.
WHOLE_PAGE = {
    "index.md",                          # home_page.py
    "changelog.md",                      # changelog_relaunch.py
    "rules.md",                          # rules_page.py
    "why-legendary.md",                  # differentiators.py
    "community/faq.md",                  # faq_page.py
    "community/highlights.md",           # highlights_page.py
    "reference/commands.md",             # commands.py
    "reference/glossary.md",             # glossary_page.py
    "reference/index.md",                # spells.py / hand index (small)
    "getting-started/index.md",          # getting_started_pages.py
    "getting-started/downloads.md",      # downloads_page.py
    "getting-started/install.md",        # getting_started_pages.py
    "getting-started/connect.md",        # getting_started_pages.py
    "getting-started/first-steps.md",    # getting_started_pages.py
    "getting-started/troubleshoot.md",   # getting_started_pages.py
    "getting-started/cheat-sheet.md",    # progression_guide_page.py
    "getting-started/your-session.md",   # your_session.py
    "progression/hub.md",                # hub_pages.py
    "progression/leafallia.md",          # hub_pages.py
    "progression/library.md",            # hub_pages.py
    "progression/subjob-exp.md",         # subjob_exp_page.py
    "progression/gear-guide.md",         # gear_guide_page.py
    "progression/augmenting-guide.md",   # augmenting_guide_page.py
    "progression/gear-finder.md",        # gear_finder.py
    "changes/background-systems.md",     # background_systems_page.py
    "endgame/nyzul-isle.md",             # nyzul_page.py
    "admin/page-index.md",               # page_index.py
    "admin/missing-spells.md",           # missing_spells.py (excluded from nav anyway)
    "community/players/index.md",        # player_profiles.py
    "admin/review.html",                 # legacy_review_page.py
}

# Whole DIRECTORIES of generated pages (computed filenames).
WHOLE_PAGE_DIRS = ("reference/spells/", "community/players/")

# Published pages allowed to have no generator owner, with the reason.
PAGE_ALLOWLIST = {
    "getting-started/progression-guide.md": "redirect stub -> cheat-sheet",
}

# mkdocs_relaunch.yml exclude_docs — not published, out of scope.
EXCLUDED = (
    "admin/gear-coverage/",
    "admin/missing-spells.md",
    "admin/unfeatured-systems.md",
    "admin/module-ownership.md",
)

# (page, exact snippet) pairs reviewed and accepted as non-drifting. Every
# entry needs a reason. Prefer FIXING the page over allowlisting — use a
# {{lua:...}} / {{setting:...}} token or point prose at the generated table.
FACT_ALLOWLIST: dict[tuple[str, str], str] = {
    ("changes/index.md", "30,000"):
        "engine enmity cap (CE/VE clamp) — C++ constant, not a tunable catalog value",
    ("endgame/casino.md", "25,000 gil"):
        "worked example illustrating the generated 2x even-money payout table",
    ("progression/hnm.md", "38 Hunt Marks"):
        "Rank IV per-kill marks; duplicates the generated Hunting League ladder (verified 2026-07-11)",
    ("progression/hunters-guild.md", "150 marks"):
        "apex reforge NM award, hunters_guild_catalog.lua table value (verified 2026-07-11)",
    ("progression/index.md", "2420"):
        "illustrative Shinryu DEF example from hunting_league_catalog.lua (verified 2026-07-11)",
    ("progression/index.md", "2700"):
        "illustrative Leaping Lizzy ATT example from hunting_league_catalog.lua (verified 2026-07-11)",
    ("progression/index.md", "5,300 marks"):
        "arithmetic sum of the four rank-unlock gates shown in the generated ladder",
    ("progression/index.md", "1000"):
        "retail Hunt Registry scyld cap — stock LSB behaviour, not custom-tuned",
    ("progression/job-rebirth.md", "2,100"):
        "retail total job points per job — engine constant",
    ("reference/ws-vs-retail.md", "131,071"):
        "17-bit client damage-display cap — engine constant",
    ("reference/ws-vs-retail.md", "250000"):
        "illustrative chat-whisper example, not a tuned value",
    ("progression/login-rewards.md", "75 marks"):
        "verbatim streak chat-message example; the streak table on this page is generated",
    ("changes/index.md", "50,000"):
        "retail comparison value (Prismatic Hourglass) — static by design",
    ("progression/hunters-guild.md", "1,540"):
        "derived kill-count estimate, not a tuned value",
}

# (generator filename, constant name) pairs reviewed and accepted. Every entry
# needs a reason; prefer parsing the runtime file over allowlisting.
MIRROR_ALLOWLIST: dict[tuple[str, str], str] = {}

# (generator filename, line-substring) pairs accepted as non-drifting. Only add
# entries here when a shadow-literal hit is coincidental (the number matched a
# Lua constant by luck, not by mirroring it). Prefer converting the site to
# lua_const() over allowlisting.
SHADOW_LITERAL_ALLOWLIST: dict[tuple[str, str], str] = {}

# Custom Lua modules that are legitimately NOT referenced by any docs file --
# plumbing, internal libraries, dev tools, etc. Every entry needs a reason so
# a reviewer can decide later whether the module actually became player-facing
# (2026-07-13 owner escalation "make sure this always stays updated" -- 5-page
# progression-sidebar audit turned up 17 player-facing modules with no doc row
# each; the coverage check below fires ONE WARN per uncovered module so future
# additions can't hide the same way).
MODULE_COVERAGE_ALLOWLIST: dict[str, str] = {
    # ---- engine plumbing / shared libraries -----------------------------
    "module_utils.lua":              "engine plumbing (Module class + override glue)",
    "mob_mechanics_library.lua":     "shared boss-mechanic library used by other modules; not a user-facing feature",
    "auto_message_scaling.lua":      "internal message-scaling helper called from mob scripts",
    "damage_scaling.lua":            "internal damage-scaling helper",
    "npcutil_backport.lua":          "npcUtil retrofit for stock scripts; engine layer",
    "spawn_scaling.lua":             "internal mob-scaling helper",
    "regional_buff_helper.lua":      "helper wired by !buff; the command is documented, this file is not",
    "affinity_ki_gate.lua":          "internal gate helper",
    "mob_leash_helper.lua":          "leash tuning helper",
    "prof_toggle_menu.lua":          "internal profiler toggle",
    "persist_nm_time_of_deaths.lua": "internal NM ToD persistence helper",
    "spawn_scaling.lua":             "internal mob-scaling helper (duplicate for safety)",
    "dungeon_zone.lua":              "internal Dungeon Instances zone helper; system IS documented",
    "hub_ambience.lua":              "internal hub-zone ambience (weather/day-night) helper",
    "invasion_loot_pool.lua":        "internal Invasion loot table; system IS documented",
    "legendary_ring_aura.lua":       "cosmetic aura on legendary rings; no player-facing menu",
    "nomad_moogle.lua":              "internal moogle helper; existing NPC dressing",
    "disable_dealer_moogle.lua":     "targeted stock-NPC override; internal",
    "climactic_flourish_consumer.lua": "internal WS consumer helper wired from JA code",
    "pet_magic_burst.lua":           "internal pet magic-burst behaviour helper",
    "daily_xp_tracker.lua":          "internal EXP tracker; feeds the Player Portal analytics",
    "new_char_trust_upgraded.lua":   "one-shot new-character trust upgrade; runs invisibly",
    # ---- Trust helpers ---------------------------------------------------
    "trust_meta.lua":                "trust metadata helper",
    "trust_naming.lua":              "trust display-name helper",
    "trust_stats_boost.lua":         "trust stat-boost helper wired from summoner code",
    "trust_baseline_boost.lua":      "trust baseline stat helper",
    "fellow_name.lua":               "fellow display-name helper; Fellow system IS documented",
    "trust_meat_vendor.lua":         "internal trust-meat NPC helper; system IS documented",
    # ---- System-internal data files whose parent system IS documented ---
    "affinity_nm_autopop.lua":       "autopop dispatcher; the Affinity NM system IS documented",
    "chocobo_raising_qol.lua":       "QoL helpers for stock chocobo raising -- no player-facing feature to name",
    "custom_HNM_system.lua":         "HNM King dispatcher; the HNMs / Sky Gods system IS documented",
    "world_first_announcements.lua": "server-wide announcement wiring; the Achievements system IS documented",
    "capacity_farm_helpers.lua":     "internal helpers for the Capacity Farm; the farm IS documented",
    "capacity_farm_common.lua":      "internal helpers for the Capacity Farm; the farm IS documented",
    "capacity_farm_engine.lua":      "engine for Capacity Farm; system IS documented",
    "capacity_farm_points.lua":      "points table for Capacity Farm; system IS documented",
    "ranperre_farm_points.lua":      "points table for Ranperre capacity farm; system IS documented",
    "omen_mechanics.lua":            "boss-mechanic wiring for Omen; system IS documented",
    "hunters_guild_hunts.lua":       "hunts table consumed by hunters_guild_catalog; guild IS documented",
    "unity_wanted_instance_runtime.lua": "Unity Wanted runtime; system IS documented",
    "gauntlet_champion_data.lua":    "static champion metadata for The Gauntlet; system IS documented",
    "prime_voucher_reward.lua":      "voucher-drop wiring for Prime Weapon Trial 1; system IS documented",
    "hl_seal_currency.lua":          "Hunt-League seal currency plumbing; system IS documented",
    # ---- Augment / Reforge internals ------------------------------------
    "augment_affinity_migrate11.lua": "one-shot migration to 11-affinity model; done, kept for late arrivals",
    "augment_catalyst_pools.lua":     "static catalyst pools consumed by Augment_Moogle; system IS documented",
    "augment_item_names.lua":         "static item-name table for Augment_Moogle labels",
    "reforge_mark_exchange_catalog.lua": "catalog consumed by ReforgeMarkExchange_NPC.lua (the NPC file IS the doc anchor)",
    "reforge_plus4_map.lua":         "static +3->+4 pair table; the Divergence +4 Forge IS documented",
    "abjuration_forge_catalog.lua":  "catalog consumed by AbjurationForge_NPC.lua (the NPC file IS the doc anchor)",
    # ---- REMA / Prime WS enhancement ------------------------------------
    "PrimeWeaponskillTuning.lua":    "engine for the REMA WS Enhancement system; the system IS documented",
    "prime_ws_tuning_catalog.lua":   "catalog for REMA WS Enhancement; system IS documented",
    "rema_ws_tier_catalog.lua":      "catalog for REMA WS Enhancement; system IS documented",
    # ---- Open-World Scaling ---------------------------------------------
    "OpenWorldScaling.lua":          "always-on scaling of open-world mobs to the relaunch curve",
    "open_world_scaling_catalog.lua": "catalog for open-world scaling; internal",
    # ---- Deferred: needs a doc row in a follow-up commit ----------------
    # (leave AbjurationForge intentionally OFF the allowlist so a future
    # session sees it flagged and adds it to the Gear Guide.)
}

# Module-level ALL_CAPS numeric assignment in a generator / `local` in Lua.
_PY_CONST_RE  = re.compile(r"^([A-Z][A-Z0-9_]{2,})\s*=\s*(-?\d+(?:\.\d+)?)\s*(?:#.*)?$", re.M)
_LUA_LOCAL_RE = re.compile(r"^local\s+([A-Z][A-Z0-9_]{2,})\s*=\s*(-?\d+(?:\.\d+)?)", re.M)


def _mirror_constants(repo_root: Path) -> list[tuple[str, str, str, str, str]]:
    """(generator, const, py_value, lua_file, lua_value) for every generator
    ALL_CAPS numeric constant whose name is also a runtime Lua local."""
    lua_dir = repo_root / "modules" / "custom" / "lua"
    if not lua_dir.is_dir():
        return []
    lua_locals: dict[str, tuple[str, str]] = {}
    for lua in sorted(lua_dir.glob("*.lua")):
        for m in _LUA_LOCAL_RE.finditer(lua.read_text(encoding="utf-8", errors="replace")):
            lua_locals.setdefault(m.group(1), (lua.name, m.group(2)))

    hits: list[tuple[str, str, str, str, str]] = []
    for py in sorted(Path(__file__).parent.glob("*.py")):
        if py.name == Path(__file__).name:
            continue
        for m in _PY_CONST_RE.finditer(py.read_text(encoding="utf-8", errors="replace")):
            name, val = m.group(1), m.group(2)
            if name in lua_locals and (py.name, name) not in MIRROR_ALLOWLIST:
                lua_file, lua_val = lua_locals[name]
                hits.append((py.name, name, val, lua_file, lua_val))
    return hits


# ---------------------------------------------------------------------------
# Shadow-literal drift scanner.
#
# The original MIRROR-CONST check only fires when a Python module-level ALL_CAPS
# assignment shares a NAME with a Lua `local`. That misses the common cases:
#   * bare literal inside a dict:  "pct": 50.0
#   * fallback default:            c.get("rusted_qty", 12)
#   * renamed constant:            CATALYST_PCT = 50  (Lua local is DROP_RATE)
#
# Shadow-literals scans every generator source for numeric literals that match
# ANY Lua constant's value, in a drift-prone context. Findings are WARN, not
# fatal -- but they surface every docgen run so no new drift can hide.
#
# Signal-shaping: only "drift-prone contexts" fire. A literal is flagged when
# it appears
#   (a) on a line matching _DRIFT_CONTEXT_RE (pct/qty/cost/rate/count keys,
#       or a percentage-string like `50%`), AND
#   (b) it is >= 6 or has a decimal (skip {0..5} = too many false positives
#       for iterator seeds / small collection sizes / signs), AND
#   (c) it matches a value assigned via `local X = N` in some Lua module, AND
#   (d) the same line does NOT already call `lua_const(` nor carry a
#       `# @from-lua` marker nor a `# not-lua:` exemption.
# ---------------------------------------------------------------------------
# A line is drift-prone if a literal appears right after a known drift-prone
# dict-key OR a known drift-prone ALL_CAPS variable assignment. We DON'T fire
# on bare "N%" prose strings -- those match too many math conversions
# (percent-of-100, ms-to-sec) and produce mostly noise.
_DRIFT_LINE_RE = re.compile(
    r'''(?xi)
        # dict-key -> value:  "pct": N.N  or  'qty': N
        ["'](?:pct|qty|cost|rate|count|weight|tier|chance|amount|drop_rate
              |droprate|drop|percent|prob|probability|max_rolls|threshold)["']
            \s*:\s*(-?\d+(?:\.\d+)?)
        |
        # ALL_CAPS mirror name assignment at any indent:
        #   DROP_RATE = 10 / TRASH_RATE = 30 / MAX_ROLLS = 5
        \b([A-Z][A-Z0-9_]*(?:PCT|RATE|QTY|COST|CHANCE|COUNT|WEIGHT|TIER
            |ROLLS|SEC(?:ONDS)?|MINUTES?|HOURS?|LIMIT|MAX|MIN))\b
            \s*=\s*(-?\d+(?:\.\d+)?)\b
    '''
)
_LUA_CONST_CALL_RE = re.compile(r"lua_const\s*\(")
_FROM_LUA_MARKER_RE = re.compile(r"#\s*@from-lua\b|#\s*not-lua\b")

# Signs / iterator seeds / tiny counts / "guaranteed" sentinel. Any other
# value with a drift-keyword-tagged Lua-side name must be inspected on each hit.
# 100 IS a common drop-rate knob but it's also the universal "guaranteed" and
# percent-scale value, so collisions are overwhelmingly incidental -- the
# Lua-name filter below (`_DRIFT_KEYWORD_RE` on the constant name) restores
# specificity for the values that stay in.
_CONVERSION_LITERALS = {0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 100.0}

# Only match Lua constants whose NAME hints at a tunable knob. Filters out
# purely mechanical constants (JP_PER_LEVEL, MAAT_GROUP_ZID, byte budgets,
# byte masks) that happen to share a value with an unrelated Python literal.
_DRIFT_KEYWORD_RE = re.compile(
    r"RATE|PCT|PERCENT|QTY|QUANTITY|COST|CHANCE|COUNT|WEIGHT|TIER"
    r"|ROLLS|DROP|RESPAWN|AMOUNT|LIMIT|MAX|MIN|BONUS|TOLL|PRICE|FEE"
    r"|CHARGE|POINTS|MARKS|REWARD|PAYOUT|DAMAGE|DMG|POWER|SECONDS?|MINUTES?",
    re.IGNORECASE,
)


def _shadow_literals(repo_root: Path) -> list[tuple[str, int, str, float, list[str]]]:
    """(generator, line#, snippet, literal, [lua_files_hosting_the_value])

    Warns for every literal on a drift-prone line that also happens to be a
    live Lua constant value. Skips lines that already call lua_const() or
    carry a `# @from-lua` / `# not-lua` marker.
    """
    from tools.docgen._lua_consts import scan_lua_constants
    lua = scan_lua_constants(repo_root)   # {lua_file: [(name, val), ...]}
    if not lua:
        return []
    # Build value -> list of (lua_file, name). Only index constants whose NAME
    # looks like a tuning knob (drift keyword). Skips JP_PER_LEVEL / group ids /
    # byte masks so their coincidental values don't spam the report.
    val_index: dict[float, list[tuple[str, str]]] = {}
    for lua_file, hits in lua.items():
        for name, val in hits:
            if not _DRIFT_KEYWORD_RE.search(name):
                continue
            val_index.setdefault(val, []).append((lua_file, name))

    gen_dir = Path(__file__).parent
    # Cover both the per-generator dir and the shared helpers one level up
    # (_item_sources.py, _paths.py, ...). Dedup via `seen` below so a file
    # matched by both globs isn't scanned twice.
    parent_dirs = [gen_dir, gen_dir.parent]
    py_files: list[Path] = []
    for d in parent_dirs:
        py_files.extend(sorted(d.glob("*.py")))
    seen: set[Path] = set()

    # Files whose whole reason for existing is DESCRIBING the shadow-literal
    # pattern. Their docstrings quote example literals; exempt them so the
    # scanner doesn't recurse on its own explanation.
    HELPER_EXEMPT = {"_lua_consts.py", "sync_audit.py"}

    hits: list[tuple[str, int, str, float, list[str]]] = []
    for py in py_files:
        if py in seen or py.name == Path(__file__).name:
            continue
        if py.name in HELPER_EXEMPT:
            continue
        seen.add(py)
        try:
            src = py.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        for lineno, line in enumerate(src.splitlines(), 1):
            # Skip pure-comment lines: a comment describing "the Lua line
            # `RATE = 10` becomes ..." isn't drift, it's prose. Code that
            # actually emits a Rate value into a doc is not a comment.
            if line.lstrip().startswith("#"):
                continue
            if _LUA_CONST_CALL_RE.search(line) or _FROM_LUA_MARKER_RE.search(line):
                continue
            m = _DRIFT_LINE_RE.search(line)
            if not m:
                continue
            # The literal is captured in group 1 (dict-key form) or group 3
            # (ALL_CAPS mirror). group(2) is the mirror name in the second arm.
            lit_str = m.group(1) or m.group(3)
            if lit_str is None:
                continue
            try:
                v = float(lit_str)
            except ValueError:
                continue
            if v in _CONVERSION_LITERALS:
                continue
            sources = val_index.get(v)
            if not sources:
                continue
            snippet = line.strip()
            if (py.name, snippet) in SHADOW_LITERAL_ALLOWLIST:
                continue
            # Prefer Lua matches whose NAME hints at the same concept as the
            # Python line (higher confidence). Fall back to raw value matches
            # if no name match wins.
            preferred = [(lf, nm) for lf, nm in sources
                         if any(tok in line.lower()
                                for tok in (nm.lower(),))]
            top = preferred if preferred else sources
            lua_refs = [f"{lf}:{nm}" for lf, nm in top[:3]]
            hits.append((py.name, lineno, snippet[:120], v, lua_refs))
    return hits


_BLOCK_RE = re.compile(
    r'<!--\s*DOCGEN:BEGIN\s+id="[^"]+"\s*-->.*?<!--\s*DOCGEN:END[^>]*-->',
    re.DOTALL,
)

# Drift-prone fact patterns, tuned for signal over recall:
#   * currency amounts:  "50,000 gil", "300 marks", "2000 beads", "150 Infamy"
#   * multipliers:       "25x EXP", "x21 BP", "5× drops"
#   * big bare numbers:  standalone 4+ digit (or comma-grouped) figures
_CURRENCY = (
    r"gil|hunt\s*marks?|marks?|beads?|silt|accolades?|infamy|sigils?|"
    r"hallmarks?|gallantry|points?|medals?|paragon|voidstones?|standing"
)
_FACT_RES = [
    ("currency", re.compile(r"\b\d[\d,]*\s*(?:%s)\b" % _CURRENCY, re.IGNORECASE)),
    ("multiplier", re.compile(r"\b\d+(?:\.\d+)?\s*[x×]\b|\b[x×]\s*\d+(?:\.\d+)?\b", re.IGNORECASE)),
    ("big-number", re.compile(r"(?<![\w.,])\d{1,3}(?:,\d{3})+(?![\w,])|(?<![\w.,])\d{4,}(?![\w,])")),
]

# Lines that are pure markdown plumbing — never facts.
_SKIP_LINE = re.compile(
    r"^\s*(?:\||#|<!--|---|https?://|\[.*\]:|!\[)|^\s*$"
)


def _published_pages(docs_dir: Path):
    # .html pages publish too and historically escaped every guard (the Legacy
    # review page drifted for a week — owner escalation 2026-07-11). They get
    # the same ownership check; being whole-page artifacts they skip the
    # naked-fact prose scan like any WHOLE_PAGE entry.
    pages = list(docs_dir.rglob("*.md")) + list(docs_dir.rglob("*.html"))
    for p in sorted(pages):
        rel = p.relative_to(docs_dir).as_posix()
        if any(rel.startswith(x) if x.endswith("/") else rel == x for x in EXCLUDED):
            continue
        yield rel, p


_EMBED_RE = re.compile(r"<(script|style)\b.*?</\1>", re.DOTALL | re.IGNORECASE)
_YEAR_RE = re.compile(r"^20\d\d$")
# Inline-injected spans are SYNCED content (settings_inject, lua_const_inject,
# npc_location_inject rewrite them every run) — blank them before scanning.
_INJECTED_RE = re.compile(
    r"<!--(setting|luaconst|npc):[^>]*-->.*?<!--/\1-->", re.DOTALL)


def _hand_prose(text: str) -> list[tuple[int, str]]:
    """Prose lines outside DOCGEN blocks, with original line numbers.

    Skips <script>/<style> bodies (page plumbing — a hand-mirrored constant in
    there still shows up via its Lua source going out of sync, and the known
    one is tracked by its generator) and strips link targets / URLs / HTML
    tags so item ids and hex colors don't read as facts."""
    # Blank out generated blocks and embeds but keep line structure.
    def blank(m: re.Match) -> str:
        return "\n" * m.group(0).count("\n")

    stripped = _BLOCK_RE.sub(blank, text)
    stripped = _EMBED_RE.sub(blank, stripped)
    stripped = _INJECTED_RE.sub("", stripped)
    out = []
    for i, line in enumerate(stripped.splitlines(), 1):
        if _SKIP_LINE.match(line):
            continue
        line = re.sub(r"\]\([^)]*\)", "]", line)   # markdown link targets
        line = re.sub(r"https?://\S+", "", line)   # bare URLs
        line = re.sub(r"<[^>]+>", "", line)        # HTML tags/attrs
        out.append((i, line))
    return out


def _uncovered_modules(repo_root: Path, docs_dir: Path) -> list[str]:
    """List custom Lua modules (modules/custom/lua/*.lua) whose filename is not
    referenced by ANY docs file (published .md + generators .py) and not on the
    allowlist. Fires ONCE PER MODULE with a WARN so a new custom system dropped
    in without a doc row cannot silently ship.

    Simple contract: the module's filename (bare, no path) must appear as text
    somewhere under docs/**/*.md OR tools/docgen/generators/*.py -- a
    presence-gate `have("modules/custom/lua/Foo.lua")` counts, a `.md` mention
    counts, a `require('modules/custom/lua/foo_catalog')` in a generator counts
    (via its bare stem).
    """
    lua_dir = repo_root / "modules" / "custom" / "lua"
    if not lua_dir.is_dir():
        return []

    modules = [p.name for p in sorted(lua_dir.glob("*.lua"))]

    haystacks: list[str] = []
    # Every published/staged .md
    for md in docs_dir.rglob("*.md"):
        try:
            haystacks.append(md.read_text(encoding="utf-8", errors="replace"))
        except OSError:
            pass
    # Every generator source
    gen_dir = Path(__file__).parent
    for py in gen_dir.glob("*.py"):
        try:
            haystacks.append(py.read_text(encoding="utf-8", errors="replace"))
        except OSError:
            pass
    corpus = "\n".join(haystacks)

    uncovered = []
    for mod in modules:
        if mod in MODULE_COVERAGE_ALLOWLIST:
            continue
        # Look for the full filename OR the bare stem (catalog files are usually
        # required by stem in generators, e.g. paragon_catalog).
        stem = mod[:-4]  # strip .lua
        if mod in corpus or stem in corpus:
            continue
        uncovered.append(mod)
    return uncovered


def generate(repo_root: Path, docs_dir: Path) -> None:  # noqa: ARG001
    unowned: list[str] = []
    naked: list[tuple[str, int, str, str]] = []

    for rel, path in _published_pages(docs_dir):
        text = path.read_text(encoding="utf-8", errors="replace")
        blocks = [m for m in re.finditer(r'DOCGEN:BEGIN\s+id="([^"]+)"', text)
                  if m.group(1) != "last-updated"]
        whole = rel in WHOLE_PAGE or rel.startswith(WHOLE_PAGE_DIRS)

        if not whole and not blocks:
            if rel not in PAGE_ALLOWLIST:
                unowned.append(rel)
            continue

        if whole:
            continue  # prose is generator output; nothing to scan

        for lineno, line in _hand_prose(text):
            for kind, rx in _FACT_RES:
                m = rx.search(line)
                if not m:
                    continue
                snippet = m.group(0).strip()
                if _YEAR_RE.match(snippet):
                    continue  # bare calendar year, not a tunable
                if (rel, snippet) in FACT_ALLOWLIST:
                    break  # reviewed line — don't re-flag it via a weaker pattern
                naked.append((rel, lineno, kind, snippet))
                break  # one report per line is enough

    if unowned:
        print("[sync_audit] UNOWNED-PAGE — published page with no generator "
              "owner (add a generator, a DOCGEN block, or allowlist):")
        for rel in unowned:
            print(f"  - {rel}")

    if naked:
        by_page: dict[str, list[tuple[int, str, str]]] = {}
        for rel, lineno, kind, snippet in naked:
            by_page.setdefault(rel, []).append((lineno, kind, snippet))
        print(f"[sync_audit] NAKED-FACT — {len(naked)} server fact(s) in hand "
              "prose outside DOCGEN blocks (move into a generator block, use a "
              "{{setting:...}} token, or allowlist with a reason):")
        for rel in sorted(by_page):
            hits = by_page[rel]
            print(f"  - {rel} ({len(hits)}):")
            for lineno, kind, snippet in hits[:8]:
                print(f"      L{lineno} [{kind}] {snippet!r}")
            if len(hits) > 8:
                print(f"      ... and {len(hits) - 8} more")

    mirrors = _mirror_constants(repo_root)
    if mirrors:
        print(f"[sync_audit] MIRROR-CONST — {len(mirrors)} generator constant(s) "
              "shadow a runtime Lua knob (parse the runtime file instead, or "
              "allowlist in MIRROR_ALLOWLIST with a reason):")
        for gen, name, val, lua_file, lua_val in mirrors:
            drift = "" if val == lua_val else f"  <-- DRIFTED (runtime is {lua_val})"
            print(f"  - {gen}: {name} = {val}  (runtime: {lua_file}){drift}")

    # Shadow-literal scan: catches the bare-literal / dict-value / rename cases
    # the name-mirror check above misses. Root cause of every "why does the doc
    # say 50% when the runtime is 10%" report to date.
    shadows = _shadow_literals(repo_root)
    if shadows:
        print(f"[sync_audit] SHADOW-LITERAL — {len(shadows)} generator literal(s) "
              "match a live Lua constant on a drift-prone line. Switch to "
              "lua_const() from tools/docgen/_lua_consts.py, or add a "
              "'# not-lua: <reason>' comment on the same line, or allowlist "
              "in SHADOW_LITERAL_ALLOWLIST with a reason:")
        for gen, lineno, snippet, lit, lua_refs in shadows[:30]:
            refs = ", ".join(lua_refs)
            print(f"  - {gen}:{lineno}  literal {lit}  matches {refs}")
            print(f"      {snippet}")
        if len(shadows) > 30:
            print(f"  ... and {len(shadows) - 30} more (rerun after the first "
                  "batch is fixed).")

    uncovered = _uncovered_modules(repo_root, docs_dir)
    if uncovered:
        print(f"[sync_audit] UNCOVERED-MODULE — {len(uncovered)} custom Lua "
              "module(s) not referenced by any generator or published doc "
              "(add a row to systems_map.py / progression_map.py / unlock_tree.py "
              "/ a hub page, or add to MODULE_COVERAGE_ALLOWLIST with a reason):")
        for mod in uncovered:
            print(f"  - modules/custom/lua/{mod}")

    if not unowned and not naked and not mirrors and not shadows and not uncovered:
        print("[sync_audit] OK — every published page is generator-owned, no "
              "naked facts in hand prose, no mirrored runtime constants, no "
              "shadow-literal drift, every custom module has doc coverage.")
