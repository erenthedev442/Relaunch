-----------------------------------
-- Trust: Rongelouts
-- WAR/WAR. Sword. Tongue Lash (AoE Terror) / Red Lotus / Savage / Seraph Blade.
-- Berserk, Aggressor, Warcry (50s). Beastmen Killer. ~75 TP/hit.
-- ASAP@1000. A-tier melee_dd (bruiser) power path — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_TONGUE_LASH = 3486

local function clearBeastmenEdge(mobArg)
    if mobArg:getLocalVar('rongeBeast') == 0 then
        return
    end

    mobArg:delMod(xi.mod.ATT, 60)
    mobArg:delMod(xi.mod.ACC, 45)
    mobArg:setLocalVar('rongeBeast', 0)
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    -- Retail: enhanced Warcry duration (50s = base 30 + 20).
    mob:addMod(xi.mod.WARCRY_DURATION, 20)
    -- Retail: gains ~75 TP on hit.
    mob:addMod(xi.mod.STORETP, 70)
    -- Seraph Blade / Red Lotus magical component.
    mob:addMod(xi.mod.MATT, 80)
    mob:addMod(xi.mod.MACC, 50)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.BERSERK }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BERSERK })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.AGGRESSOR }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.AGGRESSOR })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.WARCRY }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.WARCRY })

    -- ASAP — do not hold TP.
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 1000)

    -- Beastmen Killer: no BEASTMEN case in IsIntimidated — ATT/ACC edge while fighting them.
    mob:setLocalVar('rongeBeast', 0)
    mob:addListener('COMBAT_TICK', 'RONGELLOUTS_BEASTMEN', function(mobArg)
        local battleTarget = mobArg:getTarget()
        if not battleTarget or not battleTarget:isAlive() then
            clearBeastmenEdge(mobArg)
            return
        end

        if battleTarget:getEcosystem() == xi.ecosystem.BEASTMEN then
            if mobArg:getLocalVar('rongeBeast') == 0 then
                mobArg:addMod(xi.mod.ATT, 60)
                mobArg:addMod(xi.mod.ACC, 45)
                mobArg:setLocalVar('rongeBeast', 1)
            end
        else
            clearBeastmenEdge(mobArg)
        end
    end)

    mob:addListener('DISENGAGE', 'RONGELLOUTS_DISENGAGE', function(mobArg)
        clearBeastmenEdge(mobArg)
    end)

    mob:addListener('WEAPONSKILL_USE', 'RONGELLOUTS_WS', function(mobArg, target, skill, tp, action, damage)
        if skill:getID() == MS_TONGUE_LASH then
            -- Knave!
            xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_1)
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
