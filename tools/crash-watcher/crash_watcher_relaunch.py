#!/usr/bin/env python3
"""Relaunch crash watcher -> Discord #crash-report webhook.

Watches C:\\server\\dmp for new Wheaty .log files (and supervisor hang lines).
Posts a short summary: exception, top game stack frame, git SHA, zone if
present, and a few map-log lines from around the crash. Does not attach the
full dump.

Webhook URL lives in C:\\relaunch-ops\\.crash_webhook (one line, not in git).
State lives in C:\\relaunch-ops\\crash-watcher\\state.json.

First run records every dump already on disk and posts one "armed" message
so old crashes are not replayed. --test posts a ping and exits.

Read-only. Cannot slow or crash xi_map. Run every minute via
tools/ovh-ops/run_crash_watcher_relaunch.ps1.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import urllib.error
import urllib.request
from datetime import datetime, timedelta
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
OPS = os.environ.get("RELAUNCH_OPS", r"C:\relaunch-ops")
STATE_FILE = os.environ.get("CRASH_STATE", os.path.join(OPS, "crash-watcher", "state.json"))
HOOK_FILE = os.environ.get("CRASH_WEBHOOK", os.path.join(OPS, ".crash_webhook"))
DMP_DIR = os.environ.get("CRASH_DMP", str(REPO_ROOT / "dmp"))
MAP_LOG = os.environ.get("CRASH_MAP_LOG", str(REPO_ROOT / "log" / "map-server.log"))
SUP_LOG = os.environ.get("CRASH_SUP_LOG", str(REPO_ROOT / "relaunch-supervisor.log"))
MAX_LEN = 1900

GAME_FRAME_RE = re.compile(
    r"([A-Za-z0-9_:`<>,\s]+)\s+\([^)]*?([^\\/]+\.(?:cpp|h|lua)), line (\d+)\)"
)
HEADER_RE = re.compile(
    r"^(Exception code|Time of crash|Git SHA|Git Commit Subject|Git Branch|"
    r"Process Uptime|Process Name|Full crash report|Memory dump):\s*(.+)$"
)
ZONE_RE = re.compile(r'm_zoneName\s*=\s*"([^"]+)"')
INTERESTING_LOG = re.compile(
    r"Divergence|Dynamis|instance|Zoning|logged in|logged out|Created instance|"
    r"Loading instance|INACTIVITY WATCHDOG|!!! CRASH|luautils::",
    re.I,
)
HUNG_RE = re.compile(
    r"^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\s+HUNG xi_map confirmed \((.+)\) "
    r"- force killing \(PID (\d+)\)",
    re.I,
)
HANG_LOOKBACK = timedelta(hours=24)


def post(content: str) -> bool:
    """POST to Discord. True only when Discord accepted the message.
    Missing/invalid hook is a failure so the event is retried, not consumed.
    Never logs the webhook URL (Discord's HTTPError includes it)."""
    if not os.path.exists(HOOK_FILE):
        print(f"[crash-watcher] missing webhook file: {HOOK_FILE}", file=sys.stderr)
        return False
    with open(HOOK_FILE, encoding="utf-8-sig") as f:
        hook = f.read().strip()
    if not hook.startswith("https://discord.com/api/webhooks/"):
        print("[crash-watcher] webhook file is not a Discord webhook URL", file=sys.stderr)
        return False
    if len(content) > MAX_LEN:
        content = content[:MAX_LEN] + "\n…(truncated)"
    req = urllib.request.Request(
        hook,
        data=json.dumps({"content": content}).encode(),
        headers={"Content-Type": "application/json", "User-Agent": "ffxi-crash-watcher"},
    )
    try:
        urllib.request.urlopen(req, timeout=15).read()
        return True
    except urllib.error.HTTPError as exc:
        print(f"[crash-watcher] webhook HTTP {exc.code} {exc.reason}", file=sys.stderr)
        return False
    except OSError as exc:
        print(f"[crash-watcher] webhook send failed: {type(exc).__name__}", file=sys.stderr)
        return False


def load_state() -> dict:
    if os.path.exists(STATE_FILE):
        with open(STATE_FILE, encoding="utf-8") as f:
            return json.load(f)
    return {}


def save_state(state: dict) -> None:
    os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
    with open(STATE_FILE, "w", encoding="utf-8") as f:
        json.dump(state, f)


def list_reports() -> list[Path]:
    root = Path(DMP_DIR)
    if not root.is_dir():
        return []
    return sorted(root.glob("*.log"), key=lambda p: p.stat().st_mtime)


def load_context(wheaty_log: Path) -> str:
    sidecar = wheaty_log.with_suffix(".context.txt")
    if sidecar.is_file():
        try:
            return sidecar.read_text(encoding="utf-8", errors="replace").strip()
        except OSError:
            pass

    try:
        text = wheaty_log.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""
    start = text.find("=== Flight recorder ===")
    if start < 0:
        return ""
    rest = text[start + len("=== Flight recorder ===") :]
    end = rest.find("=====================================================")
    block = rest if end < 0 else rest[:end]
    return block.strip()


def parse_wheaty(path: Path) -> dict[str, str]:
    info: dict[str, str] = {"file": path.name}
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError as e:
        info["error"] = str(e)
        return info

    for line in text.splitlines()[:80]:
        m = HEADER_RE.match(line.strip())
        if m:
            info[m.group(1)] = m.group(2).strip()

    zone = ZONE_RE.search(text)
    if zone:
        info["zone"] = zone.group(1)

    for line in text.splitlines():
        if ".cpp, line" in line or ".h, line" in line or ".lua, line" in line:
            if any(skip in line for skip in ("asio\\", "spdlog\\", "efsw\\", "vcstartup", "win_iocp")):
                continue
            fm = GAME_FRAME_RE.search(line)
            if fm:
                info["frame"] = f"{fm.group(1).strip()} ({fm.group(2)}:{fm.group(3)})"
                break
    return info


def tail_text(path: str, nbytes: int = 400_000) -> str:
    try:
        size = os.path.getsize(path)
        with open(path, encoding="utf-8", errors="replace") as f:
            if size > nbytes:
                f.seek(size - nbytes)
                f.readline()
            return f.read()
    except OSError:
        return ""


def nearby_log_lines(crash_time: str) -> list[str]:
    clock = ""
    tm = re.search(r"(\d{2}:\d{2})", crash_time or "")
    if tm:
        hh, mm = tm.group(1).split(":")
        clocks = [f"{hh}:{mm}"]
        try:
            prev = f"{int(hh):02d}:{(int(mm) - 1) % 60:02d}"
            nxt = f"{int(hh):02d}:{(int(mm) + 1) % 60:02d}"
            clocks = [prev, tm.group(1), nxt]
        except ValueError:
            pass
        clock = "|".join(re.escape(c) for c in clocks)

    blob = tail_text(MAP_LOG)
    hits: list[str] = []
    for raw in blob.splitlines():
        line = raw.strip()
        if not line:
            continue
        if clock and not re.search(clock, line):
            continue
        if INTERESTING_LOG.search(line):
            hits.append(line[:220])
    return hits[-12:]


def supervisor_hits(crash_time: str) -> list[str]:
    blob = tail_text(SUP_LOG, 80_000)
    clock = ""
    tm = re.search(r"(\d{2}:\d{2})", crash_time or "")
    if tm:
        clock = tm.group(1)
    hits: list[str] = []
    for raw in blob.splitlines():
        line = raw.strip()
        if not line:
            continue
        if clock and clock not in line:
            continue
        if re.search(r"HUNG|force kill|Starting xi_|Supervisor starting|INACTIVITY", line, re.I):
            hits.append(line[:220])
    return hits[-6:]


def parse_hangs() -> list[dict[str, str]]:
    hangs: list[dict[str, str]] = []
    for raw in tail_text(SUP_LOG, 400_000).splitlines():
        m = HUNG_RE.match(raw.strip())
        if not m:
            continue
        hangs.append({
            "key": m.group(1),
            "time": m.group(1),
            "reason": m.group(2),
            "pid": m.group(3),
        })
    return hangs


def format_hang(hang: dict[str, str], map_lines: list[str], sup_lines: list[str]) -> str:
    lines = [
        "**xi_map HUNG** — supervisor force-killed it (no Wheaty dump)",
        f"Time: {hang['time']}",
        f"Reason: {hang['reason']}",
        f"PID: {hang['pid']}",
    ]
    if map_lines:
        lines.append("")
        lines.append("**Map log near hang**")
        lines.append("```")
        lines.extend(map_lines)
        lines.append("```")
    else:
        lines.append("_No matching map-log lines in the last few minutes._")
    if sup_lines:
        lines.append("**Supervisor**")
        lines.append("```")
        lines.extend(sup_lines)
        lines.append("```")
    return "\n".join(lines)


def format_report(info: dict[str, str], map_lines: list[str], sup_lines: list[str], context: str) -> str:
    lines = [
        "**xi_map crash**",
        f"Time: {info.get('Time of crash', '?')}",
        f"Exception: {info.get('Exception code', '?')}",
        f"Where: {info.get('frame', '(no game frame named)')}",
        f"Git: `{info.get('Git SHA', '?')}` — {info.get('Git Commit Subject', '')}".rstrip(" —"),
        f"Uptime: {info.get('Process Uptime', '?')}",
    ]
    if info.get("zone"):
        lines.append(f"Zone (dump): **{info['zone']}**")
    if context:
        lines.append("")
        lines.append("**Players / instances**")
        lines.append("```")
        lines.extend(context.splitlines()[:20])
        lines.append("```")
    lines.append(f"Dump: `{info.get('file', '?')}`")

    if map_lines:
        lines.append("")
        lines.append("**Map log near crash**")
        lines.append("```")
        lines.extend(map_lines)
        lines.append("```")
    else:
        lines.append("_No matching map-log lines in the last few minutes._")

    if sup_lines:
        lines.append("**Supervisor**")
        lines.append("```")
        lines.extend(sup_lines)
        lines.append("```")

    return "\n".join(lines)


def self_test(tmpdir: Path) -> int:
    """Prove sidecar + Wheaty fallback both name players. Does not post."""
    wheaty = tmpdir / "xi_map.exe_1-9_2-47-8.log"
    sidecar = tmpdir / "xi_map.exe_1-9_2-47-8.context.txt"
    snapshot = (
        "Snapshot: 2026/09/01 02:47:08\n"
        "Players / instances:\n"
        "  Zone Dynamis-Bastok_[D] [295] — 2 instance copy/copies\n"
        "    [0] instance 29500 dynamis_bastok_d: Alice (123)\n"
        "    [1] instance 29500 dynamis_bastok_d: Carol (789)\n"
        "Recent instance events:\n"
        "  2026/09/01 02:46:01  Loading instance 29500 for Carol (789)\n"
    )
    sidecar.write_text(snapshot, encoding="utf-8")
    wheaty.write_text(
        "Exception code: 0xC0000005 ACCESS_VIOLATION\n"
        "Time of crash: 2026/09/01 02:47:08\n"
        "Git SHA: deadbeef\n"
        "Git Commit Subject: test\n"
        "Process Uptime: 6 hours\n"
        'm_zoneName = "Dynamis-Bastok_[D]"\n'
        "CZoneInstance::ZoneServer (zone_instance.cpp, line 505)\n"
        "=====================================================\n"
        "=== Flight recorder ===\n"
        + snapshot
        + "=====================================================\n",
        encoding="utf-8",
    )

    info = parse_wheaty(wheaty)
    from_sidecar = load_context(wheaty)
    sidecar.unlink()
    from_log = load_context(wheaty)
    msg = format_report(info, [], [], from_sidecar)

    checks = [
        (info.get("Exception code", "").startswith("0xC0000005"), "exception"),
        (info.get("zone") == "Dynamis-Bastok_[D]", "zone"),
        ("zone_instance.cpp:505" in info.get("frame", ""), "frame"),
        ("Alice (123)" in from_sidecar, "sidecar Alice"),
        ("Carol (789)" in from_sidecar, "sidecar Carol"),
        ("Alice (123)" in from_log, "log fallback Alice"),
        ("**Players / instances**" in msg, "discord section"),
        ("Alice (123)" in msg, "discord Alice"),
    ]
    failed = [name for ok, name in checks if not ok]
    if failed:
        print(f"[crash-watcher] self-test FAILED: {', '.join(failed)}")
        return 1
    print("[crash-watcher] self-test OK — sidecar, Wheaty fallback, and Discord text all name Alice/Carol")
    print(msg)
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--test", action="store_true", help="Post a test message and exit")
    parser.add_argument("--self-test", action="store_true",
                        help="Parse a fake dump locally; do not post to Discord")
    args = parser.parse_args()

    if args.self_test:
        import tempfile
        with tempfile.TemporaryDirectory() as tmp:
            return self_test(Path(tmp))

    if args.test:
        ok = post(":white_check_mark: **Crash watcher test** — if you can read this, "
                  "#crash-report is wired. New Wheaty dumps and supervisor hang-kills "
                  "will post a short summary here.")
        if ok:
            print("[crash-watcher] test post sent")
            return 0
        print("[crash-watcher] test post failed", file=sys.stderr)
        return 1

    reports = list_reports()
    by_name = {p.name: p for p in reports}
    names = list(by_name)
    state = load_state()
    seen = set(state.get("seen", []))
    armed = bool(state.get("armed"))
    failed = False
    posted_any = False
    pending_dumps: list[str] = []

    if not armed:
        state["seen"] = names
        armed_msg = (
            ":white_check_mark: **Crash watcher armed** — new `C:\\server\\dmp` "
            f"reports and supervisor hang-kills will post here. {len(names)} existing dump(s) ignored."
        )
        if post(armed_msg):
            state["armed"] = True
            posted_any = True
            print(f"[crash-watcher] armed, ignored {len(names)} existing reports")
        else:
            failed = True
            print("[crash-watcher] armed ping failed; existing dumps stay ignored, will retry",
                  file=sys.stderr)
        save_state(state)
        if failed:
            return 1
    else:
        pending_dumps = [n for n in state.get("pending_dumps", []) if n in by_name]
        for n in names:
            if n not in seen and n not in pending_dumps:
                pending_dumps.append(n)
        still_pending: list[str] = []
        for name in pending_dumps:
            path = by_name[name]
            info = parse_wheaty(path)
            crash_time = info.get("Time of crash", "")
            msg = format_report(
                info,
                nearby_log_lines(crash_time),
                supervisor_hits(crash_time),
                load_context(path),
            )
            if post(msg):
                seen.add(name)
                posted_any = True
                print(f"[crash-watcher] posted {name}")
            else:
                still_pending.append(name)
                failed = True
                print(f"[crash-watcher] post failed for {name}; will retry", file=sys.stderr)
        state["seen"] = sorted(seen)
        state["pending_dumps"] = still_pending

    hangs = parse_hangs()
    hang_keys = {h["key"] for h in hangs}
    hangs_seen = set(state.get("hangs_seen", []))
    pending_hangs = [k for k in state.get("pending_hangs", []) if k in hang_keys]
    if not state.get("hangs_armed"):
        cutoff = datetime.now() - HANG_LOOKBACK
        for hang in hangs:
            try:
                when = datetime.strptime(hang["time"], "%Y-%m-%d %H:%M:%S")
            except ValueError:
                hangs_seen.add(hang["key"])
                continue
            if when >= cutoff:
                if hang["key"] not in pending_hangs:
                    pending_hangs.append(hang["key"])
            else:
                hangs_seen.add(hang["key"])
        state["hangs_armed"] = True
    else:
        for hang in hangs:
            if hang["key"] not in hangs_seen and hang["key"] not in pending_hangs:
                pending_hangs.append(hang["key"])

    hang_by_key = {h["key"]: h for h in hangs}
    still_hangs: list[str] = []
    for key in pending_hangs:
        hang = hang_by_key[key]
        msg = format_hang(
            hang,
            nearby_log_lines(hang["time"]),
            supervisor_hits(hang["time"]),
        )
        if post(msg):
            hangs_seen.add(key)
            posted_any = True
            print(f"[crash-watcher] posted hang {key}")
        else:
            still_hangs.append(key)
            failed = True
            print(f"[crash-watcher] hang post failed for {key}; will retry", file=sys.stderr)
    state["hangs_seen"] = sorted(hangs_seen)
    state["pending_hangs"] = still_hangs
    save_state(state)

    if failed:
        return 1
    if not posted_any:
        print("[crash-watcher] no new reports")
    return 0


if __name__ == "__main__":
    sys.exit(main())
