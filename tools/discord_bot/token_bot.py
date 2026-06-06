"""Legendary Hunter — two-way Discord *token* bot (slash commands).

Companion to ``discord_bot.py`` (the one-way webhook notifier). Where the
webhook bot PUSHES events (rank-ups, capstones, digests) into a channel,
this bot answers PULL queries from players via slash commands:

    /online              how many hunters are logged in right now
    /huntrank  [char]    a character's Hunter's Guild ranks + rep
    /leaderboard [cat]   top 10 by kills / Hunt Marks / Infamy / ascensions
    /prestige  [char]    a character's Ascension (Prestige) progress
    /lfg <activity>      broadcast a looking-for-group call to the channel
    /register  <char>    link your Discord account to your in-game character
    /whoami              show which character you're linked to
    /unregister          unlink your character

It shares the webhook bot's *single source of truth* catalog layer (the rank
ladder and guild list, both derived from ``catalog.json``) by importing
``discord_bot``, and the same DB connection helper (``_db.connect``). The two
bots therefore can never disagree about ranks/guilds. This bot is strictly
**read-only** against the game DB — the only thing it persists is a local
``links.json`` (Discord<->character links, gitignored); game data is never touched.

Account linking lets players run ``/huntrank`` / ``/prestige`` with no argument
and have it resolve to *their* character. Linking is trust-based (MVP): anyone
may claim any *unclaimed* character, but each character can be linked by only
one Discord member, so a claimed main can't be hijacked.

Unlike the webhook bot, this is a long-running daemon — it holds a gateway
connection — so it needs a real Discord *application + bot token*. It uses the
default (non-privileged) intents only, so you do NOT have to toggle any
privileged intents in the Developer Portal. See README.md / the hand-off doc
for application creation + hosting.

REQUIREMENTS:
    pip install -U discord.py        (2.x)

CONFIG (config.py — the same file the webhook bot uses):
    BOT_TOKEN   = "..."                # REQUIRED — Discord Dev Portal -> Bot -> Token
    GUILD_ID    = 123456789012345678   # REQUIRED — your server ID (enables instant sync)
    LFG_ROLE_ID = ""                   # optional — role to ping on /lfg

EXIT CODES:
    1  config error (missing config.py / BOT_TOKEN / GUILD_ID)
    2  discord.py not installed
"""
from __future__ import annotations

import asyncio
import json
import os
import sys
import time
from pathlib import Path
from typing import Optional

# --- path bootstrap (mirrors discord_bot.py) so the sibling _db.py and the
#     discord_bot module both resolve when run from anywhere. -----------------
THIS_DIR  = Path(__file__).resolve().parent
REPO_ROOT = THIS_DIR.parents[1]
sys.path.insert(0, str(REPO_ROOT))   # so tools.docgen.* resolves in a worktree
sys.path.insert(0, str(THIS_DIR))    # so the sibling modules win the import

# discord.py is the only hard third-party dependency. Fail loud + actionable
# rather than dumping a raw ImportError traceback on the user.
try:
    import discord
    from discord import app_commands
    from discord.ext import tasks
except ImportError:
    print("[token_bot] discord.py is not installed. Run:  pip install -U discord.py")
    sys.exit(2)

# Reuse the webhook bot's catalog-derived tables (rank ladder, guild list) so
# the two bots can never disagree — they read the same catalog.json. Importing
# discord_bot only runs its module-level catalog load; main() is __main__-guarded.
import discord_bot as core          # noqa: E402
from _db import connect             # noqa: E402

# Best-effort heartbeat (dead-man's-switch); no-op if absent. See discord_bot.py.
try:
    from tools._heartbeat import write_heartbeat   # noqa: E402
except Exception:
    def write_heartbeat(*_a, **_k):
        return False


EMBED_COLOR = 0xC8A24B   # Legendary gold

# LSB job ids (xi.job) -> abbreviation. Stable (part of FFXI itself); the
# Prestige system stores per-job progress under Prestige_Level_<jobId>, jobId 1..22.
JOB_NAMES = {
    1: "WAR", 2: "MNK", 3: "WHM", 4: "BLM", 5: "RDM", 6: "THF",
    7: "PLD", 8: "DRK", 9: "BST", 10: "BRD", 11: "RNG", 12: "SAM",
    13: "NIN", 14: "DRG", 15: "SMN", 16: "BLU", 17: "COR", 18: "PUP",
    19: "DNC", 20: "SCH", 21: "GEO", 22: "RUN",
}

