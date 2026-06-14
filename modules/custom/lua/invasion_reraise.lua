-----------------------------------
-- invasion_reraise.lua
-- Auto-reraises players who die in GM Home while any invasion is active.
-- Full HP/MP on raise, no Weakness, no Disease.
--
-- Requires restart to take effect (addOverride module).
-- Both Invasion.lua and modules/custom/commands/invasion.lua set
-- xi._any_invasion_active = true/false to signal the active state.
-----------------------------------
require('modules/module_utils')

local m = Module:new('invasion_reraise')

local RAISE_DELAY_MS  = 3000   -- ms before auto-raise fires
local RESTORE_DELAY_MS = 500   -- ms after sendReraise before we max HP/strip debuffs

m:addOverride('xi.player.onPlayerDeath', function(player, killer, isKO)
    super(player, killer, isKO)

    if player:getZoneID() ~= xi.zone.AL_ZAHBI then return end
    if not xi._any_invasion_active then return end

    player:timer(RAISE_DELAY_MS, function(p)
        if not (p and p:getHP() <= 0) then return end

        -- sendReraise animates the raise and re-enables player control.
        -- power=3 = Raise III (closest to full HP raise).
        p:sendReraise(3)

        -- Short delay so sendReraise's packets land before we override HP.
        p:timer(RESTORE_DELAY_MS, function(pp)
            if not pp then return end
            pp:setHP(pp:getMaxHP())
            pp:setMP(pp:getMaxMP())
            pp:delStatusEffectSilent(xi.effect.WEAKNESS)
            pp:delStatusEffectSilent(xi.effect.DISEASE)
            pp:delStatusEffectSilent(xi.effect.PLAGUE)
            pp:printToPlayer('[Invasion] The spirit rises! You are fully restored.',
                xi.msg.channel.SYSTEM_3)
        end)
    end)
end)

return m
