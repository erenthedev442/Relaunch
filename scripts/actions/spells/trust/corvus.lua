-----------------------------------
-- Trust: Corvus, the Black Arrow
-- Spell ID: 902 (repurposed Curilla)  |  Pool ID: 5902
-- Trust menu shows "Curilla" client-side; the summoned marksman is named "Corvus".
--
-- Lore: They say the Black Arrow never drew a breath in life -- only a bowstring.
-- A marksman of the old wars who loosed his last shot at something that should
-- not have been killable, and killed it anyway. The Void kept him for the trick.
-- Now he stands at the back of the line, says nothing, and puts a shot through
-- whatever his champion is looking at -- again, and again, and again.
--
-- Role: PURE ranged damage dealer. Stays at long range (12y), never melees, and
-- fills the fight with ranged attacks + weaponskills. Threat is halved
-- (Mod::ENMITY -50) so his damage rides BEHIND the master. Immune to every
-- status ailment so his fire never gets shut off.
--
-- Job setup (mob_pools 5902): main RNG / sub SAM (Store TP for faster WS).
--
-- Unlock: bought from the Void Keeper NPC in GM Home (cheaper than the support
-- trusts -- see modules/custom/lua/trust_skoll.lua).
--
-- *** DAMAGE MODEL ***: a Trust has no real bow (ranged weapon DMG = 0), so his
-- shots are powered by MODS, not a weapon: RANGED_DMG_RATING + the RANGED_DAMAGE_
-- OFFSET / BASE_DAMAGE_MULTIPLIER mobMods build the "bow" DMG, and RATT drives the
-- hit ratio. See the RANGED DAMAGE block in onMobSpawn for the dials. He is sized
-- to be a real DPS at lv150; verify vs live content and adjust RANGED_DMG_RATING /
-- RATT to taste.
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
    -- Name shows over the head + in the party list. true = silent (same path Gemma uses).
    mob:renameEntity('Corvus', true)

    -- Ranged DD: he shoots, he never swings. He maintains 10y from the target --
    -- close enough to stay in range of every ranged attack, far enough to never
    -- stand in melee. He follows target movement so he never falls out of range,
    -- but 10y isn't enough to look like "running away."
    mob:setAutoAttackEnabled(false)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, 10)

    -- ---- Survivability (int16 trap: Mod::HP/HPP are int16, so a single value
    -- must stay <= 32767; a flat 99999 overflows negative and he dies on spawn).
    -- (base + 30000) x 3.4 ~= 100k, which caps at the 99999 client display. ----
    mob:addMod(xi.mod.HP,   30000)
    mob:addMod(xi.mod.HPP,  240)
    mob:addMod(xi.mod.DEF,  xi.trust.modGrowthValMax(mob, 100))
    mob:addMod(xi.mod.MDEF, xi.trust.modGrowthValMax(mob, 100))
    mob:addMod(xi.mod.EVA,  xi.trust.modGrowthValMax(mob, 100))
    mob:addMod(xi.mod.MEVA, xi.trust.modGrowthValMax(mob, 150))

    -- ---- Status immunity (true block, not a resist roll) -- a slept/stunned DD
    -- is dead weight. Every bit in the xi.immunity enum (same set as Gemma). ----
    mob:addImmunity(
        xi.immunity.SILENCE  + xi.immunity.LIGHT_SLEEP + xi.immunity.DARK_SLEEP +
        xi.immunity.STUN     + xi.immunity.TERROR      + xi.immunity.PETRIFY    +
        xi.immunity.PARALYZE + xi.immunity.ADDLE       + xi.immunity.GRAVITY    +
        xi.immunity.BIND     + xi.immunity.SLOW        + xi.immunity.BLIND      +
        xi.immunity.POISON   + xi.immunity.PLAGUE      + xi.immunity.ASPIR      +
        xi.immunity.ELEGY    + xi.immunity.REQUIEM     + xi.immunity.DISPEL)

    -- Amnesia / Doom / Curse have no immunity bit: resist them hard, then strip
    -- any that slip through on the next status tick (the safe place -- removing
    -- on EFFECT_GAIN is a use-after-free).
    mob:addMod(xi.mod.STATUSRES, 100)
    mob:addListener('EFFECTS_TICK', 'CORVUS_AILMENT_WARD', function(mobArg)
        for _, eff in ipairs({ xi.effect.AMNESIA, xi.effect.DOOM, xi.effect.CURSE_I, xi.effect.CURSE_II }) do
            if mobArg:hasStatusEffect(eff) then
                mobArg:delStatusEffectSilent(eff)
            end
        end
    end)

    -- ---- Threat control: hard DPS, but he must never out-hate the master. ----
    mob:addMod(xi.mod.ENMITY, -50) -- halve all the hate his shots generate

    -- ---- RANGED DAMAGE -- the whole point of him. ----
    -- No real bow: weapon DMG is built from mods (mobutils::GetWeaponDamage(SLOT_RANGED)).
    --     rangedWeaponDmg = (baseByLvl + RANGED_DAMAGE_OFFSET + RANGED_DMG_RATING) x BASE_DAMAGE_MULTIPLIER%
    --     shot            = (rangedWeaponDmg + fSTR) x pDIF
    -- RANGED_DMG_RATING is the #1 damage dial. BASE_DAMAGE_MULTIPLIER% scales the whole base.
    -- RATT vs boss DEF determines pDIF (higher RATT -> higher pDIF -> more damage).
    mob:addMod(xi.mod.RANGED_DMG_RATING,              3500)         -- main bow-damage dial
    mob:setMobMod(xi.mobMod.RANGED_DAMAGE_OFFSET,     500)          -- base offset
    mob:setMobMod(xi.mobMod.BASE_DAMAGE_MULTIPLIER,   250)          -- x2.5 on the ranged base
    mob:addMod(xi.mod.MAIN_DMG_RATING,                2000)         -- feeds Jishnu's Radiance WS damage

    -- Drive pDIF to cap against lv150-boss DEF and guarantee every shot lands.
    mob:addMod(xi.mod.RATT, xi.trust.modGrowthValMax(mob, 250))
    mob:addMod(xi.mod.RATT, 4000)                                   -- flat ranged attack vs heavy DEF
    mob:addMod(xi.mod.RACC, xi.trust.modGrowthValMax(mob, 250))
    mob:addMod(xi.mod.RACC, 1500)                                   -- flat accuracy vs lv150 evasion

    mob:addMod(xi.mod.STR, 500)                                     -- fSTR into every shot
    mob:addMod(xi.mod.DEX, 300)                                     -- crit rate
    mob:addMod(xi.mod.AGI, 700)                                     -- ranged attack + accuracy + Jishnu's WS mod

    -- Volume: fast cadence + near-constant double shots + high crit rate.
    -- SNAPSHOT is applied to the weaponless ranged delay in trust_controller.cpp.
    mob:addMod(xi.mod.SNAPSHOT,         50)                         -- halves the base ranged delay
    mob:addMod(xi.mod.RAPID_SHOT,       100)                        -- rapid-shot procs
    mob:addMod(xi.mod.DOUBLE_SHOT_RATE, 100)                        -- second shot almost every volley
    mob:addMod(xi.mod.CRITHITRATE,      40)                         -- +40% crit rate
    mob:addMod(xi.mod.STORETP,          500)                        -- charge TP fast for Jishnu's

    -- ---- WEAPONSKILL: Jishnu's Radiance (player WS 202) at 1000 TP. ----
    -- Wired via mob_skill_lists (skill_list_id 5902, mob_skill_id 202 <= 255
    -- -> treated as player WS by trustutils::LoadTrustStatsAndSkills).
    -- setTrustTPSkillSettings(ASAP, RANDOM, 1000) fires via TryTrustSkill()
    -- the moment TP >= 1000. The gambit loop does NOT handle ai.r.WS -- only
    -- TryTrustSkill does -- so the old ai.r.WS gambit was silently a no-op.
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 1000)

    -- ---- Ranged auto-shots: bread-and-butter damage + TP building. ----
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.RATTACK, ai.s.SPECIFIC, 0 })
end

spellObject.onMobDespawn = function(mob)
    -- Silent on purpose: pool 5902 (the Curilla page) would mis-name him.
end

spellObject.onMobDeath = function(mob)
    -- Same as above.
end

return spellObject
