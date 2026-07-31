-----------------------------------
-- Mythic repeat forge
--
-- Completing one Mythic through the full Weapon Forge path unlocks direct
-- repeat forging of final mythic weapons for Beitetsu only.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Abdhaljs_Isle-Purgonorgo/Zone')

local m        = Module:new('mythic_forge')
local catalog  = require('modules/custom/lua/mythic_forge_catalog')
local currency = require('modules/custom/lua/hl_seal_currency')

local NPC_POS   = { x = 532.9669, y = -3.1591, z = 469.2771, rot = 188 }
local ODIN_LOOK = 3411 -- Einherjar Odin (mounted); see mob_groups Odin in Hazhalm
local PAGE_SIZE = 4
local PREFIX      = '[Mythic Forge]'

local function costStr()
    return string.format('%d %s', catalog.cost, catalog.currencyName)
end

local function refundCurrency(player)
    local remaining = catalog.cost
    while remaining > 0 do
        local quantity = math.min(remaining, 99)
        if not player:addItem({ id = catalog.currencyId, quantity = quantity }) then
            return false
        end

        remaining = remaining - quantity
    end

    return true
end

m:addOverride('xi.zones.Abdhaljs_Isle-Purgonorgo.Zone.onInitialize', function(zone)
    super(zone)

    local function sendMenu(player, title, options)
        local snapshot = { title = title, options = options }
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    local showWeapons

    local function doForge(player, weapon)
        if (player:getCharVar('WF_Mythic_Final') or 0) ~= 1 then
            player:printToPlayer(
                PREFIX .. ' Complete one Mythic to 119 III through the full Weapon Forge path first.',
                xi.msg.channel.SYSTEM_3)
            return
        end

        if player:getFreeSlotsCount() == 0 then
            player:printToPlayer(PREFIX .. ' Free an inventory slot first.', xi.msg.channel.SYSTEM_3)
            return
        end

        if player:hasItem(weapon.id) then
            player:printToPlayer(string.format(
                PREFIX .. ' You already hold %s -- it is RARE, so a second cannot be forged.',
                weapon.name), xi.msg.channel.SYSTEM_3)
            return
        end

        local held = player:getItemCount(catalog.currencyId)
        if held < catalog.cost then
            player:printToPlayer(string.format(
                PREFIX .. ' Need %s (you have %d).', costStr(), held),
                xi.msg.channel.SYSTEM_3)
            return
        end

        if not currency.take(player, catalog.currencyId, catalog.cost) then
            player:printToPlayer(
                PREFIX .. ' I could not gather the full Beitetsu payment, so nothing was forged.',
                xi.msg.channel.SYSTEM_3)
            return
        end

        if not player:addItem({ id = weapon.id, quantity = 1 }) then
            refundCurrency(player)
            player:printToPlayer(
                PREFIX .. ' The forging failed -- your Beitetsu has been returned.',
                xi.msg.channel.SYSTEM_3)
            return
        end

        player:printToPlayer(string.format(
            PREFIX .. ' %s has been tempered anew from imperial steel and runic fire!',
            weapon.name), xi.msg.channel.SYSTEM_3)
    end

    local function showConfirm(player, weapon, page)
        sendMenu(player, string.format('Forge %s?', weapon.name),
        {
            {
                string.format('Forge for %s', costStr()),
                function(p)
                    doForge(p, weapon)
                    showWeapons(p, page)
                end,
            },
            { 'No - go back.', function(p) showWeapons(p, page) end },
        })
    end

    showWeapons = function(player, page)
        page = page or 1
        local totalPages = math.ceil(#catalog.weapons / PAGE_SIZE)
        local options    = {}
        local startIdx   = (page - 1) * PAGE_SIZE + 1
        local endIdx     = math.min(startIdx + PAGE_SIZE - 1, #catalog.weapons)

        for index = startIdx, endIdx do
            local weapon = catalog.weapons[index]
            options[#options + 1] =
            {
                weapon.name,
                function(p)
                    p:printToPlayer(weapon.info, xi.msg.channel.SYSTEM_3)
                    showConfirm(p, weapon, page)
                end,
            }
        end

        if page > 1 then
            options[#options + 1] =
            {
                string.format('<< Prev (%d/%d)', page - 1, totalPages),
                function(p) showWeapons(p, page - 1) end,
            }
        end

        if page < totalPages then
            options[#options + 1] =
            {
                string.format('Next >> (%d/%d)', page + 1, totalPages),
                function(p) showWeapons(p, page + 1) end,
            }
        end

        options[#options + 1] = { 'Never mind.', function() end }
        sendMenu(player, string.format('Mythic Forge (%d/%d)', page, totalPages), options)
    end

    local MythicForge = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Odin_Mythic_Forge',
        packetName = string.format('Odin %sMythic Forge', xi.icon.STAR_LARGE),
        look       = ODIN_LOOK,
        x          = NPC_POS.x,
        y          = NPC_POS.y,
        z          = NPC_POS.z,
        rotation   = NPC_POS.rot,
        widescan   = 1,

        onTrade = function(player, npc, trade)
            player:printToPlayer(
                PREFIX .. ' No trades -- choose a mythic weapon from the menu.',
                xi.msg.channel.SYSTEM_3)
        end,

        onTrigger = function(player, npc)
            if (player:getCharVar('WF_Mythic_Final') or 0) ~= 1 then
                player:printToPlayer(
                    PREFIX .. ' Walk the full Mythic path at the Weapon Forger before I will temper another blade for you.',
                    xi.msg.channel.SYSTEM_3)
                return
            end

            player:printToPlayer(string.format(
                PREFIX .. ' Repeat mythics cost %s each.', costStr()),
                xi.msg.channel.SYSTEM_3)
            showWeapons(player, 1)
        end,
    })
    utils.unused(MythicForge)
end)

return m
