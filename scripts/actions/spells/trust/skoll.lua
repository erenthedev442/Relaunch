-----------------------------------
-- Trust: Skoll, the Voidhound
-- Spell ID: 901 (repurposed Nanaa Mihgo)  |  Pool ID: 5901  |  Model: Fenrir Prime (species 246)
-- Trust menu shows "Nanaa Mihgo" client-side; the summoned wolf is named "Skoll".
--
-- Lore: In the old world, two wolves ran at the edge of time. Skoll hunted
-- the sun; Hati hunted the moon. When Odin the Doombringer was sealed in
-- the Nightmare Court, Skoll was left without a master. The Altar in
-- Provenance found him first. Now he runs at the side of the League's
-- champions -- silent, tireless, and enormous -- not fighting, but watching
-- over them the way a good hound watches over anyone foolish enough to walk
-- into danger.
--
-- Role: Primary support / debuffer, secondary nuker. Never auto-attacks. He
-- keeps the party topped, buffed and the enemy debuffed FIRST, then fills every
-- idle moment with elemental damage -- element-matched Ancient Magic II bursts
-- on the party's skillchains, and a free nuke otherwise. Threat is halved
-- (Mod::ENMITY -50) so his damage stays BEHIND the master, never pulling. He is
-- immune to every status ailment (sleep, silence, stun, paralyze, ...), so his
-- support can never be shut off.
--
-- Buffer kit (party):
--   Cure V (emergency < 25%, standard < 75%), Arise on the fallen,
--   wake-from-sleep Cure, Erase + full status-cure suite, Protectra V,
--   Shellra V, Haste II, Phalanx II, Regen V, self-Aquaveil
--
-- Bard songs (party AoE, sung on self -- FULL power via a granted Singing skill):
--   Victory March, Valor Minuet V, Sword Madrigal, Sentinel's Scherzo
--
-- Corsair rolls (party):
--   Chaos (Attack), Rogue's (Crit rate), Allies' (Skillchain dmg),
--   Wizard's (Magic Attack Bonus)
--
-- Debuffer kit (enemy):
--   Slow II, Paralyze II, Blind II,
--   Dia III, Silence (50%), Dispel (15%)
--
-- Damage (enemy) -- PRIMARY support always comes first; he only nukes in the gaps:
--   * Magic burst on the party's skillchains -- element-matched Ancient Magic II
--     (Flare/Freeze/Tornado/Quake/Burst/Flood II) + Comet for Dark. Biggest hits.
--   * Free nuke when no skillchain is open -- BEST_AGAINST_TARGET (the enemy's
--     weakest element; defaults to Flare II vs Odin). Filler damage.
--   Maxed (80%) fast cast lands the long Ancient Magic in the brief burst window;
--   Mod::ENMITY -50 keeps all this damage BEHIND the master.
--
-- Job setup (mob_pools 5901): main COR / sub RDM. COR main is REQUIRED for
-- Corsair rolls -- both the max-rolls cap and the roll's power key off main
-- job == COR (lua_baseentity.cpp addCorsairRoll / corsair.lua applyRoll).
-- RDM sub still supplies A+ Enfeebling / A Enhancing / B Healing at the
-- master's FULL level (trustutils.cpp computes sub-job skill at mLvl), so
-- every debuff (incl. Dia, which is Enfeebling), buff and cure keeps its
-- former RDM-tier potency. Nothing Skoll casts is Divine, so dropping WHM
-- costs nothing. COR/RDM grant no Singing skill, so onMobSpawn grants it
-- directly (mob:setSkillLevel, now engine-supported for trusts) -- without that
-- his songs would sit at ~1/4 strength; with it they run at full power.
--
-- Unlock: 500,000,000 gil (500M) from the Void Keeper NPC in GM Home (zone 210).
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
    -- FJB NAME FIX: set isRenamed=true so the name ("Gemma") shows over the head and
    -- in chat. With a player-model (equipped) look, the spawn entity_update packet
    -- writes the 20-byte look over the name bytes at 0x34 and blanks it. isRenamed
    -- makes the engine emit the name AFTER the look at 0x44 (entity_update.cpp:539),
    -- the same path the player_trusts framework relies on. 2nd arg = silent.
    mob:renameEntity('Gemma', true)

    -- Skoll does not fight. He watches.
    mob:setAutoAttackEnabled(false)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.NO_MOVE)

    -- ---- Survivability ------------------------------------------------
    -- MAXED HP -- but mind the int16 trap. Mod::HP / Mod::HPP are stored as int16
    -- (getMod returns int16), so any SINGLE mod value must stay <= 32767. A flat
    -- 99999 silently overflowed to ~ -31073 -> NEGATIVE max HP -> Skoll died the
    -- instant he spawned (the "vanishes when cast" bug). Fix: a safe flat HP plus
    -- a percentage -- (base + 30000) x 3.4 ~= 100k, which caps at the client's
    -- 5-digit (99999) display. (Trusts are exempt from the 9999 player HP clamp --
    -- UpdateHealth gates it on TYPE_PC -- and the party packet sends HP as uint32,
    -- so the big number both functions and shows; the modhp field is int32.)
    mob:addMod(xi.mod.HP,  30000)                                        -- flat HP (int16-safe: must be <= 32767)
    mob:addMod(xi.mod.HPP, 240)                                          -- +240% on top -> ~maxed (99999 display)
    mob:addMod(xi.mod.DEF,  xi.trust.modGrowthValMax(mob, 100))          -- physical defense
    mob:addMod(xi.mod.MDEF, xi.trust.modGrowthValMax(mob, 100))          -- magic defense
    mob:addMod(xi.mod.MEVA, xi.trust.modGrowthValMax(mob, 150))          -- magic evasion
    mob:addMod(xi.mod.EVA,  xi.trust.modGrowthValMax(mob, 80))           -- physical evasion

    -- ---- Status immunity -- a slept or silenced support trust is dead weight,
    -- so NOTHING lands on him. addImmunity ORs these bits into m_Immunity, which
    -- CanGainStatusEffect (status_effect_container.cpp) reads to BLOCK the effect
    -- OUTRIGHT -- true immunity, not a resist roll. This is every bit in the
    -- xi.immunity enum: sleep (light + dark), silence, stun, terror, petrify,
    -- paralyze, addle, gravity, bind, slow, blind, poison, plague, aspir, elegy,
    -- requiem, and dispel (so even his own buffs can't be stripped). Charm is
    -- already impossible -- the engine blocks it for anything with a master, which
    -- a trust always has. (Amnesia / Doom / Curse have no immunity bit -- they're
    -- warded separately, just below.)
    mob:addImmunity(
        xi.immunity.SILENCE  + xi.immunity.LIGHT_SLEEP + xi.immunity.DARK_SLEEP +
        xi.immunity.STUN     + xi.immunity.TERROR      + xi.immunity.PETRIFY    +
        xi.immunity.PARALYZE + xi.immunity.ADDLE       + xi.immunity.GRAVITY    +
        xi.immunity.BIND     + xi.immunity.SLOW        + xi.immunity.BLIND      +
        xi.immunity.POISON   + xi.immunity.PLAGUE      + xi.immunity.ASPIR      +
        xi.immunity.ELEGY    + xi.immunity.REQUIEM     + xi.immunity.DISPEL)

    -- ---- Amnesia / Doom / Curse ward -- the three ailments with no immunity bit.
    -- STATUSRES ("Resistance to All Status Ailments") makes them land far less
    -- often, and this EFFECTS_TICK listener strips any that slip through on the
    -- next status tick (~3s) -- well before Doom's countdown can kill him, Amnesia
    -- costs more than a roll, or Curse matters (he has 100k HP/MP anyway). It runs
    -- on the TICK, NOT EFFECT_GAIN: that event fires mid-AddStatusEffect and the
    -- engine keeps using the effect pointer right after, so removing it there is a
    -- use-after-free. The tick is the safe place to strip.
    mob:addMod(xi.mod.STATUSRES, 100)                                    -- "Resistance to All Status Ailments"
    mob:addListener('EFFECTS_TICK', 'SKOLL_AILMENT_WARD', function(mobArg)
        for _, eff in ipairs({ xi.effect.AMNESIA, xi.effect.DOOM, xi.effect.CURSE_I, xi.effect.CURSE_II }) do
            if mobArg:hasStatusEffect(eff) then
                mobArg:delStatusEffectSilent(eff)
            end
        end
    end)

    -- ---- Casting power (debuffs must stick; DoTs must hurt; nukes must CRUSH) ----
    -- Sized so Skoll is a real #2 damage dealer, not a tickle, against Odin
    -- (Provenance trial boss, lv150) and his MEVA 700 / MDEF 700 walls.
    --   * Nuke MAB ratio is (100 + MATT) / (100 + targetMDEF) (damage_spell.lua).
    --     vs Odin's 800 effective MDB, MATT ~1580 -> ~2.0x (old ~180 gave 0.35x).
    --   * MACC must beat MEVA 700 for BOTH bursts and free nukes -- and free nukes
    --     get NO magic-burst accuracy bonus, so this flat MACC is what carries them.
    mob:addMod(xi.mod.MACC,       xi.trust.modGrowthValMax(mob, 250))    -- debuff/nuke accuracy (level-scaled)
    mob:addMod(xi.mod.MACC,       6000)                                  -- flat magic accuracy; sized for Abyssea NMs (MEVA 2000-5000 flat + base)
    mob:addMod(xi.mod.MATT,       xi.trust.modGrowthValMax(mob, 80))     -- Dia tick damage
    mob:addMod(xi.mod.MATT,      1500)                                   -- Magic Attack to drive nukes through Odin's MDEF 700
    mob:addMod(xi.mod.HASTE_MAGIC, 1500)                                 -- 15% magic haste

    -- ---- Debuff DURATION -- make his enfeebles STICK on tough mobs. -----------
    -- enfeebling_spell.lua::calculateDuration multiplies the final duration by
    -- (1 + ENF_MAG_DURATION/100) BEFORE the resist step, so this stretches every
    -- enfeeble he lands: Slow / Paralyze / Blind, Silence (and
    -- Dia's DoT). It's a CASTER mod, so ONLY Skoll's casts
    -- are affected -- players and other content are untouched. His big MACC above
    -- already keeps partial-resists (which shorten duration) rare, so debuffs land
    -- long AND near-full.
    --   100 = double, 200 = triple, 300 = quadruple. Set this one number to taste.
    mob:addMod(xi.mod.ENF_MAG_DURATION, 100)                             -- +100% enfeeble duration (x2)

    -- ---- Threat control -- he nukes hard, but must stay BEHIND the master.
    -- Mod::ENMITY is a +/- % on all the hate he generates, clamped to [-50, +100]
    -- (enmity_container.cpp), so -50 is the floor: HALF the enmity per nuke / cure
    -- / buff. With the master tanking, that keeps Skoll off the top of the hate
    -- list. (If he somehow still pulls, this mod is already maxed -- the lever
    -- then is more enmity on the master, not here.)
    mob:addMod(xi.mod.ENMITY, -50)                                       -- halve hate: secondary DPS, never the tank

    -- ---- MAXED FAST CAST -- land the long Ancient Magic nukes inside the brief
    -- burst window. battleutils.cpp (~5832) reads Mod::FASTCAST as a DIRECT percent
    -- and clamps the base contribution to 50; for ELEMENTAL magic only, ELEMENTAL_
    -- CELERITY stacks on top up to an 80 cap -- the recognized "maxed" fast cast.
    -- FASTCAST 80 ALSO maxes the separate recast cut (FASTCAST/2, capped at 40%),
    -- so he re-nukes / re-buffs faster too. Result:
    --   elemental nukes : 50 (FASTCAST cap) + 30 (celerity) = 80% cast-time cut
    --   everything else : 50% cast-time cut, 40% recast cut
    -- (The old "200 = 20% (10:1 scale)" note was simply wrong -- no 10:1 scale
    --  exists; 200 just clamped to the same 50.)
    mob:addMod(xi.mod.FASTCAST,           80)                            -- caps the 50% cast cut + the 40% recast cut
    mob:addMod(xi.mod.ELEMENTAL_CELERITY, 30)                            -- nukes only: 50 -> 80% (the fast-cast cap)

    -- ---- Magic-burst damage -- "the most damaging spells in the game" must HURT.
    -- damage_spell.lua: burst dmg = base * (1.25 + chainCount/10) * (1 + capped + uncapped).
    -- Both mods are read /100; CAPPED is hard-capped at +40% (mod 40 = max),
    -- UNCAPPED has no cap. 40 + 40 = a 1.8x burst-bonus multiplier on top of the
    -- automatic element-match burst multiplier.
    mob:addMod(xi.mod.MAGIC_BURST_BONUS_CAPPED,   40)                    -- +40% (the cap)
    mob:addMod(xi.mod.MAGIC_BURST_BONUS_UNCAPPED, 40)                    -- +40% more (BLM JP/trait tier)

    -- ---- Magic crit -- occasional crit nukes for spikier DPS (damage_spell.lua).
    -- MAGIC_CRITHITRATE = % chance to add up to +40 MAB on a cast (the bonus is
    -- 10 + MAGIC_CRIT_DMG_INCREASE, capped at 40). MAGIC_CRITHITRATE_II = % chance
    -- for a flat 1.25x magic-crit multiplier. Both read via getMod -> work for trusts.
    mob:addMod(xi.mod.MAGIC_CRITHITRATE,       20)                       -- 20% chance: crit adds MAB
    mob:addMod(xi.mod.MAGIC_CRIT_DMG_INCREASE, 40)                       -- that MAB crit lands at the +40 cap
    mob:addMod(xi.mod.MAGIC_CRITHITRATE_II,    20)                       -- 20% chance: 1.25x crit multiplier

    -- ---- MP sustain -- MAXED so a heavy caster never dries up. Same int16 trap
    -- as HP: Mod::MP / Mod::MPP are int16, so each value must stay <= 32767 (a
    -- flat 99999 overflows negative). So: a safe flat MP plus a percentage --
    -- (base + 30000) x 3.4 ~= 100k, capped at the 99999 display. Spawn() recomputes
    -- max MP from these right after onMobSpawn and tops him off on arrival.
    mob:addMod(xi.mod.MP,  30000)                                        -- flat MP (int16-safe: must be <= 32767)
    mob:addMod(xi.mod.MPP, 240)                                          -- +240% on top -> ~maxed (99999 display)
    -- REFRESH (MP per ~3s tick) is cosmetic given the pool, but harmless.
    mob:addMod(xi.mod.REFRESH, 100)                                      -- token auto-refresh

    -- ---- Caster stats (neutralize the COR-main stat shift; fuel nuke dINT) ----
    -- Main job is COR (required for Corsair rolls), whose INT/MND ranks are
    -- lower than RDM's. The MND bump keeps cure and enfeeble POTENCY at the
    -- RDM-main level Skoll had before; the big INT bump does the same for
    -- enfeebles AND drives the dINT term of his burst nukes -- sized to stay
    -- well ahead of Odin's lv150 base INT for a strong, positive dINT. (Magic
    -- SKILL is unchanged: the RDM sub supplies elemental B- / enfeebling A+ at
    -- the master's full level -- see the header note.)
    mob:addMod(xi.mod.MND, 200)                                          -- cure power (MND/2) + MND-based enfeebles
    mob:addMod(xi.mod.INT, 400)                                          -- enfeeble potency + strong +dINT on the nukes

    -- ---- Bard skill -- run his songs at FULL power, not ~1/4 base power. ------
    -- Song potency scales with Singing skill; COR (main) and RDM (sub) grant
    -- none, so trustutils leaves it at 0 and his songs would land at base value.
    -- setSkillLevel writes a trust's WorkingSkills directly (engine support added
    -- in lua_baseentity.cpp). The song formula DOUBLES a non-PC's singing
    -- (enhancing_song.lua), so 400 here = 800 effective -- past every song's cap.
    -- REQUIRES the rebuilt map server; on an un-rebuilt binary this call no-ops.
    mob:setSkillLevel(xi.skill.SINGING, 400)

    -- ---- DOUBLE song + roll duration (Skoll ONLY) ----------------------------
    -- These are CASTER-side duration mods, so they extend only Skoll's own
    -- songs/rolls -- player BRD/COR are completely unaffected.
    --   Songs: calculateSongDuration (enhancing_song.lua) = 120 * (instrument*0.1
    --          + SONG_DURATION_BONUS/100 + 1). Skoll has no instrument, so +100
    --          here turns the 120s base into 240s (x2).
    --   Rolls: applyRoll (corsair.lua) = 300 + PHANTOM_DURATION (FLAT seconds)
    --          + merits/JP (a trust has none). +300 turns 300s into 600s (x2).
    mob:addMod(xi.mod.SONG_DURATION_BONUS, 100)   -- bard songs:   x2 (120s -> 240s)
    mob:addMod(xi.mod.PHANTOM_DURATION,    300)   -- corsair rolls: x2 (300s -> 600s)

    -- ---- Cure power -- his heals were weak: COR/RDM give only modest Healing
    -- skill and he had no Cure Potency. The cure formula (magic.lua) is
    --   power = MND/2 + VIT/4 + Healing skill   -->   cure x (1 + CurePot)
    -- Healing skill adds to power 1:1 (the biggest lever), so grant it like
    -- Singing -- engine-supported setSkillLevel; needs the rebuilt binary, else
    -- this call no-ops. Cure Potency I/II hard-cap at +50% / +30% in the formula
    -- (caps apply to trusts too), so set them at the cap for the full +80%
    -- multiplier -- and that part works NOW, no rebuild.
    mob:setSkillLevel(xi.skill.HEALING_MAGIC, 500)                       -- +500 cure power (needs rebuild)
    mob:addMod(xi.mod.CURE_POTENCY,    50)                               -- +50% cures (the formula cap)
    mob:addMod(xi.mod.CURE_POTENCY_II, 30)                               -- +30% more (II cap) -> +80% total

    -- ---- Party-wide rolls & songs -- make every buff blanket the WHOLE party,
    -- even when it is spread out. (Skoll is NO_MOVE: he can sit at the edge of
    -- casting range while the back line is further still, so the stock radii --
    -- 8y rolls, 10y songs -- otherwise miss people.)
    --   Rolls: widened to 50y in the abilities table itself
    --          (modules/custom/sql/corsair_roll_radius.sql). The trust ability
    --          path (CBattleEntity::OnAbility) reads abilities.radius directly and
    --          ignores Mod::ROLL_RANGE, so the DB column is the lever for a Trust.
    --   Songs: there is no per-entity song-range mod, so we FLAG him here and
    --          widen his song radius in the trust_skoll module's override of
    --          xi.combat.magicAoE.calculateSongRadius.
    -- Rolls and songs are party-only (validTargets), so the wide radius can never
    -- reach anyone outside the party.
    mob:setLocalVar('SKOLL_WIDE_AOE', 1)          -- read by the song-radius override

    -- =====================================================
    -- TOP PRIORITY -- SILENCE THE ENEMY FIRST  (above everything, by request)
    -- The very first thing she does to a fresh enemy is lock its casting down.
    -- Two gates keep it from ever spamming:
    --   * NOT_STATUS(SILENCE): only when the enemy is NOT already silenced -- so a
    --     Silence that LANDED is never re-cast, and the cast is skipped entirely
    --     while it is up.
    --   * retry_delay 120: the 4th addGambit arg is a RETRY DELAY IN SECONDS, NOT a
    --     "% chance" (the engine stamps last_used the moment the cast FIRES, win OR
    --     resist -- gambits_container.cpp). So after ANY attempt she waits a full
    --     2 minutes before trying again: a resist is never retried lock-step, and
    --     at most one Silence goes out every 120s, only while the enemy still needs
    --     it. (The old `, 50` on Silence and `, 15` on Dispel were both mislabeled
    --     "% chance" in their comments -- both were always retry delays in seconds.)
    -- =====================================================
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.SILENCE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.SILENCE }, 120)

    -- =====================================================
    -- ALLY / SUPPORT GAMBITS  (priority order; first matching gambit fires)
    --   #1  KEEP THE MAIN PLAYER ALIVE WITH HEALS: emergency cure, wake-sleep, raise.
    --   #2  KEEP 4 SONGS + 4 ROLLS UP: the block inserted right below the raise.
    --   #3  Everything else (magic burst, top-off cure, cleanses, buffs, enemy
    --       debuffs, free nuke) follows below in its original relative order.
    -- =====================================================

    -- Emergency: cure anyone at critical HP, or wake sleeping allies
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 25 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_I  }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_II }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURE })

    -- =====================================================
    -- RESCUE  (revive the fallen -- the hard counter to Zantetsuken)
    -- ai.t.PARTY_DEAD targets downed party members; HIGHEST RAISE picks the best
    -- raise in his list = Arise (full HP, no weakness). Proven stock-trust pattern
    -- (ferreous_coffin / rughadjeen). Sits above the burst + support rotation: once
    -- the dying (< 25%) are stabilized, a dead ally is the single biggest emergency.
    -- =====================================================
    mob:addGambit(ai.t.PARTY_DEAD, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.RAISE })

    -- =====================================================
    -- PRIORITY #2 -- KEEP 4 BARD SONGS + 4 CORSAIR ROLLS UP AT ALL TIMES
    -- Second ONLY to the life-saving heals above (emergency cure / wake-sleep /
    -- raise); sits ABOVE Skoll's magic burst, top-off cure, cleanses, secondary
    -- buffs, enemy debuffs and free nuke (all below). Songs are sung on SELF
    -- (AoE to the party); each gambit refreshes only when its OWN effect has
    -- worn off (NOT_STATUS), so a dropped song/roll is re-applied the next tick
    -- -- i.e. "always up". Every SONG spell must also live in mob_spell_lists
    -- 901 (trust_skoll.sql) or its gambit is silently dropped at load; rolls are
    -- JAs and are NOT spell-list gated. COR main job => full-power rolls.
    -- =====================================================
    -- 4 Bard songs (3 offense + Sentinel's Scherzo for mitigation)
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.MARCH    }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.VICTORY_MARCH     })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.MINUET   }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.VALOR_MINUET_V    })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.MADRIGAL }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.SWORD_MADRIGAL    })
    -- Sentinel's Scherzo -> party phys+magic damage-taken down. Distinct SCHERZO
    -- effect, so it STACKS with the three above. Short base duration: refreshed
    -- more often than the others, which is expected for this song.
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.SCHERZO  }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.SENTINELS_SCHERZO })
    -- 4 Corsair rolls (recast each only when it wears off):
    --   Chaos (Attack) / Rogue's (Crit rate) / Allies' (Skillchain dmg) /
    --   Wizard's (Magic Attack Bonus). Allies' and Wizard's both feed Skoll's
    --   magic bursts -- direct synergy with his nukes.
    mob:addGambit(ai.t.PARTY, { ai.c.NOT_STATUS, xi.effect.CHAOS_ROLL   }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.CHAOS_ROLL   })  -- Attack
    mob:addGambit(ai.t.PARTY, { ai.c.NOT_STATUS, xi.effect.ROGUES_ROLL  }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.ROGUES_ROLL  })  -- Crit hit rate
    mob:addGambit(ai.t.PARTY, { ai.c.NOT_STATUS, xi.effect.ALLIES_ROLL  }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.ALLIES_ROLL  })  -- Skillchain damage
    mob:addGambit(ai.t.PARTY, { ai.c.NOT_STATUS, xi.effect.WIZARDS_ROLL }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.WIZARDS_ROLL })  -- Magic Attack Bonus

    -- =====================================================
    -- MAGIC BURST  (the whole point of his elemental kit)
    -- Fires ONLY when the party has an OPEN skillchain on the enemy -- tier > 0
    -- and > 3s old (gambits_container.cpp MB_AVAILABLE). MB_ELEMENT then reads the
    -- skillchain's element off the enemy and casts the matching nuke from his
    -- damage list (Ancient Magic II + Comet). Those are single-target, so they
    -- land in m_damageList -- the ONLY list MB_ELEMENT scans; -ga spells would go
    -- to the ga-list and be ignored, which is why no -ga is used.
    -- Sits just under the life-or-death triage (crit cure / wake-sleep) but above
    -- everything else: a burst window is brief and worth more than topping a
    -- healthy ally or refreshing a buff. (The no-skillchain case is handled by the
    -- lowest-priority free nuke at the very bottom; threat is held down by the
    -- Mod::ENMITY -50 set above, so neither the burst nor the free nuke pulls.)
    -- =====================================================
    mob:addGambit(ai.t.TARGET, { ai.c.MB_AVAILABLE, 0 }, { ai.r.MA, ai.s.MB_ELEMENT, xi.magic.spellFamily.NONE })

    -- Standard cure (< 75% HP)
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 75 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })

    -- Erase erasable debuffs (self first, then party)
    mob:addGambit(ai.t.SELF,  { ai.c.STATUS_FLAG, xi.effectFlag.ERASABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ERASE })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS_FLAG, xi.effectFlag.ERASABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ERASE })

    -- Status-cure suite (non-erasable ailments)
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.POISON        }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.POISONA  })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.PARALYSIS     }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.PARALYNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.BLINDNESS     }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.BLINDNA  })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SILENCE       }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.SILENA   })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.PETRIFICATION }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STONA    })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.DISEASE       }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.VIRUNA   })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.CURSE_I       }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA   })

    -- Buff rotation: Protectra V → Shellra V → Haste II → Phalanx II → Regen V
    --                → self-Aquaveil   (no Refresh -- party wants no MP buffs)
    -- SELF target (not PARTY) for the AoE buffs: Protectra V and Shellra V are
    -- self-centered AoEs. With ai.t.PARTY the engine fires the gambit once per
    -- member who lacks the buff, causing N back-to-back casts for an N-person party.
    -- ai.t.SELF fires once; she gets the effect herself (since she's in the AoE),
    -- so NOT_STATUS clears and the gambit won't fire again -- same pattern as songs.
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.PROTECT  }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.PROTECTRA })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.SHELL    }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.SHELLRA   })
    mob:addGambit(ai.t.PARTY, { ai.c.NOT_STATUS, xi.effect.HASTE    }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.HASTE_II       })
    -- Phalanx II -> flat per-hit damage reduction on the whole party. Its
    -- validTargets allow allies (unlike self-only base Phalanx / Stoneskin), so
    -- ai.t.PARTY blankets the master + Skoll. Big vs Odin's Double/Triple Attack.
    mob:addGambit(ai.t.PARTY, { ai.c.NOT_STATUS, xi.effect.PHALANX  }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.PHALANX_II     })
    -- Regen only when it has actually worn off (was: HPP_LT 95 alone, which
    -- re-cast Regen every tick a hurt ally sat below 95% -- a spam source).
    mob:addGambit(ai.t.PARTY, { { ai.c.HPP_LT, 95 }, { ai.c.NOT_STATUS, xi.effect.REGEN } }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.REGEN })
    -- (Refresh III removed -- the party doesn't need MP support.)
    -- Aquaveil on himself -> his cures / rez / nukes resist interruption when he
    -- eats an AoE. Self-only spell (validTargets 1), so SELF target.
    mob:addGambit(ai.t.SELF,  { ai.c.NOT_STATUS, xi.effect.AQUAVEIL }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.AQUAVEIL      })

    -- (BARD SONGS + CORSAIR ROLLS were moved UP to PRIORITY #2, just beneath the
    --  life-saving heals near the top of this gambit list, so they stay up "at
    --  all times" ahead of Skoll's damage/debuffs. Mage's Ballad III stays
    --  removed -- it is an MP-refresh song and the party wants no MP buffs.)

    -- =====================================================
    -- ENEMY GAMBITS  (debuff rotation, evaluated after all ally needs)
    -- =====================================================

    -- ENEMY DEBUFFS -- Silence was moved to the TOP-PRIORITY block at the very top
    -- of this gambit list (first thing she does, 2-min retry floor). The remaining
    -- debuffs follow here, Dia III first.

    -- Dia III only when the enemy has NEITHER Dia NOR Bio. Bio III (tier 6) and
    -- Dia III (tier 5) are mutually exclusive: the higher tier wins and the loser
    -- silently fails, so the NOT_STATUS BIO half stops Skoll wasting casts trying
    -- to overwrite a stronger Bio someone else applied (the old Dia-"spam" fix).
    mob:addGambit(ai.t.TARGET, { { ai.c.NOT_STATUS, xi.effect.DIA }, { ai.c.NOT_STATUS, xi.effect.BIO } }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.DIA_III }, 120)

    -- The rest -- applied whenever missing. The trailing 120 is retry_delay in
    -- SECONDS (gambits_container.cpp): after each cast she won't recast THAT spell
    -- for 2 minutes. When an enfeeble LANDS, NOT_STATUS already blocks recasts;
    -- when it "(has no effect)" on a resistant/immune target the status never
    -- lands, so NOT_STATUS stays true -- this 120s delay is what stops her spamming
    -- it: one attempt, then a 2-minute wait before she tries that spell again.
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.SLOW      }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.SLOW_II     }, 120)
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.PARALYSIS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.PARALYZE_II }, 120)
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.BLINDNESS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.BLIND_II    }, 120)
    -- Dispel -> strip a beneficial status off the enemy. No "enemy has a buff"
    -- gambit condition exists, so it fires on a low 15% chance (a cast with nothing
    -- to strip simply no-effects). Insurance, not a main lever.
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.DISPEL }, 15)

    -- =====================================================
    -- FREE NUKE  (secondary DPS -- the LOWEST-priority gambit)
    -- Reached only when every ally need and every debuff above is already
    -- handled, so SUPPORT ALWAYS WINS; he just fills the leftover time with
    -- damage instead of standing idle. NOT_SC_AVAILABLE = no skillchain on the
    -- enemy (gambits_container.cpp); while a chain is forming he holds, letting
    -- the higher-priority MB gambit element-match the burst rather than waste a
    -- cast. BEST_AGAINST_TARGET nukes the enemy's weakest element -- against
    -- Odin's flat resists that resolves to the Flare II hint (fire); against a
    -- real elemental weakness it adapts. Threat stays low via Mod::ENMITY -50
    -- (set far above), so this damage lands BEHIND the master.
    -- =====================================================
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_SC_AVAILABLE, 0 }, { ai.r.MA, ai.s.BEST_AGAINST_TARGET, xi.magic.spell.FLARE_II })
end

spellObject.onMobDespawn = function(mob)
    -- Departure message intentionally omitted (pool 5901). The repurposed
    -- Nanaa Mihgo page would mis-name him, so we stay silent on purpose:
    -- Skoll departs without a word, the way a wolf should.
end

spellObject.onMobDeath = function(mob)
    -- Same as above.
end

return spellObject
