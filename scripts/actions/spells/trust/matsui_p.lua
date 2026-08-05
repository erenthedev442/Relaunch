-----------------------------------
-- Trust: Matsui-P
-- Spell 1003 / pool 6003. Void Keeper capstone.
-- Appearance uses Makki-Chebukki's year-round look (seasonal Matsui model
-- R0-crashes). Kit is NIN/BLM: ninjutsu + Blade WS + Innin.
-- Prioritizes elemental ninjutsu + T1 nukes (Futae MB).
-- WS: Blade Rin/Retsu/Ei/Jin/Ten/Ku/Kamu/Hi/Shun.
-- After master uses a Lv2 SC property WS, opens Light/Darkness lines when
-- master has 1000+ TP. Holds to 3000 otherwise. No WS without shadows.
-- Party callouts for TP / follow-up properties.
-- S-tier hybrid (apex): soft 40–50k, hard / MB cap 79,999.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local SC = xi.skillchainType

local WS_POOL =
{
    128, -- Blade: Rin
    129, -- Blade: Retsu
    133, -- Blade: Ei
    134, -- Blade: Jin
    135, -- Blade: Ten
    136, -- Blade: Ku
    138, -- Blade: Kamu
    140, -- Blade: Hi
    141, -- Blade: Shun
}

-- Openers that set up Light / Darkness for the master's follow-up.
local OPENER_FUSION_FOLLOW =
{
    id   = 138, -- Kamu (Fragmentation) → player Fusion = Light
    hint = 'Fusion weapon skill! Now!',
}

local OPENER_FRAG_FOLLOW =
{
    id   = 141, -- Shun (Fusion) → player Fragmentation = Light
    hint = 'Use a Fragmentation weapon skill!',
}

local OPENER_DISTORTION_FOLLOW =
{
    { id = 140, hint = 'Hit \'em with a Distortion weapon skill!' }, -- Hi
    { id = 135, hint = 'Hit \'em with a Distortion weapon skill!' }, -- Ten
    { id = 136, hint = 'Hit \'em with a Distortion weapon skill!' }, -- Ku
}

local function hasProp(props, want)
    for i = 1, #props do
        if props[i] == want then
            return true
        end
    end

    return false
end

local function isLevel2Prop(prop)
    return prop ~= nil and prop >= SC.GRAVITATION and prop <= SC.FRAGMENTATION
end

