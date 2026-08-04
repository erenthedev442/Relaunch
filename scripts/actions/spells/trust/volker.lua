-----------------------------------
-- Trust: Volker
-- WAR/WAR sword. Fast Blade / Savage / Spirits Within / Vorpal / Berserk-Ruf.
-- Party has NIN/PLD/RUN: DD (Aggressor, Berserk, Warcry).
-- No other tank: tank (Defender, Retaliation). Provoke in both roles.
-- WS @2000 with Warrior's Charge when ready; does not skillchain.
-- B-tier melee_dd (bruiser) — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_BERSERK_RUF   = 3205
local RECAST_WC        = 6 -- warriors_charge abilities.sql recastId

local function canAct(mobArg)
    return mobArg:isEngaged() and
        mobArg:getCurrentAction() == xi.action.category.BASIC_ATTACK
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.NAJI ] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.CID  ] = xi.trust.messageOffset.TEAMWORK_2,
        [xi.magic.spell.KLARA] = xi.trust.messageOffset.TEAMWORK_3,
    })

    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    -- Off-tank / main-tank enmity (Provoke still the main tool).
    xi.trust.enableTankEnmity(mob, {
        tickCE       = 2800,
        tickVE       = 5600,
        actionCE     = 1400,
        actionVE     = 2800,
        tickSeconds  = 3,
        drainMaster  = 5,
        includeParty = true,
        listenerName = 'VOLKER_TANK_ENMITY',
    })

    -- DD mode (party has NIN / PLD / RUN).
    mob:addGambit(ai.t.SELF, {
        { ai.c.PT_HAS_TANK, 0 },
        { ai.c.NOT_STATUS, xi.effect.BERSERK },
    }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BERSERK })
    mob:addGambit(ai.t.SELF, {
        { ai.c.PT_HAS_TANK, 0 },
        { ai.c.NOT_STATUS, xi.effect.AGGRESSOR },
    }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.AGGRESSOR })
    mob:addGambit(ai.t.SELF, {
        { ai.c.PT_HAS_TANK, 0 },
        { ai.c.NOT_STATUS, xi.effect.WARCRY },
    }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.WARCRY })

    -- Tank mode (no NIN / PLD / RUN).
    mob:addGambit(ai.t.SELF, {
        { ai.c.NOT_PT_HAS_TANK, 0 },
        { ai.c.NOT_STATUS, xi.effect.DEFENDER },
    }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.DEFENDER })
    mob:addGambit(ai.t.SELF, {
        { ai.c.NOT_PT_HAS_TANK, 0 },
        { ai.c.NOT_STATUS, xi.effect.RETALIATION },
    }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.RETALIATION })

    -- Provoke: peel for the tank when one exists; hold hate when he is the tank.
    mob:addGambit(ai.t.TANK, { ai.c.HPP_LT, 50 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.PROVOKE })
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_PT_HAS_TANK, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.PROVOKE })
    mob:addGambit(ai.t.MASTER, { ai.c.HPP_LT, 50 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.PROVOKE })

    mob:setLocalVar('volkerRuf', 0)
    mob:setLocalVar('volkerRufReady', 0)
    -- Damage WS @2000; does not skillchain. Berserk-Ruf is script-gated.
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 2000)

    mob:addListener('COMBAT_TICK', 'VOLKER_AI', function(mobArg)
        if not canAct(mobArg) then
            return
        end

        local tp = mobArg:getTP()

        -- Berserk-Ruf (Attack Boost) on a short CD when TP is available.
        if
            tp >= 1000 and
            not mobArg:hasStatusEffect(xi.effect.ATTACK_BOOST) and
            mobArg:getLocalVar('volkerRufReady') <= os.time()
        then
            mobArg:setLocalVar('volkerRufReady', os.time() + 90)
            mobArg:setLocalVar('volkerRuf', 1)
            mobArg:setLocalVar('volkerRufTP', tp)
            mobArg:useMobAbility(MS_BERSERK_RUF, mobArg)
            return
        end

        -- Warrior's Charge before dumping WS at 2000+.
        if
            tp >= 2000 and
            not mobArg:hasStatusEffect(xi.effect.WARRIORS_CHARGE) and
            not mobArg:hasRecast(xi.recast.ABILITY, RECAST_WC)
        then
            -- Trusts have no WAR merits; apply 5/5-equivalent (DA guarantee, TA+0).
            mobArg:addStatusEffect(xi.effect.WARRIORS_CHARGE, {
                power    = 0,
                duration = 60,
                origin   = mobArg,
            })
            mobArg:addRecast(xi.recast.ABILITY, RECAST_WC, 300)
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
