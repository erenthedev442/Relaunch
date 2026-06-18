"""Render a build-time server-status snapshot onto docs/community/status.md.

Three marker blocks:
  ``status-online`` — a one-line population snapshot (online now + characters).
  ``status-hnm``    — the timed-HNM tracker: each NM's zone, respawn window,
                      and whether it was up (or roughly when it pops) as of
                      the last site build.
  ``status-jobs``   — a dead-man's-switch health panel for the background jobs
                      (AH market-maker, both Discord bots, nightly DB backup):
                      each writes a heartbeat JSON via tools/_heartbeat.py on a
                      successful pass; this panel reads the newest heartbeat under
                      ``$LEGENDARY_LIVE_ROOT/tools/heartbeats`` and flags any job
                      whose last run is older than its cadence as STALE, so a
                      silently-dead task or daemon gets noticed.

HNM spawn state lives in ``server_variables`` as ``[HNM]<Name>`` = the Unix
time the NM will (re)pop. The custom HNM module reads this on zone init: if
``popTime <= now`` the NM is spawned (UP); otherwise a respawn timer is set.
So for status:

  * ``now >= popTime``  -> **UP**
  * ``now <  popTime``  -> waiting, pops at ``popTime``
  * ``popTime == 0``    -> never initialized (that zone hasn't loaded yet)

The NM roster, zones, and respawn windows are parsed from the live HNM module
by reusing ``generators/hnm.py`` (which already drives progression/hnm.md), so
this tracker can't drift from the HNM doc page. HQ land kings
(Nidhogg / Aspidochelone / King Behemoth) are QM-pop with no timer var, so the
page notes them statically rather than tracking them here.

This is a *build-time snapshot*, not a live ticker — the relative "pops in
~Xh" ages after the build. The page says so and points players at in-game /
Discord for live status (the webhook notifier posts HNM spawns in real time).

No-ops silently without a DB connection (e.g. CI) or HNM module, leaving the
previously-published snapshot in place.
"""
from __future__ import annotations

import json
import time
from pathlib import Path

from tools.docgen._db import connect
from tools.docgen._markers import write_between_markers
from tools.docgen._paths import resolve_source
from tools.docgen.generators.hnm import parse as _parse_hnm_raw, _window_str as _fmt_hnm_window
from tools.docgen.generators.events import _parse_catalog_events, _parse_dynamic_events


def _rel(seconds: int) -> str:
    """Seconds-until-pop -> compact '2h 15m' / '45m' / '1d 3h'."""
    seconds = max(0, int(seconds))
    if seconds < 3600:
        m = seconds // 60
        return f"{m}m" if m else "<1m"
    if seconds < 86400:
        h = seconds // 3600
        m = (seconds % 3600) // 60
        return f"{h}h {m}m" if m else f"{h}h"
    d = seconds // 86400
    h = (seconds % 86400) // 3600
    return f"{d}d {h}h" if h else f"{d}d"


def _render_online(online: int, chars: int) -> str:
    return (
        f"**{online:,}** online · **{chars:,}** characters · "
        "_snapshot from the last site rebuild — the header badge shows live status._"
    )


def _render_hnm(rows: list[tuple[str, str, str, int]], now: int) -> str:
    """rows: (nm_name, zone_display, window_str, pop_time)."""
    if not rows:
        return "_HNM tracker data is temporarily unavailable._"

    # Sort: UP first, then soonest pop, uninitialized last.
    def sort_key(r: tuple[str, str, str, int]):
        pop = r[3]
        if pop == 0:
            return (2, 0)
        if now >= pop:
            return (0, 0)            # up now
        return (1, pop - now)        # waiting — soonest first

    ordered = sorted(rows, key=sort_key)
    lines = [
        "_Snapshot taken at build time — timers drift after that. For live "
        "status, check in-game or the Discord HNM feed._",
        "",
        "| NM | Zone | Respawn window | Status (snapshot) |",
        "|---|---|---:|---|",
    ]
    for name, zone, window, pop in ordered:
        if pop == 0:
            status = "⚪ awaiting first spawn"
        elif now >= pop:
            status = "🟢 **Up now**"
        else:
            status = f"🟠 pops in ~{_rel(pop - now)}"
        lines.append(f"| **{name}** | {zone} | {window} | {status} |")
    return "\n".join(lines)


def _fmt_mult(m: float) -> str:
    """Mark multiplier -> compact label: 2.0 -> '2×', 1.5 -> '1.5×'."""
    if abs(m - round(m)) < 1e-9:
        return f"{int(round(m))}×"
    return f"{m:g}×"


