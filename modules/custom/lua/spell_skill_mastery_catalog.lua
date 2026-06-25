-----------------------------------
-- spell_skill_mastery_catalog.lua
--
-- Config for the Spell & Skill Mastery system (Mastery Sage NPC, Leafallia).
-- Players spend a dedicated currency -- MASTERY SIGILS (charVar 'MasterySigils')
-- -- to permanently empower their weapon skills and magic:
--
--   * POTENCY  -- tiered % power-ups (re-applied on login as additive mods):
--       WS potency    -> ALL_WSDMG_ALL_HITS  (all weapon skills hit harder)
--       Spell potency -> MATT + MAGIC_DAMAGE + CURE_POTENCY (nukes/cures stronger)
--   * TRAITS   -- one-time passive riders (also pure additive mods), e.g.
--       WS: Store TP, WS Accuracy, Crit, TP-saver, Double Attack.
--       Spells: Fast Cast, Conserve MP, Magic Acc, Regain, Enh. duration, Focus.
--
-- Everything here is a plain modifier, so SpellSkillMastery.lua re-applies it via
-- onGameIn after a zone-in wipes in-memory mods -- exactly the Cross-Job Trait
-- Trainer pattern. No per-cast hooks, no C++ -- pure Lua + one map restart.
--
-- TUNE: all costs, tier counts, mod values and the sigil faucet live in THIS file.
-----------------------------------
local catalog = {}

-- Currency ------------------------------------------------------------------
catalog.CURRENCY_VAR  = 'MasterySigils'     -- charVar holding the player's sigils
catalog.CURRENCY_NAME = 'Mastery Sigils'

-- NPC placement (Leafallia back row, beside Rupture Sage / Relic Forge) -------
catalog.npcPos = { x = -8.000, y = 0.000, z = 20.000, rot = 128 }

-- ── Sigil faucet (xi.mob.onMobDeathEx) ─────────────────────────────────────
-- NMs are the primary source; high-level normal mobs trickle a few. All tunable.
catalog.sigils =
{
    nmBase      = 3,      -- flat sigils per NM kill
    nmPerLevel  = 0.05,   -- + this * mob level (lvl 100 NM => +5  => 8 total)
    nmMax       = 25,     -- hard cap per NM kill
    mobMinLevel = 50,     -- normal mobs below this never drop sigils
    mobChance   = 8,      -- % chance a qualifying normal mob drops sigils
    mobAmount   = 1,      -- sigils a normal mob drops when it procs
    announceNM  = true,   -- chat line on NM sigil grants (normal mobs stay silent)
}

-- ── Potency tracks ─────────────────────────────────────────────────────────
-- Each track climbs MAX_TIER steps. On every step the listed mods gain `per`.
-- value at tier T = per * T (applied additively, stacks with gear).
catalog.MAX_TIER = 5

-- Sigil cost to buy the NEXT tier (index = the tier you are buying, 1..MAX_TIER).
catalog.POTENCY_COST = { 15, 30, 55, 90, 140 }

catalog.wsPotency =
{
    var  = 'Mastery_WSPot',
    name = 'Weapon Skill Potency',
    -- +8% all-WS damage per tier  ->  +40% at tier 5
    mods = { { xi.mod.ALL_WSDMG_ALL_HITS, 8 } },
    -- short, human label for the per-tier effect (menus/chat)
    blurb = '+8% weapon skill damage per tier',
}

catalog.spellPotency =
{
    var  = 'Mastery_SpellPot',
    name = 'Spell Potency',
    -- per tier: +6 Magic Atk, +8 flat magic damage, +5% cure potency
    mods = { { xi.mod.MATT, 6 }, { xi.mod.MAGIC_DAMAGE, 8 }, { xi.mod.CURE_POTENCY, 5 } },
    blurb = '+6 M.Atk, +8 magic dmg, +5% cure per tier',
}

-- ── Trait riders (one-time unlocks; flat additive mods) ─────────────────────
-- id    -> charVar suffix (Mastery_T_<id> = 1 when owned)
-- cost  -> sigils (defaults to TRAIT_COST_DEFAULT if omitted)
catalog.TRAIT_COST_DEFAULT = 40
catalog.traitVarPrefix     = 'Mastery_T_'

catalog.wsTraits =
{
    { id = 'storetp', name = 'Store TP',     desc = 'Gain TP faster (+10 Store TP).',            mods = { { xi.mod.STORETP, 10 } } },
    { id = 'wsacc',   name = 'WS Accuracy',  desc = 'Weapon skills land more often (+20 WS Acc).', mods = { { xi.mod.WSACC, 20 } } },
    { id = 'crit',    name = 'Crit Rate',    desc = 'Higher critical hit rate (+6%).',            mods = { { xi.mod.CRITHITRATE, 6 } } },
    { id = 'critdmg', name = 'Crit Damage',  desc = 'Critical hits deal more (+10%).',            mods = { { xi.mod.CRIT_DMG_INCREASE, 10 } } },
    { id = 'tpsaver', name = 'TP Saver',     desc = '20% chance a weapon skill costs no TP.',     mods = { { xi.mod.WS_NO_DEPLETE, 20 } } },
    { id = 'dblatk',  name = 'Double Atk',   desc = 'Chance to attack twice (+5%).',              mods = { { xi.mod.DOUBLE_ATTACK, 5 } } },
}

catalog.spellTraits =
{
    { id = 'fcast',    name = 'Fast Cast',     desc = 'Cast spells faster (+10% Fast Cast).',       mods = { { xi.mod.FASTCAST, 10 } } },
    { id = 'conserve', name = 'Conserve MP',   desc = 'Chance to spend less MP (+20).',             mods = { { xi.mod.CONSERVE_MP, 20 } } },
    { id = 'macc',     name = 'Magic Acc',     desc = 'Spells land more often (+20 Magic Acc).',    mods = { { xi.mod.MACC, 20 } } },
    { id = 'regain',   name = 'Regain',        desc = 'Auto-regain TP (+2%/tick).',                 mods = { { xi.mod.REGAIN, 20 } } },
    { id = 'enhdur',   name = 'Enh Duration',  desc = 'Enhancing magic lasts longer (+20%).',       mods = { { xi.mod.ENH_MAGIC_DURATION, 20 } } },
    { id = 'focus',    name = 'Focus',         desc = 'Resist spell interruption (-20% rate).',     mods = { { xi.mod.SPELLINTERRUPT, -20 } } },
}

return catalog
