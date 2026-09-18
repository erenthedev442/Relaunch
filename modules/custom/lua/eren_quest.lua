-----------------------------------
-- The Name Beyond the Ferry
-- World interactions, story menus, and quest entry points.
--
-- This module adds quest-only objects in four existing zones.  It does not
-- move, rename, replace, or rebind any hub NPC.  The Fellow Officer and Hades
-- call the public xi.erenQuest menu API from their existing handlers.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Gusgen_Mines/Zone')
require('scripts/zones/FeiYin/Zone')
require('scripts/zones/Xarcabard/Zone')
require('scripts/zones/Walk_of_Echoes/Zone')

local m = Module:new('eren_quest')
local catalog = require('modules/custom/lua/eren_quest_catalog')
local runtime = require('modules/custom/lua/eren_quest_instance')
local SYS = xi.msg.channel.SYSTEM_3

local Q = {}

local function say(player, speaker, text)
    player:printToPlayer(string.format('[%s] %s', speaker, text), SYS)
end

local function show(player, title, options)
    local snapshot = { title = title, options = options }
    player:timer(30, function(p) p:customMenu(snapshot) end)
end

local function status(player)
    for _, line in ipairs(catalog.statusLines(player)) do
        player:printToPlayer(line, SYS)
    end
end

local function ensureMasteredBond(player)
    if not catalog.isMastered(player) then
        say(player, 'Thread', 'The bond is no longer fully mastered. Restore all fourteen stat tracks before continuing.')
        return false
    end
    return true
end

local function beginEncounter(player, encounterId)
    if not ensureMasteredBond(player) then
        return
    end
    local ok, reason = runtime.start(player, encounterId)
    if not ok then
        say(player, 'Thread', reason)
    end
end

