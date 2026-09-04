-----------------------------------
-- hades_catalog.lua
--
-- Hades daily quests + weekend shop (shop catalog lands later this week).
-- Five slots every UTC day, same board for every player, 150 Soul Shards
-- if and only if all five are cleared. Relic voucher price is locked at
-- 2100 (two perfect weeks) so later shop prices can be set from that.
-----------------------------------
local catalog = {}

catalog.currencyName = 'Soul Shards'
catalog.currencyCv   = 'Hades_Shards'
catalog.dailyCap     = 150
catalog.relicPrice   = 2100 -- 14 * 150; shop is not live yet

catalog.points =
{
    family      = 10,
    delivery    = 20,
    boss        = 30,
    battlefield = 40,
    custom      = 50,
}

-- West of Daily Board / Weekly Hunts on the hub row (zone 44).
catalog.npcPos =
{
    zone     = 'Abdhaljs_Isle-Purgonorgo',
    zoneId   = 44,
    x        = 508.0119,
    y        =  -3.1516,
    z        = 516.0237,
    rotation =  64,
}

catalog.cvDay        = 'HD_Day'
catalog.cvEarned     = 'HD_EarnedToday'
catalog.cvAllCleared = 'HD_AllCleared_Lifetime'
catalog.cvParcel     = 'HD_Parcel' -- 0 none, 1 holding, 2 delivered (awaiting turn-in)
catalog.cvMet        = 'HD_Met'    -- 1 after the first-talk story

-- First conversation only. Later talks skip straight to the board.
catalog.intro =
{
    'So. Another soul who still draws breath.',
    'I keep the crossing. The dead have no use for gil -- they pay in weight, in memory, in what they leave behind.',
    'You will run my errands. Five, each day the sun keeps. Slay what I name. Carry what I seal. Then come back to me -- not a command. Me.',
    'Do this, and I press Soul Shards into your palm. Hoard them. When the ferry rises on the weekend, I may have wares worth the crossing.',
    'Fail, and the day dies with you. I do not carry debts into tomorrow. Now... look upon today\'s work.',
}

function catalog.currentDayId()
    return tonumber(os.date('!%Y%j'))
end

-- os.date %w: 0 = Sunday, 6 = Saturday (UTC).
function catalog.isShopOpen()
    local wday = tonumber(os.date('!%w'))
    return wday == 0 or wday == 6
end

function catalog.shopStatusLine()
    if catalog.isShopOpen() then
        return 'The ferry is up. Wares are still being negotiated -- return later this week.'
    end
    return 'The market sinks until Saturday. Quests run every day; the shop opens Saturday and Sunday.'
end

function catalog.zoneLabel(zoneId)
    for name, id in pairs(xi.zone) do
        if id == zoneId and type(name) == 'string' then
            local suffix = ''
            local key    = name
            if key:sub(-2) == '_S' then
                suffix = ' [S]'
                key    = key:sub(1, -3)
            end
            local label = key:lower():gsub('_', ' '):gsub('(%a)([%w]*)', function(a, b)
                return a:upper() .. b
            end)
            return label .. suffix
        end
    end
    return string.format('Zone %d', zoneId)
end

