#!/usr/bin/env python3
"""site_drift_monitor.py -- dead-man's-switch for the two player docs sites.

Both sites rebuild hourly from the live servers (legendary-ffxi.pages.dev from
~/server + xidb; www.ffxi-legendary.com from ~/relaunch + xi_relaunch). If a
refresh silently dies -- cron broken, docgen error, wrangler/auth failure, disk
full -- the PUBLISHED site quietly drifts from the live game and nobody notices.

This runs on a short cron and pings Discord if either pipeline has not
SUCCESSFULLY published within THRESHOLD. Two independent signals per site:
  * built site index.html mtime          -> catches missed cron + docgen/mkdocs
                                             build failure (no fresh build)
  * last refresh-log run reached
    "Deployment complete"                -> catches wrangler/deploy failure
                                             (build OK but publish failed, so the
                                              local mtime still looks fresh)

Alerts go to the existing Discord WEBHOOK_URL (read from discord_bot/config.py --
no new secret). A per-site cooldown stops it spamming during a sustained outage.
stdlib only, never raises fatally. Exit 0 = healthy, 1 = a site is stale.

Tunables (env): DRIFT_THRESHOLD (s, default 5400=90m), DRIFT_COOLDOWN (s,
default 10800=3h).
"""
from __future__ import annotations
import json
import os
import re
import sys
import time
import urllib.request

NOW = time.time()
HOME = os.path.expanduser("~")
THRESHOLD = int(os.environ.get("DRIFT_THRESHOLD", 5400))   # 90 min (refresh crons are hourly)
COOLDOWN = int(os.environ.get("DRIFT_COOLDOWN", 10800))    # re-alert at most every 3h per site
STATE = os.path.join(HOME, ".site_drift_state.json")

# (label, built-site index.html, refresh log)
SITES = [
    ("Legendary (live)", f"{HOME}/legendary-docs/site/index.html", f"{HOME}/refresh_site.log"),
    ("Relaunch",         f"{HOME}/relaunch-docs/site/index.html",  f"{HOME}/refresh_site_relaunch.log"),
]


def webhook_url():
    """Reuse the Discord webhook already configured for the bots (no new secret)."""
    for cfg in (f"{HOME}/server/tools/discord_bot/config.py",
                f"{HOME}/relaunch/tools/discord_bot/config.py"):
        try:
            m = re.search(r'^\s*WEBHOOK_URL\s*=\s*["\']([^"\']+)', open(cfg).read(), re.M)
            if m and m.group(1).startswith("http"):
                return m.group(1)
        except OSError:
            pass
    return None


def tail(path, n=50):
    try:
        with open(path, "rb") as f:
            return b"".join(f.readlines()[-n:]).decode("utf-8", "replace")
    except OSError:
        return ""


def load_state():
    try:
        return json.load(open(STATE))
    except Exception:
        return {}


def save_state(s):
    try:
        json.dump(s, open(STATE, "w"))
    except OSError:
        pass


problems = []  # (label, reason)
for name, idx, log in SITES:
    try:
        age = NOW - os.path.getmtime(idx)
        if age > THRESHOLD:
            problems.append((name, f"site not rebuilt in {int(age // 60)} min "
                                   f"(limit {THRESHOLD // 60}) -- refresh cron/build likely failing"))
            continue
    except OSError:
        problems.append((name, f"built site missing ({idx})"))
        continue
    if "Deployment complete" not in tail(log):
        problems.append((name, "last refresh did not reach 'Deployment complete' -- publish/deploy error"))

state = load_state()
stamp = time.strftime("%Y-%m-%d %H:%M UTC", time.gmtime())

if not problems:
    if state:               # everything healthy again -> clear cooldowns
        save_state({})
    print(f"[drift] OK -- both sites published within {THRESHOLD // 60} min ({stamp})")
    sys.exit(0)

print("[drift] PROBLEM:\n" + "\n".join(f"  - {n}: {r}" for n, r in problems))

# Only (re-)alert problems whose cooldown has elapsed, so a long outage doesn't spam.
fresh = [(n, r) for (n, r) in problems if NOW - float(state.get(n, 0)) > COOLDOWN]
for n, _ in fresh:
    state[n] = NOW
save_state(state)

if fresh:
    msg = (":rotating_light: **Docs site drift alarm** -- a player site may be stale:\n"
           + "\n".join(f"- **{n}**: {r}" for n, r in fresh)
           + f"\n_checked {stamp} on the box; re-alerts at most every {COOLDOWN // 3600}h/site_")
    url = webhook_url()
    if url:
        try:
            urllib.request.urlopen(urllib.request.Request(
                url, data=json.dumps({"content": msg}).encode(),
                headers={"Content-Type": "application/json"}), timeout=10)
            print("[drift] alerted via Discord webhook")
        except Exception as e:
            print(f"[drift] webhook post FAILED: {e}")
    else:
        print("[drift] no WEBHOOK_URL in discord_bot/config.py -- logged only")
else:
    print("[drift] (all current problems still within cooldown -- not re-alerting)")

sys.exit(1)
