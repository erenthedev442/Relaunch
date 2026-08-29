-----------------------------------
-- Spark Shop
-- TO DO: Add Naakaul Seven Treasures
-----------------------------------
require('scripts/globals/npc_util')
require('scripts/globals/extravaganza')
-----------------------------------
xi = xi or {}
xi.sparkshop = xi.sparkshop or {}

local optionToItem =
{
    [1] = -- Items page
    {
        [ 0] = { cost =    10, id =  4181 }, -- Scroll of Instant Warp
        [ 1] = { cost =    10, id =  4182 }, -- Scroll of Instant Reraise
        [ 2] = { cost =  7500, id =  4064 }, -- Copy of Rem's Tale, chapter 1
        [ 3] = { cost =  7500, id =  4065 }, -- Copy of Rem's Tale, chapter 2
        [ 4] = { cost =  7500, id =  4066 }, -- Copy of Rem's Tale, chapter 3
        [ 5] = { cost =  7500, id =  4067 }, -- Copy of Rem's Tale, chapter 4
        [ 6] = { cost =  7500, id =  4068 }, -- Copy of Rem's Tale, chapter 5
        [ 7] = { cost = 15000, id =  4069 }, -- Copy of Rem's Tale, chapter 6
        [ 8] = { cost = 15000, id =  4070 }, -- Copy of Rem's Tale, chapter 7
        [ 9] = { cost = 15000, id =  4071 }, -- Copy of Rem's Tale, chapter 8
        [10] = { cost = 15000, id =  4072 }, -- Copy of Rem's Tale, chapter 9
        [11] = { cost = 15000, id =  4073 }, -- Copy of Rem's Tale, chapter 10
        [13] = { cost = 10000, id =  9009 }, -- Etched Memory
    },

    -- [2] Skill-increasing tomes: removed (Relaunch).
    [2] = {},

    -- [3]-[6] Equipment Lv.1-39: removed (Relaunch). Purchase is also refused
    -- in onEventUpdate for categories 3-10.
    [3] = {},
    [4] = {},
    [5] = {},
    [6] = {},


    -- [7]-[10] Equipment Lv.40+: removed (Relaunch).
    [7] = {},
    [8] = {},
    [9] = {},
    [10] = {},
    [12] = -- Alter Ego Extravaganza Trusts
    {
        [10133] = { cost =  500, id = xi.item.CIPHER_OF_F_COFFINS_ALTER_EGO }, -- F. Coffin
        [10138] = { cost =  500, id = xi.item.CIPHER_OF_CIDS_ALTER_EGO }, -- Cid
        [10148] = { cost =  500, id = xi.item.CIPHER_OF_GILGAMESHS_ALTER_EGO }, -- Gilgamesh
        [10152] = { cost =  500, id = xi.item.CIPHER_OF_QULTADAS_ALTER_EGO }, -- Qultada
        [10181] = { cost =  500, id = xi.item.CIPHER_OF_KINGS_ALTER_EGO }, -- King
    },

    -- [20]/[30] A.M.A.N. voucher exchange: removed (Relaunch).
    [20] = {},

}

function xi.sparkshop.onTrade(player, npc, trade, eventid)
    -- A.M.A.N. voucher deposit / exchange removed (Relaunch).
    if trade:getItemQty(xi.item.COPPER_AMAN_VOUCHER) > 0 then
        player:printToPlayer(
            '[Sparks] A.M.A.N. voucher exchange is no longer available here.',
            xi.msg.channel.SYSTEM_3)
    end
end

function xi.sparkshop.onTrigger(player, npc, event)
    local sparks = player:getCurrency('spark_of_eminence')
    local remainingLimit = xi.settings.main.WEEKLY_EXCHANGE_LIMIT - player:getCharVar('weekly_sparks_spent')
    local cipher = xi.extravaganza.campaignActive() * 16 * 65536 -- Trust Alter Ego Extravaganza
    local naakual = 0 -- TODO: Naakual Seven Treasures Item Logic

    -- vouchers param forced to 0 so the A.M.A.N. exchange branch stays inert.
    player:startEvent(event, 0, sparks, 0, naakual, cipher, remainingLimit)
