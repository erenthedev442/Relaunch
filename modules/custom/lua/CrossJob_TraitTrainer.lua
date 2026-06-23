-----------------------------------
-- CrossJob_TraitTrainer.lua
--
-- Sibling to the Cross-Job Ability Trainer: an NPC at GM Home that sells
-- "borrowed" JOB TRAITS usable on ANY job, for a flat gil cost each.
--
-- Traits are passive MODIFIERS (not learnable abilities). A purchase sets a
-- per-trait charVar and applies the mod(s) additively via addMod. Traits that
-- also unlock an equipment slot (e.g. Dual Wield) additionally call addTrait()
-- to set the m_TraitList bit the engine's hasTrait() equip-check reads.
-- The onGameIn override re-applies everything after a zone wipe. No macro: they
-- just work.
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
-- purchase and on every onGameIn re-apply. Traits with an equip-unlock (e.g.
-- Dual Wield) also set the trait bit so the engine's hasTrait() checks pass.
local function applyTrait(player, trait)
    for _, mv in ipairs(trait.mods) do
        player:addMod(mv[1], mv[2])
    end
    -- Traits that unlock an equipment slot (Dual Wield -> off-hand) set the real engine
    -- trait BIT, which the CLIENT reads (via the 0x0AC command-data packet, pushed by the
    -- caller's sendCommandData) to allow the slot on ANY job -- the client otherwise gates
    -- the off-hand locally and never even sends the equip. addTrait/sendCommandData ARE
    -- valid bindings on this build (an older build lacked them -- hence the prior notes).
    -- C++ BuildingCharTraitsTable ALSO grants this bit on every trait rebuild (login/zone/
    -- JOB CHANGE) for CJTrait_dwield owners, so it survives a /job swap (which onGameIn does
    -- NOT catch); this Lua call covers the live-purchase moment + the zone/login re-apply.
    -- addTrait sets ONLY the bit; the addMod above is the +15% delay reduction.
    if trait.trait then
        player:addTrait(trait.trait)
    end
end

-- Re-apply every owned trait (a zone-in/login wipes in-memory mods), then
-- push the command-data packet so the client's trait UI reflects the new bits.
local function applyAll(player)
    for _, trait in ipairs(catalog.traits) do
        if owns(player, trait) then
            applyTrait(player, trait)
        end
    end
    -- Push refreshed trait/command data so equip-slot unlocks (Dual Wield -> off-hand)
    -- reach the client without a relog. sendCommandData IS a valid binding on the current
    -- build (an earlier build lacked it -- hence the prior drop here).
    player:sendCommandData()
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
                p:sendCommandData()
                p:printToPlayer(string.format('Learned %s! It now applies on every job, kupo.', trait.name), S)
                if trait.id == 'dwield' then
                    p:printToPlayer('Your off-hand slot is now unlocked -- equip a 1-handed weapon there. If it will not stick, change main job and back (or relog) once.', S)
                end
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
        packetName = string.format('%sBuy: Traits', xi.icon.STAR_LARGE),
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
-- Re-apply owned traits after a zone reload wipes in-memory mods (Prestige
-- pattern). JOB CHANGE needs NO hook (verified by tracing the engine): the
-- handler 0x100_myroom_job.cpp -> BuildingCharTraitsTable (charutils.cpp:4027)
-- delModifier's only the TRACKED gear/trait/gift mods by their exact value and
-- never blanket-clears m_modStat, so a standalone addMod like ours survives a
-- /job switch untouched. Only a zone reload wipes mods, which this re-applies.
-----------------------------------
m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    -- Defer 3s: synchronous addMod in onGameIn is clobbered by post-login
    -- stat finalization (same pattern as Prestige/JobRebirth fix 3aa33a2469).
    player:timer(3000, function(p) applyAll(p) end)
end)

return m
