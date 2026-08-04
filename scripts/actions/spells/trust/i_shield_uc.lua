-----------------------------------
-- Trust: Invincible Shield UC
-- Spell ID: 954 | Pool ID: 5954
-- WAR/COR. Damage dealer who Provokes. No shield (Retaliation-friendly).
-- DT -20%. HP+25% (Unity ranking mid-band 20–30%).
-- JAs: Provoke, Aggressor, Restraint, Retaliation, Warcry (+Savagery 5/5),
--      Blood Rage after Warcry, Tomahawk (Skeleton/Slime/Elemental).
-- WS: Raging Rush (5) / Steel Cyclone (25) / Soturi's Fury (50+).
-- Holds 1500 TP to close skillchains.
-- A-tier melee_dd (weaponskill) — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local RECAST_TOMAHAWK = 7 -- abilities.sql recastId for Tomahawk
local SAVAGERY_TP     = 500 -- 5/5 Savagery merits (100 TP each)

local function isWearingShieldShirt(player)
    return player:getEquipID(xi.slot.BODY) == xi.item.INVINCIBLE_SHIELD_UNITY_SHIRT
end

local function canAct(mobArg)
    if not mobArg:isEngaged() then
        return false
    end

    local action = mobArg:getCurrentAction()
    return action == xi.action.category.NONE or action == xi.action.category.BASIC_ATTACK
end

local function wantsTomahawk(target)
    if not target or not target:isAlive() then
        return false
    end

    if target:hasStatusEffect(xi.effect.TOMAHAWK) then
        return false
    end

    local eco = target:getEcoSystem()
    -- Skeletons (Undead), Slimes (Amorph), Elementals.
    return eco == xi.ecosystem.UNDEAD or
        eco == xi.ecosystem.AMORPH or
        eco == xi.ecosystem.ELEMENTAL
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    local master = mob:getMaster()
    if master and isWearingShieldShirt(master) then
        xi.trust.message(mob, xi.trust.messageOffset.TEAMWORK_1)
    else
        xi.trust.message(mob, xi.trust.messageOffset.SPAWN)
    end

    -- No shield — retail UC drops it so Retaliation hits land as counters.
    mob:setMobMod(xi.mobMod.CAN_SHIELD_BLOCK, 0)

    -- Retail UC: DT -20%, Unity HP band ~20–30% (use mid 25). Scaler owns AA/WS.
    mob:addMod(xi.mod.HPP, 25)
    mob:addMod(xi.mod.DMG, -2000)

    -- Off-tank enmity (Provoke is the main tool; not a full Ginuva tank shell).
    xi.trust.enableTankEnmity(mob, {
        tickCE       = 2200,
        tickVE       = 4400,
        actionCE     = 1100,
        actionVE     = 2200,
        tickSeconds  = 3,
        drainMaster  = 4,
        includeParty = true,
        listenerName = 'I_SHIELD_UC_TANK_ENMITY',
    })

    mob:addGambit(ai.t.SELF, { ai.c.NOT_HAS_TOP_ENMITY, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.PROVOKE })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.AGGRESSOR }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.AGGRESSOR })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.RESTRAINT }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.RESTRAINT })
    -- Retaliation for damage (no shield); keep up whenever possible.
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.RETALIATION }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.RETALIATION })

    -- Retail: Warcry → Blood Rage as soon as Warcry ends → Warcry again
    -- (COMBAT_TICK sequencer below; gambits can't express the handoff).
    mob:setLocalVar('iShieldNextBR', 0)

    -- Hold 1500 TP to close; dump at 1500.
    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.HIGHEST, 1500)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    -- Savagery 5/5: Warcry TP Bonus +500 (trusts have no merit points).
    -- Also mark Blood Rage as the next buff when Warcry is used.
    mob:addListener('ABILITY_USE', 'I_SHIELD_UC_SAVAGERY', function(mobArg, target, ability, action)
        local abilityId = ability:getID()
        if abilityId == xi.ja.BLOOD_RAGE then
            mobArg:setLocalVar('iShieldNextBR', 0)
            return
        end

        if abilityId ~= xi.ja.WARCRY then
            return
        end

        mobArg:setLocalVar('iShieldNextBR', 1)

        local effect = mobArg:getStatusEffect(xi.effect.WARCRY)
        if not effect or effect:getSubPower() >= SAVAGERY_TP then
            return
        end

        local missing = SAVAGERY_TP - effect:getSubPower()
        effect:setSubPower(SAVAGERY_TP)
        mobArg:addMod(xi.mod.TP_BONUS, missing)
        mobArg:setLocalVar('iShieldSavageryTP', missing)
    end)

    mob:addListener('EFFECT_LOSE', 'I_SHIELD_UC_BUFF_LOSE', function(mobArg, effect)
        local effectType = effect:getEffectType()
        if effectType == xi.effect.WARCRY then
            local bonus = mobArg:getLocalVar('iShieldSavageryTP')
            if bonus > 0 then
                mobArg:delMod(xi.mod.TP_BONUS, bonus)
                mobArg:setLocalVar('iShieldSavageryTP', 0)
            end
        end
    end)

    -- COMBAT_TICK picks Warcry vs Blood Rage (gambits alone can't express the sequence).
    mob:addListener('COMBAT_TICK', 'I_SHIELD_UC_WC_BR', function(mobArg)
        if not canAct(mobArg) then
            return
        end

        if
            mobArg:hasStatusEffect(xi.effect.WARCRY) or
            mobArg:hasStatusEffect(xi.effect.BLOOD_RAGE)
        then
            return
        end

        -- Blood Rage is WAR 87+. Wait on its recast rather than skipping ahead to Warcry.
        if mobArg:getLocalVar('iShieldNextBR') == 1 then
            if mobArg:getMainLvl() < 87 then
                mobArg:setLocalVar('iShieldNextBR', 0)
            elseif not mobArg:hasRecast(xi.recast.ABILITY, 11) then
                mobArg:useJobAbility(xi.ja.BLOOD_RAGE, mobArg)
                return
            else
                return
            end
        end

        if not mobArg:hasRecast(xi.recast.ABILITY, 2) then -- Warcry recastId
            mobArg:useJobAbility(xi.ja.WARCRY, mobArg)
        end
    end)

    -- Tomahawk without throwing-tomahawk ammo (trusts can't equip it).
    mob:addListener('COMBAT_TICK', 'I_SHIELD_UC_TOMAHAWK', function(mobArg)
        if
            mobArg:getMainLvl() < 75 or
            not canAct(mobArg) or
            mobArg:hasRecast(xi.recast.ABILITY, RECAST_TOMAHAWK)
        then
            return
        end

        local battleTarget = mobArg:getTarget()
        if not wantsTomahawk(battleTarget) then
            return
        end

        battleTarget:addStatusEffect(xi.effect.TOMAHAWK, {
            power = 25,
            duration = 30,
            origin = mobArg,
            tick = 3,
            icon = 0,
        })
        mobArg:addRecast(xi.recast.ABILITY, RECAST_TOMAHAWK, 180)
    end)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
