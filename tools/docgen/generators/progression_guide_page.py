"""Generate docs/getting-started/progression-guide.md — the **Cheat Sheet**: a
single interactive, filterable card grid of every custom system on the server.

FULL-PAGE writer. The page is just an H1 ("Cheat Sheet") plus the systems
card-grid widget — one card per system, its title + blurb AUTO-EXTRACTED from
that system's own detail page (its H1 and `!!! "Summary"` admonition) at build
time, so the cheat sheet can never drift from the systems' own pages. The card
grid markup lives in tools/docgen/templates/progression_systems_widget.html;
this module owns the catalog of which pages get a card and how they're grouped.

To add a system, drop its page into a group in `_CATALOG_GROUPS` (for anything
under endgame/, the completeness guard below flags it if you forget). "where"
is the short command/zone shown on the card; the group label is both the filter
chip and the card's tag.

Fail-closed: if the widget can't be built (template missing, or no cards
extracted), print a skip and leave the existing page untouched — the published
cheat sheet is never blanked. No last-updated footer parsing here — stamp.py
owns that.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

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
    """Raised when the widget can't be built — fail closed."""


# ------------------------------------------------------ endgame page extraction


def _clean_blurb(text: str) -> str:
    """Make a page summary safe + compact for a card here:
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
    # Trim to the first two sentences so the card stays scannable.
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
    miss the cheat sheet. Returns the widget HTML, or None if the template is
    missing (caller falls back to a plain list so the page is never widget-less).
    """
    listed = {rel for _chip, rows in _CATALOG_GROUPS for rel, _where in rows}
    for page in sorted((docs_dir / "endgame").glob("*.md")):
        rel = f"endgame/{page.name}"
        if rel not in listed and rel not in _ENDGAME_COVERED_ELSEWHERE:
            print(f"{_TAG} WARN: {rel} is in neither a catalog group nor the "
                  f"covered-elsewhere set — it will be missing from the cheat sheet.")

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
    L: list[str] = []
    for chip, rows in _CATALOG_GROUPS:
        L += [f"## {chip}", ""]
        for rel, where in rows:
            got = _extract_page_summary(docs_dir, rel)
            if got is None:
                continue
            title, blurb = got
            tail = f" _({where})_" if where else ""
            L.append(f"- **[{title}](../{rel})** — {blurb}{tail}")
        L.append("")
    return L


# ---------------------------------------------------------------- render


def _render(docs_dir: Path, widget_html: str | None) -> str:
    L: list[str] = ["# Cheat Sheet", ""]
    if widget_html:
        L.append(widget_html)
        L.append("")
    else:
        L.extend(_fallback_systems_list(docs_dir))
    return "\n".join(L)


# ---------------------------------------------------------------- entry point


def generate(repo_root: Path, docs_dir: Path) -> None:
    try:
        widget_html = _build_systems_widget(repo_root, docs_dir)
        if widget_html is None:
            # None means the template is missing or no cards parsed. Fail closed
            # and keep the already-published cheat sheet rather than blanking it.
            raise _Skip("systems widget could not be built (template missing or no cards parsed)")
    except _Skip as e:
        print(f"{_TAG} skip: {e}")
        return

    content = _render(docs_dir, widget_html).rstrip() + "\n\n" + _FOOTER_STUB + "\n"
    page = docs_dir / "getting-started" / "progression-guide.md"
    page.parent.mkdir(parents=True, exist_ok=True)
    page.write_text(content, encoding="utf-8")
    card_count = sum(len(rows) for _chip, rows in _CATALOG_GROUPS)
    print(
        f"{_TAG} wrote getting-started/progression-guide.md "
        f"(Cheat Sheet: {len(_CATALOG_GROUPS)} groups, up to {card_count} system cards)"
    )
