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
local mechanics = require('modules/custom/lua/mob_mechanics_library')
-----------------------------------
local instanceObject = {}

-- ─── Difficulty tuning (owner call 2026-07-13) ────────────────────────────────
-- The prior HP-only scaling (Intense VD = 5x HP) played "easy" because a level-
-- 119 Breadwinner with stock mods can't hurt an ilvl-119 party -- more HP just
-- meant longer autoattacks. Rebuild: modest HP scaling, aggressive stat + mech
-- scaling. Owner directive: "make them very deadly, not necessarily with HP".
-- Intense VD HP cap set to 2.5x (was 5.0). Doom lands on the Intense VD tier
-- only.
local DIFF_HP_SCALE =
{
    -- Intense VD→VE (was 5.0/3.5/2.5/1.8/1.0)
    [1]  = 2.5,  [2]  = 2.0,  [3]  = 1.7,  [4]  = 1.4,  [5]  = 1.0,
    -- Regular VD→VE (was 4.0/2.8/2.0/1.5/1.0)
    [6]  = 2.0,  [7]  = 1.7,  [8]  = 1.4,  [9]  = 1.2,  [10] = 1.0,
    -- Light VD→VE (was 1.3/1.2/1.0/0.9/0.8) -- kept as a true easy-mode ladder
    [11] = 1.0,  [12] = 1.0,  [13] = 1.0,  [14] = 0.9,  [15] = 0.8,
}

-- Flat stat bumps applied to Breadwinner + Urchins at spawn. Every field is a
-- straight addModifier: att = xi.mod.ATT, haste = xi.mod.HASTE_GEAR (10 = 1%),
-- da = xi.mod.DOUBLE_ATTACK (percent chance), regen = xi.mod.REGEN (HP/tick).
local DIFF_STAT_MODS =
{
    -- Intense VD→VE
    [1]  = { att = 5000, acc = 500, matt = 3000, macc = 300, haste = 200, da = 40, regen = 200 },
    [2]  = { att = 3500, acc = 400, matt = 2000, macc = 250, haste = 150, da = 30, regen = 150 },
    [3]  = { att = 2500, acc = 300, matt = 1500, macc = 200, haste = 100, da = 20, regen = 100 },
    [4]  = { att = 1500, acc = 200, matt =  800, macc = 150, haste =  75, da = 10, regen =  60 },
    [5]  = { att =  800, acc = 100, matt =  400, macc =  75, haste =  40, da =  5, regen =  30 },
    -- Regular VD→VE
    [6]  = { att = 3500, acc = 350, matt = 2000, macc = 250, haste = 150, da = 25, regen = 120 },
    [7]  = { att = 2500, acc = 250, matt = 1200, macc = 150, haste = 100, da = 15, regen =  80 },
    [8]  = { att = 1500, acc = 200, matt =  800, macc = 100, haste =  50, da = 10, regen =  40 },
    [9]  = { att =  800, acc = 100, matt =  400, macc =  50, haste =  25, da =  0, regen =  20 },
    [10] = { att =  400, acc =  50, matt =  200, macc =   0, haste =   0, da =  0, regen =   0 },
    -- Light VD→VE (only the top of Light gets any bumps; the bottom stays retail)
    [11] = { att =  500, acc = 100, matt =  200, macc =  50, haste =   0, da =  0, regen =   0 },
    [12] = { att =  200, acc =  50, matt =  100, macc =   0, haste =   0, da =  0, regen =   0 },
    [13] = {},
    [14] = {},
    [15] = {},
}

-- Shared stance-dance pair reused by every tier that carries a stance mechanic.
-- -5000 on a damage-type mod caps the mob at 50% mitigation (engine hard cap),
-- so "immune" here means "cuts damage in half", not literal invulnerability.
local STANCE_PAIR =
{
    { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     },
      msg  = 'The Breadwinner\'s hide hardens -- steel bites shallow, break it with magic!' },
    { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 },
      msg  = 'The Breadwinner shrugs off the arcane -- cut it down with iron!' },
}

