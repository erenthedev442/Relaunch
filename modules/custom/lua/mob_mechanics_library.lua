-----------------------------------
-- mob_mechanics_library.lua
--
-- Reusable "hardcore" combat mechanics for the custom NMs/bosses. Lifts the
-- proven RaidBoss.lua onMobFight brain (stance dance, HP phases, add-spawning,
-- soft enrage) into a shared, config-driven library so EVERY custom NM system
-- (Hunting League, Prestige/Ascension, Endless Tower, Apex, Voidspire, Invasion,
-- Abyssea marks, Raid) can give its mobs a distinct fight without each one
-- re-implementing the wheel.
--
-- WIRING (per system) -- three touch points on the dynamic-mob spawn:
--   1. In the insertDynamicEntity def add:
--        onMobFight = function(mob, target) mechanics.tick(mob, target) end,
--   2. After mob:spawn() (and your stat/HP setup) call:
--        mechanics.attach(mob, mechCfg)         -- mechCfg from the NM's catalog tier
--   3. At the TOP of your existing onMobDeath add:
--        mechanics.cleanup(deadMob)             -- frees state + despawns its adds
--   (Call mechanics.cleanup(mob) anywhere you force-despawn a configured NM too.)
--
-- STATE is keyed by mob id (many NMs run concurrently), and is crash-safe the
-- same way RaidBoss is: fresh add sets per spawn, state cleared BEFORE despawns,
-- every mob/player call pcall-guarded (dynamic mobs + players can vanish mid-tick).
--
-- CONFIG SCHEMA (everything optional -- an NM only gets the keys it lists):
--   mechCfg = {
--     name   = 'Boss Name',          -- for shout() prefixes (optional)
--     enrage = { sec=180, att=5000, haste=200, msg='...' },              -- soft DPS check
--     stance = { startHpp=100, periodSec=18, stances={                   -- phys/mag immunity dance
--                  { mods={[xi.mod.DMGPHYS]=-10000,[xi.mod.DMGMAGIC]=0},     msg='hardens against weapons!' },
--                  { mods={[xi.mod.DMGPHYS]=0,[xi.mod.DMGMAGIC]=-10000},     msg='warps magic aside!' } } },
--     aoe    = { periodSec=12, dmgPct=22, msg='unleashes a shockwave!' }, -- % of victim max HP to all near
--     cc     = { periodSec=24, effect=xi.effect.TERROR, power=1, dur=5, msg='lets out a paralysing roar!' },
--     drain  = { periodSec=10, healPct=3 },                              -- self-heal % max HP (anti-turtle)
--     phases = { { hp=75, action='adds',   count=3, addGroupId=..., addZoneId=210, addLevel=150, regen=120, msg='...' },
--                { hp=50, action='fury',   att=3000, haste=120, msg='...' },
--                { hp=25, action='nuke',   dmgPct=40, msg='...' },
--                { hp=10, action='enrage', att=8000, haste=250, msg='...' } },
--     doom   = { startHpp=15, dur=30, msg='marks you for death!' },      -- low-HP execute pressure
--   }
-----------------------------------
local M = {}

-- [mobId] = per-fight state table
local mechState = {}

-----------------------------------
-- Small geometry/broadcast helpers (mirrors RaidBoss).
-----------------------------------
local function dist2d(ax, az, bx, bz)
    local dx, dz = ax - bx, az - bz
    return math.sqrt(dx * dx + dz * dz)
end

