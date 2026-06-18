"""Export the live Lua catalogs to a single ``catalog.json`` data file.

This is the *single source of truth* bridge between the game's Lua catalogs
and everything that needs to mirror them outside Lua — chiefly the Discord
bot, which used to hand-copy guild names, dungeon ids, and achievement
metadata into Python and inevitably drifted (wrong guild label, a missing
4th dungeon, missing Infamy achievements).

Rather than each consumer re-parsing Lua, this generator parses the catalogs
once (via the shared ``tools/docgen/_lua.py`` primitives) and emits a compact,
stable JSON document. Consumers read the JSON; when a catalog changes, one
``refresh-site.bat`` run re-exports and every consumer is back in sync.

Sources (all normally gitignored, live-only):
  - modules/custom/lua/hunters_guild_catalog.lua   -> guild_ranks, guilds, capstones
  - modules/custom/lua/dungeon_catalog.lua          -> dungeons
  - modules/custom/lua/achievements.lua             -> achievements
  - modules/custom/lua/custom_HNM_system.lua        -> hnm  (OPTIONAL — best effort)
  - modules/custom/lua/seasonal_events_catalog.lua  -> seasonal_events  (OPTIONAL)

Outputs (identical content, written to both):
  - <repo_root>/tools/docgen/catalog.json
        Committed copy on the docs branch (part of refresh-site's SITE_PATHS),
        so the data travels with the docs and CI/site builds can see it.
  - <LEGENDARY_LIVE_ROOT>/tools/discord_bot/catalog.json   (only when LIVE set)
        Runtime copy that sits next to the Discord bot on the live checkout.
        This is the cross-branch bridge: the bot lives on a different branch
        than docgen, so we hand it its own sibling copy to read at startup.

The JSON carries NO timestamp — only a ``_comment``. That keeps the file
byte-stable across runs unless the underlying catalog data actually changed,
so it doesn't churn the git history on every refresh.

Like every docgen generator, this skips cleanly when its sources aren't
available (e.g. CI without ``$LEGENDARY_LIVE_ROOT``) rather than clobbering
the committed copy with an empty/partial document.
"""
from __future__ import annotations

import json
import os
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._lua import (
    table_body,
    entry_blocks,
    map_entries,
    field_str,
    field_num,
    field_bool,
    field_str_list,
)
# The HNM module is imperative (addOverride hooks), not a declarative catalog,
# so we reuse the same parser that drives progression/hnm.md. Importing it here
# means the Discord bot's spawn-alert roster (exported below) can't drift from
# the HNM doc page — one parser feeds both.
from tools.docgen.generators.hnm import parse as _parse_hnm_raw, _window_str as _fmt_hnm_window
# Seasonal bonus-mark events share their parser with the status page's
# "Active Events" panel (generators/status.py), so the scheduled events
# exported here can't drift from what the site renders — same single-parser
# discipline as the HNM roster above.
from tools.docgen.generators.events import _parse_catalog_events

_COMMENT = (
    "GENERATED FILE — do not edit by hand. Exported from the live Lua catalogs "
    "by tools/docgen/generators/catalog_json.py. Single source of truth for the "
    "Discord bot and docs. Regenerate with refresh-site.bat (or "
    "`python tools/docgen/generate.py`). amplifier/bonus are fractions (0.25 = +25%)."
)


