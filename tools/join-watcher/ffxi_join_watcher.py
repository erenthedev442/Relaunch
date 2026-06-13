#!/usr/bin/env python3
"""FFXI join watcher -> Discord webhook.

Polls the live xidb for three events and posts them to a Discord webhook:
  - new accounts   (accounts.id rises)          "New account created"
  - new characters (chars.charid rises)         "New character: Name"
  - logins         (accounts_sessions diff)     "Name logged in - N online"

Runs as a 1-minute systemd timer ON THE AZURE BOX (see the .service/.timer
units next to this file). Deliberately a DB-polling sidecar: it touches ZERO
game code -- nothing in the login path, no Lua, no rebuild, and it can never
crash or slow the map server. First slice of the roadmap "Discord Integration"
item; rank-ups / server-firsts can post through the same webhook later.

Install layout (box):
  /opt/ffxi-join-watcher/ffxi_join_watcher.py   this script
  /etc/ffxi-join-watcher/webhook.url            the Discord webhook URL (chmod 600 root)
  /var/lib/ffxi-join-watcher/state.json         high-water marks + online set

Runs as root so the `mariadb` client authenticates via unix_socket (same
mechanism as the box's other root cron jobs). Queries are read-only SELECTs.

First run bootstraps state WITHOUT posting history (no spam), then posts a
one-time "watcher armed" message so you can confirm delivery end-to-end.
"""

import json
import os
import subprocess
import urllib.request

DB         = "xidb"
STATE_FILE = "/var/lib/ffxi-join-watcher/state.json"
HOOK_FILE  = "/etc/ffxi-join-watcher/webhook.url"
MAX_LEN    = 1900  # Discord content hard limit is 2000


def sql(query: str) -> list[list[str]]:
    """Run a read-only query via the mariadb CLI (root unix_socket auth).
    -N = no header row, -B = tab-separated batch mode."""
    out = subprocess.run(
        ["mariadb", "-N", "-B", DB, "-e", query],
        capture_output=True, text=True, timeout=20,
    )
    if out.returncode != 0:
        raise RuntimeError(f"mariadb failed: {out.stderr.strip()}")
    return [line.split("\t") for line in out.stdout.splitlines() if line]


def post(content: str) -> None:
    # utf-8-sig: tolerate a BOM (e.g. a Windows-side pipe writing the secret).
    with open(HOOK_FILE, encoding="utf-8-sig") as f:
        hook = f.read().strip()
    if len(content) > MAX_LEN:
        content = content[:MAX_LEN] + "\n…(truncated)"
    req = urllib.request.Request(
        hook,
        data=json.dumps({"content": content}).encode(),
        headers={"Content-Type": "application/json", "User-Agent": "ffxi-join-watcher"},
    )
    urllib.request.urlopen(req, timeout=10).read()


def main() -> None:
    first_run = not os.path.exists(STATE_FILE)
    state = {"max_acc": 0, "max_char": 0, "online": []}
    if not first_run:
        with open(STATE_FILE, encoding="utf-8") as f:
            state = json.load(f)

    max_acc  = int(sql("SELECT COALESCE(MAX(id), 0) FROM accounts")[0][0])
    max_char = int(sql("SELECT COALESCE(MAX(charid), 0) FROM chars")[0][0])
    online_rows = sql(
        "SELECT c.charid, c.charname FROM accounts_sessions s "
        "JOIN chars c ON c.charid = s.charid"
    )
    online = {int(r[0]): r[1] for r in online_rows}

    events: list[str] = []
    if not first_run:
        if max_acc > state["max_acc"]:
            for row in sql(f"SELECT login FROM accounts WHERE id > {state['max_acc']} ORDER BY id"):
                events.append(f":new: New account created: `{row[0]}`")
        if max_char > state["max_char"]:
            for row in sql(f"SELECT charname FROM chars WHERE charid > {state['max_char']} ORDER BY charid"):
                events.append(f":mage: New character: **{row[0]}**")
        prev = set(state.get("online", []))
        for cid, name in sorted(online.items()):
            if cid not in prev:
                events.append(f":green_circle: **{name}** logged in — {len(online)} online")

    os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
    with open(STATE_FILE, "w", encoding="utf-8") as f:
        json.dump({"max_acc": max_acc, "max_char": max_char, "online": list(online)}, f)

    if first_run:
        post(":white_check_mark: **Join watcher armed** — new accounts, new characters, "
             "and logins on the game server will be posted here (checked every minute).")
    elif events:
        post("\n".join(events))


if __name__ == "__main__":
    main()
