-----------------------------------
-- CrossJob_Trainer.lua
--
-- NPC at GM Home that sells "borrowed" job abilities. After purchase, the
-- ability can be used on ANY job (e.g. Meditate on PLD) for a flat
-- 10,000,000 gil each.
--
-- The curated list of sellable abilities lives in
--   modules/custom/lua/cross_job_ability_catalog.lua
-- and the persistence + live-injection engine work is in the companion C++
-- module
--   modules/custom/cpp/cross_job_ability_bindings.cpp
-- which exposes player:learnCrossJobAbility / hasCrossJobAbility /
-- getCrossJobAbilities used below.
--
-- USAGE NOTE for players: a borrowed ability does NOT appear in the in-game
-- Job Abilities menu (that menu is built client-side per job and can't be
-- extended server-side). Use it via a macro instead, e.g.:
--     /ja "Meditate" <me>
--
-- Zone: GM Home (zone 210)
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Abdhaljs_Isle-Purgonorgo/Zone')
local catalog = require('modules/custom/lua/cross_job_ability_catalog')
-----------------------------------
local m = Module:new('crossjob_trainer')

local GIL_COST = catalog.GIL_COST

-- 10000000 -> "10,000,000"
local function commafy(n)
    local s = tostring(math.floor(n))
    local out = s:reverse():gsub('(%d%d%d)', '%1,'):reverse()
    return (out:gsub('^,', ''))
end

local GIL_STR = commafy(GIL_COST)

