"""Full-page owners for the six getting-started pages.

Pages owned (rewritten from scratch on every docgen run — edit THIS module,
never the .md files; hand edits are clobbered by design):

  docs/getting-started/index.md         — section landing page
  docs/getting-started/install.md       — client install steps
  docs/getting-started/connect.md       — server address/ports + launcher setup
  docs/getting-started/first-steps.md   — first 20 minutes walkthrough
  docs/getting-started/troubleshoot.md  — common problems
  docs/getting-started/your-session.md  — the core gameplay loop

Live sources parsed every run:
  tools/docgen/_site.py                          — host/ports (live network.lua wins)
  modules/custom/lua/hunting_league_catalog.lua  — rank 1 NMs, marks/kill, unlock costs
  modules/custom/lua/new_char_starter_marks.lua  — starter Hunt Mark stipend
  modules/custom/lua/daily_login_bonus.lua       — daily login marks
  modules/custom/lua/login_streak.lua            — streak milestone table
  modules/custom/lua/achievements.lua            — kill-count milestone rewards/titles
  modules/custom/commands/expcamp.lua            — EXP camp count
  scripts/commands/unstick.lua                   — self-rescue command (existence)

Rate numbers are emitted as {{setting:...}} tokens; settings_inject resolves
them against the live settings after every generator has run.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen import _site


def _text(repo_root: Path, rel: str, required: bool = True) -> str | None:
    src = resolve_source(repo_root, rel, required=required)
    if src is None:
        return None
    return src.read_text(encoding="utf-8", errors="replace")


def _first_int(pattern: str, text: str, default: int) -> int:
    m = re.search(pattern, text)
    return int(m.group(1)) if m else default


# xi.zone.<CONST> -> friendly name that reads naturally in prose. Mirrors the
# _FRIENDLY map in npc_location_inject (kept small: only the hub zones the warp
# commands actually target). Unknown consts fall back to a title-cased name.
_ZONE_FRIENDLY: dict[str, str] = {
    "ABDHALJS_ISLE_PURGONORGO":  "Purgonorgo Isle",
    "LEAFALLIA":                 "Leafallia",
    "CELENNIA_MEMORIAL_LIBRARY": "the Celennia Memorial Library",
    "GM_HOME":                   "GM Home",
}


def _hub_zone(repo_root: Path) -> str | None:
    """Friendly name of the single zone the hub warp commands land in.

    Reads the live `!hub` / `!lib` / `!leaf` targets so a future hub move can't
    strand this page. Returns the friendly name only when every command shares
    one zone (the current single-hub consolidation); returns None if they
    diverge or none resolve, so the caller can fall back to generic phrasing.
    """
    consts: list[str] = []
    for cmd in ("hub", "lib", "leaf"):
        # Candidate probes: either location may legitimately lack the command.
        text = (_text(repo_root, f"modules/custom/commands/{cmd}.lua", required=False)
                or _text(repo_root, f"scripts/commands/{cmd}.lua", required=False))
        if not text:
            continue
        m = re.search(r"setPos\([^)]*xi\.zone\.(\w+)", text)
        if m:
            consts.append(m.group(1))
    if not consts or len(set(consts)) != 1:
        return None
    const = consts[0]
    return _ZONE_FRIENDLY.get(const, const.replace("_", " ").title())


# ---------------------------------------------------------------------------
# Live facts
# ---------------------------------------------------------------------------

def _facts(repo_root: Path) -> dict | None:
    hl = _text(repo_root, "modules/custom/lua/hunting_league_catalog.lua")
    if hl is None:
        return None  # the walkthrough pages are HL-centric — fail closed

    f: dict = {}
    f["host"], f["dataPort"], f["authPort"], f["viewPort"] = _site.connection(repo_root)
    f["args"] = _site.xiloader_args(repo_root)
    f["discord"] = _site.DISCORD_URL

    # Tiers: [(unlockCost, [(label, points), ...]), ...] in file order.
    tiers: list[tuple[int, list[tuple[str, int]]]] = []
    for block in re.split(r"\bunlockCost\s*=\s*", hl)[1:]:
        cost_m = re.match(r"(\d+)", block)
        nms = re.findall(r"label\s*=\s*'([^']+)'\s*,\s*points\s*=\s*(\d+)", block)
        if cost_m:
            tiers.append((int(cost_m.group(1)), [(n, int(p)) for n, p in nms]))
    f["tierCount"] = len(tiers) or 5
    f["rank1Nms"] = [n for n, _ in tiers[0][1][:3]] if tiers and tiers[0][1] else \
        ["Leaping Lizzy", "Valkurm Emperor", "Tom Tit Tat"]
    f["rank1Pts"] = min((p for _, p in tiers[0][1]), default=5) if tiers else 5
    f["rank2Cost"] = tiers[1][0] if len(tiers) > 1 else 150
    f["topPts"] = min((p for _, p in tiers[-1][1]), default=65) if tiers and tiers[-1][1] else 65

    sm = _text(repo_root, "modules/custom/lua/new_char_starter_marks.lua") or ""
    f["starterMarks"] = _first_int(r"STARTER_MARKS\s*=\s*(\d+)", sm, 25)

    dl = _text(repo_root, "modules/custom/lua/daily_login_bonus.lua") or ""
    f["dailyBonus"] = _first_int(r"DAILY_BONUS\s*=\s*(\d+)", dl, 50)

    ls = _text(repo_root, "modules/custom/lua/login_streak.lua") or ""
    f["streaks"] = [(int(d), int(m)) for d, m in
                    re.findall(r"\{\s*(\d+)\s*,\s*(\d+)\s*,", ls)] or \
                   [(7, 75), (14, 200), (21, 400), (30, 750)]

    # Kill-count achievement milestones, in catalog order: id -> (reward, title).
    ach = _text(repo_root, "modules/custom/lua/achievements.lua") or ""
    f["ach"] = {}
    for aid, reward, title in re.findall(
        r"id\s*=\s*'(\w+)'\s*,\s*reward\s*=\s*(\d+)\s*,\s*announce\s*=\s*\w+\s*,\s*title\s*=\s*'([^']+)'",
        ach,
    ):
        f["ach"][aid] = (int(reward), title)

    # camps table rows look like { '10-25 La Theine Plateau', xi.zone.X, ... }
    ec = _text(repo_root, "modules/custom/commands/expcamp.lua") or ""
    f["expCamps"] = len(re.findall(r"xi\.zone\.\w+", ec))  # 0 -> phrased without a count
    # Level bands: parse the "NN-NN Zone" label so the camp range in the prose
    # follows the table instead of being hand-quoted (it drifted to a stale
    # "Boyahda Tree at 60-75" while camps grew out to 95-99). Each entry is
    # (lowLv, highLv, zoneLabel); low = first row, high = last row.
    camp_rows = re.findall(r"\{\s*'(\d+)-(\d+)\s+([^']+)'", ec)
    f["expLow"] = (int(camp_rows[0][0]), int(camp_rows[0][1]), camp_rows[0][2].strip()) \
        if camp_rows else None
    f["expHigh"] = (int(camp_rows[-1][0]), int(camp_rows[-1][1]), camp_rows[-1][2].strip()) \
        if camp_rows else None

    # Hub zone: where !hub / !lib / !leaf now land (single-hub consolidation).
    f["hubZone"] = _hub_zone(repo_root)

    f["hasUnstick"] = resolve_source(repo_root, "scripts/commands/unstick.lua", required=False) is not None

    # Hub warp command: which of !hub/!gmhome/!leaf/!lib exists (first = canonical,
    # rest = legacy aliases), plus whether !hunt exists. hubZone (above) says where
    # they land; these say what to type.
    def _cmd_exists(name: str) -> bool:
        return (resolve_source(repo_root, f"scripts/commands/{name}.lua", required=False) is not None
                or resolve_source(repo_root, f"modules/custom/commands/{name}.lua", required=False) is not None)

    hub_present = [c for c in ("hub", "gmhome", "leaf", "lib") if _cmd_exists(c)]
    f["hubCmd"] = hub_present[0] if hub_present else "hub"
    f["hubAliases"] = hub_present[1:]
    f["hasHunt"] = _cmd_exists("hunt")
    return f


# ---------------------------------------------------------------------------
# Page templates (single editing point for the narrative)
# ---------------------------------------------------------------------------

def _page_index(f: dict) -> str:
    return f"""\
