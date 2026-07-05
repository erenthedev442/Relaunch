"""Page-index / freshness generator — lists every relaunch-site page and the
date it was last updated.

Reads:
    mkdocs_relaunch.yml        the relaunch site's `nav:` tree (source of the
                               page list and their nav titles)
    docs/**/*.md               each page's "Last updated" footer stamp

Writes markers on:
    docs/admin/page-index.md
        page-index-recent  — the 12 most-recently-updated pages
        page-index-all     — every page grouped by nav section, with its date

This generator is special: it must run AFTER `stamp.py` has written the
"Last updated" footers, so the dates it reports are the current ones (not
last run's). `generate.py` therefore calls it from the post-stamp block, and
re-runs the stamp pass afterwards so this page gets its own footer too.

The date shown is the same content-aware stamp that appears at the bottom of
every page — it only advances when a page's body actually changes.
"""
from __future__ import annotations

import os
import re
from pathlib import Path

from tools.docgen._markers import write_between_markers
from tools.docgen._paths import resolve_source

# Reuse the footer's own timestamp regex so this can't drift from stamp.py.
_TS_RE = re.compile(r"_Last updated:\s*([^_]+?)\s*_")
_H1_RE = re.compile(r"^\s*#\s+(.+?)\s*$", re.MULTILINE)


# ---------------------------------------------------------------------------
# mkdocs_relaunch.yml nav parsing
# ---------------------------------------------------------------------------

def _select_config(repo_root: Path, config: str | None = None) -> tuple[Path | None, str | None]:
    """Pick the mkdocs config whose `nav:` matches the site being built.

    The Legendary and relaunch sites share this `docs/` tree but build from
    different configs. Selection order:

    - explicit `config` argument (passed by generate.py) wins.
    - `DOCGEN_NAV_CONFIG` env override is next.
    - Otherwise, the relaunch build runs with `LEGENDARY_LIVE_ROOT=~/relaunch`
      (path contains "relaunch") -> mkdocs_relaunch.yml.
    - Everything else (Legendary box, laptop, CI) -> mkdocs.yml.

    Falls back to the other config if the preferred one isn't present.
    """
    override = config or os.environ.get("DOCGEN_NAV_CONFIG")
    if override:
        candidates = [override, "mkdocs.yml", "mkdocs_relaunch.yml"]
    elif "relaunch" in os.environ.get("LEGENDARY_LIVE_ROOT", "").lower():
        candidates = ["mkdocs_relaunch.yml", "mkdocs.yml"]
    else:
        candidates = ["mkdocs.yml", "mkdocs_relaunch.yml"]

    seen: set[str] = set()
    for name in candidates:
        if name in seen:
            continue
        seen.add(name)
        src = resolve_source(repo_root, name)
        if src is not None:
            return src, name
    return None, None


def _load_nav(repo_root: Path, config: str | None = None) -> list | None:
    """Load the `nav:` list from the site's mkdocs config, tolerating the
    `!!python/name:` tags mkdocs uses for emoji/theme extensions."""
    src, name = _select_config(repo_root, config)
    if src is None:
        return None
    print(f"[page_index] using nav from {name}")
    try:
        import yaml
    except ImportError:
        print("[page_index] skip: PyYAML not available")
        return None

    class _Loader(yaml.SafeLoader):
        pass

    # Any `!!python/name:...` tag -> None; we only care about the nav strings.
    _Loader.add_multi_constructor(
        "tag:yaml.org,2002:python/name:", lambda loader, suffix, node: None
    )

    data = yaml.load(src.read_text(encoding="utf-8"), Loader=_Loader)
    if not isinstance(data, dict):
        return None
    nav = data.get("nav")
    return nav if isinstance(nav, list) else None


def _is_local_page(path: str) -> bool:
    """False for external links (Discord, etc.) — those aren't site pages."""
    return "://" not in path


def _iter_pages(node, trail: list[str]):
    """Yield (trail, page_path) for every leaf page under a nav subtree.

    `trail` is the list of nav titles above the page within its section, so a
    deeply-nested page renders as "Gear › Gear Guide". External links are
    skipped — they aren't pages with a last-updated date.
    """
    if isinstance(node, str):
        if _is_local_page(node):
            yield trail, node
    elif isinstance(node, list):
        for item in node:
            yield from _iter_pages(item, trail)
    elif isinstance(node, dict):
        for title, value in node.items():
            if isinstance(value, str):
                if _is_local_page(value):
                    yield trail + [title], value
            else:
                yield from _iter_pages(value, trail + [title])


