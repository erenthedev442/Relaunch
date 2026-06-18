"""Generate the personal-achievement milestone tables in
docs/progression/achievements.md.

Reads `modules/custom/lua/achievements.lua` and emits a single marker block:
  - "achievements-tables" — one table per category (Hunting / Tier / Lifetime
    Marks / Dungeon Infamy / Dungeon Clears / Wave Fights / Prestige
    Ascensions / Augment Trades).

The source is normally gitignored (modules/custom/ is not committed), so this
generator usually runs against `$LEGENDARY_LIVE_ROOT`. CI without that env var
will skip cleanly.

Two things are parsed and joined on the milestone id:
  1. The flat `local MILESTONES = { {...}, ... }` table — reward / title /
     desc / optional titleName, keyed by `id`.
  2. The per-hook threshold conditions like
        if totalKills == 100 then award(player, MILESTONE_BY_ID['CENTURY'])
     which give each milestone its category (from the hook + threshold var)
     and its numeric trigger (the `== N` / `>= N` before the award call).
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers


# Captures a Lua string literal in single OR double quotes, handling backslash
# escapes inside single-quoted strings (e.g. 'Epona\'s Ring').
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
        # Lua line comment: skip to end of line. (Doesn't handle Lua's long
        # comments `--[[ ... ]]` — none in the source.)
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
# Parsing
# ---------------------------------------------------------------------------

_ROMAN = {2: "II", 3: "III", 4: "IV", 5: "V"}


def _extract_milestones(text: str) -> dict:
    """Parse the flat MILESTONES table into {id: {reward,title,desc,titleName,
    announce}}."""
    m = re.search(r"\bMILESTONES\s*=\s*", text)
    if not m:
        return {}
    remaining = text[m.end():]
    outer = next(_balanced_blocks(remaining), None)
    if outer is None:
        return {}
    block = remaining[outer[0] + 1: outer[1] - 1]

    id_re = re.compile(r"\bid\s*=\s*" + _QUOTED)
    title_re = re.compile(r"\btitle\s*=\s*" + _QUOTED)
    desc_re = re.compile(r"\bdesc\s*=\s*" + _QUOTED)
    titlename_re = re.compile(r"\btitleName\s*=\s*" + _QUOTED)
    reward_re = re.compile(r"\breward\s*=\s*(\d+)")
    announce_re = re.compile(r"\bannounce\s*=\s*(true|false)")

    out = {}
    for s, e in _balanced_blocks(block):
        body = block[s + 1: e - 1]
        idm = id_re.search(body)
        if not idm:
            continue
        mid = _quoted_value(idm)
        title = title_re.search(body)
        desc = desc_re.search(body)
        reward = reward_re.search(body)
        tn = titlename_re.search(body)
        announce = announce_re.search(body)
        out[mid] = {
            "id": mid,
            "title": _quoted_value(title) if title else mid,
            "desc": _quoted_value(desc) if desc else "",
            "reward": int(reward.group(1)) if reward else 0,
            "titleName": _quoted_value(tn) if tn else None,
            "announce": (announce.group(1) == "true") if announce else False,
        }
    return out


# A hook condition such as:
#   if totalKills == 100  then award(player, MILESTONE_BY_ID['CENTURY'])
#   if tierNum == 2 then award(player, MILESTONE_BY_ID['TIER2_FIRST']) end
# Captures: threshold var, operator, number, milestone id.
#   group 1 = var, group 2 = op, group 3 = number, groups 4/5 = quoted id
#   (the two capture groups inside _QUOTED land at 4/5 because three groups
#   precede them — so read the id from those, NOT via _quoted_value()).
_AWARD_RE = re.compile(
    r"\b([A-Za-z_]\w*)\s*(==|>=)\s*(\d+)\b"          # var OP number
    r"[\s\S]*?award\s*\(\s*player\s*,\s*"            # ... award(player,  (may
                                                     # span a newline for a
                                                     # multi-line compound `if`)
    r"MILESTONE_BY_ID\s*\[\s*" + _QUOTED + r"\s*\]"  # MILESTONE_BY_ID['ID']
)


def _award_match(m: re.Match) -> dict:
    """Decode an _AWARD_RE match into {var, op, num, id}."""
    raw_id = m.group(4) if m.group(4) is not None else m.group(5)
    mid = raw_id.replace("\\'", "'").replace('\\"', '"').replace("\\\\", "\\")
    return {"var": m.group(1), "op": m.group(2), "num": int(m.group(3)), "id": mid}

# Categories keyed by (function name). For onHLKill the threshold variable
# further splits the rows into three sub-categories.
_FUNC_CATEGORY = {
    "onDungeonClear": "Dungeon Infamy",
    "onDungeonCount": "Dungeon Clears",
    "onWaveClear": "Wave Fights",
    "onAscension": "Prestige Ascensions",
    "onAugmentTrade": "Augment Trades",
}
_HLKILL_VAR_CATEGORY = {
    "totalKills": "Hunting Milestones",
    "tierNum": "Tier Milestones",
    "lifetimeMarks": "Lifetime Marks",
}

# Stable render order.
_CATEGORY_ORDER = [
    "Hunting Milestones",
    "Tier Milestones",
    "Lifetime Marks",
    "Dungeon Infamy",
    "Dungeon Clears",
    "Wave Fights",
    "Prestige Ascensions",
    "Augment Trades",
]


def _function_bodies(text: str) -> dict:
    """Return {function_name: body_text} for each `function M.<name>(...)` ...
    `end` block. Uses brace-free top-level `end` matching by tracking the Lua
    block keywords is overkill here; instead we slice from one `function M.`
    header to the next (the file defines them sequentially)."""
    headers = list(re.finditer(r"\bfunction\s+M\.(\w+)\s*\(", text))
    bodies = {}
    for i, h in enumerate(headers):
        name = h.group(1)
        start = h.end()
        end = headers[i + 1].start() if i + 1 < len(headers) else len(text)
        bodies[name] = text[start:end]
    return bodies


def _ordinal_suffix(n: int) -> str:
    if 11 <= (n % 100) <= 13:
        return "th"
    return {1: "st", 2: "nd", 3: "rd"}.get(n % 10, "th")


def _trigger_label(category: str, var: str, op: str, num: int) -> str:
    """Human-readable trigger string for a row."""
    if category == "Tier Milestones":
        roman = _ROMAN.get(num, str(num))
        return f"First Tier {roman} kill"
    if category == "Hunting Milestones":
        return f"{num:,}{_ordinal_suffix(num)} HL kill"
    if category == "Lifetime Marks":
        return f"{num:,} lifetime marks"
    if category == "Dungeon Infamy":
        return f"{num:,} lifetime Infamy"
    if category == "Dungeon Clears":
        return f"{num:,}{_ordinal_suffix(num)} dungeon clear"
    if category == "Wave Fights":
        return f"{num:,}{_ordinal_suffix(num)} wave fight"
    if category == "Prestige Ascensions":
        return f"{num:,}{_ordinal_suffix(num)} ascension"
    if category == "Augment Trades":
        return f"{num:,} lifetime augments"
    return f"{var} {op} {num}"


def _extract_rows(text: str) -> dict:
    """Parse hook bodies into {category: [ {id, var, op, num} ... ]} preserving
    source order within each category."""
    rows = {c: [] for c in _CATEGORY_ORDER}
    for fname, body in _function_bodies(text).items():
        if fname == "onHLKill":
            for m in _AWARD_RE.finditer(body):
                a = _award_match(m)
                cat = _HLKILL_VAR_CATEGORY.get(a["var"])
                if cat:
                    rows[cat].append(a)
        elif fname in _FUNC_CATEGORY:
            cat = _FUNC_CATEGORY[fname]
            for m in _AWARD_RE.finditer(body):
                rows[cat].append(_award_match(m))
    return rows


# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------

_INTROS = {
    "Hunting Milestones": "Trigger based on your total Hunting League NM kill count.",
    "Tier Milestones": "Trigger the first time you kill an NM from each tier.",
    "Lifetime Marks": "Trigger when your cumulative earned Hunt Marks cross a threshold (spending marks does not reduce the lifetime total).",
    "Dungeon Infamy": "Trigger based on your cumulative Dungeon Infamy across all clears.",
    "Dungeon Clears": "Trigger based on your total number of dungeon clears (separate from the Infamy milestones).",
    "Wave Fights": "Trigger based on your total number of wave-fight clears.",
    "Prestige Ascensions": "Trigger based on your total number of Prestige ascensions.",
    "Augment Trades": "Trigger based on your total number of augmentation trades.",
}


def _escape_md(s: str) -> str:
    return s.replace("|", "\\|").replace("\n", " ")


def _render(rows: dict, milestones: dict) -> str:
    out = []
    first = True
    for cat in _CATEGORY_ORDER:
        catrows = rows.get(cat) or []
        if not catrows:
            continue
        if not first:
            out.append("")
            out.append("---")
            out.append("")
        first = False
        out.append(f"## {cat}")
        out.append("")
        intro = _INTROS.get(cat)
        if intro:
            out.append(intro)
            out.append("")
        out.append("| Milestone | Trigger | Reward | Title Unlock |")
        out.append("|---|---|---:|---|")
        for r in catrows:
            ms = milestones.get(r["id"], {})
            title = ms.get("title") or r["id"]
            reward = ms.get("reward", 0)
            tname = ms.get("titleName")
            trigger = _trigger_label(cat, r["var"], r["op"], r["num"])
            out.append(
                f"| {_escape_md(title)} | {_escape_md(trigger)} "
                f"| +{reward:,} | {_escape_md(tname) if tname else '—'} |"
            )
    return "\n".join(out).rstrip()


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/achievements.lua")
    if src is None:
        print("[achievements] skip: achievements.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")

    milestones = _extract_milestones(text)
    rows = _extract_rows(text)

    # Sanity guards mirroring hunting_league.py: if the source clearly has the
    # shapes we parse but we extracted nothing, a field/name probably changed.
    # Keep the existing published content rather than publishing an empty page.
    milestone_signals = len(re.findall(r"\bid\s*=\s*" + _QUOTED, text))
    if milestone_signals > 0 and not milestones:
        raise RuntimeError(
            f"achievements.lua has {milestone_signals} `id = '...'` signals but "
            f"_extract_milestones returned zero entries — the MILESTONES table "
            f"shape probably changed; update _extract_milestones."
        )

    award_signals = len(re.findall(r"MILESTONE_BY_ID\s*\[", text))
    total_rows = sum(len(v) for v in rows.values())
    if award_signals > 0 and total_rows == 0:
        raise RuntimeError(
            f"achievements.lua has {award_signals} MILESTONE_BY_ID[...] award "
            f"sites but _extract_rows returned zero threshold rows — the hook "
            f"condition shape probably changed; update _AWARD_RE / "
            f"_function_bodies."
        )

    content = _render(rows, milestones)

    page = docs_dir / "progression" / "achievements.md"
    wrote = write_between_markers(page, "achievements-tables", content)
    if not wrote:
        print(f"[achievements] skipped (markers not found in {page.name})")
        return

    per_cat = ", ".join(
        f"{c}={len(rows[c])}" for c in _CATEGORY_ORDER if rows[c]
    )
    print(
        f"[achievements] wrote {total_rows} milestone rows "
        f"({len(milestones)} defined) — {per_cat}"
    )
