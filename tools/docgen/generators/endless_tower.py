"""Sync docs/endgame/endless-tower.md with endless_tower.lua.

The Endless Tower is a 50-floor solo gauntlet: clear floor after floor, fight a
boss every tenth floor, and reach floor 50 to fell the Pinnacle Sovereign and
complete Prime Weapon Trial 2. Everything on the page — where it starts, the
solo rule, how the floor bands scale, the boss roster, the boss affixes, and
the floor-50 payoff — is read from the module so re-tuning the run updates the
published guide.

Unlike the *_catalog.lua systems, this module keeps its config in plain `local`
tables (BANDS, BOSS_AFFIXES) and top-of-file constants rather than a
`catalog.<name>` block, so the parser pulls those out with direct regex
(the same approach tournament.py uses for its WAVES table).

Markers written:
  endless-tower-access   — Arbiter NPC + zone + how to start + solo rule
  endless-tower-floors   — 50-floor structure + per-band scaling table
  endless-tower-bosses   — boss-every-10-floors roster + affix list
  endless-tower-rewards  — floor-50 Trial 2 payoff + personal-best leaderboard
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section, commafy


def _first(pattern: str, text: str, default: str) -> str:
    m = re.search(pattern, text)
    return m.group(1) if m else default


def _int(pattern: str, text: str, default: int) -> int:
    return int(float(_first(pattern, text, str(default))))


def _parse(text: str) -> dict:
    c: dict = {}

    # NPC + placement.
    c["npc"] = _first(r"packetName\s*=\s*'([^']+)'", text, "Endless Tower Arbiter")
    c["zoneConst"] = _first(r"TOWER_ZONE_ID\s*=\s*xi\.zone\.([A-Z_]+)", text, "WALK_OF_ECHOES")
    # Friendly zone name from the constant (WALK_OF_ECHOES -> Walk of Echoes).
    c["zone"] = c["zoneConst"].replace("_", " ").title()

    c["maxFloor"]    = _int(r"MAX_FLOOR\s*=\s*(\d+)", text, 50)
    c["floorDelay"]  = _int(r"FLOOR_DELAY_MS\s*=\s*(\d+)", text, 5000)

    # Boss cadence: floor % N == 0 in isBossFloor.
    c["bossEvery"] = _int(r"floor\s*%\s*(\d+)\s*==\s*0", text, 10)

    # Mob-count formula: `return 2 + band` over 10-floor bands.
    c["mobBase"] = _int(r"return\s+(\d+)\s*\+\s*band", text, 2)

    # Floor bands: each `{ maxFloor=.., level=.., bossLevel=.., ... bossHp=..,
    # ... bossName='..' }` entry inside the BANDS table.
    bands_blk = section(text, "BANDS") or text
    c["bands"] = []
    band_re = re.compile(
        r"maxFloor\s*=\s*(\d+)\s*,\s*level\s*=\s*(\d+)\s*,\s*bossLevel\s*=\s*(\d+)",
        re.DOTALL,
    )
    boss_hp_re   = re.compile(r"bossHp\s*=\s*(\d+)")
    boss_name_re = re.compile(r"bossName\s*=\s*'([^']+)'")
    # Walk entry-by-entry so each band's bossHp/bossName stays paired with it.
    entries = re.split(r"\}\s*,\s*\{", bands_blk)
    for ent in entries:
        m = band_re.search(ent)
        if not m:
            continue
        hp   = boss_hp_re.search(ent)
        name = boss_name_re.search(ent)
        c["bands"].append({
            "maxFloor":  int(m.group(1)),
            "level":     int(m.group(2)),
            "bossLevel": int(m.group(3)),
            "bossHp":    int(hp.group(1)) if hp else 0,
            "bossName":  name.group(1) if name else "?",
        })

    # Boss affixes: PUBLIC-safe label only (the mod deltas are scrubbed, like
    # voidspire.py does for its affix table).
    affix_blk = section(text, "BOSS_AFFIXES")
    c["affixes"] = re.findall(r"label\s*=\s*'([^']+)'", affix_blk)

    # The floor-50 payoff: which charVar / trial it completes.
    c["trialVar"] = _first(r"setCharVar\('(PW_Trial\d+_Done)'", text, "PW_Trial2_Done")
    tm = re.search(r"PW_Trial(\d+)_Done", text)
    c["trialNum"] = int(tm.group(1)) if tm else 2

    return c


# ---------------------------------------------------------------------------

def _render_access(c: dict) -> str:
    return (f"Speak to the **{c['npc']}** in **GM Home** and choose *Enter the "
            f"Tower* to be warped into **{c['zone']}**. After a short breather "
            f"the first floor spawns, and each cleared floor leads straight into "
            f"the next.\n\n"
            f"This is a **solo** gauntlet — Trusts are disabled inside the Tower. "
            f"A single death ends the run on the spot with no reward and no "
            f"floor saved, so you only ever advance by surviving. You can bail "
            f"out early at any time with **`!tower abort`**, and **`!tower`** on "
            f"its own reports your current floor (or your best-ever floor when "
            f"you're not in a run).")


def _render_floors(c: dict) -> str:
    lines = []
    lines.append(f"The Tower is **{c['maxFloor']} floors** tall. Every floor "
                 f"throws a pack of monsters at you; clear them all and the next "
                 f"floor spawns after a brief pause. Monsters get a fresh, "
                 f"larger level the deeper you climb, and the pack grows from "
                 f"**{c['mobBase'] + 1}** monsters on the lowest floors toward a "
                 f"bigger crowd near the top.")
    if c["bands"]:
        lines.append("")
        lines.append("Floors are grouped into ten-floor bands, each a sharp step "
                     "up in monster level:")
        lines.append("")
        lines.append("| Floors | Monster level |")
        lines.append("|---|---|")
        prev = 0
        for b in c["bands"]:
            hi = b["maxFloor"]
            rng = f"{prev + 1}" if hi == prev + 1 else f"{prev + 1}–{hi}"
            lines.append(f"| {rng} | **{b['level']}** |")
            prev = hi
    return "\n".join(lines)


def _render_bosses(c: dict) -> str:
    lines = []
    lines.append(f"Every **{c['bossEvery']}th floor** is a boss floor: a single "
                 f"towering monster stands between you and the next band. Each "
                 f"boss rolls **one random affix** when it appears, so the same "
                 f"boss can play very differently from run to run.")
    if c["bands"]:
        lines.append("")
        lines.append("The bosses, band by band:")
        lines.append("")
        lines.append("| Floor | Boss | Level | HP |")
        lines.append("|---|---|---:|---:|")
        for b in c["bands"]:
            lines.append(f"| {b['maxFloor']} | **{b['bossName']}** | "
                         f"{b['bossLevel']} | {commafy(b['bossHp'])} |")
    if c["affixes"]:
        lines.append("")
        lines.append("Possible boss affixes:")
        lines.append("")
        lines.append("- " + "\n- ".join(f"**{a}**" for a in c["affixes"]))
    return "\n".join(lines)


def _render_rewards(c: dict) -> str:
    last = c["bands"][-1]["bossName"] if c["bands"] else "the final boss"
    return (f"The Tower's prize is the climb itself. Reaching **floor "
            f"{c['maxFloor']}** and defeating **{last}** completes **Prime "
            f"Weapon Trial {c['trialNum']}** — the gateway to forging your Prime "
            f"Weapon at the Prime Armory. The trial only needs to be cleared "
            f"once; after that, floor 50 is pure bragging rights.\n\n"
            f"Your **deepest floor ever cleared** is tracked as a personal best, "
            f"so even a run that ends short of the top still pushes your record "
            f"on the leaderboard. There are no checkpoints — the Tower only "
            f"remembers how high you climbed.")


# ---------------------------------------------------------------------------

_PAGE = """# The Endless Tower

