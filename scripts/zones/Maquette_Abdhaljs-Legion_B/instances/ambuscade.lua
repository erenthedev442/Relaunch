-----------------------------------
-- Ambuscade instance handler
-- Instance ID : 30000   (!instance 30000)
-- Zone        : 287 (Maquette_Abdhaljs-Legion_B)
-- Entry pos   : (137, 12.5, -137, rot 32)
-- Exit zone   : 249 (Mhaura)
--
-- Difficulty (1-15) stored in Ambuscade_Difficulty charVar → setProgress().
-- Mobs are spawned and scaled in onInstanceCreated, after the callback has
-- stored the selected difficulty on the instance.
-----------------------------------
local ID = zones[xi.zone.MAQUETTE_ABDHALJS_LEGION_B]
local mechanics = require('modules/custom/lua/mob_mechanics_library')
-----------------------------------
local instanceObject = {}

-- Difficulty ladder (easy → hard): Light VE … Regular VD ≤ Intense N < Intense D < Intense VD.
-- Intense VD is the endgame tier (~Tier-2 Abyssea HP budget at 15.4×); entry tiers stay
-- approachable so Warbles / Thrashing Assault do not one-shot fresh groups.
local DIFF_HP_SCALE =
{
    -- Intense VD→VE
    [1]  = 15.4, [2]  = 8.7,  [3]  = 1.0,  [4]  = 0.85, [5]  = 0.75,
    -- Regular VD→VE (VD is the top of Regular but still below Intense N)
    [6]  = 0.85, [7]  = 1.0,  [8]  = 0.9,  [9]  = 0.75, [10] = 0.65,
    -- Light VD→VE
    [11] = 0.9,  [12] = 0.85, [13] = 0.75, [14] = 0.65, [15] = 0.55,
}

-- Per-tier ceiling on a single mob-skill hit (Warbles, Thrashing Assault, etc.).
-- Uses the same Geas Fete hook as scripted encounter mobs.
local DIFF_SKILL_DAMAGE_CAP =
{
    [1]  = 12000, [2]  = 9000, [3]  = 4500, [4]  = 3800, [5]  = 3200,
    [6]  = 3500,  [7]  = 3800, [8]  = 3200, [9]  = 2800, [10] = 2500,
    [11] = 2800,  [12] = 2600, [13] = 2400, [14] = 2200, [15] = 2000,
}

-- Flat stat bumps applied to Breadwinner + Urchins at spawn. Every field is a
-- straight addModifier: att = xi.mod.ATT, haste = xi.mod.HASTE_GEAR (10 = 1%),
-- da = xi.mod.DOUBLE_ATTACK (percent chance), regen = xi.mod.REGEN (HP/tick).
local DIFF_STAT_MODS =
{
    -- Intense VD→VE
    [1]  = { att = 5000, acc = 500, matt = 3000, macc = 300, haste = 200, da = 40, regen = 200 },
    [2]  = { att = 3500, acc = 400, matt = 2000, macc = 250, haste = 150, da = 30, regen = 150 },
    [3]  = { att =  400, acc =  50 },
    [4]  = {},
    [5]  = {},
    -- Regular VD→VE (flat bumps only; no endgame ATT/MATT stacks on entry tiers)
    [6]  = { att =  150, acc =  40 },
    [7]  = { att =  300, acc =  60, matt = 100 },
    [8]  = { att =  200, acc =  40 },
    [9]  = {},
    [10] = {},
    -- Light VD→VE (top of Light still below Regular VD)
    [11] = { att =  250, acc =  60, matt =  100, macc =  25 },
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
    [3] = {},  -- Intense N -- entry-level stats only
    [4] = {},  -- Intense E -- stock mechanics
    [5] = {},  -- Intense VE
    [6] = {},  -- Regular VD -- entry Regular; stats-only (same band as Intense N)
    [7] = {},  -- Regular D
    [8] = {},   -- Regular N
    [9] = {},   -- Regular E
    [10] = {},  -- Regular VE
    [11] = {}, [12] = {}, [13] = {}, [14] = {}, [15] = {},  -- Light: retail baseline
}

-- Apply the flat stat block to a single mob. Called once per mob at spawn time.
-- Safe on repeated tiers because the instance is fresh each entry.
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

local function applyAmbuscadeMob(mob, progress, mult, mods, mCfg)
    if not mob then return end

    local newHP = math.max(1, math.floor(mob:getMaxHP() * mult))
    mob:setMaxHP(newHP)
    mob:setHP(newHP)
    applyDiffMods(mob, mods)

    local cap = DIFF_SKILL_DAMAGE_CAP[progress]
    if cap and cap > 0 then
        mob:setLocalVar('GeasFeteMobSkillDamageCap', cap)
    end

    if mCfg and next(mCfg) then
        mechanics.attach(mob, mCfg)
    end
end

-- How many Urchin adds to spawn (pre-spawned, never respawn during the fight).
local URCHIN_COUNT =
{
    [1]=4, [2]=3, [3]=1, [4]=1, [5]=1,   -- Intense
    [6]=1, [7]=1, [8]=1, [9]=1, [10]=1,  -- Regular
    [11]=1,[12]=1,[13]=1,[14]=1,[15]=1,  -- Light
}

local URCHIN_IDS =
{
    ID.mob.BOZZETTO_URCHIN_1,
    ID.mob.BOZZETTO_URCHIN_2,
    ID.mob.BOZZETTO_URCHIN_3,
    ID.mob.BOZZETTO_URCHIN_4,
}

instanceObject.onInstanceCreated = function(instance)
    local progress = instance:getProgress()
    local mult     = DIFF_HP_SCALE[progress] or 1.0
    local mods     = DIFF_STAT_MODS[progress] or {}
    local mCfg     = DIFF_MECH_CFG[progress]

    local bw = SpawnMob(ID.mob.BOZZETTO_BREADWINNER, instance)
    if bw then
        applyAmbuscadeMob(bw, progress, mult, mods, mCfg)
    end

    local urchinCount = URCHIN_COUNT[progress] or 1
    for i = 1, urchinCount do
        local urchin = SpawnMob(URCHIN_IDS[i], instance)
        if urchin then
            applyAmbuscadeMob(urchin, progress, mult, mods, nil)
        end
    end

    SpawnMob(ID.mob.AMBUSCADE_HOUSEMAKER, instance)
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
    if xi.ambuscade and xi.ambuscade.onHostInstanceReady then
        xi.ambuscade.onHostInstanceReady(player, instance)
    end
end

instanceObject.afterInstanceRegister = function(player)
    local instance = player:getInstance()
    if instance then
        player:countdown(instance:getTimeLimit() * 60)
    end
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
