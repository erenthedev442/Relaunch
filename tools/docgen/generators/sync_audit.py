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

    if not unowned and not naked and not mirrors:
        print("[sync_audit] OK — every published page is generator-owned, no "
              "naked facts in hand prose, no mirrored runtime constants.")