def _parse_guild_catalog(text: str) -> dict:
    """guild_ranks[], guilds[] (in catalog.guildOrder), capstones[]."""
    ranks = []
    ranks_body = table_body(text, "catalog.ranks")
    if ranks_body is not None:
        for inner in entry_blocks(ranks_body):
            ranks.append({
                "idx": field_num(inner, "idx"),
                "label": field_str(inner, "label"),
                "minRep": field_num(inner, "minRep"),
                "amplifier": field_num(inner, "amplifier"),
            })

    by_key: dict[str, dict] = {}
    guilds_body = table_body(text, "catalog.guilds")
    if guilds_body is not None:
        for key, inner in map_entries(guilds_body):
            if key is None:
                continue
            by_key[key] = {
                "key": field_str(inner, "key") or key,
                "label": field_str(inner, "label"),
                "markType": field_str(inner, "markType"),
                "repCv": field_str(inner, "repCv"),
                "lifetimeCv": field_str(inner, "lifetimeCv"),
                "isReforge": field_bool(inner, "isReforge"),
            }
    order = field_str_list(text, "catalog.guildOrder") or list(by_key)
    guilds = [by_key[k] for k in order if k in by_key]
    # Append any guild missing from guildOrder so nothing silently drops.
    guilds += [by_key[k] for k in by_key if k not in order]

    capstones = []
    caps_body = table_body(text, "catalog.capstones")
    if caps_body is not None:
        for key, inner in map_entries(caps_body):
            capstones.append({
                "key": key,
                "label": field_str(inner, "label"),
                "achievedCv": field_str(inner, "achievedCv"),
                "requires": field_str_list(inner, "requires"),
                "bonus": field_num(inner, "bonus"),
                "appliesTo": field_str_list(inner, "appliesTo"),
            })

    return {"guild_ranks": ranks, "guilds": guilds, "capstones": capstones}


def _parse_dungeons(text: str) -> list[dict]:
    """dungeons[] — id, label, infamyBase, and the derived clear CharVar."""
    out = []
    body = table_body(text, "catalog.dungeons")
    if body is None:
        return out
    for inner in entry_blocks(body):
        did = field_str(inner, "id")
        if not did:
            continue
        out.append({
            "id": did,
            "label": field_str(inner, "label"),
            "infamyBase": field_num(inner, "infamyBase"),
            "clearCv": "Dungeon_Clears_%s" % did,
        })
    return out


def _parse_achievements(text: str) -> list[dict]:
    """achievements[] — every MILESTONE with its derived ACH_<id> CharVar."""
    out = []
    body = table_body(text, "MILESTONES")
    if body is None:
        return out
    for inner in entry_blocks(body):
        aid = field_str(inner, "id")
        if not aid:
            continue
        out.append({
            "id": aid,
            "cv": "ACH_%s" % aid,
            "reward": field_num(inner, "reward"),
            "announce": field_bool(inner, "announce"),
            "title": field_str(inner, "title"),
            "desc": field_str(inner, "desc"),
        })
    return out


def _parse_hnm(text: str) -> list[dict]:
    """hnm[] — the timed Kings and lower HNMs the Discord bot watches.

    Only NQ (timed) mobs have a [HNM]<Name> ServerVar; HQ kings are QM-pop
    with no timer so they're omitted. Each entry carries the var the bot diffs
    plus a friendly name/zone/window for the alert text.
    """
    result = _parse_hnm_raw(text)
    out = []
    for z in result.get("kings", []):
        name = z.get("nq", "")
        if not name:
            continue
        out.append({
            "var": f"[HNM]{name}",
            "name": name,
            "zone": z.get("zone") or "",
            "window": _fmt_hnm_window(z["win_min"], z["win_max"]),
        })
    for z in result.get("lower", []):
        name = z.get("nm", "")
        if not name:
            continue
        out.append({
            "var": f"[HNM]{name}",
            "name": name,
            "zone": z.get("zone") or "",
            "window": _fmt_hnm_window(z["win_min"], z["win_max"]),
        })
    return out


