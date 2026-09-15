-----------------------------------
-- Mythic Forge final-form catalog
-----------------------------------

local weaponForge = require('modules/custom/lua/weapon_forge_catalog')

local C =
{
    currencyId   = weaponForge.forgeMats.beitetsu,
    currencyName = 'Beitetsu',
    cost         = 5000,
    weapons      = {},
}

-- Quelling Bolt Quiver (26346). The crossbow is no longer an ammo enchantment.
C.companionsByItem =
{
    [21266] = { 26346 }, -- Gastraphetes 119 III
    [22139] = { 26346 }, -- Gastraphetes 119 III (no quiver)
}

for _, chain in ipairs(weaponForge.mythicChains) do
    local companions = C.companionsByItem[chain.s3] or {}
    local info = string.format('%s mythic weapon. Jobs: %s.', chain.type, chain.jobs)
    if chain.name == 'Gastraphetes' then
        info = info .. " Forging also grants Quelling Bolt Quiver."
    end

    C.weapons[#C.weapons + 1] =
    {
        id         = chain.s3,
        name       = chain.name,
        info       = info,
        companions = companions,
    }
end

function C.companionsFor(itemId)
    return C.companionsByItem[itemId] or {}
end

function C.companionSlotNeed(player, itemId)
    local need = 0
    for _, extraId in ipairs(C.companionsFor(itemId)) do
        if player:getItemCount(extraId) < 1 then
            need = need + 1
        end
    end

    return need
end

function C.grantCompanions(player, itemId, channelTag)
    local granted = 0
    for _, extraId in ipairs(C.companionsFor(itemId)) do
        if player:getItemCount(extraId) < 1 then
            if not player:addItem({ id = extraId, quantity = 1 }) then
                player:printToPlayer(
                    string.format('[%s] Free a slot for the companion item and talk to me again.', channelTag),
                    xi.msg.channel.SYSTEM_3)
                return granted, false
            end

            granted = granted + 1
            if extraId == 26346 then
                player:printToPlayer(
                    string.format('[%s] Quelling Bolt Quiver is included -- use it for Quelling Bolts.', channelTag),
                    xi.msg.channel.SYSTEM_3)
            end
        end
    end

    return granted, true
end

return C
