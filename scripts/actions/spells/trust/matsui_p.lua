-----------------------------------
-- Trust: Matsui-P
-- Spell ID: 1004 | Pool ID: 6004
-- Menu / DAT: Excenmille (S). Nametag: matsui-p (Lua overlay).
-- Look: model 3121 (ROM/310/13.DAT). NIN/BLM year-round kit.
-- Do not /ma "Matsui-P" — that is seasonal spell 1003 and R0s the client.
-- Do not renameEntity to the retail string 'Matsui-P' (same DAT key).
-----------------------------------
---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    -- Overlay only. Must run before CTrustEntity::Spawn sends 0x67.
    mob:renameEntity('matsui-p', true)

    local master = mob:getMaster()
    if not master then
        return
    end

    local lvl = mob:getMainLvl()
    local upgraded = math.max(1, master:getCharVar('TrustUpgraded') or 1)
    local power = lvl * upgraded

    mob:addMod(xi.mod.HP, power)
    mob:addMod(xi.mod.STR, math.floor(power * 0.5))
    mob:addMod(xi.mod.DEX, math.floor(power * 0.5))
    mob:addMod(xi.mod.INT, math.floor(power * 0.5))
    mob:addMod(xi.mod.ATT, math.floor(power * 1.5))
    mob:addMod(xi.mod.ACC, power)
    mob:addMod(xi.mod.MATT, power)
    mob:addMod(xi.mod.MACC, power)
    mob:addMod(xi.mod.HASTE_MAGIC, 1500)
    mob:addMod(xi.mod.FASTCAST, 80)
    mob:addMod(xi.mod.CRITHITRATE, 32 + math.floor(power / 12))
    mob:addMod(xi.mod.DOUBLE_ATTACK, 55)
    mob:addMod(xi.mod.TRIPLE_ATTACK, 15)
    mob:addMod(xi.mod.STORETP, 50 + math.floor(power / 4))
    mob:addMod(xi.mod.ALL_WSDMG_ALL_HITS, 180 + math.floor(power / 4))
    mob:addMod(xi.mod.MAIN_DMG_RATING, 80 + math.floor(power / 3))
    mob:addMod(xi.mod.MAGIC_DAMAGE, math.floor(power * 0.75))
    mob:addMod(xi.mod.MAGIC_BURST_BONUS_UNCAPPED, 40)
    mob:addMod(xi.mod.MP, 800 + power * 6)
    mob:addMod(xi.mod.REFRESH, 20)
    mob:addMod(xi.mod.DUAL_WIELD, 15)
    mob:addMod(xi.mod.UTSUSEMI_BONUS, 1)
    mob:setMP(mob:getMaxMP())

    -- Shadows / interrupt, then Futae + MB the window he just closed.
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.MIGAWARI }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.MIGAWARI_ICHI })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.COPY_IMAGE }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.UTSUSEMI })
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_WS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_MS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.SELF, { ai.c.HPP_LT, 40 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.MANA_WALL })
    -- Only siphon when truly dry. A 30% trip + post-spawn max-MP mods made him
    -- Aspir-loop on summon (current MP stayed at the tiny NIN pool).
    mob:addGambit(ai.t.SELF, { ai.c.MPP_LT, 15 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.ASPIR }, 45)
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.INNIN }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.INNIN })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.FUTAE }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.FUTAE })
    mob:addGambit(ai.t.TARGET, { ai.c.MB_AVAILABLE, 0 }, { ai.r.MA, ai.s.MB_ELEMENT, xi.magic.spellFamily.NONE })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.STORE_TP }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.KAKKA_ICHI })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.SUBTLE_BLOW_PLUS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.MYOSHU_ICHI })
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.BURN }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.BURN }, 60)
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.INHIBIT_TP }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.YURIN_ICHI }, 60)
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.ATTACK_DOWN }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.AISHA_ICHI }, 60)
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_SC_AVAILABLE, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.NONE }, 60)

    -- At 1000 TP: random Hi / Kamu / Metsu / Shun. If a skillchain is up, use
    -- the WS that forms the best close, then the MB gambit above bursts it.
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 1000)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    master:printToPlayer('matsui-p reporting. Try to keep up.', xi.msg.channel.PARTY, 'matsui-p')
end

spellObject.onMobDespawn = function(mob)
end

spellObject.onMobDeath = function(mob)
end

return spellObject
