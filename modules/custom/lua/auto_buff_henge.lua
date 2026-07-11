-----------------------------------
-- auto_buff_henge.lua
-- Automatically applies Refresh / Regen / Regain when a player zones
-- into Escha - Zi'Tah (the Hunting League hub) so they can immediately
-- start hunting without typing !buff first.
--   Refresh = 10% of max MP per tick
--   Regen   = 10% of max HP per tick
--   Regain  = 1 per 10 levels (min 1)
--   Duration = 5 hours (18000s, matches !buff)
-- A regional buff is applied if the zone's region matches; Escha zones
-- have their own region so this typically falls back to Signet.
-- If the player already has the effect it is replaced (same as !buff).
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Escha_ZiTah/Zone')

local m = Module:new('auto_buff_henge')

m:addOverride('xi.zones.Escha_ZiTah.Zone.onZoneIn', function(player, prevZone)
    super(player, prevZone)

    -- 1500ms delay: let the zone-in animation settle and stat calculations
    -- complete before applying effects (consistent with !buff manual command).
    player:timer(1500, function(p)
        local maxHP  = p:getMaxHP()
        local maxMP  = p:getMaxMP()
        local level  = p:getMainLvl()

        local refreshPower = math.max(1, math.floor(maxMP * 0.10))
        local regenPower   = math.max(1, math.floor(maxHP * 0.10))
        local regainPower  = math.max(1, math.floor(level / 10))
        local duration     = 18000   -- 5 hours (18000s)

        -- Apply Ionis for Adoulin-era regions; Escha zones have their own
        -- region so this typically resolves to Signet (harmless fallback).
        local region     = p:getCurrentRegion()
        local regionalId = xi.effect.SIGNET
        if region == xi.region.ADOULIN_ISLANDS or region == xi.region.EAST_ULBUKA then
            regionalId = xi.effect.IONIS
        end

        p:addStatusEffect(regionalId,        { power = 1,            duration = duration, origin = p, tick = 3, subType = 0, subPower = 0 })
        p:addStatusEffect(xi.effect.REFRESH, { power = refreshPower, duration = duration, origin = p, tick = 3, subType = 0, subPower = 0 })
        p:addStatusEffect(xi.effect.REGEN,   { power = regenPower,   duration = duration, origin = p, tick = 3, subType = 0, subPower = 0 })
        p:addStatusEffect(xi.effect.REGAIN,  { power = regainPower,  duration = duration, origin = p, tick = 3, subType = 0, subPower = 0 })

        p:printToPlayer(
            string.format('[Relaunch] Auto-buff: Refresh %d/tick | Regen %d/tick | Regain %d/tick  (5 hr). Happy hunting!',
                refreshPower, regenPower, regainPower),
            xi.msg.channel.SYSTEM_3)
    end)
end)

return m