# /leaderboard categories: CharVar -> human label. Each is a lifetime/total
# counter so the ranking is meaningful and stable.
LEADERBOARD_LABELS = {
    "Custom_NM_Kills":           "Hunting League Kills",
    "HL_Points_Lifetime":        "Hunt Marks (Lifetime)",
    "Infamy_Lifetime":           "Infamy (Lifetime)",
    "Prestige_Ascensions_Total": "Ascensions",
}

# /lfg activity options.
LFG_ACTIVITIES = ["Hunting League", "Dungeon", "HNM / Kings", "Reforge NM", "Other"]

_MEDALS = {1: ":first_place:", 2: ":second_place:", 3: ":third_place:"}


# ============================================================
# Config
# ============================================================

def load_config() -> dict:
    cfg_path = THIS_DIR / "config.py"
    if not cfg_path.exists():
        print("[token_bot] config.py not found. Copy config.example.py -> config.py "
              "and set BOT_TOKEN + GUILD_ID.")
        sys.exit(1)
    spec: dict = {}
    exec(cfg_path.read_text(encoding="utf-8"), spec, spec)  # nosec - user-owned file
    token = spec.get("BOT_TOKEN", "") or ""
    if not token or "REPLACE_ME" in token:
        print("[token_bot] BOT_TOKEN is not set in config.py. "
              "Create a bot at https://discord.com/developers/applications and paste its token.")
        sys.exit(1)
    if not spec.get("GUILD_ID"):
        print("[token_bot] GUILD_ID is not set in config.py "
              "(needed to register slash commands instantly). "
              "Enable Developer Mode, right-click your server icon -> Copy Server ID.")
        sys.exit(1)
    return spec


# ============================================================
# DB helpers — synchronous; called off-thread via asyncio.to_thread so the
# blocking driver never stalls the gateway event loop. Each opens a fresh
# short-lived connection (connect() has a 3s timeout); fine for low traffic.
# ============================================================

def _connect():
    conn = connect(REPO_ROOT)
    if conn is None:
        raise RuntimeError("DB unreachable")
    return conn


def db_online() -> tuple[int, list[str]]:
    """(total logged-in chars, non-opted-out charnames). accounts_sessions
    holds one row per active game session."""
    conn = _connect()
    try:
        cur = conn.cursor()
        cur.execute("SELECT COUNT(*) FROM accounts_sessions")
        total = int((cur.fetchone() or [0])[0] or 0)
        cur.execute(
            "SELECT c.charname "
            "  FROM accounts_sessions s "
            "  JOIN chars c ON c.charid = s.charid "
            "  LEFT JOIN char_vars opt ON opt.charid = c.charid "
            "                         AND opt.varname = 'Leaderboard_OptOut' "
            " WHERE (opt.value IS NULL OR opt.value = 0) "
            " ORDER BY c.charname"
        )
        names = [r[0] for r in cur.fetchall()]
        return total, names
    finally:
        conn.close()


def db_huntrank(charname: str) -> Optional[dict]:
    """Per-guild rep for a character, or None if no such character."""
    conn = _connect()
    try:
        cur = conn.cursor()
        cur.execute("SELECT charid, charname FROM chars WHERE charname = %s", (charname,))
        row = cur.fetchone()
        if not row:
            return None
        charid, real_name = row[0], row[1]
        repcvs = [repCv for _k, _l, repCv in core.GUILDS]
        ph = ",".join(["%s"] * len(repcvs))
        cur.execute(
            f"SELECT varname, value FROM char_vars "
            f" WHERE charid = %s AND varname IN ({ph}) "
            f"   AND (expiry = 0 OR expiry > UNIX_TIMESTAMP())",
            [charid, *repcvs],
        )
        reps = {vn: int(v or 0) for vn, v in cur.fetchall()}
        return {"charname": real_name, "reps": reps}
    finally:
        conn.close()


