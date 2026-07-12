-----------------------------------
-- Area: Reisenjima (291)
-- NPC: Coelestrox (Omen rewards)
-- !pos -360.00 -440.00 -800.00 291
--
-- Services (retail: https://www.bg-wiki.com/ffxi/Coelestrox):
--   * Converts 5 paragon cards of one job into 1 card of another.
--   * Reforges Artifact armor +1 -> +2 -> +3.
--
-- Reforge recipes (trade the armor with its components):
--   +1 -> +2 : AF+1 piece + paragon cards of that job
--              (head 4 / body 5 / hands 3 / legs 4 / feet 3)
--              + 10 Escha Beads (deducted automatically)
--   +2 -> +3 : AF+2 piece + 1 paragon card + the job's boss scale
--              + 500 Escha Beads
--
-- Relaunch deviations from retail: reforges complete instantly (no
-- game-day wait) and the +3 step's second-day crafted materials are
-- waived; fees use the retail "cheap" tier, paid in Escha Beads.
-----------------------------------
local catalog = require('modules/custom/lua/omen_catalog')

---@type TNpcEntity
local entity = {}

-- Artifact reforge item-id arithmetic: id = base + jobId (WAR=1 .. RUN=22).
-- Bases verified against item_basic.sql (e.g. pummelers_mask_+2 = 23040).
local SLOTS = { 'head', 'body', 'hands', 'legs', 'feet' }

local AF_BASE =
{
    plusOne   = { head = 27683, body = 27827, hands = 27963, legs = 28110, feet = 28243 },
    plusTwo   = { head = 23039, body = 23106, hands = 23173, legs = 23240, feet = 23307 },
    plusThree = { head = 23374, body = 23441, hands = 23508, legs = 23575, feet = 23642 },
}

local JOB_NAMES =
{
    'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG',
    'SAM', 'NIN', 'DRG', 'SMN', 'BLU', 'COR', 'PUP', 'DNC', 'SCH', 'GEO', 'RUN',
}

-- Returns slot, jobId for an item id found in one of the given bases.
local function classifyArmor(itemId, bases)
    for _, slot in ipairs(SLOTS) do
        local diff = itemId - bases[slot]
        if diff >= 1 and diff <= 22 then
            return slot, diff
        end
    end

    return nil, nil
end

-----------------------------------
-- Card conversion (5:1)
-----------------------------------
local function convertCards(player, fromJob, toJob)
    local fromCard = catalog.cardForJob(fromJob)
    local toCard   = catalog.cardForJob(toJob)
    local needed   = catalog.cardConversionRate

    if player:getItemCount(fromCard) < needed then
        player:printToPlayer(string.format('[Coelestrox] You need %d %s cards for that.', needed, JOB_NAMES[fromJob]), xi.msg.channel.SYSTEM_3)
        return
    end

    if player:getFreeSlotsCount() < 1 then
        player:printToPlayer('[Coelestrox] Make room in your bags first.', xi.msg.channel.SYSTEM_3)
        return
    end

    for _ = 1, needed do
        player:delItem(fromCard, 1)
    end

    player:addItem(toCard)
    player:printToPlayer(string.format('[Coelestrox] %d %s cards became 1 %s card. A fine trade.', needed, JOB_NAMES[fromJob], JOB_NAMES[toJob]), xi.msg.channel.SYSTEM_3)
end

local function pickJobMenu(player, title, page, onPick)
    local perPage   = 6
    local pageCount = math.ceil(#JOB_NAMES / perPage)
    local current   = math.min(math.max(page or 1, 1), pageCount)
    local options   = {}

    for index = (current - 1) * perPage + 1, math.min(current * perPage, #JOB_NAMES) do
        local jobId = index
        table.insert(options, {
            JOB_NAMES[index],
            function(p)
                onPick(p, jobId)
            end,
        })
    end

    if current < pageCount then
        table.insert(options, {
            'Next >>',
            function(p)
                pickJobMenu(p, title, current + 1, onPick)
            end,
        })
    end

    table.insert(options, { 'Never mind', function() end })

    player:timer(30, function(p)
        p:customMenu({
            title   = string.format('%s (%d/%d)', title, current, pageCount),
            options = options,
        })
    end)
end

-----------------------------------
-- Trigger: menu
-----------------------------------
entity.onTrigger = function(player, npc)
    player:customMenu({
        title   = 'Coelestrox',
        options =
        {
            {
                'Convert paragon cards (5:1)',
                function(p)
                    pickJobMenu(p, 'Cards to trade in', 1, function(p2, fromJob)
                        pickJobMenu(p2, 'Card to receive', 1, function(p3, toJob)
                            convertCards(p3, fromJob, toJob)
                        end)
                    end)
                end,
            },
            {
                'How does reforging work?',
                function(p)
                    p:printToPlayer('[Coelestrox] Trade me an Artifact piece with its components and I shall reforge it on the spot:', xi.msg.channel.SYSTEM_3)
                    p:printToPlayer('[Coelestrox]   +1 piece with its job\'s paragon cards (head 4 / body 5 / hands 3 / legs 4 / feet 3) and 10 Escha Beads -> +2.', xi.msg.channel.SYSTEM_3)
                    p:printToPlayer('[Coelestrox]   +2 piece with 1 paragon card and the job\'s Caturae scale and 500 Escha Beads -> +3.', xi.msg.channel.SYSTEM_3)
                    p:printToPlayer(string.format('[Coelestrox] You carry %d Escha Beads.', p:getCurrency('escha_beads')), xi.msg.channel.SYSTEM_3)
                end,
            },
            { 'Never mind', function() end },
        },
    })
end

-----------------------------------
-- Trade: reforging
-----------------------------------
entity.onTrade = function(player, npc, trade)
    -- Identify the armor piece among the traded items.
    local armorId, slot, jobId, tier

    for slotIndex = 0, trade:getSlotCount() - 1 do
        local itemId = trade:getItemId(slotIndex)
        if itemId and itemId > 0 then
            local s, j = classifyArmor(itemId, AF_BASE.plusOne)
            if s then
                armorId, slot, jobId, tier = itemId, s, j, 'plusOne'
                break
            end

            s, j = classifyArmor(itemId, AF_BASE.plusTwo)
            if s then
                armorId, slot, jobId, tier = itemId, s, j, 'plusTwo'
                break
            end
        end
    end

    if not armorId then
        player:printToPlayer('[Coelestrox] I only work Artifact armor (+1 or +2), with its components alongside.', xi.msg.channel.SYSTEM_3)
        return
    end

    local cardId = catalog.cardForJob(jobId)

    if tier == 'plusOne' then
        local cardsNeeded = catalog.cardsForSlot[slot]
        local fee         = catalog.reforgeFees.plusTwo

        if not npcUtil.tradeHasExactly(trade, { armorId, { cardId, cardsNeeded } }) then
            player:printToPlayer(string.format('[Coelestrox] For that %s piece I need it traded with exactly %d %s paragon cards.',
                slot, cardsNeeded, JOB_NAMES[jobId]), xi.msg.channel.SYSTEM_3)
            return
        end

        if player:getCurrency('escha_beads') < fee then
            player:printToPlayer(string.format('[Coelestrox] My fee is %d Escha Beads. You are short.', fee), xi.msg.channel.SYSTEM_3)
            return
        end

        player:setCurrency('escha_beads', player:getCurrency('escha_beads') - fee)
        player:tradeComplete()
        player:addItem(AF_BASE.plusTwo[slot] + jobId)
        player:printToPlayer('[Coelestrox] Reforged to +2! Wear it proudly.', xi.msg.channel.SYSTEM_3)
    else
        local scaleKey = catalog.scaleForJob[jobId]
        local scaleId  = scaleKey and catalog.items.scales[scaleKey]
        local fee      = catalog.reforgeFees.plusThree

        if not scaleId then
            player:printToPlayer('[Coelestrox] Curious... I have no scale on record for that job.', xi.msg.channel.SYSTEM_3)
            return
        end

        if not npcUtil.tradeHasExactly(trade, { armorId, cardId, scaleId }) then
            player:printToPlayer(string.format('[Coelestrox] For that piece I need it traded with exactly 1 %s paragon card and 1 %s.',
                JOB_NAMES[jobId], string.gsub(scaleKey, '^%l', string.upper) .. '\'s scale'), xi.msg.channel.SYSTEM_3)
            return
        end

        if player:getCurrency('escha_beads') < fee then
            player:printToPlayer(string.format('[Coelestrox] My fee is %d Escha Beads. You are short.', fee), xi.msg.channel.SYSTEM_3)
            return
        end

        player:setCurrency('escha_beads', player:getCurrency('escha_beads') - fee)
        player:tradeComplete()
        player:addItem(AF_BASE.plusThree[slot] + jobId)
        player:printToPlayer('[Coelestrox] Reforged to +3 -- my finest work! May it serve you in the trials ahead.', xi.msg.channel.SYSTEM_3)
    end
end

entity.onEventUpdate = function(player, csid, option, npc)
end

entity.onEventFinish = function(player, csid, option, npc)
end

return entity
