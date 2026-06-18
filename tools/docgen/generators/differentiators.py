"""Render the "What Legendary Does Differently" list on why-legendary.md from
tools/docgen/systems_registry.py, and reconcile it against the live system
detail pages so no system silently drops off the highlights (the way Ascension
once did).

Writes:
  - docs/why-legendary.md             marker id="differentiators" (the bullets)
  - docs/admin/unfeatured-systems.md  marker id="unfeatured"      (drift report)

Blurbs are HYBRID: an entry's hand-written `text` is emitted verbatim (marketing
copy); an entry without `text` gets a blurb auto-extracted from its detail page,
so newly-added systems appear on the list automatically.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._markers import write_between_markers
from tools.docgen import systems_registry as reg


def generate(repo_root: Path, docs_dir: Path) -> None:
    _render_highlights(docs_dir)
    _reconcile(docs_dir)


# ---- 1. render the highlight bullets -------------------------------------

def _render_highlights(docs_dir: Path) -> None:
    page = docs_dir / "why-legendary.md"
    bullets = []
    for entry in reg.HEADLINE:
        text = entry.get("text")
        if not text:
            text = _synthesize(entry, docs_dir)
        bullets.append("- " + text.strip())

    if not bullets:
        # Defensive: never blow the list away if the registry came back empty.
        print("[differentiators] HEADLINE is empty — leaving why-legendary.md untouched")
        return

    content = "\n\n".join(bullets)
    wrote = write_between_markers(page, "differentiators", content)
    if wrote:
        auto = sum(1 for e in reg.HEADLINE if not e.get("text"))
        print(f"[differentiators] wrote {len(bullets)} highlight bullets "
              f"({auto} auto-extracted from detail pages)")
    else:
        print('[differentiators] marker id="differentiators" not found in '
              "why-legendary.md — skipped")


def _synthesize(entry: dict, docs_dir: Path) -> str:
    """Build a bullet for an entry that has no hand-written `text`."""
    name = entry["name"]
    page = entry.get("page")
    blurb = _extract_blurb(docs_dir / page) if page else ""
    if not blurb:
        blurb = ("_(no blurb yet — add `text` in systems_registry.py, or a lead "
                 "paragraph / Summary tip to the detail page)_")
    return f"**{name}.** {blurb}"


# ---- 2. blurb extraction (for systems without curated text) ---------------

# A `!!! tip "Summary"` (or note/info/...) admonition: capture the indented body.
_SUMMARY_RE = re.compile(
    r'^!!!\s+\w+\s+"Summary".*\n((?:[ \t]+.*\n?|[ \t]*\n)+)',
    re.MULTILINE,
)


def _extract_blurb(path: Path) -> str:
    if not path.exists():
        return ""
    text = path.read_text(encoding="utf-8", errors="replace")
    m = _SUMMARY_RE.search(text)
    raw = m.group(1) if m else _first_paragraph(text)
    return _to_oneline(raw)


def _first_paragraph(text: str) -> str:
    """First real prose paragraph after the H1, skipping headings, rules,
    admonitions, tables, blockquotes and HTML-comment markers."""
    skip_prefix = ("#", "---", "<!--", "!!!", "|", ">", "    ")
    para: list[str] = []
    for line in text.splitlines():
        s = line.strip()
        if not para:
            if not s or line.startswith(skip_prefix):
                continue
            para.append(s)
        else:
            if not s or line.startswith(skip_prefix):
                break
            para.append(s)
    return " ".join(para)


def _to_oneline(raw: str) -> str:
    s = re.sub(r"<!--.*?-->", "", raw, flags=re.DOTALL)   # strip html comments
    s = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", s)          # [text](url) -> text
    s = s.replace("**", "").replace("*", "").replace("`", "")
    s = " ".join(s.split())
    return _truncate_sentences(s, max_sentences=2, max_chars=260)


def _truncate_sentences(s: str, max_sentences: int, max_chars: int) -> str:
    parts = re.split(r"(?<=[.!?])\s+", s)
    out = ""
    for i, p in enumerate(parts):
        if i >= max_sentences:
            break
        cand = (out + " " + p).strip() if out else p
        if out and len(cand) > max_chars:
            break
        out = cand
    if len(out) > max_chars:
        out = out[:max_chars].rsplit(" ", 1)[0].rstrip() + "…"
    return out


# ---- 3. drift reconciliation ---------------------------------------------

def _discover_system_pages(docs_dir: Path) -> list[str]:
    """Candidate 'system' pages: top-level docs under progression/ and
    community/ (player profile pages live in community/players/ and are
    excluded by the non-recursive glob)."""
    out: list[str] = []
    for sub in ("progression", "community"):
        d = docs_dir / sub
        if not d.is_dir():
            continue
        for p in sorted(d.glob("*.md")):
            out.append(f"{sub}/{p.name}")
    return out


def _reconcile(docs_dir: Path) -> None:
    featured: set[str] = set()
    for e in reg.HEADLINE:
        if e.get("page"):
            featured.add(e["page"])
        for c in e.get("covers", ()):  # type: ignore[union-attr]
            featured.add(c)
    known = featured | set(getattr(reg, "IGNORE_PAGES", ()))

    discovered = _discover_system_pages(docs_dir)
    orphans = [p for p in discovered if p not in known]

    admin = docs_dir / "admin" / "unfeatured-systems.md"
    if orphans:
        lines = [
            "The following system detail pages exist but are **not** represented "
            "on the [Why Legendary?](../why-legendary.md) highlights list. For "
            "each, either feature it (add an entry to `HEADLINE` in "
            "`tools/docgen/systems_registry.py`) or mark it intentionally skipped "
            "(add it to `IGNORE_PAGES`, or to a featured bullet's `covers`).",
            "",
            "| Detail page | Lead blurb |",
            "|---|---|",
        ]
        for p in orphans:
            blurb = _extract_blurb(docs_dir / p).replace("|", "\\|") or "—"
            lines.append(f"| [`{p}`](../{p}) | {blurb[:160]} |")
        body = "\n".join(lines)
        print(f"[differentiators] DRIFT: {len(orphans)} unfeatured system "
              f"page(s) — {', '.join(orphans)}")
    else:
        body = ("_All system detail pages are represented on the highlights "
                "list — no drift detected._")
        print(f"[differentiators] drift check OK — {len(discovered)} system "
              "pages, all featured or covered")

    wrote = write_between_markers(admin, "unfeatured", body)
    if not wrote:
        print('[differentiators] admin/unfeatured-systems.md marker '
              'id="unfeatured" missing — drift report not written')
