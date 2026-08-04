-----------------------------------
-- Trust: Kayeel-Payeel
-- BLM/SMN Staff. Ice + Lightning only (spell list); ignores weakness.
-- ST I–V, -ga I–III, -aja, Ancient Magic I/II. Very high Fast Cast; MB-first.
-- WS: Sunburst / Tartarus Torpor / Gate of Tartarus (AM Refresh 8 when OOM).
-- Does not engage (NO_MOVE); staff AA if enemy nearby. WS @1500; no SC hold.
-- Robel-Akbel synergy: extra Fast Cast. A-tier nuker (burst) — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_GATE = 185

local function partyHasRobel(mob)
    local master = mob:getMaster()
    if not master then
        return false
    end

    for _, member in pairs(master:getPartyWithTrusts() or {}) do
        if
            member:getObjType() == xi.objType.TRUST and
            member:getTrustID() == xi.magic.spell.ROBEL_AKBEL
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
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.ROBEL_AKBEL] = xi.trust.messageOffset.TEAMWORK_1,
    })

    -- Very high Fast Cast on top of A burst scaler (style already boosts FC).
    mob:addMod(xi.mod.FASTCAST, 45)
    mob:addMod(xi.mod.UFASTCAST, 15)
    mob:addMod(xi.mod.MAGIC_BURST_BONUS_UNCAPPED, 30)
    mob:addMod(xi.mod.MACC, 50)
    -- Staff AA when the target is in range (nuker package has no melee axes).
    mob:addMod(xi.mod.ACC, 40)
    mob:addMod(xi.mod.ATT, 50)
    mob:addMod(xi.mod.MAIN_DMG_RATING, 25)

    if partyHasRobel(mob) then
        -- Synergy: cast more frequently with Robel-Akbel.
        mob:addMod(xi.mod.FASTCAST, 25)
        mob:addMod(xi.mod.UFASTCAST, 10)
    end

    -- Magic burst windows first (Ice/Lightning only via spell list).
    mob:addGambit(ai.t.TARGET, { ai.c.MB_AVAILABLE, 0 }, { ai.r.MA, ai.s.MB_ELEMENT, xi.magic.spellFamily.NONE })

    -- Free nukes: highest available Ice/Lightning (list already element-locked).
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_SC_AVAILABLE, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.NONE }, 20)
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.NONE }, 45)

    -- Claustrum relic AM: Refresh +8 (weaponskill script needs equipped relic; cheat for trust).
    mob:addListener('WEAPONSKILL_USE', 'KAYEEL_GATE_AM', function(mobArg, target, skill, tp, action, damage)
        if skill:getID() ~= MS_GATE then
            return
        end

        local duration = math.max(20, math.floor(tp * 0.02))
        if mobArg:hasStatusEffect(xi.effect.REFRESH) then
            mobArg:delStatusEffect(xi.effect.REFRESH)
        end

        mobArg:addStatusEffect(xi.effect.REFRESH, {
            power    = 8,
            duration = duration,
            origin   = mobArg,
            tick     = 3,
        })
    end)

    -- When OOM, force Gate (last on skill list / HIGHEST) until AM Refresh is up.
    mob:addListener('COMBAT_TICK', 'KAYEEL_GATE_MODE', function(mobArg)
        local oom   = mobArg:getMPP() < 20
        local hasAM = mobArg:hasStatusEffect(xi.effect.REFRESH)
        local mode  = mobArg:getLocalVar('kayeelGateMode')

        if oom and not hasAM then
            if mode ~= 1 then
                mobArg:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 1000)
                mobArg:setLocalVar('kayeelGateMode', 1)
            end
        elseif mode == 1 then
            mobArg:setTrustTPSkillSettings(ai.tp.RANDOM, ai.s.RANDOM, 1500)
            mobArg:setLocalVar('kayeelGateMode', 0)
        end
    end)

    mob:setAutoAttackEnabled(true)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.NO_MOVE)
    -- Dump from 1500; RANDOM = no SC hold (may still close if a WS matches).
    mob:setTrustTPSkillSettings(ai.tp.RANDOM, ai.s.RANDOM, 1500)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
