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
require('scripts/zones/GM_Home/Zone')
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
showMainMenu = function(player)
    local options = {}

    for idx, group in ipairs(catalog.groups) do
        local groupIndex = idx
        table.insert(options, {
            group.name,
            function(playerArg)
                showGroupMenu(playerArg, groupIndex)
            end,
        })
    end

    table.insert(options, {
        'How it works',
        function(playerArg)
            playerArg:printToPlayer('[ Cross-Job Trainer ] Buy a job ability and use it on ANY job.', xi.msg.channel.SYSTEM_3)
            playerArg:printToPlayer(string.format('  Cost: %s gil each. The ability stays with you across jobs and logins.', GIL_STR), xi.msg.channel.SYSTEM_3)
            playerArg:printToPlayer('  It will NOT show in your Job Abilities menu - use a macro, e.g.  /ja "Meditate" <me>', xi.msg.channel.SYSTEM_3)
            showMainMenu(playerArg)
        end,
    })

    local menu =
    {
        title   = 'Cross-Job Ability Trainer',
        options = options,
    }
    player:timer(50, function(p) p:customMenu(menu) end)
end

-----------------------------------
-- Group menu: pick an ability to buy. Owned ones are marked with " *".
-----------------------------------
showGroupMenu = function(player, groupIndex)
    local group = catalog.groups[groupIndex]
    if not group then
        showMainMenu(player)
        return
    end

    local owned   = ownedSet(player)
    local options = {}

    for _, ability in ipairs(group.abilities) do
        local ab    = ability
        local label = owned[ab.id] and (ab.name .. ' *') or ab.name
        table.insert(options, {
            label,
            function(playerArg)
                showConfirmMenu(playerArg, groupIndex, ab)
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
        title   = string.format('%s  (* = owned)', group.name),
        options = options,
    }
    player:timer(50, function(p) p:customMenu(menu) end)
end

-----------------------------------
-- Confirm menu: buy one ability.
-----------------------------------
showConfirmMenu = function(player, groupIndex, ab)
    -- Show what the ability does + its home job/level before committing.
    player:printToPlayer(string.format('%s (%s Lv%d): %s', ab.name, ab.job, ab.lvl, ab.desc), xi.msg.channel.SYSTEM_3)

    if player:hasCrossJobAbility(ab.id) then
        player:printToPlayer(string.format('You already know %s. Use it with  /ja "%s" <me>', ab.name, ab.name), xi.msg.channel.SYSTEM_3)
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
    player:timer(50, function(p) p:customMenu(menu) end)
end

-----------------------------------
-- Module override: place the NPC in GM Home.
-----------------------------------
m:addOverride('xi.zones.GM_Home.Zone.onInitialize', function(zone)
    super(zone)

    local CrossJobTrainer = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'CrossJob_Trainer',
        packetName = string.format('%sCross-Job Trainer', xi.icon.STAR_LARGE),
        look       = 2401,
        -- Extends the GM Home progression row at z=-7:
        --   Gear (-3) / Augment Moogle (0) / Augment Sage (+3) / Trainer (+6).
        x          =  6.000,
        y          =  0.000,
        z          = -7.000,
        rotation   =  128,
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
