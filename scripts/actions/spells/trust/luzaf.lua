-----------------------------------
-- Trust: Luzaf
-- COR/NIN. Dual wield + shoot. No Phantom Roll.
-- Abilities: Quick Draw (vs weakness), Triple Shot.
-- WS: Bisection / Akimbo Shot / Leaden Salute / Grisly Horizon.
-- Picks one preferred WS on summon; exclusive unless closing SC.
-- Holds to 2500 TP; opens when master >=1000 TP; closes party/trust SCs.
-- A-tier ranged_dd (weaponskill) power path — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local WS_POOL =
{
    3252, -- Bisection
    3253, -- Leaden Salute
    3254, -- Akimbo Shot
    3255, -- Grisly Horizon
}

local QD_SHOTS =
{
    { ja = xi.ja.FIRE_SHOT,    sdt = xi.mod.FIRE_SDT },
    { ja = xi.ja.ICE_SHOT,     sdt = xi.mod.ICE_SDT },
    { ja = xi.ja.WIND_SHOT,    sdt = xi.mod.WIND_SDT },
    { ja = xi.ja.EARTH_SHOT,   sdt = xi.mod.EARTH_SDT },
    { ja = xi.ja.THUNDER_SHOT, sdt = xi.mod.THUNDER_SDT },
    { ja = xi.ja.WATER_SHOT,   sdt = xi.mod.WATER_SDT },
    { ja = xi.ja.LIGHT_SHOT,   sdt = xi.mod.LIGHT_SDT },
    { ja = xi.ja.DARK_SHOT,    sdt = xi.mod.DARK_SDT },
}

local RECAST_QUICK_DRAW = 195

local function pickQuickDraw(target)
    local bestJa  = xi.ja.FIRE_SHOT
    local bestSdt = -100000

    for _, entry in ipairs(QD_SHOTS) do
        local sdt = target:getMod(entry.sdt)
        if sdt > bestSdt then
            bestSdt = sdt
            bestJa  = entry.ja
        end
    end

    return bestJa
end

local function canAct(mobArg)
    return mobArg:isEngaged() and
        mobArg:getCurrentAction() == xi.action.category.BASIC_ATTACK
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    -- Merit flavor: SC bonus, MACC, QD recast/MACC (official note).
    local lvl = mob:getMainLvl()
    mob:addMod(xi.mod.SKILLCHAINBONUS, 5)
    mob:addMod(xi.mod.MACC, 40 + math.floor(lvl / 2))
    mob:addMod(xi.mod.MATT, 15 + math.floor(lvl / 3))
    mob:addMod(xi.mod.QUICK_DRAW_MACC, 20)
    mob:addMod(xi.mod.QUICK_DRAW_RECAST, 10)

    -- Dual wield + shoot → high TP (NIN DW trait + offhand swings + RA).
    mob:setMobMod(xi.mobMod.DUAL_WIELD, 1)
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.TRIPLE_SHOT }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.TRIPLE_SHOT })
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.RATTACK, 0, 0 }, 12)

    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    -- Prefer one WS for the life of the summon (unless closing).
    local preferred = WS_POOL[math.random(#WS_POOL)]
    mob:setLocalVar('luzafPrefer', preferred)
    mob:setLocalVar('luzafWsLock', 0)
    mob:setLocalVar('luzafQdReady', 0)

    -- Block built-in opener; drive preferred + closer windows ourselves.
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 3001)

    mob:addListener('COMBAT_TICK', 'LUZAF_TP', function(mobArg)
        local tp = mobArg:getTP()
        if tp < 1000 then
            mobArg:setLocalVar('luzafWsLock', 0)
            mobArg:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 3001)
            return
        end

        local battleTarget = mobArg:getTarget()
        if not battleTarget or not battleTarget:isAlive() then
            return
        end

        -- Close SCs opened by player / party / other trusts.
        if battleTarget:getStatusEffect(xi.effect.SKILLCHAIN) then
            mobArg:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.HIGHEST, 2500)
            return
        end

        -- Hold auto-WS; open for master @1000 or dump preferred @2500.
        mobArg:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 3001)

        if mobArg:getLocalVar('luzafWsLock') ~= 0 or not canAct(mobArg) then
            return
        end

        local master = mobArg:getMaster()
        local openForPlayer = master and master:getTP() >= 1000
        if not openForPlayer and tp < 2500 then
            return
        end

        mobArg:setLocalVar('luzafWsLock', 1)
        mobArg:useMobAbility(mobArg:getLocalVar('luzafPrefer'), battleTarget)
    end)

    -- Quick Draw vs highest elemental SDT (weakness).
    mob:addListener('COMBAT_TICK', 'LUZAF_QD', function(mobArg)
        if not canAct(mobArg) then
            return
        end

        local now = os.time()
        if now < mobArg:getLocalVar('luzafQdReady') then
            return
        end

        if mobArg:hasRecast(xi.recast.ABILITY, RECAST_QUICK_DRAW) then
            return
        end

        local battleTarget = mobArg:getTarget()
        if not battleTarget or not battleTarget:isAlive() then
            return
        end

        mobArg:setLocalVar('luzafQdReady', now + 12)
        mobArg:useJobAbility(pickQuickDraw(battleTarget), battleTarget)
    end)

    mob:addListener('WEAPONSKILL_USE', 'LUZAF_WS_UNLOCK', function(mobArg)
        mobArg:setLocalVar('luzafWsLock', 0)
        mobArg:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 3001)
    end)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
