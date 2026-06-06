"""Weaponskill parameter registry.

Damage params (numHits / ftpMod / *_wsc / atkVaries / ignoredDefense / accVaries
/ critVaries / multiHitfTP / hybridWS / kick) are parsed straight from each WS
script under scripts/actions/weaponskills/, taking the
USE_ADOULIN_WEAPON_SKILL_CHANGES branch -- this server runs Adoulin rules
(settings/main.lua: USE_ADOULIN_WEAPON_SKILL_CHANGES = true).

Weapon-type, the WS id (for the per-WS WEAPONSKILL_DAMAGE_BASE+id mod) and the
job mask come from the live `weapon_skills` table, so they never drift.

Merit-scaled WSC terms (e.g. Blade: Shun's `0.7 + getMerit()*0.03`) are resolved
assuming 5/5 merits -- the realistic end-game case and what the optimizer should
plan around.
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field
from functools import lru_cache

from .db import REPO_ROOT

_WS_DIR = REPO_ROOT / "scripts" / "actions" / "weaponskills"

# params.<key>_wsc  ->  stat name consumed by calculateWSC
WSC_KEYS = {
    "str_wsc": "STR", "dex_wsc": "DEX", "vit_wsc": "VIT", "agi_wsc": "AGI",
    "int_wsc": "INT", "mnd_wsc": "MND", "chr_wsc": "CHR",
}
_LIST_KEYS = ("ftpMod", "atkVaries", "ignoredDefense", "accVaries", "critVaries")
_BOOL_KEYS = {"multiHitfTP": "multi_hit_ftp", "hybridWS": "hybrid", "kick": "kick"}

_ADOULIN_RE = re.compile(r"USE_ADOULIN_WEAPON_SKILL_CHANGES")
_DOWS_RE = re.compile(r"doPhysicalWeaponskill|doRangedWeaponskill")
_NUMHITS_RE = re.compile(r"params\.numHits\s*=\s*(\d+)")
_LIST_RE = {k: re.compile(rf"params\.{k}\s*=\s*\{{([^}}]*)\}}") for k in _LIST_KEYS}
_BOOL_RE = {k: re.compile(rf"params\.{k}\s*=\s*(true|false)") for k in _BOOL_KEYS}
# A WSC rhs is a leading float, optionally `+ (getMerit(...) * k)` merit terms.
_WSC_RE = {
    k: re.compile(
        rf"params\.{k}\s*=\s*([0-9.]+(?:\s*\+\s*\([^)]*\)\s*\*\s*[0-9.]+)?)"
    )
    for k in WSC_KEYS
}
_MERIT_TERM_RE = re.compile(r"getMerit\([^)]*\)\s*\*\s*([0-9.]+)")
_ASSUMED_MERITS = 5


@dataclass
class WSParams:
    name: str
    num_hits: int = 1
    ftp: list[float] = field(default_factory=lambda: [1.0, 1.0, 1.0])
    wsc: dict[str, float] = field(default_factory=dict)
    atk_varies: list[float] | None = None
    ignored_def: list[float] | None = None
    acc_varies: list[float] | None = None
    crit_varies: list[float] | None = None
    multi_hit_ftp: bool = False
    hybrid: bool = False
    kick: bool = False

    # filled from the DB (weapon_skills table)
    ws_id: int = 0
    weapon_type: int = 0


def _floats(body: str) -> list[float]:
    out = []
    for tok in body.split(","):
        tok = tok.strip()
        if not tok:
            continue
        try:
            out.append(float(tok))
        except ValueError:
            out.append(0.0)  # non-literal entry (rare); treat as 0
    return out


def _wsc_value(rhs: str) -> float:
    """Evaluate a WSC rhs like '0.7 + (player:getMerit(...) * 0.03)' at 5/5."""
    lead = re.match(r"\s*([0-9.]+)", rhs)
    val = float(lead.group(1)) if lead else 0.0
    for m in _MERIT_TERM_RE.finditer(rhs):
        val += _ASSUMED_MERITS * float(m.group(1))
    return val


def _parse_into(text: str, p: WSParams) -> None:
    """Overlay any params.* assignments found in `text` onto p."""
    m = _NUMHITS_RE.search(text)
    if m:
        p.num_hits = int(m.group(1))
    for k, rx in _LIST_RE.items():
        lm = rx.search(text)
        if not lm:
            continue
        vals = _floats(lm.group(1))
        if k == "ftpMod":
            p.ftp = vals
        elif k == "atkVaries":
            p.atk_varies = vals
        elif k == "ignoredDefense":
            p.ignored_def = vals
        elif k == "accVaries":
            p.acc_varies = vals
        elif k == "critVaries":
            p.crit_varies = vals
    for k, attr in _BOOL_KEYS.items():
        bm = _BOOL_RE[k].search(text)
        if bm:
            setattr(p, attr, bm.group(1) == "true")
    for k, stat in WSC_KEYS.items():
        wm = _WSC_RE[k].search(text)
        if wm:
            p.wsc[stat] = _wsc_value(wm.group(1))


@lru_cache(maxsize=None)
def parse_ws_file(name: str) -> WSParams | None:
    """Parse one WS script (by file stem, e.g. 'savage_blade') into WSParams.

    Base assignments are read first, then the Adoulin branch overlays them so the
    live ruleset wins. Returns None if the script isn't a physical WS we model.
    """
    path = _WS_DIR / f"{name}.lua"
    if not path.exists():
        return None
    text = path.read_text(encoding="utf-8", errors="replace")
    if not _DOWS_RE.search(text):
        return None  # not a damage WS dispatched through the physical/ranged path

    p = WSParams(name=name)

    am = _ADOULIN_RE.search(text)
    if am:
        base_text = text[:am.start()]
        adoulin_text = text[am.start():]
        _parse_into(base_text, p)
        # Adoulin overrides win; the override block sits before the dispatch call.
        dm = _DOWS_RE.search(adoulin_text)
        _parse_into(adoulin_text[:dm.start() if dm else len(adoulin_text)], p)
    else:
        dm = _DOWS_RE.search(text)
        _parse_into(text[:dm.start()], p)
    return p


# ---------------------------------------------------------------------------
# weapon_skills table (weapon type, ws id, job mask)  -- live DB
# ---------------------------------------------------------------------------
@dataclass
class WSRow:
    ws_id: int
    name: str
    weapon_type: int
    jobs: bytes


_ws_table_cache: list[WSRow] | None = None


def load_ws_table(conn) -> list[WSRow]:
    global _ws_table_cache
    if _ws_table_cache is None:
        cur = conn.cursor()
        cur.execute("SELECT weaponskillid, name, type, jobs FROM weapon_skills")
        rows = []
        for r in cur.fetchall():
            jb = r["jobs"]
            rows.append(WSRow(r["weaponskillid"], r["name"], r["type"],
                              bytes(jb) if jb else b""))
        _ws_table_cache = rows
    return _ws_table_cache


def _usable_by_job(row: WSRow, job_id: int) -> bool:
    """weapon_skills.jobs is one byte per job (index job_id-1), non-zero = usable.
    Relic/Mythic/Empyrean/merit WS carry an all-zero mask (weapon/merit gated) and
    are allowed through so a player wielding that weapon can still pick them."""
    if not row.jobs or not any(row.jobs):
        return True
    idx = job_id - 1
    return 0 <= idx < len(row.jobs) and row.jobs[idx] != 0


def ws_for_weapon(conn, weapon_type: int, main_job: int | None = None,
                  sub_job: int | None = None) -> list[WSParams]:
    """All physical WS for a weapon type, optionally filtered to a job pair,
    each returned as fully-parsed WSParams (with ws_id + weapon_type filled)."""
    out: list[WSParams] = []
    for row in load_ws_table(conn):
        if row.weapon_type != weapon_type:
            continue
        if main_job is not None:
            ok = _usable_by_job(row, main_job)
            if sub_job:
                ok = ok or _usable_by_job(row, sub_job)
            if not ok:
                continue
        p = parse_ws_file(row.name)
        if p is None or p.hybrid:  # hybrid (magic) WS not modelled by the melee engine
            continue
        p.ws_id = row.ws_id
        p.weapon_type = row.weapon_type
        out.append(p)
    return out


def get_ws(conn, name_or_label: str) -> WSParams | None:
    """Resolve a single WS by script stem or display name (case/space-insensitive)."""
    needle = name_or_label.strip().lower().replace(" ", "_").replace(":", "")
    for row in load_ws_table(conn):
        key = row.name.lower().replace(":", "")
        if key == needle:
            p = parse_ws_file(row.name)
            if p:
                p.ws_id = row.ws_id
                p.weapon_type = row.weapon_type
            return p
    return None
