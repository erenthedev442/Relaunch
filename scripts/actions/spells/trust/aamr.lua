-----------------------------------
-- Trust: AAMR (Ark Angel MR)
-- BST/THF axe. SA / TA + Rampage / Calamity / Havoc Spiral / Cloudsplitter.
-- HP+20%, TH from lvl 7. Holds to 3000 waiting for SA/TA or front Cloudsplitter.
-- Does not skillchain-select. A-tier bruiser power path + MATT for Cloudsplitter.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local PREFER_CALAMITY      = 1
local PREFER_CLOUDSPLITTER = 2

local function canTrickAttack(mobArg)
    local master = mobArg:getMaster()
    if not master then
        return false
    end

    for _, member in pairs(master:getPartyWithTrusts()) do
        if
            member:getID() ~= mobArg:getID() and
            member:isAlive() and
            mobArg:checkDistance(member) <= 3.0 and
            mobArg:isBehind(member)
        then
            return true
        end
    end

    return false
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:addMod(xi.mod.HPP, 20)
    -- Cloudsplitter is magical thunder; bruiser package is physical — give it an A-tier MATT lane.
    mob:addMod(xi.mod.MATT, 200)
    mob:addMod(xi.mod.MACC, 120)

    if mob:getMainLvl() >= 7 then
        mob:addMod(xi.mod.TREASURE_HUNTER, 1)
    end

    mob:setLocalVar('AAMRPrefer', PREFER_CLOUDSPLITTER)
    mob:setLocalVar('AAMRMode', 0) -- 0 hold@3000, 1 ASAP SA/TA, 2 ASAP front
    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.SPECIAL_AAMR, 3000)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    mob:addListener('COMBAT_TICK', 'AAMR_SA_TA_WS', function(mobArg)
        local target = mobArg:getTarget()
        if not target or not target:isAlive() then
            return
        end

        local tp = mobArg:getTP()
        local behindEnemy = mobArg:isBehind(target)
        local canTA = canTrickAttack(mobArg)
        local inFront = mobArg:isInfront(target)

        -- SA / TA setup before WS windows.
        if tp >= 1000 then
            if
                behindEnemy and
                not mobArg:hasStatusEffect(xi.effect.SNEAK_ATTACK) and
                not mobArg:hasRecast(xi.recast.ABILITY, 64)
            then
                mobArg:useJobAbility(xi.ja.SNEAK_ATTACK, mobArg)
            end

            if
                canTA and
                not mobArg:hasStatusEffect(xi.effect.TRICK_ATTACK) and
                not mobArg:hasRecast(xi.recast.ABILITY, 66)
            then
                mobArg:useJobAbility(xi.ja.TRICK_ATTACK, mobArg)
            end
        end

        -- Mode: ASAP on SA/TA or front Cloudsplitter; else hold to 3000 (no SC preference).
        local mode = 0
        local prefer = PREFER_CLOUDSPLITTER
        if tp >= 1000 and (behindEnemy or canTA) then
            mode = 1
            prefer = PREFER_CALAMITY
        elseif tp >= 1000 and inFront and not canTA then
            mode = 2
            prefer = PREFER_CLOUDSPLITTER
        end

        mobArg:setLocalVar('AAMRPrefer', prefer)

        if mode ~= mobArg:getLocalVar('AAMRMode') then
            mobArg:setLocalVar('AAMRMode', mode)
            if mode == 0 then
                mobArg:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.SPECIAL_AAMR, 3000)
            else
                mobArg:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.SPECIAL_AAMR, 1000)
            end
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
