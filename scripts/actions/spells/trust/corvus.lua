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
-- *** TUNING NOTE ***: a Trust has no real ranged weapon, so ranged-attack base
-- damage leans on the mob_pools cmbDmgMult (250) + the ranged mods below rather
-- than a weapon's DMG. If in-game testing shows his shots hitting soft, the
-- levers are: cmbDmgMult (trust_corvus.sql), the RATT/RACC values here, and the
-- weaponskill settings at the bottom. Verify and tune against live content.
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

    -- Ranged DD: he shoots, he never swings. Stay 12y back and fire from there.
    mob:setAutoAttackEnabled(false)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.LONG_RANGE)

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

    -- ---- Ranged offense ----------------------------------------------------
    -- Ranged damage ratio is RATT vs the target's DEF; RACC must clear a lv150
    -- boss's high evasion or every shot misses. AGI feeds ranged attack/acc/crit,
    -- DEX feeds crit rate, STR adds to ranged damage. Store TP shortens the road
    -- to each weaponskill; Snapshot / Rapid Shot speed the shots themselves;
    -- Double Shot fires a free second shot; the crit mods spike the damage.
    mob:addMod(xi.mod.RATT, xi.trust.modGrowthValMax(mob, 200))
    mob:addMod(xi.mod.RATT, 1200)                                   -- flat ranged attack to drive damage through boss DEF
    mob:addMod(xi.mod.RACC, xi.trust.modGrowthValMax(mob, 250))
    mob:addMod(xi.mod.RACC, 800)                                    -- flat ranged accuracy to clear lv150 evasion
    -- Attack/Accuracy too, so melee-skill weaponskills (if his WS resolve to
    -- melee) still land and hit hard alongside the ranged ones.
    mob:addMod(xi.mod.ATT, xi.trust.modGrowthValMax(mob, 150))
    mob:addMod(xi.mod.ATT, 800)
    mob:addMod(xi.mod.ACC, xi.trust.modGrowthValMax(mob, 200))
    mob:addMod(xi.mod.ACC, 600)

    mob:addMod(xi.mod.STR, 200)
    mob:addMod(xi.mod.DEX, 250)
    mob:addMod(xi.mod.AGI, 400)

    mob:addMod(xi.mod.STORETP,          500)                        -- reach weaponskills fast
    mob:addMod(xi.mod.SNAPSHOT,         50)                         -- faster ranged attack delay
    mob:addMod(xi.mod.RAPID_SHOT,       100)                        -- rapid-shot proc (faster shot + double-damage chance)
    mob:addMod(xi.mod.DOUBLE_SHOT_RATE, 80)                         -- ~80% chance of a free second shot
    mob:addMod(xi.mod.CRITHITRATE,      30)                         -- +30% critical hit rate

    -- ---- Weaponskills: hold TP to close the party's skillchains, but fire the
    -- HIGHEST-available WS the moment TP hits 1000 so he never sits on TP. ----
    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.HIGHEST, 1000)

    -- ---- Ranged auto-shots: the bread-and-butter damage. The gambit reaction
    -- tuple MUST have 3 elements to parse (lua_baseentity.cpp addGambit); the
    -- selector/arg are ignored for RATTACK -- the engine just calls RangedAttack.
    -- ALWAYS, so he fires every time he's off cooldown and in range. ----
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.RATTACK, ai.s.SPECIFIC, 0 })
end

spellObject.onMobDespawn = function(mob)
    -- Silent on purpose: pool 5902 (the Curilla page) would mis-name him.
end

spellObject.onMobDeath = function(mob)
    -- Same as above.
end

return spellObject
