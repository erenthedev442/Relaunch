-----------------------------------
-- PET: Luopan
-----------------------------------
xi = xi or {}
xi.pets = xi.pets or {}
xi.pets.luopan = {}

xi.pets.luopan.onMobSpawn = function(mob)
    -- BGWIKI: "Regardless of perpetuation cost reduction, Luopans have a maximum duration of 10 minutes."
    -- LEGENDARY (2026-06-23): retail caps luopan lifetime at 600000ms (10 min). Uncapped here.
    -- Set LUOPAN_DURATION_MS to a number of ms to re-impose a cap; 0 = no timer (the luopan
    -- persists until you zone, dismiss it, re-summon, or die).
    local LUOPAN_DURATION_MS = 0 -- 0 = uncapped (retail = 600000 = 10 min)
    if LUOPAN_DURATION_MS > 0 then
        mob:timer(LUOPAN_DURATION_MS, function(mobArg)
            mobArg:setHP(0)
        end)
    end
end

xi.pets.luopan.onMobDeath = function(mob)
end
