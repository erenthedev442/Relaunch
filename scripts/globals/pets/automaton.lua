-----------------------------------
-- PET: Automaton
-----------------------------------
xi = xi or {}
xi.pets = xi.pets or {}
xi.pets.automaton = {}

xi.pets.automaton.onMobSpawn = function(mob)
    mob:setLocalVar('MANEUVER_DURATION', 60)
    mob:addListener('EFFECTS_TICK', 'MANEUVER_DURATION', function(automaton)
        if automaton:getTarget() then
            local dur = automaton:getLocalVar('MANEUVER_DURATION')
            automaton:setLocalVar('MANEUVER_DURATION', math.min(dur + 3, 300))
        end
    end)

    -- Barrage Turbine cannot be used unless the automaton has been active for at least 3 minutes.
    mob:addRecast(xi.recast.ABILITY, xi.automaton.abilities.BARRAGE_TURBINE, 60 * 3)

    -- Apply owner's Job Point HP/MP bonus at every spawn (Activate AND zone-in re-summon).
    -- delMod before addMod makes this idempotent if called on a persisted entity.
    local owner = mob:getMaster()
    if owner then
        local jpValue = owner:getJobPointLevel(xi.jp.AUTOMATON_HP_MP_BONUS)
        if jpValue > 0 then
            mob:delMod(xi.mod.HP, jpValue * 10)
            mob:addMod(xi.mod.HP, jpValue * 10)
            mob:delMod(xi.mod.MP, jpValue * 5)
            mob:addMod(xi.mod.MP, jpValue * 5)
            mob:updateHealth()
        end
    end
end

xi.pets.automaton.onMobDeath = function(mob)
    mob:removeListener('MANEUVER_DURATION')
end
