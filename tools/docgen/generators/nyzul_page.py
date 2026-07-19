"""Generate the Nyzul Isle page from the live entry NPC + retail scripts.

Owns (FULL-page writer — the file is rebuilt from scratch every run):
  - docs/endgame/nyzul-isle.md

Sources:
  - scripts/zones/<Zone>/npcs/Sorrowful_Sage.lua — the custom entry NPC. Found
    by scanning zone npc folders for the Sorrowful_Sage copy whose ACTIVE code
    calls createInstance() (the Whitegate retail mission-giver of the same
    name doesn't). Parsed for: hub zone, instance id, the in-game briefing.
  - scripts/globals/nyzul.lua — objective/lamp/gear enums, the floorCost
    resume table (starting floors + token costs), vigil-weapon drop chance.
  - scripts/zones/Nyzul_Isle/instances/nyzul_isle_investigation.lua —
    boss-floor cadence and the zone runs exit to.
  - sql/instance_list.sql — the instance row's time limit (minutes).
  - scripts/zones/Aht_Urhgan_Whitegate/npcs/Sorrowful_Sage.lua — the retail
    Assault mission giver, comment-stripped and checked for a working
    assault-orders flow so the page never overclaims the retail entry path.

Retail floor-mechanics narrative (what an objective asks of you, what the
Rune of Transfer is) stays as constants keyed by the parsed enum names; the
enumerated facts (objective list, boss cadence, timer, costs) are parsed.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source


# ---------------------------------------------------------------------------
# Lua helpers
# ---------------------------------------------------------------------------

def _strip_lua_comments(text: str) -> str:
    """Remove --[[ ... ]] block comments then -- line comments, so checks like
    "does this NPC still start the assault menu" only see ACTIVE code."""
    text = re.sub(r"--\[\[.*?\]\]", "", text, flags=re.DOTALL)
    text = re.sub(r"--[^\n]*", "", text)
    return text


def _parse_enum(text: str, name: str) -> list[str]:
    """Parse `xi.nyzul.<name> = { KEY = n, ... }` -> keys ordered by value."""
    m = re.search(rf"xi\.nyzul\.{re.escape(name)}\s*=\s*\{{([^}}]*)\}}", text, re.DOTALL)
    if not m:
        return []
    pairs = re.findall(r"([A-Z_][A-Z0-9_]*)\s*=\s*(\d+)", m.group(1))
    return [key for key, _ in sorted(pairs, key=lambda kv: int(kv[1]))]


# ---------------------------------------------------------------------------
# Constants keyed by parsed enum names (narrative only; the LIST is parsed)
# ---------------------------------------------------------------------------

_OBJECTIVE_LABELS: dict[str, tuple[str, str]] = {
    "ELIMINATE_ENEMY_LEADER":      ("Eliminate enemy leader",
                                    "Hunt down and kill the floor's leader — also the fixed objective on every boss floor"),
    "ELIMINATE_SPECIFIED_ENEMIES": ("Eliminate specified enemies",
                                    "Several specific targets are called out — kill all of them"),
    "ACTIVATE_ALL_LAMPS":          ("Activate all lamps",
                                    "Find and light five scattered lamps within two minutes"),
    "ELIMINATE_SPECIFIED_ENEMY":   ("Eliminate specified enemy",
                                    "Find the target that checks as Impossible to Gauge and kill it"),
    "ELIMINATE_ALL_ENEMIES":       ("Eliminate all enemies",
                                    "Kill every mob on the floor"),
    "FREE_FLOOR":                  ("Free floor",
                                    "A rare lucky floor with no objective — proceed straight to the Rune of Transfer"),
}

_LAMP_LABELS: dict[str, str] = {
    "REGISTER":     "register every party member on a lamp",
    "ACTIVATE_ALL": "light all lamps at the same time",
    "ORDER":        "light the lamps in the correct order",
    "SCAVENGER":    "find and light five lamps within two minutes",
}

_GEAR_LABELS: dict[str, str] = {
    "AVOID_AGRO":     "**Avoid agro** (don't be detected)",
    "DO_NOT_DESTROY": "**Do not destroy** (spare the flagged mobs)",
}


def _pretty_enum(name: str) -> str:
    return name.replace("_", " ").capitalize()


def _friendly_zone(raw: str) -> str:
    return raw.replace("_", " ").title().replace(" Of ", " of ")


# ---------------------------------------------------------------------------
# Source parsing
# ---------------------------------------------------------------------------

def _find_entry_npc(repo_root: Path) -> tuple[Path, str] | None:
    """Locate the Sorrowful_Sage copy that actually creates the instance.
    Returns (path, zone display name)."""
    zones_dir = resolve_source(repo_root, "scripts/zones")
    if zones_dir is None:
        return None
    for path in sorted(zones_dir.glob("*/npcs/Sorrowful_Sage.lua")):
        text = path.read_text(encoding="utf-8", errors="ignore")
        if "createInstance" in _strip_lua_comments(text):
            return path, path.parent.parent.name.replace("_", " ")
    return None


def _parse_briefing(text: str) -> list[str]:
    """The Sage's own 'How does it work?' chat lines — live in-game text."""
    lines = re.findall(r"printToPlayer\(\s*'\[Nyzul Isle\]\s*([^']+)'", text)
    return [
        ln.strip() for ln in lines
        if "already inside" not in ln and "Commencing transport" not in ln
    ]


