"""LinkShell -> Discord real-time bridge.

Mirrors ONE in-game LinkShell's chat into a Discord channel in near-real time
(~3s). One-way (game -> Discord). No bot token, no C++ change, no rebuild --
it rides the server's built-in chat audit:

    settings/map.lua:  AUDIT_CHAT = true   AND   AUDIT_LINKSHELL = true

With those on, the map server INSERTs every LinkShell line into the `audit_chat`
table (src/map/packets/c2s/0x0b5_chat_std.cpp -> auditLinkshell). This daemon
tails that table by its auto-increment `lineID`, filters to the one shell you
name, and POSTs each new line to a Discord webhook.

Because the C++ stores the *decoded* linkshell name in `lsName`, a single shell
is matched no matter whether members equip it as LinkShell1 or LinkShell2.

SAFETY: every post neutralizes ALL Discord mentions (allowed_mentions parse=[]),
so a player typing "@everyone" / "@role" in LinkShell can never ping Discord.

USAGE (on the box, where the live DB is):
    cp tools/discord_bot/config.example.py tools/discord_bot/config.py
    # edit config.py: set LS_BRIDGE_WEBHOOK_URL + LS_BRIDGE_NAME
    python3 tools/discord_bot/ls_bridge.py            # run as a daemon
    python3 tools/discord_bot/ls_bridge.py --once     # single poll (test/cron)

Run it as a service with tools/discord_bot/ls_bridge.service (systemd).

EXIT CODES (only meaningful with --once):
    0  ok      1  config error      2  DB unreachable
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

# Same import dance as discord_bot.py: prefer the local sibling _db.py (the live
# server checkout lacks tools/docgen/), fall back to the docgen copy in a worktree.
THIS_DIR  = Path(__file__).resolve().parent
REPO_ROOT = THIS_DIR.parents[1]
sys.path.insert(0, str(REPO_ROOT))
sys.path.insert(0, str(THIS_DIR))

try:
    from _db import connect  # local sibling copy  # noqa: E402
except Exception:  # pragma: no cover
    from tools.docgen._db import connect  # noqa: E402

# Best-effort heartbeat so the docs status page can flag the bridge STALE if it
# silently dies. No-op if the helper isn't present (safe direction to fail).
try:
    from tools._heartbeat import write_heartbeat
except Exception:
    def write_heartbeat(*_a, **_k):
        return False


STATE_PATH = THIS_DIR / "ls_bridge_state.json"


# ============================================================
# Config + state
# ============================================================

def load_config():
    cfg_path = THIS_DIR / "config.py"
    if not cfg_path.exists():
        print("[ls_bridge] config.py not found. Copy config.example.py -> config.py, "
              "then set LS_BRIDGE_WEBHOOK_URL + LS_BRIDGE_NAME.")
        sys.exit(1)
    spec: dict = {}
    exec(cfg_path.read_text(encoding="utf-8"), spec, spec)  # nosec - user-owned file

    url = str(spec.get("LS_BRIDGE_WEBHOOK_URL", "") or "")
    if not url or "REPLACE_ME" in url:
        print("[ls_bridge] LS_BRIDGE_WEBHOOK_URL is not set in config.py. Create a Discord "
              "webhook for your LinkShell channel and paste the URL.")
        sys.exit(1)

    name = str(spec.get("LS_BRIDGE_NAME", "") or "")
    if not name or "REPLACE_ME" in name:
        print("[ls_bridge] LS_BRIDGE_NAME is not set in config.py. Set it to the exact "
              "in-game LinkShell name you want mirrored (e.g. \"Legendary\").")
        sys.exit(1)

    return spec


def load_state():
    if not STATE_PATH.exists():
        return {"last_line": None}
    try:
        return json.loads(STATE_PATH.read_text(encoding="utf-8"))
    except Exception as e:
        print(f"[ls_bridge] state file corrupt, re-baselining: {e}")
        return {"last_line": None}


def save_state(state):
    """Atomic write so an interrupted run can't corrupt the cursor."""
    tmp = STATE_PATH.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(state, indent=2), encoding="utf-8")
    os.replace(tmp, STATE_PATH)


# ============================================================
# Discord posting
# ============================================================

