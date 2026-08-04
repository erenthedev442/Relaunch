-----------------------------------
-- Trust: Flaviria UC
-- Spell ID: 957 | Pool ID: 5957
-- DRG/WAR polearm. Jump / High Jump / Super Jump / Angon / Berserk.
-- WS @1000 TP (no skillchain): Skewer (5) / Impulse Drive (25) /
-- Celidon's Torment (50, Camlann-like ignore DEF).
-- 5/5 Jump / High Jump recast + Angon duration merits at 75.
-- A-tier melee_dd (weaponskill) — no kit inject. Piercing damage.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_SKEWER   = 118
local MS_IMPULSE  = 120
local MS_CELIDON  = 3500

-- abilities.sql recast IDs
local RECAST_JUMP      = 158
local RECAST_HIGH_JUMP = 159
local RECAST_ANGON     = 165

-- 5/5 merits: Jump -10s (60→50), High Jump -20s (120→100), Angon 90s DEF Down.
local JUMP_RECAST_MERIT      = 50
local HIGH_JUMP_RECAST_MERIT = 100
local ANGON_DURATION_MERIT   = 90

local function isWearingFlaviriaShirt(player)
    return player:getEquipID(xi.slot.BODY) == xi.item.FLAVIRIA_UNITY_SHIRT
end

local function canAct(mobArg)
    if not mobArg:isEngaged() then
        return false
    end

    local action = mobArg:getCurrentAction()
    return action == xi.action.category.NONE or action == xi.action.category.BASIC_ATTACK
end

local function pickWS(mobArg)
    local lvl = mobArg:getMainLvl()
    if lvl >= 50 then
        return MS_CELIDON
    elseif lvl >= 25 then
        return MS_IMPULSE
    elseif lvl >= 5 then
        return MS_SKEWER
    end

    return nil
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    local master = mob:getMaster()
    if master and isWearingFlaviriaShirt(master) then
        xi.trust.message(mob, xi.trust.messageOffset.TEAMWORK_1)
        -- Modest Unity Shirt boost (stack on A-tier scaler, not a second power path).
        mob:addMod(xi.mod.ATT, 20)
        mob:addMod(xi.mod.ACC, 15)
    else
        xi.trust.message(mob, xi.trust.messageOffset.SPAWN)
    end

    -- Jump TP return for aggressive jump → WS loops while leveling.
    mob:addMod(xi.mod.JUMP_TP_BONUS, 180)
    mob:addMod(xi.mod.JUMP_ATT_BONUS, 15)

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.BERSERK }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BERSERK })

    -- Jumps: build TP / shed enmity. Super Jump only when she has hate.
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.JUMP })
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.HIGH_JUMP })
    mob:addGambit(ai.t.SELF, { ai.c.HAS_TOP_ENMITY, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SUPER_JUMP })

    -- WS are listener-driven (empty skill list) so she never holds for skillchains.
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    -- Merit-shortened Jump / High Jump recasts after use.
    mob:addListener('ABILITY_USE', 'FLAVIRIA_UC_MERIT_RECAST', function(mobArg, target, ability, action)
        if mobArg:getMainLvl() < 75 then
            return
        end

        local id = ability:getID()
        if id == xi.ja.JUMP then
            mobArg:addRecast(xi.recast.ABILITY, RECAST_JUMP, JUMP_RECAST_MERIT)
        elseif id == xi.ja.HIGH_JUMP then
            mobArg:addRecast(xi.recast.ABILITY, RECAST_HIGH_JUMP, HIGH_JUMP_RECAST_MERIT)
        end
    end)

    mob:addListener('COMBAT_TICK', 'FLAVIRIA_UC_AI', function(mobArg)
        if not canAct(mobArg) then
            return
        end

        local battleTarget = mobArg:getTarget()
        if not battleTarget or not battleTarget:isAlive() then
            return
        end

        -- Angon: DEF Down without ammo check (trusts have no Angon quiver).
        -- 5/5 merit duration at 75+; shorter below.
        if
            mobArg:getMainLvl() >= 75 and
            not mobArg:hasRecast(xi.recast.ABILITY, RECAST_ANGON) and
            not battleTarget:hasStatusEffect(xi.effect.DEFENSE_DOWN)
        then
            battleTarget:addStatusEffect(xi.effect.DEFENSE_DOWN, {
                power = 20,
                duration = ANGON_DURATION_MERIT,
                origin = mobArg,
            })
            mobArg:addRecast(xi.recast.ABILITY, RECAST_ANGON, 180)
            return
        end

        -- Aggressive WS @1000 TP — highest available, no SC hold.
        if mobArg:getTP() >= 1000 then
            local wsId = pickWS(mobArg)
            if wsId then
                mobArg:useMobAbility(wsId, battleTarget)
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
