-----------------------------------
-- Trust: Darrcuiln
-- WAR/RDM "Beast" (Collared Lynx). No spells / JAs.
-- WS: Howling Gust / Starward Yowl / Righteous Rasp / Aurous Charge / Stalking Prey (AoE).
-- Special AA (charge/claw/howl). HP+~42% + large non-humanoid HP.
-- Holds TP randomly 1500–2000; does not try to skillchain.
-- With Morimar (not glowing): dumps ASAP at 1000 TP.
-- S-tier melee_dd (skirmisher) power path.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

-- Synergy only while Morimar is out and not in Vehement glow.
local function partyHasMorimarReady(mob)
    local master = mob:getMaster()
    if not master then
        return false
    end

    local party = master:getPartyWithTrusts()
    if not party then
        return false
    end

    for _, member in pairs(party) do
        if
            member:getObjType() == xi.objType.TRUST and
            member:getTrustID() == 990 and
            member:getLocalVar('moriGlow') == 0
        then
            return true
        end
    end

    return false
end

local function applyTpSettings(mob, withMorimar)
    if withMorimar then
        -- Synergy: use TP moves more often (1000 TP), no SC waiting.
        mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 1000)
    else
        -- Hold randomly from 1500 (also when Morimar is glowing).
        mob:setTrustTPSkillSettings(ai.tp.RANDOM, ai.s.RANDOM, 1500)
    end
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:addMod(xi.mod.HPP, 42)
    mob:addMod(xi.mod.HP, xi.trust.modGrowthValMax(mob, 800))
    mob:addMod(xi.mod.LIZARD_KILLER, 15)
    -- Howling Gust magical lane (no MAGIC_DAMAGE — that also feeds special AA hits).
    mob:addMod(xi.mod.MATT, 200)
    mob:addMod(xi.mod.MACC, 120)
    -- Special AA: ignore Slow (and does not benefit from Haste/Sambas).
    mob:addImmunity(xi.immunity.SLOW)

    -- Special multi-anim auto-attacks (charge / claw / howl).
    mob:setMobSkillAttack(2099)

    applyTpSettings(mob, partyHasMorimarReady(mob))
    mob:setLocalVar('DarrTpMode', partyHasMorimarReady(mob) and 1 or 0)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    mob:addListener('COMBAT_TICK', 'DARR_MORIMAR_TP', function(mobArg)
        local mode = partyHasMorimarReady(mobArg) and 1 or 0
        if mode ~= mobArg:getLocalVar('DarrTpMode') then
            mobArg:setLocalVar('DarrTpMode', mode)
            applyTpSettings(mobArg, mode == 1)
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
