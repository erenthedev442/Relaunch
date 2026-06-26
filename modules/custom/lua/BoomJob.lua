-----------------------------------
-- BoomJob.lua
--
-- The custom job "Boom" (relaunch) on the repurposed Summoner slot (job 15):
-- a pet-less staff melee/hybrid DD whose elemental spells have a chance to
-- DETONATE for big bonus damage. See BOOM_JOB.md + boom_job_catalog.lua.
--
-- EVERYTHING is driven by CASTING real spells -- no chat commands:
--   * Tier-III nukes -> small detonation. Ancient Magic (Flare/Freeze/...) ->
--     big detonation + blast. Detonation is per-spell (chance/mult).
--   * Casting an ENSPELL is "Ignite": opens a window where detonation chance is
--     boosted (the enspell's own melee enchant supports the hybrid).
--   * All run from one MAGIC_USE listener.
--
-- Job traits (incl. Staff + Elemental skill) are applied via addMod while SMN is
-- the MAIN job, reconciled on login/zone AND instantly on job change (the C++
-- onJobChange hook -- see BOOM_JOB.md; that part needs a rebuild). No skill_caps
-- or grades.cpp touch.
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

-- spellid -> per-spell detonation config; and the set of enspell ids.
local nukeCfg   = {}
for _, s in ipairs(C.spells) do nukeCfg[s.id] = s end
local enspellSet = {}
for _, id in ipairs(C.enspells) do enspellSet[id] = true end

local function isBoom(p) return p:getMainJob() == C.JOB end

local function applyTraits(p) for _, mv in ipairs(C.traits) do p:addMod(mv[1], mv[2]) end end
local function removeTraits(p) for _, mv in ipairs(C.traits) do p:delMod(mv[1], mv[2]) end end

local function grantSpells(p)
    for _, s in ipairs(C.spells) do
        if not p:hasSpell(s.id) then p:addSpell(s.id) end
    end
    for _, id in ipairs(C.enspells) do
        if not p:hasSpell(id) then p:addSpell(id) end
    end
end

-- In-memory "Boom trait mods currently applied" flag, per player. A zone-in
-- wipes mods (reset to false in onGameIn); a job change preserves standalone
-- addMods, so the flag drives delMod-on-leave / addMod-on-enter.
local applied = {}

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

-- Fires on every spell cast; gives Boom's spells their special behavior.
local function onBoomCast(caster, target, spell)
    if not isBoom(caster) then return end
    local id = spell:getID()

    -- Casting an enspell = Ignite: open the boosted-detonation window. (The
    -- engine applies the actual enspell separately.)
    if enspellSet[id] then
        local ok, now = pcall(os.time)
        if ok then caster:setCharVar(C.ignite.untilVar, now + C.ignite.duration) end
        caster:printToPlayer(C.ignite.msg, SYS)
        return
    end

    local cfg = nukeCfg[id]
    if not cfg then return end

    local chance = cfg.chance
    local ok, now = pcall(os.time)
    if ok and (caster:getCharVar(C.ignite.untilVar) or 0) > now then
        chance = math.max(chance, C.ignite.boostChance)
    end

    if math.random(100) <= chance then
        blast(caster, target, spell:getElement(), boomDamage(caster, cfg.mult), cfg.aoe or C.boom.aoeRadius)
        caster:printToPlayer(C.boom.msg, SYS)
    end
end

-----------------------------------
-- Login: reset the applied flag (zone wiped mods), reconcile after the 3s
-- post-login stat finalization, and register the cast listener.
-----------------------------------
m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    applied[player:getName()] = false
    player:timer(3000, function(p) pcall(function() reconcile(p) end) end)

    player:addListener('MAGIC_USE', 'BOOM_EXPLODE', function(caster, target, spell, action)
        pcall(function() onBoomCast(caster, target, spell) end)
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
