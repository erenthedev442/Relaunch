-----------------------------------
-- Aeonic repeat forge
--
-- Completing one Aeonic through the full Weapon Forge path unlocks direct
-- repeat forging of final Aeonic weapons for Escha Silt only.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Abdhaljs_Isle-Purgonorgo/Zone')

local m       = Module:new('aeonic_forge')
local catalog = require('modules/custom/lua/aeonic_forge_catalog')

local NPC_POS     = { x = 505.4466, y = -3.0279, z = 487.2905, rot = 250 }
local TEMPRIX_LOOK = '0x0000E20300000000000000000000000000000000'
local PAGE_SIZE   = 4
local PREFIX      = '[Temprix]'

local function costStr()
    return string.format('%d %s', catalog.cost, catalog.currencyName)
end

local function refundCurrency(player)
    player:addCurrency(catalog.currencyKey, catalog.cost)
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
        if (player:getCharVar('WF_Aeonic_Final') or 0) ~= 1 then
            player:printToPlayer(
                PREFIX .. ' Complete one Aeonic to 119 III through the full Weapon Forge path first.',
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

        local held = player:getCurrency(catalog.currencyKey) or 0
        if held < catalog.cost then
            player:printToPlayer(string.format(
                PREFIX .. ' Need %s (you have %d).', costStr(), held),
                xi.msg.channel.SYSTEM_3)
            return
        end

        player:delCurrency(catalog.currencyKey, catalog.cost)
        if not player:addItem({ id = weapon.id, quantity = 1 }) then
            refundCurrency(player)
            player:printToPlayer(
                PREFIX .. ' The forging failed -- your Escha Silt has been returned.',
                xi.msg.channel.SYSTEM_3)
            return
        end

        player:printToPlayer(string.format(
            PREFIX .. ' %s has been reforged from the crucible of eternity!',
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
        sendMenu(player, string.format('Aeonic Forge (%d/%d)', page, totalPages), options)
    end

    local AeonicForge = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Temprix_Aeonic_Forge',
        packetName = string.format('Temprix %sAeonic Forge', xi.icon.STAR_LARGE),
        look       = TEMPRIX_LOOK,
        x          = NPC_POS.x,
        y          = NPC_POS.y,
        z          = NPC_POS.z,
        rotation   = NPC_POS.rot,
        widescan   = 1,

        onTrade = function(player, npc, trade)
            player:printToPlayer(
                PREFIX .. ' No trades -- choose an Aeonic weapon from the menu.',
                xi.msg.channel.SYSTEM_3)
        end,

        onTrigger = function(player, npc)
            if (player:getCharVar('WF_Aeonic_Final') or 0) ~= 1 then
                player:printToPlayer(
                    PREFIX .. ' Walk the full Aeonic path at the Weapon Forger before I will reforge another weapon for you.',
                    xi.msg.channel.SYSTEM_3)
                return
            end

            player:printToPlayer(string.format(
                PREFIX .. ' Repeat Aeonic weapons cost %s each.', costStr()),
                xi.msg.channel.SYSTEM_3)
            showWeapons(player, 1)
        end,
    })
    utils.unused(AeonicForge)
end)

return m