def _iso_date(ts: int) -> str:
    """Unix seconds -> 'YYYY-MM-DD' (UTC), matching the page's date style."""
    return time.strftime("%Y-%m-%d", time.gmtime(int(ts)))


def _render_events(events: list[dict], now: int) -> str:
    """Render the Active Events panel from merged seasonal events.

    Lists every event that is currently active or still upcoming (ended events
    are dropped, mirroring in-game ``!events``). When two active windows
    overlap the engine applies only the highest-priority one, so the others are
    flagged 'superseded' rather than implying a stacked bonus.
    """
    active = [e for e in events if e["start"] <= now < e["finish"]]
    upcoming = [e for e in events if e["start"] > now]
    if not active and not upcoming:
        # Keep this byte-identical to the placeholder seeded in status.md so an
        # empty catalog doesn't churn the page on every rebuild.
        return (
            "_No bonus-mark events are active or scheduled right now. "
            "Watch **#announcements** on Discord for the next one._"
        )

    active.sort(key=lambda e: (-e["priority"], e["finish"]))
    upcoming.sort(key=lambda e: e["start"])

    lines = [
        "_Snapshot from the last site rebuild — for the live bonus, use "
        "`!events` in-game._",
        "",
        "| Event | Bonus | Window (UTC) | Status (snapshot) |",
        "|---|---|---|---|",
    ]

    def row(e: dict, status: str) -> str:
        # finish is exclusive (midnight after the last active day), so show the
        # inclusive last day for a human-readable window.
        window = f"{_iso_date(e['start'])} → {_iso_date(e['finish'] - 1)}"
        return f"| **{e['name']}** | {_fmt_mult(e['multiplier'])} marks | {window} | {status} |"

    for i, e in enumerate(active):
        if i == 0:
            status = f"\U0001f7e2 **active** — ends in ~{_rel(e['finish'] - now)}"
        else:
            status = "⚪ superseded (lower priority)"
        lines.append(row(e, status))
    for e in upcoming:
        lines.append(row(e, f"\U0001f7e0 starts in ~{_rel(e['start'] - now)}"))
    return "\n".join(lines)


# Background-jobs health roster: (heartbeat id, label, cadence, stale-after secs).
# Each job calls tools/_heartbeat.write_heartbeat() on a successful pass; if the
# newest heartbeat is older than stale-after, the job is flagged STALE. Thresholds
# carry ~2 cycles of slack so a single skipped run isn't a false alarm.
_JOBS = [
    ("ah_market_maker",   "Auction House market-maker",   "every 15 min",        35 * 60),
    ("discord_webhook",   "Discord notifier (webhook)",   "every 5 min",         15 * 60),
    ("discord_token_bot", "Discord bot (slash commands)", "daemon · 5 min beat", 25 * 60),
    ("db_backup",         "Database backup + verify",     "nightly 04:00",       30 * 3600),
]


