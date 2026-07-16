"""Generate Reforge System tables inside docs/progression/reforge.md.

Reads `modules/custom/lua/reforge_catalog.lua` and emits three marker
blocks:
  - "reforge-sources"   — NM pools, currencies, marks per kill
  - "reforge-costs"     — upgrade costs per tier (+1 / +2 / +3)
  - "reforge-job-sets"  — per-job armor set names (AF / Relic / Empyrean)

Set names come from the section header comments in the catalog:
    ---------- WAR  --  Pummeler's (AF) / Agoge (Relic) / Boii (Empyrean) ----------

The catalog is normally gitignored, so this generator runs against
`$LEGENDARY_LIVE_ROOT`. CI without that env var skips cleanly.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers


_QUOTED = r"(?:'((?:[^'\\]|\\.)*)'|\"([^\"]*)\")"

# Source pool block:  af = { ... mobs = { {...}, {...}, ... } ... }
_SOURCE_HEADER_RE = re.compile(
    r"(\baf\b|\brelic\b|\bempy\b)\s*=\s*\{",
)
_LABEL_RE = re.compile(r"\blabel\s*=\s*" + _QUOTED)
_CURRENCY_NAME_RE = re.compile(r"\bcurrencyName\s*=\s*" + _QUOTED)
_MARKS_RE = re.compile(r"\bmarks\s*=\s*(\d+)")
_MINLV_RE = re.compile(r"\bminLv\s*=\s*(\d+)")
_POWER_RE = re.compile(r"\bstatsFor\s*\(\s*(\d+)\s*\)")
_NAME_FIELD_RE = re.compile(r"\bname\s*=\s*" + _QUOTED)

# Upgrade costs:  af    = { plus1 = 100, plus2 = 300, plus3 = 1000 },
# The `(?:\w+\s*=\s*[^,}]+,\s*)*` between fields tolerates any extra fields
# the catalog grows over time (analog to the augments.py tolerant-fields
# pattern). _extract_costs() raises if the catalog clearly has cost rows
# but the regex matched zero -- prevents silent regressions.
_COST_LINE_RE = re.compile(
    r"(\baf\b|\brelic\b|\bempy\b)\s*=\s*\{\s*"
    r"(?:\w+\s*=\s*[^,}]+,\s*)*"
    r"plus1\s*=\s*(\d+)\s*,\s*"
    r"(?:\w+\s*=\s*[^,}]+,\s*)*"
    r"plus2\s*=\s*(\d+)\s*,\s*"
    r"(?:\w+\s*=\s*[^,}]+,\s*)*"
    r"plus3\s*=\s*(\d+)"
    r"(?:\s*,\s*\w+\s*=\s*[^,}]+)*"
    r"\s*\}"
)

# Job section header comments — set names per job:
#   -- ---------- WAR  --  Pummeler's (AF) / Agoge (Relic) / Boii (Empyrean) ----------
_JOB_HEADER_RE = re.compile(
    r"--\s*-+\s*([A-Z]{3})\s*--\s*"
    r"(.+?)\s*\(AF\)\s*/\s*"
    r"(.+?)\s*\(Relic\)\s*/\s*"
    r"(.+?)\s*\(Empyrean\)\s*-+",
)

_SOURCE_ORDER = ("af", "relic", "empy")
_SOURCE_LABEL = {
    "af":    "AF (Sky Gods)",
    "relic": "Relic (Unity NMs)",
    "empy":  "Empyrean (Abyssea NMs)",
}
_POWER_STEP = {150: "I", 175: "II", 200: "III", 225: "IV", 250: "V"}

# Job display order — matches the catalog's catalog.jobs ordering.
_JOB_ORDER = (
    "WAR", "MNK", "WHM", "BLM", "RDM", "THF", "PLD", "DRK",
    "BST", "BRD", "RNG", "SAM", "NIN", "DRG", "SMN", "BLU",
    "COR", "PUP", "DNC", "SCH", "GEO", "RUN",
)


def _quoted_value(m: re.Match) -> str:
    raw = m.group(1) if m.group(1) is not None else m.group(2)
    return raw.replace("\\'", "'").replace('\\"', '"').replace("\\\\", "\\")


def _balanced_blocks(text: str):
    """Yield (start, end_exclusive) for each top-level {...} block in text.

    Same shape as the helper in hunting_league.py: handles nested braces,
    Lua line comments, and quoted strings with escapes."""
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


def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/reforge_catalog.lua")
    if src is None:
        print("[reforge] skip: reforge_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    page = docs_dir / "progression" / "reforge.md"

    # Per-section build with sanity guards. If a parser silently returns an
    # empty result while the source clearly contains entry-shaped content,
    # the corresponding builder raises; we catch it here so the broken
    # section keeps its previously published content and the other sections
    # still get fresh data.

    def _build_hub():
        # Zone + station layout from the catalog's placement section, so the
        # page's "where is it" content moves when the hub moves.
        zone_m = re.search(r"catalog\.huntZonePath\s*=\s*'xi\.zones\.([\w-]+)'", text)
        if not zone_m:
            raise RuntimeError(
                "catalog.huntZonePath not found in reforge_catalog.lua -- "
                "placement section changed, update _build_hub."
            )
        zone = zone_m.group(1).replace("_", " ")
        stations = re.findall(
            r"\{\s*id\s*=\s*(\d+)\s*,\s*spawnerPos\s*=\s*\{\s*x\s*=\s*(-?[\d.]+)\s*,"
            r"\s*y\s*=\s*(-?[\d.]+)\s*,\s*z\s*=\s*(-?[\d.]+)", text)
        if "catalog.stations" in text and not stations:
            raise RuntimeError(
                "catalog.stations exists but zero stations parsed -- "
                "station table format changed, update _build_hub."
            )
        lines = [
            f"The Reforge hub lives in **{zone}** — warp straight there with "
            f"`!reforged`. One shared **Reforge Vendor** and **Mark Exchange** "
            f"sit at the hub entrance, with **{len(stations)} independent NM "
            f"Spawner stations** spread across the zone (each has its own "
            f"single-occupancy guard, so multiple parties — even popping the "
            f"same NM — farm side by side).",
            "",
            "| Station | Position |",
            "|---|---|",
        ]
        for sid, x, y, z in stations:
            lines.append(f"| **NM Spawner {sid}** | `({x}, {y}, {z})` |")
        return "\n".join(lines)

    def _build_sources():
        sources = _extract_sources(text)
        if "catalog.sources" in text and not sources:
            raise RuntimeError(
                "catalog.sources block exists in reforge_catalog.lua but "
                "_extract_sources parsed zero pools. Field names or block "
                "structure probably changed -- update _SOURCE_HEADER_RE or "
                "the _balanced_blocks walk in this generator."
            )
        return _render_sources(sources)

    def _build_costs():
        costs = _extract_costs(text)
        # Signal: any line with `plus1 = N` near a set key. If we find that
        # signal but extracted nothing, _COST_LINE_RE has stopped matching.
        cost_signals = len(re.findall(r"\bplus1\s*=\s*\d+", text))
        if cost_signals > 0 and not costs:
            raise RuntimeError(
                f"reforge_catalog.lua has {cost_signals} `plus1 = N` "
                f"signals but _COST_LINE_RE matched zero rows. A field "
                f"order/name probably changed -- update the regex."
            )
        return _render_costs(costs)

    def _build_job_sets():
        job_sets = _extract_job_sets(text)
        # Signal: any line like `---------- JOB --` (loose header form). If
        # we find that signal but extracted nothing, _JOB_HEADER_RE no longer
        # matches the actual header format.
        header_signals = len(
            re.findall(r"--\s*-+\s*[A-Z]{3}\s*--", text)
        )
        if header_signals > 0 and not job_sets:
            raise RuntimeError(
                f"reforge_catalog.lua has {header_signals} job-header "
                f"signals (e.g. `-- -------- WAR --`) but _JOB_HEADER_RE "
                f"matched zero. Header comment format probably changed -- "
                f"update the regex."
            )
        return _render_job_sets(job_sets)

    def _section(marker: str, build_content):
        try:
            content = build_content()
        except Exception as e:
            print(f"[reforge] {marker}: PARSER REGRESSION -- {e}")
            print(f"[reforge] {marker}: keeping existing published content")
            return False
        wrote = write_between_markers(page, marker, content)
        if wrote:
            print(f"[reforge] {marker}: written into markers")
        else:
            print(f"[reforge] {marker}: skipped (markers not found in {page.name})")
        return wrote

    wrote_any = False
    wrote_any |= _section("reforge-hub",      _build_hub)
    wrote_any |= _section("reforge-sources",  _build_sources)
    wrote_any |= _section("reforge-costs",    _build_costs)
    wrote_any |= _section("reforge-job-sets", _build_job_sets)

    if not wrote_any:
        print(f"[reforge] no marker blocks updated; add DOCGEN markers to {page} to enable")


def _extract_sources(text: str) -> dict[str, dict]:
    """Find each `<key> = { ... }` block under catalog.sources and pull
    label/currency/mobs from it."""
    # Locate the catalog.sources = { ... } block first to scope our search.
    anchor = re.search(r"catalog\.sources\s*=\s*", text)
    if not anchor:
        return {}
    remaining = text[anchor.end():]
    outer = next(_balanced_blocks(remaining), None)
    if outer is None:
        return {}
    inner = remaining[outer[0] + 1: outer[1] - 1]

    out: dict[str, dict] = {}
    for m in _SOURCE_HEADER_RE.finditer(inner):
        key = m.group(1)
        after_eq = inner[m.end() - 1:]   # start at the `{`
        block_start_rel, block_end_rel = next(_balanced_blocks(after_eq))
        body = after_eq[block_start_rel + 1: block_end_rel - 1]
        label_m = _LABEL_RE.search(body)
        currency_m = _CURRENCY_NAME_RE.search(body)

        # Mobs sub-block
        mobs: list[dict] = []
        mobs_anchor = re.search(r"\bmobs\s*=\s*", body)
        if mobs_anchor:
            mobs_remaining = body[mobs_anchor.end():]
            mobs_outer = next(_balanced_blocks(mobs_remaining), None)
            if mobs_outer is not None:
                mobs_inner = mobs_remaining[mobs_outer[0] + 1: mobs_outer[1] - 1]
                for ms, me in _balanced_blocks(mobs_inner):
                    row = mobs_inner[ms + 1: me - 1]
                    nm = _NAME_FIELD_RE.search(row)
                    marks = _MARKS_RE.search(row)
                    minlv = _MINLV_RE.search(row)
                    power = _POWER_RE.search(row)
                    if nm and marks:
                        mobs.append({
                            "name":  _quoted_value(nm).replace("_", " "),
                            "marks": int(marks.group(1)),
                            "level": int(minlv.group(1)) if minlv else None,
                            "power": int(power.group(1)) if power else None,
                        })

        out[key] = {
            "label": _quoted_value(label_m) if label_m else key,
            "currency": _quoted_value(currency_m) if currency_m else "Marks",
            "mobs": mobs,
        }
    return out


def _extract_costs(text: str) -> dict[str, tuple[int, int, int]]:
    out: dict[str, tuple[int, int, int]] = {}
    for m in _COST_LINE_RE.finditer(text):
        out[m.group(1)] = (int(m.group(2)), int(m.group(3)), int(m.group(4)))
    return out


def _extract_job_sets(text: str) -> dict[str, dict[str, str]]:
    """Per-job set names from header comments."""
    out: dict[str, dict[str, str]] = {}
    for m in _JOB_HEADER_RE.finditer(text):
        job = m.group(1)
        out[job] = {
            "af":    m.group(2).strip(),
            "relic": m.group(3).strip(),
            "empy":  m.group(4).strip(),
        }
    return out


def _escape_md(s: str) -> str:
    return s.replace("|", "\\|").replace("\n", " ")


def _render_sources(sources: dict[str, dict]) -> str:
    if not sources:
        return "_No NM pool data parsed from the catalog._"
    lines: list[str] = []
    for key in _SOURCE_ORDER:
        s = sources.get(key)
        if not s:
            continue
        lines.append(f"### {_SOURCE_LABEL[key]}")
        lines.append("")
        lines.append(f"**Currency:** {s['currency']}")
        lines.append("")
        # Sort entry → apex by power profile. All current fights are Lv99, so
        # combat level no longer distinguishes the five difficulty steps.
        mobs_sorted = sorted(s["mobs"], key=lambda m: m.get("power") or m.get("level") or 0)
        has_levels = any(m.get("level") for m in mobs_sorted)
        if has_levels:
            lines.append("| NM | Level / power step | Marks per kill |")
            lines.append("|---|---:|---:|")
            for mob in mobs_sorted:
                lvl = mob.get("level")
                lvl_str = f"Lv{lvl}" if lvl else "—"
                if mob.get("power"):
                    lvl_str += f" / {_POWER_STEP.get(mob['power'], mob['power'])}"
                lines.append(f"| {_escape_md(mob['name'])} | {lvl_str} | {mob['marks']} |")
        else:
            lines.append("| NM | Marks per kill |")
            lines.append("|---|---:|")
            for mob in mobs_sorted:
                lines.append(f"| {_escape_md(mob['name'])} | {mob['marks']} |")
        lines.append("")
    return "\n".join(lines).rstrip()


def _render_costs(costs: dict[str, tuple[int, int, int]]) -> str:
    if not costs:
        return "_No upgrade-cost data parsed from the catalog._"
    lines = [
        "| Set | base → +1 | +1 → +2 | +2 → +3 |",
        "|---|---:|---:|---:|",
    ]
    for key in _SOURCE_ORDER:
        if key not in costs:
            continue
        p1, p2, p3 = costs[key]
        lines.append(
            f"| {_SOURCE_LABEL[key]} | {p1} | {p2} | {p3} |"
        )
    lines.append("")
    lines.append("_Costs are paid in that set's marks (e.g. AF upgrades cost AF Marks)._")
    return "\n".join(lines)


def _render_job_sets(job_sets: dict[str, dict[str, str]]) -> str:
    if not job_sets:
        return "_No job/set mapping parsed from the catalog._"
    lines = [
        "| Job | AF | Relic | Empyrean |",
        "|---|---|---|---|",
    ]
    for job in _JOB_ORDER:
        sets = job_sets.get(job)
        if not sets:
            continue
        lines.append(
            f"| {job} | {_escape_md(sets['af'])} | {_escape_md(sets['relic'])} | {_escape_md(sets['empy'])} |"
        )
    return "\n".join(lines)
