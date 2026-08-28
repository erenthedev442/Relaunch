---@type TCommand
-- Wraps scripts/commands/shop.
--
-- RELAUNCH: augment catalysts are FARM-ONLY. Each catalyst drops (~50%) from one
-- specific assigned monster (modules/custom/lua/augment_catalyst_drops.lua +
-- augment_catalyst_mobs.lua); augments are tier-gated (T0 Day 1 / T1 HL Rank 3 /
-- T2 HL Rank 5 / T3 Prestige Lv15 / T4 endgame). The old gil-buy `!shop augments`
-- category is RETIRED -- it now just points players at farming. Everything else
-- delegates unchanged to the stock shop.
--
-- (The Augment Moogle perfect-crystalization token, "Maat's Cap", was previously bundled
-- into every augment shop group at 10M gil. That sale is removed here too; the
-- token is a Maat's Challenge reward -- re-add a dedicated buy if wanted.)
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 'ss',
}

local function getShop()
    package.loaded['scripts/commands/shop'] = nil
    return require('scripts/commands/shop')
end

commandObj.onTrigger = function(player, category, subcat)
    local cat = category and category:lower() or 'general'

    if cat == 'augments' then
        local SYS = xi.msg.channel.SYSTEM_3
        player:printToPlayer('Augment catalysts are no longer sold for gil -- they DROP from monsters now (each catalyst from one specific mob, ~50%).', SYS)
        player:printToPlayer('Farm the assigned monster, then trade the catalyst to the Augment Moogle at GM Home. The "Augmenting" guide lists every catalyst, its tier, and where it drops.', SYS)
        return
    end

    return getShop().onTrigger(player, category, subcat)
end

return commandObj
