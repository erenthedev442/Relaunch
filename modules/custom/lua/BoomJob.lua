-----------------------------------
-- BoomJob.lua
--
-- The custom job "Boom" (relaunch) on the repurposed Summoner slot (job 15):
-- a pet-less staff melee/hybrid DD whose elemental spells have a small chance to
-- DETONATE for big bonus damage. See BOOM_JOB.md + boom_job_catalog.lua.
--
-- Pure Lua, no rebuild:
--   * Job traits (incl. Staff + Elemental skill) applied via addMod while SMN is
--     the MAIN job, re-applied on onGameIn (3s defer) -- Cross-Job Trait pattern.
--   * The handful of nukes are granted (addSpell) and made castable by the slot
--     via boom_job_spells.sql (jobs-blob byte 15).
--   * Detonation runs from a MAGIC_USE listener (reads live; idempotent by name).
--
-- Needs ONE relaunch map restart to load (addOverride module).
-----------------------------------
require('modules/module_utils')

local C   = require('modules/custom/lua/boom_job_catalog')
local m   = Module:new('boom_job')
local SYS = xi.msg.channel.SYSTEM_3

-- Spell element -> damage type (so the blast resists/lands as its element).
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

-- Fast lookup of the Boom spell ids.
local boomSet = {}
for _, s in ipairs(C.spells) do boomSet[s.id] = true end

local function isBoom(p) return p:getMainJob() == C.JOB end

local function applyTraits(p)
    for _, mv in ipairs(C.traits) do
        p:addMod(mv[1], mv[2])
    end
end

local function grantSpells(p)
    for _, s in ipairs(C.spells) do
        if not p:hasSpell(s.id) then
            p:addSpell(s.id)
        end
    end
end

-- The detonation: a big bonus magic hit of the spell's element.
local function detonate(caster, target, spell)
    if target == nil or target:isDead() then return end
    local b   = C.boom
    local dmg = math.floor(caster:getStat(xi.mod.INT) * b.intMult
                         + caster:getMod(xi.mod.MATT) * b.mattMult
                         + b.base)
    dmg = math.max(1, math.min(dmg, b.cap))
    local dt  = ELEM_DT[spell:getElement()] or xi.damageType.FIRE

    local hit = math.min(dmg, target:getHP())
    target:takeDamage(hit, caster, xi.attackType.MAGICAL, dt)
    target:updateEnmityFromDamage(caster, hit)
    caster:printToPlayer(string.format('%s (+%d)', b.msg, hit), SYS)

    if b.aoeRadius and b.aoeRadius > 0 then
        local foes = caster:getEntitiesInRange(
            target, xi.aoeType.ROUND, xi.aoeRadius.TARGET, b.aoeRadius, 0, xi.targetType.ENEMY)
        for _, e in ipairs(foes) do
            if not e:isDead() and e:getID() ~= target:getID() then
                e:takeDamage(math.min(dmg, e:getHP()), caster, xi.attackType.MAGICAL, dt)
            end
        end
    end
end

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)

    -- Traits + granted spells only while Boom is the MAIN job. Deferred 3s so
    -- post-login stat finalization doesn't clobber the addMods.
    player:timer(3000, function(p)
        pcall(function()
            if isBoom(p) then
                applyTraits(p)
                grantSpells(p)
            end
        end)
    end)

    -- Detonation listener: registered for everyone, no-ops unless the caster is
    -- currently Boom and the spell is one of ours (so it survives job swaps).
    player:addListener('MAGIC_USE', 'BOOM_EXPLODE', function(caster, target, spell, action)
        pcall(function()
            if isBoom(caster) and boomSet[spell:getID()]
               and math.random(100) <= C.boom.chance then
                detonate(caster, target, spell)
            end
        end)
    end)
end)

return m
