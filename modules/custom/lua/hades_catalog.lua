-----------------------------------
-- hades_catalog.lua
--
-- Hades daily quests + weekend shop.
-- Five slots every UTC day, same board for every player, 150 Soul Shards
-- if and only if all five are cleared. Weekend shop sells one ware from
-- each of eight stalls (Steel, Steel II, Mail, Mail II, Gild, Crate, Trusts,
-- Cosmetics). Lv.1 EXP / Capacity looks roll on Cosmetics, not a weekday shop.
-- Steel is
-- Relic/Odyssey paper or finished Ambuscade / Geas named. Hades sets
-- that week's prices. Pin a week on hades_shop_catalog.PINNED.
-----------------------------------
-- FileWatcher dofile discards the return. Mutate the cached table so
-- board changes go live without a map restart.
local CATALOG_KEY = 'modules/custom/lua/hades_catalog'
local catalog = package.loaded[CATALOG_KEY]
if type(catalog) ~= 'table' then
    catalog = {}
end
package.loaded[CATALOG_KEY] = catalog

-- Bump when slot lists change so hades_daily drops its same-day cache.
catalog.boardRev = 4

catalog.currencyName = 'Soul Shards'
catalog.currencyCv   = 'Hades_Shards'
catalog.dailyCap     = 150
catalog.relicPrice   = nil -- weeklyPrice() on the voucher catalog is the live cost
catalog.weekOffer    = nil -- replaced by weekOffers()

catalog.points =
{
    family      = 10,
    delivery    = 20,
    boss        = 30,
    battlefield = 40,
    custom      = 50,
}

-- Daily Hades (v1). Shop is the silent second form (placeholder 16959511).
catalog.npcPos =
{
    zone     = 'Abdhaljs_Isle-Purgonorgo',
    zoneId   = 44,
    x        = 649.2089,
    y        =   0.3000,
    z        = 567.0547,
    rotation =  96,
}

-- Live hub placeholder the owner placed. Keep this ID; do not respawn him.
catalog.shopNpcId = 16959511
-- Used only if that placeholder is missing after a restart.
catalog.shopNpcPos =
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
    'Do this, and I press Soul Shards into your palm. Hoard them. When the ferry rises on the weekend, my other form keeps the wares the dead left behind.',
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

function catalog.weekOffers(weekId)
    return require('modules/custom/lua/hades_shop_catalog').weekOffers(weekId)
end

function catalog.shopStatusLine()
    if catalog.isShopOpen() then
        return 'The ferry is up. Eight stalls this week -- Steel, Steel II, Mail, Mail II, Gild, Crate, Trusts, and Cosmetics. Same board for every soul. Crate hold is on the talking form.'
    end
    return 'The market sinks until Saturday. Eight stalls return when the ferry rises. Quests run every day. Nothing sells until then. Crate hold stays open on the talking form.'
end

local function sayHades(player, line)
    player:printToPlayer('Hades : ' .. line, xi.msg.channel.SYSTEM_3)
end

local function sayDots(player)
    player:printToPlayer('......', xi.msg.channel.SYSTEM_3)
end

function catalog.sayShopSilence(player)
    sayDots(player)
end

