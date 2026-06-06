"""Database connection for dpscalc.

Reads SQL_* credentials from settings/network.lua (same source the server and
the discord bot use) and returns an open pymysql connection with a DictCursor.
Unlike the bot's _db.connect (which returns None to degrade cleanly), this
raises on failure -- a CLI tool wants a loud error, not a silent None.
"""
from __future__ import annotations

import os
import re
from pathlib import Path

import pymysql
import pymysql.cursors

# tools/dpscalc/db.py  ->  parents[2] == repo root (D:\server)
REPO_ROOT = Path(__file__).resolve().parents[2]

_SETTING_RE = re.compile(
    r"^\s*(SQL_HOST|SQL_PORT|SQL_LOGIN|SQL_PASSWORD|SQL_DATABASE)"
    r"\s*=\s*(?:'([^']*)'|\"([^\"]*)\"|(\d+))",
    re.MULTILINE,
)


def _network_cfg(repo_root: Path) -> dict[str, str]:
    candidates = []
    live = os.environ.get("LEGENDARY_LIVE_ROOT")
    if live:
        candidates.append(Path(live) / "settings" / "network.lua")
    candidates.append(repo_root / "settings" / "network.lua")

    for p in candidates:
        if not p.exists():
            continue
        text = p.read_text(encoding="utf-8", errors="replace")
        cfg = {}
        for m in _SETTING_RE.finditer(text):
            cfg[m.group(1)] = m.group(2) or m.group(3) or m.group(4)
        if cfg:
            return cfg
    raise FileNotFoundError(
        "Could not find/parse settings/network.lua (set LEGENDARY_LIVE_ROOT "
        "to the live server root if running outside the repo)."
    )


def connect(repo_root: Path | None = None) -> pymysql.connections.Connection:
    cfg = _network_cfg(repo_root or REPO_ROOT)
    return pymysql.connect(
        host=cfg.get("SQL_HOST", "127.0.0.1"),
        port=int(cfg.get("SQL_PORT", "3306")),
        user=cfg.get("SQL_LOGIN", "root"),
        password=cfg.get("SQL_PASSWORD", ""),
        database=cfg.get("SQL_DATABASE", "xidb"),
        connect_timeout=5,
        cursorclass=pymysql.cursors.DictCursor,
    )