def db_leaderboard(varname: str, limit: int = 10) -> list[tuple[str, int]]:
    """Top-N (charname, value) for one CharVar, honoring Leaderboard_OptOut."""
    conn = _connect()
    try:
        cur = conn.cursor()
        cur.execute(
            "SELECT c.charname, cv.value "
            "  FROM chars c "
            "  JOIN char_vars cv ON cv.charid = c.charid AND cv.varname = %s "
            "  LEFT JOIN char_vars opt ON opt.charid = c.charid "
            "                         AND opt.varname = 'Leaderboard_OptOut' "
            " WHERE (opt.value IS NULL OR opt.value = 0) "
            "   AND (cv.expiry = 0 OR cv.expiry > UNIX_TIMESTAMP()) "
            "   AND cv.value > 0 "
            " ORDER BY cv.value DESC "
            " LIMIT %s",
            (varname, int(limit)),
        )
        return [(r[0], int(r[1] or 0)) for r in cur.fetchall()]
    finally:
        conn.close()


def db_prestige(charname: str) -> Optional[dict]:
    """Account-wide ascension total + per-job Prestige_Level_/AP_ for a char."""
    conn = _connect()
    try:
        cur = conn.cursor()
        cur.execute("SELECT charid, charname FROM chars WHERE charname = %s", (charname,))
        row = cur.fetchone()
        if not row:
            return None
        charid, real_name = row[0], row[1]
        cur.execute(
            "SELECT varname, value FROM char_vars "
            " WHERE charid = %s AND varname LIKE 'Prestige%'",
            (charid,),
        )
        total = 0
        levels: dict[int, int] = {}
        ap: dict[int, int] = {}
        for vn, v in cur.fetchall():
            iv = int(v or 0)
            if vn == "Prestige_Ascensions_Total":
                total = iv
            elif vn.startswith("Prestige_Level_"):
                try:
                    levels[int(vn.rsplit("_", 1)[1])] = iv
                except ValueError:
                    pass
            elif vn.startswith("Prestige_AP_") and not vn.startswith("Prestige_AP_Lifetime_"):
                try:
                    ap[int(vn.rsplit("_", 1)[1])] = iv
                except ValueError:
                    pass
        return {"charname": real_name, "total": total, "levels": levels, "ap": ap}
    finally:
        conn.close()


def db_find_char(charname: str) -> Optional[tuple[int, str]]:
    """(charid, canonical charname) for an exact name match, else None.
    Used by /register to validate + resolve the claimed character."""
    conn = _connect()
    try:
        cur = conn.cursor()
        cur.execute("SELECT charid, charname FROM chars WHERE charname = %s", (charname,))
        row = cur.fetchone()
        if not row:
            return None
        return int(row[0]), row[1]
    finally:
        conn.close()


def db_char_role_tiers(charid: int) -> set:
    """Which rank-sync tiers a character currently qualifies for:
        'grandmaster' — top rank (max rep threshold) on >=1 of the four guilds
        'trinity'     — Title_Trinity_Hunter flag (top rank on three guilds)
        'apex'        — Title_Apex_Hunter flag   (top rank on all four guilds)
    Returned as an independent set so the role map can assign any subset; an
    Apex hunter typically qualifies for all three at once (roles stack). Reuses
    core.GUILDS / core.RANK_THRESHOLDS so it can't drift from the webhook bot."""
    repcvs = [repCv for _k, _l, repCv in core.GUILDS]
    want = repcvs + ["Title_Apex_Hunter", "Title_Trinity_Hunter"]
    conn = _connect()
    try:
        cur = conn.cursor()
        ph = ",".join(["%s"] * len(want))
        cur.execute(
            f"SELECT varname, value FROM char_vars "
            f" WHERE charid = %s AND varname IN ({ph}) "
            f"   AND (expiry = 0 OR expiry > UNIX_TIMESTAMP())",
            [charid, *want],
        )
        vals = {vn: int(v or 0) for vn, v in cur.fetchall()}
    finally:
        conn.close()
    gm_threshold = core.RANK_THRESHOLDS[-1][0]
    tiers: set = set()
    if any(vals.get(rc, 0) >= gm_threshold for rc in repcvs):
        tiers.add("grandmaster")
    if vals.get("Title_Trinity_Hunter", 0) == 1:
        tiers.add("trinity")
    if vals.get("Title_Apex_Hunter", 0) == 1:
        tiers.add("apex")
    return tiers