def _parse_time_limit(repo_root: Path, instance_id: int | None) -> int | None:
    if instance_id is None:
        return None
    sql = resolve_source(repo_root, "sql/instance_list.sql")
    if sql is None:
        return None
    m = re.search(
        rf"\({instance_id},'[^']*',\d+,\d+,(\d+),",
        sql.read_text(encoding="utf-8", errors="ignore"),
    )
    return int(m.group(1)) if m else None


def _retail_entry_works(repo_root: Path) -> bool | None:
    """True/False = verified either way; None = retail NPC file not found.
    The retail chain is only usable if the Whitegate mission giver still opens
    the assault-selection event (284 is the 'no rank' brush-off)."""
    path = resolve_source(repo_root, "scripts/zones/Aht_Urhgan_Whitegate/npcs/Sorrowful_Sage.lua")
    if path is None:
        return None
    active = _strip_lua_comments(path.read_text(encoding="utf-8", errors="ignore"))
    return re.search(r"startEvent\(\s*278", active) is not None


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    entry = _find_entry_npc(repo_root)
    if entry is None:
        print("[nyzul_page] skip: custom Sorrowful_Sage entry NPC (createInstance) not found")
        return
    entry_path, entry_zone = entry
    entry_text = entry_path.read_text(encoding="utf-8", errors="ignore")

    globals_path = resolve_source(repo_root, "scripts/globals/nyzul.lua")
    if globals_path is None:
        print("[nyzul_page] skip: scripts/globals/nyzul.lua not found")
        return
    gtext = globals_path.read_text(encoding="utf-8", errors="ignore")

    inst_path = resolve_source(
        repo_root, "scripts/zones/Nyzul_Isle/instances/nyzul_isle_investigation.lua"
    )
    if inst_path is None:
        print("[nyzul_page] skip: nyzul_isle_investigation.lua instance script not found")
        return
    itext = inst_path.read_text(encoding="utf-8", errors="ignore")

    # ---- entry NPC facts ---------------------------------------------------
    m = re.search(r"NYZUL_INSTANCE\s*=\s*(\d+)", entry_text)
    instance_id = int(m.group(1)) if m else None
    briefing = _parse_briefing(entry_text)

    # ---- floor mechanics ---------------------------------------------------
    objectives = _parse_enum(gtext, "objective")
    lamp_modes = _parse_enum(gtext, "lampsObjective")
    gear_modes = _parse_enum(gtext, "gearObjective")
    if not objectives:
        print("[nyzul_page] skip: xi.nyzul.objective enum not parseable")
        return

    floor_costs = [
        (int(lv), int(cost))
        for lv, cost in re.findall(r"\{\s*level\s*=\s*(\d+)\s*,\s*cost\s*=\s*(\d+)\s*\}", gtext)
    ]
    start_floors = [lv for lv, _ in floor_costs]
    paid_costs = [c for _, c in floor_costs if c > 0]

    m = re.search(r"currentFloor\s*%\s*(\d+)\s*==\s*0", itext)
    boss_every = int(m.group(1)) if m else None

    m = re.search(r"setPos\([^)]*xi\.zone\.([A-Z0-9_]+)\s*\)", itext)
    exit_zone = _friendly_zone(m.group(1)) if m else None

    # Vigil weapon drop chance inside xi.nyzul.vigilWeaponDrop
    vigil_pct = None
    vidx = gtext.find("vigilWeaponDrop")
    if vidx != -1:
        m = re.search(r"math\.random\(1,\s*100\)\s*<=\s*(\d+)", gtext[vidx:vidx + 2500])
        if m:
            vigil_pct = int(m.group(1))
    floor100_guarantee = re.search(r"floor 100 [Bb]oss", gtext) is not None

    time_limit = _parse_time_limit(repo_root, instance_id)
    retail_works = _retail_entry_works(repo_root)
    timer_phrase = f"**{time_limit}-minute timer**" if time_limit else "**fixed timer**"

    # ---- render --------------------------------------------------------------
    lines: list[str] = [
        "# Nyzul Isle",
        "",
        "**Nyzul Isle Investigation** is an instanced floor-climbing dungeon lifted "
        "from retail, accessible on the Relaunch server without completing any Assault "
        "or ToAU prerequisites. Entry, exits, and lamp floors are adapted for a solo server.",
        "",
        "---",
        "",
        "## How to enter",
        "",
        f"1. Travel to **{entry_zone}** (use a Home Point or standard travel).",
    ]
    if entry_zone == "Mhaura":
        lines.append("2. Find the **Sorrowful Sage** NPC — he stands near the Ambuscade NPCs at the docks.")
    else:
        lines.append("2. Find the **Sorrowful Sage** NPC.")
    lines += [
        "3. Talk to him and pick **Begin assault** — you (and nearby party members) are "
        "transported straight into the Nyzul staging room.",
        "",
        "No Assault rank, no Imperial Standing, no prior quest chain — just talk and enter.",
        "",
    ]

    if retail_works:
        lines += [
            '!!! note "Retail entry also works"',
            "    The retail Assault entry (Nyzul Isle Assault Orders via the staging "
            "points) also functions if you have Assault access. The Sorrowful Sage in "
            f"{entry_zone} is simply the shortcut.",
            "",
        ]
    else:
        exit_note = f" Finishing or leaving a run returns the party to {exit_zone}." if exit_zone else ""
        lines += [
            '!!! note "The Sage is the supported way in"',
            "    The retail entry chain (Assault rank, Nyzul Isle Assault Orders, the "
            "Azouph Isle staging point) is **not wired up** on this server — the retail "
            "mission NPC never hands out assault orders. Use the Sorrowful Sage."
            + exit_note,
            "",
        ]

    lines += [
        "---",
        "",
        "## What is Nyzul Isle?",
        "",
        f"A 100-floor dungeon you climb within a {timer_phrase}. Each run starts from "
        "floor 1 (or a floor you've unlocked — see below), and every floor holds a "
        "**Rune of Transfer** — the crystal that carries you up to the next floor once "
        "the floor's objective is complete.",
        "",
        "A visible countdown runs throughout the assault. System-channel reminders are "
        "also sent at **25, 20, 15, 10, 5, and 1 minute remaining**, then again at "
        "**30 seconds**, so chat filters cannot hide the only warning.",
        "",
        "### Floor objectives",
        "",
        "Each floor presents one of these mission types before the Rune of Transfer "
        "will move you on. The objective is repeated in the system channel on floor "
        "entry and whenever you check the inactive Rune:",
        "",
        "| Objective | What to do |",
        "|---|---|",
    ]
    for enum_name in objectives:
        label, desc = _OBJECTIVE_LABELS.get(
            enum_name, (_pretty_enum(enum_name), "Complete the on-screen objective")
        )
        lines.append(f"| **{label}** | {desc} |")
    lines.append("")

    if "SCAVENGER" in lamp_modes:
        lines += [
            "**Lamp floors are solo-friendly scavenger rounds:** five lamps are placed "
            "around the layout and remain lit when clicked. Activate all five within "
            "**two minutes**. If time expires, the lamps reset and the assault timer "
            "loses **one minute**, then a fresh two-minute attempt begins.",
            "",
        ]
    if gear_modes:
        extras = ", ".join(_GEAR_LABELS.get(mode, _pretty_enum(mode)) for mode in gear_modes)
        lines += [
            f"Some floors also carry a bonus discipline on top of the main objective — "
            f"{extras} — breaking it costs you time or tokens.",
            "",
        ]

    lines += [
        "### Boss floors",
        "",
    ]
    if boss_every:
        lines.append(
            f"Every **{boss_every} floors** ({boss_every}, {boss_every * 2}, "
            f"{boss_every * 3}, ...) is a boss floor: the objective is always "
            "**Eliminate enemy leader** in a dedicated arena layout. Bosses are harder "
            f"than regular floor mobs and gate your progress to the next {boss_every}-floor block."
        )
    else:
        lines.append(
            "Fixed boss floors punctuate the climb — the objective there is always "
            "**Eliminate enemy leader** in a dedicated arena layout."
        )
    if floor100_guarantee:
        lines.append("")
        lines.append("Floor 100 is the final challenge — its bosses carry guaranteed weapon drops (see Rewards).")
    lines += [
        "",
        "### Saving your progress",
        "",
        "Your first visit to the staging-room Rune of Transfer hands you the **Runic "
        "Disc** key item, which records your progress:",
        "",
    ]
    if start_floors and len(start_floors) > 1:
        step = start_floors[1] - start_floors[0]
        token_line = "- Starting above floor 1 costs **tokens** earned on previous runs."
        if paid_costs:
            token_line = (
                "- Starting above floor 1 costs **tokens** earned on previous runs "
                f"({min(paid_costs)}–{max(paid_costs)} per entry, rising with the floor)."
            )
        lines += [
            f"- Progress is banked in **{step}-floor blocks** — climbing unlocks starting "
            f"floors {start_floors[0]}, {start_floors[0] + step}, {start_floors[0] + 2 * step}, "
            f"... up to {start_floors[-1]}.",
            token_line,
            "- Only the player whose **Runic Disc selected the starting floor** records "
            "floor progress. Helpers earn rewards but do not advance their own discs.",
            "- Use the Rune of Transfer to **leave before the timer expires** and the "
            "disc holder's progress (plus earned tokens) is banked for next time.",
        ]
    else:
        lines += [
            "- Save your current floor so future runs can start there.",
            "- Use the Rune of Transfer to leave before the timer expires and your "
            "progress (and tokens) are banked for next time.",
        ]
    lines += [
        "",
        "---",
        "",
        "## Rewards",
        "",
    ]
    reward_bits: list[str] = []
    if vigil_pct:
        reward_bits.append(
            f"- **Vigil weapons** — every NM on the climb has a {vigil_pct}% chance to drop "
            "one" + (", and floor-100 bosses **guarantee** a random vigil weapon plus one "
                     "for the disc-holder's job." if floor100_guarantee else ".")
        )
    else:
        reward_bits.append("- **Vigil weapons** — dropped by NMs on the climb.")
    if any("Askar" in ln for ln in briefing):
        reward_bits.append(
            "- **Nyzul armor** — the Askar, Denali, and Goliard lines from floor NMs and bosses."
        )
    reward_bits += [
        "- **Nyzul tokens** — earned per cleared floor; spend them to resume from saved "
        "floors and buy supplies from the in-run Vending Box.",
        "- **Runic Key / Mythic trial** — a floor-100 clear is recorded only for the "
        "player whose Runic Disc selected the climb. Party helpers do not receive "
        "simultaneous floor-100 credit.",
    ]
    lines += reward_bits
    # The two drop tables below are filled by the sibling `nyzul_isle` generator
    # (live from armoury_crate.lua + appraisal.lua). This page owns the narrative
    # and emits the marker blocks empty; nyzul_isle MUST run after this module so
    # it injects into them. Keep these ids in sync with nyzul_isle.generate().
    lines += [
        "",
        "### Floor-100 Vigil Weapons",
        "",
        '<!-- DOCGEN:BEGIN id="nyzul-floor100" -->',
        '<!-- DOCGEN:END id="nyzul-floor100" -->',
        "",
        "### NM drop table",
        "",
        "Each floor NM drops one Unappraised chest; take it to the in-instance "
        "appraiser to reveal the gear, drawn from the weighted pool below "
        "(percentages rounded).",
        "",
        '<!-- DOCGEN:BEGIN id="nyzul-nm-drops" -->',
        '<!-- DOCGEN:END id="nyzul-nm-drops" -->',
    ]

    if briefing:
        lines += [
            "",
            '??? quote "The Sage\'s own briefing (in-game text)"',
        ]
        for ln in briefing:
            lines.append(f"    - {ln}")

    page = docs_dir / "endgame" / "nyzul-isle.md"
    page.parent.mkdir(parents=True, exist_ok=True)
    page.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

    facts = (
        f"entry=Sorrowful Sage @ {entry_zone}, instance {instance_id}, "
        f"{time_limit if time_limit else '?'} min, {len(objectives)} objectives, "
        f"retail-entry={'works' if retail_works else 'stubbed' if retail_works is not None else 'unknown'}"
    )
    print(f"[nyzul_page] wrote docs/endgame/nyzul-isle.md ({facts})")
