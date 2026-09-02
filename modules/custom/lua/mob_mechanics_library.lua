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
--     targetPartyOnly = true,                                             -- hostile pulses hit hate target's party only
--     damageMessages = true,                                              -- print direct scripted damage to each victim
--     aoe    = { periodSec=12, dmgPct=22, msg='unleashes a shockwave!' }, -- % of victim max HP
--     cc     = { periodSec=24, effect=xi.effect.TERROR, power=1, dur=5, msg='lets out a paralysing roar!' },
--     drain  = { periodSec=10, healPct=3 },                              -- self-heal % max HP (anti-turtle)
--     drain  = { periodSec=15, heal=10000 },                             -- fixed self-heal; takes precedence
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

-- Resolve a drain pulse without touching entity state. Fixed healing is useful
-- for encounters whose HP pools change independently of their intended regen.
function M.calculateDrainHeal(maxHp, drain)
    if drain.heal ~= nil then
        return math.floor(drain.heal)
    end

    return math.floor(maxHp * (drain.healPct or 2) / 100)
end

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

local function entityName(entity)
    local name
    if entity then
        pcall(function() name = entity:getName() end)
    end
    return name
end

local function entityId(entity)
    local id
    if entity then
        pcall(function() id = entity:getID() end)
    end
    return id
end

local function playerOwner(entity)
    if not entity then return nil end

    local okPc, isPc = pcall(function() return entity:isPC() end)
    if okPc and isPc then
        return entity
    end

    local owner
    pcall(function() owner = entity:getMaster() end)
    if owner then
        local okOwnerPc, ownerIsPc = pcall(function() return owner:isPC() end)
        if okOwnerPc and ownerIsPc then
            return owner
        end
    end

    return nil
end