function catalog.pick(list, dayId, salt)
    if not list or #list == 0 then
        return nil
    end
    return list[(((dayId or 0) * (salt or 1)) % #list) + 1]
end

local function normName(name)
    return string.lower((name or ''):gsub('[%s%+\']', '_'))
end

catalog.normName = normName

-- Slot 1: kill N of a superFamily. superFamily IDs are mob_family_system.superFamilyID.
catalog.families =
{
    { superFamily =  10, label = 'Worms',       target = 25 },
    { superFamily =   8, label = 'Slimes',      target = 25 },
    { superFamily =  11, label = 'Crabs',       target = 25 },
    { superFamily =  16, label = 'Pugils',      target = 25 },
    { superFamily =  50, label = 'Rabbits',     target = 25 },
    { superFamily =  52, label = 'Sheep',       target = 25 },
    { superFamily =  58, label = 'Goblins',     target = 25 },
    { superFamily =  63, label = 'Orcs',        target = 25 },
    { superFamily =  67, label = 'Quadav',      target = 25 },
    { superFamily =  74, label = 'Yagudo',      target = 25 },
    { superFamily =  71, label = 'Tonberries',  target = 20 },
    { superFamily =  55, label = 'Antica',      target = 25 },
    { superFamily =  68, label = 'Sahagin',     target = 25 },
    { superFamily =  60, label = 'Mamool Ja',   target = 25 },
    { superFamily =  72, label = 'Trolls',      target = 25 },
    { superFamily =  77, label = 'Bats',        target = 25 },
    { superFamily =  80, label = 'Colibri',     target = 25 },
    { superFamily =  92, label = 'Imps',        target = 20 },
    { superFamily = 126, label = 'Lizards',     target = 25 },
    { superFamily = 143, label = 'Funguar',     target = 25 },
    { superFamily = 146, label = 'Mandragora',  target = 25 },
    { superFamily = 173, label = 'Ghosts',      target = 25 },
    { superFamily = 178, label = 'Skeletons',   target = 25 },
    { superFamily = 181, label = 'Bees',        target = 25 },
    { superFamily = 182, label = 'Beetles',     target = 25 },
    { superFamily = 186, label = 'Crawlers',    target = 25 },
    { superFamily = 188, label = 'Flies',       target = 25 },
    { superFamily = 195, label = 'Spiders',     target = 25 },
    { superFamily =  25, label = 'Clusters',    target = 20 },
}

-- Slot 2: one named town NPC per destination. Picked only from npcs that
-- are spawned (npc_list status = 0) and always run onTrigger dialog --
-- shops, timekeepers, item deliverers, armor storage, or a standard CS.
-- Quest-gated silents (Balasiel, Perih Vashai, Jakoh, Ryoma, Rahi Fohlatti,
-- Rising Solstice) were replaced. Guild sendGuild shops were avoided.
--
-- speaker / say play on a successful parcel handoff, then the NPC's
-- normal script still runs (shop menu, CS, send box, etc.).
catalog.deliveries =
{
    {
        zone    = 'Southern_San_dOria',
        zoneId  = xi.zone.SOUTHERN_SAN_DORIA,
        npc     = 'Ostalie',
        speaker = 'Ostalie',
        label   = "Ostalie (Southern San d'Oria)",
        say     =
        {
            'Welcome, customer. Set that behind the counter -- parcels are not for browsing.',
            'If you came to shop, do have a look. The rest is a private matter.',
        },
    },
    {
        zone    = 'Bastok_Markets',
        zoneId  = xi.zone.BASTOK_MARKETS,
        npc     = 'Zhikkom',
        speaker = 'Zhikkom',
        label   = 'Zhikkom (Bastok Markets)',
        say     =
        {
            "Hello! Almost took a falchion to the wrapping -- then I remembered whose shop this is.",
            "Dragon's Claws sells swords, not gossip. Leave it and pick out a blade if you like.",
        },
    },
    {
        zone    = 'Windurst_Woods',
        zoneId  = xi.zone.WINDURST_WOODS,
        npc     = 'Wije_Tiren',
        speaker = 'Wije Tiren',
        label   = 'Wije Tiren (Windurst Woods)',
        say     =
        {
            "Mm... that scent is no cold medicine, and it is cerrrtainly not ambrrrosia.",
            "Do not taste it, adventurrrer. Some rremedies are not meant forrr the shop shelf.",
        },
    },
    {
        zone    = 'Lower_Jeuno',
        zoneId  = xi.zone.LOWER_JEUNO,
        npc     = 'Chululu',
        speaker = 'Chululu',
        label   = 'Chululu (Lower Jeuno)',
        say     =
        {
            'Ooooh, the Hermit came up this morning-orning... I already know who sent this.',
            'The cards do not share-ware their secrets with couriers! Shoo-shoo, unless you want a reading.',
        },
    },
    {
        zone    = 'Selbina',
        zoneId  = xi.zone.SELBINA,
        npc     = 'Isacio',
        speaker = 'Isacio',
        label   = 'Isacio (Selbina)',
        say     =
        {
            'Heh... another odd little thing for an old man to keep. You remind me of myself, running errands.',
            'Put it down and be on your way, youngster. Selbina has better tales than this box.',
        },
    },
    {
        zone    = 'Mhaura',
        zoneId  = xi.zone.MHAURA,
        npc     = 'Dieh_Yamilsiah',
        speaker = 'Dieh Yamilsiah',
        label   = 'Dieh Yamilsiah (Mhaura)',
        say     =
        {
            "Caught you just in time -- the Selbina boat would have left you and the box both.",
            "This is not going aboard, adventurrrer. Mind the ferrry board and leave the rrest to me.",
        },
    },
    {
        zone    = 'Kazham',
        zoneId  = xi.zone.KAZHAM,
        npc     = 'Tahn_Posbei',
        speaker = 'Tahn Posbei',
        label   = 'Tahn Posbei (Kazham)',
        say     =
        {
            "Better you than a Tonberrry with a knife, adventurrrer -- I will take it from herrre.",
            "I do not unwrwrap mysterious boxes in my shop. Buy a shield if yourrr hands are idle.",
        },
    },
    {
        zone    = 'Norg',
        zoneId  = xi.zone.NORG,
        npc     = 'Spasija',
        speaker = 'Spasija',
        label   = 'Spasija (Norg)',
        say     =
        {
            "Hiya! Usually I'm the one sending parcels to anybody, anywhere, anytime.",
            "This one stops here. No peeking -- I know how these jobs work.",
        },
    },
    {
        zone    = 'Rabao',
        zoneId  = xi.zone.RABAO,
        npc     = 'Brave_Wolf',
        speaker = 'Brave Wolf',
        label   = 'Brave Wolf (Rabao)',
        say     =
        {
            'Sand gets into everything out here. A sealed box is a rare mercy.',
            'I will not pry, and neither will you. Armor still sets a mind at ease if the road was long.',
        },
    },
    {
        zone    = 'Tavnazian_Safehold',
        zoneId  = xi.zone.TAVNAZIAN_SAFEHOLD,
        npc     = 'Ratonne',
        speaker = 'Ratonne',
        label   = 'Ratonne (Tavnazian Safehold)',
        say     =
        {
            'Tavnazia keeps what it is given -- quietly, and under lock.',
            'I store armor for adventurers. This box I store for myself. No catalogue, no questions.',
        },
    },
    {
        zone    = 'Aht_Urhgan_Whitegate',
        zoneId  = xi.zone.AHT_URHGAN_WHITEGATE,
        npc     = 'Gavrie',
        speaker = 'Gavrie',
        label   = 'Gavrie (Aht Urhgan Whitegate)',
        say     =
        {
            'Unmarked tinctures are how alchemists lose their licenses... and their patients.',
            'I will not inventory this like a potion. Small doses, adventurer -- of curiosity, too.',
        },
    },
    {
        zone    = 'Al_Zahbi',
        zoneId  = xi.zone.AL_ZAHBI,
        npc     = 'Chayaya',
        speaker = 'Chayaya',
        label   = 'Chayaya (Al Zahbi)',
        say     =
        {
            "Hands off! Same rule as the high drawers -- you do not rummage in Chayaya's things.",
            'Darts, hawkeyes, grenades... those you may buy. That box you may not shake.',
        },
    },
    {
        zone    = 'Nashmau',
        zoneId  = xi.zone.NASHMAU,
        npc     = 'Nanaroon',
        speaker = 'Nanaroon',
        label   = 'Nanaroon (Nashmau)',
        say     =
        {
            'Yooo bring box to Nana! Nana send gooods... this one Nana keep.',
            'No clink-clink for peeking. Peeking make Nana bite.',
        },
    },
    {
        zone    = 'Western_Adoulin',
        zoneId  = xi.zone.WESTERN_ADOULIN,
        npc     = 'Flapano',
        speaker = 'Flapano',
        label   = 'Flapano (Western Adoulin)',
        say     =
        {
            'Welcome, welcome! If that were an ingredient, it would already be in the pot.',
            'It is not. Keep your fingers out of my kitchen and order something proper -- paella, perhaps.',
        },
    },
    {
        zone    = 'Eastern_Adoulin',
        zoneId  = xi.zone.EASTERN_ADOULIN,
        npc     = 'Octavien',
        speaker = 'Octavien',
        label   = 'Octavien (Eastern Adoulin)',
        say     =
        {
            'A sealed dispatch for the palace. You have done your part, civilian.',
            'Move along. The Peacekeepers do not discuss their correspondence in the street.',
        },
    },
    {
        zone    = 'Southern_San_dOria_[S]',
        zoneId  = xi.zone.SOUTHERN_SAN_DORIA_S,
        npc     = 'Miliart_TK',
        speaker = 'Miliart T.K.',
        label   = "Miliart T.K. (Southern San d'Oria [S])",
        say     =
        {
            'A wartime dispatch, adventurer. Need-to-know, and you do not need to know.',
            'The Kingdom thanks you. If you require a sigil, that I may discuss.',
        },
    },
}

-- Slot 3: curated outdoor NMs a typical 99 can kill with trusts.
-- Home zone only. Forced to a flat 30-minute timed spawn (see
-- hades_boss_respawns.sql + hades_boss_respawn.lua) so they are not lottery.
-- Home-zone NMs only. Do not list anything custom_HNM_system owns
-- (Serket 6-8h, King Arthro 8-10h + knight-crab window + Affinity copy),
-- or multi-copy gimmicks (Padfoot's 5 sheep). Those fight live content.
catalog.bosses =
{
    { name = 'Jaggedy-Eared_Jack', zone = 'West_Ronfaure',        zoneId = xi.zone.WEST_RONFAURE,        groupId = 25, label = 'Jaggedy-Eared Jack' },
    { name = 'Fungus_Beetle',      zone = 'West_Ronfaure',        zoneId = xi.zone.WEST_RONFAURE,        groupId = 23, label = 'Fungus Beetle' },
    { name = 'Stinging_Sophie',    zone = 'North_Gustaberg',      zoneId = xi.zone.NORTH_GUSTABERG,      groupId = 16, label = 'Stinging Sophie' },
    { name = 'Leaping_Lizzy',      zone = 'South_Gustaberg',      zoneId = xi.zone.SOUTH_GUSTABERG,      groupId = 29, label = 'Leaping Lizzy' },
    { name = 'Carnero',            zone = 'South_Gustaberg',      zoneId = xi.zone.SOUTH_GUSTABERG,      groupId = 17, label = 'Carnero' },
    { name = 'Bigmouth_Billy',     zone = 'East_Ronfaure',        zoneId = xi.zone.EAST_RONFAURE,        groupId = 26, label = 'Bigmouth Billy' },
    { name = 'Tom_Tit_Tat',        zone = 'West_Sarutabaruta',    zoneId = xi.zone.WEST_SARUTABARUTA,    groupId = 25, label = 'Tom Tit Tat' },
    { name = 'Valkurm_Emperor',    zone = 'Valkurm_Dunes',        zoneId = xi.zone.VALKURM_DUNES,        groupId = 30, label = 'Valkurm Emperor' },
    { name = 'Deadly_Dodo',        zone = 'Sauromugue_Champaign', zoneId = xi.zone.SAUROMUGUE_CHAMPAIGN, groupId = 34, label = 'Deadly Dodo' },
    { name = 'Drooling_Daisy',     zone = 'Rolanberry_Fields',    zoneId = xi.zone.ROLANBERRY_FIELDS,    groupId = 39, label = 'Drooling Daisy' },
    { name = 'Bloodtear_Baldurf',  zone = 'La_Theine_Plateau',    zoneId = xi.zone.LA_THEINE_PLATEAU,    groupId = 42, label = 'Bloodtear Baldurf' },
    { name = 'Skewer_Sam',         zone = 'Garlaige_Citadel',     zoneId = xi.zone.GARLAIGE_CITADEL,     groupId = 14, label = 'Skewer Sam' },
    { name = 'Tumbling_Truffle',   zone = 'La_Theine_Plateau',    zoneId = xi.zone.LA_THEINE_PLATEAU,    groupId = 40, label = 'Tumbling Truffle' },
    { name = 'Bomb_Queen',         zone = 'Ifrits_Cauldron',      zoneId = xi.zone.IFRITS_CAULDRON,      groupId = 25, label = 'Bomb Queen' },
}

-- Slot 4: entry HTBFs (tier I is enough) or Wave Master Easy/Normal.
catalog.battlefields =
{
    { kind = 'htbf', fightKey = 'trial_by_fire',      label = 'HTBF: Trial by Fire' },
    { kind = 'htbf', fightKey = 'trial_by_ice',       label = 'HTBF: Trial by Ice' },
    { kind = 'htbf', fightKey = 'trial_by_wind',      label = 'HTBF: Trial by Wind' },
    { kind = 'htbf', fightKey = 'trial_by_earth',     label = 'HTBF: Trial by Earth' },
    { kind = 'htbf', fightKey = 'trial_by_lightning', label = 'HTBF: Trial by Lightning' },
    { kind = 'htbf', fightKey = 'trial_by_water',     label = 'HTBF: Trial by Water' },
    { kind = 'htbf', fightKey = 'the_savage',         label = 'HTBF: The Savage' },
    { kind = 'htbf', fightKey = 'warriors_path',      label = "HTBF: Warrior's Path" },
    { kind = 'htbf', fightKey = 'head_wind',          label = 'HTBF: Head Wind' },
    { kind = 'htbf', fightKey = 'shadow_lord',        label = 'HTBF: Shadow Lord' },
    { kind = 'wavemaster', difficulty = 'Easy',       label = 'Wave Master: Easy' },
    { kind = 'wavemaster', difficulty = 'Normal',     label = 'Wave Master: Normal' },
}

-- Slot 5: custom NM a 3-player 99 group can handle.
-- Hunting League Rank I-II and Reforge I-II only. No T3+, no Empy, no gods.
catalog.customNms =
{
    { system = 'hl',      name = 'Leaping_Lizzy',   groupId = 11355, label = 'Leaping Lizzy (HL I)' },
    { system = 'hl',      name = 'Valkurm_Emperor', groupId = 11356, label = 'Valkurm Emperor (HL I)' },
    { system = 'hl',      name = 'Tom_Tit_Tat',     groupId = 11357, label = 'Tom Tit Tat (HL I)' },
    { system = 'hl',      name = 'Roc',             groupId = 11358, label = 'Roc (HL II)' },
    { system = 'hl',      name = 'Bomb_Queen',      groupId = 11359, label = 'Bomb Queen (HL II)' },
    { system = 'hl',      name = 'Aquarius',        groupId = 11360, label = 'Aquarius (HL II)' },
    { system = 'reforge', name = 'Genbu',           setKey = 'af',    label = 'Genbu (Reforge I)' },
    { system = 'reforge', name = 'Suzaku',          setKey = 'af',    label = 'Suzaku (Reforge II)' },
    { system = 'reforge', name = 'Bukhis',          setKey = 'relic', label = 'Bukhis (Reforge I)' },
    { system = 'reforge', name = 'Khun',            setKey = 'relic', label = 'Khun (Reforge II)' },
}

local function familyQuest(entry)
    return
    {
        slot        = 1,
        eventType   = 'family_kill',
        points      = catalog.points.family,
        target      = entry.target,
        label       = string.format('Slay %s', entry.label),
        description = string.format('Kill %d %s anywhere in Vana\'diel.', entry.target, entry.label),
        matches     = function(meta)
            return meta and meta.superFamily == entry.superFamily
        end,
    }
end

local function deliveryQuest(entry)
    return
    {
        slot        = 2,
        eventType   = 'delivery',
        points      = catalog.points.delivery,
        target      = 1,
        zoneId      = entry.zoneId,
        npc         = entry.npc,
        label       = string.format('Parcel: %s', entry.label),
        description = string.format(
            'Collect the parcel from Hades, then talk to %s. Return to Hades to turn in.',
            entry.label),
        matches     = function(meta)
            return meta and meta.zoneId == entry.zoneId and meta.npc == entry.npc
        end,
    }
end

local function bossQuest(entry)
    return
    {
        slot        = 3,
        eventType   = 'boss_kill',
        points      = catalog.points.boss,
        target      = 1,
        label       = string.format('Hunt %s', entry.label),
        description = string.format(
            'Defeat %s in %s (the real one -- copies do not count).',
            entry.label, catalog.zoneLabel(entry.zoneId)),
        matches     = function(meta)
            return meta
                and meta.zoneId == entry.zoneId
                and normName(meta.name) == normName(entry.name)
        end,
    }
end

local function battlefieldQuest(entry)
    local description
    if entry.kind == 'htbf' then
        description = string.format('Clear %s once (any tier).', entry.label)
    else
        description = string.format('Clear a full %s Wave Master session.', entry.label)
    end
    return
    {
        slot        = 4,
        eventType   = 'battlefield',
        points      = catalog.points.battlefield,
        target      = 1,
        label       = entry.label,
        description = description,
        matches     = function(meta)
            if not meta or meta.kind ~= entry.kind then
                return false
            end
            if entry.kind == 'htbf' then
                return meta.fightKey == entry.fightKey
            end
            return meta.difficulty == entry.difficulty
        end,
    }
end

local function customQuest(entry)
    return
    {
        slot        = 5,
        eventType   = 'custom_nm',
        points      = catalog.points.custom,
        target      = 1,
        label       = entry.label,
        description = string.format(
            'Defeat %s with at least 3 real players in your alliance. Trusts do not count.',
            entry.label),
        nameMatches = function(meta)
            if not meta or meta.system ~= entry.system then
                return false
            end
            if entry.groupId and meta.groupId then
                return meta.groupId == entry.groupId
            end
            return normName(meta.name) == normName(entry.name)
        end,
        matches     = function(meta)
            if not meta or (meta.realParty or 0) < 3 then
                return false
            end
            if meta.system ~= entry.system then
                return false
            end
            if entry.groupId and meta.groupId then
                return meta.groupId == entry.groupId
            end
            return normName(meta.name) == normName(entry.name)
        end,
    }
end

function catalog.todaysQuests(dayId)
    dayId = dayId or catalog.currentDayId()
    return
    {
        familyQuest(catalog.pick(catalog.families, dayId, 7)),
        deliveryQuest(catalog.pick(catalog.deliveries, dayId, 11)),
        bossQuest(catalog.pick(catalog.bosses, dayId, 13)),
        battlefieldQuest(catalog.pick(catalog.battlefields, dayId, 17)),
        customQuest(catalog.pick(catalog.customNms, dayId, 19)),
    }
end

return catalog
