-----------------------------------
-- Trust: Karaha-Baruha
-- WHM/SMN. Cure I–VI, Protect/ra, Shell/ra, -na, Erase, Haste, Barelementra.
-- WS: Spirit Taker / Starburst / Sunburst / Lunar Bay / Howling Moon (AoE).
-- HP-10%, MP+20% (pool). Auto Refresh I; +2 with Star Sibyl while engaged.
-- Close SC at 1000+ TP; else hold to 3000 for Spirit Taker when MP not full.
-- Barelementra after elemental skill/spell damage. C-tier healer + meleeChip.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_SPIRIT_TAKER = 183
local MS_HOWLING_MOON = 3336

local function canAct(mobArg)
    if not mobArg:isEngaged() then
        return false
    end

    local action = mobArg:getCurrentAction()
    return action == xi.action.category.NONE or action == xi.action.category.BASIC_ATTACK
end

local function partyHasStarSibyl(mobArg)
    local master = mobArg:getMaster()
    if not master then
        return false
    end

    for _, member in pairs(master:getPartyWithTrusts() or {}) do
        if
            member:getObjType() == xi.objType.TRUST and
            member:getTrustID() == xi.magic.spell.STAR_SIBYL
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
        [xi.magic.spell.STAR_SIBYL] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.ROBEL_AKBEL] = xi.trust.messageOffset.TEAMWORK_2,
    })

    -- Auto Refresh I; Star Sibyl synergy handled on combat tick.
    mob:addMod(xi.mod.REFRESH, 1)
    -- SMN-like MP pool on top of MPP+20% pool mod (lowest-HP healer identity).
    mob:addMod(xi.mod.MP, 150)

    -- Status first, then triage, then shields / haste.
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.DOOM }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.CURSE_I }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.CURSE_II }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.BANE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })

    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.PARALYSIS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.PARALYNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.BLINDNESS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.BLINDNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SILENCE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.SILENA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.PETRIFICATION }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STONA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.DISEASE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.VIRUNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.POISON }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.POISONA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS_FLAG, xi.effectFlag.ERASABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ERASE })

    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_I }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_II }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 25 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })

    mob:addGambit(ai.t.PARTY, { ai.c.NOT_STATUS, xi.effect.PROTECT }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.PROTECTRA })
    mob:addGambit(ai.t.PARTY, { ai.c.NOT_STATUS, xi.effect.SHELL }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.SHELLRA })
    mob:addGambit(ai.t.PARTY, { ai.c.NOT_STATUS, xi.effect.HASTE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.HASTE })

    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 55 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })

    -- Barelementra after elemental skill/spell damage.
    mob:addListener('TAKE_DAMAGE', 'KARAHA_BARUHA_TAKE_DAMAGE', function(mobArg, amount, attacker, attackType, damageType)
        local elemTable =
        {
            [xi.damageType.FIRE]    = { effect = xi.effect.BARFIRE,     spell = xi.magic.spell.BARFIRA },
            [xi.damageType.ICE]     = { effect = xi.effect.BARBLIZZARD, spell = xi.magic.spell.BARBLIZZARA },
            [xi.damageType.WIND]    = { effect = xi.effect.BARAERO,     spell = xi.magic.spell.BARAERA },
            [xi.damageType.EARTH]   = { effect = xi.effect.BARSTONE,    spell = xi.magic.spell.BARSTONRA },
            [xi.damageType.THUNDER] = { effect = xi.effect.BARTHUNDER,  spell = xi.magic.spell.BARTHUNDRA },
            [xi.damageType.WATER]   = { effect = xi.effect.BARWATER,    spell = xi.magic.spell.BARWATERA },
        }

        local elemData = elemTable[damageType]
        if not elemData or mobArg:hasStatusEffect(elemData.effect) then
            return
        end

        local now = GetSystemTime()
        if mobArg:getLocalVar('karahaBarCD') > now then
            return
        end

        mobArg:setLocalVar('karahaBarCD', now + 20)
        mobArg:timer(1000, function(mobBar)
            if mobBar and mobBar:isAlive() and not mobBar:hasStatusEffect(elemData.effect) then
                mobBar:castSpell(elemData.spell, mobBar)
            end
        end)
    end)

    mob:addListener('WEAPONSKILL_USE', 'KARAHA_BARUHA_WEAPONSKILL_USE', function(mobArg, target, skill, tp, action, damage)
        if skill:getID() == MS_HOWLING_MOON and math.random(1, 100) <= 25 then
            xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_1) -- The light shall never fade!
        end
    end)

    -- Close SC at 1000+; dump at 3000. Spirit Taker forced when MP not full / no SC.
    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.HIGHEST, 3000)

    mob:addListener('COMBAT_TICK', 'KARAHA_BARUHA_AI', function(mobArg)
        -- Star Sibyl synergy: +2 Refresh while engaged (3 total with base Auto Refresh I).
        local wantSynergy = mobArg:isEngaged() and partyHasStarSibyl(mobArg)
        local hasSynergy  = mobArg:getLocalVar('karahaSibylRefresh') == 1
        if wantSynergy and not hasSynergy then
            mobArg:addMod(xi.mod.REFRESH, 2)
            mobArg:setLocalVar('karahaSibylRefresh', 1)
        elseif not wantSynergy and hasSynergy then
            mobArg:delMod(xi.mod.REFRESH, 2)
            mobArg:setLocalVar('karahaSibylRefresh', 0)
        end

        if not canAct(mobArg) or mobArg:getTP() < 3000 then
            return
        end

        -- Retail: hold to 3000 for Spirit Taker if unable to close and MP not full.
        if mobArg:getMPP() >= 100 then
            return
        end

        local battleTarget = mobArg:getTarget()
        if not battleTarget or not battleTarget:isAlive() then
            return
        end

        if battleTarget:hasStatusEffect(xi.effect.SKILLCHAIN) then
            return
        end

        mobArg:useMobAbility(MS_SPIRIT_TAKER, battleTarget)
    end)

    mob:setAutoAttackEnabled(true)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
