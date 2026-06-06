"""MySQL/MariaDB connection helper for the Discord bot.

This is the bot's *self-contained* copy of the same connection logic used
by the docs generator (tools/docgen/_db.py). The bot lives on a different
git branch than the docs toolchain, so `tools/docgen/` is not present in
the live server checkout where the bot actually runs — importing from it
there raises ModuleNotFoundError. Keeping a sibling copy here lets the bot
connect without depending on the docs branch being checked out.

It reads SQL_* credentials from `settings/network.lua` (under the live
server root passed to connect(), or $LEGENDARY_LIVE_ROOT) and returns an
open connection, or None on any failure so callers can degrade cleanly.

This file is connection plumbing only — no catalog/game data — so it does
not participate in the catalog-drift problem the bot's catalog.json solves.
The Lua schema for SQL_* settings is stable; this rarely needs to change.
"""
from __future__ import annotations

import os
import re
from pathlib import Path

# Driver preference order:
#   1. mariadb  — native MariaDB C connector (best fidelity, needs the C lib).
#   2. pymysql  — pure-Python fallback, no native deps.
# Whichever imports first wins. `_driver` records the choice so connect()
# calls the right API.
_driver = None
try:
    import mariadb  # type: ignore
    _driver = "mariadb"
    # Accept '%s' placeholders so parameterized queries match pymysql.
    try:
        mariadb.paramstyle = "format"
    except (AttributeError, TypeError):
        pass
except ImportError:
    mariadb = None  # type: ignore
    try:
        import pymysql  # type: ignore
        _driver = "pymysql"
    except ImportError:
        pymysql = None  # type: ignore


# Match a `SQL_* = 'value'` / `SQL_* = number` line in settings/network.lua.
# Quotes optional so both string and numeric values parse.
_SETTING_RE = re.compile(
    r"^\s*(SQL_HOST|SQL_PORT|SQL_LOGIN|SQL_PASSWORD|SQL_DATABASE)"
    r"\s*=\s*(?:'([^']*)'|\"([^\"]*)\"|(\d+))",
    re.MULTILINE,
)


def _parse_network_lua(path: Path) -> dict[str, str] | None:
    """Pull SQL_* settings out of network.lua via regex (no Lua execution)."""
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return None

    out: dict[str, str] = {}
    for m in _SETTING_RE.finditer(text):
        key = m.group(1)
        val = m.group(2) or m.group(3) or m.group(4)
        if val is not None:
            out[key] = val
    return out if out else None


def _resolve_network_lua(repo_root: Path) -> Path | None:
    live = os.environ.get("LEGENDARY_LIVE_ROOT")
    if live:
        p = Path(live) / "settings" / "network.lua"
        if p.exists():
            return p
    p = repo_root / "settings" / "network.lua"
    if p.exists():
        return p
    return None


def connect(repo_root: Path):
    """Return an open MySQL/MariaDB connection or None.

    None is returned (rather than raising) when:
      - no driver is installed (neither mariadb nor pymysql)
      - settings/network.lua can't be found
      - network.lua fails to parse
      - the DB is unreachable / credentials are wrong

    The bot treats None as exit code 2 (DB unreachable).
    """
    if _driver is None:
        return None
    netfile = _resolve_network_lua(repo_root)
    if netfile is None:
        return None
    cfg = _parse_network_lua(netfile)
    if cfg is None:
        return None

    kwargs = dict(
        user=cfg.get("SQL_LOGIN", "root"),
        password=cfg.get("SQL_PASSWORD", ""),
        host=cfg.get("SQL_HOST", "127.0.0.1"),
        port=int(cfg.get("SQL_PORT", "3306")),
        database=cfg.get("SQL_DATABASE", "xidb"),
    )

    try:
        if _driver == "mariadb":
            return mariadb.connect(connect_timeout=3, **kwargs)
        else:  # pymysql
            return pymysql.connect(connect_timeout=3, **kwargs)
    except Exception:
        return None