-- Hostile mechanics can opt into hitting the current hate target's party,
-- instead of every unrelated player who happens to be near the mob.
local function mechanicPlayersNear(mob, target, radius, st)
    local nearby = playersNear(mob, radius)
    local ownerName = st and st.ownerName

    if ownerName then
        local out = {}
        for _, p in ipairs(nearby) do
            if entityName(p) == ownerName then
                out[#out + 1] = p
            end
        end
        return out
    end

    if not (st and st.targetPartyOnly) then
        return nearby
    end

    local owner = playerOwner(target)
    if not owner then
        return {}
    end

    local allowedIds = {}
    local allowedNames = {}
    local function allow(entity)
        local id = entityId(entity)
        local name = entityName(entity)
        if id then allowedIds[id] = true end
        if name then allowedNames[name] = true end
    end

    allow(owner)

    local okParty, party = pcall(function() return owner:getParty() end)
    if okParty and party then
        for _, member in ipairs(party) do
            allow(member)
        end
    end

    local out = {}
    for _, p in ipairs(nearby) do
        local id = entityId(p)
        local name = entityName(p)
        if (id and allowedIds[id]) or (name and allowedNames[name]) then
            out[#out + 1] = p
        end
    end

    return out
end
M.mechanicPlayersNear = mechanicPlayersNear

-- Set false to silence ALL boss mechanic telegraphs (the "[BossName] ..."
-- SYSTEM_3 shouts) across every NM system in one place -- this is the single
-- choke point every mechanic message routes through. Disabled 2026-06-23 by
-- owner request (chat clutter). Flip back to true to restore the telegraphs.
local SHOUTS_ENABLED = false

local function shout(mob, msg, st)
    if not SHOUTS_ENABLED and not (st and st.forceMessages) then return end
    if not msg then return end
    local tag   = (st and st.name) and ('[%s] '):format(st.name) or '[NM] '
    local owner = st and st.ownerName
    for _, p in ipairs(playersNear(mob, 80.0)) do
        pcall(function()
            if owner and p:getName() ~= owner then return end
            p:printToPlayer(tag .. msg, xi.msg.channel.SYSTEM_3)
        end)
    end
end
M.shout = shout

-- Some mechanics are instructions players must see to play correctly, even while
-- ambient boss shouts are disabled globally to avoid chat spam.
local function forcedMessage(mob, msg, st)
    if not msg then return end
    local tag   = (st and st.name) and ('[%s] '):format(st.name) or '[NM] '
    local owner = st and st.ownerName
    for _, p in ipairs(playersNear(mob, 80.0)) do
        pcall(function()
            if owner and p:getName() ~= owner then return end
            p:printToPlayer(tag .. msg, xi.msg.channel.SYSTEM_1)
        end)
    end
end

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
-- AoE pulse: a chunk of victim MAX HP. dmgPct is % (hardcore: 20-45).
-----------------------------------
local function aoePulse(mob, aoeCfg, st, target)
    local radius = aoeCfg.radius or 30.0
    for _, p in ipairs(mechanicPlayersNear(mob, target, radius, st)) do
        pcall(function()
            local dmg = math.floor(p:getMaxHP() * (aoeCfg.dmgPct or 20) / 100)
            if dmg > 0 then
                if aoeCfg.noEnmity then
                    p:takeDamage(dmg)
                else
                    p:takeDamage(dmg, mob, xi.attackType.SPECIAL, xi.damageType.ELEMENTAL)
                end
                if st and st.damageMessages then
                    p:printToPlayer(
                        string.format('[%s] Scripted shockwave hits you for %d damage.',
                            st.name or 'NM', dmg),
                        xi.msg.channel.SYSTEM_1)
                end
            end
        end)
    end
    shout(mob, aoeCfg.msg, st)
end

-----------------------------------
-- CC pulse: a status effect on selected victims (terror/silence/amnesia/etc.).
-----------------------------------
local function ccPulse(mob, ccCfg, st, target)
    local radius = ccCfg.radius or 25.0
    for _, p in ipairs(mechanicPlayersNear(mob, target, radius, st)) do
        pcall(function()
            p:addStatusEffect(ccCfg.effect or xi.effect.TERROR, ccCfg.power or 1, 0, ccCfg.dur or 5)
        end)
    end
    shout(mob, ccCfg.msg, st)
end

-----------------------------------
-- Doom: a stacking-death mark on selected victims (they must out-DPS / cleanse).
-----------------------------------
local function applyDoom(mob, doomCfg, st, target)
    local radius = doomCfg.radius or 30.0
    for _, p in ipairs(mechanicPlayersNear(mob, target, radius, st)) do
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
-- Hold-fire pressure phase (Prime Trial / Gauntlet bosses).
-- Boss telegraphs an unstable-energy window: strike the boss during the window
-- and the striker eats a 1-shot; hold fire and the boss enters exhaustion where
-- it stops attacking and eats bonus damage. During the warning window a
-- catalog-supplied "pressure" status effect ticks the whole party so the DPS
-- window is REAL: you have to survive the tick, not just idle-through. Reader
-- gates in TheGauntlet.lua (holdFireLocked) fire off Gauntlet_HoldFireActive /
-- Gauntlet_HoldFireExhausted local-vars set here.
-----------------------------------
local function setBossFrozen(mob, frozen)
    pcall(function() mob:setAutoAttackEnabled(not frozen) end)
    pcall(function() mob:setMagicCastingEnabled(not frozen) end)
    pcall(function() mob:setMobAbilityEnabled(not frozen) end)
    pcall(function() mob:setMobMod(xi.mobMod.NO_MOVE, frozen and 1 or 0) end)
end

local function setBossTpLocked(mob, locked)
    pcall(function() mob:setMobAbilityEnabled(not locked) end)
end

local function clearHoldFireTpLock(mob, st)
    if st and st.holdFireMobTpLocked then
        setBossTpLocked(mob, false)
    end
    if st then
        st.holdFireMobTpLocked  = false
        st.holdFireMobTpUnlockAt = nil
    end
end

local function holdFireDelay(holdCfg, isInitial)
    local fixed = isInitial and holdCfg.initialSec or holdCfg.periodSec
    local minDelay = isInitial and holdCfg.initialSecMin or holdCfg.periodSecMin
    local maxDelay = isInitial and holdCfg.initialSecMax or holdCfg.periodSecMax

    if minDelay and maxDelay then
        return math.random(minDelay, math.max(minDelay, maxDelay))
    end

    return fixed or 40
end

local function holdFirePressureTarget(mob, target, st)
    local ownerName = st and st.ownerName
    if ownerName then
        for _, player in ipairs(playersNear(mob, 80.0)) do
            if entityName(player) == ownerName then
                return player
            end
        end
    end

    return playerOwner(target) or target
end

local function clearHoldFirePressure(st)
    st.holdFirePressureTarget = nil
    st.holdFirePressureEffect = nil
    st.nextHoldFirePressureTick = nil
end

local function clearActionBlockingCc(target)
    if not target then return end

    pcall(function() target:delStatusEffectSilent(xi.effect.TERROR) end)
    pcall(function() target:delStatusEffectSilent(xi.effect.STUN) end)
    pcall(function() target:delStatusEffectSilent(xi.effect.SLEEP_I) end)
    pcall(function() target:delStatusEffectSilent(xi.effect.SLEEP_II) end)
    pcall(function() target:delStatusEffectSilent(xi.effect.PETRIFICATION) end)
    pcall(function() target:delStatusEffectSilent(xi.effect.GRADUAL_PETRIFICATION) end)
    pcall(function() target:delStatusEffectSilent(xi.effect.AMNESIA) end)
end

local function applyHoldFirePressure(mob, target, holdCfg, st, now)
    local pressure = holdCfg.pressure
    if holdCfg.pressureOptions and #holdCfg.pressureOptions > 0 then
        pressure = holdCfg.pressureOptions[math.random(1, #holdCfg.pressureOptions)]
    end

    if not pressure or not pressure.effect then
        clearHoldFirePressure(st)
        return
    end

    local pressureTarget = holdFirePressureTarget(mob, target, st)
    if not pressureTarget then
        clearHoldFirePressure(st)
        return
    end

    st.holdFirePressureTarget = pressureTarget
    st.holdFirePressureEffect = pressure.effect
    st.nextHoldFirePressureTick = now + (holdCfg.pressureDelaySec or holdCfg.pressureTickSec or 3)

    clearActionBlockingCc(pressureTarget)

    if pressure.effect == xi.effect.CURSE_I or pressure.effect == xi.effect.CURSE_II then
        st.curseGraceUntil = now + (holdCfg.curseGraceSec or holdCfg.pressureDelaySec or 5)
        pcall(function() mob:setLocalVar('Gauntlet_CurseGraceUntil', st.curseGraceUntil) end)
    end

    pcall(function()
        pressureTarget:addStatusEffect(pressure.effect, {
            power = pressure.power or 1,
            duration = holdCfg.warnSec or 15,
            origin = mob,
            tick = pressure.tick,
        })
    end)
end

local function tickHoldFirePressure(mob, holdCfg, st, now)
    if not st.nextHoldFirePressureTick or now < st.nextHoldFirePressureTick then
        return
    end

    if st.curseGraceUntil and now < st.curseGraceUntil then
        st.nextHoldFirePressureTick = st.curseGraceUntil
        return
    end

    local target = st.holdFirePressureTarget
    local effect = st.holdFirePressureEffect
    if not target or not effect then
        clearHoldFirePressure(st)
        return
    end

    local blocked = false
    pcall(function()
        blocked =
            target:hasStatusEffect(xi.effect.TERROR) or
            target:hasStatusEffect(xi.effect.STUN) or
            target:hasStatusEffect(xi.effect.SLEEP_I) or
            target:hasStatusEffect(xi.effect.SLEEP_II) or
            target:hasStatusEffect(xi.effect.PETRIFICATION) or
            target:hasStatusEffect(xi.effect.GRADUAL_PETRIFICATION) or
            target:hasStatusEffect(xi.effect.AMNESIA)
    end)
    if blocked then
        st.nextHoldFirePressureTick = now + 1
        return
    end

    local active = false
    pcall(function() active = target:hasStatusEffect(effect) end)
    if not active then
        clearHoldFirePressure(st)
        return
    end

    pcall(function()
        local damage = math.max(1, math.floor(target:getMaxHP() * (holdCfg.pressureTickPct or 20) / 100))
        target:takeDamage(damage, mob, xi.attackType.SPECIAL, xi.damageType.NONE)
    end)
    st.nextHoldFirePressureTick = now + (holdCfg.pressureTickSec or 3)
end

local function enterHoldFireExhaustion(mob, holdCfg, st, now)
    st.holdFireActive     = false
    st.holdFirePunished   = false
    st.holdFireDangerAt   = nil
    st.holdFireExhausted  = true
    st.holdFireExhaustEnd = now + (holdCfg.exhaustedSec or 20)
    clearHoldFirePressure(st)
    pcall(function()
        mob:setLocalVar('Gauntlet_HoldFireActive', 0)
        mob:setLocalVar('Gauntlet_HoldFireExhausted', 1)
    end)
    st.holdFireMods = {
        [xi.mod.DEF]  = -(holdCfg.defDown  or 0),
        [xi.mod.MDEF] = -(holdCfg.mdefDown or 0),
        [xi.mod.EVA]  = -(holdCfg.evaDown  or 0),
        [xi.mod.MEVA] = -(holdCfg.mevaDown or 0),
        [xi.mod.DMGRANGE] = holdCfg.rangedRelief or 0,
    }

    clearHoldFireTpLock(mob, st)
    if st.stanceOn then
        pcall(function() mob:setMod(xi.mod.DMGPHYS, 0) end)
        pcall(function() mob:setMod(xi.mod.DMGMAGIC, 0) end)
    end
    setBossFrozen(mob, true)
    for modId, amount in pairs(st.holdFireMods) do
        if amount ~= 0 then
            pcall(function() mob:addMod(modId, amount) end)
        end
    end

    forcedMessage(mob, holdCfg.successMsg or 'The boss is exhausted and its defenses falter!', st)
end

local function exitHoldFireExhaustion(mob, holdCfg, st, now)
    st.holdFireExhausted  = false
    st.holdFireExhaustEnd = nil

    clearHoldFireTpLock(mob, st)
    for modId, amount in pairs(st.holdFireMods or {}) do
        if amount ~= 0 then
            pcall(function() mob:addMod(modId, -amount) end)
        end
    end
    st.holdFireMods = nil

    setBossFrozen(mob, false)
    pcall(function() mob:setLocalVar('Gauntlet_HoldFireExhausted', 0) end)
    if st.stanceOn and st.cfg and st.cfg.stance then
        applyStance(mob, st.cfg.stance, st.stanceIdx or 1, st)
    end
    clearHoldFirePressure(st)
    st.nextHoldFireAt = now + holdFireDelay(holdCfg, false)
    forcedMessage(mob, holdCfg.recoverMsg or 'The boss recovers its strength.', st)
end

local function beginHoldFire(mob, target, holdCfg, st, now)
    st.holdFireActive   = true
    st.holdFirePunished = false
    st.holdFireDangerAt = now + (holdCfg.graceSec or 0)
    st.holdFireUntil    = now + (holdCfg.warnSec or 15)
    st.nextHoldFireAt   = nil
    if (holdCfg.mobNoTpSec or 0) > 0 then
        st.holdFireMobTpLocked   = true
        st.holdFireMobTpUnlockAt = now + holdCfg.mobNoTpSec
        setBossTpLocked(mob, true)
    end
    pcall(function()
        mob:setLocalVar('Gauntlet_HoldFireActive', 1)
        mob:setLocalVar('Gauntlet_HoldFireExhausted', 0)
    end)
    applyHoldFirePressure(mob, target, holdCfg, st, now)
    if st.nextCcAt then
        st.nextCcAt = now + (holdCfg.warnSec or 15) + (holdCfg.exhaustedSec or 20) + 3
    end
    forcedMessage(mob, holdCfg.warningMsg or 'The boss draws in unstable energy...', st)
end

-----------------------------------
-- HP-phase dispatcher.
-----------------------------------
local function firePhase(mob, phase, st, target)
    if phase.message or phase.msg then shout(mob, phase.message or phase.msg, st) end
    local act = phase.action
    if act == 'adds' then
        spawnAdds(mob, phase, st)
    elseif act == 'fury' then
        safeAddMod(mob, xi.mod.ATT, phase.att or 2500)
        pcall(function() mob:addMod(xi.mod.HASTE_GEAR, phase.haste or 100) end)
    elseif act == 'dispel' then
        for _, p in ipairs(mechanicPlayersNear(mob, target, phase.radius or 30.0, st)) do
            for _ = 1, (phase.count or 3) do
                pcall(function() p:dispelStatusEffect() end)
            end
        end
    elseif act == 'nuke' then
        aoePulse(mob, { dmgPct = phase.dmgPct or 35, radius = phase.radius, msg = nil }, st, target)
    elseif act == 'heal' then
        pcall(function() mob:addHP(math.floor(mob:getMaxHP() * (phase.healPct or 15) / 100)) end)
    elseif act == 'enrage' then
        st.enraged = true
        safeAddMod(mob, xi.mod.ATT, phase.att or 6000)
        pcall(function() mob:addMod(xi.mod.HASTE_GEAR, phase.haste or 200) end)
    elseif act == 'doom' then
        applyDoom(mob, { dur = phase.dur or 30, radius = phase.radius }, st, target)
    elseif act == 'terror' then
        ccPulse(mob, { effect = phase.effect or xi.effect.TERROR, dur = phase.dur or 6, radius = phase.radius }, st, target)
    end
end

-----------------------------------
-- PUBLIC: attach mechanics to a freshly-spawned mob (post-spawn, pre/post-claim).
-----------------------------------
function M.attach(mob, cfg, ownerName)
    if not mob or not cfg then return end
    local id
    if not pcall(function() id = mob:getID() end) or not id then return end
    local now = os.time()
    mechState[id] = {
        cfg          = cfg,
        name         = cfg.name,
        forceMessages = cfg.forceMessages == true,
        ownerName       = ownerName or nil,  -- when set, AoE/CC/shout only targets this player
        targetPartyOnly = cfg.targetPartyOnly == true,
        damageMessages  = cfg.damageMessages == true,
        startedAt       = now,
        firedPhases     = {},
        addsAlive       = {},
        stanceOn        = false,
        stanceIdx       = 0,
        nextStanceAt    = nil,
        nextAoeAt       = cfg.aoe   and (now + (cfg.aoe.periodSec   or 12)) or nil,
        nextCcAt        = cfg.cc    and (now + (cfg.cc.periodSec    or 24)) or nil,
        nextDrainAt     = cfg.drain and (now + (cfg.drain.periodSec or 10)) or nil,
        nextHoldFireAt  = cfg.holdFire and (now + holdFireDelay(cfg.holdFire, true)) or nil,
        enraged         = false,
        doomFired       = false,
        regenActive     = false,
    }

    -- Punish-on-strike for hold-fire windows. Once the boss begins holding fire
    -- (st.holdFireActive), any WS landed on the boss inside the window sets the
    -- striker's HP to 0. Grace + WEAPONSKILL_TAKE is a mob-side listener so it
    -- also catches Trust/pet WS through their owner via playerOwner.
    if cfg.holdFire then
        local listenerId = 'HOLD_FIRE_WS_' .. tostring(id)
        pcall(function() mob:removeListener(listenerId) end)
        mob:addListener('WEAPONSKILL_TAKE', listenerId, function(user, targetMob, skill, tp, action)
            local st = mechState[id]
            if not st or not st.holdFireActive or st.holdFirePunished then return end

            local striker = playerOwner(user) or user
            if st.ownerName and entityName(striker) ~= st.ownerName then return end

            local now = os.time()
            if st.holdFireDangerAt and now < st.holdFireDangerAt then return end

            local holdCfg = st.cfg.holdFire or {}
            st.holdFirePunished = true
            st.holdFireActive   = false
            st.holdFireUntil    = nil
            st.holdFireDangerAt = nil
            clearHoldFireTpLock(mob, st)
            clearHoldFirePressure(st)
            st.nextHoldFireAt   = now + holdFireDelay(holdCfg, false)

            forcedMessage(mob, holdCfg.failMsg or 'The gathered power erupts without mercy.', st)
            pcall(function()
                striker:setHP(0)
            end)
        end)
    end
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

    -- Hold-fire warning / exhaustion reward. During exhaustion, suppress the rest
    -- of the scripted kit so the player gets a real punish window.
    if cfg.holdFire then
        if st.holdFireExhausted then
            if st.holdFireExhaustEnd and now >= st.holdFireExhaustEnd then
                exitHoldFireExhaustion(mob, cfg.holdFire, st, now)
            else
                return
            end
        end

        if st.holdFireActive then
            if st.holdFireMobTpLocked and st.holdFireMobTpUnlockAt and now >= st.holdFireMobTpUnlockAt then
                clearHoldFireTpLock(mob, st)
            end
            tickHoldFirePressure(mob, cfg.holdFire, st, now)
        end

        if st.holdFireActive and st.holdFireUntil and now >= st.holdFireUntil then
            enterHoldFireExhaustion(mob, cfg.holdFire, st, now)
            return
        elseif st.nextHoldFireAt and now >= st.nextHoldFireAt then
            beginHoldFire(mob, target, cfg.holdFire, st, now)
        end
    end

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
        aoePulse(mob, cfg.aoe, st, target)
    end

    -- CC pulse.
    if cfg.cc and st.nextCcAt and now >= st.nextCcAt then
        st.nextCcAt = now + (cfg.cc.periodSec or 24)
        ccPulse(mob, cfg.cc, st, target)
    end

    -- Self-heal / lifesteal (anti-turtle pressure).
    if cfg.drain and st.nextDrainAt and now >= st.nextDrainAt then
        st.nextDrainAt = now + (cfg.drain.periodSec or 10)
        pcall(function()
            mob:addHP(M.calculateDrainHeal(mob:getMaxHP(), cfg.drain))
        end)
    end

    -- HP phases (catalog order; a big hit can fire several in one tick -- intended).
    if cfg.phases then
        for idx, phase in ipairs(cfg.phases) do
            if not st.firedPhases[idx] and hpp <= phase.hp then
                st.firedPhases[idx] = true
                pcall(function() firePhase(mob, phase, st, target) end)
            end
        end
    end

    -- Doom at low HP (execute pressure).
    if cfg.doom and not st.doomFired and hpp <= (cfg.doom.startHpp or 15) then
        st.doomFired = true
        applyDoom(mob, cfg.doom, st, target)
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