function catalog.tryBuyRelicVoucher(player, poolIndex, silent)
    if not player then
        return false
    end

    if not catalog.isShopOpen() then
        if silent then
            sayDots(player)
        else
            sayHades(player, 'The ferry is down. Come back when the weekend keeps.')
        end
        return false
    end

    local shop = require('modules/custom/lua/hades_shop_catalog')
    local offer = catalog.weekOffers()[poolIndex or 0]
    local row = offer and offer.row
    local price = offer and offer.price
    if not row or not price or price < 1 then
        if silent then
            sayDots(player)
        else
            sayHades(player, 'The dead have no wares at that stall.')
        end
        return false
    end

    local shards = player:getCharVar(catalog.currencyCv) or 0
    local wareName = shop.shopName(offer)
    if shards < price then
        if silent then
            sayDots(player)
        else
            sayHades(player, string.format(
                'You hold %d %s. %s costs %d.',
                shards, catalog.currencyName, wareName, price))
        end
        return false
    end

    if shop.owns(player, offer) then
        if silent then
            sayDots(player)
        elseif offer.key == 'crate' then
            sayHades(player, 'You already took this week\'s crate. The other stalls still stand.')
        elseif offer.key == 'trust' then
            sayHades(player, string.format(
                'This stall is %s. You already know that name. The other stalls still stand.',
                row.name))
        else
            sayHades(player, string.format(
                'This stall is %s. You already carry that one. The other stalls still stand.',
                row.name))
        end
        return false
    end

    if not shop.award(player, offer, silent and '' or 'Hades') then
        if silent then
            sayDots(player)
        end
        return false
    end

    player:setCharVar(catalog.currencyCv, shards - price)
    if silent then
        sayDots(player)
        return true
    end

    if offer.key == 'crate' then
        sayHades(player, 'The dead hoarded what they could not spend.')
        sayHades(player, string.format(
            'The crate is banked -- %s. Forges take from this hold before your bags. Ask either form for Crate hold if you want a stack in your bags.',
            wareName))
    elseif offer.key == 'trust' then
        sayHades(player, 'A name the dead still answer.')
        sayHades(player, string.format('%s will walk with you now.', row.name))
    elseif offer.key == 'cosmetic' then
        sayHades(player, 'Vanity survives the crossing.')
        sayHades(player, string.format('Wear %s if you still care how you look.', row.name))
    elseif offer.key == 'armor' or offer.key == 'accessory' then
        if row.sourced then
            if offer.key == 'armor' then
                sayHades(player, 'The dead still wear their mail.')
            else
                sayHades(player, 'The dead still keep their jewels.')
            end
        else
            sayHades(player, 'This one never washed ashore here. Until now.')
        end
        sayHades(player, string.format('Take %s.', row.name))
    elseif row.kind == 'ambuscade' or row.kind == 'geas' then
        sayHades(player, 'The dead left steel, not paper.')
        sayHades(player, string.format('Take %s. It is already whole.', row.name))
    elseif row.kind == 'odyssey' then
        sayHades(player, 'The dead paid in relics once. This paper is newer -- an Odyssey name.')
        sayHades(player, string.format(
            'This one bears the name %s. Take it to the Weapon Forger -- if you have already walked the Relic path on any job.',
            row.name))
    else
        sayHades(player, 'The dead paid in relics once. I still have their papers.')
        sayHades(player, string.format(
            'This one bears the name %s. Take it to the Weapon Forger -- if you have already walked that path yourself.',
            row.name))
    end
    player:printToPlayer(
        string.format('[Hades] Received: %s. %s remaining: %d.',
            wareName, catalog.currencyName, shards - price),
        xi.msg.channel.SYSTEM_3)
    return true
end

function catalog.tryBuyLeveling(player, itemId, silent)
    if not player then
        return false
    end

    if silent then
        sayDots(player)
    else
        sayHades(player, 'Those looks wait with the dead. Cosmetics, when the ferry rises.')
    end
    return false
end

function catalog.showLevelingShop(player, backFn, silent, page)
    if not player then
        return
    end

    catalog.tryBuyLeveling(player, 0, silent)
    if backFn then
        backFn(player)
    end
end

