-----------------------------------
-- Ambuscade Housemaker
-- Passive support structure for the Bozzetto Breadwinner.
-- Does not attack players. While alive, buffs the Breadwinner with ATT/MACC.
-- Destroying it removes the buff. Respawns each time the Breadwinner warbles
-- if not already present (controlled by instance handler; no auto-respawn here).
-----------------------------------
local ID = zones[xi.zone.MAQUETTE_ABDHALJS_LEGION_B]

local HM_ATT_BONUS  = 600
local HM_MATT_BONUS = 200
local HM_EVA_BONUS  = 80   -- harder to hit while buffing

local entity = {}

entity.onMobInitialize = function(mob)
    -- Disable melee retaliation completely so it acts as a structure.
    mob:setMobMod(xi.mobMod.DRAW_IN, 0)
    mob:setMobMod(xi.mobMod.NOAGGROTHRESHOLD, 1)
end

entity.onMobSpawn = function(mob)
    -- Give the Breadwinner its buff once the server tick settles.
    mob:timer(800, function(m)
        local bw = GetMobByID(ID.mob.BOZZETTO_BREADWINNER)
        if bw and bw:isAlive() and bw:getLocalVar('hm_buffed') == 0 then
            bw:addMod(xi.mod.ATT,  HM_ATT_BONUS)
            bw:addMod(xi.mod.MATT, HM_MATT_BONUS)
            bw:addMod(xi.mod.EVA,  HM_EVA_BONUS)
            bw:setLocalVar('hm_buffed', 1)
            -- Announce via zone message so players know it's active.
            bw:printToZone('[Ambuscade] The Housemaker awakens! The Breadwinner is empowered.')
        end
    end)
end

entity.onMobEngaged = function(mob, target)
    -- Prevent fighting back; immediately disengage.
    mob:disengage()
end

entity.onMobFight = function(mob, target)
    mob:disengage()
end

entity.onMobWeaponSkill = function(mob, target, skill, action)
end

entity.onMobDeath = function(mob, player, optParams)
    -- Remove Breadwinner buff on death.
    local bw = GetMobByID(ID.mob.BOZZETTO_BREADWINNER)
    if bw and bw:isAlive() and bw:getLocalVar('hm_buffed') == 1 then
        bw:delMod(xi.mod.ATT,  HM_ATT_BONUS)
        bw:delMod(xi.mod.MATT, HM_MATT_BONUS)
        bw:delMod(xi.mod.EVA,  HM_EVA_BONUS)
        bw:setLocalVar('hm_buffed', 0)
        bw:printToZone('[Ambuscade] The Housemaker is defeated! The Breadwinner weakens.')
    end
end

return entity
