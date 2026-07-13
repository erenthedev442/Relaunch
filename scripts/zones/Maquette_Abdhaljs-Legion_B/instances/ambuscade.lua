-----------------------------------
-- Ambuscade instance handler
-- Instance ID : 30000   (!instance 30000)
-- Zone        : 287 (Maquette_Abdhaljs-Legion_B)
-- Entry pos   : (137, 12.5, -137, rot 32)
-- Exit zone   : 249 (Mhaura)
--
-- Difficulty (1-15) stored in Ambuscade_Difficulty charVar → setProgress().
-- onInstanceProgressUpdate fires immediately after setProgress(); that is
-- where mob HP is scaled AND Urchins/Housemaker are spawned so difficulty
-- is known before the player zones in.
-----------------------------------
local ID = zones[xi.zone.MAQUETTE_ABDHALJS_LEGION_B]
-----------------------------------
local instanceObject = {}

-- HP multiplier for Bozzetto Breadwinner (party HP scaling is done at engage).
-- Urchins are also scaled here; Housemaker HP comes from mob_groups.
local DIFF_HP_SCALE =
{
    -- Intense VD→VE
    [1]  = 5.0,  [2]  = 3.5,  [3]  = 2.5,  [4]  = 1.8,  [5]  = 1.0,
    -- Regular VD→VE
    [6]  = 4.0,  [7]  = 2.8,  [8]  = 2.0,  [9]  = 1.5,  [10] = 1.0,
    -- Light VD→VE
    [11] = 1.3,  [12] = 1.2,  [13] = 1.0,  [14] = 0.9,  [15] = 0.8,
}

-- How many Urchin adds to spawn (pre-spawned, never respawn during the fight).
local URCHIN_COUNT =
{
    [1]=4, [2]=3, [3]=2, [4]=2, [5]=1,   -- Intense
    [6]=3, [7]=2, [8]=2, [9]=1, [10]=1,  -- Regular
    [11]=1,[12]=1,[13]=1,[14]=1,[15]=1,  -- Light
}

local URCHIN_IDS =
{
    ID.mob.BOZZETTO_URCHIN_1,
    ID.mob.BOZZETTO_URCHIN_2,
    ID.mob.BOZZETTO_URCHIN_3,
    ID.mob.BOZZETTO_URCHIN_4,
}

-- Spawn only the Breadwinner here; Urchins and Housemaker are spawned
-- in onInstanceProgressUpdate (once difficulty is known).
instanceObject.onInstanceCreated = function(instance)
    SpawnMob(ID.mob.BOZZETTO_BREADWINNER, instance)
end

-- Read difficulty, persist to instance, warp player in.
-- setProgress() triggers onInstanceProgressUpdate before returning.
instanceObject.onInstanceCreatedCallback = function(player, instance)
    if not instance then return end
    local diff = player:getCharVar('Ambuscade_Difficulty')
    if diff < 1 or diff > 15 then diff = 10 end  -- default: Regular VE
    instance:setProgress(diff)
    player:setInstance(instance)
    player:setPos(137, 12.5, -137, 32, instance:getZone():getID())
end

instanceObject.afterInstanceRegister = function(player)
    local instance = player:getInstance()
    if instance then
        player:countdown(instance:getTimeLimit() * 60)
    end
end

-- Fires immediately after onInstanceCreatedCallback calls setProgress().
-- Scale Breadwinner HP, spawn adds.
instanceObject.onInstanceProgressUpdate = function(instance, progress)
    local mult = DIFF_HP_SCALE[progress] or 1.0

    -- Scale Breadwinner HP.
    local bw = GetMobByID(ID.mob.BOZZETTO_BREADWINNER)
    if bw and bw:isAlive() then
        local newHP = math.max(1, math.floor(bw:getMaxHP() * mult))
        bw:setMaxHP(newHP)
        bw:setHP(newHP)
    end

    -- Spawn difficulty-appropriate number of Urchins.
    local urchinCount = URCHIN_COUNT[progress] or 1
    for i = 1, urchinCount do
        SpawnMob(URCHIN_IDS[i], instance)
    end

    -- Scale Urchin HP.
    for i = 1, urchinCount do
        local u = GetMobByID(URCHIN_IDS[i])
        if u and u:isAlive() then
            local newHP = math.max(1, math.floor(u:getMaxHP() * mult))
            u:setMaxHP(newHP)
            u:setHP(newHP)
        end
    end

    -- Always spawn one Housemaker.
    SpawnMob(ID.mob.AMBUSCADE_HOUSEMAKER, instance)
end

-- Detect when all killable mobs are dead; record elapsed time for time bonus.
instanceObject.onInstanceTimeUpdate = function(instance, elapsed)
    -- CheckTime keeps ticking after completion (core only gates on Failed()),
    -- and Complete() re-fires onInstanceComplete unconditionally — without this
    -- guard every 1s tick after the clear re-awards the victory reward.
    if instance:completed() then
        return
    end

    -- CLEAR-DETECT FIX (2026-07-12): the old check compared getName()
    -- against the packet name 'Ambuscade_Housemaker' with an underscore,
    -- but getName() returns the DISPLAY name ('Ambuscade Housemaker' with
    -- a space) -- so the passive Housemaker was ALWAYS counted as a live
    -- kill target, this loop always early-returned, and completion never
    -- fired even after the player killed Breadwinner + all Urchins. Match
    -- on mob ID (which is exact) instead of a name string.
    local mobs      = instance:getMobs()
    local anyMob    = false
    local hmId      = ID.mob.AMBUSCADE_HOUSEMAKER
    for _, mob in pairs(mobs) do
        if mob:getID() ~= hmId then
            -- Only count non-passive mobs toward the kill condition.
            anyMob = true
            if mob:isAlive() then return end
        end
    end
    if anyMob then
        -- Store clear time so onInstanceComplete can award the time bonus.
        for _, player in pairs(instance:getChars()) do
            player:setCharVar('Ambuscade_Clear_Time', math.floor(elapsed))
        end
        -- Despawn any surviving Housemaker cleanly.
        pcall(function()
            local hm = GetMobByID(ID.mob.AMBUSCADE_HOUSEMAKER)
            if hm and hm:isAlive() then hm:setHP(0) end
        end)
        instance:complete()
    end
end

instanceObject.onInstanceFailure = function(instance)
    xi.ambuscade.onInstanceFailure(instance)
end

instanceObject.onInstanceComplete = function(instance)
    xi.ambuscade.onInstanceComplete(instance)
end

instanceObject.onEventUpdate = function(player, csid, option, npc)
end

-- csid 10001 = generic instance-exit event; warp back to Mhaura.
instanceObject.onEventFinish = function(player, csid, option, npc)
    if csid == 10001 then
        player:setPos(-34.2, -16, 58, 32, 249)
    end
end

return instanceObject
