-----------------------------------
-- Oggbi's Prime repeat forge
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Abdhaljs_Isle-Purgonorgo/Zone')

local m        = Module:new('prime_repeat_forge')
local C        = require('modules/custom/lua/prime_repeat_catalog')
local forge    = require('modules/custom/lua/weapon_forge_catalog')
local currency = require('modules/custom/lua/hl_seal_currency')

local SYS    = xi.msg.channel.SYSTEM_3
local PREFIX = '[Oggbi]'

local function totalMarks(player)
    local total = 0
    for _, var in ipairs(forge.markVars) do
        total = total + (player:getCharVar(var) or 0)
    end
    return total
end

local function drainMarks(player, amount)
    local prior = {}
    for _, var in ipairs(forge.markVars) do
        prior[var] = player:getCharVar(var) or 0
    end
    if totalMarks(player) < amount then return nil end

    local remaining = amount
    for _, var in ipairs(forge.markVars) do
        local have = prior[var]
        local take = math.min(have, remaining)
        player:setCharVar(var, have - take)
        remaining = remaining - take
        if remaining == 0 then break end
    end
    return prior
end

local function restoreMarks(player, prior)
    for var, value in pairs(prior or {}) do player:setCharVar(var, value) end
end

local function refundMedals(player)
    local remaining = C.demons
    while remaining > 0 do
        local amount = math.min(remaining, 99)
        if not player:addItem({ id = C.demonsId, quantity = amount }) then return false end
        remaining = remaining - amount
    end
    return true
end

m:addOverride('xi.zones.Abdhaljs_Isle-Purgonorgo.Zone.onInitialize', function(zone)
    super(zone)

    local function sendMenu(player, title, options)
        local snapshot = { title = title, options = options }
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    local function doForge(player, recipe)
        if (player:getCharVar(C.initialPrimeVar) or 0) ~= 1 then
            player:printToPlayer(
                PREFIX .. ' A first Prime must be won through the full pilgrimage. I have no shortcut for an untested hand.',
                SYS)
            return
        end
        if (player:getCharVar(C.pendingVar) or 0) ~= recipe.index then
            player:printToPlayer(
                PREFIX .. ' Present the four completed REMA of this weapon lineage before we speak of forging.',
                SYS)
            return
        end
        if player:hasItem(recipe.prime.id) then
            player:printToPlayer(string.format(
                PREFIX .. ' You already carry %s. Its spirit will not answer twice.', recipe.prime.name), SYS)
            return
        end
        if player:getFreeSlotsCount() == 0 then
            player:printToPlayer(PREFIX .. ' Make room for the weapon first.', SYS)
            return
        end
        if player:getItemCount(C.demonsId) < C.demons then
            player:printToPlayer(string.format(
                PREFIX .. ' Bring %d %s%s.', C.demons, C.demonsName, C.demons == 1 and '' or 's'), SYS)
            return
        end
        if totalMarks(player) < C.marks then
            player:printToPlayer(string.format(
                PREFIX .. ' Your legend is short. I require %d Reforge Marks.', C.marks), SYS)
            return
        end
        if player:getGil() < C.gil then
            player:printToPlayer(string.format(
                PREFIX .. ' The final tempering requires %d gil.', C.gil), SYS)
            return
        end

        local priorMarks = drainMarks(player, C.marks)
        if not priorMarks then return end
        if not currency.take(player, C.demonsId, C.demons) then
            restoreMarks(player, priorMarks)
            player:printToPlayer(PREFIX .. ' I could not gather the full medal payment.', SYS)
            return
        end
        player:delGil(C.gil)

        if not player:addItem({ id = recipe.prime.id, quantity = 1 }) then
            player:addGil(C.gil)
            restoreMarks(player, priorMarks)
            refundMedals(player)
            player:printToPlayer(
                PREFIX .. ' The lineage rejected the vessel. Your payment has been returned.', SYS)
            return
        end

        player:setCharVar(C.pendingVar, 0)
        player:setCharVar('WF_Prime_Final', 1)
        player:printToPlayer(string.format(
            PREFIX .. ' Four perfected legacies speak with one voice. Rise, %s, and prove the fifth.',
            recipe.prime.name), SYS)
    end

    local Oggbi = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Oggbi_Prime_Repeat',
        packetName = string.format('%sOggbi', xi.icon.STAR_LARGE),
        look       = C.oggbi.look,
        x          = C.oggbi.x,
        y          = C.oggbi.y,
        z          = C.oggbi.z,
        rotation   = C.oggbi.rotation,
        widescan   = 1,

        onTrade = function(player, npc, trade)
            if (player:getCharVar(C.initialPrimeVar) or 0) ~= 1 then
                player:printToPlayer(
                    PREFIX .. ' I have no business with you. Return when a Prime weapon has answered your hand.',
                    SYS)
                return
            end

            for _, recipe in ipairs(C.recipes) do
                if C.tradeMatches(trade, recipe) then
                    player:setCharVar(C.pendingVar, recipe.index)
                    player:printToPlayer(string.format(
                        PREFIX .. ' I know these four masterworks. Their lineage leads to %s. Take them back; they have earned their rest.',
                        recipe.prime.name), SYS)
                    player:printToPlayer(string.format(
                        PREFIX .. ' Return with %d Reforge Marks, %d %ss, and %d gil.',
                        C.marks, C.demons, C.demonsName, C.gil), SYS)
                    return
                end
            end

            player:printToPlayer(
                PREFIX .. ' These arms do not form one lineage. Bring one final Relic, Empyrean, Mythic, and Aeonic of the same weapon kind.',
                SYS)
        end,

        onTrigger = function(player, npc)
            local pending = player:getCharVar(C.pendingVar) or 0
            local recipe = C.recipes[pending]
            if not recipe then
                player:printToPlayer(
                    PREFIX .. ' I have no business with empty claims. Show me four perfected weapons of one lineage.',
                    SYS)
                return
            end

            player:printToPlayer(string.format(
                PREFIX .. ' The path to %s is acknowledged: %d Marks, %d %ss, and %d gil.',
                recipe.prime.name, C.marks, C.demons, C.demonsName, C.gil), SYS)
            sendMenu(player, 'Prime Lineage: ' .. recipe.prime.name,
            {
                { 'Complete the repeat forge', function(p) doForge(p, recipe) end },
                { 'Not yet.', function() end },
            })
        end,
    })
    utils.unused(Oggbi)

    local Apparition = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Prime_Lineage_Apparition',
        packetName = '',
        look       = C.apparition.look,
        x          = C.apparition.x,
        y          = C.apparition.y,
        z          = C.apparition.z,
        rotation   = C.apparition.rotation,
        widescan   = 0,
    })
    utils.unused(Apparition)
end)

return m