# ============================================================
# Account links — Discord user <-> in-game character.
#
# Stored in a local links.json next to the bot (gitignored), NOT in the game
# DB: this bot stays strictly read-only against the game. The map is
#   { "<discord_user_id>": {"charid": int, "charname": str, "ts": int} }
#
# MVP claim model: linking is trust-based — anyone may claim any *unclaimed*
# character (there's no in-game ownership proof yet). Char-uniqueness IS
# enforced (a character can't be linked by two Discord members at once), so a
# claimed main can't be hijacked; a GM can hand-edit links.json to settle
# disputes. A future hardening step is an in-game confirmation code, but that
# needs a DB-write path this read-only bot deliberately avoids.
# ============================================================

LINKS_PATH = THIS_DIR / "links.json"
_links_lock = asyncio.Lock()


def _links_read() -> dict:
    """Load the link map; tolerate a missing/corrupt file by returning {}."""
    try:
        with open(LINKS_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
        return data if isinstance(data, dict) else {}
    except (FileNotFoundError, ValueError, OSError):
        return {}


def _links_write(data: dict) -> None:
    """Atomically replace links.json (temp file + os.replace) so a crash
    mid-write can't truncate the map."""
    tmp = LINKS_PATH.with_name(LINKS_PATH.name + ".tmp")
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, sort_keys=True)
    os.replace(tmp, LINKS_PATH)


async def _get_link(discord_id: int) -> Optional[dict]:
    """The link record for one Discord user, or None. Read off-thread."""
    data = await asyncio.to_thread(_links_read)
    rec = data.get(str(discord_id))
    return rec if isinstance(rec, dict) else None


async def _resolve_target(
    interaction: "discord.Interaction", character: Optional[str]
) -> tuple[Optional[str], Optional[str]]:
    """Pick the character a /huntrank|/prestige call should report on. An
    explicit name wins; otherwise fall back to the caller's linked character.
    Returns (charname, error_message) with exactly one non-None."""
    if character and character.strip():
        return character.strip(), None
    link = await _get_link(interaction.user.id)
    if link and link.get("charname"):
        return link["charname"], None
    return None, (
        ":information_source: Which character? Pass `character:<name>`, or link "
        "yourself once with `/register <your character>` so I can default to it."
    )


# ============================================================
# Bot + slash commands
# ============================================================

intents = discord.Intents.default()          # no privileged intents needed
client = discord.Client(intents=intents)
tree = app_commands.CommandTree(client)
CFG: dict = {}


@tree.command(name="online", description="How many hunters are logged in right now")
async def cmd_online(interaction: discord.Interaction) -> None:
    await interaction.response.defer(thinking=True)
    try:
        total, names = await asyncio.to_thread(db_online)
    except Exception as e:
        await interaction.followup.send(f":warning: Couldn't reach the game DB ({e}).")
        return
    emb = discord.Embed(title=":satellite: Hunters Online", color=EMBED_COLOR)
    emb.description = f"**{total}** {'hunter' if total == 1 else 'hunters'} currently logged in."
    if names:
        shown = names[:20]
        more = "" if len(names) <= 20 else f"\n…and {len(names) - 20} more"
        emb.add_field(name="Who's on", value="\n".join(shown) + more, inline=False)
    await interaction.followup.send(embed=emb)


@tree.command(name="huntrank", description="A character's Hunter's Guild ranks and rep")
@app_commands.describe(character="In-game character name (defaults to your linked character)")
async def cmd_huntrank(interaction: discord.Interaction, character: Optional[str] = None) -> None:
    await interaction.response.defer(thinking=True)
    target, err = await _resolve_target(interaction, character)
    if err:
        await interaction.followup.send(err)
        return
    try:
        data = await asyncio.to_thread(db_huntrank, target)
    except Exception as e:
        await interaction.followup.send(f":warning: Couldn't reach the game DB ({e}).")
        return
    if data is None:
        await interaction.followup.send(f":mag: No character named **{target}** found.")
        return
    emb = discord.Embed(title=f":shield: {data['charname']} — Hunter's Guild Ranks",
                        color=EMBED_COLOR)
    for key, label, repCv in core.GUILDS:
        rep = data["reps"].get(repCv, 0)
        idx = core.rank_index_for_rep(rep)
        rank_label = core.RANK_LABELS[idx - 1]
        amp = core.RANK_AMP_PCT[idx - 1]
        mark = core.GUILD_MARK_TYPES.get(key, "Marks")
        emb.add_field(
            name=label,
            value=f"**{rank_label}** · {rep:,} rep · +{amp}% {mark}",
            inline=False,
        )
    await interaction.followup.send(embed=emb)


