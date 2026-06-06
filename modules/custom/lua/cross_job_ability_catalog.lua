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
            { id =  35, name = 'Provoke',   job = 'WAR', lvl =  5, desc = 'Increases enmity toward an enemy.' },
            { id =  31, name = 'Berserk',    job = 'WAR', lvl = 15, desc = 'Boosts attack; lowers defense.' },
            { id =  33, name = 'Defender',   job = 'WAR', lvl = 25, desc = 'Boosts defense; lowers attack.' },
            { id =  34, name = 'Aggressor',  job = 'WAR', lvl = 45, desc = 'Boosts accuracy; lowers evasion.' },
            { id =  32, name = 'Warcry',     job = 'WAR', lvl = 35, desc = 'Party-wide attack boost (AoE).' },
            { id = 267, name = 'Blood Rage', job = 'WAR', lvl = 87, desc = 'Party-wide critical hit rate boost (AoE).' },
        },
    },
    {
        name = 'Monk',
        abilities =
        {
            { id =  39, name = 'Boost',         job = 'MNK', lvl =  5, desc = 'Stores an attack boost for your next hit.' },
            { id =  37, name = 'Dodge',         job = 'MNK', lvl = 15, desc = 'Boosts evasion.' },
            { id =  36, name = 'Focus',         job = 'MNK', lvl = 25, desc = 'Boosts accuracy.' },
            { id =  38, name = 'Chakra',        job = 'MNK', lvl = 35, desc = 'Restores HP (scales with your level).' },
            { id =  40, name = 'Counterstance', job = 'MNK', lvl = 45, desc = 'Greatly boosts counter rate; lowers defense.' },
            { id = 151, name = 'Mantra',        job = 'MNK', lvl = 77, desc = 'Party-wide maximum HP boost (AoE).' },
        },
    },
    {
        name = 'Thief',
        abilities =
        {
            { id =  41, name = 'Steal',        job = 'THF', lvl =  5, desc = 'Attempt to steal an item from an enemy.' },
            { id =  44, name = 'Sneak Attack', job = 'THF', lvl = 15, desc = 'Guarantees a critical hit from behind on your next attack.' },
            { id =  42, name = 'Flee',         job = 'THF', lvl = 25, desc = 'Greatly boosts movement speed briefly.' },
            { id =  76, name = 'Trick Attack', job = 'THF', lvl = 30, desc = 'Shifts enmity to a party member behind you.' },
            { id =  45, name = 'Mug',          job = 'THF', lvl = 35, desc = 'Attempt to steal gil from an enemy.' },
            { id =  43, name = 'Hide',         job = 'THF', lvl = 45, desc = 'Attempt to drop enmity and hide from enemies.' },
        },
    },
    {
        name = 'Samurai',
        abilities =
        {
            { id =  62, name = 'Third Eye', job = 'SAM', lvl = 15, desc = 'Anticipate (evade) your next incoming attack.' },
            { id =  63, name = 'Meditate',  job = 'SAM', lvl = 30, desc = 'Gradually builds TP over time.' },
            { id = 230, name = 'Sekkanoki', job = 'SAM', lvl = 40, desc = 'Lets you use a weapon skill at only 1000 TP.' },
        },
    },
    {
        name = 'Paladin/DRK',
        abilities =
        {
            { id =  47, name = 'Holy Circle',   job = 'PLD', lvl =  5, desc = 'Resistance/defense vs undead (reduced off-job).' },
            { id =  48, name = 'Sentinel',      job = 'PLD', lvl = 30, desc = 'Greatly boosts defense and enmity briefly.' },
            { id =  50, name = 'Arcane Circle', job = 'DRK', lvl =  5, desc = 'Resistance/defense vs arcana (reduced off-job).' },
            { id =  51, name = 'Last Resort',   job = 'DRK', lvl = 15, desc = 'Boosts attack; lowers defense.' },
            { id =  49, name = 'Souleater',     job = 'DRK', lvl = 30, desc = 'Adds part of your HP to melee damage, costing HP.' },
            { id =  92, name = 'Rampart',       job = 'PLD', lvl = 62, desc = 'Party-wide damage-reduction ward (AoE).' },
            { id =  79, name = 'Cover',         job = 'PLD', lvl = 35, desc = 'Intercept melee attacks aimed at a party member.' },
        },
    },
    {
        name = 'Mage',
        abilities =
        {
            { id =  74, name = 'Divine Seal',    job = 'WHM', lvl = 15, desc = 'Doubles the potency of your next healing spell.' },
            { id =  75, name = 'Elemental Seal', job = 'BLM', lvl = 15, desc = 'Boosts accuracy of your next elemental spell.' },
            { id =  83, name = 'Convert',        job = 'RDM', lvl = 40, desc = 'Swaps your current HP and MP.' },
            { id = 233, name = 'Sublimation',    job = 'SCH', lvl = 45, desc = 'Stores HP as MP over time; release for a big MP refund.' },
            { id = 247, name = 'Composure',      job = 'RDM', lvl = 45, desc = 'Boosts accuracy; extends your self-cast enhancing magic.' },
            { id = 275, name = 'Spontaneity',    job = 'RDM', lvl = 76, desc = 'Your next spell is cast instantly and uninterrupted.' },
        },
    },
    {
        name = 'Dancer',
        abilities =
        {
            { id = 196, name = 'Spectral Jig',  job = 'DNC', lvl = 25, desc = 'Grants Sneak and Invisible at once.' },
            { id = 197, name = 'Chocobo Jig',   job = 'DNC', lvl = 45, desc = 'Boosts movement speed for a while.' },
            { id = 194, name = 'Healing Waltz', job = 'DNC', lvl = 50, desc = 'Removes one debuff from the target (costs TP).' },
        },
    },
    {
        name = 'Dragoon/RUN',
        abilities =
        {
            { id =  68, name = 'Super Jump', job = 'DRG', lvl = 50, desc = 'Leap away, erasing nearly all your enmity.' },
            { id = 370, name = 'Embolden',   job = 'RUN', lvl = 75, desc = 'Empowers your next enhancing magic spell.' },
        },
    },
}

return catalog
