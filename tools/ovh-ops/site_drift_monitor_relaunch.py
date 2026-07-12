#!/usr/bin/env python3
"""site_drift_monitor_relaunch.py -- dead-man's-switch for fjb-relaunch (OVH).

Relaunch-only half of the old shared Azure monitor (the Legendary half stays on
Azure). The relaunch docs site rebuilds hourly on OVH from the live server
(C:\\server + localhost xi_relaunch). If a refresh silently dies -- task broken,
docgen error, wrangler/auth failure, disk full -- the PUBLISHED site quietly
drifts from the live game and nobody notices.

Three independent signals:
  * built site index.html mtime           -> missed task + docgen/mkdocs failure
  * refresh log reached "Deployment complete" -> wrangler/deploy failure
  * docgen WARN / [sync_audit] lines in the last refresh run -> content/site
    sync violations (unowned pages, naked facts, mirrored constants, generator
    warnings). Alerted once per distinct finding-set (fingerprint in state),
    so a fixed warning re-arms and a standing one doesn't spam. This is the
    owner-visible half of the "site must match the server" rule -- the audits
    are warn-loud in a log nobody reads without this.

Alerts go to the Discord webhook in C:\\relaunch-ops\\.discord_webhook (one line).
A cooldown stops it spamming during a sustained outage. stdlib only; never raises
fatally. Exit 0 = healthy, 1 = stale site (audit warnings alone stay exit 0).

Tunables (env): DRIFT_THRESHOLD (s, default 5400=90m), DRIFT_COOLDOWN (s, 10800=3h).
"""
from __future__ import annotations
import hashlib
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


# Warn-tagged lines emitted by docgen's guard generators (sync_audit,
# coverage_check, per-generator WARNs). Indented detail lines under a
# [sync_audit] header are captured by the second pattern.
AUDIT_TAG = ("[sync_audit]", "UNOWNED-PAGE", "NAKED-FACT", "MIRROR-CONST",
             "WARN", "MARKER MISSING")


def audit_findings(log):
    """Warn lines from the LAST refresh run in the log (between the final
    'refresh_site_relaunch START' marker and EOF)."""
    text = tail(log, 1200)
    start = text.rfind("refresh_site_relaunch START")
    if start != -1:
        text = text[start:]
    hits = []
    for line in text.splitlines():
        if any(tag in line for tag in AUDIT_TAG) and "[sync_audit] OK" not in line:
            hits.append(line.strip()[:200])
    return hits


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

# --- signal 3: content-sync audit warnings from the last publish run -------
# Independent of staleness: the site published fine but docgen flagged sync
# violations. Alert once per distinct finding-set (fingerprint), clear when
# the run comes back clean so the next violation re-alerts.
findings = audit_findings(SITES[0][2])
fp = hashlib.md5("\n".join(sorted(findings)).encode("utf-8", "replace")).hexdigest() if findings else ""
if findings and state.get("audit_fp") != fp:
    shown = findings[:12]
    print(f"[drift] {len(findings)} audit warning(s) in last publish:")
    for ln in shown:
        print(f"  - {ln}")
    msg = (":warning: **Relaunch site sync audit** -- the last publish raised "
           f"{len(findings)} warning(s):\n"
           + "\n".join(f"- `{ln}`" for ln in shown)
           + (f"\n_... and {len(findings) - len(shown)} more_" if len(findings) > len(shown) else "")
           + f"\n_fix or allowlist (docs stay live meanwhile); {stamp}_")
    url = webhook_url()
    posted = False
    if url:
        try:
            urllib.request.urlopen(urllib.request.Request(
                url, data=json.dumps({"content": msg}).encode(),
                headers={"Content-Type": "application/json"}), timeout=10)
            posted = True
            print("[drift] audit warnings alerted via Discord webhook")
        except Exception as e:
            print(f"[drift] audit webhook post FAILED: {e} -- will retry next run")
    else:
        print("[drift] no webhook configured -- audit warnings logged only")
    # Record the fingerprint only once the alert actually went out (or can
    # never go out) -- a transient/broken webhook must not eat the alert.
    if posted or not url:
        state["audit_fp"] = fp
        save_state(state)
elif findings:
    print(f"[drift] {len(findings)} audit warning(s) (unchanged -- already alerted)")
elif state.pop("audit_fp", None) is not None:
    save_state(state)   # clean run -> re-arm the audit alert

if not problems:
    # Healthy again -> clear the staleness cooldowns, but KEEP audit_fp so a
    # standing audit finding doesn't re-alert every run.
    stale_keys = [k for k in state if k != "audit_fp"]
    if stale_keys:
        for k in stale_keys:
            state.pop(k, None)
        save_state(state)
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
