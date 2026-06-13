-----------------------------------
-- gil_warp_npc_catalog.lua
-- Destinations + pricing for the Insta-Warp NPC at GM Home. Edit
-- freely -- the module loads at server start and rebuilds the menu.
--
-- The menu is TWO LEVELS:
--   1. Pick a tier (Cities / Expansions / Remote / Endgame)
--   2. Pick a destination within that tier (all share the tier's cost)
-- The tier structure exists because of FFXI's ~150-byte customMenu
-- packet cap. A flat 15-row destination menu overflowed and truncated
-- the bottom entries client-side. Adding many more destinations to one
-- tier may also overflow it; if so, split it into two tiers (e.g.
-- 'Expansions A-M' / 'Expansions N-Z') with the same cost.
--
-- Each destination: { label, zone, x, y, z, r }
--   label : shown in the menu (keep short)
--   zone  : xi.zone.X constant (target zone id)
--   x/y/z/r: spawn position + rotation in target zone
-----------------------------------
local catalog = {}

catalog.zoneId    = xi.zone.GM_HOME
catalog.zonePath  = 'xi.zones.GM_Home'
catalog.npcName   = 'Warpman'
catalog.npcLook   = 3000
catalog.npcPos    = { x = 2.000, y = 0.000, z = -15.000, rot = 128 }

-- Pricing tiers used in the destinations below. Adjust globally here.
catalog.pricing =
{
    city     = 5000,    -- nation capitals, Jeuno
    mid      = 15000,   -- mid-range zones (Aht Urhgan, Tavnazia, etc.)
    remote   = 30000,   -- exotic / endgame entry zones
    endgame  = 50000,   -- premium endgame (Reisenjima, etc.)
}

catalog.tiers =
{
    {
        label = 'Cities (5k)',
        cost  = catalog.pricing.city,
        destinations =
        {
            { label = "San d'Oria",     zone = xi.zone.SOUTHERN_SAN_DORIA, x =  20.00, y =   0.50, z = -55.00, r = 192 },
            { label = "Bastok Markets", zone = xi.zone.BASTOK_MARKETS,     x =  41.00, y =  -1.00, z =  -1.00, r = 192 },
            { label = "Windurst Woods", zone = xi.zone.WINDURST_WOODS,     x =   0.00, y =  -5.00, z =   0.00, r = 192 },
            { label = "Jeuno (Lower)",  zone = xi.zone.LOWER_JEUNO,        x =  35.00, y =  -7.00, z =   0.00, r = 192 },
        },
    },
    {
        label = 'Expansions (15k)',
        cost  = catalog.pricing.mid,
        destinations =
        {
            { label = "Aht Urhgan Whitegate", zone = xi.zone.AHT_URHGAN_WHITEGATE, x = -30.00, y = -6.00, z = -50.00, r = 192 },
            { label = "Tavnazian Safehold",   zone = xi.zone.TAVNAZIAN_SAFEHOLD,   x = -85.00, y = 12.00, z =  40.00, r = 192 },
            { label = "Norg",                 zone = xi.zone.NORG,                 x = -10.00, y = -3.00, z =  10.00, r = 192 },
            { label = "Selbina",              zone = xi.zone.SELBINA,              x =   0.00, y =  0.00, z =   0.00, r = 192 },
            { label = "Kazham",               zone = xi.zone.KAZHAM,               x =   0.00, y =  0.00, z =   0.00, r = 192 },
            { label = "Mhaura",               zone = xi.zone.MHAURA,               x =   0.00, y =  0.00, z =   0.00, r = 192 },
        },
    },
    {
        label = 'Remote (30k)',
        cost  = catalog.pricing.remote,
        destinations =
        {
            { label = "Western Adoulin", zone = xi.zone.WESTERN_ADOULIN, x = -10.00, y = 0.00, z = 0.00, r = 192 },
            { label = "Eastern Adoulin", zone = xi.zone.EASTERN_ADOULIN, x = -10.00, y = 0.00, z = 0.00, r = 192 },
            { label = "Al Zahbi",        zone = xi.zone.AL_ZAHBI,        x =   0.00, y = 0.00, z = 0.00, r = 192 },
        },
    },
    {
        label = 'Endgame (50k)',
        cost  = catalog.pricing.endgame,
        destinations =
        {
            { label = "Reisenjima",            zone = xi.zone.REISENJIMA,           x =   0.00, y =   0.00, z =  0.00, r = 192 },
            { label = "Reisenjima Henge",      zone = xi.zone.REISENJIMA_HENGE,     x =   0.00, y =   5.50, z =  0.00, r = 192 },
            { label = "Ra'Kaznar Inner Court", zone = xi.zone.RAKAZNAR_INNER_COURT, x = -312.29, y = -440.25, z = 380.70, r = 129 }, -- coord verified in-game via !pos (Floor 1, Stone terrain)
        },
    },
}

return catalog
