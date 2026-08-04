-----------------------------------
-- Trust: Fujito-PD
-- Spell 1020 / pool 6020. WAR/DNC Great Axe.
-- Implemented but DISABLED (not grantable) until an unlock path exists.
-- S-tier melee_dd (bruiser) power path.
--
-- Kit: Restraint / Tomahawk / Provoke / Haste Samba / Box Step /
-- Curing Waltz / Divine Waltz / Violent Flourish / Chocobo Jig II.
-- WS: Armor Break … Disaster (prefers Disaster via HIGHEST skill id).
-- Announces 1000 TP; after master uses a Lv2 SC property WS, switches to
-- OPENER (WS when master/party has 1000+ TP). Announces Light/Darkness follow-ups.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

-- Lv2 skillchain properties (Gravitation … Fragmentation).
local function isLevel2Prop(prop)
    return prop >= xi.skillchainType.GRAVITATION and prop <= xi.skillchainType.FRAGMENTATION
end

-- Flavor follow-up hints toward Light / Darkness after his WS.
local SC_FOLLOWUP =
{
    [82] = 'Sturmwind → follow with Distortion/Gravitation for Darkness, or Fusion for Light lines.',
    [83] = 'Armor Break → Impaction setup. Look for Light via Fragmentation/Fusion.',
    [84] = 'Keen Edge → Compression. Darkness line is open via Gravitation/Distortion.',
    [86] = 'Raging Rush → Impaction/Detonation. Fragmentation/Fusion toward Light.',
    [87] = 'Full Break → Distortion. Pair with Gravitation for Darkness.',
    [88] = 'Steel Cyclone → Distortion/Detonation. Darkness or Light depending on close.',
    [90] = "King's Justice → Fragmentation/Scission. Strong Light/Darkness bridge.",
    [92] = "Ukko's Fury → Light. Close Darkness only if the window already favors it.",
    [93] = 'Upheaval → Fusion/Compression. Light or Darkness depending on close.',
    [94] = 'Disaster → Gravitation. Close with Distortion for Darkness (or Fusion lines).',
}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    -- Client menu string may be missing for 1020; force the display name.
    mob:renameEntity('Fujito-PD', true)

    local master = mob:getMaster()
    if master then
        master:printToPlayer('Fujito-PD on set. Call action when you are ready.', xi.msg.channel.PARTY, 'Fujito-PD')
    end

    -- Retail notes: Regain+15, Store TP+25, Double Attack merits 5/5.
    -- (Global scaler already adds Store TP / DA; these are the flavor floors.)
    mob:addMod(xi.mod.REGAIN, 15)
    mob:addMod(xi.mod.STORETP, 25)
    mob:addMod(xi.mod.DOUBLE_ATTACK, 15)
    -- "Warcry Merits for the memes" — no Warcry JA, just a tiny duration nod.
    mob:addMod(xi.mod.WARCRY_DURATION, 5)

    -- WAR kit (no Warcry).
    mob:addGambit(ai.t.SELF, { ai.c.ALWAYS, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.RESTRAINT })
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.TOMAHAWK }, 180)
    mob:addGambit(ai.t.MASTER, { ai.c.HPP_LT, 50 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.PROVOKE })

    -- DNC kit.
    mob:addGambit(ai.t.SELF, { ai.c.NO_SAMBA, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.HASTE_SAMBA })
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.LETHARGIC_DAZE_5 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BOX_STEP }, 20)
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_WS, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.VIOLENT_FLOURISH })
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_MS, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.VIOLENT_FLOURISH })
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_JA, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.VIOLENT_FLOURISH })
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 50 }, { ai.r.JA, ai.s.HIGHEST_WALTZ, xi.ja.CURING_WALTZ })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_I }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.DIVINE_WALTZ })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_II }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.DIVINE_WALTZ })

    -- Default: hold to close; dump by 2000. HIGHEST favors Disaster (94) when opening.
    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.HIGHEST, 2000)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    -- Announce when he hits 1000 TP.
    mob:addListener('COMBAT_TICK', 'FUJITO_TP_ANNOUNCE', function(mobArg)
        local m = mobArg:getMaster()
        if not m then
            return
        end

        if mobArg:getTP() >= 1000 then
            if mobArg:getLocalVar('FujitoTpAnnounced') == 0 then
                mobArg:setLocalVar('FujitoTpAnnounced', 1)
                m:printToPlayer('TP 1000 — ready to skillchain!', xi.msg.channel.PARTY, 'Fujito-PD')
            end
        else
            mobArg:setLocalVar('FujitoTpAnnounced', 0)
        end

        -- Divine Waltz if multiple party members are red (<25%).
        if mobArg:getTP() < 400 then
            return
        end

        local party = m:getPartyWithTrusts()
        if not party then
            return
        end

        local red = 0
        for _, member in pairs(party) do
            if member:isAlive() and member:getHPP() < 25 then
                red = red + 1
            end
        end

        if red >= 2 then
            mobArg:useJobAbility(xi.ja.DIVINE_WALTZ, mobArg)
        end
    end)

    -- After combat: occasional Chocobo Jig II + Raising feature quip.
    mob:addListener('COMBAT_TICK', 'FUJITO_JIG', function(mobArg)
        if mobArg:isEngaged() then
            mobArg:setLocalVar('FujitoWasEngaged', 1)
            return
        end

        if mobArg:getLocalVar('FujitoWasEngaged') ~= 1 then
            return
        end

        mobArg:setLocalVar('FujitoWasEngaged', 0)

        if math.random(100) > 35 then
            return
        end

        local m = mobArg:getMaster()
        if m then
            m:printToPlayer('I created the Chocobo Raising feature, you know.', xi.msg.channel.PARTY, 'Fujito-PD')
        end

        mobArg:useJobAbility(xi.ja.CHOCOBO_JIG_II, mobArg)
    end)

    -- Master Lv2 SC property WS → assist mode (OPENER @ party 1000 TP).
    if master then
        master:addListener('WEAPONSKILL_USE', 'FUJITO_MASTER_LV2_' .. mob:getID(), function(player, target, skill, tp, action, damage)
            local trust = nil
            for _, member in pairs(player:getPartyWithTrusts() or {}) do
                if member:getObjType() == xi.objType.TRUST and member:getID() == mob:getID() then
                    trust = member
                    break
                end
            end

            if not trust or trust:getLocalVar('FujitoAssist') == 1 then
                return
            end

            -- Props are available while the master's WS state is still current.
            local p, s, t = player:getWSSkillchainProp()
            if isLevel2Prop(p) or isLevel2Prop(s) or isLevel2Prop(t) then
                trust:setLocalVar('FujitoAssist', 1)
                trust:setTrustTPSkillSettings(ai.tp.OPENER, ai.s.HIGHEST, 1000)
                player:printToPlayer('Lv2 skillchain spotted — I will open when you are at 1000 TP.', xi.msg.channel.PARTY, 'Fujito-PD')
            end
        end)
    end

    mob:addListener('WEAPONSKILL_USE', 'FUJITO_WS_HINT', function(mobArg, target, skill, tp, action, damage)
        local m = mobArg:getMaster()
        if not m then
            return
        end

        local hint = SC_FOLLOWUP[skill:getID()]
        if hint then
            m:printToPlayer(hint, xi.msg.channel.PARTY, 'Fujito-PD')
        end
    end)
end

spellObject.onMobDespawn = function(mob)
    local master = mob:getMaster()
    if master then
        master:removeListener('FUJITO_MASTER_LV2_' .. mob:getID())
    end
end

spellObject.onMobDeath = function(mob)
    local master = mob:getMaster()
    if master then
        master:removeListener('FUJITO_MASTER_LV2_' .. mob:getID())
    end
end

return spellObject
