"""Relaunch #rescue-me Discord bot -- `!rescue <charname>` unsticks a player.

Mirrors the engine's OFFLINE rescue (CLuaBaseEntity::resetPlayer in
src/map/lua/lua_baseentity.cpp): it clears the character's accounts_sessions
row and moves them to Lower Jeuno at the same known-good coordinate the C++
uses, so a player stuck on a broken/instance-only zone -- or blocked by a
stale "you are already logged in" session -- can log straight back in.

2.0-ONLY BY DESIGN. This runs on the OVH box against localhost `xi_relaunch`.
The Azure 1.0 rescue bot is separate and left untouched: one `!rescue` typed in
#rescue-me is handled by both bots, each resetting its own server. (xi_relaunch
is localhost-only, so the reset for 2.0 *must* run here on the box.)

It's a long-lived gateway daemon and needs the Discord **Message Content**
intent (it reads the text of `!rescue` messages). Run it via
tools/ovh-ops/run_rescue_bot_relaunch.ps1 (the "Relaunch-RescueBot" task).
See tools/discord_bot/RESCUE-BOT-RELAUNCH-DEPLOY.md for setup.
"""
from __future__ import annotations

import logging
import os
import re
import sys
from pathlib import Path

import discord

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from _db import connect  # self-contained xi_relaunch connector (reads network.lua)

# --- config (config.py is gitignored; see config.example.py) --------------
try:
    import config  # type: ignore
except Exception:
    config = None


def _cfg(name, default=None):
    return getattr(config, name, default) if config is not None else default


BOT_TOKEN       = str(_cfg("RESCUE_BOT_TOKEN", "") or "")
CHANNEL_ID      = int(_cfg("RESCUE_CHANNEL_ID", 0) or 0)
ALLOWED_ROLE_ID = str(_cfg("RESCUE_ALLOWED_ROLE_ID", "") or "")   # "" = anyone in the channel
LIVE_ROOT       = os.environ.get("LEGENDARY_LIVE_ROOT", r"C:\server")

# Rescue destination -- identical to CLuaBaseEntity::resetPlayer (Lower Jeuno).
# Keep in sync with src/map/lua/lua_baseentity.cpp if the engine spot ever moves.
ZONE_LOWER_JEUNO = 245
RESCUE_ROT, RESCUE_X, RESCUE_Y, RESCUE_Z = 86, 33.464, -5.000, 69.162

CMD_RE  = re.compile(r"^!rescue\s+(.+?)\s*$", re.IGNORECASE)
NAME_RE = re.compile(r"^[A-Za-z]{3,15}$")   # FFXI character-name charset

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
log = logging.getLogger("rescue_bot")


def do_rescue(charname: str):
    """Clear the session + warp the named char to Lower Jeuno. -> (ok, message).

    Mirrors the engine resetPlayer exactly (parameterized). Case-insensitive
    match rides the chars table's _ci collation; the canonical name is read
    back for the reply.
    """
    conn = connect(Path(LIVE_ROOT))
    if conn is None:
        return False, ":warning: Database unreachable -- try again in a moment."
    try:
        cur = conn.cursor()
        cur.execute("SELECT charid, charname FROM chars WHERE charname = %s", (charname,))
        row = cur.fetchone()
        if not row:
            return False, f":x: No character named **{charname}** exists on Relaunch 2.0."
        charid, canonical = row[0], row[1]

        cur.execute("DELETE FROM accounts_sessions WHERE charid = %s", (charid,))
        cleared = cur.rowcount

        cur.execute(
            "UPDATE chars SET "
            "pos_zone = %s, pos_prevzone = %s, pos_rot = %s, "
            "pos_x = %s, pos_y = %s, pos_z = %s, boundary = 0, moghouse = 0 "
            "WHERE charid = %s",
            (ZONE_LOWER_JEUNO, ZONE_LOWER_JEUNO, RESCUE_ROT,
             RESCUE_X, RESCUE_Y, RESCUE_Z, charid),
        )
        conn.commit()

        note = " (cleared a stuck session)" if cleared else ""
        return True, (f":white_check_mark: **{canonical}** rescued on Relaunch 2.0 "
                      f"-> Lower Jeuno{note}. They can log back in now.")
    except Exception as e:
        log.exception("rescue DB error for %s", charname)
        return False, f":warning: Rescue failed: {e}"
    finally:
        try:
            conn.close()
        except Exception:
            pass


intents = discord.Intents.default()
intents.message_content = True   # privileged -- enable it in the Developer Portal
client = discord.Client(intents=intents)


@client.event
async def on_ready():
    log.info("rescue bot online as %s; watching channel %s", client.user, CHANNEL_ID)


@client.event
async def on_message(msg: discord.Message):
    if msg.author.bot:
        return
    if CHANNEL_ID and msg.channel.id != CHANNEL_ID:
        return
    m = CMD_RE.match((msg.content or "").strip())
    if not m:
        return

    # Optional role gate (empty = anyone in the channel, matching the 1.0 UX).
    if ALLOWED_ROLE_ID:
        role_ids = {str(r.id) for r in getattr(msg.author, "roles", [])}
        if ALLOWED_ROLE_ID not in role_ids:
            await msg.reply(":no_entry: You don't have permission to use `!rescue`.",
                            mention_author=False)
            return

    charname = m.group(1).strip()
    if not NAME_RE.match(charname):
        await msg.reply("Usage: `!rescue <charname>` (letters only, 3-15 chars).",
                        mention_author=False)
        return

    ok, message = do_rescue(charname)
    # Audit trail: who ran it, on whom, and the outcome.
    log.info("rescue by %s (id=%s): target=%s ok=%s", msg.author, msg.author.id, charname, ok)
    await msg.reply(message, mention_author=False)


def main():
    if not BOT_TOKEN or BOT_TOKEN == "REPLACE_ME":
        log.error("RESCUE_BOT_TOKEN is not set in config.py -- see RESCUE-BOT-RELAUNCH-DEPLOY.md")
        sys.exit(2)
    if not CHANNEL_ID:
        log.error("RESCUE_CHANNEL_ID is not set in config.py (the #rescue-me channel ID)")
        sys.exit(2)
    client.run(BOT_TOKEN, log_handler=None)


if __name__ == "__main__":
    main()
