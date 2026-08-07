-----------------------------------
-- Trust: Excenmille
-- PLD/PLD. Flash, Cure I-IV. Sentinel.
-- WS: Double Thrust / Leg Sweep / Penta Thrust.
-- RANDOM TP, no skillchains. Sentinel + Flash on cooldown for enmity.
-- Cure party <50%; if no WHM in party, cure threshold rises to <75%.
-- C-tier tank (bruiser) power path — San d'Oria starter.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    -- Exc_S slot (1004) is Matsui-P; no mutual exclusion with Meat/Exc.
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    local sandoriaFirstTrust = caster:getCharVar('SandoriaFirstTrust')
    local zone = caster:getZoneID()

    if
        sandoriaFirstTrust == 1 and
        (zone == xi.zone.WEST_RONFAURE or zone == xi.zone.EAST_RONFAURE)
    then
        caster:setCharVar('SandoriaFirstTrust', 2)
    end

    return xi.trust.spawn(caster, spell)
end

local function partyHasWHM(mob)
    local master = mob:getMaster()
    if not master then
        return false
    end

    local party = master:getPartyWithTrusts()
    if not party then
        return false
    end

    for _, member in pairs(party) do
        if member:getMainJob() == xi.job.WHM then
            return true
        end
    end

    return false
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.RAHAL] = xi.trust.messageOffset.TEAMWORK_1,
    })

    mob:setMobMod(xi.mobMod.CAN_SHIELD_BLOCK, 1)
    mob:addMod(xi.mod.STORETP, 25)
    mob:addMod(xi.mod.UNDEAD_KILLER, 15)
    -- Entry tank enmity (C-tier; keep under B/A tanks).
    mob:addMod(xi.mod.ENMITY, 100)
    xi.trust.enableTankEnmity(mob, {
        tickCE       = 3000,
        tickVE       = 6000,
        actionCE     = 1500,
        actionVE     = 3000,
        tickSeconds  = 3,
        drainMaster  = 5,
        includeParty = true,
        listenerName = 'EXCENMILLE_TANK_ENMITY',
    })

    -- Sentinel + Flash on cooldown for enmity.
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.SENTINEL }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SENTINEL })
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.FLASH }, 45)

    -- Base cure: orange HP (<50%).
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 50 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })

    -- No WHM: prioritize healing — raise threshold to <75%.
    local cure75Id = nil
    local function syncCureThreshold(mobArg)
        local hasWhm = partyHasWHM(mobArg)
        local mode = hasWhm and 1 or 0
        if mode == mobArg:getLocalVar('ExcenCureMode') then
            return
        end

        mobArg:setLocalVar('ExcenCureMode', mode)

        if cure75Id then
            mobArg:removeGambit(cure75Id)
            cure75Id = nil
        end

        if not hasWhm then
            cure75Id = mobArg:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 75 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })
        end
    end

    mob:setLocalVar('ExcenCureMode', 2) -- force first sync
    syncCureThreshold(mob)
    mob:addListener('COMBAT_TICK', 'EXCEN_CURE_THRESH', syncCureThreshold)

    mob:setTrustTPSkillSettings(ai.tp.RANDOM, ai.s.RANDOM, 1000)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
