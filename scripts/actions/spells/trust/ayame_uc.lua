-----------------------------------
-- Trust: Ayame UC
-- Spell ID: 1005 | Pool ID: 6005
-- SAM/WAR. Player/pet skillchain closer (SPECIAL_AYAME_UC).
-- WS: Jinpu / Koki / Mudo / Kasha / Ageha (2015 DEF Down).
-- JAs: Hasso, Third Eye (hate), Meditate, Sengikori (on close),
--      Shikikoyo 5/5 (+48%) @2000 TP after leader WS, Blade Bash (casts only).
-- Holds to 3000 TP; ignores windows she cannot close.
-- A-tier melee_dd (weaponskill) — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local SHIKIKOYO_RECAST = 136 -- abilities.sql recast id
local SHIKIKOYO_MULT   = 1.48 -- 5/5 merits

local function canAct(mobArg)
    if not mobArg:isEngaged() then
        return false
    end

    local action = mobArg:getCurrentAction()
    return action == xi.action.category.NONE or action == xi.action.category.BASIC_ATTACK
end

-- 5/5 Shikikoyo: trusts have no merit points, so apply retail +48% manually.
local function tryShikikoyo(mobArg, master)
    if
        not master or
        mobArg:getMainLvl() < 75 or
        mobArg:getTP() < 2000 or
        mobArg:hasRecast(xi.recast.ABILITY, SHIKIKOYO_RECAST)
    then
        return false
    end

    local transfer = math.floor((mobArg:getTP() - 1000) * SHIKIKOYO_MULT)
    transfer = utils.clamp(transfer, 0, 3000 - master:getTP())
    if transfer <= 0 then
        return false
    end

    mobArg:setTP(1000)
    master:addTP(transfer)
    mobArg:addRecast(xi.recast.ABILITY, SHIKIKOYO_RECAST, 300)
    return true
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.AYAME)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    -- Modest MACC so Ageha DEF Down can land on high-level content.
    mob:addMod(xi.mod.MACC, 40)

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.HASSO }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.HASSO })
    mob:addGambit(ai.t.SELF, { ai.c.HAS_TOP_ENMITY, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.THIRD_EYE })

    -- Blade Bash: interrupt casting only (not TP moves).
    mob:addGambit(ai.t.TARGET, { ai.c.CASTING_MA, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BLADE_BASH })

    -- Closer: hold for player SC; dump attempts at 3000 (SPECIAL ignores if can't close).
    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.SPECIAL_AYAME_UC, 3000)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    local master = mob:getMaster()
    if master then
        -- Only close skillchains started by the party leader (or their pet).
        master:addListener('WEAPONSKILL_USE', 'AYAME_UC_LEADER_WS', function(playerArg, target, skill, tp, action)
            local trust = nil
            for _, member in pairs(playerArg:getPartyWithTrusts() or {}) do
                if member:getObjType() == xi.objType.TRUST and member:getTrustID() == xi.magic.spell.AYAME_UC then
                    trust = member
                    break
                end
            end

            if not trust then
                return
            end

            trust:setLocalVar('AyameUcAllowClose', 1)
            trust:setLocalVar('AyameUcLeaderWS', 1)

            -- Shikikoyo after leader WS when she already has 2000+ TP.
            if trust:getTP() >= 2000 then
                tryShikikoyo(trust, playerArg)
            end
        end)
    end

    mob:addListener('COMBAT_TICK', 'AYAME_UC_AI', function(mobArg)
        local masterArg = mobArg:getMaster()
        if not masterArg then
            return
        end

        -- Attach pet WS listener once pet exists (often nil at spawn).
        if mobArg:getLocalVar('AyameUcPetListen') == 0 then
            local pet = masterArg:getPet()
            if pet then
                pet:addListener('WEAPONSKILL_USE', 'AYAME_UC_PET_WS', function(petArg)
                    local owner = petArg:getMaster()
                    if not owner then
                        return
                    end

                    for _, member in pairs(owner:getPartyWithTrusts() or {}) do
                        if member:getObjType() == xi.objType.TRUST and member:getTrustID() == xi.magic.spell.AYAME_UC then
                            member:setLocalVar('AyameUcAllowClose', 1)
                            break
                        end
                    end
                end)
                mobArg:setLocalVar('AyameUcPetListen', 1)
            end
        end

        -- Drop close permission once the SC / Chainbound window is gone.
        local battleTarget = mobArg:getTarget()
        if
            battleTarget and
            mobArg:getLocalVar('AyameUcAllowClose') == 1 and
            not battleTarget:hasStatusEffect(xi.effect.SKILLCHAIN) and
            not battleTarget:hasStatusEffect(xi.effect.CHAINBOUND)
        then
            mobArg:setLocalVar('AyameUcAllowClose', 0)
        end

        -- If she hits 2000 TP before the leader has WSed, Shikikoyo immediately.
        if
            mobArg:getLocalVar('AyameUcLeaderWS') == 0 and
            mobArg:getTP() >= 2000
        then
            tryShikikoyo(mobArg, masterArg)
        end

        if not canAct(mobArg) then
            return
        end

        -- Meditate when a close is allowed / leader has TP and she is under 1000.
        if
            not mobArg:hasRecast(xi.recast.ABILITY, 134) and
            mobArg:getTP() < 1000 and
            (masterArg:getTP() >= 1000 or mobArg:getLocalVar('AyameUcAllowClose') == 1)
        then
            mobArg:useJobAbility(xi.ja.MEDITATE, mobArg)
        end
    end)

    -- After she closes, require a fresh player/pet WS before the next close.
    mob:addListener('WEAPONSKILL_USE', 'AYAME_UC_CLOSED', function(mobArg)
        mobArg:setLocalVar('AyameUcAllowClose', 0)
    end)

    mob:addListener('WEAPONSKILL_STATE_EXIT', 'AYAME_UC_MS_CLOSED', function(mobArg)
        -- Mudo is a mobskill (>255); still consume the allow flag.
        mobArg:setLocalVar('AyameUcAllowClose', 0)
    end)
end

spellObject.onMobDespawn = function(mob)
    local master = mob:getMaster()
    if master then
        master:removeListener('AYAME_UC_LEADER_WS')
        local pet = master:getPet()
        if pet then
            pet:removeListener('AYAME_UC_PET_WS')
        end
    end

    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    local master = mob:getMaster()
    if master then
        master:removeListener('AYAME_UC_LEADER_WS')
        local pet = master:getPet()
        if pet then
            pet:removeListener('AYAME_UC_PET_WS')
        end
    end

    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
