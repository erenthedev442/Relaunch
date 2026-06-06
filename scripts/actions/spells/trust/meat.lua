-----------------------------------
-- Trust: Meat, the Immovable  --  the ULTIMATE TANK
-- Spell ID: 899 (repurposed Excenmille) | Pool ID: 5899 | Model: tiny Tarutaru -- Koru-Moru trust model 0x0BF1 (species 255, kept for stats)
--
-- The Trust menu shows "Excenmille" client-side; the summoned tiny Tarutaru is
-- named "Meat" over its head and in the party list (mob_pools.packet_name).
-- SQL: modules/custom/sql/trust_meat.sql.  REQUIRES a map-server restart.
--
-- DESIGN (per request -- "ultimate tank, can't be killed, always keeps hate,
-- minimal DPS, soak all the damage"):
--
--   * CANNOT DIE -- setUnkillable() floors HP at 1 on any lethal hit
--     (battleentity.cpp::addHP), backed by ~100k HP, -50% damage taken (the
--     engine cap), huge DEF/MDEF, and TOTAL status immunity so it can never be
--     slept / amnesia'd / doomed off the job.
--
--   * ALWAYS HOLDS HATE -- Mod::ENMITY +100 (the engine cap: every enmity
--     action lands DOUBLE) plus the proven PLD tank loop: Provoke on cooldown
--     (the constant taunt), Flash, and Sentinel. The enemy attacks whoever has
--     the highest enmity, so it focuses Meat -> Meat soaks the single-target
--     damage for the party.
--
--   * MINIMAL DPS -- no offensive mods, cmbDmgMult 10 (mob_pools) and no native
--     TP moves (skill_list_id 0). It swings only to keep enmity flowing.
--
-- NOTE: trusts are TYPE_TRUST, so the Lua addEnmity() API no-ops for them -- hate
-- is held purely through the engine combat paths (Provoke/Flash/Sentinel/being
-- hit), the same way every stock PLD tank trust holds it. Enmity governs only
-- SINGLE-TARGET focus; AoE damage still splashes the party (no taunt stops AoE).
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
    -- FJB NAME FIX: set isRenamed=true so the name shows over the head and in chat.
    -- With a player-model (equipped) look, the spawn entity_update packet writes the
    -- 20-byte look over the name bytes at 0x34 and blanks it. isRenamed makes the
    -- engine emit the name AFTER the look at 0x44 (see entity_update.cpp:539), the
    -- same path the player_trusts framework relies on. 2nd arg = silent (no log spam).
    mob:renameEntity('Meat', true)

    -- Meat wades INTO melee and swings (unlike the backline Skoll). Chip damage
    -- keeps cumulative enmity flowing; the taunts below do the heavy lifting.
    mob:setAutoAttackEnabled(true)

    -- ===================================================================
    -- CANNOT DIE
    -- setUnkillable floors HP at 1 on any lethal hit; the status-immunity kit
    -- further guarantees it can never be CC'd into uselessness.
    -- ===================================================================
    mob:setUnkillable(true)

    -- ---- Maxed bulk (int16-safe HP: each single mod value must stay <= 32767) --
    mob:addMod(xi.mod.HP,  30000)
    mob:addMod(xi.mod.HPP, 240)                                  -- ~100k HP (5-digit display cap)
    mob:addMod(xi.mod.DEF,  xi.trust.modGrowthValMax(mob, 200))  -- huge physical defense
    mob:addMod(xi.mod.MDEF, xi.trust.modGrowthValMax(mob, 200))  -- huge magic defense
    mob:addMod(xi.mod.MEVA, xi.trust.modGrowthValMax(mob, 150))  -- magic evasion
    mob:addMod(xi.mod.EVA,  xi.trust.modGrowthValMax(mob, 100))  -- physical evasion
    mob:addMod(xi.mod.DMG,  -5000)                               -- -50% damage taken (the engine cap, all types)
    mob:addMod(xi.mod.SHIELDBLOCKRATE, 70)                       -- blocks like a wall
    mob:setMobMod(xi.mobMod.CAN_SHIELD_BLOCK, 1)                 -- carries a shield (enables Shield Bash + blocking)
    mob:addMod(xi.mod.REGEN, 500)                                -- passive heal (gravy -- it's unkillable)

    -- ---- ALWAYS KEEP HATE ----
    -- Mod::ENMITY is a +/-% on ALL enmity generated, clamped to [-50, +100];
    -- +100 = max, so every Provoke / Flash / Sentinel / swing lands double hate.
    mob:addMod(xi.mod.ENMITY, 100)

    -- ...but +100% of a TINY number is still tiny, and THAT is why Meat was
    -- losing hate. Cumulative Enmity (CE) -- the permanent kind that decides who
    -- the mob fights -- is built mainly from DAMAGE DEALT: a hit grants
    -- CE = 80/dmgMod * damage straight toward the 30000 cap
    -- (enmity_container.cpp::UpdateEnmityFromDamage). Meat deals almost nothing
    -- (cmbDmgMult 10, no TP moves), so it earns almost no CE, while Provoke/Flash
    -- give mostly VOLATILE enmity that decays 60/s. Net: a geared DD out-CEs the
    -- taunt loop in seconds and rips hate away.
    --
    -- Fix: feed Meat the CE it can't earn. Every combat tick, slam CE+VE up to
    -- the enmity cap on EVERY mob it should be holding -- not just its current
    -- target but the whole crowd-control pull -- so its hate is unbeatable and
    -- nothing slips back onto a squishy party member.
    --
    -- A trust CANNOT add enmity to ITSELF (meat:addEnmity(...) no-ops for
    -- TYPE_TRUST as the caller -- lua_baseentity.cpp), so we add it from the
    -- other side: enemy:addEnmity(meat, CE, VE), which the engine allows for any
    -- non-NPC gainer and clamps to map.ENMITY_CAP (30000) for us.
    --
    -- "Everything it should hold" = every mob already aggroed to Meat
    -- (getNotorietyList) PLUS every mob aggroed to a party member it protects
    -- (each member's getNotorietyList). The party half is the crowd-control
    -- fix: a freshly pulled mob sits on the PULLER's enmity, not Meat's, so
    -- without this Meat could only grab adds one slow Provoke at a time; with it
    -- Meat rips the entire pull onto itself the very next tick.
    -- SAME-ZONE ONLY: pinning a mob in another zone would make it chase an
    -- absent Meat and leash off whoever is actually fighting it.
    --   Lower HATE_CE / HATE_VE if you want Meat merely dominant rather than
    --   cap-pinned (e.g. so an intentional puller can still pull off it).
    local HATE_CE = 30000   -- Cumulative Enmity (permanent) -> pins Meat at cap
    local HATE_VE = 30000   -- Volatile Enmity (decays 60/s) -> refreshed each tick
    mob:addListener('COMBAT_TICK', 'MEAT_HATE_PIN', function(mobArg)
        local myZone = mobArg:getZoneID()
        local seen   = {}

        -- Slam Meat's hate to the cap on one foe (same-zone, alive, not self;
        -- deduped so a mob shared across party lists is only pinned once).
        local function pin(foe)
            if not foe then
                return
            end
            local id = foe:getID()
            if id == mobArg:getID() or seen[id] then
                return
            end
            seen[id] = true
            if foe:getZoneID() == myZone and foe:isAlive() then
                foe:addEnmity(mobArg, HATE_CE, HATE_VE)
            end
        end

        local function pinList(list)
            if list then
                for _, foe in ipairs(list) do
                    pin(foe)
                end
            end
        end

        -- 1) Everything already aggroed to Meat.
        pinList(mobArg:getNotorietyList())

        -- 2) The crowd-control pull: every mob aggroed to each party member
        --    (ForParty yields the lone master when solo, so this covers both).
        local master = mobArg:getMaster()
        if master then
            local party = master:getParty()
            if party and #party > 0 then
                for _, member in ipairs(party) do
                    pinList(member:getNotorietyList())
                end
            else
                pinList(master:getNotorietyList())
            end
        end
    end)

    -- ---- Cast reliably while being pounded (so Flash / cures don't whiff) ----
    mob:addMod(xi.mod.FASTCAST, 30)
    mob:addMod(xi.mod.SPELLINTERRUPT, 50)   -- +50% spell-interruption resist
    mob:addMod(xi.mod.MP,  30000)           -- int16-safe MP pool for Flash / buffs / cures
    mob:addMod(xi.mod.MPP, 100)

    -- ---- TOTAL status immunity (cannot be CC'd off the hate game) ----
    -- Every bit in xi.immunity (same kit as Skoll): a tank that can be slept,
    -- amnesia'd, silenced, or doomed is not the "ultimate" tank.
    mob:addImmunity(
        xi.immunity.SILENCE  + xi.immunity.LIGHT_SLEEP + xi.immunity.DARK_SLEEP +
        xi.immunity.STUN     + xi.immunity.TERROR      + xi.immunity.PETRIFY    +
        xi.immunity.PARALYZE + xi.immunity.ADDLE       + xi.immunity.GRAVITY    +
        xi.immunity.BIND     + xi.immunity.SLOW        + xi.immunity.BLIND      +
        xi.immunity.POISON   + xi.immunity.PLAGUE      + xi.immunity.ASPIR      +
        xi.immunity.ELEGY    + xi.immunity.REQUIEM     + xi.immunity.DISPEL)

    -- Amnesia / Doom / Curse have no immunity bit -- ward them on the status tick.
    -- (Amnesia would block Provoke -> lost hate; Doom would otherwise kill it.)
    -- Strip on the TICK, not EFFECT_GAIN (gaining fires mid-AddStatusEffect; the
    -- engine reuses the pointer right after, so removing it there is a UAF).
    mob:addMod(xi.mod.STATUSRES, 100)
    mob:addListener('EFFECTS_TICK', 'MEAT_AILMENT_WARD', function(mobArg)
        for _, eff in ipairs({ xi.effect.AMNESIA, xi.effect.DOOM, xi.effect.CURSE_I, xi.effect.CURSE_II }) do
            if mobArg:hasStatusEffect(eff) then
                mobArg:delStatusEffectSilent(eff)
            end
        end
    end)

    -- ===================================================================
    -- HATE GAMBITS (engine enmity paths; the proven PLD tank loop)
    -- Evaluated top-to-bottom -- Provoke-on-ALWAYS is the heartbeat taunt
    -- (the JA's own recast gates it, so it never spams).
    -- ===================================================================
    -- Provoke -- the heartbeat taunt (its own JA recast gates it).
    mob:addGambit(ai.t.SELF,   { ai.c.ALWAYS, 0 },                     { ai.r.JA, ai.s.SPECIFIC, xi.ja.PROVOKE                })
    -- Divine Emblem fires just before Flash -> a hugely enmity-enhanced Flash.
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.FLASH    }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.DIVINE_EMBLEM          })
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.FLASH    }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.FLASH         })
    -- Sentinel -- big enmity + defense spike.
    mob:addGambit(ai.t.SELF,   { ai.c.NOT_STATUS, xi.effect.SENTINEL }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SENTINEL               })
    -- Shield Bash -- enmity + stun (uses the shield enabled above; recast gates it).
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 },                     { ai.r.JA, ai.s.SPECIFIC, xi.ja.SHIELD_BASH            })
    -- Warcry -- WAR enmity burst (recast when it wears off).
    mob:addGambit(ai.t.SELF,   { ai.c.NOT_STATUS, xi.effect.WARCRY   }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.WARCRY                })
    -- (Tomahawk intentionally omitted: it THROWS ammo, and a trust carries none,
    --  so the engine logged "[warn] Invalid entity type calling function (meat)"
    --  [removeAmmo] on every recast. Provoke is the taunt -- no ammo required.)

    -- ---- Self mitigation buffs (kept up; gravy on an unkillable wall) ----
    mob:addGambit(ai.t.SELF,   { ai.c.NOT_STATUS, xi.effect.REPRISAL }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.REPRISAL      })
    mob:addGambit(ai.t.SELF,   { ai.c.NOT_STATUS, xi.effect.PHALANX  }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.PHALANX       })
    mob:addGambit(ai.t.SELF,   { ai.c.NOT_STATUS, xi.effect.PROTECT  }, { ai.r.MA, ai.s.HIGHEST,  xi.magic.spellFamily.PROTECT  })

    -- ---- Backup self-heal (rarely needed -- it cannot die -- but stays topped) ----
    mob:addGambit(ai.t.SELF,   { ai.c.HPP_LT, 50 },                    { ai.r.MA, ai.s.HIGHEST,  xi.magic.spellFamily.CURE     })

    -- Benign opener cadence for completeness; with skill_list_id 0 there are no
    -- native TP moves to fire, so this adds no DPS (minimal-DPS by design).
    mob:setTrustTPSkillSettings(ai.tp.OPENER, ai.s.RANDOM, 2000)
end

spellObject.onMobDespawn = function(mob)
end

spellObject.onMobDeath = function(mob)
    -- Should never fire -- Meat is unkillable. Left intentionally silent.
end

return spellObject
