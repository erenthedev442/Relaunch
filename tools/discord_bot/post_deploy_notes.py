#!/usr/bin/env python3
"""Post the latest deploy's player-facing notes to Discord.

Called from deploy-everything.bat step [2c], right after regen_changelog.py
regenerates docs/changelog.md. Reads the first update block from the changelog
(already cleaned into player-friendly format by changelog.py) and POSTs it to
WEBHOOK_URL in config.py.

Exits 0 on success or graceful skip; exits 1 only on a real webhook failure
(so deploy-everything.bat can continue regardless).
"""
from __future__ import annotations

import json
import re
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "discord_bot"))

try:
    import config as cfg
except ImportError:
    cfg = None

WEBHOOK_URL: str = (getattr(cfg, "WEBHOOK_URL", "") or "") if cfg else ""
if not WEBHOOK_URL or "REPLACE_ME" in WEBHOOK_URL:
    # OVH-box fallback: the box keeps its webhook as a one-line file at
    # C:\relaunch-ops\.discord_webhook (same convention as
    # tools/ovh-ops/site_drift_monitor_relaunch.py); config.py is gitignored
    # and typically absent there.
    try:
        WEBHOOK_URL = Path(r"C:\relaunch-ops\.discord_webhook").read_text(encoding="utf-8").strip()
    except OSError:
        WEBHOOK_URL = ""
if not WEBHOOK_URL or "REPLACE_ME" in WEBHOOK_URL:
    print("[post_deploy] no webhook (config.py or C:\\relaunch-ops\\.discord_webhook) — skipping")
    sys.exit(0)

CHANGELOG = ROOT / "docs" / "changelog.md"
if not CHANGELOG.exists():
    print(f"[post_deploy] {CHANGELOG} not found — skipping")
    sys.exit(0)

text = CHANGELOG.read_text(encoding="utf-8")

# Extract the first **Weekday, Month N** block and its bullet lines.
# changelog.py renders:  "    **Monday, June 23**\n\n    - note\n    - note"
match = re.search(
    r'\*\*([A-Z][a-z]+, [A-Z][a-z]+ \d+)\*\*\s*\n+((?:[ \t]+-[ \t]+.+\n?)+)',
    text,
)
if not match:
    print("[post_deploy] no update block found in changelog — skipping")
    sys.exit(0)

day_label = match.group(1)
notes = [
    line.strip().lstrip("- ").strip()
    for line in match.group(2).splitlines()
    if line.strip().startswith("-")
]
if not notes:
    print("[post_deploy] no notes in latest block — skipping")
    sys.exit(0)

cap = int(getattr(cfg, "PATCH_NOTES_MAX", 15) or 15)
total = len(notes)
notes = notes[:cap]

role = str(getattr(cfg, "PING_ROLE_ON_PATCH", "") or "")
prefix = f"<@&{role}>  " if role else ""

# Title + role-ping stay OUTSIDE the code block: emoji/bold only render outside a
# ``` block, and a role mention won't fire (no ping) if it's wrapped inside one.
header = f"{prefix}:scroll: **Server Update — {day_label}**"

# The "full changelog" link also stays outside so it stays clickable.
footer = ""
if total > cap:
    footer = f"\n…and {total - cap} more. Full changelog: https://fjb-relaunch.pages.dev/changelog/"

# Per Ririn: wrap the notes in a triple-backtick code block so they render as a
# clean monospace box in Discord.
body = "\n".join(f"• {n}" for n in notes)

# Stay under Discord's 2000-char webhook limit. Reserve room for header, footer and
# the fences ("\n```\n" before + "\n```" after = 9 chars), then truncate the BODY
# only — so the closing fence is never cut off (an unclosed ``` swallows the rest).
max_body = 1990 - len(header) - len(footer) - 9
if len(body) > max_body:
    body = body[: max(0, max_body - 1)].rstrip() + "…"

msg = f"{header}\n```\n{body}\n```{footer}"

bot_name   = str(getattr(cfg, "BOT_USERNAME", "") or "Legendary")
avatar_url = str(getattr(cfg, "BOT_AVATAR_URL", "") or "") or None

payload = json.dumps({"content": msg, "username": bot_name, "avatar_url": avatar_url}).encode()
req = urllib.request.Request(
    WEBHOOK_URL,
    data=payload,
    headers={"Content-Type": "application/json", "User-Agent": "LegendaryBot/1.0"},
    method="POST",
)

try:
    with urllib.request.urlopen(req, timeout=10) as r:
        if r.status in (200, 204):
            print(f"[post_deploy] posted {len(notes)} note(s) to Discord")
        else:
            print(f"[post_deploy] webhook returned HTTP {r.status}")
            sys.exit(1)
except Exception as e:
    print(f"[post_deploy] webhook error: {e}")
    sys.exit(1)
