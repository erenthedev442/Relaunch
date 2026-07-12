"""Sync the augment-catalyst drop tables on docs/endgame/dungeons.md.

The seven "Augmentation Dungeons" each own a stat family of augment
catalysts (strategy owner-approved 2026-07-03): every trash mob carries one
fixed catalyst (30%-ish roll to the treasure pool), and the boss pays each
party member random picks from the dungeon's boss pool. All player-facing
tables AND the rate/quantity knobs derive from the same files the runtime
uses, so docs cannot drift from what actually drops:

  modules/custom/lua/augment_dungeon_drops_data.lua  (AUTO-GENERATED drop map)
  modules/custom/lua/augment_dungeon_drops.lua       (TRASH_RATE / BOSS_QTY knobs)
  modules/custom/lua/dungeon_catalog.lua             (labels, rosters, order)

Markers written:
  dungeon-augment-drops -- rules + per-dungeon boss pool and trash tables
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._bgwiki import item_anchor

# Runtime knobs (TRASH_RATE / BOSS_QTY) are PARSED from
# modules/custom/lua/augment_dungeon_drops.lua in generate() -- never mirror
# them here: a hardcoded copy silently drifted when the runtime was retuned
# (the 2026-07-11 "treasure pool" doc lie). Fallbacks below only cover a
# missing/unparseable runtime file.
_KNOB_RE = re.compile(r"^local\s+(TRASH_RATE|BOSS_QTY)\s*=\s*(\d+)", re.M)
_KNOB_DEFAULTS = {"TRASH_RATE": 30, "BOSS_QTY": 20}


def _parse_knobs(runtime_text: str) -> dict[str, int]:
    knobs = dict(_KNOB_DEFAULTS)
    for m in _KNOB_RE.finditer(runtime_text):
        knobs[m.group(1)] = int(m.group(2))
    return knobs

_ENTRY_RE = re.compile(
    r"\{ id = (\d+), tier = (\d+), cat = \d+, label = '([^']*)'(?:, item = '((?:[^'\\]|\\.)*)')? \}"
)
_ROSTER_RE = re.compile(
    r"\},\s*([\"'])(.+?)\1,\s*([\"'])(.+?)\3,\s*([\"'])(.+?)\5,\s*\d+\)"
)


def _parse_drops(text: str) -> dict[str, dict]:
    """augment_dungeon_drops_data.lua -> {key: {family, trash{slot: entry}, boss[entry]}}"""
    out: dict[str, dict] = {}
    blocks = re.split(r"^    (\w+) =$", text, flags=re.M)
    # re.split gives [prefix, key1, body1, key2, body2, ...]
    for key, body in zip(blocks[1::2], blocks[2::2]):
        fam_m = re.search(r"family = '((?:[^'\\]|\\.)*)'", body)
        trash_part, _, boss_part = body.partition("boss =")
        trash: dict[int, dict] = {}
        for m in re.finditer(r"\[(\d+)\] = " + _ENTRY_RE.pattern, trash_part):
            slot, item_id, tier, label, item = m.groups()
            trash[int(slot)] = {
                "id": int(item_id), "tier": int(tier),
                "label": label.replace("\\'", "'"),
                "item": item.replace("\\'", "'") if item else None,
            }
        boss = []
        for m in _ENTRY_RE.finditer(boss_part):
            item_id, tier, label, item = m.groups()
            boss.append({
                "id": int(item_id), "tier": int(tier),
                "label": label.replace("\\'", "'"),
                "item": item.replace("\\'", "'") if item else None,
            })
        out[key] = {
            "family": fam_m.group(1).replace("\\'", "'") if fam_m else key,
            "trash": trash,
            "boss": boss,
        }
    return out


def _parse_dungeons(text: str) -> dict[str, dict]:
    """dungeon_catalog.lua -> {key: {label, first, second, boss}} for roster naming."""
    out: dict[str, dict] = {}
    starts = [(m.start(), m.group(1))
              for m in re.finditer(r"^    (\w+) =\s*$", text, flags=re.M)]
    for i, (pos, key) in enumerate(starts):
        end = starts[i + 1][0] if i + 1 < len(starts) else len(text)
        window = text[pos:end]
        label_m = re.search(r"label\s*=\s*([\"'])(.+?)\1", window)
        roster_m = _ROSTER_RE.search(window)
        if label_m and roster_m:
            out[key] = {
                "label":  label_m.group(2),
                "first":  roster_m.group(2),
                "second": roster_m.group(4),
                "boss":   roster_m.group(6),
            }
    return out


def _pretty(token: str) -> str:
    return re.sub(r"(\w[\w'.]*)", lambda m: m.group(1)[0].upper() + m.group(1)[1:],
                  token.replace("_", " "))


def _item_cell(entry: dict) -> str:
    if not entry["item"]:
        return "_(catalyst)_"
    display = _pretty(entry["item"])
    return item_anchor(display,
                       resolve_key=entry["item"].replace("_", " ").title(),
                       item_id=entry["id"])


def _slot_mob(info: dict, slot: int) -> str:
    if slot <= 6:
        return f"{info['first']} {slot:02d}"
    return f"{info['second']} {slot - 6:02d}"


def _render(drops: dict[str, dict], dungeons: dict[str, dict], knobs: dict[str, int]) -> str:
    trash_rate = knobs["TRASH_RATE"]
    boss_qty   = knobs["BOSS_QTY"]

    lines: list[str] = []
    lines.append(
        "Each **Augmentation Dungeon** owns a **family of augments** — pick your "
        "dungeon by the kind of catalyst you're hunting. Two ways to get paid:")
    lines.append("")
    lines.append(
        f"- **Trash (12 mobs)** — every trash mob carries **one fixed catalyst**; the "
        f"killing blow has a **{trash_rate}% chance** to drop it (**×1**) into the "
        f"party's **treasure pool**, so anyone in the run can lot it. Same 1:1 model "
        f"as open-world catalyst mobs, so you can target a specific augment.")
    lines.append(
        f"- **Boss** — appears **only after you clear all 12 guardians**, so a boss "
        f"kill always caps a full clear. **Every party member** then receives "
        f"**{boss_qty} random catalysts** from the dungeon's boss pool (each rolled "
        f"independently), straight to inventory, **guaranteed on every full clear**.")
    lines.append("")
    lines.append(
        "Trade catalysts to the **Augment Moogle** to apply them. Every augment is "
        "available at every Augment Tier — your tier determines the **power** of the "
        "roll, not which augments you can access.")

    for key, d in drops.items():
        info = dungeons.get(key)
        if not info:
            continue
        lines.append("")
        lines.append(f"#### {info['label']} — {d['family']}")
        lines.append("")
        lines.append(
            f"_Trash: **{trash_rate}%** · **×1** · to the treasure pool (anyone in "
            f"the run can lot) — Boss: **×{boss_qty} random** to each member, every "
            f"full clear._")
        lines.append("")
        lines.append(f"**Boss pool — {info['boss']}** (×{boss_qty} random per member per clear):")
        lines.append("")
        lines.append("| Catalyst | Augment |")
        lines.append("|---|---|")
        for e in sorted(d["boss"], key=lambda e: (e["label"], e["id"])):
            lines.append(f"| {_item_cell(e)} | {e['label']} |")
        lines.append("")
        lines.append("**Trash assignments:**")
        lines.append("")
        lines.append("| Mob | Catalyst | Augment |")
        lines.append("|---|---|---|")
        for slot in sorted(d["trash"]):
            e = d["trash"][slot]
            lines.append(f"| {_slot_mob(info, slot)} | {_item_cell(e)} "
                         f"| {e['label']} |")

    return "\n".join(lines)


def generate(repo_root: Path, docs_dir: Path) -> None:
    drops_src = resolve_source(repo_root, "modules/custom/lua/augment_dungeon_drops_data.lua")
    cat_src   = resolve_source(repo_root, "modules/custom/lua/dungeon_catalog.lua")
    if drops_src is None or cat_src is None:
        print("[augment_dungeon_drops] skip: source lua not found")
        return

    drops    = _parse_drops(drops_src.read_text(encoding="utf-8", errors="replace"))
    dungeons = _parse_dungeons(cat_src.read_text(encoding="utf-8", errors="replace"))
    if not drops:
        print("[augment_dungeon_drops] skip: no dungeons parsed from data file")
        return

    # Drop-rate knobs come from the runtime payout module itself (see _KNOB_RE).
    knobs = dict(_KNOB_DEFAULTS)
    runtime_src = resolve_source(repo_root, "modules/custom/lua/augment_dungeon_drops.lua")
    if runtime_src is not None:
        knobs = _parse_knobs(runtime_src.read_text(encoding="utf-8", errors="replace"))
    else:
        print("[augment_dungeon_drops] WARN: runtime lua not found -- using fallback knobs")

    page = docs_dir / "endgame" / "dungeons.md"
    ok = write_between_markers(page, "dungeon-augment-drops", _render(drops, dungeons, knobs))
    n_entries = sum(len(d["trash"]) + len(d["boss"]) for d in drops.values())
    print(f"[augment_dungeon_drops] {'written' if ok else 'MARKER MISSING'} "
          f"({len(drops)} dungeons, {n_entries} drop rows, "
          f"trash {knobs['TRASH_RATE']}%, boss x{knobs['BOSS_QTY']})")
