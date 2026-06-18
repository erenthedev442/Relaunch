"""Parse the seasonal bonus-mark event catalogs (static + GM-dynamic).

Two live Lua sources drive the Hunting League's bonus-mark events — windows
during which a kill earns a Hunt Mark *multiplier* on top of the Guild
amplifier:

  ``modules/custom/lua/seasonal_events_catalog.lua``
      Declarative ``catalog.events = { {...}, ... }`` — the scheduled events
      (holiday windows, anniversaries) an admin edits by hand. This is the
      *single source of truth* that gets exported into ``catalog.json`` for the
      Discord bot.

  ``modules/custom/lua/seasonal_events_dynamic.lua``
      A bare ``return { {...} }`` written at runtime by the ``!setbonus`` GM
      command. Ephemeral (max ~168 h) and not committed, so it is NOT exported
      to ``catalog.json``; the build-time status panel reads it directly so a
      GM-triggered bonus still shows up on the next site rebuild.

Both share one event shape::

    { name, multiplier, start (unix), finish (unix, exclusive), priority }

The in-game engine (``seasonal_events.lua::getActiveEvent``) merges both and
lets the highest ``priority`` win when windows overlap; the status renderer in
``generators/status.py`` mirrors that.

This module is a *parser library* — it has no ``generate()`` of its own and is
not registered in ``generate.py``. ``catalog_json.py`` imports the catalog
parser (single-source export); ``status.py`` imports both parsers (the live
"Active Events" snapshot panel). This is the same split already used for the
HNM parser in ``generators/hnm.py``, so the parsing logic lives in exactly one
place and can't drift between the two consumers.

Parsing leans on the shared brace-balanced scanner in ``tools/docgen/_lua.py``,
which honors Lua ``--`` line comments — so the commented-out example entries in
the catalog are correctly ignored rather than parsed as real events.
"""
from __future__ import annotations

import re

from tools.docgen._lua import (
    table_body,
    entry_blocks,
    iter_blocks,
    field_str,
    field_num,
)


def _event_from_block(inner: str) -> dict | None:
    """One ``{ name=, multiplier=, start=, finish=, priority= }`` block -> dict.

    Returns None if any required field is missing, so a malformed/partial entry
    is skipped rather than emitted with holes. ``priority`` defaults to 0 (the
    Lua engine's default) when absent.
    """
    name = field_str(inner, "name")
    mult = field_num(inner, "multiplier")
    start = field_num(inner, "start")
    finish = field_num(inner, "finish")
    if name is None or mult is None or start is None or finish is None:
        return None
    prio = field_num(inner, "priority")
    return {
        "name": name,
        "multiplier": float(mult),
        "start": int(start),
        "finish": int(finish),
        "priority": int(prio) if prio is not None else 0,
    }


def _parse_catalog_events(text: str) -> list[dict]:
    """Static scheduled events from ``catalog.events = { ... }`` (source order).

    Commented-out example entries are skipped automatically: ``iter_blocks``
    (used by ``table_body``/``entry_blocks``) walks past ``--`` line comments,
    so a fully-commented ``{ ... }`` example contributes no block.
    """
    body = table_body(text, "catalog.events")
    if body is None:
        return []
    out: list[dict] = []
    for inner in entry_blocks(body):
        ev = _event_from_block(inner)
        if ev is not None:
            out.append(ev)
    return out


def _parse_dynamic_events(text: str) -> list[dict]:
    """GM-triggered events from a bare ``return { {...} }`` file (or ``return {}``).

    The dynamic file has no named table to anchor on, so we take the first
    top-level ``{...}`` block after the ``return`` keyword and read its entries.
    ``return {}`` yields an empty body and therefore no events.
    """
    m = re.search(r"\breturn\b", text)
    if m is None:
        return []
    rest = text[m.end():]
    blk = next(iter_blocks(rest), None)
    if blk is None:
        return []
    body = rest[blk[0] + 1: blk[1] - 1]
    out: list[dict] = []
    for inner in entry_blocks(body):
        ev = _event_from_block(inner)
        if ev is not None:
            out.append(ev)
    return out
