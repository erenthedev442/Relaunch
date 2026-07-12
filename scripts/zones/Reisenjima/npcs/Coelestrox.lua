-----------------------------------
-- Area: Reisenjima (291)
-- NPC: Coelestrox (Omen rewards)
-- !pos -360.00 -440.00 -800.00 291
--
-- Services (retail: https://www.bg-wiki.com/ffxi/Coelestrox):
--   * Converts 5 paragon cards of one job into 1 card of another.
--
-- Relaunch deviation (owner, 2026-07-12): Coelestrox does NOT reforge
-- Artifact armor here -- AF +1/+2/+3 lives in the Reforge System and +4 at
-- the Dynamis-Divergence Forge. Retail's AF reforge service was removed to
-- keep a single source per upgrade path.
-----------------------------------
local catalog = require('modules/custom/lua/omen_catalog')

---@type TNpcEntity
local entity = {}

local JOB_NAMES =
{
    'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG',
    'SAM', 'NIN', 'DRG', 'SMN', 'BLU', 'COR', 'PUP', 'DNC', 'SCH', 'GEO', 'RUN',
}

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
            { 'Never mind', function() end },
        },
    })
end

-----------------------------------
-- Trade: no services take items -- point reforgers at the right systems.
-----------------------------------
entity.onTrade = function(player, npc, trade)
    player:printToPlayer("[Coelestrox] I no longer work armor. Artifact reforges are done at the Reforge hub (!reforged); the +4 tier at the Divergence Forge in San d'Oria.", xi.msg.channel.SYSTEM_3)
end

entity.onEventUpdate = function(player, csid, option, npc)
end

entity.onEventFinish = function(player, csid, option, npc)
end

return entity
