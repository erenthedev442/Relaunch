#!/usr/bin/env python3
"""FFXI join watcher (RELAUNCH / OVH-Windows port) -> Discord webhooks.

This is the Relaunch counterpart of ffxi_join_watcher.py (which runs on the
frozen Azure 1.0 box). Same two feeds, same messages -- the ONLY differences
are the two things that made the original Azure/Linux-only:

  1. DB access. The Azure script shells out to the `mariadb` CLI with root
     unix_socket auth against a DB literally named "xidb". That can't work on
     the OVH Windows box, and the Relaunch DB is named `xi_relaunch` and is
     locked to localhost. This port reuses tools/docgen/_db.connect(), which
     reads C:\\server\\settings\\network.lua (SQL_* incl. SQL_DATABASE=xi_relaunch)
     and connects via mariadb/pymysql -- the exact pattern docgen's DB-backed
     generators already use on this box.
  2. Paths. Lua catalogs come from the live server tree (this repo's root,
     i.e. C:\\server on the box); state + webhook files live under C:\\relaunch-ops
     like the other OVH ops tools. All overridable via env vars.

Feeds (unchanged from the Azure original):
  JOINS  (-> JOIN_WEBHOOK file, e.g. #player-logins):
    - new characters (chars.charid rises)        "New character: Name"
    - logins         (accounts_sessions diff)    "Name logged in - N online"
  ACHIEVEMENTS  (-> ACH_WEBHOOK file, optional -- feed self-disables if the
    file is absent):
    - achievements   (char_vars ACH_* stamps)    "Name earned Title - desc"
    - HL rank-ups    (char_vars HL_Tier rises)   "Name reached Rank V - Legend"
    - ascensions     (Prestige_Total_Ascensions) "Name ascended - lifetime #N"

Bootstrap is silent: the first run records current online/chars WITHOUT posting
them (no backlog spam of everyone already online), then posts a one-time
"armed" message so delivery is confirmed. Read-only SELECTs only; touches zero
game code; can never slow or crash the map server.

Run it as a 1-minute scheduled task via tools/ovh-ops/run_join_watcher_relaunch.ps1.
See tools/join-watcher/RELAUNCH-DEPLOY.md for the one-time setup.
"""
from __future__ import annotations

import json
import os
import sys
import urllib.request
from pathlib import Path

# Repo root = C:\server on the box (this file is <root>/tools/join-watcher/x.py).
# Used both to import the shared DB helper and to locate the live Lua catalogs.
REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT))

from tools.docgen._db import connect  # noqa: E402  (after sys.path setup)

# --- Paths / config (env-overridable; C:\relaunch-ops defaults match the
#     other OVH ops tools) ------------------------------------------------------
OPS         = os.environ.get("RELAUNCH_OPS", r"C:\relaunch-ops")
STATE_FILE  = os.environ.get("JOIN_STATE",   os.path.join(OPS, "join-watcher", "state.json"))
HOOK_JOINS  = os.environ.get("JOIN_WEBHOOK", os.path.join(OPS, ".join_webhook"))
HOOK_ACH    = os.environ.get("ACH_WEBHOOK",  os.path.join(OPS, ".join_ach_webhook"))
ACH_LUA     = str(REPO_ROOT / "modules" / "custom" / "lua" / "achievements.lua")
HL_LUA      = str(REPO_ROOT / "modules" / "custom" / "lua" / "hunting_league_catalog.lua")
MAX_LEN     = 1900  # Discord content hard limit is 2000

_conn = None  # opened once per run in main()


def sql(query: str) -> list[list[str]]:
    """Run a read-only query on the shared connection. Returns rows as lists of
    strings so the feed logic (written for the CLI's tab-separated text) is
    byte-for-byte unchanged: int()/set() conversions happen in the callers."""
    cur = _conn.cursor()
    try:
        cur.execute(query)
        rows = cur.fetchall()
    finally:
        cur.close()
    return [["" if v is None else str(v) for v in row] for row in rows]


