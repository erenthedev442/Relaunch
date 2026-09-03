-----------------------------------
-- spell_skill_mastery_catalog.lua
--
-- Config for the Spell & Skill Mastery system (Mastery Sage NPC, Leafallia).
-- Players spend a dedicated currency -- MASTERY SIGILS (charVar 'MasterySigils')
-- -- to permanently empower their weapon skills and magic.
--
-- THREE kinds of upgrade:
--   * POTENCY  -- tiered % power-ups, applied as additive mods (re-applied on
--                 login). WS -> ALL_WSDMG_ALL_HITS; Spell -> MATT/MAGIC_DAMAGE/CURE.
--   * TRAITS   -- one-time passive riders (also additive mods).
--   * WS EFFECTS -- per-player weapon-skill procs driven by a WEAPONSKILL_USE
--                 listener (currently Empowered Strike only). Read live from
--                 charVars each WS, so they need NO re-apply.
--
-- Sigils are earned mainly from a ROTATION of target NMs (kill the active ones
-- each period for a big chunk), plus an optional small trickle from any NM.
--
-- TUNE: all costs, tiers, mod/effect values, the rotation pool and the sigil
-- faucet live in THIS file. Balance below is PLACEHOLDER -- tune in playtest.
-----------------------------------
local catalog = {}

-- Currency ------------------------------------------------------------------
catalog.CURRENCY_VAR  = 'MasterySigils'     -- charVar holding the player's sigils
catalog.CURRENCY_NAME = 'Mastery Sigils'

-- NPC placement (center of the GM Home mastery conversation semicircle) ------
catalog.npcPos = { x = 537.9993, y = -3.4665, z = 497.0069, rot = 216 }

-- ── Sigil faucet (secondary; the rotation below is the primary source) ──────
-- Optional small trickle on ANY NM kill so players are never fully dry between
-- rotation targets. Set nmTrickle=false to make the rotation the ONLY source.
catalog.sigils =
{
    nmTrickle   = true,   -- small flat sigils per any NM kill
    nmBase      = 2,      -- flat sigils per NM
    nmPerLevel  = 0.03,   -- + this * mob level
    nmMax       = 10,     -- cap per NM
    mobChance   = 0,      -- % chance a normal (non-NM) mob >= mobMinLevel drops; 0 = off
    mobMinLevel = 50,
    mobAmount   = 1,
    announceNM  = false,  -- keep the trickle quiet (rotation kills announce instead)
}

-- ── NM ROTATION (primary sigil source) ─────────────────────────────────────
-- A time-based rotation: `activeCount` NMs from `pool` are "live" each period.
-- Killing a live target grants `reward` sigils, ONCE per target per period. The
-- active set is derived from the clock (no DB) and advances through the pool.
-- Per-player claims tracked via charVars Mastery_RotPeriod + Mastery_RotMask.
--
-- Each entry: name (matches mob:getName(), underscored), label + zone (display).
-- Matching is case-insensitive and underscore/space-insensitive, so either form
-- of the in-game name resolves. The pool below is the set of REAL overworld NMs
-- verified on disk (sourced from hunters_guild_catalog -- non-instanced, walkable
-- zones with camp-viable respawns). Add/remove freely.
catalog.rotation =
{
    enabled     = true,
    periodHours = 24,     -- rotation length (24 = daily)
    activeCount = 3,      -- how many NMs are live at once
    reward      = 50,     -- sigils per live target, once per period
    announce    = true,   -- chat line when a rotation target is claimed
    partyWide   = true,   -- credit every same-zone party member, not just the killer
    -- Distinct from the Hunters' Guild / Reforge / Hunting League NM sets (those
    -- pay their own currencies). Verified present in the relaunch DB (mobType is
    -- NM, walkable overworld zones). `name` matches mob:getName() (underscored).
    pool =
    {
        { name = 'Jaggedy-Eared_Jack', label = 'Jaggedy-Eared Jack', zone = 'West_Ronfaure' },
        { name = 'Bigmouth_Billy',     label = 'Bigmouth Billy',     zone = 'East_Ronfaure' },
        { name = 'King_Arthro',        label = 'King Arthro',        zone = 'Jugner_Forest' },
        { name = 'Lumber_Jack',        label = 'Lumber Jack',        zone = 'Batallia_Downs' },
        { name = 'Stray_Mary',         label = 'Stray Mary',         zone = 'Konschtat_Highlands' },
        { name = 'Carnero',            label = 'Carnero',            zone = 'South_Gustaberg' },
        { name = 'Serpopard_Ishtar',   label = 'Serpopard Ishtar',   zone = 'Tahrongi_Canyon' },
        { name = 'Botulus_Rex',        label = 'Botulus Rex',        zone = 'Buburimu_Peninsula' },
        { name = 'Orcus',              label = 'Orcus',              zone = 'Meriphataud_Mountains' },
        { name = 'Old_Sabertooth',     label = 'Old Sabertooth',     zone = 'Sauromugue_Champaign' },
        { name = 'Bastet',             label = 'Bastet',             zone = 'The_Sanctuary_of_ZiTah' },
        { name = 'Voluptuous_Vilma',   label = 'Voluptuous Vilma',   zone = 'Yuhtunga_Jungle' },
        { name = 'Powderer_Penny',     label = 'Powderer Penny',     zone = 'Yhoator_Jungle' },
        { name = 'Kraken',             label = 'Kraken',             zone = 'Qufim_Island' },
        { name = 'Nue',                label = 'Nue',                zone = 'Beaucedine_Glacier' },
        { name = 'Gargantua',          label = 'Gargantua',          zone = 'Beaucedine_Glacier' },
        { name = 'Koenigstiger',       label = 'Koenigstiger',       zone = 'Xarcabard' },
        { name = 'Stolas',             label = 'Stolas',             zone = 'Cape_Teriggan' },
        { name = 'Kreutzet',           label = 'Kreutzet',           zone = 'Cape_Teriggan' },
        { name = 'Guivre',             label = 'Guivre',             zone = 'Kuftal_Tunnel' },
    },
}

