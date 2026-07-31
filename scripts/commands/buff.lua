-----------------------------------
-- func: buff
-- desc: Grants the zone-appropriate regional buff (Signet / Sanction /
--       Sigil / Ionis) plus Refresh, Regen, Regain, Composure, and
--       Reraise III to the player.
--       Refresh = 10% of max MP per tick (main job below 99 only)
--       Regen   = 10% of max HP per tick (main job below 99 only)
--       Regain  = scales with player level (1 per 10 levels, min 1)
--       Reraise = tier III (power 3, highest HP restored on death)
--       Regen and Refresh are a leveling aid: they are applied only while
--       the main job is below 99. At 99 they are skipped; the regional buff,
--       Regain, Composure, and Reraise III still apply at every level.
--
--       Regional buff is chosen from the player's current region:
--         Vana'diel conquest regions (0..22)   -> Signet
--         Aht Urhgan       regions (28..32)    -> Sanction
--         WotG past-era    regions (33..40)    -> Sigil
--         Adoulin          regions (44..45)    -> Ionis
--         Anywhere else (instanced/Abyssea)    -> Signet (safe fallback)
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 's'
}

-- Region -> (effect id, display name). The C++ code in
-- charutils::AddExperiencePoints uses the same region ranges to decide
-- which regional currency a kill awards, so this mapping is the canonical
-- one (see src/map/utils/charutils.cpp:5024-5031).
local function regionalEffect(region)
    if region <= xi.region.JEUNO then
        return xi.effect.SIGNET, 'Signet'
    elseif region >= xi.region.WEST_AHT_URHGAN and region <= xi.region.ALZADAAL then
        return xi.effect.SANCTION, 'Sanction'
    elseif region >= xi.region.RONFAURE_FRONT and region <= xi.region.VALDEAUNIA_FRONT then
        return xi.effect.SIGIL, 'Sigil'
    elseif region == xi.region.ADOULIN_ISLANDS or region == xi.region.EAST_ULBUKA then
        return xi.effect.IONIS, 'Ionis'
    end
    -- Instanced content (Dynamis, Limbus, Abyssea, etc.) or unknown:
    -- fall back to Signet so the player always gets *something*.
    return xi.effect.SIGNET, 'Signet'
end

commandObj.onTrigger = function(player, target)
    local targ

    -- allow optional target name, default to self
    if target ~= nil then
        targ = GetPlayerByName(target)
        if targ == nil then
            player:printToPlayer(string.format('Player "%s" not found.', target))
            return
        end
    else
        targ = player
    end

    local maxHP  = targ:getMaxHP()
    local maxMP  = targ:getMaxMP()
    local level  = targ:getMainLvl()

    -- Refresh: 10% of max MP per tick (minimum 1)
    local refreshPower = math.max(1, math.floor(maxMP * 0.10))

    -- Regen: 10% of max HP per tick (minimum 1)
    local regenPower = math.max(1, math.floor(maxHP * 0.10))

    -- Regain: 1 per 10 levels (minimum 1, max 10 at level 99)
    local regainPower = math.max(1, math.floor(level / 10))

    -- Duration: 5 hours (18000 seconds)
    local duration = 18000

    -- Regen/Refresh are a leveling aid only: applied while the main job is
    -- BELOW 99. At 99 (endgame) they are skipped -- the regional buff, Regain,
    -- Composure, and Reraise III still apply at every level.
    local sustainApplies = level < 99

    -- Apply the regional buff that matches the target's current zone.
    local regionalId, regionalName = regionalEffect(targ:getCurrentRegion())
    targ:addStatusEffect(regionalId, { power = 1, duration = duration, origin = player, tick = 3, subType = 0, subPower = 0 })

    if sustainApplies then
        -- Apply Refresh
        targ:addStatusEffect(xi.effect.REFRESH, { power = refreshPower, duration = duration, origin = player, tick = 3, subType = 0, subPower = 0 })

        -- Apply Regen
        targ:addStatusEffect(xi.effect.REGEN, { power = regenPower, duration = duration, origin = player, tick = 3, subType = 0, subPower = 0 })
    end

    -- Apply Regain
    targ:addStatusEffect(xi.effect.REGAIN, { power = regainPower, duration = duration, origin = player, tick = 3, subType = 0, subPower = 0 })

    -- Apply Composure: boosts accuracy and makes self-cast enhancing magic
    -- last longer. power = 1 is just a flag here -- the actual ACC bonus is
    -- computed inside the effect from the target's level + COMPOSURE_EFFECT
    -- job points (see scripts/effects/composure.lua). Non-ticking, so tick = 0.
    targ:addStatusEffect(xi.effect.COMPOSURE, { power = 1, duration = duration, origin = player, tick = 0, subType = 0, subPower = 0 })

    -- Apply Reraise III: power = raise tier (see scripts/effects/reraise.lua,
    -- onEffectLose -> sendReraise(power)). Non-ticking. Consumed on death, or
    -- expires with the other buffs after 5 hours if unused.
    targ:addStatusEffect(xi.effect.RERAISE, { power = 3, duration = duration, origin = player, tick = 0, subType = 0, subPower = 0 })

    -- Confirm message. Regen/Refresh only appear when they were actually
    -- applied (main job below 99); at 99 they are called out as skipped.
    local sustainMsg = sustainApplies
        and string.format('Regen: %d/tick | Refresh: %d/tick | ', regenPower, refreshPower)
        or 'Regen/Refresh: skipped at Lv.99 | '
    targ:printToPlayer(string.format(
        'Buffs applied! %s | %sRegain: %d/tick | Composure | Reraise III | Duration: 5 hours',
        regionalName, sustainMsg, regainPower
    ))
end

return commandObj