-- Hard cap on cross-job ability PURCHASES per character. This is a purchase
-- ceiling, NOT a usability one: the ability-recast packet
-- (GP_SERV_COMMAND_ABIL_RECAST) carries at most 30 entries total -- native job
-- abilities AND borrowed ones combined -- and a fully-merited job already runs
-- ~20-25 native abilities, so only the first few borrowed ones fit on a heavy
-- job. The C++ binding caps LIVE injection at 30 total (excess borrowed stay
-- owned but dormant until you're on a lighter job); this purchase cap just keeps
-- players from paying for far more than they could realistically use. (The old
-- value of 30 assumed ~1 native ability -- the miscount that let players overbuy
-- past the packet limit and lose access to abilities they had paid for.)
local MAX_CROSS_JOB_ABILITIES = 15

-- Group-menu pagination: keep each page's customMenu payload under the
-- ~150-byte cap. 6 abilities + nav + Back per page stays safely within budget,
-- so a group can hold any number of abilities without silently truncating the
-- Back/Next buttons.
local GROUP_PAGE_SIZE = 6

-- Main-menu pagination (added 2026-06-13): the client's GMPROMPT UI renders only
-- the FIRST 8 options, and this menu had 9 job groups + "How it works" = 10, so
-- Ninja + How-it-works were silently dropped. Paginate the top-level list so
-- every page stays <= 8 (entries + nav).
local MAIN_PAGE_SIZE  = 6

-- Forward declarations (mutually recursive menu screens).
local showMainMenu, showGroupMenu, showConfirmMenu

-- Build a quick lookup set of ability ids the player already owns, so the
-- menu can mark them. One binding call instead of one query per ability.
local function ownedSet(player)
    local set  = {}
    local list = player:getCrossJobAbilities()
    if list then
        for _, id in ipairs(list) do
            set[id] = true
        end
    end
    return set
end

-----------------------------------
-- Main menu: pick a job group.
-----------------------------------
showMainMenu = function(player, page)
    -- Full top-level item list: every job group, then "How it works" last.
    local items = {}
    for idx, group in ipairs(catalog.groups) do
        local groupIndex = idx
        items[#items + 1] = {
            group.name,
            function(playerArg)
                showGroupMenu(playerArg, groupIndex)
            end,
        }
    end
    items[#items + 1] = {
        'How it works',
        function(playerArg)
            playerArg:printToPlayer('[ Cross-Job Trainer ] Buy a job ability and use it on ANY job.', xi.msg.channel.SYSTEM_3)
            playerArg:printToPlayer(string.format('  Cost: %s gil each. The ability stays with you across jobs and logins.', GIL_STR), xi.msg.channel.SYSTEM_3)
            playerArg:printToPlayer('  It will NOT show in your Job Abilities menu - use a macro, e.g.  /ja "Meditate" <me>', xi.msg.channel.SYSTEM_3)
            showMainMenu(playerArg)
        end,
    }

    -- Paginate so each page stays under the client's 8-option GMPROMPT cap.
    local pages = math.max(1, math.ceil(#items / MAIN_PAGE_SIZE))
    page = math.max(1, math.min(page or 1, pages))
    local startIdx = (page - 1) * MAIN_PAGE_SIZE + 1
    local endIdx   = math.min(startIdx + MAIN_PAGE_SIZE - 1, #items)

    local options = {}
    for i = startIdx, endIdx do
        options[#options + 1] = items[i]
    end
    if page > 1 then
        table.insert(options, {
            string.format('<< Page %d/%d', page - 1, pages),
            function(p) showMainMenu(p, page - 1) end,
        })
    end
    if page < pages then
        table.insert(options, {
            string.format('Page %d/%d >>', page + 1, pages),
            function(p) showMainMenu(p, page + 1) end,
        })
    end

    local menu =
    {
        title   = (pages > 1)
            and string.format('Cross-Job Ability Trainer %d/%d', page, pages)
            or  'Cross-Job Ability Trainer',
        options = options,
    }
    local snapshot = { title = menu.title, options = menu.options }  -- shared table + deferred send
    player:timer(30, function(p) p:customMenu(snapshot) end)
end

-----------------------------------
-- Group menu: pick an ability to buy. Owned ones are marked with " *".
-----------------------------------
showGroupMenu = function(player, groupIndex, page)
    local group = catalog.groups[groupIndex]
    if not group then
        showMainMenu(player)
        return
    end

    local owned = ownedSet(player)
    local list  = group.abilities
    local pages = math.max(1, math.ceil(#list / GROUP_PAGE_SIZE))
    page = math.max(1, math.min(page or 1, pages))

    local startIdx = (page - 1) * GROUP_PAGE_SIZE + 1
    local endIdx   = math.min(startIdx + GROUP_PAGE_SIZE - 1, #list)

    local options = {}

    for i = startIdx, endIdx do
        local ab    = list[i]
        local label = owned[ab.id] and (ab.name .. ' *') or ab.name
        table.insert(options, {
            label,
            function(playerArg)
                showConfirmMenu(playerArg, groupIndex, ab)
            end,
        })
    end

    -- Page navigation (only shown when the group spans more than one page).
    if page > 1 then
        table.insert(options, {
            string.format('<< Page %d/%d', page - 1, pages),
            function(playerArg)
                showGroupMenu(playerArg, groupIndex, page - 1)
            end,
        })
    end
    if page < pages then
        table.insert(options, {
            string.format('Page %d/%d >>', page + 1, pages),
            function(playerArg)
                showGroupMenu(playerArg, groupIndex, page + 1)
            end,
        })
    end

    table.insert(options, {
        '<< Back',
        function(playerArg)
            showMainMenu(playerArg)
        end,
    })

    local menu =
    {
        title   = (pages > 1)
            and string.format('%s %d/%d (* = owned)', group.name, page, pages)
            or  string.format('%s  (* = owned)', group.name),
        options = options,
    }
    local snapshot = { title = menu.title, options = menu.options }  -- shared table + deferred send
    player:timer(30, function(p) p:customMenu(snapshot) end)
end

-----------------------------------
-- Confirm menu: buy one ability.
-----------------------------------
showConfirmMenu = function(player, groupIndex, ab)
    -- Show what the ability does + its home job/level before committing.
    player:printToPlayer(string.format('%s (%s Lv%d): %s', ab.name, ab.job, ab.lvl, ab.desc), xi.msg.channel.SYSTEM_3)

    -- Show how full the ability bar is on the player's CURRENT job so they
    -- understand a borrowed ability only fits under the 30-total (native +
    -- borrowed) recast-packet cap. A heavy job may leave little or no room; the
    -- ability still saves and re-activates on a lighter job.
    local used = player:getAbilityRecastCount()
    if used >= 30 then
        player:printToPlayer('  Heads-up: your ability bar is FULL (30/30) on this job - a borrowed ability stays dormant until you switch to a job with fewer abilities.', xi.msg.channel.SYSTEM_3)
    else
        player:printToPlayer(string.format('  Ability slots used on this job: %d/30 (room for %d more borrowed).', used, 30 - used), xi.msg.channel.SYSTEM_3)
    end

    if player:hasCrossJobAbility(ab.id) then
        player:printToPlayer(string.format('You already know %s. Use it with  /ja "%s" <me>', ab.name, ab.name), xi.msg.channel.SYSTEM_3)
        showGroupMenu(player, groupIndex)
        return
    end

    local owned = player:getCrossJobAbilities()
    if #owned >= MAX_CROSS_JOB_ABILITIES then
        player:printToPlayer(string.format('[ Cross-Job Trainer ] You have reached the limit of %d borrowed abilities.', MAX_CROSS_JOB_ABILITIES), xi.msg.channel.SYSTEM_3)
        showGroupMenu(player, groupIndex)
        return
    end

    local options =
    {
        {
            string.format('Yes - learn (%s gil)', GIL_STR),
            function(playerArg)
                -- Re-check on confirm (state may have changed).
                if playerArg:hasCrossJobAbility(ab.id) then
                    playerArg:printToPlayer(string.format('You already know %s.', ab.name), xi.msg.channel.SYSTEM_3)
                    showGroupMenu(playerArg, groupIndex)
                    return
                end

                local ownedNow = playerArg:getCrossJobAbilities()
                if #ownedNow >= MAX_CROSS_JOB_ABILITIES then
                    playerArg:printToPlayer(string.format('[ Cross-Job Trainer ] You have reached the limit of %d borrowed abilities.', MAX_CROSS_JOB_ABILITIES), xi.msg.channel.SYSTEM_3)
                    showGroupMenu(playerArg, groupIndex)
                    return
                end

                if playerArg:getGil() < GIL_COST then
                    playerArg:printToPlayer(string.format('You need %s gil to learn %s.', GIL_STR, ab.name), xi.msg.channel.SYSTEM_3)
                    showGroupMenu(playerArg, groupIndex)
                    return
                end

                -- Learn first; only charge if the engine accepted it, so a
                -- failure can never burn the player's gil.
                if playerArg:learnCrossJobAbility(ab.id) then
                    playerArg:delGil(GIL_COST)
                    playerArg:printToPlayer(string.format('Learned %s! Use it on any job with:  /ja "%s" <me>', ab.name, ab.name), xi.msg.channel.SYSTEM_3)
                else
                    playerArg:printToPlayer(string.format('Unable to learn %s right now.', ab.name), xi.msg.channel.SYSTEM_3)
                end

                showGroupMenu(playerArg, groupIndex)
            end,
        },
        {
            'No',
            function(playerArg)
                showGroupMenu(playerArg, groupIndex)
            end,
        },
    }

    local menu =
    {
        title   = string.format('Learn %s for %s gil?', ab.name, GIL_STR),
        options = options,
    }
    local snapshot = { title = menu.title, options = menu.options }  -- shared table + deferred send
    player:timer(30, function(p) p:customMenu(snapshot) end)
end

-----------------------------------
-- Module override: place the NPC in GM Home.
-----------------------------------
m:addOverride('xi.zones.Abdhaljs_Isle-Purgonorgo.Zone.onInitialize', function(zone)
    super(zone)

    local CrossJobTrainer = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'CrossJob_Trainer',
        packetName = string.format('%sBuy: Abilities', xi.icon.STAR_LARGE),
        look       = 167,
        -- Extends the GM Home progression row at z=-7:
        --   Gear (-3) / Augment Moogle (0) / Augment Sage (+3) / Trainer (+6).
        x          = 557.000,
        y          =   -3.360,
        z          =  539.500,
        rotation   =  48,
        widescan   =  1,

        onTrigger = function(player, npc)
            player:printToPlayer('[ Cross-Job Trainer ] Learn a job ability and use it on ANY job, kupo!', xi.msg.channel.SYSTEM_3)
            player:printToPlayer(string.format('  %s gil each. Borrowed abilities are used via macro (e.g. /ja "Meditate" <me>).', GIL_STR), xi.msg.channel.SYSTEM_3)
            showMainMenu(player)
        end,
    })
    utils.unused(CrossJobTrainer)
end)

return m