-- ── Potency tracks (additive mods, re-applied on login) ─────────────────────
-- value at tier T = per * T. Buying tier t costs POTENCY_COST[t].
catalog.MAX_TIER     = 5
catalog.POTENCY_COST = { 15, 30, 55, 90, 140 }

catalog.wsPotency =
{
    var  = 'Mastery_WSPot',
    name = 'Weapon Skill Potency',
    mods = { { xi.mod.ALL_WSDMG_ALL_HITS, 8 } },        -- +8% all-WS dmg / tier
    blurb = '+8% weapon skill damage per tier',
}

catalog.spellPotency =
{
    var  = 'Mastery_SpellPot',
    name = 'Spell Potency',
    mods = { { xi.mod.MATT, 6 }, { xi.mod.MAGIC_DAMAGE, 8 }, { xi.mod.CURE_POTENCY, 5 } },
    blurb = '+6 M.Atk, +8 magic dmg, +5% cure per tier',
}

-- ── WS Effects (per-player WEAPONSKILL_USE procs; read live, no re-apply) ────
-- Tiered like potency (cost = EFFECT_COST[tier]). `kind` selects the handler in
-- SpellSkillMastery.lua. Add a new effect = add a row (+ a kind handler if it
-- is a new kind).
--
-- The old 'splash' (AoE) effect was removed on 2026-07-13: single-target WS
-- was never meant to become AoE on this server, and it duplicated the earlier
-- retired Rupture Sage / !aoews feature (a22038d3b5). Existing
-- Mastery_WSFx_splash charvars go inert; players keep the sigils they had left
-- but the ones spent on splash tiers are not refunded.
--
-- The 'lifesteal' effect was removed on 2026-07-17: same retirement pattern --
-- healing from every weapon skill bypassed encounter sustain and HP-management
-- mechanics. Existing Mastery_WSFx_drain charvars go inert; no sigil refund.
-- The runtime handler for `kind='lifesteal'` was also stripped from
-- SpellSkillMastery.lua.
catalog.EFFECT_COST = { 20, 40, 70, 110, 160 }

catalog.wsEffects =
{
    { id = 'empstrike', var = 'Mastery_WSFx_crit',   name = 'Empowered Strike', max = 5,
      kind = 'crit',      chancePerTier = 8, bonusPct = 60,
      desc = 'Per tier: +8% chance your WS lands a critical burst (+60% damage).' },
}

-- ── Trait riders (one-time unlocks; flat additive mods) ─────────────────────
catalog.TRAIT_COST_DEFAULT = 40
catalog.traitVarPrefix     = 'Mastery_T_'

catalog.wsTraits =
{
    { id = 'storetp', name = 'Store TP',     desc = 'Gain TP faster (+10 Store TP).',              mods = { { xi.mod.STORETP, 10 } } },
    { id = 'wsacc',   name = 'WS Accuracy',  desc = 'Weapon skills land more often (+20 WS Acc).',  mods = { { xi.mod.WSACC, 20 } } },
    { id = 'crit',    name = 'Crit Rate',    desc = 'Higher critical hit rate (+6%).',              mods = { { xi.mod.CRITHITRATE, 6 } } },
    { id = 'critdmg', name = 'Crit Damage',  desc = 'Critical hits deal more (+10%).',              mods = { { xi.mod.CRIT_DMG_INCREASE, 10 } } },
    { id = 'tpsaver', name = 'TP Saver',     desc = '20% chance a weapon skill costs no TP.',       mods = { { xi.mod.WS_NO_DEPLETE, 20 } } },
    { id = 'dblatk',  name = 'Double Atk',   desc = 'Chance to attack twice (+5%).',                mods = { { xi.mod.DOUBLE_ATTACK, 5 } } },
}

catalog.spellTraits =
{
    { id = 'fcast',    name = 'Fast Cast',     desc = 'Cast spells faster (+10% Fast Cast).',        mods = { { xi.mod.FASTCAST, 10 } } },
    { id = 'conserve', name = 'Conserve MP',   desc = 'Chance to spend less MP (+20).',              mods = { { xi.mod.CONSERVE_MP, 20 } } },
    { id = 'macc',     name = 'Magic Acc',     desc = 'Spells land more often (+20 Magic Acc).',     mods = { { xi.mod.MACC, 20 } } },
    { id = 'regain',   name = 'Regain',        desc = 'Auto-regain TP (+2%/tick).',                  mods = { { xi.mod.REGAIN, 20 } } },
    { id = 'enhdur',   name = 'Enh Duration',  desc = 'Enhancing magic lasts longer (+20%).',        mods = { { xi.mod.ENH_MAGIC_DURATION, 20 } } },
    -- SPELLINTERRUPT is SIRD: interrupt chance is (100 - mod) / 100.
    -- Positive values reduce interrupts. -20 was raising the rate instead.
    { id = 'focus',    name = 'Focus',         desc = 'Resist spell interruption (+20% SIRD).',     mods = { { xi.mod.SPELLINTERRUPT, 20 } } },
}

return catalog
