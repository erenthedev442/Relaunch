-----------------------------------
-- Trust: Apururu UC
-- Spell ID: 955 | Pool ID: 5955
-- WHM/RDM. S-tier CORE healer — no kit inject; scaler owns cure potency.
-- Regain 75, no AA / no enemy casts. Nott (listener) restores MP/HP.
-- Curaga on sleep or 3+ yellow; Haste master/self/melee DDs (not NIN).
-- Convert @ <10% MP; Devotion @ ally <20% MP; Martyr when silenced.
-- ~15' standback without hate. Devotion/Martyr close to ~10'.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_NOTT       = 3502
local DIST_SAFE     = 15
local DIST_JA       = 8 -- Devotion/Martyr retail range ~10.6'
local NOTT_MPP      = 66 -- SE: Nott when MP below 66%
local NOTT_MPP_FORCE = 15 -- Prefer Nott when nearly dry (break Cure spam)

-- Melee DD jobs that receive Haste (explicitly excludes NIN).
local HASTE_MELEE_JOBS =
{
    [xi.job.WAR] = true,
    [xi.job.MNK] = true,
    [xi.job.THF] = true,
    [xi.job.PLD] = true,
    [xi.job.DRK] = true,
    [xi.job.BST] = true,
    [xi.job.SAM] = true,
    [xi.job.DRG] = true,
    [xi.job.BLU] = true,
    [xi.job.PUP] = true,
    [xi.job.DNC] = true,
    [xi.job.RUN] = true,
}

local function isWearingApururuShirt(player)
    return player:getEquipID(xi.slot.BODY) == xi.item.APURURU_UNITY_SHIRT
end

local function canAct(mobArg)
    if not mobArg:isEngaged() then
        return false
    end

    local action = mobArg:getCurrentAction()
    return action == xi.action.category.NONE or action == xi.action.category.BASIC_ATTACK
end

local function hasTopEnmity(mob)
    local battleTarget = mob:getTarget()
    if not battleTarget then
        return false
    end

    local hateTarget = battleTarget:getTarget()
    return hateTarget ~= nil and hateTarget:getID() == mob:getID()
end

local function highestCuraga(mobArg)
    local lvl = mobArg:getMainLvl()
    if lvl >= 91 then
        return xi.magic.spell.CURAGA_V
    elseif lvl >= 71 then
        return xi.magic.spell.CURAGA_IV
    elseif lvl >= 51 then
        return xi.magic.spell.CURAGA_III
    elseif lvl >= 31 then
        return xi.magic.spell.CURAGA_II
    end

    return xi.magic.spell.CURAGA
end

local function yellowCount(mob)
    local yellow = 0
    local firstHurt = nil
    local master = mob:getMaster()
    if not master then
        return yellow, firstHurt
    end

    for _, member in pairs(master:getPartyWithTrusts() or {}) do
        if member:isAlive() and mob:checkDistance(member) <= 20 then
            if member:getHPP() < 75 then
                yellow = yellow + 1
                firstHurt = firstHurt or member
            end
        end
    end

    return yellow, firstHurt
end

local function castHasteOnMelee(mobArg)
    local master = mobArg:getMaster()
    if not master then
        return false
    end

    for _, member in pairs(master:getPartyWithTrusts() or {}) do
        if
            member:isAlive() and
            member:getID() ~= mobArg:getID() and
            member:getID() ~= master:getID() and
            not member:hasStatusEffect(xi.effect.HASTE) and
            HASTE_MELEE_JOBS[member:getMainJob()]
        then
            mobArg:castSpell(xi.magic.spell.HASTE, member)
            return true
        end
    end

    return false
end

-- Lowest-MPP ally under threshold (for Devotion).
local function findDevotionTarget(mobArg, mppCap)
    local master = mobArg:getMaster()
    if not master then
        return nil
    end

    local best, bestMpp = nil, 101
    for _, member in pairs(master:getPartyWithTrusts() or {}) do
        if
            member:isAlive() and
            member:getID() ~= mobArg:getID() and
            member:getMaxMP() > 0
        then
            local mpp = member:getMPP()
            if mpp < mppCap and mpp < bestMpp then
                best = member
                bestMpp = mpp
            end
        end
    end

    return best
end

