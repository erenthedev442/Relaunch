"""Generate the HNM King roster inside docs/progression/hnm.md.

Reads: modules/custom/lua/custom_HNM_system.lua (gitignored — normally
resolved via $LEGENDARY_LIVE_ROOT; CI without that env var skips cleanly).

The HNM module is not a data catalog; it's a sequence of `addOverride(...)`
calls. Three pieces of state are recovered per NM:

  * Zone aliases:  `local <alias>ID = zones[xi.zone.<ZONE>]`
  * NQ + respawn:  each `...mobs.<Mob>.onMobDespawn` body holds
                   `local randomPopTime = <MIN> + math.random(0, <STEPS>) * 1800`
                   -> window = [MIN .. MIN + STEPS*1800] seconds.
  * HQ + pop item: each `...npcs.<qm>.onTrade` body holds
                   `popFromQM(player, npc, <alias>ID.mob.<HQ>)` and
                   `tradeHasExactly(trade, xi.item.<ITEM>)`.

NQ and HQ are paired by shared zone. NMs with an HQ partner are "Kings"
(NQ/HQ pairs); NMs without one are lower-tier HNMs (timed-only).

Marker IDs (docs/progression/hnm.md):
  - "hnm-kings" — NQ/HQ King roster (zone, NQ, HQ, pop item, respawn window)
  - "hnm-lower" — lower-tier HNM roster (NM, zone, respawn window)
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers


# ---------------------------------------------------------------------------
# Lua helpers (copied from the established generator template)
# ---------------------------------------------------------------------------

# Captures a Lua string literal in single OR double quotes.
_QUOTED = r"(?:'((?:[^'\\]|\\.)*)'|\"([^\"]*)\")"


def _quoted_value(m: re.Match) -> str:
    raw = m.group(1) if m.group(1) is not None else m.group(2)
    return raw.replace("\\'", "'").replace('\\"', '"').replace("\\\\", "\\")


def _balanced_blocks(text: str):
    """Yield (start, end_exclusive) for each top-level {...} block in text.

    Handles nested braces, Lua `--` line comments, and both single- and
    double-quoted strings (with backslash escapes)."""
    depth = 0
    start = None
    i = 0
    n = len(text)
    while i < n:
        c = text[i]
        if c == "-" and i + 1 < n and text[i + 1] == "-":
            nl = text.find("\n", i)
            if nl == -1:
                break
            i = nl + 1
            continue
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
# Source parsing
# ---------------------------------------------------------------------------

# `local <alias>ID = zones[xi.zone.<ZONE>]`
_ZONE_ALIAS_RE = re.compile(
    r"\blocal\s+(\w+?)ID\s*=\s*zones\[\s*xi\.zone\.(\w+)\s*\]"
)

# `hnmSystem:addOverride('xi.zones.<Zone>.mobs.<Mob>.onMobDespawn', function(mob)`
_DESPAWN_RE = re.compile(
    r"addOverride\(\s*'xi\.zones\.(\w+)\.mobs\.(\w+)\.onMobDespawn'"
)

# `local randomPopTime = <MIN> + math.random(0, <STEPS>) * 1800`
_POPTIME_RE = re.compile(
    r"randomPopTime\s*=\s*(\d+)\s*\+\s*math\.random\(\s*0\s*,\s*(\d+)\s*\)\s*\*\s*(\d+)"
)

# `...addOverride('xi.zones.<Zone>.npcs.<qm>.onTrade', function(player, npc, trade)`
_ONTRADE_RE = re.compile(
    r"addOverride\(\s*'xi\.zones\.(\w+)\.npcs\.(\w+)\.onTrade'"
)

# `popFromQM(player, npc, <alias>ID.mob.<HQ>)`
_POPFROMQM_RE = re.compile(r"popFromQM\([^)]*?\.mob\.(\w+)\s*\)")

# `tradeHasExactly(trade, xi.item.<ITEM>)`
_TRADEITEM_RE = re.compile(r"tradeHasExactly\([^,]*,\s*xi\.item\.(\w+)\s*\)")


def _titleize(token: str) -> str:
    """FAFNIR / King_Behemoth / VALLEY_OF_SORROWS -> Fafnir / King Behemoth / Valley Of Sorrows."""
    words = token.replace("_", " ").split()
    out = []
    for w in words:
        # Already mixed-case (e.g. "King") -> leave as-is; ALLCAPS -> Title.
        out.append(w if (not w.isupper() and not w.islower()) else w.capitalize())
    return " ".join(out)


# A few zone tokens whose title-cased form needs small-word fixups so they
# read naturally (apostrophes/possessives aren't in the enum names).
_ZONE_PRETTY = {
    "DRAGONS_AERY": "Dragon's Aery",
    "VALLEY_OF_SORROWS": "Valley of Sorrows",
    "BEHEMOTHS_DOMINION": "Behemoth's Dominion",
    "SAUROMUGUE_CHAMPAIGN": "Sauromugue Champaign",
    "ROLANBERRY_FIELDS": "Rolanberry Fields",
    "GARLAIGE_CITADEL": "Garlaige Citadel",
    "JUGNER_FOREST": "Jugner Forest",
    "EAST_SARUTABARUTA": "East Sarutabaruta",
}

# Item-name fixups for trade items (lower-case connectives).
_SMALL_WORDS = {"Of", "The", "A"}


def _pretty_item(token: str) -> str:
    words = _titleize(token).split()
    out = []
    for idx, w in enumerate(words):
        if idx > 0 and w in _SMALL_WORDS:
            out.append(w.lower())
        else:
            out.append(w)
    return " ".join(out)


def _zone_name(zone_token: str) -> str:
    return _ZONE_PRETTY.get(zone_token, _titleize(zone_token))


def _fmt_hours(seconds: int) -> str:
    """Render seconds as a compact hours string (integer when whole)."""
    hours = seconds / 3600.0
    if abs(hours - round(hours)) < 1e-9:
        return str(int(round(hours)))
    return f"{hours:g}"


def _window(min_s: int, steps: int, step_s: int) -> tuple[int, int]:
    """Return (min_seconds, max_seconds) for MIN + random(0,STEPS)*step_s."""
    return min_s, min_s + steps * step_s


def parse(text: str) -> dict:
    """Parse the HNM module into structured NM records.

    Returns dict with:
      kings: [{zone, zone_token, nq, hq, hq_item, win_min, win_max}]
      lower: [{nm, zone, zone_token, win_min, win_max}]
      king_window: (min_s, max_s) | None   (common King window, if uniform)
    """
    # 1) Zone alias -> zone token (e.g. "valleySorrows" -> "VALLEY_OF_SORROWS").
    alias_to_zone = {}
    for m in _ZONE_ALIAS_RE.finditer(text):
        alias_to_zone[m.group(1)] = m.group(2)

    # 2) NQ mobs + respawn windows, keyed by (Zone path token from override).
    #    Walk each onMobDespawn override and read the next randomPopTime.
    nq_by_zone = {}  # zone_token -> {nm, win_min, win_max}
    for dm in _DESPAWN_RE.finditer(text):
        zone_token_path = dm.group(1)          # e.g. "Valley_of_Sorrows"
        mob = dm.group(2)                       # e.g. "Adamantoise"
        tail = text[dm.end(): dm.end() + 600]   # respawn line is a few lines down
        pm = _POPTIME_RE.search(tail)
        if not pm:
            continue
        win_min, win_max = _window(int(pm.group(1)), int(pm.group(2)), int(pm.group(3)))
        zkey = zone_token_path.upper()
        nq_by_zone[zkey] = {
            "nm": _titleize(mob),
            "win_min": win_min,
            "win_max": win_max,
        }

    # 3) HQ mobs + pop item, keyed by zone. The onTrade override path gives the
    #    zone; popFromQM gives the HQ mob; tradeHasExactly gives the item.
    hq_by_zone = {}  # zone_token (UPPER) -> {hq, hq_item}
    onTrade_starts = [m.start() for m in _ONTRADE_RE.finditer(text)]
    for tm in _ONTRADE_RE.finditer(text):
        zone_token_path = tm.group(1)
        # Isolate this onTrade's body: the first balanced {...} after the match,
        # which is the `if ... then ... end`? No — the override body is a
        # function, not a brace block. Read a bounded window instead and stop at
        # the next addOverride to avoid bleeding into the following handler.
        start = tm.end()
        next_starts = [s for s in onTrade_starts if s > tm.start()]
        end = min(next_starts) if next_starts else len(text)
        # Also clamp on the next despawn override if one comes first.
        body = text[start:end]
        pq = _POPFROMQM_RE.search(body)
        ti = _TRADEITEM_RE.search(body)
        if not pq:
            continue
        zkey = zone_token_path.upper()
        hq_by_zone[zkey] = {
            "hq": _titleize(pq.group(1)),
            "hq_item": _pretty_item(ti.group(1)) if ti else None,
        }

    # 4) Resolve a display zone name per zone token. The override path token
    #    ("Valley_of_Sorrows") upper-cases to the enum token
    #    ("VALLEY_OF_SORROWS"), which keys _ZONE_PRETTY.
    kings = []
    lower = []
    all_zone_keys = list(nq_by_zone.keys())
    for zkey in all_zone_keys:
        nq = nq_by_zone[zkey]
        zone_disp = _zone_name(zkey)
        hq = hq_by_zone.get(zkey)
        if hq:
            kings.append({
                "zone": zone_disp,
                "zone_token": zkey,
                "nq": nq["nm"],
                "hq": hq["hq"],
                "hq_item": hq["hq_item"],
                "win_min": nq["win_min"],
                "win_max": nq["win_max"],
            })
        else:
            lower.append({
                "nm": nq["nm"],
                "zone": zone_disp,
                "zone_token": zkey,
                "win_min": nq["win_min"],
                "win_max": nq["win_max"],
            })

    # Stable ordering: Kings in source/zone order, lower-tier by ascending
    # min window then name (newer players read shortest first).
    lower.sort(key=lambda r: (r["win_min"], r["nm"]))

    # 5) Common King window, if all Kings share one (they do in the live file).
    king_window = None
    if kings:
        wins = {(k["win_min"], k["win_max"]) for k in kings}
        if len(wins) == 1:
            king_window = next(iter(wins))

    return {"kings": kings, "lower": lower, "king_window": king_window}


# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------

def _esc(s: str) -> str:
    return s.replace("|", "\\|")


def _window_str(win_min: int, win_max: int) -> str:
    return f"{_fmt_hours(win_min)}–{_fmt_hours(win_max)} h"


def _render_kings(kings: list[dict]) -> str:
    if not kings:
        return "_No HNM Kings parsed from the source._"
    lines = [
        "| Zone | NQ King | HQ King | HQ pop item | Respawn window |",
        "|---|---|---|---|---|",
    ]
    for k in kings:
        item = k["hq_item"] or "—"
        lines.append(
            f"| {_esc(k['zone'])} | **{_esc(k['nq'])}** | **{_esc(k['hq'])}** | "
            f"{_esc(item)} | {_window_str(k['win_min'], k['win_max'])} |"
        )
    return "\n".join(lines)


def _render_lower(lower: list[dict]) -> str:
    if not lower:
        return "_No lower-tier HNMs parsed from the source._"
    lines = [
        "| NM | Zone | Respawn window |",
        "|---|---|---|",
    ]
    for r in lower:
        lines.append(
            f"| **{_esc(r['nm'])}** | {_esc(r['zone'])} | "
            f"{_window_str(r['win_min'], r['win_max'])} |"
        )
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/custom_HNM_system.lua")
    if src is None:
        print("[hnm] skip: custom_HNM_system.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")

    page = docs_dir / "progression" / "hnm.md"
    if not page.exists():
        print(f"[hnm] skip: target page {page} not found")
        return

    data = parse(text)
    kings = data["kings"]
    lower = data["lower"]

    # Guard against a silent parse regression. The source unmistakably has
    # onMobDespawn handlers with respawn formulas; if we recovered nothing,
    # a field/pattern changed — keep the published tables rather than wiping
    # them with an "_No ... parsed_" placeholder.
    despawn_signals = len(_DESPAWN_RE.findall(text))
    if despawn_signals > 0 and not (kings or lower):
        print(
            f"[hnm] PARSER REGRESSION: {despawn_signals} onMobDespawn overrides "
            f"in source but parse() returned no NMs. Patterns likely changed — "
            f"keeping existing published content."
        )
        return

    wrote_any = False

    if write_between_markers(page, "hnm-kings", _render_kings(kings)):
        wrote_any = True
    else:
        print("[hnm] hnm-kings: marker not found in hnm.md")

    if write_between_markers(page, "hnm-lower", _render_lower(lower)):
        wrote_any = True
    else:
        print("[hnm] hnm-lower: marker not found in hnm.md")

    if wrote_any:
        kw = data["king_window"]
        kw_str = _window_str(*kw) if kw else "n/a"
        print(
            f"[hnm] wrote {len(kings)} Kings (window {kw_str}) + "
            f"{len(lower)} lower-tier HNMs into hnm.md"
        )