@tree.command(name="leaderboard", description="Top 10 hunters by a category")
@app_commands.describe(category="What to rank by (defaults to Hunting League kills)")
@app_commands.choices(
    category=[app_commands.Choice(name=label, value=cv)
              for cv, label in LEADERBOARD_LABELS.items()]
)
async def cmd_leaderboard(
    interaction: discord.Interaction,
    category: Optional[app_commands.Choice[str]] = None,
) -> None:
    await interaction.response.defer(thinking=True)
    varname = category.value if category else "Custom_NM_Kills"
    label = LEADERBOARD_LABELS.get(varname, varname)
    try:
        rows = await asyncio.to_thread(db_leaderboard, varname, 10)
    except Exception as e:
        await interaction.followup.send(f":warning: Couldn't reach the game DB ({e}).")
        return
    emb = discord.Embed(title=f":trophy: Leaderboard — {label}", color=EMBED_COLOR)
    if not rows:
        emb.description = "_No ranked hunters yet._"
    else:
        lines = []
        for i, (name, val) in enumerate(rows, start=1):
            badge = _MEDALS.get(i, f"**{i}.**")
            lines.append(f"{badge} {name} — {val:,}")
        emb.description = "\n".join(lines)
    await interaction.followup.send(embed=emb)


@tree.command(name="prestige", description="A character's Ascension (Prestige) progress")
@app_commands.describe(character="In-game character name (defaults to your linked character)")
async def cmd_prestige(interaction: discord.Interaction, character: Optional[str] = None) -> None:
    await interaction.response.defer(thinking=True)
    target, err = await _resolve_target(interaction, character)
    if err:
        await interaction.followup.send(err)
        return
    try:
        data = await asyncio.to_thread(db_prestige, target)
    except Exception as e:
        await interaction.followup.send(f":warning: Couldn't reach the game DB ({e}).")
        return
    if data is None:
        await interaction.followup.send(f":mag: No character named **{target}** found.")
        return
    total = data["total"]
    levels = {j: l for j, l in data["levels"].items() if l > 0}
    emb = discord.Embed(title=f":sparkles: {data['charname']} — Ascension", color=EMBED_COLOR)
    if total <= 0 and not levels:
        emb.description = (
            "No ascensions yet. Reach **Hunting League Legend** (Rank V), then re-clear "
            "the three Legend Trial NMs to ascend — each ascension grants Ascension Points "
            "on your current job."
        )
    else:
        emb.description = f"**{total}** lifetime ascension{'s' if total != 1 else ''}."
        parts = []
        for jid in sorted(levels):
            ap = data["ap"].get(jid, 0)
            cell = f"{JOB_NAMES.get(jid, f'JOB{jid}')} **{levels[jid]}**"
            if ap:
                cell += f" ({ap} AP)"
            parts.append(cell)
        if parts:
            emb.add_field(name="Per-job Prestige", value=" · ".join(parts), inline=False)
    await interaction.followup.send(embed=emb)


