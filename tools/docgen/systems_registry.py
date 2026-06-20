"""Single source of truth for the "What Legendary Does Differently" highlights
on docs/why-legendary.md.

The `differentiators` generator renders HEADLINE into the page's
`differentiators` marker block, then reconciles the registry against the live
system detail pages so a new system can never silently go un-highlighted again
(the way Ascension once did).

Each HEADLINE entry is a dict:
    name     Display name / id. Used as the bold lead-in when a blurb is
             auto-extracted, and in the drift report.
    text     OPTIONAL hand-written bullet markdown (everything after the "- ").
             When present it is emitted verbatim — this is where the punchy
             marketing copy lives. When omitted, the generator AUTO-EXTRACTS a
             blurb from `page` (its `!!! tip "Summary"` block, else its first
             paragraph) and renders `**{name}.** {blurb}`.
    page     OPTIONAL docs-relative detail page (e.g. "progression/prestige.md").
             Drives the auto-extracted blurb AND the drift reconciliation.
    covers   OPTIONAL extra detail pages this one bullet accounts for, so
             multi-system bullets (e.g. "No dead content") don't trip the
             drift check.
    modules  OPTIONAL modules/custom/lua files this system owns. Informational
             only (surfaced in the drift report); not required.

TO ADD A SYSTEM: drop a new entry here with a `page`. Leave `text` off to let
its blurb auto-fill from the detail page, or write `text` for marketing punch.
If you add a system detail page but forget to register it, the build prints a
DRIFT warning and lists it on docs/admin/unfeatured-systems.md until you either
feature it here or mark it skipped (IGNORE_PAGES, or another bullet's `covers`).
"""
from __future__ import annotations

