-----------------------------------
-- gil_title_vendor_catalog.lua
-- Buyable titles for the Title Broker NPC. Each entry is a real FFXI
-- title ID from scripts/enum/title.lua -- pay gil, title goes onto your
-- character. Players already-earned titles via gameplay get to "buy"
-- them displayed (player:setTitle just sets the active title).
--
-- To find more title IDs:
--   grep -i 'PROUD_LIBERATOR\|<flavor>' scripts/enum/title.lua
--
-- Each entry: { label, titleId, cost }
-----------------------------------
local catalog = {}

catalog.zoneId   = xi.zone.ABDHALJS_ISLE_PURGONORGO
catalog.zonePath = 'xi.zones.Abdhaljs_Isle-Purgonorgo'
catalog.npcName  = 'Title Broker'
catalog.npcLook  = 3017
catalog.npcPos   = { x = 511.000, y = -3.000, z = 556.000, rot = 64 }

-- Tiered title catalog. Cheap = silly flavor, mid = decent prestige,
-- expensive = rare endgame titles. Player can buy + display anything
-- here regardless of whether they've earned it.
-- IMPORTANT: customMenu's prompt packet caps the TITLE + every OPTION label
-- combined at ~150 bytes. The main menu has all four tier labels plus the
-- close button, so each tier label MUST stay terse or the bottom of the
-- menu gets truncated client-side (the whale-tier "(10M)" disappears,
-- followed by Close). Keep these labels short. The full cost is still
-- shown in the sub-menu title and in each purchase's confirmation.
catalog.tiers =
{
    {
        label = 'Cheap (10k)',
        cost  = 10000,
        titles =
        {
            { label = 'Fodderchief Flayer', titleId = xi.title.FODDERCHIEF_FLAYER },
            { label = 'Manifest Mauler',    titleId = xi.title.MANIFEST_MAULER },
            { label = 'Bogeydowner',        titleId = xi.title.BOGEYDOWNER },
            { label = 'Beakbender',         titleId = xi.title.BEAKBENDER },
            { label = 'Skullcrusher',       titleId = xi.title.SKULLCRUSHER },
            { label = 'Tortoise Torturer',  titleId = xi.title.TORTOISE_TORTURER },
        },
    },
    {
        label = 'Mid (100k)',
        cost  = 100000,
        titles =
        {
            { label = "Behemoth's Bane",    titleId = xi.title.BEHEMOTHS_BANE },
            { label = 'Giant Killer',       titleId = xi.title.GIANT_KILLER },
            { label = 'Lich Banisher',      titleId = xi.title.LICH_BANISHER },
            { label = 'Fafnir Slayer',      titleId = xi.title.FAFNIR_SLAYER },
            { label = 'Nidhogg Slayer',     titleId = xi.title.NIDHOGG_SLAYER },
            { label = 'Vrtra Vanquisher',   titleId = xi.title.VRTRA_VANQUISHER },
        },
    },
    {
        label = 'Endgame (1M)',
        cost  = 1000000,
        titles =
        {
            { label = 'Dread Dragon Slayer',   titleId = xi.title.DREAD_DRAGON_SLAYER },
            { label = 'Dark Dragon Slayer',    titleId = xi.title.DARK_DRAGON_SLAYER },
            { label = 'Black Dragon Slayer',   titleId = xi.title.BLACK_DRAGON_SLAYER },
            { label = 'Adamantking Killer',    titleId = xi.title.ADAMANTKING_KILLER },
            { label = 'Behemoth Dethroner',    titleId = xi.title.BEHEMOTH_DETHRONER },
            { label = 'World Serpent Slayer',  titleId = xi.title.WORLD_SERPENT_SLAYER },
        },
    },
    {
        label = 'Whale (10M)',
        cost  = 10000000,
        titles =
        {
            { label = 'Overlord Executioner', titleId = xi.title.OVERLORD_EXECUTIONER },
            { label = 'Hellsbane',            titleId = xi.title.HELLSBANE },
            { label = 'Cassienova',           titleId = xi.title.CASSIENOVA },
            { label = 'Mon Cherry',           titleId = xi.title.MON_CHERRY },
            { label = 'Dragon Asher',         titleId = xi.title.DRAGON_ASHER },
        },
    },
}

return catalog