@tree.command(name="register", description="Link your Discord account to your in-game character")
@app_commands.describe(character="Your in-game character name (exact spelling)")
async def cmd_register(interaction: discord.Interaction, character: str) -> None:
    await interaction.response.defer(thinking=True, ephemeral=True)
    name = character.strip()
    if not name:
        await interaction.followup.send(":warning: Please give a character name.", ephemeral=True)
        return
    try:
        found = await asyncio.to_thread(db_find_char, name)
    except Exception as e:
        await interaction.followup.send(f":warning: Couldn't reach the game DB ({e}).", ephemeral=True)
        return
    if found is None:
        await interaction.followup.send(
            f":mag: No character named **{name}** found. Check the exact spelling.",
            ephemeral=True)
        return
    charid, canon = found
    me = str(interaction.user.id)
    async with _links_lock:
        data = await asyncio.to_thread(_links_read)
        # Char-uniqueness: refuse if someone else already claimed this character.
        for did, link in data.items():
            if did != me and isinstance(link, dict) and int(link.get("charid", -1)) == charid:
                await interaction.followup.send(
                    f":no_entry: **{canon}** is already linked to another Discord member. "
                    "If it's really yours and was claimed by mistake, ask a GM to fix it.",
                    ephemeral=True)
                return
        prev = data.get(me) if isinstance(data.get(me), dict) else None
        data[me] = {"charid": charid, "charname": canon, "ts": int(time.time())}
        await asyncio.to_thread(_links_write, data)
    if prev and int(prev.get("charid", -1)) != charid:
        await interaction.followup.send(
            f":white_check_mark: Re-linked from **{prev.get('charname', '?')}** to **{canon}**. "
            "If rank-role sync is on, your roles update on the next pass.",
            ephemeral=True)
    else:
        await interaction.followup.send(
            f":white_check_mark: You're now linked to **{canon}**. "
            "`/huntrank` and `/prestige` will default to this character.",
            ephemeral=True)


@tree.command(name="whoami", description="Show which in-game character you're linked to")
async def cmd_whoami(interaction: discord.Interaction) -> None:
    await interaction.response.defer(thinking=True, ephemeral=True)
    link = await _get_link(interaction.user.id)
    if not link:
        await interaction.followup.send(
            "You're not linked yet. Use `/register <your character>` to connect your "
            "Discord account to your in-game character.", ephemeral=True)
        return
    await interaction.followup.send(
        f":link: You're linked to **{link.get('charname', '?')}**. "
        "Use `/unregister` to remove this link.", ephemeral=True)


@tree.command(name="unregister", description="Remove the link between your Discord and your character")
async def cmd_unregister(interaction: discord.Interaction) -> None:
    await interaction.response.defer(thinking=True, ephemeral=True)
    me = str(interaction.user.id)
    async with _links_lock:
        data = await asyncio.to_thread(_links_read)
        prev = data.pop(me, None)
        if prev is not None:
            await asyncio.to_thread(_links_write, data)
    if prev is None:
        await interaction.followup.send("You weren't linked to any character.", ephemeral=True)
    else:
        name = prev.get("charname", "?") if isinstance(prev, dict) else "?"
        await interaction.followup.send(
            f":wave: Unlinked from **{name}**. Rank roles (if any) clear on the next sync.",
            ephemeral=True)


@tree.command(name="lfg", description="Broadcast a looking-for-group call to the channel")
@app_commands.describe(activity="What you want to do", note="Optional details (zone, time, party size…)")
@app_commands.choices(
    activity=[app_commands.Choice(name=a, value=a) for a in LFG_ACTIVITIES]
)
async def cmd_lfg(
    interaction: discord.Interaction,
    activity: app_commands.Choice[str],
    note: Optional[str] = None,
) -> None:
    role_id = str(CFG.get("LFG_ROLE_ID", "") or "")
    ping = f"<@&{role_id}> " if role_id else ""
    emb = discord.Embed(title=":crossed_swords: Looking for Group", color=EMBED_COLOR)
    emb.add_field(name="Activity", value=activity.value, inline=True)
    emb.add_field(name="Hunter", value=interaction.user.mention, inline=True)
    if note:
        emb.add_field(name="Details", value=note[:500], inline=False)
    await interaction.response.send_message(
        content=(ping or None),
        embed=emb,
        allowed_mentions=discord.AllowedMentions(roles=bool(role_id), everyone=False, users=False),
    )


# ============================================================
# Presence — show the live online count as the bot's status.
# ============================================================

@tasks.loop(minutes=2)
async def update_presence() -> None:
    try:
        total, _ = await asyncio.to_thread(db_online)
    except Exception:
        return
    activity = discord.Activity(
        type=discord.ActivityType.watching,
        name=f"{total} hunter{'s' if total != 1 else ''} online",
    )
    try:
        await client.change_presence(activity=activity)
    except Exception:
        pass


@update_presence.before_loop
async def _before_presence() -> None:
    await client.wait_until_ready()


