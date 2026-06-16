---@type TCommand
-- Wraps scripts/commands/shop to make !shop augments read the catalog fresh
-- on every call. Module files hot-reload; scripts/commands/ files do not.
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 'ss',
}

local origShop  = require('scripts/commands/shop')
local itemNames = require('modules/custom/lua/augment_item_names')

local augmentGroups =
{
    [1]  = { 'str',    'STR / Attack / Phys.Dmg' },
    [2]  = { 'dex',    'DEX / Accuracy / Crit'   },
    [3]  = { 'vit',    'VIT / Defense'           },
    [4]  = { 'agi',    'AGI / Evasion / Haste'   },
    [5]  = { 'int',    'INT / Magic Offense'     },
    [6]  = { 'mnd',    'MND / Healing'           },
    [7]  = { 'chr',    'CHR / Charm / Enmity'    },
    [8]  = { 'hp',     'HP / Regen'              },
    [9]  = { 'mp',     'MP / Refresh'            },
    [10] = { 'pet',    'Pet'                     },
    [11] = { 'resist', 'Resist / Affinity'       },
    [12] = { 'skill',  'Skill+'                  },
    [13] = { 'ws',     'Weaponskill DMG'         },
}
local POINT_AUGMENTS    = { [2523] = true, [942] = true }
local POINT_TOKEN       = 'points'
local POINT_NAME        = 'EXP / Capacity Points'
local AUGMENT_PRICE     = 100000
local AUGMENT_PRICE_STR = '100,000'

local function buildAugmentStock()
    package.loaded['modules/custom/lua/augment_catalog'] = nil
    local ok, catalog = pcall(require, 'modules/custom/lua/augment_catalog')
    if not ok or type(catalog) ~= 'table' then
        return {}, {}
    end

    local byToken = {}
    for itemId, def in pairs(catalog) do
        if type(def) == 'table' and def.cat then
            local token
            if POINT_AUGMENTS[itemId] then
                token = POINT_TOKEN
            else
                local grp = augmentGroups[def.cat]
                token = grp and grp[1] or 'other'
            end
            byToken[token] = byToken[token] or {}
            table.insert(byToken[token], itemId)
        end
    end

    local stock = {}
    local order = {}

    local function finalize(token, name)
        local ids = byToken[token]
        if ids and #ids > 0 then
            table.sort(ids, function(a, b)
                local la = itemNames[a] or (catalog[a] and catalog[a].label) or ''
                local lb = itemNames[b] or (catalog[b] and catalog[b].label) or ''
                return la < lb
            end)
            local list = {}
            for _, itemId in ipairs(ids) do
                list[#list + 1] = { itemId, AUGMENT_PRICE }
            end
            stock[token]             = list
            order[#order + 1]        = { token, name, #list }
        end
    end

    for cat = 1, 13 do
        finalize(augmentGroups[cat][1], augmentGroups[cat][2])
    end
    finalize(POINT_TOKEN, POINT_NAME)
    finalize('other', 'Other')

    return stock, order
end

commandObj.onTrigger = function(player, category, subcat)
    local cat = category and category:lower() or 'general'

    if cat ~= 'augments' then
        return origShop.onTrigger(player, category, subcat)
    end

    local augmentStock, augmentOrder = buildAugmentStock()

    if #augmentOrder == 0 then
        player:printToPlayer('The augment catalyst shop is unavailable (catalog failed to load).')
        return
    end

    if subcat == nil or subcat == '' then
        player:printToPlayer(string.format('Augment catalysts -- %s gil each. Choose a group with  !shop augments <group>', AUGMENT_PRICE_STR), xi.msg.channel.SYSTEM_3)
        for _, g in ipairs(augmentOrder) do
            player:printToPlayer(string.format('  augments %-7s  %s (%d)', g[1], g[2], g[3]), xi.msg.channel.SYSTEM_3)
        end
        return
    end

    local sub  = subcat:lower()
    local list = augmentStock[sub]
    if not list then
        local toks = {}
        for _, g in ipairs(augmentOrder) do
            toks[#toks + 1] = g[1]
        end
        player:printToPlayer(string.format('Unknown augment group "%s". Valid groups: %s', sub, table.concat(toks, ', ')), xi.msg.channel.SYSTEM_3)
        return
    end

    player:printToPlayer(string.format('Augment catalysts -- %s gil each. Trade purchases to the Augment Moogle at GM Home to apply.', AUGMENT_PRICE_STR), xi.msg.channel.SYSTEM_3)
    xi.shop.general(player, list)
end

return commandObj