def post(hook_file: str, content: str) -> None:
    """POST one message to a webhook. Missing hook file = feed disabled, skip."""
    if not os.path.exists(hook_file):
        return
    # utf-8-sig: tolerate a BOM (Notepad / a Windows pipe writing the secret).
    with open(hook_file, encoding="utf-8-sig") as f:
        hook = f.read().strip()
    if not hook:
        return
    if len(content) > MAX_LEN:
        content = content[:MAX_LEN] + "\n…(truncated)"
    req = urllib.request.Request(
        hook,
        data=json.dumps({"content": content}).encode(),
        headers={"Content-Type": "application/json", "User-Agent": "ffxi-join-watcher"},
    )
    urllib.request.urlopen(req, timeout=10).read()


# ---------------------------------------------------------------------------
# Live-catalog lookups (parsed from the game's own Lua; failures degrade
# gracefully to raw ids, never to a crash).
# ---------------------------------------------------------------------------

def load_achievement_catalog() -> dict[str, dict[str, str]]:
    """id -> {title, desc} parsed from achievements.lua entry blocks."""
    import re
    catalog: dict[str, dict[str, str]] = {}
    try:
        with open(ACH_LUA, encoding="utf-8", errors="replace") as f:
            text = f.read()
        for m in re.finditer(r"id\s*=\s*'([^']+)'", text):
            chunk = text[m.start():m.start() + 600]
            t = re.search(r"\btitle\s*=\s*'([^']*)'", chunk)
            d = re.search(r"\bdesc\s*=\s*'([^']*)'", chunk)
            catalog[m.group(1)] = {
                "title": t.group(1) if t else m.group(1),
                "desc":  d.group(1) if d else "",
            }
    except OSError:
        pass
    return catalog


def load_hl_tier_names() -> dict[int, str]:
    """tier number -> display name ('Rank V - Legend') from the HL catalog."""
    import re
    names: dict[int, str] = {}
    try:
        with open(HL_LUA, encoding="utf-8", errors="replace") as f:
            text = f.read()
        for m in re.finditer(r"tier\s*=\s*(\d+)\s*,\s*\n\s*name\s*=\s*'([^']+)'", text):
            names[int(m.group(1))] = m.group(2)
    except OSError:
        pass
    return names


# ---------------------------------------------------------------------------
# Feeds  (logic identical to the Azure original)
# ---------------------------------------------------------------------------

def joins_feed(state: dict) -> list[str]:
    """New characters / logins. Mutates state; returns messages."""
    bootstrap = "max_acc" not in state

    max_acc  = int(sql("SELECT COALESCE(MAX(id), 0) FROM accounts")[0][0])
    max_char = int(sql("SELECT COALESCE(MAX(charid), 0) FROM chars")[0][0])
    online_rows = sql(
        "SELECT c.charid, c.charname FROM accounts_sessions s "
        "JOIN chars c ON c.charid = s.charid"
    )
    online = {int(r[0]): r[1] for r in online_rows}

    events: list[str] = []
    if not bootstrap:
        # New-account posts stay DISABLED (login names are semi-sensitive);
        # max_acc is still tracked so re-enabling later won't backlog-spam.
        if max_char > state["max_char"]:
            for row in sql(f"SELECT charname FROM chars WHERE charid > {state['max_char']} ORDER BY charid"):
                events.append(f":mage: New character: **{row[0]}**")
        prev = set(state.get("online", []))
        for cid, name in sorted(online.items()):
            if cid not in prev:
                events.append(f":green_circle: **{name}** logged in — {len(online)} online")

    state["max_acc"]  = max_acc
    state["max_char"] = max_char
    state["online"]   = list(online)

    if bootstrap:
        post(HOOK_JOINS, ":white_check_mark: **Join watcher armed** — new characters "
                         "and logins will be posted here (checked every minute).")
    return events