-- Hurt ally for Martyr (HP heal when silenced).
local function findMartyrTarget(mobArg)
    local master = mobArg:getMaster()
    if not master then
        return nil
    end

    local best, bestHpp = nil, 101
    for _, member in pairs(master:getPartyWithTrusts() or {}) do
        if
            member:isAlive() and
            member:getID() ~= mobArg:getID()
        then
            local hpp = member:getHPP()
            if hpp < 75 and hpp < bestHpp then
                best = member
                bestHpp = hpp
            end
        end
    end

    return best
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    local master = mob:getMaster()
    if master and isWearingApururuShirt(master) then
        xi.trust.message(mob, xi.trust.messageOffset.TEAMWORK_2)
    else
        xi.trust.message(mob, xi.trust.messageOffset.SPAWN)
    end

    -- Priority: triage → status → yellow → shields → haste → stoneskin → convert.
    -- Nott / Devotion / Martyr / Curaga-3+ live on COMBAT_TICK (low vs gambit race
    -- handled by only firing when idle). Skill list stays empty so the engine's
    -- TP-before-gambit path cannot steal cure priority (retail Nott is lowest).

    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 25 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })

    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_I }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURAGA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_II }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURAGA })

    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.DOOM }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.CURSE_I }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.CURSE_II }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.BANE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.PETRIFICATION }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STONA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SILENCE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.SILENA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.PARALYSIS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.PARALYNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.BLINDNESS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.BLINDNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.DISEASE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.VIRUNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.POISON }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.POISONA })
    mob:addGambit(ai.t.SELF, { ai.c.STATUS_FLAG, xi.effectFlag.ERASABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ERASE })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS_FLAG, xi.effectFlag.ERASABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ERASE })

    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 75 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })

    mob:addGambit(ai.t.PARTY, { ai.c.NOT_STATUS, xi.effect.PROTECT }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.PROTECTRA })
    mob:addGambit(ai.t.PARTY, { ai.c.NOT_STATUS, xi.effect.SHELL }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.SHELLRA })

    mob:addGambit(ai.t.MASTER, { ai.c.NOT_STATUS, xi.effect.HASTE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.HASTE })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.HASTE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.HASTE })

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.STONESKIN }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STONESKIN })

    -- Convert only when nearly dry (retail <10%; safer than old 25%).
    mob:addGambit(ai.t.SELF, { ai.c.MPP_LT, 10 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.CONVERT })

    -- Regain fuels Nott only — no AA.
    mob:addMod(xi.mod.REGAIN, 75)
    mob:setAutoAttackEnabled(false)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, DIST_SAFE)

    mob:addListener('COMBAT_TICK', 'APURURU_UC_AI', function(mobArg)
        -- Positioning: 15' without hate; melee if she pulls; close for JA range.
        local devotionTarget = findDevotionTarget(mobArg, 20)
        local martyrTarget = nil
        if mobArg:hasStatusEffect(xi.effect.SILENCE) then
            martyrTarget = findMartyrTarget(mobArg)
        end

        if hasTopEnmity(mobArg) then
            mobArg:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
        elseif (devotionTarget and mobArg:checkDistance(devotionTarget) > DIST_JA) or
            (martyrTarget and mobArg:checkDistance(martyrTarget) > DIST_JA)
        then
            mobArg:setMobMod(xi.mobMod.TRUST_DISTANCE, DIST_JA)
        else
            mobArg:setMobMod(xi.mobMod.TRUST_DISTANCE, DIST_SAFE)
        end

        if not canAct(mobArg) then
            return
        end

        local yellow, hurt = yellowCount(mobArg)

        -- Curaga when 3+ yellow (sleep covered by gambits).
        if yellow >= 3 and hurt then
            mobArg:castSpell(highestCuraga(mobArg), hurt)
            return
        end

        -- Martyr: silenced + hurt ally in range (retail).
        if martyrTarget and mobArg:checkDistance(martyrTarget) <= 10.6 then
            mobArg:useJobAbility(xi.ja.MARTYR, martyrTarget)
            return
        end

        -- Devotion: ally <20% MP, in range.
        if
            devotionTarget and
            mobArg:getMainLvl() >= 75 and
            mobArg:checkDistance(devotionTarget) <= 10.6 and
            mobArg:getHPP() > 25
        then
            mobArg:useJobAbility(xi.ja.DEVOTION, devotionTarget)
            return
        end

        -- Haste other melee DDs (not NIN); master/self via gambits.
        if castHasteOnMelee(mobArg) then
            return
        end

        -- Nott: lowest priority. SE: TP>=1000, MPP<66%, lvl>=50.
        -- Skip while party is yellow unless nearly dry (force path).
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
