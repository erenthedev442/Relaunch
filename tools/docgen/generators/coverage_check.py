"""Docs coverage guard (relaunch) — ENFORCES the owner rule that every custom
system is represented on the website.

For each player-facing custom catalog / system Lua under modules/custom, checks
that SOME docgen generator reads it (so it has a live, reconciling page). Any
system that is neither read by a generator NOR on the ALLOWLIST prints a loud
`[coverage_check] GAP` warning at the end of every docgen run.

When you add a new relaunch system you must do ONE of:
  * give it a generator + page (the generator reads its catalog -> it passes), OR
  * add its filename to ALLOWLIST below with a reason (internal-only, no page).
Never leave a system unclassified. See feedback_relaunch_docs_mandatory in memory.
"""
from __future__ import annotations

import os
from pathlib import Path

# Internal-only files that legitimately need NO player page. Keep reasons.
ALLOWLIST = {
    # pure mechanics / fixes (no player-facing "system")
    "DualWieldPersist.lua", "RngOverhaul.lua", "RealLevel_Tracker.lua",
    "WSTracker.lua", "AbysseaKICleanup.lua", "trust_progression_cap.lua",
    "BstJugPetOverhaul.lua",           # BST pet buff mechanic
    "Ascension_Companion.lua",         # disabled cosmetic pet
    # NPCs that READ an already-documented catalog (the catalog has the page)
    "Armor_NPC.lua",                   # armor_catalog -> armor_npc generator
    "GearProgression_NPC.lua",         # gear_progression_catalog -> weapons_npc/gear_guide
    "CraftingExchange_NPC.lua",        # -> crafting_exchange generator
    "ReforgeMarkExchange_NPC.lua",     # -> reforge_mark_exchange generator
    "Accessory_NPC.lua", "Weapons_NPC.lua",
    # thin wrappers / runtime / points pools (catalog or parent system is documented)
    "RanperreFarm.lua", "CapacityFarm.lua",     # capacity_farm/ranperre_farm catalogs have the page
    "UnityWantedInstances.lua",        # Unity documented via unity_concord
    # runtime system modules whose CONTENT is documented via their *_catalog.lua
    # (the catalog is what a generator reads -> the page exists; the module is logic)
    "Augment_Sage.lua",          # augment_sage_catalog -> augment_sage generator
    "ChocoboDerby.lua",          # chocobo_derby_catalog -> chocobo_derby generator
    "Colosseum.lua",             # colosseum_catalog -> colosseum generator
    "GameMaster.lua",            # gm_home / game_master generators
    "Prestige_System.lua",       # prestige_catalog -> prestige generator
    "ProvisionersLeague.lua",    # provisioners_league generator
    "TreasureHunt.lua",          # treasure_hunts generator
    # GM / test / minor NPCs
    "TestDummy.lua", "survival_guide_npc_catalog.lua",
    "gil_mystery_box_catalog.lua", "gil_warp_npc_catalog.lua",
    "test_dummy_catalog.lua", "new_player_starter.lua", "maat_infamy_fight.lua",
}


def _is_candidate(fname: str) -> bool:
    if not fname.endswith(".lua"):
        return False
    # a "system" = a *catalog* file, or a top-level System/NPC module (Uppercase).
    return ("catalog" in fname.lower()) or (fname[0].isupper())


def generate(repo_root: Path, docs_dir: Path) -> None:
    luadir = repo_root / "modules" / "custom" / "lua"
    if not luadir.exists():
        return
    # concatenate all generator source (this file's siblings)
    gensrc = ""
    gendir = Path(__file__).resolve().parent
    for f in os.listdir(gendir):
        if f.endswith(".py"):
            gensrc += (gendir / f).read_text(encoding="utf-8", errors="replace") + "\n"

    gaps = []
    for fname in sorted(os.listdir(luadir)):
        if not _is_candidate(fname) or fname in ALLOWLIST:
            continue
        if fname not in gensrc:      # no generator reads it
            gaps.append(fname)

    if gaps:
        print(f"[coverage_check] GAP: {len(gaps)} custom system(s) with NO docs page "
              f"(give each a generator+page OR add to ALLOWLIST):")
        for g in gaps:
            print(f"   !! {g}")
    else:
        print("[coverage_check] OK: every player-facing custom system has a page.")
