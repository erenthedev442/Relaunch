"""trust_tiers — fills the trust-tiers slot on reference/spells/trust.md.

Two gating systems, both parsed from live Lua so the page can't drift:

  1. SUMMON-COUNT LADDER (trust_progression_cap.lua): how many trusts you can
     field at once. BASE_CAP + TRUST_GATES, each gate's content string taken
     verbatim from the code's own `unlock =` text.

  2. LOCKED CUSTOM TRUSTS (trust_skoll.lua): the marquee trusts the Void Keeper
     sells, each behind a Hunting League rank + a Hunt Marks price. These reuse
     retail spell IDs (899/901/902), so in the big spell dump below they appear
     only as their repurposed client names (Excenmille / Nanaa Mihgo / Curilla)
     — the crosswalk table here is the only place a player learns that
     "Excenmille" IS the Meat trust and that it's a paid unlock.

spells.py owns and rewrites trust.md wholesale each run, emitting an empty
`trust-tiers` marker slot under the title; this generator (registered AFTER
spells) fills it. FAIL-CLOSED: a parse error raises, generate.py logs it, and
spells.py's fallback text stays — the page never shows a hole.
"""

from __future__ import annotations

import html
import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers


def _read(repo_root: Path, rel: str) -> str:
    src = resolve_source(repo_root, rel)
    if src is None:
        raise RuntimeError(f"trust_tiers: source not found: {rel}")
    return src.read_text(encoding="utf-8", errors="replace")


def _esc(s: str) -> str:
    return html.escape(s, quote=False)


def _parse_ladder(text: str) -> tuple[int, list[tuple[int, str]]]:
    base_m = re.search(r"BASE_CAP\s*=\s*(\d+)", text)
    if not base_m:
        raise RuntimeError("trust_tiers: BASE_CAP not found")
    base = int(base_m.group(1))
    gates = [(int(cap), unlock) for cap, unlock in
             re.findall(r"cap\s*=\s*(\d+),\s*unlock\s*=\s*'((?:[^'\\]|\\.)*)'", text)]
    if not gates:
        raise RuntimeError("trust_tiers: TRUST_GATES parse failed")
    gates.sort()
    return base, gates


def _parse_paid(text: str) -> list[dict]:
    trusts = []
    for blk in re.findall(r"\{(.*?)\}", text, flags=re.S):
        sid = re.search(r"spellId\s*=\s*(\d+)", blk)
        name = re.search(r"name\s*=\s*'([^']+)'", blk)
        client = re.search(r"clientName\s*=\s*'([^']+)'", blk)
        rank = re.search(r"rankReq\s*=\s*(\d+)", blk)
        cost = re.search(r"markCost\s*=\s*(\d+)", blk)
        if sid and name and client and rank and cost:
            trusts.append({
                "spellId": int(sid.group(1)),
                "name": name.group(1),
                "client": client.group(1),
                "rank": int(rank.group(1)),
                "cost": int(cost.group(1)),
            })
    if not trusts:
        raise RuntimeError("trust_tiers: TRUSTS parse failed")
    trusts.sort(key=lambda t: t["rank"])
    return trusts


def _vendor_name(text: str) -> str:
    m = re.search(r"packetName\s*=\s*string\.format\('%s([^']+)'", text)
    return m.group(1).strip() if m else "Void Keeper"


def generate(repo_root: Path, docs_dir: Path) -> None:
    cap_txt = _read(repo_root, "modules/custom/lua/trust_progression_cap.lua")
    paid_txt = _read(repo_root, "modules/custom/lua/trust_skoll.lua")

    base, gates = _parse_ladder(cap_txt)
    paid = _parse_paid(paid_txt)
    vendor = _vendor_name(paid_txt)

    # Link the gate content to its own reference page where one exists.
    LINKS = {
        "Unity": "../../endgame/unity-concord.md",
        "Voidwatch": "../../endgame/voidwatch.md",
        "Fellow": "../../progression/fellow-companion.md",
    }

    def _linkify(unlock: str) -> str:
        out = _esc(unlock)
        for kw, href in LINKS.items():
            if kw.lower() in unlock.lower():
                return f"[{out}]({href})"
        return out

    # ---- Part 1: summon-count ladder (admonition) ----
    ladder_bits = [f"**{base}** on a fresh character"]
    for cap, unlock in gates:
        ladder_bits.append(f"**{cap}** once you {_linkify(unlock)}")
    ladder = (
        '!!! info "How many trusts you can field at once"\n'
        "    Every trust is learnable from day 1 — the ladder below caps how many "
        "you can summon *simultaneously*. It is consecutive: you earn each slot in "
        "order. Your allies earn your allies.\n\n"
        "    " + " · ".join(ladder_bits) + ".\n\n"
        "    _Config: `trust_progression_cap.lua`._"
    )

    # ---- Part 2: locked custom trusts (crosswalk table) ----
    rows = "\n".join(
        f"| **{_esc(t['name'])}** | {_esc(t['client'])} (spell {t['spellId']}) "
        f"| Hunting League Rank {t['rank']} | {t['cost']:,} Hunt Marks |"
        for t in paid
    )
    lo_rank = min(t["rank"] for t in paid)
    hi_rank = max(t["rank"] for t in paid)
    locked = (
        f'??? note "Locked trusts — the {_esc(vendor)}\'s marquee allies"\n'
        f"    Three custom trusts aren\'t in the day-1 grant. The **{_esc(vendor)}** "
        f"in GM Home binds them one at a time, each gated behind a Hunting League "
        f"rank and paid for in Hunt Marks. They reuse retail spell slots, so in the "
        f"table below they show as their **client name** — casting that name is what "
        f"summons the custom trust.\n\n"
        "    | Trust | Cast in your menu as | Requires | Cost |\n"
        "    |---|---|---|---:|\n"
        + "\n".join("    " + r for r in rows.splitlines())
        + f"\n\n    _Ranks {lo_rank}–{hi_rank} track your `HL_Tier`; the marks come "
          f"from your `HL_Points` balance. Config: `trust_skoll.lua`._"
    )

    body = ladder + "\n\n" + locked

    page = docs_dir / "reference" / "spells" / "trust.md"
    if write_between_markers(page, "trust-tiers", body):
        print(f"[trust_tiers] filled: ladder {base}-{gates[-1][0]}, {len(paid)} locked trusts")
    else:
        print(f"[trust_tiers] skipped (markers not found in {page} — did spells run first?)")