def post(cfg, content: str) -> bool:
    payload = {
        "content":  content[:1990],   # Discord hard-caps at 2000
        "username": cfg.get("LS_BRIDGE_BOT_USERNAME") or "Legendary Linkshell",
        # CRITICAL: forbid ALL mentions. Without this a player typing "@everyone"
        # or "@role" in LinkShell would ping your whole Discord server.
        "allowed_mentions": {"parse": []},
    }
    avatar = cfg.get("LS_BRIDGE_AVATAR_URL")
    if avatar:
        payload["avatar_url"] = avatar

    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        cfg["LS_BRIDGE_WEBHOOK_URL"],
        data=data,
        headers={
            "Content-Type": "application/json",
            # Discord sits behind Cloudflare, which 403s the default
            # "Python-urllib/x.y" User-Agent as a bad bot ("error 1010") -- so every
            # webhook POST silently failed and the cursor wedged at 0. Sending any
            # real UA clears Cloudflare's Browser Integrity Check. Overridable via
            # config.py (LS_BRIDGE_USER_AGENT) if Discord ever tightens it further.
            "User-Agent": cfg.get("LS_BRIDGE_USER_AGENT")
                or "Legendary-LS-Bridge/1.0 (+https://legendary-ffxi.pages.dev)",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            if 200 <= resp.status < 300:
                return True
            print(f"[ls_bridge] unexpected status {resp.status}")
            return False
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        print(f"[ls_bridge] HTTP {e.code}: {body}")
        return False
    except urllib.error.URLError as e:
        print(f"[ls_bridge] webhook unreachable: {e.reason}")
        return False


# ============================================================
# Message formatting
# ============================================================

def _decode(raw) -> str:
    """audit_chat.message is a BLOB -> bytes. Decode to text, dropping control
    bytes. FFXI auto-translate phrases are multi-byte and will show as the
    Unicode replacement char -- acceptable for a chat mirror."""
    if isinstance(raw, (bytes, bytearray)):
        s = bytes(raw).decode("utf-8", errors="replace")
    else:
        s = str(raw or "")
    s = "".join(ch for ch in s if ch >= " ")  # strip control chars
    return s.strip()


def format_line(cfg, speaker, ls_name, message) -> str | None:
    msg = _decode(message)
    if not msg:
        return None
    speaker = str(speaker or "?").strip()
    prefix = f"`[{ls_name}]` " if cfg.get("LS_BRIDGE_SHOW_LSNAME", False) else ""
    # Bold the speaker; body posts verbatim. Mentions are neutralized in post().
    return f"{prefix}**{speaker}**: {msg}"


# ============================================================
# Poll
# ============================================================

def poll_once(cfg, conn, state) -> int:
    """One poll. Posts any new LinkShell lines for the target shell. Returns the
    number of messages posted this cycle."""
    target = str(cfg.get("LS_BRIDGE_NAME", "") or "")
    cur = conn.cursor()

    # Current high-water lineID -- cheap (PK index). Also lets us detect a table
    # truncate/recreate (e.g. a full schema reimport drops + recreates audit_chat,
    # resetting AUTO_INCREMENT) so we re-baseline instead of wedging forever above
    # every new row.
    cur.execute("SELECT COALESCE(MAX(lineID), 0) FROM audit_chat")
    max_id = int((cur.fetchone() or [0])[0] or 0)

    # First ever run, OR the table reset under us: baseline at the newest line so
    # we never replay history into Discord and never sit dead above a reset table.
    if state.get("last_line") is None or max_id < int(state["last_line"]):
        if state.get("last_line") is not None and max_id < int(state["last_line"]):
            print(f"[ls_bridge] audit_chat reset (max {max_id} < cursor {state['last_line']}); re-baselining")
        state["last_line"] = max_id
        save_state(state)
        cur.close()
        _refresh(conn)
        print(f"[ls_bridge] baseline at lineID {max_id}; bridging \"{target}\" from here")
        return 0

    last = int(state["last_line"])
    cur.execute(
        "SELECT lineID, speaker, lsName, message FROM audit_chat "
        "WHERE type = 'LINKSHELL' AND lineID > %s AND lsName = %s "
        "ORDER BY lineID ASC LIMIT 200",
        (last, target),
    )
    rows = cur.fetchall()
    cur.close()
    _refresh(conn)  # end the read txn so the NEXT poll sees fresh inserts

    posted = 0
    for line_id, speaker, ls_name, message in rows:
        content = format_line(cfg, speaker, ls_name, message)
        if content is None:
            # nothing renderable (e.g. pure auto-translate) -> skip past it
            state["last_line"] = int(line_id)
            save_state(state)
            continue
        if post(cfg, content):
            posted += 1
            state["last_line"] = int(line_id)
            save_state(state)
            time.sleep(0.3)   # gentle spacing; keeps Discord ordering + avoids 429
        else:
            # Transient failure (Discord down / rate limited): stop WITHOUT
            # advancing so this line retries next cycle -- don't drop chat.
            break
    return posted


def _refresh(conn):
    """End the current implicit transaction so the next SELECT on this long-lived
    connection sees rows inserted by other sessions (InnoDB default is
    REPEATABLE READ -> a held txn would never see new chat)."""
    try:
        conn.commit()
    except Exception:
        try:
            conn.rollback()
        except Exception:
            pass


# ============================================================
# Main loop
# ============================================================

def main() -> int:
    ap = argparse.ArgumentParser(description="LinkShell -> Discord bridge")
    ap.add_argument("--once", action="store_true",
                    help="single poll then exit (for testing or a cron tick)")
    ap.add_argument("--interval", type=float, default=None,
                    help="seconds between polls (overrides config LS_BRIDGE_POLL_SECONDS)")
    args = ap.parse_args()

    cfg = load_config()
    interval = args.interval if args.interval is not None else float(cfg.get("LS_BRIDGE_POLL_SECONDS", 3) or 3)
    interval = max(0.5, interval)
    state = load_state()

    conn = None
    try:
        while True:
            try:
                if conn is None:
                    conn = connect(REPO_ROOT)
                    if conn is None:
                        print("[ls_bridge] DB unreachable; will retry.")
                        if args.once:
                            return 2
                        time.sleep(min(interval * 3, 30))
                        continue
                poll_once(cfg, conn, state)
                write_heartbeat(REPO_ROOT, "ls_bridge", ok=True, detail=f"line {state.get('last_line')}")
            except Exception as e:
                print(f"[ls_bridge] poll error: {e}; reconnecting next cycle")
                try:
                    if conn:
                        conn.close()
                except Exception:
                    pass
                conn = None
                write_heartbeat(REPO_ROOT, "ls_bridge", ok=False, detail=str(e)[:120])

            if args.once:
                return 0
            time.sleep(interval)
    except KeyboardInterrupt:
        print("[ls_bridge] stopped.")
        return 0
    finally:
        try:
            if conn:
                conn.close()
        except Exception:
            pass


if __name__ == "__main__":
    sys.exit(main())