end

function xi.sparkshop.onEventUpdate(player, csid, option, npc)
    local sparks = player:getCurrency('spark_of_eminence')
    local weeklySparksSpent = player:getCharVar('weekly_sparks_spent')
    local remainingLimit = xi.settings.main.WEEKLY_EXCHANGE_LIMIT - weeklySparksSpent
    local category = bit.band(option, 0xFF)
    local selection = bit.rshift(option, 16)

    -- Relaunch: no skill tomes (2), equipment (3-10), or A.M.A.N. voucher
    -- currency/provisions (20/30). Only non-equipment Items and Trusts remain.
    if category == 2 then
        player:updateEvent(sparks, 0, 0, 0, 0, remainingLimit)
        player:printToPlayer('[Sparks] Skill-increasing tomes are no longer sold here.', xi.msg.channel.SYSTEM_3)
        return
    end

    if category >= 3 and category <= 10 then
        player:updateEvent(sparks, 0, 0, 0, 0, remainingLimit)
        player:printToPlayer('[Sparks] Equipment is no longer sold here.', xi.msg.channel.SYSTEM_3)
        return
    end

    if category == 20 or category == 30 then
        player:updateEvent(sparks, 0, 0, 0, 0, remainingLimit)
        player:printToPlayer('[Sparks] A.M.A.N. voucher exchange is no longer available here.', xi.msg.channel.SYSTEM_3)
        return
    end

    local qty = 1
    local requestedQty = bit.band(bit.rshift(option, 10), 0x3F)

    -- qty > 1 only for remaining multi-buy categories (none currently; kept for ammo specials)
    if category == 2 or category == 20 or category == 30 then
        qty = requestedQty
    end

    -- Sparks item purchases (non-equipment Items and Trust ciphers).
    if category == 1 or category == 12 then
        local itemCategory = optionToItem[category]
        local item         = itemCategory and itemCategory[selection]

        if not item then
            -- No catalog entry for this menu slot. Refresh the menu instead of
            -- returning silently: a bare return sends NO updateEvent, so the
            -- client locks forever waiting for a reply (the Rolandienne freeze).
            player:updateEvent(sparks, 0, 0, 0, 0, remainingLimit)
            return
        end

        local cost = item.cost * qty

        -- handles eminent ammo (catalog emptied for Lv.99, kept for safety)
        local emminentAmmoCosts = { [21302] = 5000, [21316] = 5000, [21331] = 5000, [21355] = 7000 }
        local ammoCost = emminentAmmoCosts[item.id]
        if ammoCost then
            qty  = 99
            cost = ammoCost
        end

        -- verifies and finishes transaction
        if cost > remainingLimit and xi.settings.main.ENABLE_EXCHANGE_LIMIT == 1 then
            player:messageSpecial(zones[player:getZoneID()].text.MAX_SPARKS_LIMIT_REACHED, xi.settings.main.WEEKLY_EXCHANGE_LIMIT)
        elseif sparks >= cost then
            if npcUtil.giveItem(player, { { item.id, qty } }) then
                sparks = sparks - cost
                player:delCurrency('spark_of_eminence', cost)
                if xi.settings.main.ENABLE_EXCHANGE_LIMIT == 1 then
                    remainingLimit = remainingLimit - cost
                    player:setCharVar('weekly_sparks_spent', weeklySparksSpent + cost)
                end
            end
        else
            player:messageSpecial(zones[player:getZoneID()].text.NOT_ENOUGH_SPARKS)
        end

        player:updateEvent(sparks, 0, 0, 0, 0, remainingLimit)
    else
        -- Any category the handler doesn't recognize still gets a menu refresh,
        -- so the client can never wedge waiting for a reply that never comes.
        player:updateEvent(sparks, 0, 0, 0, 0, remainingLimit)
    end
end

function xi.sparkshop.onEventFinish(player, csid, option, npc)
end
