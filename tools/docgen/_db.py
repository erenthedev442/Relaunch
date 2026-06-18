"""MySQL/MariaDB connection helper for docgen modules that need to read
the live server's database (leaderboards, player stats, etc.).

Reads credentials from `settings/network.lua` in the LEGENDARY_LIVE_ROOT
(or the repo, but the repo doesn't ship a populated network.lua, so it
will almost always be the live root). Returns `None` if anything goes
wrong — generators must handle the None case by skipping cleanly, the
same way they skip when their input file is missing.

CI never has LEGENDARY_LIVE_ROOT, so DB-backed generators silently no-op
there and the previously-committed markdown stays in place.
"""
from __future__ import annotations

import os
import re
from pathlib import Path

# Driver preference order:
#   1. mariadb  — what dbtool.py uses; pulls in the native MariaDB C
#      connector. Best fidelity, but needs the C lib installed on the
#      host so the .venv-docs `pip install mariadb` only works if that
#      lib is already present.
#   2. pymysql  — pure-Python fallback; talks MySQL/MariaDB protocol
#      directly, no native deps. Easier to install in a fresh venv.
# Whichever loads first wins. `_driver` records which one so connect()
# can call the right API.
_driver = None
try:
    import mariadb  # type: ignore
    _driver = "mariadb"
    # Make mariadb cursors accept '%s' placeholders so we can share
    # parameterized queries with pymysql verbatim. Default for mariadb
    # is 'qmark' (?), pymysql is 'format' (%s) and doesn't accept ?.
    try:
        mariadb.paramstyle = "format"
    except (AttributeError, TypeError):
        # Older builds may not expose paramstyle at module level; cursor
        # behavior will still work if `mariadb` was wired with format
        # style at build time. Anything else will surface as a query
        # error and the generator will fail loudly via the harness.
        pass
except ImportError:
    mariadb = None  # type: ignore
    try:
        import pymysql  # type: ignore
        _driver = "pymysql"
    except ImportError:
        pymysql = None  # type: ignore


# Match a `SETTING = 'value'` or `SETTING = number` line inside a Lua
# table. We only care about the five SQL_* settings; anything else is
# ignored. Quotes optional so we cope with both string and numeric values.
_SETTING_RE = re.compile(
    r"^\s*(SQL_HOST|SQL_PORT|SQL_LOGIN|SQL_PASSWORD|SQL_DATABASE)"
    r"\s*=\s*(?:'([^']*)'|\"([^\"]*)\"|(\d+))",
    re.MULTILINE,
)


def _parse_network_lua(path: Path) -> dict[str, str] | None:
    """Pull SQL_* settings out of settings/network.lua without trying
    to actually execute Lua. The schema is stable and regex is plenty."""
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

    Failure modes that yield None:
      - no driver installed (neither mariadb nor pymysql)
      - settings/network.lua not findable (CI, fresh clone)
      - parse failure on network.lua
      - DB unreachable / wrong creds

    Callers should treat None as "skip this generator silently".
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
