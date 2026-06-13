#!/usr/bin/env python3
"""FFXI watcher -> Discord webhooks (joins + achievements).

Two feeds, two webhooks:

  JOINS  (private log channel, /etc/ffxi-join-watcher/webhook.url):
    - new accounts   (accounts.id rises)          "New account created"
    - new characters (chars.charid rises)         "New character: Name"
    - logins         (accounts_sessions diff)     "Name logged in - N online"

  ACHIEVEMENTS  (public channel, /etc/ffxi-join-watcher/webhook-achievements.url):
    - achievements   (char_vars ACH_* stamps)     "Name earned Title - desc"
    - HL rank-ups    (char_vars HL_Tier rises)    "Name reached Rank V - Legend"
    - ascensions     (Prestige_Total_Ascensions)  "Name ascended - lifetime #N"

Achievement titles/descriptions are parsed AT RUNTIME from the live
modules/custom/lua/achievements.lua, and Hunting League tier names from
hunting_league_catalog.lua -- so content added in-game later posts correctly
here with zero maintenance (no duplicated catalogs, no drift). Lookup
failures degrade to posting the raw id, never to crashing.

Runs as a 1-minute systemd timer ON THE AZURE BOX (see the .service/.timer
units next to this file). Deliberately a DB-polling sidecar: it touches ZERO
game code -- nothing in the login path, no Lua, no rebuild, and it can never
crash or slow the map server. This is the roadmap "Discord Integration" item.

Install layout (box):
  /opt/ffxi-join-watcher/ffxi_join_watcher.py              this script
  /etc/ffxi-join-watcher/webhook.url                       joins webhook (600 root)
  /etc/ffxi-join-watcher/webhook-achievements.url          achievements webhook (600 root)
  /var/lib/ffxi-join-watcher/state.json                    high-water marks + seen sets

Runs as root so the `mariadb` client authenticates via unix_socket. All
queries are read-only SELECTs. Each feed bootstraps silently the first time
its state keys are missing (no history spam), then posts a one-time "armed"
message so delivery is confirmed end-to-end.
"""

import json
import os
import re
import subprocess
import urllib.request

DB          = "xidb"
STATE_FILE  = "/var/lib/ffxi-join-watcher/state.json"
HOOK_JOINS  = "/etc/ffxi-join-watcher/webhook.url"
HOOK_ACH    = "/etc/ffxi-join-watcher/webhook-achievements.url"
ACH_LUA     = "/home/azureuser/server/modules/custom/lua/achievements.lua"
HL_LUA      = "/home/azureuser/server/modules/custom/lua/hunting_league_catalog.lua"
MAX_LEN     = 1900  # Discord content hard limit is 2000


def sql(query: str) -> list[list[str]]:
    """Run a read-only query via the mariadb CLI (root unix_socket auth).
    -N = no header row, -B = tab-separated batch mode. subprocess arg-array,
    so no shell quoting is involved."""
    out = subprocess.run(
        ["mariadb", "-N", "-B", DB, "-e", query],
        capture_output=True, text=True, timeout=20,
    )
    if out.returncode != 0:
        raise RuntimeError(f"mariadb failed: {out.stderr.strip()}")
    return [line.split("\t") for line in out.stdout.splitlines() if line]


def post(hook_file: str, content: str) -> None:
    """POST one message to a webhook. Missing hook file = feed disabled, skip."""
    if not os.path.exists(hook_file):
        return
    # utf-8-sig: tolerate a BOM (e.g. a Windows-side pipe writing the secret).
    with open(hook_file, encoding="utf-8-sig") as f:
        hook = f.read().strip()
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
# Feeds
# ---------------------------------------------------------------------------

def joins_feed(state: dict) -> list[str]:
    """New accounts / characters / logins. Mutates state; returns messages."""
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

    state["max_acc"]  = max_acc
    state["max_char"] = max_char
    state["online"]   = list(online)

    if bootstrap:
        post(HOOK_JOINS, ":white_check_mark: **Join watcher armed** — new accounts, "
                         "new characters, and logins will be posted here (checked every minute).")
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
            if tier > hl_tiers.get(cid, tier if bootstrap else 1):
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


def main() -> None:
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


if __name__ == "__main__":
    main()
