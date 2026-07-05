-----------------------------------
-- cross_job_ability_catalog.lua
--
-- The curated "safe set" of job abilities that can be purchased from the
-- Cross-Job Ability Trainer (GM Home) and then used on ANY job.
--
-- CURATION RULES (why these and not others):
--   * Self / party buffs + utility only. No pet, BST/SMN/PUP/DRG/COR
--     job-mechanic-coupled abilities (rolls, ready/sic, wyvern, etc).
--   * NO 2-hour abilities. (The C++ binding also hard-rejects any ability
--     whose recastId == 0, which is how every 2-hour is flagged, so this is
--     belt-and-suspenders.)
--   * Excluded abilities that do literally nothing off their home job, e.g.
--     Hasso (STR boost is 0 unless SAM main/sub) and Seigan/Sharpshot
--     (2H-weapon / ranged-only gated) -- they'd be dead 10M purchases.
--
-- Each ability id was verified against sql/abilities.sql. The `name` is the
-- exact display name the client knows, so players use a borrowed ability via
-- a macro:  /ja "Meditate" <me>
-- (Borrowed abilities do NOT appear in the in-game Job Abilities menu -- that
--  menu is built client-side per job from the game DATs and we can't add to
--  it. The server validates the macro via the usable-ability table, so the
--  ability works; its recast is server-enforced.)
--
-- The single source of truth for WHICH abilities are sold. The C++ binding
-- only enforces mechanical safety (valid id, not a 2-hour, fits the bitmask);
-- this file decides the actual menu.
-----------------------------------
local catalog = {}

-- Flat cost per ability, in gil.
catalog.GIL_COST = 10000000

-- Grouped for the (paginated) NPC menu. Keep each group's ability count and
-- label lengths modest -- customMenu caps title+labels at ~150 bytes per page.
catalog.groups =
{
    {
        name = 'Warrior',
        abilities =
        {
            { id =  31, name = 'Berserk',     job = 'WAR', lvl = 15, desc = 'Boosts attack; lowers defense.' },
            { id =  34, name = 'Aggressor',   job = 'WAR', lvl = 45, desc = 'Boosts accuracy; lowers evasion.' },
            { id =  32, name = 'Warcry',      job = 'WAR', lvl = 35, desc = 'Party-wide attack boost (AoE).' },
            { id = 267, name = 'Blood Rage',  job = 'WAR', lvl = 87, desc = 'Party-wide critical hit rate boost (AoE).' },
            { id = 226, name = 'Retaliation', job = 'WAR', lvl = 60, desc = 'Chance to counter melee attacks while standing.' },
        },
    },
    {
        name = 'Thief',
        abilities =
        {
            { id = 276, name = 'Conspirator', job = 'THF', lvl = 87, desc = 'Boosts accuracy and Subtle Blow; scales with nearby allies.' },
        },
    },
    {
        name = 'Samurai',
        abilities =
        {
            { id =  62, name = 'Third Eye', job = 'SAM', lvl = 15, desc = 'Anticipate (evade) your next incoming attack.' },
        },
    },
    {
        name = 'Paladin/DRK',
        abilities =
        {
            { id =  51, name = 'Last Resort', job = 'DRK', lvl = 15, desc = 'Boosts attack; lowers defense.' },
            { id =  49, name = 'Souleater',   job = 'DRK', lvl = 30, desc = 'Adds part of your HP to melee damage, costing HP.' },
        },
    },
}

return catalog
