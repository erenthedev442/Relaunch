"""Live read of the gameplay constants the engine needs from settings/main.lua.

Parsing the settings file (rather than hardcoding) keeps the calculator pinned to
whatever this server is actually running -- STR/DEX combat ratios, the WS power
multiplier and the Adoulin toggle have all been re-tuned here vs. retail defaults.
"""
from __future__ import annotations

import re
from functools import lru_cache

from .db import REPO_ROOT

_MAIN = REPO_ROOT / "settings" / "main.lua"


@lru_cache(maxsize=1)
def _text() -> str:
    return _MAIN.read_text(encoding="utf-8", errors="replace")


def get_float(key: str, default: float) -> float:
    m = re.search(rf"\b{re.escape(key)}\s*=\s*(-?[0-9.]+)", _text())
    return float(m.group(1)) if m else default


def get_bool(key: str, default: bool) -> bool:
    m = re.search(rf"\b{re.escape(key)}\s*=\s*(true|false)", _text())
    return (m.group(1) == "true") if m else default


class Conf:
    """Snapshot of the settings the engine reads (resolved once, lazily)."""

    @property
    def weapon_skill_power(self) -> float:
        return get_float("WEAPON_SKILL_POWER", 1.0)

    @property
    def use_adoulin_ws(self) -> bool:
        return get_bool("USE_ADOULIN_WEAPON_SKILL_CHANGES", True)

    # STR -> Attack multipliers, keyed by weapon situation.
    @property
    def str_mult_2h(self) -> float:
        return get_float("TWO_HANDED_STR_ATTACK_MULTIPLIER", 1.0)

    @property
    def str_mult_h2h(self) -> float:
        return get_float("HAND_TO_HAND_STR_ATTACK_MULTIPLIER", 1.0)

    @property
    def str_mult_1h_main(self) -> float:
        return get_float("ONE_HAND_MAIN_HAND_STR_ATTACK_MULTIPLIER", 0.75)

    @property
    def str_mult_1h_sub(self) -> float:
        return get_float("ONE_HAND_OFF_HAND_STR_ATTACK_MULTIPLIER", 0.5)

    # DEX -> Accuracy multipliers.
    @property
    def dex_mult_2h(self) -> float:
        return get_float("TWO_HANDED_DEX_ACCURACY_MULTIPLIER", 0.75)

    @property
    def dex_mult_h2h(self) -> float:
        return get_float("HAND_TO_HAND_DEX_ACCURACY_MULTIPLIER", 0.75)

    @property
    def dex_mult_1h_main(self) -> float:
        return get_float("ONE_HAND_MAIN_HAND_DEX_ACCURACY_MULTIPLIER", 0.75)

    @property
    def dex_mult_1h_sub(self) -> float:
        return get_float("ONE_HAND_OFF_HAND_DEX_ACCURACY_MULTIPLIER", 0.75)


CONF = Conf()
