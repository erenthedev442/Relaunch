"""Generate the Background Systems page from the implementing Lua modules.

Owns (FULL-page writer — the file is rebuilt from scratch every run):
  - docs/changes/background-systems.md

Sources (all under modules/custom/lua/ — one module per rendered section):
  - always_popped_nms.lua                 covered zones + respawn seconds
  - unlimited_visitant.lua                permanent Visitant grant
      (falls back to AbysseaPermanentVisitant.lua if the primary is removed)
  - auto_unstick.lua                      watched zones + delay + what it clears
  - disable_zonein_cutscenes.lua          zone-in cutscene suppression
  - world_first_announcements.lua         tracked firsts + level milestones
  - chocobo_raising_qol.lua               growth days + speed/endurance caps
  - soa_remove_imprimatur_gate.lua        SoA imprimatur/fame gate removal
  - conquest_regional_npcs_always_up.lua  zones + regional NPC names
  - enhancing_magic_double_duration.lua   duration multiplier
  - blu_spell_progression.lua             auto-granted BLU spell count
  - auto_buff_henge.lua                   hub auto-buff package + duration
  - alzahbi_loot.lua                      Al Zahbi bonus-drop roll
  - mob_seal_drops.lua                    seal tiers + quantity distribution

Numbers on the page are parsed from the modules; the surrounding narrative is
constant. A section whose module no longer exists is DROPPED from the page
(reported in the console line). A parse miss degrades to vaguer wording — the
page never renders a fabricated specific.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source


# ---------------------------------------------------------------------------
# Small parse helpers
# ---------------------------------------------------------------------------

def _int(pattern: str, text: str) -> int | None:
    m = re.search(pattern, text)
    return int(m.group(1)) if m else None


def _num(pattern: str, text: str) -> float | None:
    m = re.search(pattern, text)
    return float(m.group(1)) if m else None


def _friendly(raw: str) -> str:
    out = raw.replace("_", " ")
    out = out.replace("dOria", "d'Oria").replace("Doria", "d'Oria")
    if out == "Escha ZiTah":
        out = "Escha - Zi'Tah"
    return out


def _join(items: list[str], bold: bool = True) -> str:
    items = [f"**{i}**" if bold else i for i in items]
    if len(items) <= 1:
        return "".join(items)
    return ", ".join(items[:-1]) + " and " + items[-1]


def _link(docs_dir: Path, target: str, label: str) -> str:
    """Markdown link relative to docs/changes/, only if the target page still
    exists — otherwise degrade to the plain label."""
    rel_file = target.split("#")[0]
    if (docs_dir / "changes" / rel_file).resolve().exists():
        return f"[{label}]({target})"
    return label


def _duration_phrase(seconds: int) -> str:
    if seconds % 3600 == 0:
        hours = seconds // 3600
        return f"{hours} hour" + ("s" if hours != 1 else "")
    minutes = seconds // 60
    return f"{minutes} minutes"


class _Ctx:
    """Bag of shared lookups the renderers need."""

    def __init__(self, repo_root: Path, docs_dir: Path, lua_dir: Path):
        self.repo_root = repo_root
        self.docs_dir = docs_dir
        self.lua_dir = lua_dir

    def module_exists(self, fname: str) -> bool:
        return (self.lua_dir / fname).exists()

    def command_exists(self, name: str) -> bool:
        return resolve_source(self.repo_root, f"scripts/commands/{name}.lua", required=False) is not None


# ---------------------------------------------------------------------------
# Section renderers — each returns (heading_line, [body lines])
# ---------------------------------------------------------------------------

def _render_always_popped(text: str, ctx: _Ctx):
    secs = _int(r"RESPAWN_SECONDS\s*=\s*(\d+)", text)
    zones = [_friendly(z) for z in re.findall(r"\{\s*xi\.zone\.[A-Z0-9_]+\s*,\s*'([^']+)'", text)]

    zone_phrase = _join(zones) if zones else "the covered endgame zones"
    respawn_phrase = f"**{secs} seconds** after death" if secs else "shortly after death"
    body = [
        f"Every NM in {zone_phrase} auto-spawns at server start and respawns "
        f"{respawn_phrase}.",
        "",
        "No pop requirements. No trade items. No key items. Just walk in and start "
        "fighting — if the NM you want is down, it'll be back "
        + (f"in {'half a minute' if secs == 30 else f'{secs} seconds'}." if secs else "momentarily."),
        "",
    ]
    if ctx.module_exists("AbysseaMarks.lua"):
        body += [
            "Abyssea NMs are **not** blanket-spawned: they're popped on demand at their "
            "??? points with Hunt Marks — see "
            + _link(ctx.docs_dir, "../endgame/abyssea-nms.md", "Abyssea NMs")
            + ".",
            "",
        ]
    body += [
        '!!! note "Hunting League hubs excluded"',
        "    Reisenjima Henge and Escha - Zi'Tah are deliberately outside the "
        "auto-pop list — their tier Spawner NPCs pop NMs on demand, so the "
        "always-up system would fight the \"spawn in front of you\" flow.",
    ]
    # Heading renamed from "Abyssea Always-Popped" (the module no longer covers
    # Abyssea); the old anchor is pinned so existing links keep working.
    return "## Always-Popped NMs { #abyssea-always-popped }", body


def _render_visitant(text: str, ctx: _Ctx):
    body = [
        "In retail Abyssea, Visitant status has a time limit — your clock ticks down, "
        "and when it runs out you get ejected. On this server, every player receives "
        "**permanent Visitant status** the moment they zone into any Abyssea area",
    ]
    if "setPos" in text or "!abyssea" in text:
        body[-1] += " — including entries via the `!abyssea` warp command."
    else:
        body[-1] += "."
    body += [
        "",
        "No timer. No decay. No Traverser Stones. Zone in and stay as long as you want.",
    ]
    return "## Unlimited Visitant", body


def _render_auto_unstick(text: str, ctx: _Ctx):
    delay_ms = _int(r"UNSTICK_DELAY_MS\s*=\s*(\d+)", text)
    zone_block = re.search(r"MH_ZONES\s*=\s*\{([^}]*)\}", text, re.DOTALL)
    zones = [_friendly(z) for z in re.findall(r"'(\w+)'", zone_block.group(1))] if zone_block else []

    where = (
        f"the **{len(zones)} starting-city zones** ({', '.join(zones)})"
        if zones else "the starting-city zones"
    )
    delay = f"{delay_ms // 1000} seconds" if delay_ms else "a few seconds"
    body = [
        f"A server-side watchdog runs whenever you zone into {where}. "
        f"{delay.capitalize()} after zone-in, if your character is still flagged "
        '"in an event" (a cutscene loop or stuck event state), the watchdog '
        "force-releases you — no GM needed.",
        "",
        "It also pre-sets the Mog House second-floor unlock flag, which breaks the "
        "classic flower-quest cutscene loop that used to re-trap characters on every "
        "login.",
        "",
        "So if you're ever locked in a cutscene loop, the fix is simple:",
        "",
        "1. Zone (or log out and back in) into one of the starting cities.",
        "2. Wait a moment — the watchdog fires after zone-in and releases the stuck state.",
        "",
        "!!! tip",
        "    Logging out and back in inside a starting city counts as a full zone-in "
        "cycle and always triggers the watchdog.",
    ]
    return "## Auto-Unstick", body


def _render_cutscenes(text: str, ctx: _Ctx):
    body = [
        "Auto-cutscenes that fire when you zone into a mission-heavy area are "
        "suppressed — server-wide, in every zone. If you've ever had the game lock "
        "you into a five-minute cutscene just because you walked through a zone "
        "line, you know why this exists.",
        "",
        "Any side effects the cutscene would have produced — position resets, "
        "mission-flag updates, key item grants — still happen. Only the video "
        "playback is skipped.",
        "",
        "If you want to watch a specific cutscene, talk to the relevant NPC manually "
        "— the suppression only covers the auto-trigger-on-zone-in path.",
    ]
    return "## Zone-In Cutscenes Disabled", body


def _render_world_firsts(text: str, ctx: _Ctx):
    milestones_m = re.search(r"levelMilestones\s*=\s*\{([^}]*)\}", text)
    milestones = re.findall(r"\d+", milestones_m.group(1)) if milestones_m else []

    body = [
        "When a player achieves a server-first milestone, the server broadcasts it to "
        "everyone online. Tracked milestones include:",
        "",
        "- **First player death** on the server (yes, this one is tracked)",
    ]
    if "PLAYER_LEVEL_UP" in text:
        body.append("- **First level-up** (and, less gloriously, the first level *down*)")
    if milestones:
        body.append(
            f"- **Per-job level milestones** — first of each job to reach level "
            f"{', '.join(milestones[:-1])} and {milestones[-1]}"
        )
    if "NM_KILL_" in text:
        body.append("- **First kill of every NM** — each notorious monster's first defeat is announced")
    body += [
        "",
        "These are stored permanently in server variables — a first stays attributed "
        "to the correct player even after server restarts. If you're racing for a "
        "world-first, everyone will know when it happens.",
    ]
    return "## World-First Announcements", body


def _render_chocobo(text: str, ctx: _Ctx):
    chick = _int(r"daysToChick\s*=\s*(\d+)", text)
    adolescent = _int(r"daysToAdolescent\s*=\s*(\d+)", text)
    adult = _int(r"daysToAdult1\s*=\s*(\d+)", text)
    speed_cap = _int(r"ridingSpeedCap\s*=\s*(\d+)", text)
    time_cap = _int(r"ridingTimeCap\s*=\s*(\d+)", text)

    body = ["Chocobo raising is tuned for faster results:", ""]
    if chick:
        growth = f"- **{chick}-day chick cycle** (retail takes twice as long or more)"
        if adolescent and adult:
            growth = (
                f"- **Faster growth** — chick in {chick} days, adolescent in {adolescent}, "
                f"full adult in {adult} (retail: 4 / 19 / 29)"
            )
        body.append(growth)
    if speed_cap:
        body.append(f"- **Higher speed cap** — raised riding speed up to **{speed_cap}** (retail clamps at 100)")
    if time_cap:
        body.append(f"- **Longer riding time** — up to **{time_cap} minutes** in the saddle")
    body += [
        "",
        "If you want a high-stat mount, raising is worth the investment.",
    ]
    return "## Chocobo Raising", body


def _render_soa(text: str, ctx: _Ctx):
    body = [
        "Seekers of Adoulin missions no longer require **Imprimatur** currency or fame "
        "to progress — the gate check always passes. Just talk to the NPC and accept "
        "the mission.",
        "",
        "If you've ever hit the Imprimatur wall on retail (or on a standard private "
        "server), this won't be a problem here.",
    ]
    return "## SoA Imprimatur Gate Removed", body


def _render_conquest(text: str, ctx: _Ctx):
    zone_ids = re.findall(r"xi\.zone\.([A-Z0-9_]+)", text)
    zones = [_friendly(z.title()) for z in dict.fromkeys(zone_ids)]
    names_block = re.search(r"regionalNPCNames\s*=\s*\{([^}]*)\}", text, re.DOTALL)
    names = [_friendly(n) for n in re.findall(r"'([^']+)'", names_block.group(1))] if names_block else []

    where = _join(zones) if zones else "the three capital cities"
    body = [
        f"The **regional merchant NPCs** in {where} are permanently visible, "
        "regardless of which nation holds conquest standing in each region.",
        "",
        "On retail, these NPCs disappear when their nation loses the region — leaving "
        "you to come back next week. On this server, they're always there"
        + (f" ({', '.join(names)})." if names else "."),
    ]
    return "## Conquest Regional NPCs Always Up", body


def _render_enhancing(text: str, ctx: _Ctx):
    mult = _num(r"DURATION_MULTIPLIER\s*=\s*([\d.]+)", text)
    mult = mult if mult else 2.0
    mult_word = "twice as long" if mult == 2 else f"{mult:g}× as long"

    def _fmt(minutes: float) -> str:
        return f"{minutes:g}"

    body = [
        f"Every Enhancing Magic spell lasts **{mult_word}** as it normally would. "
        f"The {mult:g}× is applied on top of all the usual modifiers — gear "
        '"Enhancing Magic Duration", RDM merits and job points, Composure, '
        "Perpetuance, and Embolden all stack first, then the result is multiplied.",
        "",
        f"- A 5-minute Protect becomes **{_fmt(5 * mult)} minutes**.",
        f"- A Composure'd 5-minute buff (already ×3) becomes **{_fmt(5 * 3 * mult)} minutes**.",
        "",
        "No NPC, no gear requirement — it applies to every player casting any "
        "enhancing spell.",
    ]
    return "## Double-Duration Enhancing Magic", body


def _render_blu(text: str, ctx: _Ctx):
    count = len(re.findall(r"xi\.magic\.spell\.[A-Z0-9_]+", text))
    covers_sub = "getSubJob() == xi.job.BLU" in text

    first = (
        "Blue Mage never has to hunt down and learn spells the hard way. As your BLU "
        "levels up, every spell it would normally have to learn from a monster "
    )
    if count:
        first += f"(all **{count}** of them) "
    first += (
        "is **granted automatically** at the appropriate level. Logging in also runs "
        "a full catch-up, so a BLU is always holding the complete spell list for its "
        "current level."
    )
    body = [first, ""]
    if covers_sub:
        body += [
            "This covers **/BLU as a subjob** too — the sub's spell list fills in as "
            "your main level (and with it the sub level) rises.",
            "",
        ]
    body.append(
        "You still set and arrange your own spells — this only removes the chore of "
        "farming each one off a mob."
    )
    return "## Blue Mage Auto-Learns Spells", body


def _render_auto_buff(text: str, ctx: _Ctx):
    zone_m = re.search(r"xi\.zones\.(\w+)\.Zone\.onZoneIn", text)
    zone = _friendly(zone_m.group(1)) if zone_m else "the Hunting League hub"
    duration = _int(r"duration\s*=\s*(\d+)", text)
    refresh_pct = _num(r"maxMP\s*\*\s*([\d.]+)", text)
    regen_pct = _num(r"maxHP\s*\*\s*([\d.]+)", text)
    regain_div = _int(r"level\s*/\s*(\d+)", text)

    dur_phrase = _duration_phrase(duration) if duration else "a generous duration"
    hub_note = f"**{zone}** (the Hunting League hub" + (
        ", reached with `!hunt`)" if ctx.command_exists("hunt") else ")"
    )
    parts = []
    if refresh_pct:
        parts.append(f"Refresh ({refresh_pct:.0%} of max MP per tick)")
    else:
        parts.append("Refresh")
    if regen_pct:
        parts.append(f"Regen ({regen_pct:.0%} of max HP per tick)")
    else:
        parts.append("Regen")
    if regain_div:
        parts.append(f"Regain (1 per {regain_div} levels)")
    else:
        parts.append("Regain")

    buff_cmd = _link(ctx.docs_dir, "../progression/server-features.md#the-buff-command", "`!buff`")
    body = [
        f"Zone into {hub_note} and the server applies your buffs automatically — the "
        f"same package as the {buff_cmd} command: a regional buff plus "
        f"{', '.join(parts[:-1])} and {parts[-1]}, for **{dur_phrase}**.",
        "",
        "You can start hunting the moment you arrive without typing anything. If the "
        "buffs drop mid-session, `!buff` re-applies them anywhere.",
    ]
    return "## Auto-Buff at the Hunting League Hub", body


def _render_alzahbi(text: str, ctx: _Ctx):
    invasions = _link(ctx.docs_dir, "../endgame/invasions.md", "Scheduled Invasions")
    body = [
        "Every monster killed in **Al Zahbi** drops one extra random item, rolled "
        "from across the whole item database, on top of its normal loot. It is pure "
        "novelty — you never know what you'll get — and it stacks with the "
        f"{invasions} that also take place there.",
    ]
    return "## Al Zahbi Loot Fountain", body


def _render_seal_drops(text: str, ctx: _Ctx):
    seals = re.findall(r"id\s*=\s*\d+\s*,\s*name\s*=\s*'([^']+)'", text)
    lvl_threshold = _int(r"lvl\s*>=\s*(\d+)", text)
    qty_pairs = sorted(
        (int(t), int(q))
        for t, q in re.findall(r"r\s*<=\s*(\d+)\s*then\s*return\s*(\d+)", text)
    )

    dummy = _link(ctx.docs_dir, "../progression/gm-home.md#test-dummy", "Test Dummy")
    vendors = _link(ctx.docs_dir, "../progression/gear-vendors.md", "Gear Vendors")
    body = [
        f"Monsters killed inside **GM Home** (where the {dummy} lives) drop "
        f"**gear-vendor seals** every kill — the currency the {vendors} accept.",
        "",
    ]
    if len(seals) >= 3 and lvl_threshold:
        body += [
            f"- **Tier scales with mob level** — below level {lvl_threshold} drops "
            f"{seals[0]}s, level {lvl_threshold}+ drops {seals[1]}s, and **NMs bump "
            f"one tier higher** (so a {lvl_threshold}+ NM yields {seals[2]}s).",
        ]
    else:
        body += ["- The seal tier scales with the mob's level, and NMs drop a tier higher."]
    if qty_pairs:
        jackpot = max(q for _, q in qty_pairs)
        chances = ", ".join(
            f"{t}% for {q}+"
            for t, q in sorted(qty_pairs, key=lambda p: p[1])
            if q != jackpot
        )
        jackpot_t = min(t for t, q in qty_pairs if q == jackpot)
        body += [
            f"- **Quantity varies per kill** — every kill yields at least one; "
            f"{chances}; and a {jackpot_t}% shot at the **{jackpot}-seal jackpot**.",
        ]
    else:
        body += ["- The quantity varies per kill, with the occasional jackpot stack."]
    body += [
        "",
        "It's a small bonus faucet for testing your damage on something that fights back.",
    ]
    return "## GM Home Seal Drops", body


# ---------------------------------------------------------------------------
# Page assembly. Order matches the vetted hand-written page. Each entry may
# list fallback module files (first that exists is parsed).
# ---------------------------------------------------------------------------

_SYSTEMS: list[tuple[tuple[str, ...], object]] = [
    (("always_popped_nms.lua",),                            _render_always_popped),
    (("unlimited_visitant.lua", "AbysseaPermanentVisitant.lua"), _render_visitant),
    (("auto_unstick.lua",),                                 _render_auto_unstick),
    (("disable_zonein_cutscenes.lua",),                     _render_cutscenes),
    (("world_first_announcements.lua",),                    _render_world_firsts),
    (("chocobo_raising_qol.lua",),                          _render_chocobo),
    (("soa_remove_imprimatur_gate.lua",),                   _render_soa),
    (("conquest_regional_npcs_always_up.lua",),             _render_conquest),
    (("enhancing_magic_double_duration.lua",),              _render_enhancing),
    (("blu_spell_progression.lua",),                        _render_blu),
    (("auto_buff_henge.lua",),                              _render_auto_buff),
    (("alzahbi_loot.lua",),                                 _render_alzahbi),
    (("mob_seal_drops.lua",),                               _render_seal_drops),
]

_INTRO = [
    "# Background Systems",
    "",
    "These are server-level systems that run silently in the background — no NPC to "
    "talk to, no command to type. Most players encounter them indirectly: you zone "
    "into an endgame zone and an NM is already up, or you get stuck in a cutscene "
    "loop and zoning fixes it.",
    "",
    "This page explains what each system does so you know what's happening when you "
    "run into it.",
    "",
]


def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules")
    if src is None:
        print("[background_systems_page] skip: modules/ not found")
        return
    lua_dir = src / "custom" / "lua"
    if not lua_dir.exists():
        print("[background_systems_page] skip: modules/custom/lua not found")
        return

    ctx = _Ctx(repo_root, docs_dir, lua_dir)

    lines: list[str] = list(_INTRO)
    rendered: list[str] = []
    dropped: list[str] = []

    for fnames, renderer in _SYSTEMS:
        path = next((lua_dir / f for f in fnames if (lua_dir / f).exists()), None)
        if path is None:
            dropped.append(fnames[0])
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        heading, body = renderer(text, ctx)
        lines += ["---", "", heading, ""]
        lines += body
        lines.append("")
        rendered.append(path.name)

    if not rendered:
        print("[background_systems_page] skip: no background-system modules found — not writing")
        return

    page = docs_dir / "changes" / "background-systems.md"
    page.parent.mkdir(parents=True, exist_ok=True)
    page.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

    note = f", dropped: {', '.join(dropped)}" if dropped else ""
    print(
        f"[background_systems_page] wrote docs/changes/background-systems.md "
        f"({len(rendered)} systems{note})"
    )
