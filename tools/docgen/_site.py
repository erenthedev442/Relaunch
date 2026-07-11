"""Site-wide constants + connection facts for the relaunch docs generators.

Single committed source for values that are not parseable from the repo (the
box's public address, invite links). Connection PORTS are parsed from the live
`settings/network.lua` when present (the box exports LEGENDARY_LIVE_ROOT, whose
settings are the real relaunch ones); the constants below are the fallback so
local/CI builds still render the production values instead of LSB stock
defaults (settings/network.lua is gitignored, so the repo copy never exists).

Edit connection facts HERE, never in a docs page — every getting-started page
renders from these.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source

SERVER_NAME = "the Relaunch server"
SERVER_HOST = "15.204.112.102"   # OVH VPS (moved off Azure 172.215.213.23 on 2026-07-06)
DATA_PORT = 54230
AUTH_PORT = 54231
VIEW_PORT = 54001

DISCORD_URL = "https://discord.gg/Yd3Kn3dN36"
REPO_URL = "https://github.com/richardknutzjr/Relaunch"


def connection(repo_root: Path) -> tuple[str, int, int, int]:
    """(host, data_port, auth_port, view_port) — live network.lua wins,
    the constants above fall back. Since the OVH move (2026-07-06) the
    relaunch uses the standard login ports (54230/54231/54001), not the
    old Azure +10 block."""
    host, data, auth, view = SERVER_HOST, DATA_PORT, AUTH_PORT, VIEW_PORT
    src = resolve_source(repo_root, "settings/network.lua")
    if src is not None:
        text = src.read_text(encoding="utf-8", errors="replace")

        def port(key: str, default: int) -> int:
            m = re.search(rf"{key}\s*=\s*(\d+)", text)
            return int(m.group(1)) if m else default

        data = port("LOGIN_DATA_PORT", data)
        auth = port("LOGIN_AUTH_PORT", auth)
        view = port("LOGIN_VIEW_PORT", view)
    return host, data, auth, view


def xiloader_args(repo_root: Path) -> str:
    """The exact launch-argument string the connect/troubleshoot pages show."""
    host, data, auth, view = connection(repo_root)
    return f"--server {host} --dataport {data} --authport {auth} --viewport {view}"
