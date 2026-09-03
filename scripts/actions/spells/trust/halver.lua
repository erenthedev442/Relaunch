-----------------------------------
-- Trust: Halver
-- PLD/WAR. Polearm. Cure I–IV, Flash.
-- Abilities: Berserk (always), Provoke / Sentinel / Rampart (tank mode).
-- WS: Penta Thrust / Impulse Drive / Raiden Thrust.
-- MP+30% (pool mod). WS ASAP @1000 (lower priority than tank/cure gambits).
-- When any party member is <40% HP: tank mode — Sentinel/Rampart immediately,
-- Provoke + Flash more often, Cure party.
-- C-tier melee_dd (bruiser) power path.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

local function partyNeedsTank(mob)
    local master = mob:getMaster()
    if not master then
        return false
    end

    local party = master:getPartyWithTrusts()
    if not party then
        return false
    end

    for _, member in pairs(party) do
        if member:isAlive() and member:getHPP() < 40 then
            return true
        end
    end

    return false
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    -- Light thunder lane for Raiden Thrust (melee package owns AA / physical WS).
    mob:addMod(xi.mod.MATT, 80)
    mob:addMod(xi.mod.MACC, 60)
    mob:addMod(xi.mod.CURE_POTENCY, 10)

    -- Berserk as often as possible (DD default).
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.BERSERK }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BERSERK })

    -- Cure is always available for orange/red party; tank mode adds more tools below.
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 40 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })

    -- WS at 1000 TP, lower priority than the gambits above.
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 1000)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    local tankGambits = {}

    local function clearTankGambits(mobArg)
        for _, id in ipairs(tankGambits) do
            mobArg:removeGambit(id)
        end

        tankGambits = {}
    end

    -- Enmity hooks stay registered for the whole summon. COMBAT_TICK used
    -- to call enableTankEnmity here, which added another COMBAT_TICK while
    -- that list was being walked and crashed the map (Corvinos / Valkurm).
    xi.trust.enableTankEnmity(mob, {
        profile      = 'steady',
        listenerName = 'HALVER_TANK_ENMITY',
        activeVar    = 'HalverTankMode',
    })

    local function enterTankMode(mobArg)
        clearTankGambits(mobArg)

        -- Sentinel + Rampart as soon as tank behavior starts.
        tankGambits[#tankGambits + 1] = mobArg:addGambit(
            ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.SENTINEL }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SENTINEL })
        tankGambits[#tankGambits + 1] = mobArg:addGambit(
            ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.RAMPART }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.RAMPART })
        tankGambits[#tankGambits + 1] = mobArg:addGambit(
            ai.t.SELF, { ai.c.NOT_HAS_TOP_ENMITY, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.PROVOKE })
        -- Flash more frequently while tanking.
        tankGambits[#tankGambits + 1] = mobArg:addGambit(
            ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.FLASH }, 30)
    end

    local function leaveTankMode(mobArg)
        clearTankGambits(mobArg)
    end

    mob:setLocalVar('HalverTankMode', 2) -- force first sync

    mob:addListener('COMBAT_TICK', 'HALVER_TANK_MODE', function(mobArg)
        local need = partyNeedsTank(mobArg) and 1 or 0
        if need == mobArg:getLocalVar('HalverTankMode') then
            return
        end

        mobArg:setLocalVar('HalverTankMode', need)

        if need == 1 then
            enterTankMode(mobArg)
        else
            leaveTankMode(mobArg)
        end
    end)
end

local function removeHalverListeners(mob)
    mob:removeListener('HALVER_TANK_MODE')
    mob:removeListener('HALVER_TANK_ENMITY_ABILITY')
    mob:removeListener('HALVER_TANK_ENMITY_MAGIC')
    mob:removeListener('HALVER_TANK_ENMITY_WS')
    mob:removeListener('HALVER_TANK_ENMITY_TICK')
end

spellObject.onMobDespawn = function(mob)
    removeHalverListeners(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    removeHalverListeners(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
