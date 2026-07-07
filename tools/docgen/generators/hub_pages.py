"""Generate the two hub NPC-directory pages from the live NPC modules.

Owns (FULL-page writer — each file is rebuilt from scratch every run):
  - docs/progression/leafallia.md   (Leafallia — endgame hub)
  - docs/progression/library.md     (Celennia Memorial Library — beginner hub)

Sources:
  - tools/docgen/generators/npc_location_inject.py — the `_NPC_FILES`
    key -> module mapping and `_ZONE_PATTERNS` zone-resolution regexes are
    imported at run time so the two modules can never drift apart.
  - modules/custom/lua/<file> — each NPC module/catalog, parsed for the hub
    zone it registers in (same resolution npc_location_inject uses).
  - scripts/commands/<name>.lua — hub warp commands; a "reach it with !cmd"
    line is only emitted when the command file exists AND references the hub.

Each page lists exactly the NPCs whose module currently resolves to that hub,
so when an NPC moves hubs it migrates between the pages automatically. Keys
that resolve to neither hub (e.g. GM Home services) appear on neither page —
that is the design, not an error. Prose that names another custom NPC's zone
uses `{{npc:key}}` tokens, expanded post-generation by npc_location_inject.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source

# ---------------------------------------------------------------------------
# NPC directory
#
# key -> (display name, section tag, one-line blurb). Keys are the same keys
# npc_location_inject._NPC_FILES uses; blurbs were seeded from the vetted
# hand-written pages. Keys mapped in _NPC_FILES but absent here still render,
# via _fallback_entry(), in the "More services" section — so a newly-mapped
# NPC always appears somewhere without a code change in this file.
# ---------------------------------------------------------------------------

# Section tags. Each page decides which tags it renders (and their headings);
# any tag a page doesn't know — including "misc" — lands in "More services".
_SEC_MASTERY    = "mastery"
_SEC_AUGMENTS   = "augments"
_SEC_BATTLE     = "battle"
_SEC_TRAVEL     = "travel"
_SEC_CURRENCY   = "currency"
_SEC_ACTIVITIES = "activities"
_SEC_MISC       = "misc"

_NPCS: dict[str, tuple[str, str, str]] = {
    # -- weapons & mastery ---------------------------------------------------
    "prime_armory":      ("Prime Armory",            _SEC_MASTERY,
                          "Forge and upgrade Prime weapons through the five Armory trials."),
    "relic_forge":       ("Relic Forge",             _SEC_MASTERY,
                          "Forge Stage-5 Relic weapons (Lv.119 III) from Dynamis currency."),
    "weapon_forger":     ("Weapon Forger",           _SEC_MASTERY,
                          "Upgrade Lv.119 weapons along the forge chain (119 I → II → III) for seals and Reforge Marks."),
    "spell_mastery":     ("Spell & Skill Mastery",   _SEC_MASTERY,
                          "Empower weapon skills and spells with Mastery Sigils."),
    "job_mastery":       ("Job Mastery",             _SEC_MASTERY,
                          "Per-job mastery bonuses beyond the level cap."),
    "cross_job_ability": ("Cross-Job Ability Trainer", _SEC_MASTERY,
                          "Learn a selection of another job's abilities."),
    "cross_job_trait":   ("Cross-Job Trait Trainer", _SEC_MASTERY,
                          "Learn another job's passive traits."),
    # -- augments --------------------------------------------------------------
    "augment_moogle":    ("Augment Moogle",          _SEC_AUGMENTS,
                          "Trade one equipment piece + 1–4 catalyst crystals for stacking augments."),
    "augment_sage":      ("Augment Sage",            _SEC_AUGMENTS,
                          "Unlock augment affinities — passive stat bonuses — with hunt marks and NM trophies."),
    # -- battle content --------------------------------------------------------
    "apex":              ("Apex Trials",             _SEC_BATTLE,
                          "Climb endlessly-scaling boss tiers for Paragon Points."),
    "paragon":           ("Paragon",                 _SEC_BATTLE,
                          "Spend Paragon Points on the Paragon board."),
    "gauntlet":          ("The Gauntlet",            _SEC_BATTLE,
                          "Survival gauntlet against escalating NM waves."),
    "endless_tower":     ("Endless Tower",           _SEC_BATTLE,
                          "Affix-stacked tower climb for rewards."),
    "colosseum":         ("Colosseum",               _SEC_BATTLE,
                          "Arena matches against summoned challengers."),
    "htbf_vendor":       ("HTBF Vendor",             _SEC_BATTLE,
                          "Buy the phantom gems that open High-Tier Battlefields."),
    "infamy_vendor":     ("Infamy Vendor",           _SEC_BATTLE,
                          "Spend infamy (from Abyssea hunts, Invasions, and the weekly Raid) on gear."),
    "voidwatch":         ("Voidwatch Officer",       _SEC_BATTLE,
                          "Buy Voidstones and spend Voidwatch shards at the Atmacite Refiner."),
    "void_keeper":       ("Void Keeper",             _SEC_BATTLE,
                          "Bind the custom trusts — Gemma and company — for Hunt Marks."),
    "dungeon_guide":     ("Dungeon Guide",           _SEC_BATTLE,
                          "Open instanced dungeon runs."),
    # -- getting around & set-up ------------------------------------------------
    "home_point":        ("Homepoint",               _SEC_TRAVEL,
                          "Set your home point and teleport between unlocked ones."),
    "warpman":           ("Warpman",                 _SEC_TRAVEL,
                          "Paid gil warps to the cities, expansion areas, remote zones, and endgame spots."),
    "race_changer":      ("Race Changer",            _SEC_TRAVEL,
                          "Change your character's race for gil."),
    # -- currencies & exchanges --------------------------------------------------
    "gil_exchange":      ("Gil Exchange",            _SEC_CURRENCY,
                          "Trade hunt marks for gil in bulk."),
    "sparks_exchange":   ("Sparks Exchange",         _SEC_CURRENCY,
                          "Spend Sparks of Eminence on gear and items."),
    "crafting_exchange": ("Crafting Exchange",       _SEC_CURRENCY,
                          "Trade for crafting materials."),
    "title_broker":      ("Title Broker",            _SEC_CURRENCY,
                          "Buy cosmetic titles for gil."),
    "cosmetic_shop":     ("Cosmetic Shop",           _SEC_CURRENCY,
                          "Pure-cosmetic outfits and hats, bought with Allied Notes."),
    # -- activities & boards -------------------------------------------------------
    "daily_board":       ("Daily Board",             _SEC_ACTIVITIES,
                          "Pick up and turn in daily objectives."),
    "hunt_board":        ("Hunt Board",              _SEC_ACTIVITIES,
                          "Weekly NM-target bounties — turn them in for hunt marks."),
    "unity":             ("Unity",                   _SEC_ACTIVITIES,
                          'Unity Concord "Wanted" NM fights.'),
    "casino":            ("Casino",                  _SEC_ACTIVITIES,
                          "Gil-sink gambling games (Lady Luck)."),
    "mystery_mog":       ("Mystery Mog",             _SEC_ACTIVITIES,
                          "Gacha box — spend hunt marks for a random reward pull."),
    "chocobo_derby":     ("Chocobo Derby",           _SEC_ACTIVITIES,
                          "Chocobo racing and betting."),
    # -- misc ------------------------------------------------------------------
    "test_dummy":        ("Test Dummy",              _SEC_MISC,
                          "Combat dummy for DPS testing."),
}

# Hub NPCs that live in modules/custom/lua but aren't (yet) in
# npc_location_inject._NPC_FILES. Same file-name convention; resolved with the
# same zone patterns. Remove an entry here once it graduates into _NPC_FILES.
_EXTRA_NPC_FILES: dict[str, str] = {
    "warpman": "gil_warp_npc.lua",
}


def _fallback_entry(key: str) -> tuple[str, str, str]:
    """A newly-mapped key with no blurb still gets a presentable row."""
    name = key.replace("_", " ").title()
    return name, _SEC_MISC, "Custom service NPC — talk to it in the hub to see what it offers."


# ---------------------------------------------------------------------------
# Page specs. Intros are the vetted hand-written paragraphs (constant).
# ---------------------------------------------------------------------------

# 2026-07-06: the three former hubs (Leafallia / Celennia Library / GM Home) were
# consolidated onto a single island plaza on Purgonorgo Isle (zone 44). One page
# now owns every service NPC; old leafallia.md / library.md are redirect stubs.
_PAGES = [
    {
        "zone":  "Abdhaljs_Isle-Purgonorgo",
        "out":   ("progression", "hub.md"),
        "title": "# Purgonorgo Isle — The Hub",
        "intro": (
            "Purgonorgo Isle is the relaunch's **one and only hub** — every custom "
            "service NPC, from getting-started tools to endgame progression, lives "
            "here on a single island plaza, spaced out so a crowd can shop at once. "
            "Reach it any time with the `!hub` command (the old `!leaf`, `!lib`, and "
            "`!gmhome` commands now land here too)."
        ),
        "sections": [
            (_SEC_TRAVEL,     "Getting around & set-up"),
            (_SEC_CURRENCY,   "Currencies & exchanges"),
            (_SEC_AUGMENTS,   "Augments"),
            (_SEC_MASTERY,    "Weapons & mastery"),
            (_SEC_BATTLE,     "Battle content"),
            (_SEC_ACTIVITIES, "Activities & boards"),
            (_SEC_MISC,       "More services"),
        ],
        # candidate warp-command basenames + strings that must appear in the
        # command file for the warp claim to be emitted at all
        "warp_commands":    ("hub", "leaf", "lib"),
        "warp_zone_tokens": ("ABDHALJS_ISLE_PURGONORGO", "Abdhaljs_Isle-Purgonorgo"),
    },
]


# ---------------------------------------------------------------------------
# Zone resolution (mirrors npc_location_inject._resolve_zone, but returns the
# RAW zone id so pages can bucket on it instead of the friendly display name)
# ---------------------------------------------------------------------------

def _resolve_raw_zone(lua_dir: Path, fname: str, patterns) -> str | None:
    path = lua_dir / fname
    if not path.exists():
        return None
    text = path.read_text(encoding="utf-8", errors="ignore")
    for pat in patterns:
        m = pat.search(text)
        if m:
            return m.group(1)
    return None


def _verify_warp_command(repo_root: Path, names: tuple[str, ...], zone_tokens: tuple[str, ...]) -> str | None:
    """Return the first command basename that exists AND references the hub
    zone. No file (or no zone reference) -> None -> no warp claim on the page."""
    for name in names:
        src = (resolve_source(repo_root, f"scripts/commands/{name}.lua")
               or resolve_source(repo_root, f"modules/custom/commands/{name}.lua"))
        if src is None:
            continue
        text = src.read_text(encoding="utf-8", errors="ignore")
        if any(tok in text for tok in zone_tokens):
            return name
    return None


# ---------------------------------------------------------------------------
# Page rendering
# ---------------------------------------------------------------------------

def _footer_lines(repo_root: Path, zone: str, zone_of) -> list[str]:
    if zone == "Leafallia":
        # The Test Dummy lives elsewhere; say where via the {{npc:...}} token so
        # the location stays live (expanded by npc_location_inject after this
        # generator runs). Skip the whole note if the dummy can't be resolved.
        if zone_of("test_dummy") is None or zone_of("test_dummy") == zone:
            return []
        note = "*The combat **Test Dummy** for DPS testing remains in {{npc:test_dummy}}"
        if resolve_source(repo_root, "scripts/commands/gmhome.lua") is not None:
            note += " (reach it with `!gmhome`)"
        note += ".*"
        return ["---", "", note, ""]
    if zone == "Celennia_Memorial_Library":
        return [
            "---",
            "",
            "*New-character set-up (weapon skills, spells, key items, missions, maps, etc.) "
            "is now granted **automatically at character creation** — there's no longer an "
            "Unlocker NPC to visit.*",
            "",
        ]
    return []


def _bucket(spec: dict, keys: list[str]) -> dict[str, list[tuple[str, str]]]:
    """Group the page's NPC keys into its section tags. Tags the page doesn't
    render (and unknown keys) collapse into the "More services" bucket."""
    known_tags = {tag for tag, _ in spec["sections"]}
    by_tag: dict[str, list[tuple[str, str]]] = {}
    for key in keys:
        name, tag, blurb = _NPCS.get(key) or _fallback_entry(key)
        if tag not in known_tags:
            tag = _SEC_MISC
        by_tag.setdefault(tag, []).append((name, blurb))
    return by_tag


def _render_page(repo_root: Path, spec: dict, by_tag: dict, zone_of) -> str:
    lines: list[str] = [spec["title"], "", spec["intro"], ""]

    warp = _verify_warp_command(repo_root, spec["warp_commands"], spec["warp_zone_tokens"])
    if warp:
        lines += [f"Reach it any time with the `!{warp}` command.", ""]

    for tag, heading in spec["sections"]:
        rows = by_tag.get(tag)
        if not rows:
            continue
        lines += [f"## {heading}", "", "| NPC | What it does |", "|---|---|"]
        for name, blurb in rows:
            lines.append(f"| **{name}** | {blurb} |")
        lines.append("")

    lines += _footer_lines(repo_root, spec["zone"], zone_of)
    return "\n".join(lines).rstrip() + "\n"


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    # Import at run time so a missing/renamed npc_location_inject fails this
    # generator closed instead of breaking the whole generator import batch.
    try:
        from tools.docgen.generators.npc_location_inject import _NPC_FILES, _ZONE_PATTERNS
    except Exception:
        print("[hub_pages] skip: npc_location_inject (_NPC_FILES/_ZONE_PATTERNS) not found")
        return

    src = resolve_source(repo_root, "modules")
    if src is None:
        print("[hub_pages] skip: modules/ not found")
        return
    lua_dir = src / "custom" / "lua"
    if not lua_dir.exists():
        print("[hub_pages] skip: modules/custom/lua not found")
        return

    npc_files: dict[str, str] = dict(_NPC_FILES)
    for key, fname in _EXTRA_NPC_FILES.items():
        npc_files.setdefault(key, fname)

    zones: dict[str, str | None] = {
        key: _resolve_raw_zone(lua_dir, fname, _ZONE_PATTERNS)
        for key, fname in npc_files.items()
    }

    def zone_of(key: str) -> str | None:
        return zones.get(key)

    # Stable ordering: keys in _NPCS declaration order first (matches the
    # vetted pages), then any unknown newly-mapped keys alphabetically.
    known_order = {key: i for i, key in enumerate(_NPCS)}
    ordered_keys = sorted(npc_files, key=lambda k: (known_order.get(k, len(known_order)), k))

    for spec in _PAGES:
        keys = [k for k in ordered_keys if zones.get(k) == spec["zone"]]
        rel = "docs/" + "/".join(spec["out"])
        if not keys:
            print(f"[hub_pages] skip: no NPC modules resolved to {spec['zone']} — not writing {rel}")
            continue

        page = docs_dir.joinpath(*spec["out"])
        page.parent.mkdir(parents=True, exist_ok=True)
        by_tag = _bucket(spec, keys)
        content = _render_page(repo_root, spec, by_tag, zone_of)
        page.write_text(content, encoding="utf-8")

        n_sections = sum(1 for tag, _ in spec["sections"] if by_tag.get(tag))
        print(f"[hub_pages] wrote {rel} ({len(keys)} NPCs in {n_sections} sections)")