def achievements_feed(state: dict) -> list[str]:
    """ACH_* stamps, HL tier rises, ascension count rises. Mutates state."""
    bootstrap = "ach_seen" not in state

    ach_rows = sql(
        "SELECT c.charname, v.charid, v.varname FROM char_vars v "
        "JOIN chars c ON c.charid = v.charid "
        "WHERE v.varname LIKE 'ACH\\_%' AND v.value <> 0"
    )
    tier_rows = sql(
        "SELECT c.charname, v.charid, v.value FROM char_vars v "
        "JOIN chars c ON c.charid = v.charid "
        "WHERE v.varname = 'HL_Tier'"
    )
    asc_rows = sql(
        "SELECT c.charname, v.charid, v.value FROM char_vars v "
        "JOIN chars c ON c.charid = v.charid "
        "WHERE v.varname = 'Prestige_Total_Ascensions' AND v.value > 0"
    )

    events: list[str] = []
    seen      = set(state.get("ach_seen", []))
    hl_tiers  = {int(k): v for k, v in state.get("hl_tier", {}).items()}
    asc_total = {int(k): v for k, v in state.get("asc_total", {}).items()}

    if not bootstrap:
        catalog = None
        for name, cid_s, varname in ach_rows:
            key = f"{cid_s}|{varname}"
            if key in seen:
                continue
            seen.add(key)
            if catalog is None:
                catalog = load_achievement_catalog()
            info  = catalog.get(varname[4:], {})   # strip 'ACH_'
            title = info.get("title", varname[4:])
            desc  = info.get("desc", "")
            line  = f":trophy: **{name}** earned **{title}**"
            events.append(line + (f" — {desc}" if desc else ""))

        tier_names = None
        for name, cid_s, value in tier_rows:
            cid, tier = int(cid_s), int(value)
            if tier > hl_tiers.get(cid, 1):
                if tier_names is None:
                    tier_names = load_hl_tier_names()
                label = tier_names.get(tier, f"Tier {tier}")
                events.append(f":military_medal: **{name}** reached **{label}** in the Hunting League!")
            hl_tiers[cid] = max(tier, hl_tiers.get(cid, 0))

        for name, cid_s, value in asc_rows:
            cid, total = int(cid_s), int(value)
            if total > asc_total.get(cid, 0):
                events.append(f":fleur_de_lis: **{name}** ascended at the Altar — lifetime ascension **#{total}**!")
            asc_total[cid] = max(total, asc_total.get(cid, 0))
    else:
        seen      = {f"{cid}|{var}" for _n, cid, var in ach_rows}
        hl_tiers  = {int(cid): int(val) for _n, cid, val in tier_rows}
        asc_total = {int(cid): int(val) for _n, cid, val in asc_rows}

    state["ach_seen"]  = sorted(seen)
    state["hl_tier"]   = {str(k): v for k, v in hl_tiers.items()}
    state["asc_total"] = {str(k): v for k, v in asc_total.items()}

    if bootstrap:
        post(HOOK_ACH, ":white_check_mark: **Achievement feed armed** — achievements, "
                       "Hunting League rank-ups, and Ascensions will be posted here.")
    return events


def main() -> int:
    global _conn
    _conn = connect(REPO_ROOT)
    if _conn is None:
        # No DB driver (pip install pymysql) or network.lua/creds unreadable.
        # Loud on stderr so the wrapper's log shows why; never crashes the task.
        print("[join-watcher] ERROR: no DB connection (xi_relaunch). Is pymysql "
              "installed for this python, and C:\\server\\settings\\network.lua present?",
              file=sys.stderr)
        return 1

    try:
        state: dict = {}
        if os.path.exists(STATE_FILE):
            with open(STATE_FILE, encoding="utf-8") as f:
                state = json.load(f)

        join_events = joins_feed(state)
        ach_events  = achievements_feed(state)

        os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
        with open(STATE_FILE, "w", encoding="utf-8") as f:
            json.dump(state, f)

        if join_events:
            post(HOOK_JOINS, "\n".join(join_events))
        if ach_events:
            post(HOOK_ACH, "\n".join(ach_events))
        return 0
    finally:
        try:
            _conn.close()
        except Exception:
            pass


if __name__ == "__main__":
    sys.exit(main())
