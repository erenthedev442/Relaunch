-----------------------------------
-- Empyrean repeat forge
--
-- Completing one Empyrean through the full Weapon Forge path unlocks direct
-- repeat forging of final Empyrean equipment and Marsyas for Boulders only.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Abdhaljs_Isle-Purgonorgo/Zone')

local m        = Module:new('empyrean_forge')
local catalog  = require('modules/custom/lua/empyrean_forge_catalog')
local currency = require('modules/custom/lua/hl_seal_currency')

local NPC_POS   = { x = 603.6885, y = -3.2039, z = 487.9435, rot = 144 }
local PAGE_SIZE = 4

local function costStr()
    return string.format('%d %ss', catalog.cost, catalog.currencyName)
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
        if (player:getCharVar('WF_Empyrean_Final') or 0) ~= 1 then
            player:printToPlayer(
                '[Empyrean Forge] Complete one Empyrean to 119 III through the full Weapon Forge path first, kupo!',
                xi.msg.channel.SYSTEM_3)
            return
        end

        if player:getFreeSlotsCount() == 0 then
            player:printToPlayer('[Empyrean Forge] Free an inventory slot first, kupo!', xi.msg.channel.SYSTEM_3)
            return
        end

        if player:hasItem(weapon.id) then
            player:printToPlayer(string.format(
                '[Empyrean Forge] You already hold %s -- it is RARE, so a second cannot be forged, kupo!',
                weapon.name), xi.msg.channel.SYSTEM_3)
            return
        end

        local held = player:getItemCount(catalog.currencyId)
        if held < catalog.cost then
            player:printToPlayer(string.format(
                '[Empyrean Forge] Need %s (you have %d). Kupo!', costStr(), held),
                xi.msg.channel.SYSTEM_3)
            return
        end

        if not currency.take(player, catalog.currencyId, catalog.cost) then
            player:printToPlayer(
                '[Empyrean Forge] I could not gather the full Boulder payment, so nothing was forged, kupo!',
                xi.msg.channel.SYSTEM_3)
            return
        end

        if not player:addItem({ id = weapon.id, quantity = 1 }) then
            refundCurrency(player)
            player:printToPlayer(
                '[Empyrean Forge] The forging failed -- your Boulders have been returned, kupo!',
                xi.msg.channel.SYSTEM_3)
            return
        end

        player:printToPlayer(string.format(
            '[Empyrean Forge] %s has been forged anew! Kupo!', weapon.name),
            xi.msg.channel.SYSTEM_3)
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
        sendMenu(player, string.format('Empyrean Forge (%d/%d)', page, totalPages), options)
    end

    local EmpyreanForge = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Empyrean_Forge',
        packetName = string.format('%sEmpyrean Forge', xi.icon.STAR_LARGE),
        look       = 171,
        x          = NPC_POS.x,
        y          = NPC_POS.y,
        z          = NPC_POS.z,
        rotation   = NPC_POS.rot,
        widescan   = 1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('[Empyrean Forge] No trades -- choose a weapon from the menu, kupo!', xi.msg.channel.SYSTEM_3)
        end,

        onTrigger = function(player, npc)
            if (player:getCharVar('WF_Empyrean_Final') or 0) ~= 1 then
                player:printToPlayer(
                    '[Empyrean Forge] Complete one Empyrean to 119 III through the full Weapon Forge path to unlock repeat forging, kupo!',
                    xi.msg.channel.SYSTEM_3)
                return
            end

            player:printToPlayer(string.format(
                '[Empyrean Forge] Repeat equipment costs %s each, kupo!', costStr()),
                xi.msg.channel.SYSTEM_3)
            showWeapons(player, 1)
        end,
    })
    utils.unused(EmpyreanForge)
end)

return m
