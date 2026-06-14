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

    -- ---- RANGED DAMAGE -- the whole point of him; sized so he's worth 15M. ----
    -- A Trust has NO real bow, so its ranged weapon DMG is 0 and RATT alone just
    -- multiplies zero (that's why an un-tuned ranged trust hits soft). The ranged
    -- weapon DMG is built entirely from mods -- mobutils::GetWeaponDamage(SLOT_
    -- RANGED) -- and attack.cpp resolves each shot as:
    --     shot = (rangedWeaponDmg + fSTR) x damageRatio
    --     rangedWeaponDmg = (baseByLvl + RANGED_DAMAGE_OFFSET + RANGED_DMG_RATING)
    --                       x BASE_DAMAGE_MULTIPLIER
    --     damageRatio climbs with RATT vs the target's DEF.
    -- So THESE THREE MODS ARE HIS BOW, and RATT turns each shot into a heavy hit.
    mob:addMod(xi.mod.RANGED_DMG_RATING,              800)          -- his "bow" DMG -- the #1 damage dial
    mob:setMobMod(xi.mobMod.RANGED_DAMAGE_OFFSET,     300)          -- more ranged base damage
    mob:setMobMod(xi.mobMod.BASE_DAMAGE_MULTIPLIER,   175)          -- x1.75 on the ranged base
    mob:addMod(xi.mod.MAIN_DMG_RATING,                500)          -- feeds his Apex Arrow (it scales off getWeaponDmg)

    -- Drive the damage ratio to its cap even against lv150-boss DEF, and make
    -- sure every shot LANDS through boss evasion.
    mob:addMod(xi.mod.RATT, xi.trust.modGrowthValMax(mob, 250))
    mob:addMod(xi.mod.RATT, 2500)                                   -- flat ranged attack: keeps pDIF near cap vs heavy DEF
    mob:addMod(xi.mod.RACC, xi.trust.modGrowthValMax(mob, 250))
    mob:addMod(xi.mod.RACC, 1200)                                   -- flat ranged accuracy to clear lv150 evasion

    mob:addMod(xi.mod.STR, 300)                                     -- fSTR added to every shot
    mob:addMod(xi.mod.DEX, 250)                                     -- crit rate
    mob:addMod(xi.mod.AGI, 500)                                     -- ranged attack + accuracy + crit

    -- Volume + spikes: fire fast, fire twice, crit hard.
    mob:addMod(xi.mod.SNAPSHOT,         50)                         -- shorter ranged delay -> faster shots (the cap)
    mob:addMod(xi.mod.RAPID_SHOT,       100)                        -- rapid-shot procs (faster shot + double-damage chance)
    mob:addMod(xi.mod.DOUBLE_SHOT_RATE, 100)                        -- a second shot nearly every volley
    mob:addMod(xi.mod.CRITHITRATE,      40)                         -- +40% critical hit rate
    mob:addMod(xi.mod.STORETP,          500)                        -- feed any weaponskill fast

    -- TUNING DIALS after a live test: for the shot stream, RANGED_DMG_RATING (bow
    -- DMG) + the flat RATT are the big two and BASE_DAMAGE_MULTIPLIER scales it
    -- all; for the Apex Arrow spike, MAIN_DMG_RATING above. (No setTrustTPSkill-
    -- Settings on purpose: a weaponless Trust has no weaponskills, and its
    -- CLOSER_UNTIL_TP would make him sit on TP instead of firing the gambit below.)

    -- ---- HARD HITTER: Apex Arrow at 1000 TP -- a Humanoid Archery weaponskill
    -- (mob skill id 203) that IGNORES 15-50% of the enemy's DEF (TP-scaled) and
    -- hits at fTP 3.0. Fired via ai.r.MS / SPECIFIC -> controller->MobSkill ->
    -- Internal_MobSkill, which looses the EXACT skill with no skill-list needed.
    -- Its baseDamage = getWeaponDmg (fed by MAIN_DMG_RATING) and its ratio rides
    -- his big RATT, so it lands as a heavy spike. Sits ABOVE the auto-shot so it
    -- wins once TP is full; the TP_GTE self-gates its recast (TP drains on use).
    mob:addGambit(ai.t.TARGET, { ai.c.TP_GTE, 1000 }, { ai.r.MS, ai.s.SPECIFIC, 203 })

    -- ---- Ranged auto-shots: the bread-and-butter damage that also BUILDS the TP
    -- for Apex Arrow. The RATTACK reaction tuple MUST have 3 elements to parse
    -- (lua_baseentity.cpp addGambit); selector/arg are ignored -- the engine just
    -- calls RangedAttack. ALWAYS, so he fires whenever off cooldown and in range.
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.RATTACK, ai.s.SPECIFIC, 0 })
end

spellObject.onMobDespawn = function(mob)
    -- Silent on purpose: pool 5902 (the Curilla page) would mis-name him.
end

spellObject.onMobDeath = function(mob)
    -- Same as above.
end

return spellObject
