-----------------------------------
-- Trust: Iroha II
-- SAM/WHM. Great Katana. Protectra V / Shellra V / Flare II.
-- Abilities: Hasso, Meditate, Third Eye, Save TP 400.
-- WS: Amatsu Kyori / Hanadoki / Suien / Gachirin; Rise From Ashes (party heal).
-- Holds TP to close skillchains. At 2000+ TP with Meditate ready:
--   Kyori > Hanadoki = Fragmentation > Suien = Light > Gachirin = Double Light.
-- MB fire skillchains with near-instant Flare II.
-- HP-5%, MP+250%, high Store TP (~205 TP/hit).
-- A-tier melee_dd (weaponskill) power path.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local WS_KYORI    = 3733
local WS_HANADOKI = 3734
local WS_SUIEN    = 3737
local WS_GACHIRIN = 3736
local MS_RISE     = 3738

local RECAST_MEDITATE = 134

local SOLO_SEQ =
{
    WS_KYORI,
    WS_HANADOKI,
    WS_SUIEN,
    WS_GACHIRIN,
}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.IROHA)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

local function shouldRiseFromAshes(mob)
    local master = mob:getMaster()
    if not master then
        return false
    end

    local party = master:getPartyWithTrusts()
    if not party then
        return false
    end

    local yellow = 0
    for _, member in pairs(party) do
        if member:isAlive() then
            if
                member:hasStatusEffect(xi.effect.SLEEP_I) or
                member:hasStatusEffect(xi.effect.SLEEP_II) or
                member:hasStatusEffect(xi.effect.LULLABY)
            then
                return true
            end

            if member:getHPP() < 75 then
                yellow = yellow + 1
            end
        end
    end

    return yellow >= 3
end

local function queueSoloWS(mob, step)
    mob:timer(1800, function(mobArg)
        if mobArg:getLocalVar('irohaIISoloStep') ~= step then
            return
        end

        local target = mobArg:getTarget()
        if not target or not target:isAlive() then
            mobArg:setLocalVar('irohaIISoloStep', 0)
            mobArg:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 2500)
            return
        end

        -- Save TP / Meditate flavor: keep enough TP to finish the Double Light chain.
        mobArg:setTP(math.max(mobArg:getTP(), 2000))
        mobArg:useMobAbility(SOLO_SEQ[step], target)
    end)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:addMod(xi.mod.SAVETP, 400)
    mob:addMod(xi.mod.HPP, -5)
    mob:addMod(xi.mod.MPP, 250)
    -- Retail ~205 TP per hit.
    mob:addMod(xi.mod.STORETP, 100)

    -- Magical Amatsu + Flare II lane (melee package owns AA).
    mob:addMod(xi.mod.MATT, 180)
    mob:addMod(xi.mod.MACC, 110)
    mob:addMod(xi.mod.MAGIC_DAMAGE, 4500)
    mob:addMod(xi.mod.FASTCAST, 70)
    mob:addMod(xi.mod.UFASTCAST, 25)

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.HASSO }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.HASSO })
    mob:addGambit(ai.t.SELF, { ai.c.HAS_TOP_ENMITY, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.THIRD_EYE })

    -- Protectra V / Shellra V only.
    mob:addGambit(ai.t.PARTY, { ai.c.NOT_STATUS, xi.effect.PROTECT }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.PROTECTRA_V })
    mob:addGambit(ai.t.PARTY, { ai.c.NOT_STATUS, xi.effect.SHELL }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.SHELLRA_V })

    -- Near-instant Flare II on fire MB windows.
    mob:addGambit(ai.t.TARGET, { ai.c.MB_AVAILABLE, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.FLARE_II })

    mob:setLocalVar('irohaIISoloStep', 0)
    mob:setLocalVar('irohaIIRiseReady', 0)

    -- Hold to close; dump by 2500. RANDOM keeps Kyori/Hanadoki/Suien/Gachirin in play.
    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 2500)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    -- Rise From Ashes: party heal ability, not a TP WS.
    mob:addListener('COMBAT_TICK', 'IROHA_II_RISE', function(mobArg)
        local now = os.time()
        if now < mobArg:getLocalVar('irohaIIRiseReady') then
            return
        end

        if mobArg:getLocalVar('irohaIISoloStep') > 0 then
            return
        end

        if not shouldRiseFromAshes(mobArg) then
            return
        end

        mobArg:setLocalVar('irohaIIRiseReady', now + 45)
        mobArg:useMobAbility(MS_RISE)
    end)

    -- Double Light solo when Meditate ready @2000+ TP.
    mob:addListener('COMBAT_TICK', 'IROHA_II_SOLO_SC', function(mobArg)
        if mobArg:getLocalVar('irohaIISoloStep') > 0 then
            return
        end

        -- Meditate ready + 2000 TP: open Double Light. Save Meditate for this (don't burn while building).
        if mobArg:hasRecast(xi.recast.ABILITY, RECAST_MEDITATE) or mobArg:getTP() < 2000 then
            return
        end

        -- Suppress foreign closes while opening the Double Light package.
        mobArg:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 3000)

        local target = mobArg:getTarget()
        if not target or not target:isAlive() then
            return
        end

        mobArg:useJobAbility(xi.ja.MEDITATE, mobArg)
        mobArg:setLocalVar('irohaIISoloStep', 1)
        mobArg:useMobAbility(WS_KYORI, target)
    end)

    mob:addListener('WEAPONSKILL_USE', 'IROHA_II_SOLO_WS', function(mobArg, target, skill, tp, action, damage)
        local step = mobArg:getLocalVar('irohaIISoloStep')
        if step <= 0 then
            return
        end

        if skill:getID() ~= SOLO_SEQ[step] then
            return
        end

        if step >= #SOLO_SEQ then
            mobArg:setLocalVar('irohaIISoloStep', 0)
            mobArg:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 2500)
            return
        end

        local nextStep = step + 1
        mobArg:setLocalVar('irohaIISoloStep', nextStep)
        queueSoloWS(mobArg, nextStep)
    end)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
