-----------------------------------
-- Trust: Ygnas
-- S-tier WHM/PLD healer. Cure III (MP-efficient) / Cure VI triage.
-- Unique WS: Sacred Caper / Phototrophic Blessing / Wrath / Deific Gambol.
-- No AA; holds TP to 3000 unless party has taken damage (Selh'teus-like).
-- Identity: Cure Potency +50%, FC +50%, Cure→MP 5%, Regain 30, HP/MP +10%.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_GAMBOL = 3815

local function setHoldTP(mobArg)
    mobArg:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 3000)
end

local function setDumpTP(mobArg)
    -- Party damaged: allow WS from 1000 (still prefer closers if SC open).
    mobArg:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 1000)
end

local function tryArcielaRefreshAura(mob)
    local master = mob:getMaster()
    if not master then
        return
    end

    for _, member in pairs(master:getPartyWithTrusts() or {}) do
        if member:getObjType() == xi.objType.TRUST then
            local id = member:getTrustID()
            if id == xi.magic.spell.ARCIELA or id == xi.magic.spell.ARCIELA_II then
                mob:addStatusEffect(xi.effect.COLURE_ACTIVE, {
                    power = 6,
                    tick = 3,
                    origin = mob,
                    subType = xi.effect.GEO_REFRESH,
                    subPower = 2,
                    tier = xi.auraTarget.ALLIES,
                    flag = xi.effectFlag.AURA,
                })
                return
            end
        end
    end
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.ARCIELA]    = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.ARCIELA_II] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.MORIMAR]    = xi.trust.messageOffset.TEAMWORK_2,
        [xi.magic.spell.DARRCUILN]  = xi.trust.messageOffset.TEAMWORK_3,
        [xi.magic.spell.TEODOR]     = xi.trust.messageOffset.TEAMWORK_4,
    })

    -- Retail identity mods (S-tier support package owns the rest).
    mob:addMod(xi.mod.CURE_POTENCY, 50)
    mob:addMod(xi.mod.FASTCAST, 50)
    mob:addMod(xi.mod.REGAIN, 30)
    mob:addMod(xi.mod.CURE2MP_PERCENT, 5)
    mob:addMod(xi.mod.HPP, 10)
    mob:addMod(xi.mod.MPP, 10)
    mob:addMod(xi.mod.BEAST_KILLER, 50)

    -- Status first.
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_I }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_II }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.POISON }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.POISONA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.PARALYSIS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.PARALYNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.BLINDNESS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.BLINDNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SILENCE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.SILENA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.PETRIFICATION }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STONA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.DISEASE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.VIRUNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.CURSE_I }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS_FLAG, xi.effectFlag.ERASABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ERASE })
    mob:addGambit(ai.t.SELF, { ai.c.STATUS_FLAG, xi.effectFlag.ERASABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ERASE })

    -- Cure VI (or highest available) under 45%; Cure III for tank yellow / party orange.
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 45 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })
    mob:addGambit(ai.t.TANK, { ai.c.HPP_LT, 75 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURE_III })
    mob:addGambit(ai.t.TOP_ENMITY, { ai.c.HPP_LT, 75 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURE_III })
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 66 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURE_III })
    -- Leveling fallback before Cure III is learned.
    mob:addGambit(ai.t.TANK, { ai.c.HPP_LT, 75 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 66 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })

    mob:addGambit(ai.t.PARTY, { ai.c.NOT_STATUS, xi.effect.PROTECT }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.PROTECTRA })
    mob:addGambit(ai.t.PARTY, { ai.c.NOT_STATUS, xi.effect.SHELL }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.SHELLRA })
    mob:addGambit(ai.t.MELEE, { ai.c.NOT_STATUS, xi.effect.HASTE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.HASTE })

    mob:setAutoAttackEnabled(false)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.LONG_RANGE)

    setHoldTP(mob)
    tryArcielaRefreshAura(mob)

    local master = mob:getMaster()
    local dmgListener = 'YGNAS_PARTY_DMG_' .. mob:getID()

    if master then
        -- Master damage is the reliable Selh'teus-style dump signal.
        master:addListener('TAKE_DAMAGE', dmgListener, function(_, amount)
            if amount and amount > 0 and mob:isAlive() then
                setDumpTP(mob)
            end
        end)
    end

    mob:addListener('WEAPONSKILL_USE', 'YGNAS_WS', function(mobArg, target, skill)
        setHoldTP(mobArg)
        if skill and skill:getID() == MS_GAMBOL then
            if math.random(1, 100) <= 25 then
                xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_1)
            end
        end
    end)
end

local function cleanup(mob)
    local master = mob:getMaster()
    if master then
        master:removeListener('YGNAS_PARTY_DMG_' .. mob:getID())
    end
end

spellObject.onMobDespawn = function(mob)
    cleanup(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    cleanup(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
