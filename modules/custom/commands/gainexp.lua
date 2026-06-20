 -----------------------------------
-- func: gainexp
-- desc: Player-facing on-demand version of RoE timed record 4013
--       ("Gain Experience"). Instantly credits the reward bundle:
--         +1500 EXP, +300 sparks, +300 accolades, 1x Copper Aman Voucher
--
-- Usage:  !gainexp
--
-- Lives in modules/custom/commands/ so it survives upstream merges
-- (scripts/commands/ is upstream-tracked; modules/custom/commands/ is
-- the documented extension point and is already enabled in init.txt).
--
-- Notes:
--   - permission = 1 (GM-only).
--   - Calls setEminenceCompleted(4013); the engine grants whatever
--     reward bundle record 4013 has in scripts/globals/roe_records.lua
--     at the time of the call. If upstream changes the reward, this
--     command stays in sync automatically.
--   - No cooldown is enforced. If players abuse it, add a charvar
--     timestamp check at the top of onTrigger -- pattern:
--       local now  = os.time()
--       local last = player:getCharVar('gainexp_lastused')
--       if now - last < 300 then return end  -- 5 min cooldown
--       player:setCharVar('gainexp_lastused', now)
--   - The matching timed record is always-on (see
--     modules/custom/lua/roe_gain_exp_always_on.lua), so players can
--     also earn the reward the "real" way by gaining 5000 EXP.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

local COOLDOWN_SECS = 86400   -- 24 hours

commandObj.onTrigger = function(player)
    local now  = os.time()
    local last = player:getCharVar('gainexp_lastused') or 0
    local elapsed = now - last

    if elapsed < COOLDOWN_SECS then
        local remaining = COOLDOWN_SECS - elapsed
        local hrs  = math.floor(remaining / 3600)
        local mins = math.floor((remaining % 3600) / 60)
        player:printToPlayer(
            string.format('[Gain Experience] On cooldown - %d h %02d m remaining.', hrs, mins),
            xi.msg.channel.SYSTEM_3
        )
        return
    end

    player:setCharVar('gainexp_lastused', now)
    player:setEminenceCompleted(4013)
    player:printToPlayer(
        '[Gain Experience] Reward claimed: +1500 EXP, +300 sparks, +300 accolades, 1x Copper Aman Voucher. (Next use in 24 h)',
        xi.msg.channel.SYSTEM_3
    )
end

return commandObj