HEADLINE = [
    {
        "name": "Fast progression, real endgame",
        "text": "**Fast progression, real endgame.** <!--setting:map.EXP_RATE-->3<!--/setting-->× mob EXP (and <!--setting:main.EXP_RATE:int-->10<!--/setting-->× from books, FoV/GoV & Records of Eminence) means you hit 99 in days, not months. But 99 is the *beginning*, not the finish line. The Hunting League, Reforge gear, augments, and a full tier of endgame events are all designed to hold your interest for months. There's always a next thing.",
    },
    {
        "name": "Hunting League",
        "page": "progression/index.md",
        "modules": ["HuntingLeague.lua", "hunting_league_catalog.lua"],
        "text": "**Hunting League — a custom 5-tier progression system.** Retail FFXI has NMs. Legendary turns them into a structured progression ladder. Five ranks, each harder than the last, each with meaningful rewards and increasing HL Point rates. If you love the hunt, this server was built for you.",
    },
    {
        "name": "Ascension",
        "page": "progression/prestige.md",
        "modules": ["Prestige_System.lua", "prestige_catalog.lua"],
        "text": "**Ascension — a prestige ladder above the level cap.** Reach the Hunting League's Legend tier and the Altar in Provenance opens. Re-clear the Nightmare Court — three ascension-only superbosses that get harder *and change* as you climb — and spend Hunt Marks to *ascend*, earning Ascension Points: a Job-Points-style currency poured into permanent, stacking stat boosts. It's tracked per main job, never wipes anything you've earned, and the prestige levels are uncapped — an endless Paragon tail to chase on the leaderboards.",
    },
    {
        "name": "Reforge system",
        "page": "progression/reforge.md",
        "modules": ["Reforge_System.lua", "reforge_catalog.lua", "reforge_mark_exchange_catalog.lua"],
        "text": "**Reforge system — three NM ladders to +3 BiS.** Kill Sky Gods for AF Marks. Kill Unity NMs for Relic Marks. Kill Abyssea NMs for Empy Marks. Each currency line upgrades a full armor set across four tiers. No RNG boxes, no cash shop — just the satisfaction of killing your way to best-in-slot.",
    },
    {
        "name": "Hunter's Guild",
        "page": "progression/hunters-guild.md",
        "covers": ["progression/hnm.md"],
        "modules": ["hunters_guild.lua", "hunters_guild_hunts.lua", "hunters_guild_catalog.lua", "custom_HNM_system.lua"],
        "text": "**Hunter's Guild — reputation that pays you back.** Four hunting guilds, each tied to one of the mark currencies, are climbed by tracking down classic HNMs scattered across Vana'diel — not by farming the spawners. Every rank you earn passively *amplifies* the marks that currency pays out, so the more of the world you hunt, the faster your Reforge and Hunting League grinds go. Reach Grandmaster across multiple guilds and the Trinity and Apex meta-bonuses unlock.",
    },
    {
        "name": "Augment Moogle",
        "page": "progression/augments.md",
        "covers": ["progression/augment-sage.md"],
        "modules": ["Augment_Moogle.lua", "augment_catalog.lua", "Augment_Sage.lua", "augment_sage_catalog.lua"],
        "text": "**Augment Moogle — 400+ ways to customize your gear.** Catalysts drop from monsters all over the world. Trade them to the Augment Moogle to apply permanent stat bonuses to your gear. Stack them with the Augment Sage (whose power scales with your NM kill history) and you can push gear further than retail ever allowed.",
    },
    {
        "name": "Cross-Job Abilities",
        "page": "progression/cross-job-abilities.md",
        "covers": ["progression/cross-job-traits.md"],
        "modules": ["CrossJob_Trainer.lua", "cross_job_ability_catalog.lua",
                    "CrossJob_TraitTrainer.lua", "cross_job_trait_catalog.lua"],
        "text": "**Cross-Job Abilities — borrow from other jobs.** The Cross-Job Trainer in GM Home sells a hand-curated set of job abilities — self and party buffs and utility, like Meditate — that you can then use on *any* job via macro, with the recast enforced server-side. No 2-hours, no build-breaking picks: just the smart cross-pollination retail never allowed.",
    },
    {
        "name": "No dead content",
        "page": "progression/weekly-hunts.md",
        "covers": ["progression/daily-board.md", "progression/game-master.md"],
        "modules": ["weekly_hunts.lua", "daily_board.lua", "GameMaster.lua", "game_master_catalog.lua"],
        "text": "**No dead content — weekly objectives, daily board, Wave Master arena.** The Weekly Hunt Board resets every week with five fresh objectives. The Daily Board resets at midnight UTC. The Wave Master NPC in Escha - Ru'Aun spawns NM waves on demand. There is always a reason to log in.",
    },
    {
        "name": "Endgame & Events",
        "page": "endgame/star-devourer.md",
        "covers": [
            "endgame/voidspire.md",
            "endgame/endless-tower.md",
            "endgame/job-mastery.md",
            "endgame/colosseum.md",
            "endgame/invasions.md",
            "endgame/treasure-hunts.md",
            "endgame/chocobo-derby.md",
            "endgame/provisioners-league.md",
            "endgame/casino.md",
            "endgame/seasonal-events.md",
        ],
        "modules": ["RaidBoss.lua", "Voidspire.lua", "Colosseum.lua", "Invasion.lua",
                    "TreasureHunt.lua", "ChocoboDerby.lua", "ProvisionersLeague.lua", "Casino.lua"],
        "text": "**Endgame & Events — a whole tier of things to do at 99.** Take on **The Star-Devourer**, a weekly multi-phase raid boss; climb the endless **Voidspire** gauntlet for a leaderboard floor; duel level-scaled champions in the **Colosseum**; hold the line against scheduled **Invasions**; dig up buried **Treasure**; bet at the **Chocobo Derby**; rank up the fishing-and-crafting **Provisioners' League**; or push your luck at **Lady Luck's Casino** — plus rotating **Seasonal Events** that supercharge your hunts.",
    },
    {
        "name": "Prime Armory",
        "page": "progression/prime-armory.md",
        "modules": ["PrimeArmory_NPC.lua"],
        "text": "**Prime Armory — claim an apex Prime weapon.** Trade a Prime Voucher at the Prime Armory for one of twelve **Prime weapons**, the server's top weapon tier. Browse the full set in the menu and take the one built for your job.",
    },
    {
        "name": "Achievements & World Firsts",
        "page": "progression/achievements.md",
        "modules": ["achievements.lua", "world_first_announcements.lua"],
        "text": "**Achievements & World Firsts.** Hit a personal milestone and you bank bonus Hunt Marks plus an in-game shout-out. Be the *first on the server* to pull something off and everyone hears about it — world-first announcements give the race to the top real stakes.",
    },
    {
        "name": "Leaderboards",
        "page": "community/leaderboards.md",
        "modules": ["leaderboard_npc.lua", "online_tracker.lua", "level_99_tracker.lua"],
        "text": "**Leaderboards — see where you rank.** The Chronicler at Reisenjima Henge tallies your kills, unique NMs, and competitive stats, and a live website ranks every player server-wide, refreshed from the database through the day. Whether you're chasing Paragon levels or the longest hunt streak, there's always a scoreboard watching.",
    },
    {
        "name": "A deep quality-of-life bench",
        "page": "progression/server-features.md",
        "covers": [
            "progression/capacity-farm.md",
            "progression/subjob-exp.md",
            "progression/death-penalty.md",
            "progression/login-rewards.md",
            "progression/meat.md",
            "progression/skoll.md",
            "progression/corvus.md",
            "progression/gm-home.md",
            "progression/gear-progression.md",
            "progression/title-vendor.md",
            "economy/sparks-exchange.md",
            "economy/gil-exchange.md",
            "economy/race-changer.md",
            "economy/home-point.md",
            "economy/reforge-mark-exchange.md",
            "community/player-trusts.md",
        ],
        "text": "**A deep quality-of-life bench.** Always-popped NMs (no camping, no lottery), a Character Upgrader that hands a new character everything in one click, homepoint healing, zone-in cutscene skips, sub-job EXP share, gil-sink vendors, seasonal events, login streaks — dozens of friction-removers, all catalogued on the [Quality of Life Features](progression/server-features.md) page.",
    },
    {
        "name": "Everything unlocked at character creation",
        "text": "**Everything unlocked at character creation.** No quest to unlock advanced jobs. No tour of outpost warps. No waiting for maps. You create a character and immediately have access to everything that retail made you spend weeks unlocking. The friction that doesn't make the game better is just gone.",
    },
]

# Detail pages that are intentionally NOT headline systems (guides, reference,
# meta). Kept out of the drift report so it only ever surfaces real
# un-highlighted *systems*.
IGNORE_PAGES = {
    "progression/gear-vendors.md",
    "progression/gear-guide.md",
    "progression/bis-guide.md",
    "progression/gear-finder.md",
    "progression/item-database.md",
    "community/status.md",
    "community/faq.md",
    "community/highlights.md",
}
