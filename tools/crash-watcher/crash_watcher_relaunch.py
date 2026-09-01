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
import urllib.request
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


def post(content: str) -> None:
    if not os.path.exists(HOOK_FILE):
        print(f"[crash-watcher] missing webhook file: {HOOK_FILE}", file=sys.stderr)
        return
    with open(HOOK_FILE, encoding="utf-8-sig") as f:
        hook = f.read().strip()
    if not hook.startswith("https://discord.com/api/webhooks/"):
        print("[crash-watcher] webhook file is not a Discord webhook URL", file=sys.stderr)
        return
    if len(content) > MAX_LEN:
        content = content[:MAX_LEN] + "\n…(truncated)"
    req = urllib.request.Request(
        hook,
        data=json.dumps({"content": content}).encode(),
        headers={"Content-Type": "application/json", "User-Agent": "ffxi-crash-watcher"},
    )
    urllib.request.urlopen(req, timeout=15).read()


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
        post(":white_check_mark: **Crash watcher test** — if you can read this, "
             "#crash-report is wired. New Wheaty dumps will post a short summary here.")
        print("[crash-watcher] test post sent")
        return 0

    reports = list_reports()
    names = [p.name for p in reports]
    state = load_state()
    seen = set(state.get("seen", []))
    armed = bool(state.get("armed"))

    if not armed:
        state["seen"] = names
        state["armed"] = True
        save_state(state)
        post(":white_check_mark: **Crash watcher armed** — new `C:\\server\\dmp` "
             f"reports will post here. {len(names)} existing dump(s) ignored.")
        print(f"[crash-watcher] armed, ignored {len(names)} existing reports")
        return 0

    new_files = [p for p in reports if p.name not in seen]
    if not new_files:
        print("[crash-watcher] no new reports")
        return 0

    for path in new_files:
        info = parse_wheaty(path)
        crash_time = info.get("Time of crash", "")
        msg = format_report(
            info,
            nearby_log_lines(crash_time),
            supervisor_hits(crash_time),
            load_context(path),
        )
        try:
            post(msg)
            print(f"[crash-watcher] posted {path.name}")
        except Exception as e:
            print(f"[crash-watcher] post failed for {path.name}: {e}", file=sys.stderr)
            return 1
        seen.add(path.name)

    state["seen"] = sorted(seen)
    save_state(state)
    return 0


if __name__ == "__main__":
    sys.exit(main())
