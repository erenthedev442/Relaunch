-----------------------------------
-- prime_voucher_reward.lua
--
-- Reusable helper for awarding a Prime Voucher (item 29699) as an EARNED
-- reward from any source -- a Hunting League NM drop, a weekly board payout,
-- a boss kill, a treasure dig, etc. Centralizes the inventory-space check and
-- the player messaging so every source behaves identically. The granted
-- voucher is redeemed at the Prime Armory NPC (GM Home) for a Prime weapon.
--
-- SOURCE (live): a 1% drop from any Hunting League NM -- the call sits in
-- HuntingLeague.lua's NM onMobDeath. Add MORE sources by calling award() from
-- their reward code; examples:
--
--   local primeVoucher = require('modules/custom/lua/prime_voucher_reward')
--
--   -- Rare drop (e.g. in a Hunting League NM's onMobDeath):
--   if math.random(100) <= 2 then           -- 2% chance, tune to taste
--       primeVoucher.award(killer, 1, 'NM drop')
--   end
--
--   -- Guaranteed reward (e.g. on weekly Hunt Board completion):
--   primeVoucher.award(player, 1, 'weekly board')
--
-- Granting is also available to GMs directly via the !primevoucher command.
-----------------------------------
local M = {}

local VOUCHER = 29699

-----------------------------------
-- Award `count` Prime Voucher(s) to `player`. `reason` is an optional short
-- label shown in the player's message (e.g. 'NM drop'). Returns true if
-- granted; false if the player's inventory was full (the caller decides
-- whether to retry -- a drop is simply missed, so players should keep space).
-----------------------------------
function M.award(player, count, reason)
    count = count or 1
    if player == nil then
        return false
    end

    if player:getFreeSlotsCount() == 0 then
        player:printToPlayer('Your inventory is full -- a Prime Voucher reward could not be granted. Free a slot, kupo!', xi.msg.channel.SYSTEM_3)
        return false
    end

    player:addItem({ id = VOUCHER, quantity = count })

    local tag = reason and (' (' .. reason .. ')') or ''
    player:printToPlayer(
        string.format('You earned %d Prime Voucher%s%s! Turn one in at the Prime Armory in GM Home for Prime Weapon Trial 3.',
            count, count == 1 and '' or 's', tag),
        xi.msg.channel.SYSTEM_3)

    return true
end

return M
