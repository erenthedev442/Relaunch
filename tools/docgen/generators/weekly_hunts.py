"""Generate the Weekly Hunt Board page from the live catalog.

Reads `modules/custom/lua/weekly_hunts_catalog.lua` and emits an
objective-pool table + reward summary into
`docs/progression/weekly-hunts.md`.

Marker IDs:
  - "weekly-hunts-pool"   — every objective in the pool with target + reward
  - "weekly-hunts-config" — slots-per-week, all-cleared bonus

Catalog is normally gitignored so this generator runs against
`$LEGENDARY_LIVE_ROOT`. CI without that skips cleanly.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers


_QUOTED = r"(?:'((?:[^'\\]|\\.)*)'|\"([^\"]*)\")"


def _quoted_value(m: re.Match) -> str:
    raw = m.group(1) if m.group(1) is not None else m.group(2)
    return raw.replace("\\'", "'").replace('\\"', '"').replace("\\\\", "\\")


def _balanced_blocks(text: str):
    """Iterate top-level {...} blocks in `text`. Handles nested braces,
    Lua line comments, and quoted strings. Copied from hunting_league.py
    and accessories_npc.py — same shape, same caveats."""
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


_ID_RE       = re.compile(r"\bid\s*=\s*" + _QUOTED)
_LABEL_RE    = re.compile(r"\blabel\s*=\s*" + _QUOTED)
_DESC_RE     = re.compile(r"\bdescription\s*=\s*" + _QUOTED)
_TARGET_RE   = re.compile(r"\btarget\s*=\s*(\d+)")
_EVENT_RE    = re.compile(r"\beventType\s*=\s*" + _QUOTED)

# Reward shape: { currency = '<X>', amount = N }
_REWARD_CURRENCY_RE = re.compile(
    r"\breward\s*=\s*\{[^}]*?currency\s*=\s*" + _QUOTED,
    re.DOTALL,
)
_REWARD_AMOUNT_RE = re.compile(
    r"\breward\s*=\s*\{[^}]*?amount\s*=\s*(\d+)",
    re.DOTALL,
)

# Slots + all-cleared bonus
_SLOTS_RE = re.compile(r"\bslotsPerWeek\s*=\s*(\d+)")
_ACR_CURRENCY_RE = re.compile(
    r"\ballClearedReward\s*=\s*\{[^}]*?currency\s*=\s*" + _QUOTED,
    re.DOTALL,
)
_ACR_AMOUNT_RE = re.compile(
    r"\ballClearedReward\s*=\s*\{[^}]*?amount\s*=\s*(\d+)",
    re.DOTALL,
)

# Currency code → display name (mirrors catalog.currencyCv table)
_CURRENCY_DISPLAY = {
    "hl":    "Hunt Marks",
    "af":    "AF Marks",
    "relic": "Relic Marks",
    "empy":  "Empy Marks",
}

# Event type → short human description (so the page can show which system
# fires which objective without the player reading source).
_EVENT_SOURCE = {
    "nm_kill":       "Any NM kill (Hunting League + Reforge)",
    "guild_rankup":  "Hunter's Guild rank-up",
    "gm_wave_clear": "Game Master wave session complete",
    "augment_done":  "Successful augment at Augment Moogle",
}


def _extract_objectives(text: str) -> list[dict]:
    """Parse `objectivePool = { {...}, {...}, ... }`."""
    m = re.search(r"\bobjectivePool\s*=\s*", text)
    if not m:
        return []
    remaining = text[m.end():]
    outer = next(_balanced_blocks(remaining), None)
    if outer is None:
        return []
    inner = remaining[outer[0] + 1: outer[1] - 1]

    objectives: list[dict] = []
    for s, e in _balanced_blocks(inner):
        body = inner[s + 1: e - 1]
        id_m     = _ID_RE.search(body)
        label_m  = _LABEL_RE.search(body)
        desc_m   = _DESC_RE.search(body)
        target_m = _TARGET_RE.search(body)
        event_m  = _EVENT_RE.search(body)
        rcur_m   = _REWARD_CURRENCY_RE.search(body)
        ramt_m   = _REWARD_AMOUNT_RE.search(body)

        if not (label_m and target_m and event_m and rcur_m and ramt_m):
            continue
        objectives.append({
            "id":        _quoted_value(id_m) if id_m else "?",
            "label":     _quoted_value(label_m),
            "desc":      _quoted_value(desc_m) if desc_m else "",
            "target":    int(target_m.group(1)),
            "event":     _quoted_value(event_m),
            "reward_currency": _quoted_value(rcur_m),
            "reward_amount":   int(ramt_m.group(1)),
        })
    return objectives


def _escape_md(s: str) -> str:
    return s.replace("|", "\\|").replace("\n", " ")


def _render_pool(objectives: list[dict], slots: int) -> str:
    if not objectives:
        return "_No objectives parsed from the catalog._"
    lines = [
        f"_The pool has **{len(objectives)} objectives**. Each week, "
        f"**{slots}** are rolled randomly per player — your set may differ "
        "from your friends' sets._",
        "",
        "| Objective | Target | Source | Reward |",
        "|---|---:|---|---:|",
    ]
    for obj in objectives:
        currency_display = _CURRENCY_DISPLAY.get(
            obj["reward_currency"], obj["reward_currency"]
        )
        source = _EVENT_SOURCE.get(obj["event"], obj["event"])
        reward = f"{obj['reward_amount']:,} {currency_display}"
        # Description goes BELOW the row title to keep the table narrow.
        # Markdown table cells don't render multi-line gracefully, so
        # we inline it as a sub-line via <br>.
        title  = f"**{_escape_md(obj['label'])}**"
        if obj["desc"]:
            title = f"{title}<br><sub>{_escape_md(obj['desc'])}</sub>"
        lines.append(
            f"| {title} | {obj['target']} | {_escape_md(source)} | {reward} |"
        )
    return "\n".join(lines)


def _render_config(slots: int, ac_currency: str, ac_amount: int) -> str:
    ac_display = _CURRENCY_DISPLAY.get(ac_currency, ac_currency)
    lines = [
        "| Setting | Value |",
        "|---|---|",
        f"| Objectives rolled per week | {slots} |",
        f"| Reset cadence | Every Monday 00:00 UTC (ISO week) |",
        f"| All-cleared bonus | **{ac_amount:,} {ac_display}** + lifetime sweep counter |",
        f"| Reset trigger | Lazy — first player interaction in a new week auto-rolls |",
    ]
    return "\n".join(lines)


def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/weekly_hunts_catalog.lua")
    if src is None:
        print("[weekly_hunts] skip: weekly_hunts_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    objectives = _extract_objectives(text)

    slots_m = _SLOTS_RE.search(text)
    slots = int(slots_m.group(1)) if slots_m else 5

    ac_cur_m = _ACR_CURRENCY_RE.search(text)
    ac_amt_m = _ACR_AMOUNT_RE.search(text)
    ac_cur = _quoted_value(ac_cur_m) if ac_cur_m else "hl"
    ac_amt = int(ac_amt_m.group(1)) if ac_amt_m else 0

    # Sanity check — if the catalog clearly has objectives but we got
    # zero, a field rename probably broke the parse. Raise so the page
    # keeps its previous content instead of publishing "_No objectives_".
    objective_signals = len(re.findall(r"\beventType\s*=", text))
    if objective_signals > 0 and not objectives:
        raise RuntimeError(
            f"weekly_hunts_catalog.lua has {objective_signals} eventType "
            f"entries but _extract_objectives returned zero. A required "
            f"field (id/label/target/eventType/reward) probably changed "
            f"name — update the regexes at the top of weekly_hunts.py."
        )

    page = docs_dir / "progression" / "weekly-hunts.md"
    if not page.exists():
        print(f"[weekly_hunts] skip: page not found ({page})")
        return

    pool_md = _render_pool(objectives, slots)
    if write_between_markers(page, "weekly-hunts-pool", pool_md):
        print(f"[weekly_hunts] pool: {len(objectives)} objectives written into marker")
    else:
        print(f"[weekly_hunts] pool: marker missing in {page.name}")

    cfg_md = _render_config(slots, ac_cur, ac_amt)
    if write_between_markers(page, "weekly-hunts-config", cfg_md):
        print(f"[weekly_hunts] config: written into marker")
    else:
        print(f"[weekly_hunts] config: marker missing in {page.name}")
