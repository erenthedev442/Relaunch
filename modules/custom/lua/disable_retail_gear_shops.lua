-----------------------------------
-- disable_retail_gear_shops.lua
--
-- Strip weapons/armor from retail gil shops (xi.shop.general and callers:
-- nation, outpost, celebratory, regional, Valeriano). That includes Antonia
-- in Upper Jeuno (i119 Arasy / Yoshikiri / Ashijiro / Animator Z).
--
-- Also blocks retail *event* vendors that sell gear for sparks, cruor,
-- dominion notes, assault points, therion ichor, or ancient beastcoins.
--
-- Left alone (legendary paths): !shop ([ShopAllowGear]), Welcome Moogle,
-- hunt-medal Armor/Accessory/Gear Progression NPCs, Infamy, Domain
-- Quartermaster, Cosmetic Shop, and the Relic/Mythic/Empy/Abjuration forges.
-- Ammunition, medicines, scrolls, keys, and crafting materials stay.
--
-- Takes effect on the next map restart.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/shop')
require('scripts/globals/abyssea')

local m = Module:new('disable_retail_gear_shops')

local SYS = xi.msg.channel.SYSTEM_3
local ALLOW_VAR = '[ShopAllowGear]'
local MSG = '[Shop] Equipment is not sold here.'

local function stripGear(stock)
    local filtered = {}
    for _, row in ipairs(stock or {}) do
        if not xi.shop.isEquipment(row[1]) then
            table.insert(filtered, row)
        end
    end

    return filtered
end

local function openOrRefuse(player, stock, opener)
    if player:getLocalVar(ALLOW_VAR) == 1 then
        return opener(stock)
    end

    local filtered = stripGear(stock)
    if #filtered == 0 then
        player:printToPlayer(MSG, SYS)
        return
    end

    return opener(filtered)
end

local function refuseGear(player)
    player:printToPlayer(MSG, SYS)
end

m:addOverride('xi.shop.general', function(player, stock, log)
    return openOrRefuse(player, stock, function(filtered)
        return super(player, filtered, log)
    end)
end)

m:addOverride('xi.shop.generalGuild', function(player, stock, guildSkillId)
    return openOrRefuse(player, stock, function(filtered)
        return super(player, filtered, guildSkillId)
    end)
end)

m:addOverride('xi.shop.curioVendorMoogle', function(player, stock)
    return openOrRefuse(player, stock, function(filtered)
        return super(player, filtered)
    end)
end)

-- Cruor Prospectors that use the shared Visions finish (Tahrongi / La Theine /
-- Konschtat / Empyreal Paradox). Local-finish zones are patched in their NPC
-- scripts to call xi.shop.blockEquipmentPurchase.
local origCruorFinish = xi.abyssea.visionsCruorProspectorOnEventFinish
xi.abyssea.visionsCruorProspectorOnEventFinish = function(player, csid, option, prospectorItems)
    local itemCategory = bit.band(option, 0x07)
    local itemSelected = bit.band(bit.rshift(option, 16), 0x1F)
    if itemCategory == xi.abyssea.itemType.ITEM then
        local itemData = prospectorItems and prospectorItems[itemCategory] and prospectorItems[itemCategory][itemSelected]
        if itemData and xi.shop.blockEquipmentPurchase(player, itemData[1]) then
            return
        end
    end

    return origCruorFinish(player, csid, option, prospectorItems)
end

-- Assault mission NPCs: slots 1-11 are gear, 12-13 are trust ciphers.
local assaultShopNpcs =
{
    'Yahsra',
    'Bhoy_Yhupplo',
    'Famad',
    'Lageegee',
    'Isdebaaq',
}

for _, npcName in ipairs(assaultShopNpcs) do
    m:addOverride('xi.zones.Aht_Urhgan_Whitegate.npcs.' .. npcName .. '.onEventFinish', function(player, csid, option, npc)
        local selectiontype = bit.band(option, 0xF)
        local item = bit.rshift(option, 14)
        if selectiontype == 2 and item >= 1 and item <= 11 then
            refuseGear(player)
            return
        end

        return super(player, csid, option, npc)
    end)
end

-- Einherjar ichor shop: 1-21 are gear, 22-24 are Valkyrie key items.
m:addOverride('xi.zones.Nashmau.npcs.Kilusha.onEventFinish', function(player, csid, option, npc)
    if csid == 24 and option >= 1 and option <= 21 then
        refuseGear(player)
        return
    end

    return super(player, csid, option, npc)
end)

-- Dominion Tactician: category 1 slots 1-9 are AF, 10-11 are shades;
-- category 3 is augmented weapons.
m:addOverride('xi.zones.Abyssea-Grauberg.npcs.Dominion_Tactician.onEventFinish', function(player, csid, option, npc)
    local itemCategory = bit.band(option, 0xF)
    local itemSelected = bit.rshift(option, 8)
    if itemCategory == 3 or (itemCategory == 1 and itemSelected >= 1 and itemSelected <= 9) then
        refuseGear(player)
        return
    end

    return super(player, csid, option, npc)
end)

-- Sagheera ABC shop: options 11-19 are accessories, 20 is a metal chip.
m:addOverride('xi.zones.Port_Jeuno.npcs.Sagheera.onEventFinish', function(player, csid, option, npc)
    local opt = bit.band(option, 65535)
    if csid == 310 and opt >= 11 and opt <= 19 then
        refuseGear(player)
        return
    end

    return super(player, csid, option, npc)
end)

return m
