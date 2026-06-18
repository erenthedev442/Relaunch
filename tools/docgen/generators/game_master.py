"""Generate Game Master NPC reference tables inside docs/progression/game-master.md.

Reads: modules/custom/lua/game_master_catalog.lua

Marker IDs:
  - "game-master-difficulty"  -- difficulty tiers table
  - "game-master-mob-roster"  -- mob roster per difficulty table
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers

# ---------------------------------------------------------------------------
# Lua helpers (duplicated per the established pattern)
# ---------------------------------------------------------------------------

_QUOTED = r"""'(?:[^'\\]|\\.)*'|"(?:[^"\\]|\\.)*" """


def _quoted_value(s: str) -> str:
    s = s.strip()
    if (s.startswith("'") and s.endswith("'")) or (s.startswith('"') and s.endswith('"')):
        return s[1:-1]
    return s


def _balanced_blocks(text: str):
    """Yield (start, end) character offsets for every top-level {...} block."""
    depth = 0
    in_single = False
    in_double = False
    start = -1
    i = 0
    while i < len(text):
        c = text[i]
        if not in_single and not in_double and text[i:i+2] == '--':
            end_of_line = text.find('\n', i)
            i = end_of_line + 1 if end_of_line != -1 else len(text)
            continue
        if c == "'" and not in_double:
            in_single = not in_single
        elif c == '"' and not in_single:
            in_double = not in_double
        elif not in_single and not in_double:
            if c == '{':
                if depth == 0:
                    start = i
                depth += 1
            elif c == '}':
                depth -= 1
                if depth == 0 and start != -1:
                    yield (start, i + 1)
                    start = -1
        i += 1


# ---------------------------------------------------------------------------
# Parsers
# ---------------------------------------------------------------------------

def _parse_difficulty_order(text: str) -> list[str]:
    m = re.search(r'\bdifficultyOrder\s*=\s*\{', text)
    if not m:
        return []
    for start, end in _balanced_blocks(text[m.start():]):
        block = text[m.start():][start:end]
        return [_quoted_value(q) for q in re.findall(_QUOTED, block)]
    return []


def _parse_difficulty(text: str, name: str) -> dict | None:
    """Parse a single named difficulty block like 'Easy = { ... }'."""
    m = re.search(rf'\b{re.escape(name)}\s*=\s*\{{', text)
    if not m:
        return None

    for start, end in _balanced_blocks(text[m.start():]):
        block = text[m.start():][start:end]

        def _int(key: str) -> int | None:
            km = re.search(rf'\b{re.escape(key)}\s*=\s*(-?\d+)', block)
            return int(km.group(1)) if km else None

        def _float(key: str) -> float | None:
            km = re.search(rf'\b{re.escape(key)}\s*=\s*(\d+(?:\.\d+)?)', block)
            return float(km.group(1)) if km else None

        waves       = _int("wavesTotal")
        mobs_pw     = _int("mobsPerWave")
        wave_delay  = _int("waveDelay")
        comp_bonus  = _int("completionBonus")
        mark_bonus  = _int("markBonus")
        hp_boost    = _float("hpBoost")

        # Parse mobs sub-array
        mobs_m = re.search(r'\bmobs\s*=\s*\{', block)
        mobs = []
        if mobs_m:
            for ms, me in _balanced_blocks(block[mobs_m.start():]):
                mobs_block = block[mobs_m.start():][ms:me]
                for em in re.finditer(
                    r'\{\s*groupId\s*=\s*\d+\s*,\s*name\s*=\s*(' + _QUOTED + r')\s*\}',
                    mobs_block
                ):
                    raw_name = _quoted_value(em.group(1).strip())
                    mobs.append(raw_name.replace("_", " "))
                break

        return {
            "name":           name,
            "wavesTotal":     waves,
            "mobsPerWave":    mobs_pw,
            "waveDelay":      wave_delay,
            "completionBonus": comp_bonus,
            "markBonus":      mark_bonus,
            "hpBoost":        hp_boost,
            "mobs":           mobs,
        }
    return None


# ---------------------------------------------------------------------------
# Renderers
# ---------------------------------------------------------------------------

def _render_difficulty_table(difficulties: list[dict]) -> str:
    lines = [
        "| Difficulty | Waves | Mobs/wave | Wave delay | Per-kill bonus | Completion bonus |",
        "|---|---:|---:|---:|---:|---:|",
    ]
    for d in difficulties:
        waves      = d["wavesTotal"]      if d["wavesTotal"]      is not None else "?"
        mobs_pw    = d["mobsPerWave"]     if d["mobsPerWave"]      is not None else "?"
        delay      = f"{d['waveDelay']}s" if d["waveDelay"]        is not None else "?"
        per_kill   = f"+{d['markBonus']} marks"       if d["markBonus"]       is not None else "?"
        completion = f"**+{d['completionBonus']} marks**" if d["completionBonus"] is not None else "?"
        lines.append(
            f"| {d['name']} | {waves} | {mobs_pw} | {delay} | {per_kill} | {completion} |"
        )
    return "\n".join(lines)


def _render_mob_roster(difficulties: list[dict]) -> str:
    lines = [
        "| Difficulty | Mobs in the pool |",
        "|---|---|",
    ]
    for d in difficulties:
        mob_list = ", ".join(d["mobs"]) if d["mobs"] else "—"
        lines.append(f"| {d['name']} | {mob_list} |")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/game_master_catalog.lua")
    if src is None:
        print("[game_master] skip: game_master_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")

    page = docs_dir / "progression" / "game-master.md"
    if not page.exists():
        print(f"[game_master] skip: target page {page} not found")
        return

    order = _parse_difficulty_order(text)
    if not order:
        print("[game_master] warning: could not parse difficultyOrder; no output written")
        return

    difficulties = []
    for name in order:
        d = _parse_difficulty(text, name)
        if d:
            difficulties.append(d)
        else:
            print(f"[game_master] warning: could not parse difficulty '{name}'")

    if not difficulties:
        print("[game_master] warning: no difficulties parsed; no output written")
        return

    # --- difficulty table ---
    diff_content = _render_difficulty_table(difficulties)
    wrote = write_between_markers(page, "game-master-difficulty", diff_content)
    if wrote:
        print(f"[game_master] difficulty: {len(difficulties)} tiers written into marker")
    else:
        print(f"[game_master] difficulty: marker 'game-master-difficulty' not found in {page.name}")

    # --- mob roster ---
    roster_content = _render_mob_roster(difficulties)
    wrote = write_between_markers(page, "game-master-mob-roster", roster_content)
    if wrote:
        print("[game_master] mob-roster: written into marker")
    else:
        print(f"[game_master] mob-roster: marker 'game-master-mob-roster' not found in {page.name}")