local function memoryReplay(player, page)
    page = page or 1
    local memories =
    {
        {
            title = 'The Mortal Ferryman',
            text = 'Eren was mortal. When the road to Hades broke, he refused his own crossing and carried strangers ahead of himself.',
        },
        {
            title = 'The Six Remembrances',
            text = 'Resolve, guardianship, discernment, insight, fury, and mercy were not powers bestowed on Eren. They were choices he made until they became his soul.',
        },
        {
            title = 'The Fracture',
            text = 'The passage collapsed before the last souls crossed. Eren split his own spirit six ways to hold it open, leaving his guilt behind as the Last Uncrossed.',
        },
        {
            title = 'The Living Bond',
            text = string.format('%s chose the merger freely. Eren accepted only after seeing that a mastered bond could change without being erased.', catalog.formerName(player)),
        },
    }
    page = math.max(1, math.min(page, #memories))
    local entry = memories[page]
    say(player, 'Memory', entry.text)
    local options = {}
    if page > 1 then
        options[#options + 1] = { 'Previous memory', function(p) memoryReplay(p, page - 1) end }
    end
    if page < #memories then
        options[#options + 1] = { 'Next memory', function(p) memoryReplay(p, page + 1) end }
    end
    options[#options + 1] = { 'Close', function() end }
    show(player, string.format('%s (%d/%d)', entry.title, page, #memories), options)
end

local function officerEpilogue(player)
    local oldName = catalog.formerName(player)
    say(player, 'Fellow Officer', string.format(
        'Eren still pauses exactly as %s did before answering you. Whatever crossed that day, your bond did not vanish.', oldName))
    show(player, 'A Name Remembered',
    {
        { 'Recovered memories', function(p) memoryReplay(p, 1) end },
        { 'Quest status', function(p) status(p); officerEpilogue(p) end },
        { 'Close', function() end },
    })
end

local function acceptanceMenu(player)
    local eligible, reason = catalog.canAccept(player)
    if not eligible then
        if reason == 'mastery' then
            say(player, 'Fellow Officer', 'The second shadow has not formed. Every one of the fourteen stat tracks must reach 100.')
        end
        return
    end

    local fellowName = catalog.fellowName(player)
    say(player, 'Fellow Officer', string.format(
        '%s has stopped growing, but another outline moves inside the shadow you share. It is not possession. It is an answer waiting to be heard.',
        fellowName))
    say(player, 'Fellow Officer',
        'Hades keeps the names of souls that never reached his ferry. If this shadow belongs to one of them, only he will know.')
    show(player, 'The Second Shadow',
    {
        {
            'Follow the second shadow',
            function(p)
                local ok = catalog.accept(p)
                if ok then
                    say(p, 'Fellow Officer', 'Go together. Speak with Hades on the northeastern beach.')
                    status(p)
                end
            end,
        },
        { 'Not yet', function() end },
    })
end

function Q.openOfficer(player)
    if not catalog.hasAccess(player) then
        return
    end
    runtime.recover(player)
    catalog.reconcile(player)
    catalog.migrateLegacy(player, true)

    if catalog.isUnlocked(player) then
        officerEpilogue(player)
    elseif catalog.getStage(player) == catalog.stage.LOCKED then
        acceptanceMenu(player)
    else
        status(player)
        show(player, catalog.title,
        {
            { 'Review quest status', function(p) status(p) end },
            { 'Close', function() end },
        })
    end
end

function Q.shouldShowOfficer(player)
    return catalog.shouldShowOfficer(player)
end

local function showRemembranceMenu(player, page)
    page = page or 1
    local perPage = 3
    local first = (page - 1) * perPage + 1
    local last = math.min(first + perPage - 1, #catalog.memoryOrder)
    local options = {}
    for index = first, last do
        local key = catalog.memoryOrder[index]
        local memory = catalog.memories[key]
        local complete = catalog.memoryComplete(player, key)
        local capturedKey = key
        local capturedMemory = memory
        local capturedPage = page
        options[#options + 1] =
        {
            string.format('%s%s [%s]', complete and '* ' or '', memory.label, memory.role),
            function(p)
                if catalog.memoryComplete(p, capturedKey) then
                    say(p, 'Hades', capturedMemory.label .. ' already rests within the thread.')
                    showRemembranceMenu(p, capturedPage)
                    return
                end
                say(p, 'Hades', capturedMemory.summary)
                show(p, capturedMemory.label,
                {
                    { 'Enter this remembrance', function(pp) beginEncounter(pp, capturedMemory.encounter) end },
                    { 'Return', function(pp) showRemembranceMenu(pp, capturedPage) end },
                })
            end,
        }
    end
    if page > 1 then
        options[#options + 1] = { 'Previous trials', function(p) showRemembranceMenu(p, page - 1) end }
    end
    if last < #catalog.memoryOrder then
        options[#options + 1] = { 'More trials', function(p) showRemembranceMenu(p, page + 1) end }
    end
    options[#options + 1] = { 'Quest status', function(p) status(p); showRemembranceMenu(p, page) end }
    options[#options + 1] = { 'Close', function() end }
    show(player, string.format('Six Remembrances %d/2', page), options)
end

local function confirmFinalTransformation(player)
    local oldName = catalog.fellowName(player)
    say(player, 'Hades', string.format(
        '%s and Eren have both consented. The memories will remain, but the name and shape that return will be Eren.',
        oldName))
    say(player, oldName,
        'I know what will change. I also know what will remain. If you still choose this road, I choose it with you.')
    show(player, 'A Soul Beside A Soul',
    {
        {
            'I understand. Continue.',
            function(p)
                show(p, 'THIS CANNOT BE UNDONE',
                {
                    {
                        'Transform my Fellow into Eren',
                        function(pp)
                            local former = catalog.fellowName(pp)
                            if catalog.transform(pp) then
                                say(pp, 'Hades', 'A soul is not spent. A soul is answered.')
                                say(pp, 'Eren', string.format(
                                    '%s is not gone. Those memories are mine now—and ours.', former))
                                if xi.fellow and xi.fellow.respawnIfOut then
                                    pcall(function() xi.fellow.respawnIfOut(pp) end)
                                end
                                status(pp)
                            else
                                say(pp, 'Hades', 'The crossing is no longer ready. Speak to me again.')
                            end
                        end,
                    },
                    { 'No. Leave us as we are.', function() end },
                })
            end,
        },
        { 'Not yet', function() end },
    })
end

function Q.openHades(player)
    if not catalog.hasAccess(player) then
        return
    end
    runtime.recover(player)
    catalog.reconcile(player)
    catalog.migrateLegacy(player, true)
    local stage = catalog.getStage(player)

    if catalog.isUnlocked(player) then
        say(player, 'Hades', 'The ferryman\'s guise suits the soul that finally chose to return.')
        show(player, 'The Name Beyond the Ferry',
        {
            { 'Hear a recovered memory', function(p) memoryReplay(p, 1) end },
            { 'Close', function() end },
        })
    elseif stage == catalog.stage.SECOND_SHADOW then
        local fellowName = catalog.fellowName(player)
        say(player, 'Hades', string.format(
            '%s carries a second shadow with a name: Eren. He was a mortal warrior who refused my ferry until every soul behind him had crossed.',
            fellowName))
        say(player, 'Hades',
            'The road broke first. His spirit became six remembrances holding the dead apart from the living. Your completed bond has made them stir.')
        show(player, 'The Thread of the Uncrossed',
        {
            {
                'Take the thread together',
                function(p)
                    if ensureMasteredBond(p) and catalog.beginPilgrimage(p) then
                        say(p, 'Hades', 'Gusgen. Fei\'Yin. Xarcabard. The Walk of Echoes. Follow what the dead could not erase.')
                        status(p)
                    end
                end,
            },
            { 'Not yet', function() end },
        })
    elseif stage == catalog.stage.PILGRIMAGE then
        say(player, 'Hades', 'Four footprints. Recover each with your Fellow beside you.')
        status(player)
    elseif stage == catalog.stage.REMEMBRANCES then
        say(player, 'Hades', 'Eren divided himself into six choices. Your Fellow must live each one, not merely hear its name.')
        showRemembranceMenu(player, 1)
    elseif stage == catalog.stage.BOND then
        say(player, 'Hades',
            'You have learned who Eren was. Now prove that the bond standing here is more than a vessel waiting to be filled.')
        show(player, 'The Bond That Remains',
        {
            { 'Enter the three-room crossing', function(p) beginEncounter(p, 20) end },
            { 'Quest status', function(p) status(p) end },
            { 'Not yet', function() end },
        })
    elseif stage == catalog.stage.EREN then
        say(player, 'Hades',
            'Your Fellow has chosen change without surrender. Eren still fears that his return would erase the soul that carries him.')
        show(player, 'Eren, Unwhole',
        {
            { 'Face Eren together', function(p) beginEncounter(p, 30) end },
            { 'Quest status', function(p) status(p) end },
            { 'Not yet', function() end },
        })
    elseif stage == catalog.stage.CROSSING then
        say(player, 'Hades',
            'Eren has consented. One thing remains: the guilt that took the shape of every soul he believes he failed.')
        show(player, 'The Last Crossing',
        {
            { 'Open the final crossing', function(p) beginEncounter(p, 40) end },
            { 'Quest status', function(p) status(p) end },
            { 'Not yet', function() end },
        })
    elseif stage == catalog.stage.DECISION then
        confirmFinalTransformation(player)
    end
end

function Q.shouldShowHades(player)
    return catalog.hasAccess(player) and (
        catalog.isUnlocked(player) or catalog.getStage(player) >= catalog.stage.SECOND_SHADOW)
end

function Q.status(player)
    if catalog.hasAccess(player) then
        runtime.recover(player)
        status(player)
    end
end

function Q.abort(player)
    return runtime.abort(player)
end

function Q.recover(player)
    return runtime.recover(player)
end

local function siteMenu(player, key)
    local site = catalog.sites[key]
    if not catalog.hasAccess(player) or catalog.getStage(player) ~= catalog.stage.PILGRIMAGE then
        say(player, 'Old Memorial', 'Nothing answers your touch.')
        return
    elseif catalog.siteComplete(player, key) then
        say(player, 'Thread', 'This footprint is already woven into the bond.')
        return
    elseif not ensureMasteredBond(player) then
        return
    end

    local fellowName = catalog.fellowName(player)
    local text =
    {
        gusgen = string.format('%s hears three lamps repeat the same command in different voices: carry the frightened, face the danger, cross last.', fellowName),
        feiyin = string.format('Ice preserves Eren\'s first promise: "If I can still stand, no soul behind me stands alone." %s steps beside the echo.', fellowName),
        xarcabard = string.format('A shade is eating the trail one footprint at a time. %s points toward the last trace before it disappears.', fellowName),
        echoes = string.format('The final stand remains here: Eren splitting his spirit to hold a broken passage open. %s refuses to look away.', fellowName),
    }
    say(player, 'Thread', text[key])

    if key == 'gusgen' then
        show(player, 'Reconstruct the Memorial',
        {
            {
                'Carry, face, cross',
                function(p)
                    say(p, 'Thread', 'The lamps align. Remorse rises from beneath them to test whether the order still has meaning.')
                    beginEncounter(p, site.encounter)
                end,
            },
            {
                'Face, cross, carry',
                function(p)
                    say(p, 'Thread', 'The order is wrong. A corrective memory tears the answer from the stone.')
                    beginEncounter(p, 5)
                end,
            },
            {
                'Cross, carry, face',
                function(p)
                    say(p, 'Thread', 'The order is wrong. A corrective memory tears the answer from the stone.')
                    beginEncounter(p, 5)
                end,
            },
            { 'Step away', function() end },
        })
    else
        show(player, site.label,
        {
            { 'Enter the recovered footprint', function(p) beginEncounter(p, site.encounter) end },
            { 'Step away', function() end },
        })
    end
end

local function installSite(zone, key)
    local site = catalog.sites[key]
    local pos = site.pos
    local npc = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Eren_Memory_' .. key,
        packetName = site.packetName,
        look       = site.look,
        x          = pos.x,
        y          = pos.y,
        z          = pos.z,
        rotation   = pos.rot,
        widescan   = 0,
        onTrigger  = function(player)
            siteMenu(player, key)
        end,
    })
    utils.unused(npc)
end

for _, key in ipairs(catalog.siteOrder) do
    local site = catalog.sites[key]
    local capturedKey = key
    m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', site.zone), function(zone)
        super(zone)
        installSite(zone, capturedKey)
    end)
end

-- The quest runtime summons its flagged Fellow through the raw Fellow API.
-- Ordinary Trust spells are blocked before they can act in the private arena.
m:addOverride('xi.trust.canCast', function(caster, spell, notAllowedTrustIds)
    if (caster:getCharVar(catalog.vars.active) or 0) == catalog.instanceId then
        caster:printToPlayer('[Beyond the Ferry] Ordinary trusts cannot enter these memories.', SYS)
        return xi.msg.basic.TRUST_NO_CAST_TRUST
    end
    return super(caster, spell, notAllowedTrustIds)
end)

m:addOverride('xi.player.onGameIn', function(player, gameLogin, zoning)
    super(player, gameLogin, zoning)
    if not player:getInstance() then
        player:timer(1000, function(p)
            runtime.recover(p)
        end)
    end
end)

xi.erenQuest = Q
m.openOfficer = Q.openOfficer
m.openHades = Q.openHades
m.shouldShowOfficer = Q.shouldShowOfficer
m.shouldShowHades = Q.shouldShowHades
m.status = Q.status
m.abort = Q.abort
m.recover = Q.recover

return m