local function pickLightDarknessOpener(p, s, t)
    local props = { p, s, t }

    -- No Distortion in kit → ignore Gravitation-only setups.
    if hasProp(props, SC.GRAVITATION) and
        not hasProp(props, SC.DISTORTION) and
        not hasProp(props, SC.FUSION) and
        not hasProp(props, SC.FRAGMENTATION)
    then
        return nil
    end

    if hasProp(props, SC.FUSION) then
        return OPENER_FUSION_FOLLOW
    end

    if hasProp(props, SC.FRAGMENTATION) then
        return OPENER_FRAG_FOLLOW
    end

    if hasProp(props, SC.DISTORTION) then
        return OPENER_DISTORTION_FOLLOW[math.random(#OPENER_DISTORTION_FOLLOW)]
    end

    return nil
end

local function canAct(mobArg)
    return mobArg:isEngaged() and
        mobArg:getCurrentAction() == xi.action.category.BASIC_ATTACK
end

local function say(master, msg)
    if master then
        master:printToPlayer(msg, xi.msg.channel.PARTY, 'Matsui-P')
    end
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    -- Look from pool (Makki year-round model); force display name.
    mob:renameEntity('Matsui-P', true)

    local master = mob:getMaster()
    local lvl = mob:getMainLvl()
    local upgraded = math.max(1, master and master:getCharVar('TrustUpgraded') or 1)
    local power = lvl * upgraded

    say(master, 'Greetings, adventurers! Matsui here, happy to join you in Vana\'diel!')

    -- Capstone flavor on top of S hybrid/apex package (do not fight softclamp/cap).
    -- Tuned so San/T1 MBs frequently land in the 40–50k soft band; crit/MB spikes
    -- can compress toward the 79,999 hard ceiling.
    mob:addMod(xi.mod.HP, power)
    mob:addMod(xi.mod.STR, math.floor(power * 0.5))
    mob:addMod(xi.mod.DEX, math.floor(power * 0.5))
    mob:addMod(xi.mod.INT, math.floor(power * 0.65))
    mob:addMod(xi.mod.ATT, power)
    mob:addMod(xi.mod.ACC, power + 40)
    mob:addMod(xi.mod.MATT, math.floor(power * 1.15))
    mob:addMod(xi.mod.MACC, power + 30)
    mob:addMod(xi.mod.HASTE_MAGIC, 1500)
    mob:addMod(xi.mod.FASTCAST, 80)
    mob:addMod(xi.mod.CRITHITRATE, 18 + math.floor(power / 12))
    mob:addMod(xi.mod.STORETP, math.floor(power / 5))
    mob:addMod(xi.mod.ALL_WSDMG_ALL_HITS, 55 + math.floor(power / 8))
    mob:addMod(xi.mod.MAGIC_DAMAGE, math.floor(power * 1.35) + 400)
    mob:addMod(xi.mod.MAGIC_BURST_BONUS_UNCAPPED, 55)
    -- Permanent ninjutsu bonus (Innin path is %/100); stacks with Innin uptime.
    mob:addMod(xi.mod.NIN_NUKE_BONUS_INNIN, 20)

    -- SetupJob(NIN) assigns shuriken SPECIAL_SKILL + standback; melee kit only.
    mob:setMobMod(xi.mobMod.SPECIAL_SKILL, 0)
    mob:setMobMod(xi.mobMod.HP_STANDBACK, 0)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    -- Shadows first — never WS without them.
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.COPY_IMAGE }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.UTSUSEMI })

    -- MB window: Futae / Elemental Seal, then San ninjutsu or T1 elemental.
    mob:addGambit(ai.t.SELF, { ai.c.MB_AVAILABLE, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.FUTAE })
    mob:addGambit(ai.t.SELF, { ai.c.MB_AVAILABLE, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.ELEMENTAL_SEAL })
    mob:addGambit(ai.t.TARGET, { ai.c.MB_AVAILABLE, 0 }, { ai.r.MA, ai.s.MB_ELEMENT, xi.magic.spellFamily.NONE })

    -- Free nukes / utility (ninjutsu + T1 BLM prioritized via spell list).
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_SC_AVAILABLE, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.NONE }, 45)
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.BURN }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.BURN }, 60)
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_WS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_MS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    -- Myoshu: Subtle Blow (less TP fed to mob). Yurin: Inhibit TP on target.
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.SUBTLE_BLOW_PLUS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.MYOSHU_ICHI }, 180)
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.ATTACK_DOWN }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.AISHA_ICHI }, 120)
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.INHIBIT_TP }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.YURIN_ICHI }, 120)
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.MIGAWARI }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.MIGAWARI_ICHI }, 180)
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.STORE_TP }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.KAKKA_ICHI }, 180)
    mob:addGambit(ai.t.SELF, { ai.c.MPP_LT, 40 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ASPIR })

    -- Job abilities.
    mob:addGambit(ai.t.SELF, {
        { ai.c.NOT_HAS_TOP_ENMITY, 0 },
        { ai.c.NOT_STATUS, xi.effect.INNIN },
    }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.INNIN })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.SANGE }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SANGE })
    mob:addGambit(ai.t.SELF, {
        { ai.c.HPP_LT, 35 },
        { ai.c.NOT_STATUS, xi.effect.MANA_WALL },
    }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.MANA_WALL })

    -- Block built-in WS; drive shadows / assist / 3000 dump ourselves.
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 3001)
    mob:setLocalVar('matsuiAssist', 0)
    mob:setLocalVar('matsuiWsLock', 0)
    mob:setLocalVar('matsuiTpAnnounced', 0)
    mob:setLocalVar('matsuiLastP', 0)
    mob:setLocalVar('matsuiLastS', 0)
    mob:setLocalVar('matsuiLastT', 0)

    -- Announce 1000 TP.
    mob:addListener('COMBAT_TICK', 'MATSUI_TP_ANNOUNCE', function(mobArg)
        local m = mobArg:getMaster()
        if not m then
            return
        end

        if mobArg:getTP() >= 1000 then
            if mobArg:getLocalVar('matsuiTpAnnounced') == 0 then
                mobArg:setLocalVar('matsuiTpAnnounced', 1)
                say(m, 'Ready for skillchain.')
            end
        else
            mobArg:setLocalVar('matsuiTpAnnounced', 0)
        end
    end)

    mob:addListener('COMBAT_TICK', 'MATSUI_TP', function(mobArg)
        local tp = mobArg:getTP()
        if tp < 1000 then
            mobArg:setLocalVar('matsuiWsLock', 0)
            return
        end

        -- Prioritize reapplying shadows; never WS without them.
        if not mobArg:hasStatusEffect(xi.effect.COPY_IMAGE) then
            return
        end

        if mobArg:getLocalVar('matsuiWsLock') ~= 0 or not canAct(mobArg) then
            return
        end

        local battleTarget = mobArg:getTarget()
        if not battleTarget or not battleTarget:isAlive() then
            return
        end

        local m = mobArg:getMaster()
        local skillId = nil
        local hint = nil

        if mobArg:getLocalVar('matsuiAssist') == 1 and m and m:getTP() >= 1000 then
            local opener = pickLightDarknessOpener(
                mobArg:getLocalVar('matsuiLastP'),
                mobArg:getLocalVar('matsuiLastS'),
                mobArg:getLocalVar('matsuiLastT')
            )
            if opener then
                skillId = opener.id
                hint = opener.hint
            end
        end

        -- Dump random WS at 3000 if assist conditions are not met.
        if not skillId and tp >= 3000 then
            skillId = WS_POOL[math.random(#WS_POOL)]
            hint = 'Opening — follow for Light or Darkness if you can!'
        end

        if not skillId then
            return
        end

        if hint then
            say(m, hint)
        end

        mobArg:setLocalVar('matsuiWsLock', 1)
        mobArg:useMobAbility(skillId, battleTarget)
    end)

    -- Master Lv2 SC property → assist mode (open when master has 1000+ TP).
    if master then
        master:addListener('WEAPONSKILL_USE', 'MATSUI_MASTER_LV2_' .. mob:getID(), function(player, target, skill, tp, action, damage)
            local trust = nil
            for _, member in pairs(player:getPartyWithTrusts() or {}) do
                if member:getObjType() == xi.objType.TRUST and member:getID() == mob:getID() then
                    trust = member
                    break
                end
            end

            if not trust then
                return
            end

            local p, s, t = player:getWSSkillchainProp()
            if not (isLevel2Prop(p) or isLevel2Prop(s) or isLevel2Prop(t)) then
                return
            end

            -- Gravitation-only: no Distortion in kit — no reaction.
            if pickLightDarknessOpener(p, s, t) == nil then
                return
            end

            trust:setLocalVar('matsuiAssist', 1)
            trust:setLocalVar('matsuiLastP', p or 0)
            trust:setLocalVar('matsuiLastS', s or 0)
            trust:setLocalVar('matsuiLastT', t or 0)
            player:printToPlayer('Lv2 spotted — I will open Light/Darkness when you are at 1000 TP.', xi.msg.channel.PARTY, 'Matsui-P')
        end)
    end

    mob:addListener('WEAPONSKILL_USE', 'MATSUI_WS_UNLOCK', function(mobArg)
        mobArg:setLocalVar('matsuiWsLock', 0)
    end)
end

spellObject.onMobDespawn = function(mob)
    local master = mob:getMaster()
    if master then
        master:removeListener('MATSUI_MASTER_LV2_' .. mob:getID())
        say(master, 'How\'d I do? And don\'t say my alter ego did it better!')
    end
end

spellObject.onMobDeath = function(mob)
    local master = mob:getMaster()
    if master then
        master:removeListener('MATSUI_MASTER_LV2_' .. mob:getID())
    end
end

return spellObject