# ============================================================
# Rank role sync — grant/remove Discord roles by in-game capstone tier.
#
# Runs every 10 minutes over the linked players in links.json. For each it
# resolves their guild Member (cache, else a REST fetch_member so NO privileged
# members intent is needed), computes their tiers from the live DB, and adds/
# removes ONLY the roles mapped in CFG['ROLE_SYNC']. Unmanaged roles are never
# touched. Needs the bot to have Manage Roles and to sit ABOVE the target roles
# in the server's role list, or Discord rejects the change (handled per-user).
# ============================================================

def _parse_role_map(cfg: dict) -> dict:
    """tier -> int role id, dropping blanks / zeros / unknown tiers."""
    raw = cfg.get("ROLE_SYNC") or {}
    out: dict = {}
    if isinstance(raw, dict):
        for tier, rid in raw.items():
            if tier not in ("apex", "trinity", "grandmaster"):
                continue
            try:
                rid_int = int(str(rid).strip())
            except (TypeError, ValueError):
                continue
            if rid_int > 0:
                out[tier] = rid_int
    return out


@tasks.loop(minutes=10)
async def sync_roles() -> None:
    if not CFG.get("ROLE_SYNC_ENABLED"):
        return
    role_map = _parse_role_map(CFG)
    if not role_map:
        return
    guild = client.get_guild(int(CFG["GUILD_ID"]))
    if guild is None:
        return
    # Resolve configured roles; skip any that were deleted.
    managed: dict = {}
    for tier, rid in role_map.items():
        role = guild.get_role(rid)
        if role is not None:
            managed[tier] = role
    if not managed:
        return
    managed_roles = set(managed.values())

    links = await asyncio.to_thread(_links_read)
    for discord_id, rec in links.items():
        if not isinstance(rec, dict):
            continue
        try:
            charid = int(rec.get("charid"))
            uid = int(discord_id)
        except (TypeError, ValueError):
            continue
        # get_member hits the cache; fetch_member falls back to REST (no
        # privileged intent). A user who left the server resolves to None/raises.
        member = guild.get_member(uid)
        if member is None:
            try:
                member = await guild.fetch_member(uid)
            except discord.HTTPException:
                continue
        try:
            tiers = await asyncio.to_thread(db_char_role_tiers, charid)
        except Exception:
            continue   # DB hiccup — leave this user's roles as-is this pass
        should_have = {managed[t] for t in tiers if t in managed}
        current = set(member.roles) & managed_roles
        to_add = list(should_have - current)
        to_remove = list(current - should_have)
        try:
            if to_add:
                await member.add_roles(*to_add, reason="Legendary rank sync")
            if to_remove:
                await member.remove_roles(*to_remove, reason="Legendary rank sync")
        except discord.HTTPException:
            continue   # missing perms / role hierarchy — skip, retry next pass


@sync_roles.before_loop
async def _before_sync() -> None:
    await client.wait_until_ready()


# ============================================================
# Heartbeat — dead-man's-switch. A dedicated loop (NOT piggy-backed on the
# presence/role-sync loops) keeps this a pure process-liveness signal: it fires
# every 5 min as long as the gateway is connected, independent of whether the
# game DB is reachable or role sync is enabled. The docs status page flags
# 'discord_token_bot' as STALE if these stop landing. tasks.loop runs the first
# iteration immediately on start, so a fresh boot writes a heartbeat at once.
# ============================================================

@tasks.loop(minutes=5)
async def write_hb() -> None:
    await asyncio.to_thread(write_heartbeat, REPO_ROOT, "discord_token_bot", True, "gateway up")


@write_hb.before_loop
async def _before_hb() -> None:
    await client.wait_until_ready()


@client.event
async def on_ready() -> None:
    guild = discord.Object(id=int(CFG["GUILD_ID"]))
    # Register the globally-defined commands to this one guild so they appear
    # instantly (global propagation can take up to an hour).
    tree.copy_global_to(guild=guild)
    await tree.sync(guild=guild)
    if not update_presence.is_running():
        update_presence.start()
    if not sync_roles.is_running():
        sync_roles.start()
    if not write_hb.is_running():
        write_hb.start()
    print(f"[token_bot] ready as {client.user} — "
          f"slash commands synced to guild {CFG['GUILD_ID']}")


def main() -> int:
    global CFG
    CFG = load_config()
    client.run(CFG["BOT_TOKEN"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
