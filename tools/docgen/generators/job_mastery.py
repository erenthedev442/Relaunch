"""Sync docs/endgame/job-mastery.md with job_mastery.lua.

The Job Mastery challenges are defined inline in job_mastery.lua: a `GUARDIANS`
table of one Guardian boss per weapon type, plus an `AFFIXES` pool rolled onto
the boss when it spawns. We surface the player-facing fields only — each
weapon type and its Guardian's name, and the affix labels. The internal tuning
(boss HP, level, group ids, and the affix mod deltas) is never published.
Adding a weapon to the table updates the page and the headline count
automatically.

Markers written:
  job-mastery-access   — Mastery Sage NPC + how to start + zone line
  job-mastery-fights   — the per-weapon Guardian table + solo rules
  job-mastery-affixes  — the affix pool (labels only)
  job-mastery-rewards  — Trial 4 credit + accumulation
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section


def _first(pattern: str, text: str, default: str) -> str:
    m = re.search(pattern, text)
    return m.group(1) if m else default


def _parse(text: str) -> dict:
    c: dict = {}

    # Where the NPC lives + how to start. The Mastery Sage is placed in GM Home
    # (packetName), and the bosses spawn in the challenge zone.
    c["npc"] = _first(r"packetName\s*=\s*'([^']+)'", text, "Weapon Mastery Sage")
    c["command"] = "!mastery"

    # The challenge zone is referenced as xi.zone.<NAME>; humanize it.
    m = re.search(r"CHALLENGE_ZONE_ID\s*=\s*xi\.zone\.([A-Z_]+)", text)
    c["zone"] = m.group(1).replace("_", " ").title() if m else "Walk Of Echoes"

    # Guardians: PUBLIC-safe weapon label + Guardian name only. The level / hp /
    # groupId tuning fields are scrubbed (same policy as prime_armory dropping
    # the raw item id and voidspire scrubbing affix mod deltas).
    block = section(text, "GUARDIANS") or text
    c["guardians"] = re.findall(
        r"label\s*=\s*'([^']+)'\s*,\s*bossName\s*=\s*'([^']+)'", block
    )

    # Affixes: label only (the mod tables are internal difficulty tuning).
    affixes = section(text, "AFFIXES")
    c["affixes"] = re.findall(r"label\s*=\s*'([^']+)'", affixes)

    # The Trial credit this challenge feeds (PW_Trial4_Done gates the Prime
    # Armory forge).
    m = re.search(r"PW_Trial(\d+)_Done", text)
    c["trial"] = int(m.group(1)) if m else 4

    return c


# ---------------------------------------------------------------------------

def _render_access(c: dict) -> str:
    return (f"Find the **{c['npc']}** in **GM Home** and pick a weapon type. "
            f"Choosing one warps you alone into **{c['zone']}**, where that "
            f"weapon's Guardian appears moments later. There is no quest and no "
            f"cost to attempt a challenge — just talk to the Sage and choose. "
            f"If you ever need to bail out of an active attempt, use "
            f"**`{c['command']} abort`**.")


def _render_fights(c: dict) -> str:
    lines = []
    lines.append(f"There is one Guardian for each of the **{len(c['guardians'])} "
                 f"weapon types**. Each is a **solo** fight — trusts are disabled "
                 f"in the arena, so it is you and your weapon against the "
                 f"Guardian. Whichever one you defeat, the credit is the same; "
                 f"pick the weapon type you fight best with.")
    lines.append("")
    lines.append("Every Guardian rolls a random **affix** when it spawns, so the "
                 "same fight plays differently each attempt. They hit hard and "
                 "carry an enormous health pool — bring your strongest setup.")
    lines.append("")
    lines.append("**Death ends the challenge** with no reward and no save: you "
                 "are returned to GM Home and must start over.")
    if c["guardians"]:
        lines.append("")
        lines.append("| Weapon type | Guardian |")
        lines.append("|---|---|")
        for label, boss in c["guardians"]:
            lines.append(f"| **{label}** | {boss} |")
    return "\n".join(lines)


def _render_affixes(c: dict) -> str:
    lines = []
    lines.append("When a Guardian appears it carries one of these affixes, rolled "
                 "at random and shown to you as it spawns. Every affix piles real "
                 "offense on top of the Guardian's base power, so there is no "
                 "\"safe\" roll:")
    if c["affixes"]:
        lines.append("")
        lines.append("| Affix |")
        lines.append("|---|")
        for label in c["affixes"]:
            lines.append(f"| **{label}** |")
    return "\n".join(lines)


def _render_rewards(c: dict) -> str:
    return (f"Defeating **any** Guardian completes **Trial {c['trial']}** of the "
            f"Prime Weapon path — the final gate before the **Prime Armory** will "
            f"forge your Prime weapon. You only need to beat **one** Guardian to "
            f"earn that credit.\n\n"
            f"Beyond that first clear, every additional Guardian you defeat is "
            f"tracked on its own, so completionists can work through all "
            f"{len(c['guardians'])} weapon types — but a single victory is all "
            f"Trial {c['trial']} requires.")


# ---------------------------------------------------------------------------

_PAGE = """# Job Mastery

The final proof of mastery is to stand alone against a weapon's living avatar.
Each weapon type has a **Guardian** — a single, brutal boss you face solo in
{zone}. Beat the Guardian of any weapon and you complete the last trial on the
Prime Weapon path.

!!! tip "Summary"
    Pick a weapon type at the {npc} in GM Home, fight its Guardian solo in
    {zone}, and a single victory completes Trial {trial} of the Prime Weapon
    path. Death ends the attempt with no reward.

## Where to start

<!-- DOCGEN:BEGIN id="job-mastery-access" -->
<!-- DOCGEN:END id="job-mastery-access" -->

## The Guardian fights

<!-- DOCGEN:BEGIN id="job-mastery-fights" -->
<!-- DOCGEN:END id="job-mastery-fights" -->

## Affixes

<!-- DOCGEN:BEGIN id="job-mastery-affixes" -->
<!-- DOCGEN:END id="job-mastery-affixes" -->

## Reward

<!-- DOCGEN:BEGIN id="job-mastery-rewards" -->
<!-- DOCGEN:END id="job-mastery-rewards" -->

Job Mastery is the capstone of the Prime Weapon journey — there is no party to
hide behind and no second chance once you fall, so master your weapon before you
challenge its Guardian.
"""


def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/job_mastery.lua")
    if src is None:
        print("[job_mastery] skip: job_mastery.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    c = _parse(text)

    page = docs_dir / "endgame" / "job-mastery.md"
    if not page.exists():
        page.parent.mkdir(parents=True, exist_ok=True)
        page.write_text(
            _PAGE.format(zone=c["zone"], npc=c["npc"], trial=c["trial"]),
            encoding="utf-8",
        )

    blocks = [
        ("job-mastery-access", _render_access(c)),
        ("job-mastery-fights", _render_fights(c)),
        ("job-mastery-affixes", _render_affixes(c)),
        ("job-mastery-rewards", _render_rewards(c)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[job_mastery] {written}/{len(blocks)} marker block(s) written "
          f"(guardians={len(c['guardians'])}, affixes={len(c['affixes'])})")