A spire with no roof, only more floors. The **Endless Tower** is a solo
gauntlet that climbs through ever-stronger monsters, a boss waiting on every
tenth floor. Fight your way to the top and the Pinnacle Sovereign falls — and
with it, a piece of your Prime Weapon legend. One death, and the run is over.

!!! tip "Summary"
    A solo {max_floor}-floor climb from the {npc} in GM Home — a boss every
    {boss_every} floors, no Trusts allowed, one death ends the run, and reaching
    floor {max_floor} completes Prime Weapon Trial {trial_num}.

## Where to start

<!-- DOCGEN:BEGIN id="endless-tower-access" -->
<!-- DOCGEN:END id="endless-tower-access" -->

## How the floors scale

<!-- DOCGEN:BEGIN id="endless-tower-floors" -->
<!-- DOCGEN:END id="endless-tower-floors" -->

## Bosses

<!-- DOCGEN:BEGIN id="endless-tower-bosses" -->
<!-- DOCGEN:END id="endless-tower-bosses" -->

## Rewards

<!-- DOCGEN:BEGIN id="endless-tower-rewards" -->
<!-- DOCGEN:END id="endless-tower-rewards" -->

Climb carefully — there is no checkpoint, no party to lean on, and the Tower
only remembers how high you dared to go.
"""


def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/endless_tower.lua")
    if src is None:
        print("[endless-tower] skip: endless_tower.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    c = _parse(text)

    page = docs_dir / "endgame" / "endless-tower.md"
    if not page.exists():
        page.parent.mkdir(parents=True, exist_ok=True)
        page.write_text(
            _PAGE.format(
                max_floor=c["maxFloor"],
                npc=c["npc"],
                boss_every=c["bossEvery"],
                trial_num=c["trialNum"],
            ),
            encoding="utf-8",
        )

    blocks = [
        ("endless-tower-access",  _render_access(c)),
        ("endless-tower-floors",  _render_floors(c)),
        ("endless-tower-bosses",  _render_bosses(c)),
        ("endless-tower-rewards", _render_rewards(c)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[endless-tower] {written}/{len(blocks)} marker block(s) written "
          f"(bands={len(c['bands'])}, affixes={len(c['affixes'])})")