-- mob_mechanics_library configs, keyed by difficulty. Missing keys = no mechanic.
-- Doom lives ONLY on tier 1 per owner call (2026-07-13).
local DIFF_MECH_CFG =
{
    [1] = {  -- Intense VD -- full kit
        name   = 'Bozzetto Breadwinner',
        stance = { startHpp = 90, periodSec = 14, stances = STANCE_PAIR },
        aoe    = { periodSec = 10, dmgPct = 18, msg = 'The Breadwinner erupts -- a shockwave hurls out!' },
        drain  = { periodSec =  8, healPct =  3 },
        doom   = { startHpp = 12, dur = 25, msg = 'The Breadwinner marks you for oblivion!' },
        phases = {
            { hp = 75, action = 'fury',   att = 1500, haste = 100, msg = 'The Breadwinner\'s eyes redden -- it accelerates!' },
            { hp = 50, action = 'nuke',   dmgPct = 25, msg = 'The Breadwinner exhales devastation!' },
            { hp = 25, action = 'fury',   att = 2500, haste = 150, msg = 'The Breadwinner ascends its true fury!' },
            { hp = 10, action = 'enrage', att = 5000, haste = 200, msg = 'The Breadwinner enters its final gasp -- FINISH IT!' },
        },
    },
    [2] = {  -- Intense D
        name   = 'Bozzetto Breadwinner',
        stance = { startHpp = 90, periodSec = 17, stances = STANCE_PAIR },
        aoe    = { periodSec = 12, dmgPct = 14, msg = 'The Breadwinner erupts!' },
        drain  = { periodSec = 10, healPct = 3 },
        phases = {
            { hp = 50, action = 'fury', att = 1500, haste = 100, msg = 'The Breadwinner accelerates!' },
            { hp = 25, action = 'nuke', dmgPct = 20, msg = 'The Breadwinner unleashes a burst!' },
        },
    },
    [3] = {  -- Intense N
        name   = 'Bozzetto Breadwinner',
        stance = { startHpp = 85, periodSec = 20, stances = STANCE_PAIR },
        aoe    = { periodSec = 14, dmgPct = 11, msg = 'The Breadwinner erupts!' },
        phases = {
            { hp = 50, action = 'fury', att = 1000, haste = 80, msg = 'The Breadwinner accelerates!' },
        },
    },
    [4] = {  -- Intense E
        name = 'Bozzetto Breadwinner',
        aoe  = { periodSec = 16, dmgPct = 9, msg = 'The Breadwinner erupts!' },
    },
    [5] = {},  -- Intense VE -- stat bumps only
    [6] = {  -- Regular VD
        name   = 'Bozzetto Breadwinner',
        stance = { startHpp = 85, periodSec = 18, stances = STANCE_PAIR },
        aoe    = { periodSec = 12, dmgPct = 13, msg = 'The Breadwinner erupts!' },
        drain  = { periodSec = 12, healPct = 3 },
        phases = {
            { hp = 50, action = 'fury', att = 1200, haste = 80, msg = 'The Breadwinner accelerates!' },
        },
    },
    [7] = {  -- Regular D
        name   = 'Bozzetto Breadwinner',
        stance = { startHpp = 80, periodSec = 22, stances = STANCE_PAIR },
        aoe    = { periodSec = 14, dmgPct = 10, msg = 'The Breadwinner erupts!' },
        phases = {
            { hp = 50, action = 'fury', att = 800, haste = 50, msg = 'The Breadwinner accelerates!' },
        },
    },
    [8] = {  -- Regular N
        name   = 'Bozzetto Breadwinner',
        stance = { startHpp = 75, periodSec = 25, stances = STANCE_PAIR },
    },
    [9] = {},   -- Regular E
    [10] = {},  -- Regular VE
    [11] = {}, [12] = {}, [13] = {}, [14] = {}, [15] = {},  -- Light: retail baseline
}

-- Apply the flat stat block to a single mob. Called once per mob at spawn time
-- inside onInstanceProgressUpdate. Safe on repeated tiers because the instance
-- is fresh each entry (mob mods don't carry over).
local function applyDiffMods(mob, mods)
    if not mob or not mods then return end
    if mods.att   and mods.att   > 0 then mob:addMod(xi.mod.ATT,            mods.att)   end
    if mods.acc   and mods.acc   > 0 then mob:addMod(xi.mod.ACC,            mods.acc)   end
    if mods.matt  and mods.matt  > 0 then mob:addMod(xi.mod.MATT,           mods.matt)  end
    if mods.macc  and mods.macc  > 0 then mob:addMod(xi.mod.MACC,           mods.macc)  end
    if mods.haste and mods.haste > 0 then mob:addMod(xi.mod.HASTE_GEAR,     mods.haste) end
    if mods.da    and mods.da    > 0 then mob:addMod(xi.mod.DOUBLE_ATTACK,  mods.da)    end
    if mods.regen and mods.regen > 0 then mob:addMod(xi.mod.REGEN,          mods.regen) end
end

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
-- Scale Breadwinner HP, spawn adds, apply per-tier stat bumps + attach the
-- mob_mechanics_library config to the Breadwinner.
instanceObject.onInstanceProgressUpdate = function(instance, progress)
    local mult  = DIFF_HP_SCALE[progress] or 1.0
    local mods  = DIFF_STAT_MODS[progress] or {}
    local mCfg  = DIFF_MECH_CFG[progress]

    -- Scale Breadwinner HP + apply the tier's stat bumps.
    local bw = GetMobByID(ID.mob.BOZZETTO_BREADWINNER)
    if bw and bw:isAlive() then
        local newHP = math.max(1, math.floor(bw:getMaxHP() * mult))
        bw:setMaxHP(newHP)
        bw:setHP(newHP)
        applyDiffMods(bw, mods)
        -- Attach mechanics (stance/aoe/drain/doom/phases). Empty cfg = no-op.
        if mCfg and next(mCfg) then
            mechanics.attach(bw, mCfg)
        end
    end

    -- Spawn difficulty-appropriate number of Urchins.
    local urchinCount = URCHIN_COUNT[progress] or 1
    for i = 1, urchinCount do
        SpawnMob(URCHIN_IDS[i], instance)
    end

    -- Scale Urchin HP + apply the tier's stat bumps. Urchins share the boss's
    -- stat curve (they're MNK-typed adds; on Intense VD they hit as hard as
    -- the boss for their HP pool, so ignoring them means a wipe fast).
    for i = 1, urchinCount do
        local u = GetMobByID(URCHIN_IDS[i])
        if u and u:isAlive() then
            local newHP = math.max(1, math.floor(u:getMaxHP() * mult))
            u:setMaxHP(newHP)
            u:setHP(newHP)
            applyDiffMods(u, mods)
        end
    end

    -- Always spawn one Housemaker. Housemaker is a passive structure so it
    -- doesn't need the offensive stat curve or a mechanic block.
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
