"""Stamp each docs page with a "Last updated" footer.

Runs after every generator. The footer is content-aware:

- A SHA-256 hash of the page (excluding the footer itself) is recorded
  in an HTML comment inside the marker block.
- On each run, the new body hash is compared to the stored hash. If they
  match, the existing timestamp is preserved — meaning pages that didn't
  actually change keep their real last-updated date.
- If the body changed, the timestamp is bumped to NOW.

This avoids the "every page shows today" problem you'd get from naive
stamping while still giving readers a real signal about freshness.

Footer format inserted at the bottom of every .md file:

    ---

    <!-- DOCGEN:BEGIN id="last-updated" -->
    <!-- content-hash: abcdef012345 -->
    _Last updated: 2026-05-24 14:30 PDT_
    <!-- DOCGEN:END id="last-updated" -->
"""
from __future__ import annotations

import datetime as _dt
import hashlib
import re
import zoneinfo as _zi
from pathlib import Path

_PACIFIC = _zi.ZoneInfo("America/Los_Angeles")


_MARKER_BEGIN = '<!-- DOCGEN:BEGIN id="last-updated" -->'
_MARKER_END   = '<!-- DOCGEN:END id="last-updated" -->'

# Pages (relative to docs_dir) that should NOT receive an auto-stamp footer.
# The home page is excluded by design — it has no auto-generated content that
# would make a "last updated" signal meaningful to readers.
_EXCLUDED_PAGES: frozenset[str] = frozenset({
    "index.md",
})

# Captures an optional preceding `---` separator + any blank lines, the
# whole marker block, and any trailing newlines. Stripping THIS regex from
# the page text leaves the original body verbatim, so the body hash is
# stable across runs.
_BLOCK_RE = re.compile(
    r"(?:\n*-{3,}\n+)?"
    + re.escape(_MARKER_BEGIN)
    + r".*?"
    + re.escape(_MARKER_END)
    + r"\n*",
    re.DOTALL,
)
_HASH_RE = re.compile(r"<!--\s*content-hash:\s*([a-f0-9]+)\s*-->")
_TS_RE   = re.compile(r"_Last updated:\s*([^_]+?)\s*_")


def _hash_body(body: str) -> str:
    """Short SHA-256 of the page body, normalized to ignore trailing
    whitespace differences."""
    normalized = body.rstrip() + "\n"
    return hashlib.sha256(normalized.encode("utf-8")).hexdigest()[:12]


def _now_utc() -> str:
    return _dt.datetime.now(_PACIFIC).strftime("%Y-%m-%d %H:%M %Z")


_TRAILING_HRULE_RE = re.compile(r"(?:\n\s*-{3,}\s*)+\s*$")


def _strip_footer(text: str) -> str:
    """Return the page text with any existing last-updated block AND any
    trailing horizontal rules removed. We claim the bottom of every page
    for the auto-stamp, so a stale `---` separator from a previous run
    (or hand-authored cosmetic divider) gets cleaned up here. This keeps
    the body hash stable across runs and avoids stacking `---` lines."""
    stripped = _BLOCK_RE.sub("", text).rstrip()
    # Remove any trailing horizontal-rule lines so we don't emit a double
    # `---` once we re-add the footer's own separator.
    stripped = _TRAILING_HRULE_RE.sub("", stripped).rstrip()
    return stripped


def _build_footer(body_hash: str, timestamp: str) -> str:
    return (
        f"---\n\n"
        f"{_MARKER_BEGIN}\n"
        f"<!-- content-hash: {body_hash} -->\n"
        f"_Last updated: {timestamp}_\n"
        f"{_MARKER_END}\n"
    )


def capture_existing(docs_dir: Path) -> dict[Path, tuple[str, str]]:
    """Snapshot the (content-hash, timestamp) of the last-updated footer
    on every page. Call this BEFORE other generators run — they may
    overwrite pages they own and erase the footer.

    Returns {absolute_path: (hash, timestamp)} for pages that already have
    a footer. Pages without one are absent from the dict.
    """
    snap: dict[Path, tuple[str, str]] = {}
    for path in sorted(docs_dir.rglob("*.md")):
        try:
            text = path.read_text(encoding="utf-8")
        except OSError:
            continue
        m = _BLOCK_RE.search(text)
        if not m:
            continue
        block = m.group(0)
        h = _HASH_RE.search(block)
        t = _TS_RE.search(block)
        if h and t:
            snap[path.resolve()] = (h.group(1), t.group(1).strip())
    return snap


def stamp_pages(
    docs_dir: Path,
    prior: dict[Path, tuple[str, str]] | None = None,
    verbose: bool = False,
) -> tuple[int, int]:
    """Add/refresh the last-updated footer on every .md page.

    If `prior` is supplied (from `capture_existing` called BEFORE other
    generators ran), it's used to look up the page's previous hash and
    timestamp. Otherwise we fall back to reading the current file, which
    only works for pages that weren't overwritten by another generator.

    Returns (pages_with_new_timestamp, pages_with_preserved_timestamp).
    """
    now = _now_utc()
    new_count = 0
    kept_count = 0
    new_names: list[str] = []

    for path in sorted(docs_dir.rglob("*.md")):
        # Skip excluded pages — strip any legacy footer they may carry but
        # don't write a new one.
        if path.relative_to(docs_dir).as_posix() in _EXCLUDED_PAGES:
            text = path.read_text(encoding="utf-8")
            cleaned = _strip_footer(text)
            if cleaned != text.rstrip():
                path.write_text(cleaned + "\n", encoding="utf-8")
            continue

        text = path.read_text(encoding="utf-8")

        # Strip the existing footer (if any) to get just the body.
        body = _strip_footer(text)
        body_hash = _hash_body(body)

        # Look up the previously-stamped hash + timestamp.
        existing_hash: str | None = None
        existing_ts:   str | None = None

        if prior is not None:
            entry = prior.get(path.resolve())
            if entry:
                existing_hash, existing_ts = entry
        else:
            # Fallback: read footer from current file state.
            m = _BLOCK_RE.search(text)
            if m:
                block = m.group(0)
                h = _HASH_RE.search(block)
                if h:
                    existing_hash = h.group(1)
                t = _TS_RE.search(block)
                if t:
                    existing_ts = t.group(1).strip()

        # Preserve timestamp if hash matches (body unchanged).
        if existing_hash == body_hash and existing_ts:
            timestamp = existing_ts
            kept_count += 1
        else:
            timestamp = now
            new_count += 1
            new_names.append(str(path.relative_to(docs_dir)))

        footer = _build_footer(body_hash, timestamp)
        new_text = body + "\n\n" + footer

        if new_text != text:
            path.write_text(new_text, encoding="utf-8")

    if verbose and new_names:
        for name in new_names:
            print(f"[stamp]   bumped: {name}")
    return new_count, kept_count


def generate(repo_root: Path, docs_dir: Path, prior: dict | None = None) -> None:
    """Standard generator entrypoint so the orchestrator can call this
    like any other module. Accepts an optional `prior` snapshot from
    `capture_existing()` — pass this if other generators may have
    overwritten pages between snapshot and stamp."""
    import os
    verbose = os.environ.get("DOCGEN_STAMP_VERBOSE") == "1"
    new_count, kept_count = stamp_pages(docs_dir, prior=prior, verbose=verbose)
    print(f"[stamp] {new_count} page(s) timestamped now, {kept_count} kept existing (unchanged content)")
