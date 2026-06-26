-----------------------------------
-- BoomJob.lua
--
-- The custom job "Boom" (relaunch) on the repurposed Summoner slot (job 15):
-- a pet-less staff melee/hybrid DD whose elemental spells have a chance to
-- DETONATE for big bonus damage. See BOOM_JOB.md + boom_job_catalog.lua.
--
-- Pure Lua, no rebuild (EXCEPT the onJobChange hook, which needs the C++ event
-- added in 0x100_myroom_job.cpp + scripts/globals/player.lua -- see BOOM_JOB.md):
--   * Job traits applied while SMN is MAIN job; reconciled on login/zone AND
--     instantly on job change (addMod on enter, delMod on leave).
--   * The handful of nukes are granted (addSpell) + made castable via SQL.
--   * Detonation runs from a MAGIC_USE listener (boosted during !ignite).
--   * Abilities (!overload, !ignite) exposed as xi.boomJob.* for the commands.
-----------------------------------
require('modules/module_utils')

local C   = require('modules/custom/lua/boom_job_catalog')
local m   = Module:new('boom_job')
local SYS = xi.msg.channel.SYSTEM_3

-- Spell element -> damage type (so a blast resists/lands as its element).
local ELEM_DT =
{
    [xi.element.FIRE]    = xi.damageType.FIRE,
    [xi.element.ICE]     = xi.damageType.ICE,
    [xi.element.WIND]    = xi.damageType.WIND,
    [xi.element.EARTH]   = xi.damageType.EARTH,
    [xi.element.THUNDER] = xi.damageType.THUNDER,
    [xi.element.WATER]   = xi.damageType.WATER,
    [xi.element.LIGHT]   = xi.damageType.LIGHT,
    [xi.element.DARK]    = xi.damageType.DARK,
}

local boomSet = {}
for _, s in ipairs(C.spells) do boomSet[s.id] = true end

-- In-memory "are Boom's trait mods currently applied" flag, per player. A
-- zone-in wipes mods (reset to false in onGameIn); job change preserves standalone
-- addMods, so the flag drives delMod-on-leave / addMod-on-enter.
local applied = {}

local function isBoom(p) return p:getMainJob() == C.JOB end

local function applyTraits(p) for _, mv in ipairs(C.traits) do p:addMod(mv[1], mv[2]) end end
local function removeTraits(p) for _, mv in ipairs(C.traits) do p:delMod(mv[1], mv[2]) end end

local function grantSpells(p)
    for _, s in ipairs(C.spells) do
        if not p:hasSpell(s.id) then p:addSpell(s.id) end
    end
end

-- Bring the player's trait state in line with their current job.
local function reconcile(p)
    local name = p:getName()
    if isBoom(p) then
        if not applied[name] then
            applyTraits(p)
            grantSpells(p)
            applied[name] = true
        end
    else
        if applied[name] then
            removeTraits(p)
            applied[name] = false
        end
    end
end

-- Detonation damage = (INT*intMult + M.Atk*mattMult + base) * mult, capped.
local function boomDamage(caster, mult)
    local b = C.boom
    local d = (caster:getStat(xi.mod.INT) * b.intMult
            +  caster:getMod(xi.mod.MATT) * b.mattMult
            +  b.base) * (mult or 1)
    return math.max(1, math.min(math.floor(d), b.cap))
end

-- Deal a `dmg` blast of `element` to target (+ optional AoE), with enmity.
local function blast(caster, target, element, dmg, aoeRadius)
    if target == nil or target:isDead() then return end
    local dt  = ELEM_DT[element] or xi.damageType.FIRE
    local hit = math.min(dmg, target:getHP())
    target:takeDamage(hit, caster, xi.attackType.MAGICAL, dt)
    target:updateEnmityFromDamage(caster, hit)
    if aoeRadius and aoeRadius > 0 then
        local foes = caster:getEntitiesInRange(
            target, xi.aoeType.ROUND, xi.aoeRadius.TARGET, aoeRadius, 0, xi.targetType.ENEMY)
        for _, e in ipairs(foes) do
            if not e:isDead() and e:getID() ~= target:getID() then
                e:takeDamage(math.min(dmg, e:getHP()), caster, xi.attackType.MAGICAL, dt)
            end
        end
    end
end

-- Seconds remaining on a charVar cooldown (0 if ready).
local function cdLeft(p, var)
    local ok, now = pcall(os.time)
    if not ok then return 0 end
    return math.max(0, (p:getCharVar(var) or 0) - now)
end
local function setCd(p, var, secs)
    local ok, now = pcall(os.time)
    if ok then p:setCharVar(var, now + secs) end
end

-----------------------------------
-- Public API for the command files (!overload / !ignite).
-----------------------------------
xi.boomJob = xi.boomJob or {}
xi.boomJob.isBoom = isBoom

xi.boomJob.overload = function(p)
    if not isBoom(p) then
        p:printToPlayer('[Boom] Overload only works on the Boom job.', SYS); return
    end
    local a    = C.abilities.overload
    local left = cdLeft(p, a.cdVar)
    if left > 0 then
        p:printToPlayer(string.format('[Boom] Overload recasts in %ds.', left), SYS); return
    end
    local target = p:getTarget()
    if target == nil or target:isDead() then
        p:printToPlayer('[Boom] Overload needs a target -- engage an enemy first.', SYS); return
    end
    blast(p, target, a.element, boomDamage(p, a.mult), a.aoeRadius)
    setCd(p, a.cdVar, a.cd)
    p:printToPlayer(a.msg, SYS)
end

xi.boomJob.ignite = function(p)
    if not isBoom(p) then
        p:printToPlayer('[Boom] Ignite only works on the Boom job.', SYS); return
    end
    local a    = C.abilities.ignite
    local left = cdLeft(p, a.cdVar)
    if left > 0 then
        p:printToPlayer(string.format('[Boom] Ignite recasts in %ds.', left), SYS); return
    end
    -- Visible enspell buff (best-effort) + the boosted-detonation window.
    pcall(function() p:addStatusEffect(a.enspell, a.enspellPower, 0, a.duration) end)
    local ok, now = pcall(os.time)
    if ok then p:setCharVar(a.untilVar, now + a.duration) end
    setCd(p, a.cdVar, a.cd)
    p:printToPlayer(a.msg, SYS)
end

-----------------------------------
-- Login: reset the applied flag (zone wiped mods) then reconcile after the 3s
-- post-login stat finalization. Also register the detonation listener.
-----------------------------------
m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    applied[player:getName()] = false
    player:timer(3000, function(p) pcall(function() reconcile(p) end) end)

    player:addListener('MAGIC_USE', 'BOOM_EXPLODE', function(caster, target, spell, action)
        pcall(function()
            if not (isBoom(caster) and boomSet[spell:getID()]) then return end
            local chance = C.boom.chance
            local ok, now = pcall(os.time)
            if ok and (caster:getCharVar(C.abilities.ignite.untilVar) or 0) > now then
                chance = C.abilities.ignite.boostChance
            end
            if math.random(100) <= chance then
                blast(caster, target, spell:getElement(), boomDamage(caster, 1), C.boom.aoeRadius)
                caster:printToPlayer(C.boom.msg, SYS)
            end
        end)
    end)
end)

-----------------------------------
-- Job change: instant reconcile (apply on entering Boom, clear on leaving).
-- Requires the onJobChange event added in 0x100_myroom_job.cpp (rebuild).
-----------------------------------
m:addOverride('xi.player.onJobChange', function(player, prevMain, prevSub)
    if super then pcall(function() super(player, prevMain, prevSub) end) end
    pcall(function() reconcile(player) end)
end)

return m
