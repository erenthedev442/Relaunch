-----------------------------------
-- Trust: Kukki-Chebukki
-- BLM/BLM. Day-element nukes only (ST I–V, -ga I–III, -aja, ele debuffs).
-- Lightsday: idle. Darksday: Sleepga I–II only. Low enemy HP: T1–T2 conserve.
-- Stays ~15' when not top enmity; no WS (Occult Acumen TP unused).
-- C-tier nuker (apprentice) — no kit inject. mbCap 10k.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local DIST_SAFE  = 15
local LOW_HP_PCT = 25

-- Day → single-target / -ga families, -aja, and elemental debuff.
local DAY_KIT =
{
    [xi.day.FIRESDAY] =
    {
        st     = xi.magic.spellFamily.FIRE,
        ga     = xi.magic.spellFamily.FIRAGA,
        ja     = xi.magic.spell.FIRAJA,
        st1    = xi.magic.spell.FIRE,
        st2    = xi.magic.spell.FIRE_II,
        dot    = xi.magic.spell.BURN,
        dotFx  = xi.effect.BURN,
    },
    [xi.day.ICEDAY] =
    {
        st     = xi.magic.spellFamily.BLIZZARD,
        ga     = xi.magic.spellFamily.BLIZZAGA,
        ja     = xi.magic.spell.BLIZZAJA,
        st1    = xi.magic.spell.BLIZZARD,
        st2    = xi.magic.spell.BLIZZARD_II,
        dot    = xi.magic.spell.FROST,
        dotFx  = xi.effect.FROST,
    },
    [xi.day.WINDSDAY] =
    {
        st     = xi.magic.spellFamily.AERO,
        ga     = xi.magic.spellFamily.AEROGA,
        ja     = xi.magic.spell.AEROJA,
        st1    = xi.magic.spell.AERO,
        st2    = xi.magic.spell.AERO_II,
        dot    = xi.magic.spell.CHOKE,
        dotFx  = xi.effect.CHOKE,
    },
    [xi.day.EARTHSDAY] =
    {
        st     = xi.magic.spellFamily.STONE,
        ga     = xi.magic.spellFamily.STONEGA,
        ja     = xi.magic.spell.STONEJA,
        st1    = xi.magic.spell.STONE,
        st2    = xi.magic.spell.STONE_II,
        dot    = xi.magic.spell.RASP,
        dotFx  = xi.effect.RASP,
    },
    [xi.day.LIGHTNINGDAY] =
    {
        st     = xi.magic.spellFamily.THUNDER,
        ga     = xi.magic.spellFamily.THUNDAGA,
        ja     = xi.magic.spell.THUNDAJA,
        st1    = xi.magic.spell.THUNDER,
        st2    = xi.magic.spell.THUNDER_II,
        dot    = xi.magic.spell.SHOCK,
        dotFx  = xi.effect.SHOCK,
    },
    [xi.day.WATERSDAY] =
    {
        st     = xi.magic.spellFamily.WATER,
        ga     = xi.magic.spellFamily.WATERGA,
        ja     = xi.magic.spell.WATERJA,
        st1    = xi.magic.spell.WATER,
        st2    = xi.magic.spell.WATER_II,
        dot    = xi.magic.spell.DROWN,
        dotFx  = xi.effect.DROWN,
    },
}

local MODE_IDLE     = 0
local MODE_DARK     = 1
local MODE_NUKE     = 2
local MODE_CONSERVE = 3

local function hasTopEnmity(mob)
    local battleTarget = mob:getTarget()
    if not battleTarget then
        return false
    end

    local hateTarget = battleTarget:getTarget()
    return hateTarget ~= nil and hateTarget:getID() == mob:getID()
end

local function installIdle(mob)
    mob:removeAllGambits()
    mob:setMagicCastingEnabled(false)
end

local function installDark(mob)
    mob:removeAllGambits()
    mob:setMagicCastingEnabled(true)
    mob:addGambit(ai.t.TARGET, {
        { ai.c.NOT_STATUS, xi.effect.SLEEP_I },
        { ai.c.NOT_STATUS, xi.effect.SLEEP_II },
    }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.SLEEPGA })
end

local function installNuke(mob, kit, conserve)
    mob:removeAllGambits()
    mob:setMagicCastingEnabled(true)

    -- Keep the day's elemental debuff up.
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, kit.dotFx }, { ai.r.MA, ai.s.SPECIFIC, kit.dot }, 60)

    if conserve then
        -- Low enemy HP: T1–T2 only (ai.s.LOWEST is unimplemented).
        mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.SPECIFIC, kit.st2 }, 12)
        mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.SPECIFIC, kit.st1 }, 12)
    else
        mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.HIGHEST, kit.ga }, 18)
        mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.SPECIFIC, kit.ja }, 30)
        mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.HIGHEST, kit.st }, 18)
    end
end

local function applyMode(mob, mode, kit)
    if mode == MODE_IDLE then
        installIdle(mob)
    elseif mode == MODE_DARK then
        installDark(mob)
    elseif mode == MODE_CONSERVE and kit then
        installNuke(mob, kit, true)
    elseif kit then
        installNuke(mob, kit, false)
    else
        installIdle(mob)
    end

    mob:setLocalVar('kukkiMode', mode)
end

local function resolveMode()
    local day = VanadielDayOfTheWeek()
    if day == xi.day.LIGHTSDAY then
        return MODE_IDLE, nil
    end

    if day == xi.day.DARKSDAY then
        return MODE_DARK, nil
    end

    return MODE_NUKE, DAY_KIT[day]
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.MAKKI_CHEBUKKI] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.CHERUKIKI] = xi.trust.messageOffset.TEAMWORK_2,
    })

    -- Modest FC (C apprentice scaler already contributes); Shantotto-like cadence.
    mob:addMod(xi.mod.FASTCAST, 25)
    mob:addMod(xi.mod.MACC, 40)
    -- Occult Acumen from BLM traits; reinforce so nukes feed unused TP.
    mob:addMod(xi.mod.OCCULT_ACUMEN, 50)

    mob:setAutoAttackEnabled(false)
    mob:setMobAbilityEnabled(false)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, DIST_SAFE)

    local mode, kit = resolveMode()
    applyMode(mob, mode, kit)

    mob:addListener('COMBAT_TICK', 'KUKKI_DAY_AI', function(mobArg)
        local wantMode, wantKit = resolveMode()

        -- Conserve MP with T1–T2 when the enemy is nearly dead.
        if wantMode == MODE_NUKE then
            local battleTarget = mobArg:getTarget()
            if battleTarget and battleTarget:isAlive() and battleTarget:getHPP() < LOW_HP_PCT then
                wantMode = MODE_CONSERVE
            end
        end

        if mobArg:getLocalVar('kukkiMode') ~= wantMode then
            applyMode(mobArg, wantMode, wantKit)
        end

        -- ~15' when not holding hate; close up if he pulls enmity.
        if hasTopEnmity(mobArg) then
            mobArg:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
        else
            mobArg:setMobMod(xi.mobMod.TRUST_DISTANCE, DIST_SAFE)
        end
    end)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
