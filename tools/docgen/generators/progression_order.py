"""Generate the "Recommended progression order" numbered list inside
docs/progression/index.md.

Reads catalog Lua files from modules/custom/lua/ via resolve_source() and
emits a data-driven ordered list into the DOCGEN marker block:
  "progression-order"

All catalog sources are optional — if any file is missing (CI without
LEGENDARY_LIVE_ROOT), that data section falls back to a static description.
If ALL files are missing, the entire block is replaced with a single
fallback message.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers


# ---------------------------------------------------------------------------
# Lua string literal capture — single or double quoted, backslash-escaped
# ---------------------------------------------------------------------------
_QUOTED = r"(?:'((?:[^'\\]|\\.)*)'|\"([^\"]*)\")"


def _quoted_value(m: re.Match) -> str:
    raw = m.group(1) if m.group(1) is not None else m.group(2)
    return raw.replace("\\'", "'").replace('\\"', '"').replace("\\\\", "\\")


# ---------------------------------------------------------------------------
# Balanced-brace block iterator (copied from hunting_league.py)
# ---------------------------------------------------------------------------

def _balanced_blocks(text: str):
    """Yield (start, end_exclusive) for each top-level {...} block in text.

    Handles nested braces, Lua ``--`` line comments, and both single- and
    double-quoted strings (with backslash escapes)."""
    depth = 0
    start = None
    i = 0
    n = len(text)
    while i < n:
        c = text[i]
        # Lua line comment: skip to end of line.
        if c == "-" and i + 1 < n and text[i + 1] == "-":
            nl = text.find("\n", i)
            if nl == -1:
                break
            i = nl + 1
            continue
        # Quoted string: skip until matching close quote, respecting escapes
        if c == "'" or c == '"':
            quote = c
            i += 1
            while i < n:
                cc = text[i]
                if cc == "\\" and i + 1 < n:
                    i += 2
                    continue
                if cc == quote:
                    i += 1
                    break
                i += 1
            continue
        if c == "{":
            if depth == 0:
                start = i
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0 and start is not None:
                yield (start, i + 1)
                start = None
        i += 1


# ---------------------------------------------------------------------------
# Hunting League catalog parsing
# ---------------------------------------------------------------------------

def _parse_hl_tiers(text: str) -> list[dict]:
    """Return a list of tier dicts sorted by tier number.

    Each dict: {tier, name, unlockCost, mobs: [{name, label, points}]}
    """
    name_re = re.compile(r"\bname\s*=\s*" + _QUOTED)
    label_re = re.compile(r"\blabel\s*=\s*" + _QUOTED)

    m = re.search(r"\btiers\s*=\s*", text)
    if not m:
        return []
    remaining = text[m.end():]
    outer = next(_balanced_blocks(remaining), None)
    if outer is None:
        return []
    tiers_block = remaining[outer[0] + 1: outer[1] - 1]

    tiers = []
    for ts, te in _balanced_blocks(tiers_block):
        body = tiers_block[ts + 1: te - 1]
        tier_num = re.search(r"\btier\s*=\s*(\d+)", body)
        tier_name = name_re.search(body)
        unlock = re.search(r"\bunlockCost\s*=\s*(\d+)", body)
        if not (tier_num and tier_name and unlock):
            continue

        mobs = []
        mobs_match = re.search(r"\bmobs\s*=\s*", body)
        if mobs_match:
            mobs_remaining = body[mobs_match.end():]
            mobs_outer = next(_balanced_blocks(mobs_remaining), None)
            if mobs_outer is not None:
                mobs_inner = mobs_remaining[mobs_outer[0] + 1: mobs_outer[1] - 1]
                for ms, me in _balanced_blocks(mobs_inner):
                    mob_body = mobs_inner[ms + 1: me - 1]
                    nm = name_re.search(mob_body)
                    lbl = label_re.search(mob_body)
                    pts = re.search(r"\bpoints\s*=\s*(\d+)", mob_body)
                    if nm and lbl and pts:
                        mobs.append({
                            "name": _quoted_value(nm).replace("_", " "),
                            "label": _quoted_value(lbl),
                            "points": int(pts.group(1)),
                        })

        tiers.append({
            "tier": int(tier_num.group(1)),
            "name": _quoted_value(tier_name),
            "unlockCost": int(unlock.group(1)),
            "mobs": mobs,
        })
    tiers.sort(key=lambda t: t["tier"])
    return tiers


def _parse_hl_currency(text: str) -> str:
    m = re.search(r"\bcurrencyName\s*=\s*" + _QUOTED, text)
    if m:
        return _quoted_value(m)
    return "Hunt Marks"


def _parse_defending_ring_cost(text: str) -> int | None:
    """Return the cost of 'Defending Ring' from rewards, or None if not found."""
    m = re.search(r"Defending\s+Ring", text)
    if not m:
        return None
    # Find cost = N in the same brace block right after the name
    snippet = text[m.end(): m.end() + 200]
    c = re.search(r"\bcost\s*=\s*(\d+)", snippet)
    return int(c.group(1)) if c else None


# ---------------------------------------------------------------------------
# Game Master catalog parsing
# ---------------------------------------------------------------------------

def _parse_gm_difficulties(text: str) -> dict[str, dict]:
    """Return dict keyed by difficulty name with completionBonus and wavesTotal."""
    m = re.search(r"\bdifficulties\s*=\s*", text)
    if not m:
        return {}
    remaining = text[m.end():]
    outer = next(_balanced_blocks(remaining), None)
    if outer is None:
        return {}
    block = remaining[outer[0] + 1: outer[1] - 1]

    # Named keys: Easy = { ... }, Normal = { ... }, Hard = { ... }, Insane = { ... }
    result = {}
    for name in ("Easy", "Normal", "Hard", "Insane"):
        key_pat = re.compile(rf"\b{name}\s*=\s*")
        km = key_pat.search(block)
        if not km:
            continue
        sub = block[km.end():]
        inner = next(_balanced_blocks(sub), None)
        if inner is None:
            continue
        body = sub[inner[0] + 1: inner[1] - 1]
        bonus = re.search(r"\bcompletionBonus\s*=\s*(\d+)", body)
        waves = re.search(r"\bwavesTotal\s*=\s*(\d+)", body)
        result[name] = {
            "completionBonus": int(bonus.group(1)) if bonus else None,
            "wavesTotal": int(waves.group(1)) if waves else None,
        }
    return result


# ---------------------------------------------------------------------------
# Weekly hunts catalog parsing
# ---------------------------------------------------------------------------

def _parse_weekly_all_cleared(text: str) -> int | None:
    """Return the Hunt Marks amount for the all-cleared weekly reward."""
    # The catalog uses allClearedReward = { currency = 'hl', amount = N }
    m = re.search(r"\ballClearedReward\s*=\s*", text)
    if not m:
        # Fallback: look for a plain allClearedBonus field
        m2 = re.search(r"\ballClearedBonus\s*=\s*(\d+)", text)
        return int(m2.group(1)) if m2 else None
    sub = text[m.end():]
    inner = next(_balanced_blocks(sub), None)
    if inner is None:
        return None
    body = sub[inner[0] + 1: inner[1] - 1]
    am = re.search(r"\bamount\s*=\s*(\d+)", body)
    return int(am.group(1)) if am else None


# ---------------------------------------------------------------------------
# Content rendering
# ---------------------------------------------------------------------------

def _render(
    tiers: list[dict] | None,
    currency: str,
    defending_ring_cost: int | None,
    difficulties: dict | None,
    weekly_all_cleared: int | None,
) -> str:
    """Assemble the ordered-list markdown."""

    lines: list[str] = []

    # ---- Step 1: Visit GM Home ----------------------------------------
    lines.append(
        "1. **Orient yourself at the two main hubs.** The **Celennia Memorial Library** (`!lib`) "
        "is the economy hub — Hunt Board, Gil Exchange, Sparks Exchange, Race Changer, Home Point. "
        "**Leafallia** (`!leaf`) is the endgame hub — Apex Trials, Prime Armory, Colosseum, "
        "Infamy Vendor, Augment Sage, and the endgame NPC row. GM Home (`!gmhome`) still exists "
        "but only the Test Dummy remains there for DPS testing."
    )

    # ---- Step 2: Hit level 99 -----------------------------------------
    lines.append(
        "2. **Hit level 99.** Use FoV books, ROE, trust grinding, or EXP rings. "
        "With <!--setting:map.EXP_RATE-->3<!--/setting-->× mob EXP and "
        "<!--setting:main.EXP_RATE-->10<!--/setting-->× scripted EXP, "
        "expect an afternoon."
    )

    # ---- Step 3: Warp to Escha ZiTah -----------------------------
    lines.append(
        "3. **Warp to Escha ZiTah** with `!hunt`. "
        "The command drops you right at the Seals and Spawner NPCs. "
        "_(Without `!hunt` the zone is gated behind mid-Seekers progression — "
        "use the command.)_"
    )

    # ---- Step 4: Start Rank I -----------------------------------------
    if tiers:
        t1 = tiers[0]
        t2 = tiers[1] if len(tiers) > 1 else None
        mob_list = ", ".join(m["label"] for m in t1["mobs"]) if t1["mobs"] else "the starter NMs"
        per_kill = t1["mobs"][0]["points"] if t1["mobs"] else "?"
        unlock_next = (
            f"{t2['unlockCost']} {currency}" if t2 else f"the next rank"
        )
        lines.append(
            f"4. **Start {t1['name']}.** Pop any of the three NMs from the Spawner: "
            f"{mob_list}. Each kill pays **{per_kill} {currency}**. "
            f"Grind until you have **{unlock_next}** to unlock Rank II — "
            f"talk to the Seals NPC to advance."
        )
    else:
        lines.append(
            "4. **Start Rank I (Initiate).** Pop NMs from the Spawner, earn Hunt Marks "
            "per kill, and grind to the Rank II unlock threshold."
        )

    # ---- Step 5: Weekly Hunts -----------------------------------------
    weekly_note = ""
    if weekly_all_cleared is not None:
        weekly_note = (
            f" Sweeping all 5 objectives in a single week pays a **{weekly_all_cleared:,} "
            f"{currency}** meta-bonus on top of the per-objective rewards."
        )
    lines.append(
        "5. **Pick up Weekly Hunt objectives.** Visit the Weekly Hunt Board at the **Celennia "
        "Memorial Library** (`!lib`) or type `!weekly` for a status check. "
        f"Five random objectives roll fresh each Monday.{weekly_note} "
        "Completing these adds a big mark income boost alongside your regular NM grind."
    )

    # ---- Step 6: Push Ranks II–III ------------------------------------
    if tiers and len(tiers) >= 3:
        t2, t3 = tiers[1], tiers[2]
        lines.append(
            f"6. **Push through {t2['name']} and {t3['name']}.** "
            f"Rank II unlocks at **{t2['unlockCost']} {currency}** spent; "
            f"each kill pays **{t2['mobs'][0]['points']} {currency}** "
            f"({', '.join(m['label'] for m in t2['mobs'])}). "
            f"Rank III unlocks at **{t3['unlockCost']} {currency}** — "
            f"kills pay **{t3['mobs'][0]['points']} {currency}** "
            f"({', '.join(m['label'] for m in t3['mobs'])}). "
            "Use accumulated marks to buy core BiS accessories: "
            "Brutal Earring, Epona’s Ring, Rajas Ring, Suppanomimi, etc."
        )
    else:
        lines.append(
            "6. **Push through Ranks II–III.** Marks per kill increase each rank. "
            "Spend marks on core BiS accessories along the way."
        )

    # ---- Step 7: Game Master wave challenges --------------------------
    if difficulties and "Easy" in difficulties:
        easy = difficulties["Easy"]
        bonus_note = (
            f" Full clear pays **{easy['completionBonus']} {currency}**." if easy.get("completionBonus") else ""
        )
        waves_note = (
            f" {easy['wavesTotal']} waves," if easy.get("wavesTotal") else ""
        )
        lines.append(
            "7. **Try Game Master wave challenges in Escha Ru'Aun.** "
            f"Use `!wavemaster` to warp there and talk to the Game Master NPC. "
            f"Start with **Easy** difficulty:{waves_note} 1 mob per wave, manageable for a geared solo player.{bonus_note} "
            "Harder difficulties (Normal / Hard / Insane) pay progressively more marks "
            "and unlock tougher wave pools."
        )
    else:
        lines.append(
            "7. **Try Game Master wave challenges in Escha Ru'Aun (`!wavemaster`).** "
            "Start on Easy difficulty. Full clear pays bonus Hunt Marks. "
            "Harder difficulties pay more and pull from tougher mob pools."
        )

    # ---- Step 8: Ranks IV–V -------------------------------------------
    if tiers and len(tiers) >= 5:
        t4, t5 = tiers[3], tiers[4]
        dr_note = ""
        if defending_ring_cost is not None:
            dr_note = (
                f" Before unlocking Rank V, consider saving **{defending_ring_cost} {currency}** "
                "for the Defending Ring (−10% Damage Taken) — a premium tank/survivability item."
            )
        lines.append(
            f"8. **Unlock {t4['name']} and {t5['name']}.** "
            f"Rank IV costs **{t4['unlockCost']} {currency}** total spent; "
            f"kills pay **{t4['mobs'][0]['points']} {currency}** "
            f"({', '.join(m['label'] for m in t4['mobs'])}). "
            f"Rank V costs **{t5['unlockCost']} {currency}** total spent — "
            f"endgame kills pay **{t5['mobs'][0]['points']} {currency}** "
            f"({', '.join(m['label'] for m in t5['mobs'])}).{dr_note} "
            "Rank V is the gear-check wall. Bring a party."
        )
    else:
        lines.append(
            "8. **Unlock Ranks IV–V.** Rank V is the gear-check wall — "
            "Shinryu (Lv 225–250) is a real raid boss. Bring a party."
        )

    # ---- Step 9: Reforge track ----------------------------------------
    lines.append(
        "9. **Start the Reforge track.** Farm Sky Gods, Unity NMs, and Abyssea NMs "
        "for AF Marks, Relic Marks, and Empy Marks. "
        "These currencies feed the Reforge system to upgrade your AF/Relic/Empy armor "
        "to +1 / +2 / +3 tiers. "
        "Type `!huntrank` to check your current Hunting League rank and overall progress."
    )

    # ---- Step 10: Augmentation -----------------------------------------
    lines.append(
        "10. **Augment your gear.** Visit the **Augment Moogle in Leafallia** (`!leaf`) "
        "to add random stats to equipment. "
        "For passive endgame bonuses, earn enough Infamy to unlock the "
        "**Augment Sage** — also in Leafallia — Infamy comes from apex Reisenjima NMs, Scheduled "
        "Invasions, and the weekly Raid. "
        "The Sage applies permanent stat bonuses outside the normal augment RNG."
    )

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Public entrypoint
# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    page = docs_dir / "progression" / "index.md"

    # ---- Resolve sources -----------------------------------------------
    hl_src  = resolve_source(repo_root, "modules/custom/lua/hunting_league_catalog.lua")
    gm_src  = resolve_source(repo_root, "modules/custom/lua/game_master_catalog.lua")
    wh_src  = resolve_source(repo_root, "modules/custom/lua/weekly_hunts_catalog.lua")

    if not any([hl_src, gm_src, wh_src]):
        fallback = (
            "_Progression order temporarily unavailable — catalog data not found. "
            "Run with `LEGENDARY_LIVE_ROOT` set to regenerate._"
        )
        wrote = write_between_markers(page, "progression-order", fallback)
        if not wrote:
            print("[progression_order] skip: markers not found in index.md")
        else:
            print("[progression_order] wrote static fallback (no catalog sources found)")
        return

    # ---- Parse each source (graceful degradation per file) -------------
    tiers: list[dict] | None = None
    currency = "Hunt Marks"
    defending_ring_cost: int | None = None
    if hl_src:
        hl_text = hl_src.read_text(encoding="utf-8", errors="replace")
        tiers = _parse_hl_tiers(hl_text)
        currency = _parse_hl_currency(hl_text)
        defending_ring_cost = _parse_defending_ring_cost(hl_text)
        if not tiers:
            print("[progression_order] warning: HL tiers parsed as empty — check catalog field names")

    difficulties: dict | None = None
    if gm_src:
        gm_text = gm_src.read_text(encoding="utf-8", errors="replace")
        difficulties = _parse_gm_difficulties(gm_text)
        if not difficulties:
            print("[progression_order] warning: GM difficulties parsed as empty")

    weekly_all_cleared: int | None = None
    if wh_src:
        wh_text = wh_src.read_text(encoding="utf-8", errors="replace")
        weekly_all_cleared = _parse_weekly_all_cleared(wh_text)

    # ---- Render --------------------------------------------------------
    content = _render(tiers, currency, defending_ring_cost, difficulties, weekly_all_cleared)

    wrote = write_between_markers(page, "progression-order", content)
    if not wrote:
        print("[progression_order] skip: markers not found in docs/progression/index.md")
        return

    # ---- Summary -------------------------------------------------------
    tier_count = len(tiers) if tiers else 0
    diff_count = len(difficulties) if difficulties else 0
    print(
        f"[progression_order] wrote 10-step progression list — "
        f"{tier_count} HL ranks, {diff_count} GM difficulties, "
        f"weekly bonus={weekly_all_cleared} {currency}"
    )
