"""Generate Hunters' Guild reference tables inside docs/progression/hunters-guild.md.

Reads: modules/custom/lua/hunters_guild_catalog.lua

Marker IDs:
  - "hunters-guild-ranks"        -- rank ladder table
  - "hunters-guild-capstones"    -- capstones table
  - "hunters-guild-hunt-targets" -- hunt targets by guild
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

def _parse_ranks(text: str) -> list[dict]:
    m = re.search(r'\branks\s*=\s*\{', text)
    if not m:
        return []
    for start, end in _balanced_blocks(text[m.start():]):
        block = text[m.start():][start:end]
        break
    else:
        return []

    ranks = []
    for es, ee in _balanced_blocks(block[1:]):
        entry = block[1:][es:ee]
        idx_m   = re.search(r'\bidx\s*=\s*(\d+)', entry)
        label_m = re.search(r'\blabel\s*=\s*(' + _QUOTED + r')', entry)
        rep_m   = re.search(r'\bminRep\s*=\s*(\d+)', entry)
        amp_m   = re.search(r'\bamplifier\s*=\s*(\d+(?:\.\d+)?)', entry)
        if not (idx_m and label_m and rep_m and amp_m):
            continue
        ranks.append({
            "idx":       int(idx_m.group(1)),
            "label":     _quoted_value(label_m.group(1).strip()),
            "minRep":    int(rep_m.group(1)),
            "amplifier": float(amp_m.group(1)),
        })
    return sorted(ranks, key=lambda r: r["idx"])


def _parse_guild_order(text: str) -> list[str]:
    m = re.search(r'\bguildOrder\s*=\s*\{', text)
    if not m:
        return []
    for start, end in _balanced_blocks(text[m.start():]):
        block = text[m.start():][start:end]
        return [_quoted_value(q) for q in re.findall(_QUOTED, block)]
    return []


def _parse_guilds(text: str) -> dict[str, dict]:
    """Parse catalog.guilds into a {key: {key, label, markType, isReforge}} dict."""
    m = re.search(r'\bguilds\s*=\s*\{', text)
    if not m:
        return {}
    for start, end in _balanced_blocks(text[m.start():]):
        guilds_block = text[m.start():][start:end]
        break
    else:
        return {}

    guilds = {}
    # Each guild entry: key = { key='...', label='...', ... }
    for gm in re.finditer(r'\b(\w+)\s*=\s*\{', guilds_block):
        guild_key = gm.group(1)
        if guild_key in ("guilds",):
            continue
        # Find the balanced block starting at gm.start()
        sub = guilds_block[gm.start():]
        for gs, ge in _balanced_blocks(sub):
            entry = sub[gs:ge]
            label_m    = re.search(r'\blabel\s*=\s*(' + _QUOTED + r')', entry)
            marktype_m = re.search(r'\bmarkType\s*=\s*(' + _QUOTED + r')', entry)
            reforge_m  = re.search(r'\bisReforge\s*=\s*(true|false)', entry)
            if label_m:
                guilds[guild_key] = {
                    "key":       guild_key,
                    "label":     _quoted_value(label_m.group(1).strip()),
                    "markType":  _quoted_value(marktype_m.group(1).strip()) if marktype_m else "",
                    "isReforge": reforge_m.group(1) == "true" if reforge_m else False,
                }
            break

    return guilds


def _parse_capstones(text: str) -> list[dict]:
    m = re.search(r'\bcapstones\s*=\s*\{', text)
    if not m:
        return []
    for start, end in _balanced_blocks(text[m.start():]):
        block = text[m.start():][start:end]
        break
    else:
        return []

    capstones = []
    for gm in re.finditer(r'\b(\w+)\s*=\s*\{', block):
        name = gm.group(1)
        if name == "capstones":
            continue
        sub = block[gm.start():]
        for cs, ce in _balanced_blocks(sub):
            entry = sub[cs:ce]
            label_m   = re.search(r'\blabel\s*=\s*(' + _QUOTED + r')', entry)
            bonus_m   = re.search(r'\bbonus\s*=\s*(\d+(?:\.\d+)?)', entry)
            req_m     = re.search(r'\brequires\s*=\s*\{([^}]*)\}', entry)
            applies_m = re.search(r'\bappliesTo\s*=\s*\{([^}]*)\}', entry)
            if not label_m:
                break
            requires = [_quoted_value(q) for q in re.findall(_QUOTED, req_m.group(1))] if req_m else []
            applies_to = [_quoted_value(q) for q in re.findall(_QUOTED, applies_m.group(1))] if applies_m else []
            capstones.append({
                "key":        name,
                "label":      _quoted_value(label_m.group(1).strip()),
                "bonus":      float(bonus_m.group(1)) if bonus_m else 0.0,
                "requires":   requires,
                "appliesTo":  applies_to,
            })
            break

    return capstones


def _parse_hunt_targets(text: str, guild_order: list[str]) -> dict[str, list[dict]]:
    m = re.search(r'\bhuntTargets\s*=\s*\{', text)
    if not m:
        return {}
    for start, end in _balanced_blocks(text[m.start():]):
        ht_block = text[m.start():][start:end]
        break
    else:
        return {}

    result: dict[str, list[dict]] = {}
    for guild_key in guild_order:
        gm = re.search(rf'\b{re.escape(guild_key)}\s*=\s*\{{', ht_block)
        if not gm:
            continue
        sub = ht_block[gm.start():]
        for gs, ge in _balanced_blocks(sub):
            guild_block = sub[gs:ge]
            targets = []
            for es, ee in _balanced_blocks(guild_block[1:]):
                entry = guild_block[1:][es:ee]
                tier_m    = re.search(r'\btier\s*=\s*(\d+)', entry)
                rep_m     = re.search(r'\bbaseRep\s*=\s*(\d+)', entry)
                label_m   = re.search(r'\blabel\s*=\s*(' + _QUOTED + r')', entry)
                zone_m    = re.search(r'\bzone\s*=\s*(' + _QUOTED + r')', entry)
                if not (tier_m and label_m):
                    continue
                raw_zone = _quoted_value(zone_m.group(1).strip()) if zone_m else ""
                targets.append({
                    "tier":    int(tier_m.group(1)),
                    "baseRep": int(rep_m.group(1)) if rep_m else 0,
                    "label":   _quoted_value(label_m.group(1).strip()),
                    "zone":    raw_zone.replace("_", " "),
                })
            result[guild_key] = sorted(targets, key=lambda t: t["tier"])
            break

    return result


# ---------------------------------------------------------------------------
# Renderers
# ---------------------------------------------------------------------------

def _render_ranks(ranks: list[dict]) -> str:
    lines = [
        "| Rank | Rep needed | Amplifier |",
        "|---|---:|---:|",
    ]
    for r in ranks:
        pct = int(r["amplifier"] * 100)
        lines.append(f"| {r['label']} | {r['minRep']:,} | +{pct}% |")
    return "\n".join(lines)


def _render_capstones(capstones: list[dict], guilds: dict[str, dict]) -> str:
    lines = [
        "| Capstone | Requires | Bonus | Applies to |",
        "|---|---|---:|---|",
    ]
    for cap in capstones:
        # Build "requires" description
        req_labels = [guilds[k]["label"] if k in guilds else k for k in cap["requires"]]
        if len(cap["requires"]) == 4:
            requires_str = "Grandmaster in **all four** guilds"
        else:
            requires_str = "Grandmaster in " + " + ".join(req_labels)

        # Build "applies to" description
        applies = cap["appliesTo"]
        if set(applies) == {"af", "relic", "empy", "hl"}:
            applies_str = "All marks, supersedes Trinity"
        elif set(applies) == {"af", "relic", "empy"}:
            applies_str = "All Reforge marks (AF/Relic/Empy)"
        else:
            applies_str = ", ".join(guilds[k]["markType"] if k in guilds else k for k in applies)

        pct = int(cap["bonus"] * 100)
        lines.append(
            f"| **{cap['label']}** | {requires_str} | **+{pct}%** | {applies_str} |"
        )
    return "\n".join(lines)


def _render_hunt_targets(hunt_targets: dict[str, list[dict]], guilds: dict[str, dict], guild_order: list[str]) -> str:
    lines = ['<div class="milestone-grid" markdown="1">', ""]

    for guild_key in guild_order:
        if guild_key not in hunt_targets:
            continue
        targets = hunt_targets[guild_key]
        guild_label = guilds[guild_key]["label"] if guild_key in guilds else guild_key

        lines.append(f"#### {guild_label}")
        lines.append("")
        lines.append("| Tier | NM | Zone | Rep reward |")
        lines.append("|---|---|---|---:|")

        for t in targets:
            stars = "★" * t["tier"]
            lines.append(f"| {stars} | {t['label']} | {t['zone']} | {t['baseRep']:,} |")

        lines.append("")

    lines.append("</div>")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/hunters_guild_catalog.lua")
    if src is None:
        print("[hunters_guild] skip: hunters_guild_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")

    page = docs_dir / "progression" / "hunters-guild.md"
    if not page.exists():
        print(f"[hunters_guild] skip: target page {page} not found")
        return

    ranks       = _parse_ranks(text)
    guild_order = _parse_guild_order(text)
    guilds      = _parse_guilds(text)
    capstones   = _parse_capstones(text)
    hunt_targets = _parse_hunt_targets(text, guild_order)

    # --- ranks ---
    ranks_content = _render_ranks(ranks)
    wrote = write_between_markers(page, "hunters-guild-ranks", ranks_content)
    if wrote:
        print(f"[hunters_guild] ranks: {len(ranks)} ranks written into marker")
    else:
        print(f"[hunters_guild] ranks: marker 'hunters-guild-ranks' not found in {page.name}")

    # --- capstones ---
    caps_content = _render_capstones(capstones, guilds)
    wrote = write_between_markers(page, "hunters-guild-capstones", caps_content)
    if wrote:
        print(f"[hunters_guild] capstones: {len(capstones)} capstones written into marker")
    else:
        print(f"[hunters_guild] capstones: marker 'hunters-guild-capstones' not found in {page.name}")

    # --- hunt targets ---
    targets_content = _render_hunt_targets(hunt_targets, guilds, guild_order)
    wrote = write_between_markers(page, "hunters-guild-hunt-targets", targets_content)
    if wrote:
        total_targets = sum(len(v) for v in hunt_targets.values())
        print(f"[hunters_guild] hunt-targets: {total_targets} NMs across {len(hunt_targets)} guilds written into marker")
    else:
        print(f"[hunters_guild] hunt-targets: marker 'hunters-guild-hunt-targets' not found in {page.name}")