def _read_heartbeat(hb_dir: Path, job: str) -> dict | None:
    """Load one heartbeat JSON, or None if missing/unreadable. Re-implemented
    here rather than importing tools._heartbeat: this generator runs in the docs
    worktree, where tools/ is the docgen package, not the live tree that owns the
    helper. The payload shape (ts/ok/detail) is that helper's tiny contract."""
    try:
        data = json.loads((hb_dir / f"{job}.json").read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return None
    return data if isinstance(data, dict) else None


def _render_jobs(hb_dir: Path, now: int) -> str:
    lines = [
        "_Health snapshot from the last site rebuild._ "
        "\U0001f7e2 OK · \U0001f7e0 last run reported errors · "
        "\U0001f534 STALE (may be down) · ⚪ no signal yet.",
        "",
        "| Background job | Schedule | Last run | Status (snapshot) |",
        "|---|---|---:|---|",
    ]
    for job, label, cadence, stale_after in _JOBS:
        hb = _read_heartbeat(hb_dir, job)
        ts = hb.get("ts") if isinstance(hb, dict) else None
        if not isinstance(ts, (int, float)):
            last, status = "—", "⚪ no signal yet"
        else:
            age = max(0, now - int(ts))
            last = f"{_rel(age)} ago"
            if age > stale_after:
                status = f"\U0001f534 **STALE** — no run in {_rel(age)}"
            elif not hb.get("ok", True):
                status = "\U0001f7e0 last run errored"
            else:
                status = "\U0001f7e2 OK"
        lines.append(f"| **{label}** | {cadence} | {last} | {status} |")
    return "\n".join(lines)


def generate(repo_root: Path, docs_dir: Path) -> None:
    page = docs_dir / "community" / "status.md"
    if not page.exists():
        print(f"[status] skip: page not found ({page})")
        return

    now = int(time.time())
    written = 0

    # --- background-jobs health (dead-man's-switch) -----------------------
    # Rendered first and independently of the DB: this panel exists to surface
    # outages, so it must still publish even if the game DB is down too. The
    # heartbeats live on the LIVE checkout (gitignored), so resolve them via
    # LEGENDARY_LIVE_ROOT; CI (no live root, no repo copy) skips and leaves the
    # previously-published panel untouched.
    hb_dir = resolve_source(repo_root, "tools/heartbeats")
    if hb_dir is None:
        print("[status] heartbeats dir not found; leaving background-jobs panel as-is")
    elif write_between_markers(page, "status-jobs", _render_jobs(hb_dir, now)):
        written += 1
    else:
        print("[status] status-jobs: marker missing in status.md")

    # --- seasonal bonus-mark events (Active Events panel) -----------------
    # Reads the live Lua event catalogs (static schedule + the ephemeral GM
    # !setbonus file), not the DB, so render it here in the DB-independent zone
    # alongside the jobs panel. The static parser is shared with catalog_json so
    # the panel can't drift from the exported single source of truth. Merges
    # both sources the way the in-game engine does, then snapshots active/upcoming.
    se_src = resolve_source(repo_root, "modules/custom/lua/seasonal_events_catalog.lua")
    dyn_src = resolve_source(repo_root, "modules/custom/lua/seasonal_events_dynamic.lua")
    if se_src is None and dyn_src is None:
        print("[status] seasonal event catalogs not found; leaving Active Events panel as-is")
    else:
        try:
            events: list[dict] = []
            if se_src is not None:
                events += _parse_catalog_events(se_src.read_text(encoding="utf-8", errors="replace"))
            if dyn_src is not None:
                events += _parse_dynamic_events(dyn_src.read_text(encoding="utf-8", errors="replace"))
            if write_between_markers(page, "status-events", _render_events(events, now)):
                written += 1
            else:
                print("[status] status-events: marker missing in status.md")
        except Exception as e:  # noqa: BLE001
            print(f"[status] Active Events panel failed ({e})")

    conn = connect(repo_root)
    if conn is None:
        print("[status] skip DB sections: no DB connection (LEGENDARY_LIVE_ROOT unset / DB unreachable)")
        print(f"[status] {written} section(s) written into markers")
        return

    cur = conn.cursor()
    try:
        # --- population snapshot -------------------------------------------
        try:
            cur.execute("SELECT COUNT(*) FROM accounts_sessions")
            online = int(cur.fetchone()[0])
            cur.execute("SELECT COUNT(*) FROM chars WHERE gmlevel = 0")
            chars = int(cur.fetchone()[0])
            if write_between_markers(page, "status-online", _render_online(online, chars)):
                written += 1
            else:
                print("[status] status-online: marker missing in status.md")
        except Exception as e:  # noqa: BLE001
            print(f"[status] online snapshot failed ({e})")

        # --- HNM tracker ----------------------------------------------------
        src = resolve_source(repo_root, "modules/custom/lua/custom_HNM_system.lua")
        if src is None:
            print("[status] HNM module not found; skipping HNM tracker")
        else:
            try:
                result = _parse_hnm_raw(src.read_text(encoding="utf-8", errors="replace"))
                cur.execute("SELECT name, value FROM server_variables WHERE name LIKE '[HNM]%'")
                popmap = {r[0]: int(r[1]) for r in cur.fetchall()}
                rows: list[tuple[str, str, str, int]] = []
                for z in result.get("kings", []):
                    name = z.get("nq", "")
                    if not name:
                        continue
                    var = f"[HNM]{name}"
                    window = _fmt_hnm_window(z["win_min"], z["win_max"])
                    rows.append((name, z.get("zone") or "—", window, popmap.get(var, 0)))
                for z in result.get("lower", []):
                    name = z.get("nm", "")
                    if not name:
                        continue
                    var = f"[HNM]{name}"
                    window = _fmt_hnm_window(z["win_min"], z["win_max"])
                    rows.append((name, z.get("zone") or "—", window, popmap.get(var, 0)))
                if write_between_markers(page, "status-hnm", _render_hnm(rows, now)):
                    written += 1
                else:
                    print("[status] status-hnm: marker missing in status.md")
            except Exception as e:  # noqa: BLE001
                print(f"[status] HNM tracker failed ({e})")
    finally:
        cur.close()
        conn.close()

    print(f"[status] {written} section(s) written into markers")
