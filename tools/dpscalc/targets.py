"""Hunting League NM target table, parsed from the live catalog.

Source of truth: modules/custom/lua/hunting_league_catalog.lua. Each NM there
spawns a base mob and then `setMod`s a block of absolute modifiers. The catalog
author balanced the fights treating those mod values as the mob's EFFECTIVE
DEF / EVASION / ACC (the inline comments compute hit rates straight from them),
so we take them as effective rather than trying to reconstruct base-mob stats.

Stats the catalog does NOT set on a given NM (commonly VIT and AGI, which feed
the *player's* fSTR and crit rate) fall back to a level-scaled default that the
caller can override -- they are minor terms and do not change gear rankings.
"""
from __future__ import annotations

import re
from dataclasses import dataclass
from functools import lru_cache

from .db import REPO_ROOT

_CATALOG = REPO_ROOT / "modules" / "custom" / "lua" / "hunting_league_catalog.lua"

_TIER_RE = re.compile(r"tier\s*=\s*(\d+)\s*,\s*\n\s*name\s*=\s*'([^']+)'")
_MOB_RE = re.compile(
    r"name\s*=\s*'([^']+)'\s*,\s*label\s*=\s*'([^']+)'\s*,\s*"
    r"points\s*=\s*(\d+)\s*,\s*groupId\s*=\s*(\d+)\s*,\s*"
    r"minLv\s*=\s*(\d+)\s*,\s*maxLv\s*=\s*(\d+)"
)
_HPBOOST_RE = re.compile(r"hpBoost\s*=\s*(\d+)")
_MOD_RE = re.compile(r"\[xi\.mod\.(\w+)\]\s*=\s*(-?\d+)")


@dataclass
class Target:
    name: str
    label: str
    tier: int
    tier_name: str
    points: int
    group_id: int
    min_lv: int
    max_lv: int
    hp_boost: int
    mods: dict[str, int]          # raw catalog mods (effective values)

    # --- derived / overridable combat stats the engine consumes ---
    def defense(self) -> int:
        return self.mods.get("DEF", 0)

    def evasion(self) -> int:
        return self.mods.get("EVASION", 0)

    def vit(self) -> int:
        # Catalog rarely sets mob VIT; default to a level-scaled estimate.
        return self.mods.get("VIT", self.max_lv)

    def agi(self) -> int:
        return self.mods.get("AGI", self.max_lv)

    def crit_def_bonus(self) -> int:
        return self.mods.get("CRIT_DEF_BONUS", 0)

    def crit_eva(self) -> int:
        return self.mods.get("CRITICAL_HIT_EVASION", 0)

    def level(self) -> int:
        return self.max_lv


def _split_tiers(text: str) -> str:
    start = text.find("tiers")
    end = text.find("rewardCategories")
    if start == -1:
        return text
    return text[start:end if end != -1 else len(text)]


@lru_cache(maxsize=1)
def load_targets() -> list[Target]:
    text = _CATALOG.read_text(encoding="utf-8", errors="replace")
    body = _split_tiers(text)

    # Tier headers partition the body; each mob inherits the tier above it.
    tiers = list(_TIER_RE.finditer(body))
    out: list[Target] = []
    for i, tm in enumerate(tiers):
        tier_num = int(tm.group(1))
        tier_name = tm.group(2)
        seg_start = tm.end()
        seg_end = tiers[i + 1].start() if i + 1 < len(tiers) else len(body)
        segment = body[seg_start:seg_end]

        for mm in _MOB_RE.finditer(segment):
            # The mods + hpBoost for this mob live between this match and the next.
            nxt = _MOB_RE.search(segment, mm.end())
            chunk = segment[mm.end():nxt.start() if nxt else len(segment)]
            hp = _HPBOOST_RE.search(chunk)
            mods = {name: int(v) for name, v in _MOD_RE.findall(chunk)}
            out.append(Target(
                name=mm.group(1), label=mm.group(2), tier=tier_num,
                tier_name=tier_name, points=int(mm.group(3)),
                group_id=int(mm.group(4)), min_lv=int(mm.group(5)),
                max_lv=int(mm.group(6)), hp_boost=int(hp.group(1)) if hp else 1,
                mods=mods,
            ))
    return out


def find_target(name_or_label: str) -> Target | None:
    needle = name_or_label.strip().lower().replace(" ", "_")
    for t in load_targets():
        if t.name.lower() == needle or t.label.lower() == name_or_label.strip().lower():
            return t
    # loose contains-match as a convenience
    for t in load_targets():
        if needle in t.name.lower():
            return t
    return None
