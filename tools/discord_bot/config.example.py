"""Discord bot config — copy this file to config.py and fill in your webhook URL.

config.py is gitignored so your webhook URL never lands in git.

Setting up the webhook (Discord side):
  1. Open the Discord channel you want notifications in.
  2. Channel Settings -> Integrations -> Webhooks -> New Webhook.
  3. Name it (e.g. "Legendary Hunter"), copy the Webhook URL.
  4. Paste it into WEBHOOK_URL below.

That's it. The bot uses webhooks (one-way POST) so no bot token,
no permissions intent setup, no Discord application required.
"""

# REQUIRED: Discord webhook URL. Looks like:
#   https://discord.com/api/webhooks/<id>/<token>
WEBHOOK_URL = "https://discord.com/api/webhooks/REPLACE_ME"

# Visual styling for the bot's posts.
BOT_USERNAME   = "Legendary Hunter"
BOT_AVATAR_URL = ""   # optional; leave empty for the channel's default

# ============================================================
# DIGEST SCHEDULES
# ============================================================
# The script is idempotent — run it as often as you want. The
# event-detection path posts whenever something new happens
# (rank-ups, capstones, weekly sweeps). The digest paths only
# post when their cadence window has passed since the last digest.
#
# Run this script via Task Scheduler every 5 minutes for near-real-
# time event posts. Digests will fire on their own schedule.

# Daily digest: fires once per UTC day, after this hour.
DAILY_DIGEST_HOUR_UTC = 8       # 8am UTC = 4am EDT / 1am PDT

# Weekly digest: fires once per ISO week, on this UTC weekday after
# this hour. 0 = Monday ... 6 = Sunday.
WEEKLY_DIGEST_DAY      = 0       # Monday
WEEKLY_DIGEST_HOUR_UTC = 8

# Set DAILY_DIGEST_ENABLED / WEEKLY_DIGEST_ENABLED to False to skip
# entirely. Per-event posts (rank-ups etc.) still fire either way.
DAILY_DIGEST_ENABLED  = True
WEEKLY_DIGEST_ENABLED = True

# ============================================================
# EVENT FILTERS
# ============================================================
# Post only rank-ups for ranks at or above this index. Useful if
# Apprentice/Journeyman noise feels spammy. Set to 1 to post all
# rank-ups; 3 for Veteran+; 5 for Grandmaster only.
MIN_RANK_TO_ANNOUNCE = 2   # Journeyman+

# Don't post per-kill messages (would be very chatty). Kill counts
# only roll up into the daily/weekly digests. Set True only if you
# want every single NM kill to land in Discord.
ANNOUNCE_EVERY_KILL = False

# Broadcast daily-login-streak milestones (30 / 100 / 365 consecutive days)
# to the channel. The high-water streak comes from the in-game daily reward
# system (daily_reward.lua). Set False to keep streaks in-game only.
STREAK_ALERTS_ENABLED = True

# ============================================================
# MENTION / PING CONFIG
# ============================================================
# Discord lets the bot @-ping a role or @here when notable events fire.
# Used to wake up your server's roster for big moments without spamming
# the channel on every Apprentice-tier rank-up.
#
# How to get a Discord role ID:
#   1. In Discord, enable Developer Mode (Settings -> Advanced).
#   2. Server Settings -> Roles -> right-click the role -> Copy Role ID.
#   3. Paste the numeric ID below (quoted as a string).
#
# Leave any value as the empty string ("") to disable that ping. The
# event still posts, just without a mention prefix.

# Mention this role ID when an Apex Hunter achievement fires.
# This is the biggest moment in the system — pings a role is appropriate.
PING_ROLE_ON_APEX = ""           # e.g. "1234567890123456789"

# Mention this role ID when a Trinity Hunter achievement fires.
# Less rare than Apex but still major. Leave blank if Apex-only is enough.
PING_ROLE_ON_TRINITY = ""

# Mention this role ID when any player hits Grandmaster on a single guild.
# Fires four times per Apex achiever total, so optional/quieter.
PING_ROLE_ON_GRANDMASTER = ""

# Use @here instead of (or in addition to) a role ID. @here pings every
# currently-online Discord user in the channel — great for rallying real-
# time attention on big achievements without needing a role set up.
PING_HERE_ON_APEX    = False
PING_HERE_ON_TRINITY = False

