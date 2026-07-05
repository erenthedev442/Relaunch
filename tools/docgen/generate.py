"""Run all doc generators.

Usage (from repo root):
    python tools/docgen/generate.py

Optional environment variable:
    LEGENDARY_LIVE_ROOT  Path to the live server checkout. When set,
                         generators that can't find their source in the
                         repo fall back to <LEGENDARY_LIVE_ROOT>/<path>.
                         Example: D:\\server

Behavior:
    Each generator runs in its own try/except — if one explodes, the
    others still run. A summary at the end lists which generators
    succeeded and which failed. Exit code is 0 unless every generator
    failed (the refresh-site.bat keeps going on partial-success).
"""
from __future__ import annotations

import os
import sys
import traceback
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
DOCS_DIR = REPO_ROOT / "docs"

sys.path.insert(0, str(REPO_ROOT))


def main() -> int:
    DOCS_DIR.mkdir(exist_ok=True)

    live = os.environ.get("LEGENDARY_LIVE_ROOT")
    if live:
        print(f"[docgen] LEGENDARY_LIVE_ROOT = {live}")
    else:
        print("[docgen] LEGENDARY_LIVE_ROOT not set — only repo-committed sources will be used")
    print(f"[docgen] repo_root = {REPO_ROOT}")
    print(f"[docgen] docs_dir  = {DOCS_DIR}")
    print()

    # Build the display-name -> item-id index (sql/item_basic.sql) up front so
    # every generator's item links + hover icons resolve to FFXIAH by id.
    from tools.docgen import _bgwiki
    _idx_n = _bgwiki.build_item_index(REPO_ROOT)
    print(f"[docgen] item index: {_idx_n} unambiguous item names -> ids")
    print()

    from tools.docgen import stamp
    from tools.docgen.generators import (
        achievements,
        ah_prices,
        crafting_exchange,
        hnm,
        abyssea_nms,
        tournament,
        missing_spells,
        accessories_npc,
        accessory_npc,
        armor_npc,
        augment_sage,
        augment_calculator,
        augments,
        catalog_json,
        changelog_relaunch,
        commands,
        cross_job_abilities,
        daily_board,
        death_penalty,
        job_rebirth,
        differentiators,
        drop_finder,
        economy,
        game_master,
        gear_finder,
        gm_home,
        gm_home_npcs,
        hunters_guild,
        hunting_league,
        infamy_npc,
        item_index,
        leaderboards,
        login_rewards,
        npc_location_inject,
        player_profiles,
        prestige,
        progression_map,
        progression_order,
        systems_map,
        rates_table,
        reforge,
        settings_inject,
        spells,
        status,
        trust_tiers,
        weapons_npc,
        weekly_hunts,
        # --- custom-systems pages (2026-06-14): Endgame & Events + vendors/trust ---
        casino,
        chocobo_derby,
        colosseum,
        maats_challenge,
        corvus,
        cross_job_traits,
        gear_progression,
        invasions,
        provisioners_league,
        seasonal_events,
        star_devourer,
        title_vendor,
        treasure_hunts,
        voidspire,
        apex_paragon,
        # economy/service NPCs (2026-06-14 follow-up): inline-config + a couple catalogs
        gil_exchange,
        home_point,
        prime_armory,
        prime_trials,
        race_changer,
        reforge_mark_exchange,
        sparks_exchange,
        # cosmetic Boutique daily-rotation page (2026-06-20)
        cosmetics,
        # previously-undocumented systems given pages 2026-06-20 (each parses
        # its own inline config / catalog, same shape as voidspire)
        endless_tower,
        job_mastery,
        # --- relaunch-only systems (2026-06-27): each parses its own catalog ---
        htbf,
        voidwatch,
        dungeon_instances,
        dynamis_divergence,
        fellow,
        spell_skill_mastery,
        gear_vs_retail,
        gauntlet,
        unity_concord,
        affinity_nms,
        weapon_forge,
    )

    # Snapshot existing last-updated footers BEFORE any generator runs.
    # Some generators (spells, commands) rewrite their pages from scratch
    # and would otherwise erase the footer — losing the previous timestamp.
    prior_stamps = stamp.capture_existing(DOCS_DIR)

    modules = [
        # catalog_json exports the live Lua catalogs (guilds, dungeons,
        # achievements) to tools/docgen/catalog.json — the single source of
        # truth the Discord bot reads so its tables can't drift from Lua.
        # Writes data only (no docs page); runs first, depends on nothing.
        ("catalog_json",     catalog_json),
        ("spells",           spells),
        # trust_tiers fills the summon-count ladder + locked custom-trust table
        # into the marker slot spells.py emits on reference/spells/trust.md.
        # MUST run after spells (which rewrites that page each run).
        ("trust_tiers",      trust_tiers),
        ("commands",         commands),
        ("rates_table",      rates_table),
        ("changelog",        changelog_relaunch),
        # gm_home_npcs reads catalog Lua files and fills the GM Home NPC
        # position table in docs/changes/index.md.
        ("gm_home_npcs",     gm_home_npcs),
        ("hunting_league",   hunting_league),
        # hnm parses the imperative custom_HNM_system.lua (addOverride hooks,
        # no catalog table) and renders the land-king pairs + lower-tier HNM
        # tables onto progression/hnm.md — correcting a badly drifted page.
        ("hnm",              hnm),
        # abyssea_nms reads AbysseaMarks.lua zoneConfig and fills the tiers
        # table and all reward tables on endgame/abyssea-nms.md.
        ("abyssea_nms",      abyssea_nms),
        # tournament reads the WAVES table from Tournament.lua and fills the
        # wave difficulty table on endgame/tournament.md.
        ("tournament",       tournament),
        # progression_order reads rank/dungeon/GM-wave/weekly catalogs and
        # generates the Recommended progression order on docs/progression/index.md.
        ("progression_order", progression_order),
        # progression_map regenerates the ENTIRE Progression Flow Map body on
        # getting-started/progression-map.md from ten live catalogs (owner
        # requirement 2026-07-05: the map must track the content). Fail-closed:
        # a parse error keeps the last good page instead of publishing holes.
        ("progression_map",  progression_map),
        # systems_map regenerates the ENTIRE Systems Map body on
        # getting-started/systems-map.md from the same live catalogs (owner
        # requirement 2026-07-05: like progression-map, the page must be 100%
        # connected to the content). Presence-gated rows drop retired systems;
        # fail-closed parses keep the last good page on error.
        ("systems_map",      systems_map),
        ("armor_npc",        armor_npc),
        ("weapons_npc",      weapons_npc),
        # accessories_npc reads the same hunting_league_catalog as
        # hunting_league does, but renders the Accessories Vendor's stock
        # (rewardCategories minus Seals) onto gear-vendors.md so players
        # see all three vendors on one page.
        ("accessories_npc",  accessories_npc),
        # accessory_npc (singular) reads the scored accessory_catalog.lua
        # and renders Bronze/Silver/Gold tier blocks on gear-vendors.md.
        # Parallel to armor_npc / weapons_npc but for jewelry slots.
        ("accessory_npc",    accessory_npc),
        # weekly_hunts reads weekly_hunts_catalog.lua and renders the
        # rotating objective pool + reset/bonus config onto
        # docs/progression/weekly-hunts.md.
        ("weekly_hunts",     weekly_hunts),
        # infamy_npc reads infamy_vendor_catalog.lua and renders the Infamy
        # Vendor's curated + auto-promoted stock onto gear-vendors.md. Runs
        # before item_index so the finder's infamy rows match this page.
        ("infamy_npc",       infamy_npc),
        # item_index aggregates every purchasable item across all four
        # vendor catalogs (armor/weapons/accessories/infamy) into one
        # alphabetical "where do I get it" table on
        # progression/item-finder.md. Reuses the four vendor parsers above
        # (so it can't drift from their pages); MUST run after them.
        ("item_index",       item_index),
        # cross_job_abilities reads cross_job_ability_catalog.lua and fills
        # the ability table on docs/progression/cross-job-abilities.md.
        ("cross_job_abilities", cross_job_abilities),
        # prestige reads prestige_catalog.lua and fills prestige.md marker blocks
        # (economy cost table, nightmare court bosses, AP spend table).
        ("prestige",         prestige),
        # daily_board reads daily_board_catalog.lua and fills daily-board.md
        # (objective pool and all-cleared reward).
        ("daily_board",      daily_board),
        # game_master reads game_master_catalog.lua and fills game-master.md
        # (difficulty tiers table, mob roster per difficulty).
        ("game_master",      game_master),
        # hunters_guild reads hunters_guild_catalog.lua and fills hunters-guild.md
        # (rank ladder, capstones, Vana'diel hunt targets by guild).
        ("hunters_guild",    hunters_guild),
        # death_penalty reads death_penalty.lua and fills death-penalty.md
        # (config summary table).
        ("death_penalty",    death_penalty),
        # job_rebirth reads job_rebirth_catalog.lua and fills job-rebirth.md
        # (NPC location, RP grant formula, EXP penalty table).
        ("job_rebirth",      job_rebirth),
        # gm_home reads test_dummy, gil_mystery_box, and gil_warp_npc catalogs
        # and fills gm-home.md (Test Dummy tiers, Mystery Mog pool, Warpman dests).
        ("gm_home",          gm_home),
        # login_rewards reads daily_login_bonus.lua and login_streak.lua and
        # fills login-rewards.md (daily bonus line, streak milestone table).
        ("login_rewards",    login_rewards),
        ("reforge",          reforge),
        ("augments",         augments),
        ("augment_sage",     augment_sage),
        ("augment_calculator", augment_calculator),
        # gear_finder builds docs/assets/gear-data.json for the interactive
        # Gear Finder page. Runs AFTER every item-granting source page so its
        # obtainability scan can see the freshly-generated item-links.
        ("gear_finder",      gear_finder),
        # drop_finder builds docs/assets/item-search-data.json for the Item
        # Database page (where each item drops + what it's used for). Reads the
        # live DB for drops; skips silently if the DB is unreachable (CI/laptop).
        ("drop_finder",      drop_finder),
        # leaderboards reads char_vars from the live DB. Skips silently
        # without LEGENDARY_LIVE_ROOT (CI), or if the DB is unreachable.
        ("leaderboards",     leaderboards),
        # economy reads aggregate gil/AH/population figures from the live DB
        # (anonymous, GM-excluded) onto community/economy.md. Same DB-skip
        # behavior as leaderboards on CI / unreachable DB.
        ("economy",          economy),
        # status writes a build-time snapshot onto community/status.md: a
        # population one-liner + the timed-HNM tracker (reads [HNM]% ServerVars
        # for pop times, reuses hnm.py's parser for the NM roster/windows).
        ("status",           status),
        # player_profiles also reads the live DB. Writes one .md per
        # character under docs/community/players/ plus an index. Profile
        # pages are excluded from the nav tree via
        # `validation.nav.omitted_files: info` in mkdocs.yml.
        ("player_profiles",  player_profiles),
        # --- new content generators (2026-06-04): fill formerly hand-written pages ---
        ("achievements",     achievements),
        ("ah_prices",        ah_prices),
        ("crafting_exchange", crafting_exchange),
        ("missing_spells",   missing_spells),
        # --- custom-systems pages (2026-06-14): each parses its own live catalog ---
        ("casino",              casino),
        ("colosseum",           colosseum),
        ("maats_challenge",     maats_challenge),
        ("invasions",           invasions),
        ("star_devourer",       star_devourer),
        ("voidspire",           voidspire),
        ("treasure_hunts",      treasure_hunts),
        ("chocobo_derby",       chocobo_derby),
        ("provisioners_league", provisioners_league),
        ("seasonal_events",     seasonal_events),
        ("cross_job_traits",    cross_job_traits),
        ("gear_progression",    gear_progression),
        ("title_vendor",        title_vendor),
        ("corvus",              corvus),
        # economy/service NPCs (2026-06-14 follow-up)
        ("sparks_exchange",      sparks_exchange),
        ("cosmetics",            cosmetics),
        ("gil_exchange",         gil_exchange),
        ("race_changer",         race_changer),
        ("home_point",           home_point),
        ("reforge_mark_exchange", reforge_mark_exchange),
        ("prime_armory",         prime_armory),
        ("prime_trials",         prime_trials),
        # newly-documented systems (2026-06-20): Endless Tower + Job Mastery
        # (the two solo Prime-Weapon trials) and the Bibiki Bay Capacity farm.
        ("endless_tower",        endless_tower),
        ("job_mastery",          job_mastery),
        # Apex Trials + Paragon (2026-06-22): infinite post-cap chase + meta board.
        ("apex_paragon",         apex_paragon),
        # relaunch-only systems (2026-06-27): HTBF, Boom job, Voidwatch,
        # Dynamis-Divergence, Fellow companion, Spell & Skill Mastery. Each
        # parses its own *_catalog.lua / module CONFIG and fills marker blocks.
        ("htbf",                 htbf),
        ("voidwatch",            voidwatch),
        ("dungeon_instances",    dungeon_instances),
        ("dynamis_divergence",   dynamis_divergence),
        ("fellow",               fellow),
        ("spell_skill_mastery",  spell_skill_mastery),
        ("gauntlet",             gauntlet),
        ("unity_concord",        unity_concord),
        ("affinity_nms",         affinity_nms),
        ("weapon_forge",         weapon_forge),
        # differentiators renders why-legendary.md's "What Legendary Does
        # Differently" list from systems_registry.py and writes a drift report
        # of any system detail page that isn't featured. Runs before
        # settings_inject so the EXP_RATE marker it emits gets substituted.
        ("gear_vs_retail",   gear_vs_retail),
        ("differentiators",  differentiators),
        # settings_inject MUST run after every generator that writes into
        # docs/, so its {{setting:X}} -> live-value substitutions land on
        # the final text (including content other generators just wrote).
        ("settings_inject",  settings_inject),
        # npc_location_inject substitutes {{npc:KEY}} -> the NPC's live hub zone,
        # same idea as settings_inject for rates. Runs last so locations land on
        # final text (incl. anything other generators just wrote).
        ("npc_location_inject", npc_location_inject),
    ]

    successes: list[str] = []
    failures: list[tuple[str, str]] = []  # (name, traceback)

    for name, module in modules:
        try:
            module.generate(REPO_ROOT, DOCS_DIR)
            successes.append(name)
        except Exception:
            tb = traceback.format_exc()
            failures.append((name, tb))
            print(f"[docgen] !!! {name} FAILED — continuing with remaining generators")
            print(tb)

    # Stamp every page with a "Last updated" footer last. Content-aware:
    # preserves the existing timestamp when a page's body didn't actually
    # change, so unchanged pages don't get noisy "today" stamps on every run.
    # Uses the prior_stamps snapshot taken before generators ran, so even
    # pages that get fully rewritten retain their real last-changed date.
    try:
        stamp.generate(REPO_ROOT, DOCS_DIR, prior=prior_stamps)
        successes.append("stamp")
    except Exception:
        tb = traceback.format_exc()
        failures.append(("stamp", tb))
        print(f"[docgen] !!! stamp FAILED — continuing")
        print(tb)

    print()
    print("=" * 60)
    print(f"[docgen] SUMMARY: {len(successes)} ok, {len(failures)} failed")
    print("=" * 60)
    if successes:
        print(f"  ok      : {', '.join(successes)}")
    if failures:
        print(f"  failed  : {', '.join(name for name, _ in failures)}")
        print()
        print("  Full tracebacks above. Site will publish with the sections")
        print("  that succeeded; failed sections keep their previous content.")

    # Only fail the script if EVERY generator died. Partial success is fine
    # — the refresh-site flow should still publish whatever did regenerate.
    return 1 if (failures and not successes) else 0


if __name__ == "__main__":
    sys.exit(main())