# Getting Started

![Gateway](../assets/emblems/getting-started.svg){{ .lgnd-emblem }}

New here? Here's the path from zero to playing:

1. **[Install the Client](install.md)** — get a working FFXI client and launcher on your machine.
2. **[Connect to the Server](connect.md)** — point the client at the Relaunch server.
3. **[First Steps](first-steps.md)** — once you're in, this walks you through your first hour: leveling to 99, grabbing starter gear, and unlocking the custom systems.
4. **[Your First Session](your-session.md)** — setup done? This is the core gameplay loop and the rewards that keep you coming back.
5. **[Troubleshooting](troubleshoot.md)** — stuck on a connection, version, or login error? Start here.

If you've played retail FFXI before, the client setup is the same — only the server you point at changes.
"""


def _page_install(f: dict) -> str:
    return f"""\
# Install the Client

You need a working **retail FFXI client** plus a third-party launcher (Ashita or Windower) to play on the Relaunch server. If you've already got the game running for retail or another private server, you have everything you need — skip ahead to [Connect to the Server](connect.md).

## Requirements

- **A retail FFXI client** — the Steam edition or an original PlayOnline install both work.
- **A launcher** — [Ashita](https://www.ashitaxi.com/) (recommended) or [Windower](https://www.windower.net/). Either one points the client at our server; pick whichever you prefer.

## Steps

1. **Install FFXI.** If you don't already have the game, the official [Windows client installer](https://www.playonline.com/ff11us/download/media/install_win.html) is the easiest way to get it.
2. **Run the PlayOnline updater** and let it finish completely. The client has to be fully patched before it will connect.
3. **Install Ashita or Windower** and follow that launcher's own first-time setup guide.
4. **Get the loader** (below), then **continue to [Connect to the Server](connect.md)** to point the launcher at the Relaunch server.

## Get the loader

Private servers use **`xiloader.exe`** in place of the retail PlayOnline login. Grab it from the **Discord server** (pinned in the getting-started channel) and drop it somewhere convenient — your launcher profile points at it during [Connect](connect.md).

!!! tip "Hitting a snag?"
    Connection failures and version-mismatch errors are almost always a patching or config issue. The [Troubleshooting](troubleshoot.md) page covers the common ones.
"""


def _page_connect(f: dict) -> str:
    return f"""\
# Connect to the Server

## Server details

| | |
|---|---|
| **Server IP** | `{f['host']}` |
| **Data port** | `{f['dataPort']}` |
| **Auth port** | `{f['authPort']}` |
| **View port** | `{f['viewPort']}` |

---

## Windower

Windower 4 has no "Login Server" field for private servers. Instead, you point a profile at **`xiloader.exe`** (the FJB loader) and pass the server address and ports as launch arguments.

1. Make sure **`xiloader.exe`** is in your FFXI folder, next to `pol.exe` (usually `…\\SquareEnix\\PlayOnlineViewer\\`). See [Get the loader](install.md#get-the-loader).
2. Open the **Windower 4** launcher and create or edit a profile.
3. Set **Executable** to `xiloader.exe` (use the full path if Windower can't find it).
4. Set **Arguments** to:
   ```
   {f['args']}
   ```
5. Save and launch.

Prefer to edit `Windower4/settings/settings.xml` by hand? The profile looks like this:

```xml
<profile name="FJBRelaunch">
  <executable>xiloader.exe</executable>
  <args>{f['args']}</args>
</profile>
```

!!! tip "Skip the login prompt"
    Add your credentials to log in automatically:
    ```
    {f['args']} --user YOURNAME --pass YOURPASSWORD
    ```

---

## Ashita

1. Open the **Ashita** launcher.
2. Select your profile (or create a new one) and click **Edit**.
3. Under **Login Server**, enter `{f['host']}`.
4. Set the **Data port** to `{f['dataPort']}`, **Auth port** to `{f['authPort']}`, and **View port** to `{f['viewPort']}`.
5. Save the profile and launch.

!!! tip
    If Ashita uses a `boot.ini` or boot script, set `{f['args']}`.

---

## Troubleshooting

**"Unable to connect" / connection timeout**
: Verify all four values (IP + 3 ports) match the table above. If the server was just restarted, wait 30 seconds and try again.

**"Version mismatch" error**
: Your client needs to be the current retail version. Run the PlayOnline updater to patch up, then try again.

**Stuck on the login screen / no response**
: Check the [Discord]({f['discord']}) #server-status channel — the server may be down for maintenance.
"""


def _page_first_steps(f: dict) -> str:
    nm1, nm2, nm3 = (f["rank1Nms"] + ["?", "?", "?"])[:3]
    hub = f["hubZone"] or "the server hub"
    camps = (f"one of {f['expCamps']} level-banded EXP camps"
             if f["expCamps"] else "a level-banded EXP camp")
    # Range phrase follows the camps table: "<low zone> early, up through
    # <high zone> at <high band>." Falls back to a bare sentence if unparsed.
    if f["expLow"] and f["expHigh"]:
        lo_zone = f["expLow"][2]
        hi_lo, hi_hi, hi_zone = f["expHigh"]
        camp_range = f" — {lo_zone} early, up through {hi_zone} at {hi_lo}–{hi_hi}"
    else:
        camp_range = ""
    return f"""\
# First Steps

Welcome to the Relaunch server. You've got the client running, you're in-game — now what?

This page walks you through the first 15–20 minutes: getting your character set up, picking up starter gear, and launching the core progression path. Follow these steps in order and you won't miss anything important.

!!! note "Not in-game yet?"
    Get connected first: [install the client](install.md) — including the **`xiloader.exe`** loader — then follow the [Connect to the Server](connect.md) page to configure your launcher with the correct IP and ports.

---

## 1. Orient yourself — one island hub

Every custom NPC lives on a single island plaza — **{hub}**. Type **`!hub`** to warp there any time.

- **Getting-around & set-up** — Home Point crystal, Warpman, Survival Guide.
- **Economy** — Gil Exchange, Sparks Exchange, Race Changer, Title Broker, Mystery Mog, Cosmetic Shop; the Casino; the Daily & Hunt boards; Unity and Chocobo Derby.
- **Endgame** — Apex Trials, Prime Armory, Relic Forge, Colosseum, Endless Tower, the Gauntlet, Infamy / HTBF / Voidwatch vendors, Augment Moogle & Sage, the mastery trainers, Cross-Job Trainers, and the combat **Test Dummy** for DPS testing.

The NPCs are spaced out across the plaza so a crowd can shop at once. The old `!leaf`, `!lib`, and `!gmhome` commands all still work — they now land you on {hub} too.

---

## 2. Your character is already set up

There's no setup NPC to visit on the Relaunch server — every new character is fully provisioned **the moment it's created**. Before you take a single step, you already have:

| What you get | Details |
|---|---|
| **Weapon skills & spells** | Every weapon skill and every job-appropriate spell, granted automatically |
| **Capped skills** | All combat and magic skills capped to your level |
| **Trusts** | Your full trust roster |
| **Key items** | The complete set of ~4,000 key items — zone access, teleports, and everything else key items gate |
| **Missions & rank** | Every story mission completed (all nations + RoZ/CoP/ToAU/WotG/SoA/RoV); nation rank 10 |
| **Maps & travel** | All maps, outpost warps (including Tu'Lia and Tavnazia), homepoints, and survival guides |
| **Storage** | Full Mog Wardrobes |
| **Pets** | Pet attachments (for the relevant jobs) |
| **Starter gear** | A one-time starter gear kit — enough to survive your first few fights and get the Hunting League rolling |

You're also handed **{f['starterMarks']} Hunt Marks** as a starter stipend — the currency everything here runs on.

!!! note
    None of this requires talking to anyone. You don't need to track down a Character Upgrader, Key Item Moogle, Mission Moogle, or Gear Moogle — it's all done for you at creation. Just play.

---

## 3. Level up to 99

You start at level **1** — but with every job and subjob already unlocked and **{{{{setting:map.EXP_RATE}}}}× mob EXP** (plus {{{{setting:main.EXP_RATE:int}}}}× from books & RoE), the climb is hours, not weeks.

- Type **`!expcamp`** to warp straight to {camps}{camp_range}. Run `!expcamp` on its own to list the camps, then `!expcamp 4` to warp to one.
- Or dive into the **Hunting League** below right away: the Rank I NMs are low-level, so you earn EXP *and* Hunt Marks at the same time.

---

## 4. Head to Escha ZiTah — start the Hunting League

Once your character is set up, the next stop is the server's core progression system: **the Hunting League**.

```
!hunt
```

This command warps you directly to **Escha ZiTah** and drops you next to the Hunt Hub and Spawner NPCs.

!!! warning "Don't skip this step"
    Without `!hunt`, Escha ZiTah requires mid-Seekers of Adoulin mission progress to access. Use the command. It's always available.

### What is the Hunting League?

The Hunting League is a custom rank-based NM hunting system with {f['tierCount']} ranks. You kill NMs, earn **Hunt Marks**, spend marks to unlock the next rank, and buy gear from the reward shop.

It's the primary path to endgame gear and the main thing to do on the Relaunch server. For full details — ranks, NMs, rewards, recommended order — see the **[Hunting League page](../progression/index.md)**.

### Quick start at Escha ZiTah

1. Talk to **Hunt: Hub** to see your current rank and marks.
2. Talk to **Hunt: Spawner** to pop a Rank I NM ({nm1}, {nm2}, or {nm3}).
3. Kill the NM. Each kill pays **{f['rank1Pts']} Hunt Marks**.
4. Repeat until you have {f['rank2Cost']} marks, then return to Hunt: Hub to unlock Rank II.

---

## Summary

| Step | Action |
|---|---|
| 1 | `!hub` — warp to {hub}, the single custom-NPC hub |
| 2 | Nothing to do — your character is fully set up at creation (weapon skills, spells, trusts, capped skills, key items, missions, maps, warps, wardrobes, starter gear) |
| 3 | `!expcamp` — warp to a level-banded camp and level to 99 ({{{{setting:map.EXP_RATE}}}}× mob EXP) |
| 4 | `!hunt` — warp to Escha ZiTah and start the Hunting League |

---

## Questions? Join Discord

If something isn't working, you're not sure what to do next, or you just want to find people to group with — hop into the **[Discord server]({f['discord']})**. The community is active and happy to help new players get going.
"""


def _page_troubleshoot(f: dict) -> str:
    hub = f["hubCmd"]
    hub_zone = f["hubZone"] or "the server hub"
    warp_examples = f"`!{hub}`" + (", `!hunt`" if f["hasHunt"] else "") + ", etc."
    alias_note = ""
    if f["hubAliases"]:
        aliases = ", ".join(f"`!{a}`" for a in f["hubAliases"])
        alias_note = f" {aliases} are legacy aliases that land in the same place."
    unstick = ""
    if f["hasUnstick"]:
        unstick = """
!!! tip
    If you're truly looped with no way to reach a zone line, try typing `!unstick` in chat. This is a self-rescue command that clears stuck event/sequence state on the spot.
"""
    return f"""\
# Troubleshooting

Common problems and how to fix them. If your issue isn't listed here, ask in Discord — the community and GMs are active and can usually sort things out quickly.

---

## Can't Connect to the Server

1. **Check Discord `#server-status`** first. If the server is down for maintenance or hit an unexpected crash, it'll be posted there before anywhere else.
2. **Verify your connection settings.** Make sure your client is pointing at the correct IP and port — see the [Connect to Server](connect.md) page for the exact values.
3. **Check your firewall / antivirus.** Overly aggressive security software occasionally blocks game client connections. Try temporarily disabling it to isolate the issue.

---

## Character Stuck in a Cutscene

The server has an **Auto-Unstick watchdog** that clears stuck event state on zone-in.

**Fix:**

1. Zone out — walk to a zone line, or use any warp command ({warp_examples}).
2. Zone back in.
3. The watchdog fires on zone-in and should release the stuck state.

If one zone cycle doesn't fix it, **log out and back in** — that's a full zone-in cycle and always triggers the watchdog.
{unstick}
---

## Lost an Item / Died to a Bug

If something was lost due to a server bug (not player error), a GM can investigate and restore it.

**What to do:**

1. Note your **character name**, **what was lost**, and **roughly when it happened** (within the last hour is ideal — log timestamps help a lot).
2. Head to Discord and open a ticket or post in the support channel.
3. A GM will follow up when they're available.

!!! warning "Be specific"
    "I lost my item" is hard to act on. "I lost my Ridill around 9pm EST — I was in Dragon's Aery when the server lagged" is actionable. The more detail you give, the faster it gets resolved.

---

## Hub Warp (`!{hub}`) Not Working

`!{hub}` warps you to {hub_zone}, where every custom NPC lives.{alias_note} If a hub warp isn't working:

- **Nothing happens / an error in the log.** `!{hub}` is available to every player — if it isn't firing at all, check the chat log for a message (usually a typo, or you're somewhere it's blocked).
- **Command is on cooldown.** Some warp commands have a short cooldown between uses. Wait a few seconds and try again.
- **You're in a zone that blocks it.** A small number of instanced areas prevent teleport commands from firing. Zone out first, then use `!{hub}`.

Still not working? Ask in Discord.

---

## Lag / Rubber-Banding

The server runs at **{f['host']}**. Performance issues can come from a few sources:

- **Server load.** If multiple players are reporting rubber-banding at the same time, the server is likely under load. Check `#server-status` in Discord.
- **Your connection.** If it's only you, run a quick latency check to the server IP. High packet loss between you and the server will cause rubber-banding even if the server itself is healthy.
- **Zone population.** Heavily populated zones with lots of AOE and particle effects can stress client rendering. Try a less busy area to isolate the issue.

In most cases, lag during peak hours resolves on its own. If it's persistent and only happening to you, mention it in Discord with your approximate location and what time it started.

---

## Version Mismatch Error

If you get a version mismatch error on login:

1. Run the **PlayOnline updater** and let it fully complete.
2. Restart the client after updating.
3. Try connecting again.

If the updater says you're up to date but the error persists, the server may have been updated while your client wasn't patched yet. Check `#server-status` in Discord for any recent update announcements.

---

## Something Else

If your problem isn't covered here:

1. Check the [FAQ](../community/faq.md).
2. Ask in **Discord** — describe what happened, what you expected, and what you saw instead.
"""


def _page_your_session(f: dict) -> str:
    nm1, nm2, nm3 = (f["rank1Nms"] + ["?", "?", "?"])[:3]
    first = f["ach"].get("FIRST_HUNT", (50, "First Hunt"))
    tenth = f["ach"].get("TENTH_HUNT", (100, "Ten Hunts In"))
    cent = f["ach"].get("CENTURY", (300, "Desert Hunter"))
    mill = f["ach"].get("MILLENNIUM", (1000, "Hero Among Heroes"))
    streak_rows = "\n".join(
        f"| {d} days logged in a row | **+{m}** Hunt Marks |" for d, m in f["streaks"]
    )
    return f"""\
# Your First Session

You've finished [First Steps](first-steps.md) — your character is set up, you grabbed starter gear, and `!hunt` dropped you at Escha ZiTah. This page is what comes next: the actual rhythm of playing on the Relaunch server, and the systems that quietly reward you just for showing up.

If you remember only one thing: **almost everything on the Relaunch server runs on Hunt Marks.** You earn them by killing NMs in the Hunting League, and you spend them on seals, gear, and rank unlocks. Learn that one loop and the rest falls into place.

---

## The core loop

```
!buff        →  sustain (Refresh / Regen / Regain)
pop an NM    →  Hunt: Spawner
kill it     →  earn Hunt Marks
spend marks  →  seals, gear, next rank
rank up      →  repeat — tougher NMs pay more
```

That's the whole game in five beats. Everything else on this page just makes the loop faster or more rewarding.

---

## Your first 30 minutes at Escha ZiTah

You arrived via `!hunt`. Before you swing at anything:

```
!buff
```

This grants Refresh, Regen, Regain, and your zone's regional buff (Signet / Sanction / Sigil / Ionis) — free sustain that makes solo hunting comfortable. Recast it whenever it wears off or you change zones.

Then work the loop using the two NPCs standing side-by-side where you landed:

1. **Talk to Hunt: Hub** — your rank board. It shows your current Hunting League rank, your Hunt Marks balance, and the reward shop. (Quick balance check anytime with `!marks`.)
2. **Talk to Hunt: Spawner** — pop a Rank I NM: **{nm1}**, **{nm2}**, or **{nm3}**. It appears right in front of you — no map navigation, no cooldown.
3. **Kill it.** You must land the killing blow (or be credited as the killer). Each Rank I kill pays **{f['rank1Pts']} Hunt Marks**, and your very first kill also fires the **{first[1]}** achievement for a bonus **+{first[0]}**.
4. **Spend at the Hub.** You were handed **{f['starterMarks']} Hunt Marks** at character creation — a head start. Convert some into **Seals** at the reward shop and take them to the Armor & Weapons vendors at Escha ZiTah for your first real upgrade. (Full breakdown: [Gear Vendors](../progression/gear-vendors.md).)
5. **Keep popping.** Rack up marks, return to **Hunt: Hub**, and unlock **Rank II** for **{f['rank2Cost']} marks**. Each rank opens a tougher NM roster that pays more per kill — {f['rank1Pts']} at Rank I climbing to **{f['topPts']}** at Rank {f['tierCount']}.

Not sure what you need for the next rank? Ask the game directly:

```
!tier
```

It shows your current tier, the NMs available to you, and exactly what's required to rank up. For the full ladder — all {f['tierCount']} ranks, every NM, the reward shop — see the **[Hunting League page](../progression/index.md)**.

!!! warning "Don't underestimate the starters"
    The Rank I NMs are buffed well beyond their retail stats — they are a real fight on fresh gear. That's what your starter marks and `!buff` are for.

---

## Rewards just for showing up

The Relaunch server front-loads its generosity. You don't have to grind for hours to feel progress — Hunt Marks land in your lap for logging in and for hitting milestones:

| When | Reward |
|---|---|
| Create your character | **+{f['starterMarks']}** Hunt Marks (starter stipend) |
| First login each day (UTC) | **+{f['dailyBonus']}** Hunt Marks |
{streak_rows}
| Your 1st NM kill | **+{first[0]}** — *{first[1]}* |
| Your 10th NM kill | **+{tenth[0]}** — *{tenth[1]}* |
| Your 100th NM kill | **+{cent[0]}** — *{cent[1]}* |
| Your 1,000th NM kill | **+{mill[0]}** — *{mill[1]}* |

Login streaks reset if you skip a UTC day, so a quick daily login keeps them alive. There are plenty more milestones beyond the ones above — first kill at each tier, lifetime-marks landmarks, Infamy hauls — and you can see the whole list, earned and unearned, with:

```
!achievements
```

!!! tip "Titles are yours to display"
    Achievement titles unlock for display without being forced on. Pick when to show one with `/title`.

---

## The weekly rhythm

Once the core loop clicks, two rotating boards give you a reason to come back beyond raw marks:

- **Weekly Hunt Board** — five objectives rolled fresh each week. Complete them for bonus marks and a lifetime "Weekly Hunter" sweep counter. Track it with `!weekly`. (Details: [Weekly Hunt Board](../progression/weekly-hunts.md).)
- **Featured Hunts** — one NM per tier is featured each week and pays **2× base marks** on your first kill of the week. See them with `!featured`.
- **Daily Board** — lighter objectives that refresh every daily reset.

Two commands roll up everything time-sensitive:

```
!week     # your weekly objectives at a glance
!time     # server time + hours to daily reset, days to weekly reset
```

Resets land **daily at 00:00 UTC** and **weekly on Monday 00:00 UTC**.

---

## Commands worth memorizing

You don't need to learn every command — these are the ones a new hunter actually reaches for:

| Command | What it does |
|---|---|
| `!hunt` | Warp to Escha ZiTah (the Hunting League) |
| `!buff` | Refresh / Regen / Regain + your regional buff |
| `!marks` | Hunt Marks balance — spendable and lifetime |
| `!tier` | Current tier + exactly what's needed to rank up |
| `!progress` | One-screen summary across every system |
| `!nms` | NM Encyclopedia — what you've killed, what's left |
| `!achievements` | Every milestone, earned and unearned |
| `!week` / `!weekly` | Weekly objectives and board progress |
| `!featured` | This week's 2× featured-hunt bonuses |
| `!lfg` | Broadcast "looking for group" server-wide |
| `!who` | Who's online, ranked by tier |
| `!help` | The full custom-command list |

Forgot one mid-session? `!help` prints them all. The complete reference lives on the **[Player Commands](../reference/commands.md)** page.

---

## Where you're headed

The Hunting League is the spine, but it isn't the whole skeleton. As you climb, these open up:

- **[Ascension (Prestige)](../progression/prestige.md)** — hit the top HL rank on a job, then reset it for permanent per-job bonuses.
- **[Gear Guide](../progression/gear-guide.md)** — where your marks are best spent as you gear up.
- **[HNM Kings](../progression/hnm.md)** and the **[Hunter's Guild](../progression/hunters-guild.md)** — the endgame loops beyond Escha ZiTah.

To see your own trajectory, your character gets a public profile with a **personalized "recommended next step."** Browse the **[Player Profiles](../community/players/index.md)** list and click your name — it appears after your first stats sync.

---

## Stuck or solo? Join Discord

The fastest way to find a group, ask a question, or report something broken is the **[Discord server]({f['discord']})**. Use `!lfg` in-game to ping for a group, and check the live **[Server Status](../community/status.md)** page to see who's on before you log in.

Welcome to the hunt.
"""


# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    f = _facts(repo_root)
    if f is None:
        print("[getting_started_pages] skip: hunting_league_catalog.lua not found")
        return

    gs = docs_dir / "getting-started"
    gs.mkdir(parents=True, exist_ok=True)
    pages = [
        ("index.md",        _page_index(f)),
        ("install.md",      _page_install(f)),
        ("connect.md",      _page_connect(f)),
        ("first-steps.md",  _page_first_steps(f)),
        ("troubleshoot.md", _page_troubleshoot(f)),
        ("your-session.md", _page_your_session(f)),
    ]
    for name, content in pages:
        (gs / name).write_text(content, encoding="utf-8")
    print(f"[getting_started_pages] wrote {len(pages)} pages "
          f"(host={f['host']}:{f['dataPort']}, hub={f['hubZone']}, "
          f"starterMarks={f['starterMarks']}, daily={f['dailyBonus']}, "
          f"rank2Cost={f['rank2Cost']}, camps={f['expCamps']})")