def _split_groups(nav: list) -> list[tuple[str, list[tuple[list[str], str]]]]:
    """Split the top-level nav into (group_title, [(trail, page_path), ...]).

    Bare top-level pages (Home, Rules, Changelog, ...) are collected under a
    single "General" group; each top-level section with children becomes its
    own group.
    """
    general: list[tuple[list[str], str]] = []
    groups: list[tuple[str, list[tuple[list[str], str]]]] = []

    for item in nav:
        if isinstance(item, str):
            if _is_local_page(item):
                general.append(([], item))
        elif isinstance(item, dict):
            (title, value), = item.items()
            if isinstance(value, str):
                if _is_local_page(value):
                    general.append(([title], value))
            else:
                groups.append((title, list(_iter_pages(value, []))))

    if general:
        groups.insert(0, ("General", general))
    return groups


# ---------------------------------------------------------------------------
# Per-page metadata
# ---------------------------------------------------------------------------

def _prettify(stem: str) -> str:
    return stem.replace("-", " ").replace("_", " ").strip().title()


def _page_meta(docs_dir: Path, page_path: str) -> dict:
    """Return {label, link, updated, sort} for one nav page path."""
    rel = page_path.lstrip("/")
    full = docs_dir / rel

    meta = {
        "label": None,      # H1 fallback title
        "link": "../" + rel,
        "updated": "—",
        "sort": "",         # sortable timestamp ("" sorts last)
    }

    if not rel.endswith(".md"):
        # Non-markdown nav target (e.g. admin/review.html) — no footer.
        meta["updated"] = "—"
        meta["is_md"] = False
        return meta
    meta["is_md"] = True

    if not full.exists():
        meta["updated"] = "— _(missing)_"
        return meta

    text = full.read_text(encoding="utf-8", errors="replace")

    h1 = _H1_RE.search(text)
    if h1:
        meta["label"] = h1.group(1).strip()

    ts = _TS_RE.search(text)
    if ts:
        raw = ts.group(1).strip()
        meta["updated"] = raw
        # Only rank real dates (YYYY-MM-DD ...). Placeholder footers like
        # "pending first generation." are shown as-is but never sorted to the
        # top of the recently-updated list.
        if re.match(r"\d{4}-\d{2}-\d{2}", raw):
            meta["sort"] = raw.replace(" UTC", "")

    return meta


def _row_title(trail: list[str], meta: dict, page_path: str) -> str:
    if trail:
        return " › ".join(trail)
    if meta.get("label"):
        return meta["label"]
    return _prettify(Path(page_path).stem)


# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------

def _render_all(groups) -> tuple[str, list[dict]]:
    """Render the grouped 'All pages' tables. Also returns a flat list of
    {title, link, updated, sort} for the 'recently updated' table."""
    out: list[str] = []
    flat: list[dict] = []

    for group_title, pages in groups:
        if not pages:
            continue
        out.append(f"### {group_title}")
        out.append("")
        out.append("| Page | Last updated |")
        out.append("|---|---|")
        for trail, page_path in pages:
            meta = _page_meta_cache(page_path)
            title = _row_title(trail, meta, page_path)
            link = f"[{title}]({meta['link']})"
            out.append(f"| {link} | {meta['updated']} |")
            if meta.get("is_md") and meta["sort"]:
                flat.append({
                    "title": title,
                    "link": meta["link"],
                    "updated": meta["updated"],
                    "sort": meta["sort"],
                })
        out.append("")

    return "\n".join(out).rstrip(), flat


def _render_recent(flat: list[dict], limit: int = 12) -> str:
    ranked = sorted(flat, key=lambda r: r["sort"], reverse=True)[:limit]
    if not ranked:
        return "_No timestamped pages found._"
    out = ["| Page | Last updated |", "|---|---|"]
    for r in ranked:
        out.append(f"| [{r['title']}]({r['link']}) | {r['updated']} |")
    return "\n".join(out)


# Small per-run cache so each page is read/parsed once even though the flat
# recent-list reuses the same metadata the grouped table produced.
_CACHE: dict[str, dict] = {}


def _page_meta_cache(page_path: str) -> dict:
    return _CACHE[page_path]


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path, config: str | None = None) -> None:
    nav = _load_nav(repo_root, config)
    if nav is None:
        print("[page_index] skip: could not read nav from mkdocs_relaunch.yml")
        return

    page = docs_dir / "admin" / "page-index.md"
    if not page.exists():
        print("[page_index] skip: docs/admin/page-index.md not found")
        return

    groups = _split_groups(nav)

    # Prime the metadata cache once.
    _CACHE.clear()
    for _title, pages in groups:
        for _trail, page_path in pages:
            if page_path not in _CACHE:
                _CACHE[page_path] = _page_meta(docs_dir, page_path)

    all_md, flat = _render_all(groups)
    recent_md = _render_recent(flat)

    ok_recent = write_between_markers(page, "page-index-recent", recent_md)
    ok_all = write_between_markers(page, "page-index-all", all_md)

    n_pages = sum(len(p) for _t, p in groups)
    print(f"[page_index] {n_pages} nav pages indexed "
          f"({'recent ok' if ok_recent else 'recent MISS'}, "
          f"{'all ok' if ok_all else 'all MISS'})")