function catalog.showShop(player, backFn, silent)
    local S = xi.msg.channel.SYSTEM_3
    player:printToPlayer('[Hades] ' .. catalog.shopStatusLine(), S)
    player:printToPlayer(
        string.format('[Hades] You hold %d %s.',
            player:getCharVar(catalog.currencyCv) or 0, catalog.currencyName),
        S)

    local opts = {}
    if catalog.isShopOpen() then
        local shop = require('modules/custom/lua/hades_shop_catalog')
        for _, offer in ipairs(catalog.weekOffers()) do
            local poolIndex = offer.pool
            player:printToPlayer(
                string.format('[Hades] %s: %s -- %d %s.',
                    offer.label, shop.shopName(offer),
                    offer.price, catalog.currencyName),
                S)
            -- customMenu packs title + labels into ~150 bytes. Full ware
            -- names overflow; stall + price is enough -- chat already
            -- printed the real name.
            opts[#opts + 1] =
            {
                string.format('%s %d', offer.label, offer.price),
                function(p)
                    catalog.tryBuyRelicVoucher(p, poolIndex, silent)
                    catalog.showShop(p, backFn, silent)
                end,
            }
        end
    end
    opts[#opts + 1] =
    {
        'Crate hold',
        function(p)
            catalog.showCrateHold(p, function(pp)
                catalog.showShop(pp, backFn, silent)
            end, silent)
        end,
    }
    if backFn then
        opts[#opts + 1] =
        {
            'Back',
            function(p)
                backFn(p)
            end,
        }
    else
        opts[#opts + 1] = { 'Close', function(_) end }
    end

    local snapshot = { title = silent and '......' or 'Hades Shop', options = opts }
    player:timer(30, function(p) p:customMenu(snapshot) end)
end

local HOLD_PAGE = 4

function catalog.printHoldLedger(player)
    local hold = require('modules/custom/lua/hades_hold_currency')
    local rows = hold.heldRows(player)
    if #rows == 0 then
        player:printToPlayer(
            '[Hades] Crate hold is empty. Weekend crates bank here. Forges spend this before your bags.',
            xi.msg.channel.SYSTEM_3)
        return rows
    end
    player:printToPlayer(
        string.format(
            '[Hades] Crate hold -- banked currency. Forges spend this first. Take one stack (up to %d) into a free slot.',
            hold.STACK),
        xi.msg.channel.SYSTEM_3)
    for _, row in ipairs(rows) do
        if row.bags > 0 then
            player:printToPlayer(string.format(
                '[Hades]   %s: %d (Hold) + %d (bags) = %d',
                row.label, row.held, row.bags, row.held + row.bags),
                xi.msg.channel.SYSTEM_3)
        else
            player:printToPlayer(string.format(
                '[Hades]   %s: %d (Hold)',
                row.label, row.held),
                xi.msg.channel.SYSTEM_3)
        end
    end
    return rows
end

function catalog.showCrateHold(player, backFn, silent, page)
    if not player then
        return
    end

    local hold = require('modules/custom/lua/hades_hold_currency')
    local rows = catalog.printHoldLedger(player)
    page = page or 1
    local pages = math.max(1, math.ceil(#rows / HOLD_PAGE))
    if page > pages then
        page = pages
    end

    local opts = {}
    local first = ((page - 1) * HOLD_PAGE) + 1
    local last  = math.min(first + HOLD_PAGE - 1, #rows)
    for i = first, last do
        local row = rows[i]
        local itemId = row.itemId
        opts[#opts + 1] =
        {
            string.format('%s %d', row.label, row.held),
            function(p)
                hold.withdraw(p, itemId, hold.STACK)
                catalog.showCrateHold(p, backFn, silent, page)
            end,
        }
    end
    if page < pages then
        opts[#opts + 1] =
        {
            string.format('Next (%d/%d)', page + 1, pages),
            function(p)
                catalog.showCrateHold(p, backFn, silent, page + 1)
            end,
        }
    end
    if backFn then
        opts[#opts + 1] =
        {
            'Back',
            function(p)
                backFn(p)
            end,
        }
    else
        opts[#opts + 1] = { 'Close', function(_) end }
    end

    local snapshot = { title = silent and '......' or 'Crate hold', options = opts }
    player:timer(30, function(p) p:customMenu(snapshot) end)
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

-- Slot 3 used to force-spawn starter-zone lottery NMs on a 30-minute
-- timer. Those timers stay as leftover QoL (see hades_boss_respawn.lua).
-- Do not add Abyssea / custom_HNM_system names here.
catalog.respawnBosses =
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

-- Slot 3: high-level open-world NMs a 99 + trusts can kill.
-- Hunter's Guild T1-T3 camps already sit on a 30-minute timer
-- (!huntwarp). Skip Abyssea Marks (too hard), custom_HNM windows
-- (Fafnir / kings / Serket), ToAU/Zilart land kings (Tiamat,
-- Cerberus, Khimaira, Bahamut, Jormungand), weather-gated
-- Vinegarroon, and Carmine Dobsonfly's 10-pack.
-- Adoulin named NMs are yggrete-shard ??? pops / reives, not
-- walk-up camps -- do not list them here.
catalog.bosses =
{
    { name = 'Tarasque',          zoneId = xi.zone.IFRITS_CAULDRON,        label = 'Tarasque' },
    { name = 'Capricornus',       zoneId = xi.zone.JUGNER_FOREST,          label = 'Capricornus' },
    { name = 'Charybdis',         zoneId = xi.zone.SEA_SERPENT_GROTTO,     label = 'Charybdis' },
    { name = 'Cactrot_Rapido',    zoneId = xi.zone.EASTERN_ALTEPA_DESERT,  label = 'Cactrot Rapido' },
    { name = 'Lord_of_Onzozo',    zoneId = xi.zone.LABYRINTH_OF_ONZOZO,    label = 'Lord of Onzozo' },
    { name = 'Faust',             zoneId = xi.zone.THE_SHRINE_OF_RUAVITAU, label = 'Faust' },
    { name = 'Despot',            zoneId = xi.zone.RUAUN_GARDENS,          label = 'Despot' },
    { name = 'Steam_Cleaner',     zoneId = xi.zone.VELUGANNON_PALACE,      label = 'Steam Cleaner' },
    { name = 'Bune',              zoneId = xi.zone.GUSTAV_TUNNEL,          label = 'Bune' },
    { name = 'Brigandish_Blade',  zoneId = xi.zone.VELUGANNON_PALACE,      label = 'Brigandish Blade' },
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

-- Slot 5: 3 real PCs. Hunting League III-IV and Reforge III-IV.
-- Skip HL V gods (AV / PW / Shinryu) and Reforge V apex NMs.
catalog.customNms =
{
    { system = 'hl',      name = 'Serket',         groupId = 11361, label = 'Serket (HL III)' },
    { system = 'hl',      name = 'Vrtra',          groupId = 11362, label = 'Vrtra (HL III)' },
    { system = 'hl',      name = 'Simurgh',        groupId = 11363, label = 'Simurgh (HL III)' },
    { system = 'hl',      name = 'Nidhogg',        groupId = 11364, label = 'Nidhogg (HL IV)' },
    { system = 'hl',      name = 'King_Behemoth',  groupId = 11365, label = 'King Behemoth (HL IV)' },
    { system = 'hl',      name = 'Kirin',          groupId = 11366, label = 'Kirin (HL IV)' },
    { system = 'reforge', name = 'Seiryu',         setKey = 'af',    label = 'Seiryu (Reforge III)' },
    { system = 'reforge', name = 'Byakko',         setKey = 'af',    label = 'Byakko (Reforge IV)' },
    { system = 'reforge', name = 'Padfoot',        setKey = 'relic', label = 'Padfoot (Reforge III)' },
    { system = 'reforge', name = 'Glavoid',        setKey = 'relic', label = 'Glavoid (Reforge IV)' },
    { system = 'reforge', name = 'Briareus',       setKey = 'empy',  label = 'Briareus (Reforge III)' },
    { system = 'reforge', name = 'Itzpapalotl',    setKey = 'empy',  label = 'Itzpapalotl (Reforge IV)' },
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
            'Defeat %s in %s. 30-minute camp -- !huntwarp if you need the spot.',
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
