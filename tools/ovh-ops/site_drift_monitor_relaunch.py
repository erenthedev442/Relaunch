#!/usr/bin/env python3
"""site_drift_monitor_relaunch.py -- dead-man's-switch for fjb-relaunch (OVH).

Relaunch-only half of the old shared Azure monitor (the Legendary half stays on
Azure). The relaunch docs site rebuilds hourly on OVH from the live server
(C:\\server + localhost xi_relaunch). If a refresh silently dies -- task broken,
docgen error, wrangler/auth failure, disk full -- the PUBLISHED site quietly
drifts from the live game and nobody notices.

Two independent signals:
  * built site index.html mtime           -> missed task + docgen/mkdocs failure
  * refresh log reached "Deployment complete" -> wrangler/deploy failure

Alerts go to the Discord webhook in C:\\relaunch-ops\\.discord_webhook (one line).
A cooldown stops it spamming during a sustained outage. stdlib only; never raises
fatally. Exit 0 = healthy, 1 = stale.

Tunables (env): DRIFT_THRESHOLD (s, default 5400=90m), DRIFT_COOLDOWN (s, 10800=3h).
"""
from __future__ import annotations
import json
import os
import sys
import time
import urllib.request

NOW = time.time()
THRESHOLD = int(os.environ.get("DRIFT_THRESHOLD", 5400))   # 90 min (refresh is hourly)
COOLDOWN = int(os.environ.get("DRIFT_COOLDOWN", 10800))    # re-alert at most every 3h
OPS = r"C:\relaunch-ops"
STATE = os.path.join(OPS, ".site_drift_state.json")
WEBHOOK_FILE = os.path.join(OPS, ".discord_webhook")

# (label, built-site index.html, refresh log)
SITES = [
    ("Relaunch", r"C:\relaunch-docs\site\index.html", os.path.join(OPS, "logs", "refresh_site_relaunch.log")),
]


def webhook_url():
    try:
        u = open(WEBHOOK_FILE, encoding="utf-8").read().strip()
        return u if u.startswith("http") else None
    except OSError:
        return None


def tail(path, n=80):
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
                                   f"(limit {THRESHOLD // 60}) -- refresh task/build likely failing"))
            continue
    except OSError:
        problems.append((name, f"built site missing ({idx})"))
        continue
    if "Deployment complete" not in tail(log):
        problems.append((name, "last refresh did not reach 'Deployment complete' -- publish/deploy error"))

state = load_state()
stamp = time.strftime("%Y-%m-%d %H:%M UTC", time.gmtime())

if not problems:
    if state:               # healthy again -> clear cooldowns
        save_state({})
    print(f"[drift] OK -- fjb-relaunch published within {THRESHOLD // 60} min ({stamp})")
    sys.exit(0)

print("[drift] PROBLEM:\n" + "\n".join(f"  - {n}: {r}" for n, r in problems))

fresh = [(n, r) for (n, r) in problems if NOW - float(state.get(n, 0)) > COOLDOWN]
for n, _ in fresh:
    state[n] = NOW
save_state(state)

if fresh:
    msg = (":rotating_light: **Relaunch docs drift alarm** -- fjb-relaunch may be stale:\n"
           + "\n".join(f"- **{n}**: {r}" for n, r in fresh)
           + f"\n_checked {stamp} on OVH; re-alerts at most every {COOLDOWN // 3600}h_")
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
        print(r"[drift] no webhook in C:\relaunch-ops\.discord_webhook -- logged only")
else:
    print("[drift] (within cooldown -- not re-alerting)")

sys.exit(1)
