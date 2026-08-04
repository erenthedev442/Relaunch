-----------------------------------
-- Trust: Iroha
-- SAM/WHM. Great Katana. Protectra V / Shellra V only (75+).
-- Abilities: Hasso, Hagakure, Meditate, Third Eye, Save TP 400.
-- WS: Amatsu Hanadoki / Choun / Fuga / Gachirin (magical Light/Fire).
-- Solo SC when Hagakure + Meditate ready @2000 TP:
--   Hanadoki > Choun = Liquefaction > Fuga = Fusion > Gachirin = Light > Gachirin = LightLight.
-- Otherwise holds to 2500 to close. Blessing of Phoenix (one revive per summon).
-- MP+50%. B-tier melee_dd (weaponskill) power path.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

-- Trust Iroha Amatsu set (3556–3560). Iroha II uses 3732+.
local WS_HANADOKI  = 3558
local WS_CHOUN     = 3559
local WS_FUGA      = 3556
local WS_GACHIRIN  = 3560

-- Hagakure recastId 54, Meditate recastId 134 (abilities.sql).
local RECAST_HAGAKURE = 54
local RECAST_MEDITATE = 134

local SOLO_SEQ =
{
    WS_HANADOKI,
    WS_CHOUN,
    WS_FUGA,
    WS_GACHIRIN,
    WS_GACHIRIN,
}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.IROHA_II)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

local function soloPackageReady(mob)
    return not mob:hasRecast(xi.recast.ABILITY, RECAST_HAGAKURE) and
        not mob:hasRecast(xi.recast.ABILITY, RECAST_MEDITATE)
end

local function queueSoloWS(mob, step)
    mob:timer(1800, function(mobArg)
        if mobArg:getLocalVar('irohaSoloStep') ~= step then
            return
        end

        local target = mobArg:getTarget()
        if not target or not target:isAlive() then
            mobArg:setLocalVar('irohaSoloStep', 0)
            mobArg:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.HIGHEST, 2500)
            return
        end

        -- Hagakure retains TP; ensure enough for the next link.
        if mobArg:hasStatusEffect(xi.effect.HAGAKURE) then
            mobArg:setTP(math.max(mobArg:getTP(), 2000))
        end

        mobArg:useMobAbility(SOLO_SEQ[step], target)
    end)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:addMod(xi.mod.SAVETP, 400)
    mob:addMod(xi.mod.MPP, 50)

    -- Magical Amatsu lane (melee package owns AA / physical side).
    mob:addMod(xi.mod.MATT, 140)
    mob:addMod(xi.mod.MACC, 90)
    mob:addMod(xi.mod.MAGIC_DAMAGE, 3000)

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.HASSO }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.HASSO })
    mob:addGambit(ai.t.SELF, { ai.c.HAS_TOP_ENMITY, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.THIRD_EYE })

    -- Protectra V / Shellra V only (spell list has no lower tiers).
    mob:addGambit(ai.t.PARTY, { ai.c.NOT_STATUS, xi.effect.PROTECT }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.PROTECTRA_V })
    mob:addGambit(ai.t.PARTY, { ai.c.NOT_STATUS, xi.effect.SHELL }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.SHELLRA_V })

    mob:setLocalVar('irohaSoloStep', 0)
    mob:setLocalVar('irohaPhoenixUsed', 0)

    -- Default: close others' skillchains; dump by 2500.
    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.HIGHEST, 2500)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    -- Solo SC package when Hagakure + Meditate are both ready.
    mob:addListener('COMBAT_TICK', 'IROHA_SOLO_SC', function(mobArg)
        if mobArg:getLocalVar('irohaSoloStep') > 0 then
            return
        end

        if not soloPackageReady(mobArg) then
            mobArg:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.HIGHEST, 2500)
            return
        end

        -- Package ready: do not close foreign SCs; hold for solo @2000.
        mobArg:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 3000)

        if not mobArg:hasStatusEffect(xi.effect.HAGAKURE) then
            mobArg:useJobAbility(xi.ja.HAGAKURE, mobArg)
            return
        end

        if mobArg:getTP() < 2000 then
            -- Save Meditate for the open; AA + Hagakure builds TP.
            return
        end

        local target = mobArg:getTarget()
        if not target or not target:isAlive() then
            return
        end

        -- Burn Meditate then open Hanadoki in the same tick (Meditate CD must not abort the package).
        mobArg:useJobAbility(xi.ja.MEDITATE, mobArg)
        mobArg:setLocalVar('irohaSoloStep', 1)
        mobArg:useMobAbility(WS_HANADOKI, target)
    end)

    mob:addListener('WEAPONSKILL_USE', 'IROHA_SOLO_WS', function(mobArg, target, skill, tp, action, damage)
        local step = mobArg:getLocalVar('irohaSoloStep')
        if step <= 0 then
            return
        end

        if skill:getID() ~= SOLO_SEQ[step] then
            return
        end

        if step >= #SOLO_SEQ then
            mobArg:setLocalVar('irohaSoloStep', 0)
            mobArg:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.HIGHEST, 2500)
            return
        end

        local nextStep = step + 1
        mobArg:setLocalVar('irohaSoloStep', nextStep)
        queueSoloWS(mobArg, nextStep)
    end)

    -- Blessing of Phoenix: survive lethal damage once per summon (full HP).
    mob:addListener('TAKE_DAMAGE', 'IROHA_PHOENIX', function(mobArg, amount, attacker, attackType, damageType)
        if mobArg:getLocalVar('irohaPhoenixUsed') ~= 0 then
            return
        end

        if amount > 0 and mobArg:getHP() <= amount then
            mobArg:setLocalVar('irohaPhoenixUsed', 1)
            mobArg:setHP(mobArg:getMaxHP() + amount)
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
