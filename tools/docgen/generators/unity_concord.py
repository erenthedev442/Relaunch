"""Generate docs/endgame/unity-concord.md from unity_wanted_catalog.lua.

Unity Concord is a custom NM hunting system accessed from the Celennia Memorial
Library board. Players pledge to a Unity leader, pay accolades to spawn a
Wanted NM in Escha-Zi'tah, and earn accolades on kill to spend in the shop.

Markers written:
  unity-overview  — tier cost/reward table
  unity-tiers     — full NM roster grouped by tier (includes item drops)
  unity-shop      — accolade shop item list
  unity-leaders   — the 11 Unity leaders
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section, commafy


def _first(pattern: str, text: str, default: str) -> str:
    m = re.search(pattern, text)
    return m.group(1) if m else default


def _int(pattern: str, text: str, default: int) -> int:
    return int(float(_first(pattern, text, str(default))))


def _parse_kv_ints(text: str) -> dict[int, int]:
    """Parse { [1]=X, [2]=Y, [3]=Z } -> {1:X, 2:Y, 3:Z}."""
    return {int(k): int(v) for k, v in re.findall(r"\[(\d+)\]\s*=\s*(\d+)", text)}


def _extract_drops(nm_block: str) -> list[str]:
    """Extract item names from a drops = { {id=X, name='...'}, ... } block."""
    drops_m = re.search(r"drops\s*=\s*\{((?:[^{}]|\{[^{}]*\})*)\}", nm_block)
    if not drops_m:
        return []
    results = []
    for m in re.finditer(r"name\s*=\s*(?:'([^']*)'|\"([^\"]*)\")", drops_m.group(1)):
        results.append(m.group(1) if m.group(1) is not None else m.group(2))
    return results


def _parse(text: str) -> dict:
    c: dict = {}

    costs_blk = section(text, "costs")
    c["costs"] = _parse_kv_ints(costs_blk) if costs_blk else {1: 200, 2: 600, 3: 1500}

    rewards_blk = section(text, "rewards")
    c["rewards"] = _parse_kv_ints(rewards_blk) if rewards_blk else {1: 400, 2: 1500, 3: 4000}

    # Leaders: { id=N, name='...' }
    leaders_blk = section(text, "leaders")
    c["leaders"] = [
        {"id": int(i), "name": n}
        for i, n in re.findall(r"id\s*=\s*(\d+)\s*,\s*name\s*=\s*'([^']+)'", leaders_blk or "")
    ]

    # Shop items: { item=..., label='...', cost=N }
    shop_blk = section(text, "shop")
    c["shop"] = [
        {"label": lbl, "cost": int(cost)}
        for lbl, cost in re.findall(
            r'label\s*=\s*[\'"]([^\'"]+)[\'"]\s*,\s*cost\s*=\s*(\d+)', shop_blk or ""
        )
    ]

    # NMs: parse each { ... } entry in the nms section as a block.
    # section() returns the outer { ... } of the nms array; we scan inside it
    # (starting at position 1) so each NM entry is found at depth 0.
    nms_blk = section(text, "nms") or ""
    c["nms"] = []
    depth = 0
    start = None
    i = 1  # skip opening { of the nms array
    n = max(0, len(nms_blk) - 1)  # stop before closing }
    while i < n:
        ch = nms_blk[i]
        if ch == "-" and i + 1 < n and nms_blk[i + 1] == "-":  # line comment
            nl = nms_blk.find("\n", i)
            i = (nl + 1) if nl != -1 else n
            continue
        if ch in ("'", '"'):  # quoted string — skip braces inside
            q = ch
            i += 1
            while i < n:
                if nms_blk[i] == "\\" and i + 1 < n:
                    i += 2
                    continue
                if nms_blk[i] == q:
                    i += 1
                    break
                i += 1
            continue
        if ch == "{":
            if depth == 0:
                start = i
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0 and start is not None:
                block = nms_blk[start:i + 1]
                lbl_m = re.search(r"label\s*=\s*(?:'([^']*)'|\"([^\"]*)\")", block)
                tier_m = re.search(r"tier\s*=\s*(\d)", block)
                minlv_m = re.search(r"minLv\s*=\s*(\d+)", block)
                maxlv_m = re.search(r"maxLv\s*=\s*(\d+)", block)
                if lbl_m and tier_m and minlv_m and maxlv_m:
                    label = lbl_m.group(1) if lbl_m.group(1) is not None else lbl_m.group(2)
                    c["nms"].append({
                        "label": label,
                        "tier":  int(tier_m.group(1)),
                        "minLv": int(minlv_m.group(1)),
                        "maxLv": int(maxlv_m.group(1)),
                        "drops": _extract_drops(block),
                    })
                start = None
        i += 1

    c["despawn"] = _int(r"despawnSecs\s*=\s*(\d+)", text, 120)
    return c


_TIER_NAMES = {1: "Tier 1", 2: "Tier 2", 3: "Tier 3"}
_LV_RANGES  = {1: "lv 75–80", 2: "lv 99–119", 3: "lv 128–145"}


def _render_overview(c: dict) -> str:
    lines = [
        "| Tier | Level range | Spawn cost | Kill reward |",
        "|---:|---|---:|---:|",
    ]
    for tier in sorted(c["costs"]):
        cost   = commafy(c["costs"][tier])
        reward = commafy(c["rewards"][tier])
        lv_rng = _LV_RANGES.get(tier, f"Tier {tier}")
        lines.append(f"| **{tier}** | {lv_rng} | {cost} accolades | {reward} accolades |")
    return "\n".join(lines)


def _render_tiers(c: dict) -> str:
    nms_by_tier: dict[int, list[dict]] = {}
    for nm in c["nms"]:
        nms_by_tier.setdefault(nm["tier"], []).append(nm)

    lines: list[str] = []
    for tier in sorted(nms_by_tier):
        tier_nms = nms_by_tier[tier]
        cost     = commafy(c["costs"].get(tier, 0))
        reward   = commafy(c["rewards"].get(tier, 0))
        lv_rng   = _LV_RANGES.get(tier, f"Tier {tier}")
        lines.append(f"### Tier {tier} — {lv_rng}")
        lines.append(f"*Spawn cost: {cost} · Kill reward: {reward} accolades*")
        lines.append("")
        lines.append("| NM | Level | Notable Drops (50% each) |")
        lines.append("|---|---:|---|")
        for nm in tier_nms:
            lv = nm["minLv"] if nm["minLv"] == nm["maxLv"] else f"{nm['minLv']}–{nm['maxLv']}"
            drops_str = ", ".join(nm["drops"]) if nm["drops"] else "—"
            lines.append(f"| {nm['label']} | {lv} | {drops_str} |")
        lines.append("")
    return "\n".join(lines).rstrip()


def _render_shop(c: dict) -> str:
    if not c["shop"]:
        return "_No shop items defined._"
    lines = [
        "| Item | Cost |",
        "|---|---:|",
    ]
    for it in c["shop"]:
        lines.append(f"| {it['label']} | {commafy(it['cost'])} accolades |")
    return "\n".join(lines)


def _render_leaders(c: dict) -> str:
    if not c["leaders"]:
        return "_Leader list unavailable._"
    names = ", ".join(f"**{ldr['name']}**" for ldr in sorted(c["leaders"], key=lambda x: x["id"]))
    return (f"Pledge to one of the **{len(c['leaders'])} Unity leaders** from the board. "
            f"Your pledge is cosmetic for now — it doesn't restrict which NMs you can fight.\n\n"
            f"{names}")


def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/unity_wanted_catalog.lua")
    if src is None:
        print("[unity_concord] skip: unity_wanted_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    c = _parse(text)

    page = docs_dir / "endgame" / "unity-concord.md"
    page.parent.mkdir(parents=True, exist_ok=True)

    blocks = [
        ("unity-overview", _render_overview(c)),
        ("unity-tiers",    _render_tiers(c)),
        ("unity-shop",     _render_shop(c)),
        ("unity-leaders",  _render_leaders(c)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    total_nms = len(c["nms"])
    print(f"[unity_concord] {written}/{len(blocks)} marker block(s) written "
          f"(nms={total_nms}, shop={len(c['shop'])}, leaders={len(c['leaders'])})")
