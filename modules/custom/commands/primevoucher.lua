-----------------------------------
-- func: primevoucher
-- desc: [GM] Grant Prime Voucher(s) (item 29699) to a player. They trade one
--       at the Prime Armory NPC in GM Home to claim a Prime weapon of their
--       choice. The voucher is EX (bound), so a GM cannot trade it over by
--       hand -- this command is how you grant it.
--
-- Usage:  !primevoucher <player> [count]   -- give to a named online player
--         !primevoucher                    -- give one to yourself
-----------------------------------
local VOUCHER = 29699

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,   -- GM only
    parameters = 'si',
}

commandObj.onTrigger = function(player, name, count)
    count = tonumber(count) or 1
    if count < 1  then count = 1  end
    if count > 12 then count = 12 end

    -- Resolve the recipient: a named online player, or the GM if no name given.
    local target = player
    if name ~= nil then
        target = GetPlayerByName(name)
        if target == nil then
            player:printToPlayer(string.format('Prime Voucher: player "%s" not found or not online.', tostring(name)), xi.msg.channel.SYSTEM_3)
            return
        end
    end

    if target:getFreeSlotsCount() == 0 then
        player:printToPlayer(string.format('Prime Voucher: %s has no free inventory slot.', target:getName()), xi.msg.channel.SYSTEM_3)
        return
    end

    target:addItem({ id = VOUCHER, quantity = count })
    target:printToPlayer(string.format('You received %d Prime Voucher(s)! Visit the Prime Armory in GM Home and trade one to claim a Prime weapon.', count), xi.msg.channel.SYSTEM_3)

    if target:getID() ~= player:getID() then
        player:printToPlayer(string.format('Gave %d Prime Voucher(s) to %s.', count, target:getName()), xi.msg.channel.SYSTEM_3)
    end
end

return commandObj