-- Living players within `radius` of `entity` (pcall-guarded; entity may be dying).
local function playersNear(entity, radius)
    local out = {}
    local ok, zone = pcall(function() return entity:getZone() end)
    if not ok or not zone then return out end
    local okp, players = pcall(function() return zone:getPlayers() end)
    if not okp or not players then return out end
    local ex, ez
    if not pcall(function() ex, ez = entity:getXPos(), entity:getZPos() end) then return out end
    for _, p in pairs(players) do
        local okd = pcall(function()
            if p and p:getHP() > 0 and dist2d(ex, ez, p:getXPos(), p:getZPos()) <= radius then
                out[#out + 1] = p
            end
        end)
        if not okd then end
    end
    return out
end
M.playersNear = playersNear

local function shout(mob, msg, st)
    if not msg then return end
    local tag = (st and st.name) and ('[%s] '):format(st.name) or '[NM] '
    for _, p in ipairs(playersNear(mob, 80.0)) do
        pcall(function() p:printToPlayer(tag .. msg, xi.msg.channel.SYSTEM_3) end)
    end
end
M.shout = shout

-----------------------------------
-- addMod that won't overflow the engine's int16 modifier storage (max 32767).
-- The custom bosses already carry large BASE mods (ATT in the 20k+ range, REGEN
-- ~1000); a naive addMod on top can wrap to a huge NEGATIVE -> the boss hits for
-- ~0 (or heals backwards). Clamps the running total to `cap`. Returns how much
-- was actually added (so callers can peel exactly that much back off later).
-----------------------------------
local function safeAddMod(mob, modId, amount, cap)
    cap = cap or 32000
    local added = 0
    pcall(function()
        local cur  = mob:getMod(modId)
        local room = cap - cur
        local add  = math.min(amount, room)
        if add > 0 then
            mob:addMod(modId, add)
            added = add
        end
    end)
    return added
end
M.safeAddMod = safeAddMod

-----------------------------------
-- Stance dance: setMod is ABSOLUTE, so each swap just sets the stance's mods.
-----------------------------------
local function applyStance(mob, stanceCfg, idx, st)
    local stance = stanceCfg.stances and stanceCfg.stances[idx]
    if not stance then return end
    for modId, val in pairs(stance.mods or {}) do
        pcall(function() mob:setMod(modId, val) end)
    end
    shout(mob, stance.msg, st)
end

-----------------------------------
-- AoE pulse: a chunk of every nearby player's MAX HP. dmgPct is % (hardcore: 20-45).
-----------------------------------
local function aoePulse(mob, aoeCfg, st)
    local radius = aoeCfg.radius or 30.0
    for _, p in ipairs(playersNear(mob, radius)) do
        pcall(function()
            local dmg = math.floor(p:getMaxHP() * (aoeCfg.dmgPct or 20) / 100)
            if dmg > 0 then
                p:takeDamage(dmg, mob, xi.attackType.SPECIAL, xi.damageType.ELEMENTAL)
            end
        end)
    end
    shout(mob, aoeCfg.msg, st)
end

-----------------------------------
-- CC pulse: a status effect on every nearby player (terror/silence/amnesia/etc.).
-----------------------------------
local function ccPulse(mob, ccCfg, st)
    local radius = ccCfg.radius or 25.0
    for _, p in ipairs(playersNear(mob, radius)) do
        pcall(function()
            p:addStatusEffect(ccCfg.effect or xi.effect.TERROR, ccCfg.power or 1, 0, ccCfg.dur or 5)
        end)
    end
    shout(mob, ccCfg.msg, st)
end

-----------------------------------
-- Doom: a stacking-death mark on nearby players (they must out-DPS / cleanse).
-----------------------------------
local function applyDoom(mob, doomCfg, st)
    local radius = doomCfg.radius or 30.0
    for _, p in ipairs(playersNear(mob, radius)) do
        pcall(function()
            if not p:hasStatusEffect(xi.effect.DOOM) then
                p:addStatusEffect(xi.effect.DOOM, 1, 3, doomCfg.dur or 30)
            end
        end)
    end
    shout(mob, doomCfg.msg, st)
end

-----------------------------------
-- Add-spawning (RaidBoss tendril pattern). Fresh set per call; while ANY of this
-- set lives the boss regens hard. addGroupId/addZoneId/addLevel come from the phase.
-----------------------------------
local function spawnAdds(mob, phase, st)
    if not st then return end
    st.addsAlive = {}   -- fresh set (a stale ref = map crash)
    local ok, zone = pcall(function() return mob:getZone() end)
    if not ok or not zone or not phase.addGroupId then return end
    local bx, by, bz
    if not pcall(function() bx, by, bz = mob:getXPos(), mob:getYPos(), mob:getZPos() end) then return end

    for _ = 1, (phase.count or 2) do
        local angle = math.random() * math.pi * 2
        local d     = 6.0 + math.random() * 4.0
        local mx, mz = bx + math.cos(angle) * d, bz + math.sin(angle) * d
        local add = zone:insertDynamicEntity({
            objtype              = xi.objType.MOB,
            groupId              = phase.addGroupId,
            groupZoneId          = phase.addZoneId or 210,
            name                 = phase.addName or 'Servitor',
            x = mx, y = by, z = mz,
            rotation             = math.random(0, 255),
            minLevel             = phase.addLevel or 150,
            maxLevel             = phase.addLevel or 150,
            detection            = xi.detects.SIGHT_AND_HEARING,
            isAggroable          = true,
            releaseIdOnDisappear = true,
            onMobDeath = function(deadAdd, killer)
                if not st.addsAlive then return end
                st.addsAlive[deadAdd:getID()] = nil
                for _ in pairs(st.addsAlive) do return end   -- some still alive
                if st.regenActive then                       -- last add down -> peel the boost
                    st.regenActive = false
                    pcall(function() mob:addMod(xi.mod.REGEN, -(st.addedRegen or 0)) end)
                    st.addedRegen = 0
                    shout(mob, 'The last servitor falls -- its wounds stay open!', st)
                end
            end,
        })
        if add then
            pcall(function()
                add:setSpawn(mx, by, mz, 0)
                add:spawn()
                add:setMobMod(xi.mobMod.NO_CAPACITY_POINTS, 1)
                add:setMobMod(xi.mobMod.NO_DROPS, 1)
            end)
            st.addsAlive[add:getID()] = add
        end
    end

    if phase.regen then
        st.regenActive = true
        -- addMod (not setMod) so the boss's BASE regen survives -- the adds add a
        -- heal-pressure layer on top, clamped to int16 and peeled back off (exactly
        -- what was added) when the last add dies. Tracks the ACTUAL delta so a
        -- clamp or a second overlapping adds-phase can't desync the removal.
        st.addedRegen = (st.addedRegen or 0) + safeAddMod(mob, xi.mod.REGEN, phase.regen)
    end
end

-----------------------------------
-- HP-phase dispatcher.
-----------------------------------
local function firePhase(mob, phase, st)
    if phase.message or phase.msg then shout(mob, phase.message or phase.msg, st) end
    local act = phase.action
    if act == 'adds' then
        spawnAdds(mob, phase, st)
    elseif act == 'fury' then
        safeAddMod(mob, xi.mod.ATT, phase.att or 2500)
        pcall(function() mob:addMod(xi.mod.HASTE_GEAR, phase.haste or 100) end)
    elseif act == 'dispel' then
        for _, p in ipairs(playersNear(mob, phase.radius or 30.0)) do
            for _ = 1, (phase.count or 3) do
                pcall(function() p:dispelStatusEffect() end)
            end
        end
    elseif act == 'nuke' then
        aoePulse(mob, { dmgPct = phase.dmgPct or 35, radius = phase.radius, msg = nil }, st)
    elseif act == 'heal' then
        pcall(function() mob:addHP(math.floor(mob:getMaxHP() * (phase.healPct or 15) / 100)) end)
    elseif act == 'enrage' then
        st.enraged = true
        safeAddMod(mob, xi.mod.ATT, phase.att or 6000)
        pcall(function() mob:addMod(xi.mod.HASTE_GEAR, phase.haste or 200) end)
    elseif act == 'doom' then
        applyDoom(mob, { dur = phase.dur or 30, radius = phase.radius }, st)
    elseif act == 'terror' then
        ccPulse(mob, { effect = phase.effect or xi.effect.TERROR, dur = phase.dur or 6, radius = phase.radius }, st)
    end
end

-----------------------------------
-- PUBLIC: attach mechanics to a freshly-spawned mob (post-spawn, pre/post-claim).
-----------------------------------
function M.attach(mob, cfg)
    if not mob or not cfg then return end
    local id
    if not pcall(function() id = mob:getID() end) or not id then return end
    local now = os.time()
    mechState[id] = {
        cfg          = cfg,
        name         = cfg.name,
        startedAt    = now,
        firedPhases  = {},
        addsAlive    = {},
        stanceOn     = false,
        stanceIdx    = 0,
        nextStanceAt = nil,
        nextAoeAt    = cfg.aoe   and (now + (cfg.aoe.periodSec   or 12)) or nil,
        nextCcAt     = cfg.cc    and (now + (cfg.cc.periodSec    or 24)) or nil,
        nextDrainAt  = cfg.drain and (now + (cfg.drain.periodSec or 10)) or nil,
        enraged      = false,
        doomFired    = false,
        regenActive  = false,
    }
end

-----------------------------------
-- PUBLIC: combat-tick handler (call from the spawn def's onMobFight).
-----------------------------------
function M.tick(mob, target)
    local id
    if not pcall(function() id = mob:getID() end) or not id then return end
    local st = mechState[id]
    if not st then return end
    local cfg = st.cfg
    local now = os.time()
    local hpp = 100
    pcall(function() hpp = mob:getHPP() end)

    -- Soft enrage (time-based DPS check).
    if cfg.enrage and not st.enraged and now >= st.startedAt + (cfg.enrage.sec or 180) then
        st.enraged = true
        safeAddMod(mob, xi.mod.ATT, cfg.enrage.att or 4000)
        pcall(function() mob:addMod(xi.mod.HASTE_GEAR, cfg.enrage.haste or 150) end)
        shout(mob, cfg.enrage.msg, st)
    end

    -- Stance dance (physical/magical immunity windows).
    if cfg.stance and cfg.stance.stances then
        if not st.stanceOn and hpp <= (cfg.stance.startHpp or 100) then
            st.stanceOn     = true
            st.stanceIdx    = 1
            st.nextStanceAt = now + (cfg.stance.periodSec or 18)
            applyStance(mob, cfg.stance, 1, st)
        elseif st.stanceOn and st.nextStanceAt and now >= st.nextStanceAt then
            st.stanceIdx    = (st.stanceIdx % #cfg.stance.stances) + 1
            st.nextStanceAt = now + (cfg.stance.periodSec or 18)
            applyStance(mob, cfg.stance, st.stanceIdx, st)
        end
    end

    -- AoE pulse.
    if cfg.aoe and st.nextAoeAt and now >= st.nextAoeAt then
        st.nextAoeAt = now + (cfg.aoe.periodSec or 12)
        aoePulse(mob, cfg.aoe, st)
    end

    -- CC pulse.
    if cfg.cc and st.nextCcAt and now >= st.nextCcAt then
        st.nextCcAt = now + (cfg.cc.periodSec or 24)
        ccPulse(mob, cfg.cc, st)
    end

    -- Self-heal / lifesteal (anti-turtle pressure).
    if cfg.drain and st.nextDrainAt and now >= st.nextDrainAt then
        st.nextDrainAt = now + (cfg.drain.periodSec or 10)
        pcall(function() mob:addHP(math.floor(mob:getMaxHP() * (cfg.drain.healPct or 2) / 100)) end)
    end

    -- HP phases (catalog order; a big hit can fire several in one tick -- intended).
    if cfg.phases then
        for idx, phase in ipairs(cfg.phases) do
            if not st.firedPhases[idx] and hpp <= phase.hp then
                st.firedPhases[idx] = true
                pcall(function() firePhase(mob, phase, st) end)
            end
        end
    end

    -- Doom at low HP (execute pressure).
    if cfg.doom and not st.doomFired and hpp <= (cfg.doom.startHpp or 15) then
        st.doomFired = true
        applyDoom(mob, cfg.doom, st)
    end
end

-----------------------------------
-- PUBLIC: free state + despawn this mob's adds (call from onMobDeath / on despawn).
-----------------------------------
function M.cleanup(mob)
    local id
    if not pcall(function() id = mob:getID() end) or not id then return end
    local st = mechState[id]
    if not st then return end
    mechState[id] = nil   -- clear BEFORE despawning leftovers
    for _, add in pairs(st.addsAlive or {}) do
        if type(add) == 'userdata' then
            pcall(function() if add:getHP() > 0 then add:setHP(0) end end)
        end
    end
end

return M
