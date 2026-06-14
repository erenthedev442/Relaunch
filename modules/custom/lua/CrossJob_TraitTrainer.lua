-----------------------------------
-- CrossJob_TraitTrainer.lua
--
-- Sibling to the Cross-Job Ability Trainer: an NPC at GM Home that sells
-- "borrowed" JOB TRAITS usable on ANY job, for a flat gil cost each.
--
-- Traits are passive MODIFIERS (not learnable abilities), so there's no C++
-- binding here: a purchase sets a per-trait charVar and applies the mod(s)
-- additively, and the onGameIn override re-applies every owned trait after a
-- zone-in/login rebuilds (and wipes) in-memory mods -- the same trick the
-- Prestige system uses. Unlike borrowed abilities, traits are passive, so they
-- need NO macro: they just work.
--
-- Sellable list: modules/custom/lua/cross_job_trait_catalog.lua.
-- A SEPARATE NPC (not a branch on the Ability Trainer) because that NPC's main
-- menu is already at the client's 8-option GMPROMPT cap.
--
-- Zone: GM Home (zone 210)
-----------------------------------
require('modules/module_utils')
require('scripts/zones/GM_Home/Zone')
local catalog = require('modules/custom/lua/cross_job_trait_catalog')

local m = Module:new('crossjob_traittrainer')

local S        = xi.msg.channel.SYSTEM_3
local GIL_COST = catalog.GIL_COST

-- 10000000 -> "10,000,000"
local function commafy(n)
    local s = tostring(math.floor(n))
    local out = s:reverse():gsub('(%d%d%d)', '%1,'):reverse()
    return (out:gsub('^,', ''))
end
local GIL_STR = commafy(GIL_COST)

local function cvKey(trait)        return catalog.cvPrefix .. trait.id end
local function owns(player, trait) return (player:getCharVar(cvKey(trait)) or 0) == 1 end

-- Apply one trait's mods additively (so they stack with gear). Called on
-- purchase and on every onGameIn re-apply.
local function applyTrait(player, trait)
    for _, mv in ipairs(trait.mods) do
        player:addMod(mv[1], mv[2])
    end
end

-- Re-apply every owned trait (a zone-in/login wipes in-memory mods).
local function applyAll(player)
    for _, trait in ipairs(catalog.traits) do
        if owns(player, trait) then
            applyTrait(player, trait)
        end
    end
end

local showMenu, showConfirm

-----------------------------------
-- Trait list. Owned ones are marked " *".
-----------------------------------
showMenu = function(player)
    local options = {}
    for _, trait in ipairs(catalog.traits) do
        local t     = trait
        local label = owns(player, t) and (t.name .. ' *') or t.name
        table.insert(options, { label, function(p) showConfirm(p, t) end })
    end
    table.insert(options, {
        'How it works',
        function(p)
            p:printToPlayer('[ Trait Trainer ] Buy a passive job trait and keep it on ANY job, kupo.', S)
            p:printToPlayer(string.format('  %s gil each. Traits are passive -- no macro needed, unlike borrowed abilities.', GIL_STR), S)
            showMenu(p)
        end,
    })

    local menu     = { title = 'Cross-Job Trait Trainer  (* = owned)', options = options }
    local snapshot = { title = menu.title, options = menu.options }
    player:timer(30, function(p) p:customMenu(snapshot) end)
end

-----------------------------------
-- Confirm + buy one trait.
-----------------------------------
showConfirm = function(player, trait)
    player:printToPlayer(string.format('%s: %s', trait.name, trait.desc), S)

    if owns(player, trait) then
        player:printToPlayer(string.format('You already have %s -- it applies on every job.', trait.name), S)
        showMenu(player)
        return
    end

    local options =
    {
        {
            string.format('Yes - buy (%s gil)', GIL_STR),
            function(p)
                if owns(p, trait) then
                    showMenu(p)
                    return
                end
                if p:getGil() < GIL_COST then
                    p:printToPlayer(string.format('You need %s gil for %s.', GIL_STR, trait.name), S)
                    showMenu(p)
                    return
                end
                p:delGil(GIL_COST)
                p:setCharVar(cvKey(trait), 1)
                applyTrait(p, trait)
                p:printToPlayer(string.format('Learned %s! It now applies on every job, kupo.', trait.name), S)
                showMenu(p)
            end,
        },
        {
            'No',
            function(p) showMenu(p) end,
        },
    }

    local menu     = { title = string.format('Buy %s for %s gil?', trait.name, GIL_STR), options = options }
    local snapshot = { title = menu.title, options = menu.options }
    player:timer(30, function(p) p:customMenu(snapshot) end)
end

-----------------------------------
-- NPC placement.
-----------------------------------
m:addOverride('xi.zones.GM_Home.Zone.onInitialize', function(zone)
    super(zone)

    local TraitTrainer = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'CrossJob_TraitTrainer',
        packetName = string.format('%sCross-Job Trait Trainer', xi.icon.STAR_LARGE),
        look       = 2401,
        x          = catalog.npcPos.x,
        y          = catalog.npcPos.y,
        z          = catalog.npcPos.z,
        rotation   = catalog.npcPos.rot,
        widescan   = 1,

        onTrigger = function(player, npc)
            player:printToPlayer('[ Trait Trainer ] Buy a passive job trait and use it on ANY job, kupo!', S)
            player:printToPlayer(string.format('  %s gil each. No macro needed -- traits are always-on.', GIL_STR), S)
            showMenu(player)
        end,
    })
    utils.unused(TraitTrainer)
end)

-----------------------------------
-- Re-apply owned traits after a zone-in/login rebuilds (and wipes) in-memory
-- mods. Same pattern as Prestige_System. NOTE: a job change may also rebuild
-- mods; if a trait drops after switching jobs, a quick zone restores it
-- (onGameIn fires on zone-in). Add a job-change hook here if testing needs it.
-----------------------------------
m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    applyAll(player)
    super(player, firstLogin, zoning)
end)

return m