def generate(repo_root: Path, docs_dir: Path) -> None:  # docs_dir unused
    guild_src = resolve_source(repo_root, "modules/custom/lua/hunters_guild_catalog.lua")
    dungeon_src = resolve_source(repo_root, "modules/custom/lua/dungeon_catalog.lua")
    ach_src = resolve_source(repo_root, "modules/custom/lua/achievements.lua")

    missing = [
        name for name, p in (
            ("hunters_guild_catalog.lua", guild_src),
            ("dungeon_catalog.lua", dungeon_src),
            ("achievements.lua", ach_src),
        ) if p is None
    ]
    if missing:
        # Don't overwrite the committed catalog.json with a partial document.
        print(f"[catalog_json] skipping — source(s) not found: {', '.join(missing)}")
        return

    data: dict = {"_comment": _COMMENT}
    data.update(_parse_guild_catalog(guild_src.read_text(encoding="utf-8", errors="replace")))
    data["dungeons"] = _parse_dungeons(dungeon_src.read_text(encoding="utf-8", errors="replace"))
    data["achievements"] = _parse_achievements(ach_src.read_text(encoding="utf-8", errors="replace"))

    # HNM roster is OPTIONAL/additive (the Discord bot's spawn-alert feed). If
    # the module is missing or its structure changed under the parser, emit
    # hnm = [] rather than failing the whole export — the three catalogs above
    # are what most consumers depend on. The bot also reads [HNM]% ServerVars
    # directly, so an empty roster only costs the pretty name/zone, not the alert.
    hnm_src = resolve_source(repo_root, "modules/custom/lua/custom_HNM_system.lua")
    if hnm_src is not None:
        try:
            data["hnm"] = _parse_hnm(hnm_src.read_text(encoding="utf-8", errors="replace"))
        except Exception as e:  # noqa: BLE001
            print(f"[catalog_json] HNM parse failed ({e}); emitting hnm = []")
            data["hnm"] = []
    else:
        print("[catalog_json] custom_HNM_system.lua not found; emitting hnm = []")
        data["hnm"] = []

    # Seasonal bonus-mark events (scheduled, static catalog). OPTIONAL/additive,
    # like the HNM roster: the Discord announcer reads these to post when an
    # event opens/closes. The catalog is usually empty (events are added by
    # hand for holidays), so [] is the normal, byte-stable state. The ephemeral
    # GM !setbonus events live in seasonal_events_dynamic.lua and are
    # deliberately NOT exported — they'd churn this committed file; the live
    # status panel reads that file directly instead. Sorted by (start, name)
    # so the JSON stays byte-stable regardless of source order.
    se_src = resolve_source(repo_root, "modules/custom/lua/seasonal_events_catalog.lua")
    if se_src is not None:
        try:
            events = _parse_catalog_events(se_src.read_text(encoding="utf-8", errors="replace"))
            events.sort(key=lambda e: (e["start"], e["name"]))
            data["seasonal_events"] = events
        except Exception as e:  # noqa: BLE001
            print(f"[catalog_json] seasonal events parse failed ({e}); emitting seasonal_events = []")
            data["seasonal_events"] = []
    else:
        print("[catalog_json] seasonal_events_catalog.lua not found; emitting seasonal_events = []")
        data["seasonal_events"] = []

    payload = json.dumps(data, indent=2, sort_keys=True, ensure_ascii=False) + "\n"

    # 1) Committed copy that travels with the docs branch.
    out_repo = repo_root / "tools" / "docgen" / "catalog.json"
    out_repo.write_text(payload, encoding="utf-8")
    print(
        f"[catalog_json] wrote {out_repo}  "
        f"({len(data['guilds'])} guilds, {len(data['dungeons'])} dungeons, "
        f"{len(data['achievements'])} achievements, {len(data['hnm'])} HNM, "
        f"{len(data['seasonal_events'])} seasonal events)"
    )

    # 2) Runtime copy next to the live Discord bot (cross-branch bridge).
    live = os.environ.get("LEGENDARY_LIVE_ROOT")
    if live:
        bot_dir = Path(live) / "tools" / "discord_bot"
        if bot_dir.is_dir():
            out_bot = bot_dir / "catalog.json"
            out_bot.write_text(payload, encoding="utf-8")
            print(f"[catalog_json] wrote {out_bot}")
        else:
            print(f"[catalog_json] live bot dir not found, skipping bot copy: {bot_dir}")