# ============================================================
# TIMED HNM SPAWN ALERTS
# ============================================================
# Post when a timed HNM King goes UP (read from the [HNM]<Name> ServerVars,
# the same timers the in-game module and the status page use). Each distinct
# spawn fires exactly once; kills/respawns are tracked silently in state.json.
# HQ land kings are QM-pop (no timer) and are NOT tracked here.
HNM_ALERTS_ENABLED = True

# Optional @-ping when a King spawns. A role ID rallies a hunting role; @here
# pings everyone currently online. Both default off (alerts post without a ping).
PING_ROLE_ON_HNM = ""        # e.g. "1234567890123456789"
PING_HERE_ON_HNM = False

# ============================================================
# PATCH-NOTES CROSS-POST
# ============================================================
# Cross-post new commits from the server repo (D:\server) to the channel, so
# players see updates as you ship them. Subjects are your git commit messages,
# with merge/automated commits filtered out (same filter as the website
# changelog). The first run records the current HEAD as a baseline and posts
# nothing historical — only commits made *after* that show up.
PATCH_NOTES_ENABLED = True

# Cap how many commits one post lists (the rest collapse into "…and N more").
PATCH_NOTES_MAX = 15

# Optional role ID to @-ping on a patch-notes post. Empty = no ping.
PING_ROLE_ON_PATCH = ""

# ============================================================
# TWO-WAY TOKEN BOT  (token_bot.py)  — OPTIONAL, separate from the webhook above
# ============================================================
# Everything above powers discord_bot.py — the one-way webhook *notifier*.
# token_bot.py is a SECOND, optional bot that adds player-facing slash
# commands (/online, /huntrank, /leaderboard, /prestige, /lfg). Unlike the
# webhook notifier it needs a real Discord application + bot token, and it
# runs as a long-lived daemon. See README.md "Two-way slash-command bot".
#
# Leave these as-is if you only want the webhook notifier — the webhook bot
# ignores them, and the token bot is a separate process you start yourself.

# REQUIRED for token_bot.py: the bot token from the Discord Developer Portal
#   (https://discord.com/developers/applications -> your app -> Bot -> Reset
#   Token -> Copy). Keep it secret — config.py is gitignored.
BOT_TOKEN = "REPLACE_ME"

# REQUIRED for token_bot.py: your Discord server (guild) ID, as an integer
# (no quotes). Slash commands are registered to this one guild so they show
# up instantly. Enable Developer Mode (Settings -> Advanced), then right-click
# your server icon -> Copy Server ID.
GUILD_ID = 0

# OPTIONAL for token_bot.py: role ID to ping when someone runs /lfg. Empty
# string = no ping (the LFG call still posts). Right-click a role -> Copy Role ID.
LFG_ROLE_ID = ""

# OPTIONAL for token_bot.py: automatic Discord role sync by in-game rank.
# When enabled, the token bot grants/removes the roles below every ~10 minutes
# for each player who linked their character with /register. It ONLY ever
# touches the roles you list here — other roles are never added or removed.
#
# Requirements on the Discord side:
#   1. Give the bot the "Manage Roles" permission.
#   2. Drag the bot's OWN role ABOVE each role it assigns (Server Settings ->
#      Roles), or Discord refuses the change. No privileged intents are needed —
#      the bot resolves members via the REST API (fetch_member).
#
# Tiers (Hunter's Guild capstones, rarest first):
#   apex        — Apex Hunter: top rank on all four guilds (the rarest)
#   trinity     — Trinity Hunter: top rank on three guilds
#   grandmaster — reached the top rank on at least ONE of the four guilds
# A player keeps every tier they qualify for, so roles stack: map all three and
# an Apex hunter holds apex + trinity + grandmaster. Map only one (e.g. apex) to
# hand out a single elite role. Leave a value "" to skip syncing that tier.
ROLE_SYNC_ENABLED = False
ROLE_SYNC = {
    "apex":        "",   # role ID (string) for Apex hunters
    "trinity":     "",   # role ID for Trinity hunters
    "grandmaster": "",   # role ID for single-guild Grandmasters
}
