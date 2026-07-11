"""Substitute each custom NPC's live hub zone into narrative markdown.

Mirrors settings_inject: write `{{npc:prime_armory}}` in any docs/**/*.md and it
expands to the NPC's current zone (parsed from its module/catalog), then stays in
sync on every refresh. So when an NPC moves (e.g. GM Home -> Leafallia) the docs
follow automatically instead of going stale — locations become generated, like
rates, instead of hand-written.

    Source:  The Prime Armory is in {{npc:prime_armory}}.
    Built:   The Prime Armory is in <!--npc:prime_armory-->Leafallia<!--/npc-->.

HTML comments render as nothing in MkDocs Material, so the page reads identically
to hand-written prose — just kept truthful.

Unknown / unresolvable keys are left as the literal token and reported as WARN.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source


# key -> module/catalog file under modules/custom/lua that sets the NPC's zone.
_NPC_FILES: dict[str, str] = {
    # Leafallia (endgame hub)
    "prime_armory":      "PrimeArmory_NPC.lua",
    "relic_forge":       "Relic_Forge.lua",
    "augment_moogle":    "Augment_Moogle.lua",
    "augment_sage":      "augment_sage_catalog.lua",
    "infamy_vendor":     "InfamyVendor.lua",
    "endless_tower":     "endless_tower.lua",
    "apex":              "ApexTrials.lua",
    "paragon":           "Paragon.lua",
    "gauntlet":          "TheGauntlet.lua",
    "job_mastery":       "job_mastery.lua",
    "colosseum":         "colosseum_catalog.lua",
    "cross_job_ability": "CrossJob_Trainer.lua",
    "cross_job_trait":   "CrossJob_TraitTrainer.lua",
    "void_keeper":       "trust_skoll.lua",
    "spell_mastery":     "SpellSkillMastery.lua",
    "htbf_vendor":       "HTBF_Vendor.lua",
    "voidwatch":         "Voidwatch.lua",
    # Celennia Memorial Library (beginner hub)
    "title_broker":      "gil_title_vendor.lua",
    "cosmetic_shop":     "Cosmetic_Shop.lua",
    "sparks_exchange":   "SparksExchange.lua",
    "gil_exchange":      "gil_exchange_npc.lua",
    "home_point":        "gm_home_homepoint.lua",
    "race_changer":      "gil_race_changer.lua",
    "casino":            "Casino.lua",
    "mystery_mog":       "gil_mystery_box.lua",
    "unity":             "unity_wanted.lua",
    "unity_board":       "unity_wanted.lua",
    "chocobo_derby":     "chocobo_derby_catalog.lua",
    "crafting_exchange": "crafting_exchange_catalog.lua",
    "daily_board":       "daily_board_catalog.lua",
    "hunt_board":        "weekly_hunts_catalog.lua",
    # GM Home
    # dungeon_catalog.lua (not DungeonInstances.lua) holds the literal
    # npc.zone = 'Abdhaljs_Isle-Purgonorgo'; DungeonInstances builds the zone via
    # string.format(..., catalog.npc.zone), which the zone patterns can't parse.
    "dungeon_guide":     "dungeon_catalog.lua",
    "test_dummy":        "test_dummy_catalog.lua",
    "weapon_forger":     "WeaponForge_NPC.lua",
    # npcPos.zone literal; DomainSpoils_NPC.lua places the NPC from this catalog.
    "domain_quartermaster": "domain_spoils_catalog.lua",
}

# Raw zone id -> friendly display name (reads naturally after "in ...").
_FRIENDLY: dict[str, str] = {
    "Abdhaljs_Isle-Purgonorgo":  "Purgonorgo Isle",
    # Legacy hubs (kept so historical references still resolve; all custom NPCs
    # were consolidated onto Purgonorgo Isle 2026-07-06).
    "Leafallia":                 "Leafallia",
    "Celennia_Memorial_Library": "the Celennia Memorial Library",
    "GM_Home":                   "GM Home",
}

# Tried in order; first match wins. The bare `zone = '...'` form is restricted to
# the known hub zones so a warp-destination `zone =` can't be mistaken for the home.
# NOTE: zone names can contain hyphens (Abdhaljs_Isle-Purgonorgo) -> [\w-], not \w.
_ZONE_PATTERNS = [
    re.compile(r"addOverride\(\s*['\"]xi\.zones\.([\w-]+)\.Zone\.onInitialize"),
    re.compile(r"zonePath\s*=\s*['\"]xi\.zones\.([\w-]+)['\"]"),
    re.compile(r"\bzone\s*=\s*['\"](Abdhaljs_Isle-Purgonorgo|Leafallia|Celennia_Memorial_Library|GM_Home)['\"]"),
]

_TOKEN_RE  = re.compile(r"\{\{\s*npc\s*:\s*([a-z0-9_]+)\s*\}\}")
_MARKER_RE = re.compile(r"<!--npc:([a-z0-9_]+)-->.*?<!--/npc-->", re.DOTALL)


def _resolve_zone(lua_dir: Path, key: str) -> str | None:
    fname = _NPC_FILES.get(key)
    if not fname:
        return None
    path = lua_dir / fname
    if not path.exists():
        return None
    text = path.read_text(encoding="utf-8", errors="ignore")
    for pat in _ZONE_PATTERNS:
        m = pat.search(text)
        if m:
            raw = m.group(1)
            return _FRIENDLY.get(raw, raw.replace("_", " "))
    return None


def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules")
    if src is None:
        print("[npc_location_inject] skip: modules/ not found")
        return
    lua_dir = src / "custom" / "lua"
    if not lua_dir.exists():
        print("[npc_location_inject] skip: modules/custom/lua not found")
        return

    cache: dict[str, str | None] = {}

    def zone_for(key: str) -> str | None:
        if key not in cache:
            cache[key] = _resolve_zone(lua_dir, key)
        return cache[key]

    files_changed = 0
    expansions = 0
    refreshes = 0
    missing: set[str] = set()

    for md in sorted(docs_dir.rglob("*.md")):
        text = md.read_text(encoding="utf-8")
        original = text

        def expand(m: re.Match) -> str:
            nonlocal expansions
            key = m.group(1)
            z = zone_for(key)
            if z is None:
                missing.add(key)
                return m.group(0)
            expansions += 1
            return f"<!--npc:{key}-->{z}<!--/npc-->"

        text = _TOKEN_RE.sub(expand, text)

        def refresh(m: re.Match) -> str:
            nonlocal refreshes
            key = m.group(1)
            z = zone_for(key)
            if z is None:
                missing.add(key)
                return m.group(0)
            refreshes += 1
            return f"<!--npc:{key}-->{z}<!--/npc-->"

        text = _MARKER_RE.sub(refresh, text)

        if text != original:
            md.write_text(text, encoding="utf-8")
            files_changed += 1

    print(f"[npc_location_inject] {expansions} new + {refreshes} refreshed across {files_changed} file(s)")
    if missing:
        print(f"[npc_location_inject] WARN unresolved npc keys: {sorted(missing)}")
