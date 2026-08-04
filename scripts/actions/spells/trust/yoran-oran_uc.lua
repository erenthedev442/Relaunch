-----------------------------------
-- Trust: Yoran-Oran UC
-- Spell ID: 980 | Pool ID: 5980
-- WHM/BLM. A-tier support healer — no kit inject; scaler owns cure path.
-- Retail: Afflatus Solace, Cure I–VI, Protectra/Shellra, -na, Erase, Stoneskin.
-- Regain 50, no AA / no enemy casts. Standback ~15'.
-- Nott (listener, low priority) restores MP; may keep curing at 3000 TP.
-- Cure Potency locked at retail 50% cap (not package+50). Mid Unity MP+20%.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_NOTT        = 3502
local DIST_SAFE      = 15
local NOTT_MPP       = 66 -- SE-style: Nott when MP below 66%
local NOTT_MPP_FORCE = 15 -- Prefer Nott when nearly dry (break Cure spam)

local function isWearingYoranShirt(player)
    return player:getEquipID(xi.slot.BODY) == xi.item.YORAN_ORAN_UNITY_SHIRT
end

local function canAct(mobArg)
    if not mobArg:isEngaged() then
        return false
    end

    local action = mobArg:getCurrentAction()
    return action == xi.action.category.NONE or action == xi.action.category.BASIC_ATTACK
end

local function yellowCount(mob)
    local yellow = 0
    local master = mob:getMaster()
    if not master then
        return yellow
    end

    for _, member in pairs(master:getPartyWithTrusts() or {}) do
        if member:isAlive() and mob:checkDistance(member) <= 20 and member:getHPP() < 75 then
            yellow = yellow + 1
        end
    end

    return yellow
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    local master = mob:getMaster()
    if master and isWearingYoranShirt(master) then
        xi.trust.message(mob, xi.trust.messageOffset.TEAMWORK_1)
    else
        xi.trust.message(mob, xi.trust.messageOffset.SPAWN)
    end

    -- Retail identity within A-tier (scaler already owns FC/MND/MP/cure base).
    mob:addMod(xi.mod.REGAIN, 50)
    mob:addMod(xi.mod.MPP, 20) -- Unity mid-band (15–25%)
    mob:addMod(xi.mod.CONSERVE_MP, 25)
    -- Very high magic evasion / silence resist; sleep still lands occasionally.
    mob:addMod(xi.mod.MEVA, 120)
    mob:addMod(xi.mod.SILENCERES, 90)
    mob:addMod(xi.mod.STATUSRES, 40)
    mob:addMod(xi.mod.SLEEPRES, 25)

    -- Priority: Solace → triage → status → yellow → shields → stoneskin.
    -- Nott lives on COMBAT_TICK (lowest). Empty skill list so TP-before-gambit
    -- cannot steal cure priority (retail: may keep curing at 3000 TP until OOM).
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.AFFLATUS_SOLACE }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.AFFLATUS_SOLACE })

    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 25 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })

    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.DOOM }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.CURSE_I }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.PETRIFICATION }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STONA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SILENCE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.SILENA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.PARALYSIS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.PARALYNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.BLINDNESS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.BLINDNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.DISEASE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.VIRUNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.POISON }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.POISONA })
    mob:addGambit(ai.t.SELF, { ai.c.STATUS_FLAG, xi.effectFlag.ERASABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ERASE })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS_FLAG, xi.effectFlag.ERASABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ERASE })

    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 75 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.PROTECT }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.PROTECTRA })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.SHELL }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.SHELLRA })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.STONESKIN }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STONESKIN })

    mob:setAutoAttackEnabled(false)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, DIST_SAFE)

    mob:addListener('COMBAT_TICK', 'YORAN_UC_AI', function(mobArg)
        -- Lock cure potency at retail 50% cap after A-tier package applies.
        if
            mobArg:getLocalVar('yoranCureSet') == 0 and
            mobArg:getLocalVar('TrustPowerScaled') == 1
        then
            local cur = mobArg:getMod(xi.mod.CURE_POTENCY)
            if cur ~= 50 then
                mobArg:addMod(xi.mod.CURE_POTENCY, 50 - cur)
            end
            -- Keep CURE_POTENCY_II on A-tier path; trim runaway above ~12.
            local cur2 = mobArg:getMod(xi.mod.CURE_POTENCY_II)
            if cur2 > 12 then
                mobArg:addMod(xi.mod.CURE_POTENCY_II, 12 - cur2)
            end
            mobArg:setLocalVar('yoranCureSet', 1)
        end

        if not canAct(mobArg) then
            return
        end

        -- Nott: lowest priority. TP>=1000, MPP<66%, lvl>=50.
        -- Skip while party is yellow unless nearly dry (force path).
        local yellow = yellowCount(mobArg)
        local lvl = mobArg:getMainLvl()
        local tp = mobArg:getTP()
        local mpp = mobArg:getMPP()
        if
            lvl >= 50 and
            tp >= 1000 and
            mpp < NOTT_MPP and
            (yellow == 0 or mpp < NOTT_MPP_FORCE)
        then
            mobArg:useMobAbility(MS_NOTT, mobArg)
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
