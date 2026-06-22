-----------------------------------
-- prestige_catalog.lua
-- Configuration for the Ascension (Prestige) system.
-- Edit this file only -- Prestige_System.lua reads it automatically.
--
-- Ascension is the endgame layer ABOVE Hunting League's Legend tier.
-- It NEVER wipes progression -- levels, gear, marks, and HL_Tier are all
-- untouched. Each ascension is *earned* by re-clearing the Legend NMs
-- (the "Trial") and paying an escalating Hunt Marks cost. Ascending
-- grants Ascension Points (AP): a Job-Points-style currency spent on
-- permanent, stacking stat boosts that re-apply every zone-in.
--
-- PER-JOB: AP, prestige level, and every boost are tracked per MAIN JOB,
-- just like Job Points. Ascending on a job earns/spends AP for that job,
-- and its boosts apply only while that job is active (swapped on job change
-- as well as zone-in). The Legend gate and the Trial stay account-wide, so
-- each ascension -- on whichever job -- still costs one fresh Trial clear.
--
-- xi.mod.* is available at require-time (same as hunting_league_catalog).
-----------------------------------

return
{
    -- =========================================================
    -- ZONE / NPC PLACEMENT
    -- =========================================================
    -- The Altar lives in Provenance (zone 222) -- the abyssal void arena
    -- at the climax of Rhapsodies of Vana'diel, a fitting stage for an
    -- endgame ascension rite. Players zone in at (-640, -20, -519.999)
    -- facing rot 192 (see scripts/zones/Provenance/Zone.lua), so the Altar
    -- sits a few units off that entry point. If it clips, floats, or faces
    -- the wrong way, only altarPos needs changing (rot is 0-255).
    -- Moved here 2026-05-30 (was GM Home 210; before that Reisenjima Henge).
    zonePath = 'xi.zones.Provenance',
    altarPos = { x = -636.000, y = -20.000, z = -519.999, rot = 128 },

    -- Ascension spends Hunt Marks, stored in CharVar HL_Points (the same
    -- balance the Hunting League uses -- Legend players sit on a surplus
    -- of these with nothing left to buy). Display names only.
    markVar  = 'HL_Points',
    markName = 'Hunt Marks',
    apName   = 'Ascension Points',

    -- =========================================================
    -- ASCENSION ECONOMY  (all tunable)
    -- =========================================================
    -- Gate: the Altar only works once the player has reached this
    -- Hunting League tier (5 = Legend, the current ceiling).
    unlockTier     = 5,

    -- AP granted per ascension, tiered by the NEW prestige level after ascending.
    -- Prestige_System.lua reads apTiers in order and uses the highest minLevel met.
    apTiers =
    {
        { minLevel =  0, ap = 10 },   -- P.Lv 1-50
        { minLevel = 51, ap = 15 },   -- P.Lv 51-80
        { minLevel = 81, ap = 20 },   -- P.Lv 81+
    },

    -- Hunt Marks cost to ascend, escalating with current Prestige_Level:
    --   cost(level) = min(markCostBase * (level + 1), markCostCap)
    -- base 500 -> 500, 1000, 1500, 2000, 2500, 3000, 3000, 3000, ...
    markCostBase   = 500,
    markCostCap    = 3000,

    -- Hard cap on prestige levels. nil = uncapped (endless "Paragon"
    -- tail for leaderboard flex). Set a number to cap it.
    maxLevel       = nil,

    -- EXP penalty: MULTIPLICATIVE cut (the per-main-job [PrestigeExpCut] charVar the
    -- ENGINE applies AFTER gear/augment EXP_BONUS, so +EXP augments can't cancel it).
    -- Applied per-job (only while that job is your main). Stacks MULTIPLICATIVELY with
    -- the Job Rebirth cut (e.g. -80% rebirth then -80% prestige = -96% off the boosted
    -- total). Linear: caps at expPenaltyMaxCut% at expPenaltyMaxLevel, scaling to lv 1 --
    -- mirrors the Rebirth cut (80% @ 20).
    --   cut(L) = min(round(L / expPenaltyMaxLevel * expPenaltyMaxCut), expPenaltyMaxCut)
    --   P.Lv 1 -4%, P.Lv 5 -20%, P.Lv 10 -40%, P.Lv 15 -60%, P.Lv 20+ -80% (cap).
    -- The engine still floors EXP at 5% of base, so a job can never be soft-locked.
    expPenaltyMaxCut   = 80,
    expPenaltyMaxLevel = 20,

    -- =========================================================
    -- ASCENSION TRIAL  --  "The Nightmare Court"
    -- =========================================================
    -- Three Ascension-EXCLUSIVE superbosses (used by NO other custom system)
    -- you must re-slay since your last ascension. They are SUMMONED at the
    -- Altar itself (menu option "Face the Trial"), one at a time, via
    -- insertDynamicEntity -- so there is no Spawner NPC and no mob_spawn_points.
    -- Each kill stamps Prestige_Trial_<groupId>; ascending clears the stamps so
    -- the next cycle starts fresh. The mob_groups rows live in
    -- modules/custom/sql/prestige_trial_mobs.sql (all at zoneid 222).
    --
    -- They are chosen to inject psychological dread, not just be stat walls:
    --   Diabolos -- Nightmare: AoE sleep, then drains you while you dream.
    --   Medusa   -- petrifying gaze: turned to stone, you watch yourself die.
    --   Odin     -- Zantetsuken: instant death. The final wall.
    --
    --   requireAll = true  -> must clear EVERY boss each cycle.
    --   requireAll = false -> must clear at least `requireCount` of them.
    trial =
    {
        requireAll   = true,
        requireCount = 3,   -- only consulted when requireAll = false
        nms =
        {
            { groupId = 11370, label = 'Diabolos, the Dream Devourer' },
            { groupId = 11373, label = 'Medusa, the Gorgon Queen'     },
            { groupId = 11372, label = 'Odin, the Doombringer'        },
        },
    },

    -- =========================================================
    -- TRIAL BOSS SUMMONING  ("The Nightmare Court")
    -- =========================================================
    -- The Altar summons these directly (no Spawner NPC). trialBossZoneId must
    -- match the zoneid of the mob_groups rows in prestige_trial_mobs.sql.
    trialBossZoneId = 222,

    -- The sequence the Altar presents them in -- you face the Court one boss at
    -- a time, in this order, until every stamp is cleared for the cycle.
    trialBossOrder = { 11370, 11373, 11372 },

    -- Summoned bosses appear NEXT TO THE SUMMONER (their live position) on a small
    -- ring -- not at a fixed arena point. The old fixed point below spawned bosses
    -- under the platform / off-map ("below the character"). trialSpawnGap = how many
    -- yalms out from the summoner the boss lands (a small gap so it isn't on top of
    -- them); its height is the player's own, which sits on the floor. This mirrors
    -- the working GameMaster waves -- see summonNextTrial in Prestige_System.lua.
    -- trialSpawnPos is kept ONLY as a fallback if the player position can't be read
    -- (should never happen). Bump trialSpawnGap if you want the boss further away.
    trialSpawnGap = 2.5,
    trialSpawnPos = { x = -624.000, y = -20.000, z = -519.999, rot = 192 },

    -- Per-boss spawn profile. Mirrors the Hunting League Tier-5 mod schema:
    --   name     mob_groups.name (MUST match the SQL row's name)
    --   label    flavour name shown in menus / server announces
    --   level    minLevel = maxLevel. 150 = the "lv99 superboss" baseline used
    --            by Absolute Virtue / Pandemonium Warden. REQUIRED -- without a
    --            level the engine spawns the mob at lv255 and it cannot be hit.
    --   hpBoost  multiplier applied to the mob's base HP after spawn()
    --   cry      one-line flavour barked to the summoner (the "fear" hook)
    --   mods     { [xi.mod.X] = value } applied AFTER spawn() (pairs-iterated)
    --
    -- Magnitudes sit at/above the Legend tier (AV/PW) and escalate to Odin as
    -- the apex, but stay below Shinryu's raid-wall numbers. The real terror is
    -- each pool's authentic kit (Nightmare sleep / petrify gaze / Zantetsuken).
    trialBosses =
    {
        [11370] =
        {
            name    = 'Diabolos',
            label   = 'Diabolos, the Dream Devourer',
            level   = 150,
            hpBoost = 39,
            cry     = '"Close your eyes... this nightmare is the last thing you will know."',
            mods =
            {
                [xi.mod.DEF] = 2475,
                [xi.mod.ATT] = 12600,
                [xi.mod.ACC] = 2700,
                [xi.mod.EVASION] = 720,
                [xi.mod.MATT] = 900,
                [xi.mod.MACC] = 1260,
                [xi.mod.MEVA] = 1260,
                [xi.mod.MDEF] = 1260,
                [xi.mod.INT]        = 500,
                [xi.mod.MND]        = 400,
                [xi.mod.HASTE_GEAR] = 250,
                [xi.mod.REGEN]      = 600,
            },
        },
        [11373] =
        {
            name    = 'Medusa',
            label   = 'Medusa, the Gorgon Queen',
            level   = 150,
            hpBoost = 44,
            cry     = '"Look upon me... and be still, forever."',
            mods =
            {
                [xi.mod.DEF] = 2887,
                [xi.mod.ATT] = 15300,
                [xi.mod.ACC] = 3060,
                [xi.mod.EVASION] = 900,
                [xi.mod.MEVA] = 900,
                [xi.mod.MDEF] = 900,
                [xi.mod.STR]           = 400,
                [xi.mod.DEX]           = 400,
                [xi.mod.DOUBLE_ATTACK] = 22,
                [xi.mod.HASTE_GEAR]    = 200,
                [xi.mod.REGEN]         = 700,
            },
        },
        [11372] =
        {
            name    = 'Odin',
            label   = 'Odin, the Doombringer',
            level   = 150,
            hpBoost = 51,
            cry     = '"Zantetsuken. There is no wound -- only the end."',
            mods =
            {
                [xi.mod.DEF] = 3300,
                [xi.mod.ATT] = 18000,
                [xi.mod.ACC] = 3960,
                [xi.mod.EVASION] = 1170,
                [xi.mod.MEVA] = 1260,
                [xi.mod.MDEF] = 1260,
                [xi.mod.STR]           = 600,
                [xi.mod.DEX]           = 600,
                [xi.mod.HASTE_GEAR]    = 300,
                [xi.mod.DOUBLE_ATTACK] = 28,
                [xi.mod.TRIPLE_ATTACK] = 15,
                [xi.mod.REGEN]         = 900,
            },
        },
    },

    -- =========================================================
    -- ASCENSION TRIAL DIFFICULTY SCALING  ("the Court changes as you rise")
    -- =========================================================
    -- The Trial gets HARDER -- and the BOSSES THEMSELVES CHANGE -- as the job you
    -- are ascending climbs in prestige level, so you never grind the same three
    -- forever and the fight never trivializes as you bank AP. DISCRETE TIERS: at
    -- summon time we read the prestige LEVEL of your current main job (each
    -- ascension == 1 level on that job) and apply the HIGHEST tier whose minLevel
    -- you meet -- one tier per 10 ascensions.
    --
    -- Each tier from 1 up carries its OWN `roster`: a fresh Court of three
    -- Ascension-EXCLUSIVE bosses (distinct mob_groups rows in
    -- prestige_trial_mobs.sql; a boss's `name` MUST match its SQL row). Tier 0
    -- has NO roster and falls back to the top-level trialBossOrder/trialBosses
    -- (the Nightmare Court). Rosters are authored at full strength and escalate
    -- to roughly the old mult-2.0 Apex by tier 4, so the difficulty curve holds.
    --
    -- A tier's `mult` (default 1.00 now that rosters carry the difficulty) is an
    -- optional FINE-TUNE applied on top of its roster: it multiplies the summoned
    -- boss's HP + every mod in scaleMods, and scales raw DEF gentler
    -- (1 + (mult-1)*defFactor) so a bump makes a tier deadlier, not spongier.
    -- Bump a tier's mult if its Court feels easy -- no need to re-author mods.
    --
    -- *** CAP = the top tier (4). Prestige level is UNCAPPED (maxLevel = nil) but
    -- every AP spend category IS capped, so power plateaus. Keep tier 4 at/under
    -- what a near-maxed AP build can beat or you SOFT-LOCK further ascension (the
    -- Trial gates it). Tune against a real maxed character. enabled=false reverts
    -- to flat tier-0 bosses (the Nightmare Court) at every level.
    trialScaling =
    {
        enabled   = true,
        defFactor = 0.5,                 -- DEF gets half a tier's mult bonus over 1.0
        defMod    = xi.mod.DEF,
        scaleMods =                      -- mods a tier `mult` > 1 multiplies
        {
            xi.mod.ATT,  xi.mod.ACC,  xi.mod.MATT, xi.mod.MACC,
            xi.mod.MEVA, xi.mod.MDEF, xi.mod.EVASION,
        },

        -- minLevel ASCENDING. `name` is the Court shown in menus/announces.
        -- Tier 0 = no roster -> the top-level Nightmare Court. Tiers 1-4 each
        -- summon their own three bosses (one Court per 10 ascensions).
        tiers =
        {
            { minLevel = 0, mult = 1.00, name = 'The Nightmare Court' },  -- P.Lv 0-9: Diabolos/Medusa/Odin (top-level roster)

            { minLevel = 10, mult = 1.00, name = 'The Voidwalkers',
              roster =
              {
                  order  = { 11381, 11382, 11383 },
                  bosses =
                  {
                      [11381] = { name = 'Sarameya', label = 'Sarameya, the Abyssal Hound', level = 150, hpBoost = 47,
                                  cry = '"From the rift I was loosed. I will drag you back through it."',
                                  mods = { [xi.mod.DEF] = 4125, [xi.mod.ATT] = 23400, [xi.mod.ACC] = 4860, [xi.mod.EVASION] = 1080, [xi.mod.MATT] = 1080, [xi.mod.MACC] = 1620, [xi.mod.MEVA] = 1440, [xi.mod.MDEF] = 1620, [xi.mod.STR] = 600, [xi.mod.VIT] = 500, [xi.mod.DOUBLE_ATTACK] = 30, [xi.mod.HASTE_GEAR] = 250, [xi.mod.REGEN] = 1100 } },
                      [11382] = { name = 'Kaggen', label = 'Kaggen, the Devouring Swarm', level = 150, hpBoost = 47,
                                  cry = '"Ten thousand mandibles hunger. Be unmade."',
                                  mods = { [xi.mod.DEF] = 3850, [xi.mod.ATT] = 21600, [xi.mod.ACC] = 5040, [xi.mod.EVASION] = 1440, [xi.mod.MATT] = 1620, [xi.mod.MACC] = 1980, [xi.mod.MEVA] = 1620, [xi.mod.MDEF] = 1440, [xi.mod.DEX] = 500, [xi.mod.INT] = 400, [xi.mod.DOUBLE_ATTACK] = 25, [xi.mod.TRIPLE_ATTACK] = 12, [xi.mod.HASTE_GEAR] = 300, [xi.mod.REGEN] = 1000 } },
                      [11383] = { name = 'Qilin', label = 'Qilin, the Tempest Beast', level = 150, hpBoost = 48,
                                  cry = '"The storm walks. You are merely in its path."',
                                  mods = { [xi.mod.DEF] = 3987, [xi.mod.ATT] = 22500, [xi.mod.ACC] = 5220, [xi.mod.EVASION] = 1620, [xi.mod.MATT] = 1800, [xi.mod.MACC] = 1980, [xi.mod.MEVA] = 1530, [xi.mod.MDEF] = 1530, [xi.mod.STR] = 500, [xi.mod.AGI] = 500, [xi.mod.DOUBLE_ATTACK] = 28, [xi.mod.HASTE_GEAR] = 350, [xi.mod.REGEN] = 1000 } },
                  },
              },
            },

            { minLevel = 20, mult = 1.00, name = 'The Jailers',
              roster =
              {
                  order  = { 11384, 11385, 11386 },
                  bosses =
                  {
                      [11384] = { name = 'Jailer_of_Justice', label = 'Jailer of Justice', level = 150, hpBoost = 54,
                                  cry = '"You are weighed, and found wanting. The sentence is death."',
                                  mods = { [xi.mod.DEF] = 4675, [xi.mod.ATT] = 27900, [xi.mod.ACC] = 6120, [xi.mod.EVASION] = 1800, [xi.mod.MATT] = 1980, [xi.mod.MACC] = 2340, [xi.mod.MEVA] = 1800, [xi.mod.MDEF] = 1800, [xi.mod.AGI] = 600, [xi.mod.DOUBLE_ATTACK] = 30, [xi.mod.TRIPLE_ATTACK] = 15, [xi.mod.HASTE_GEAR] = 400, [xi.mod.REGEN] = 1200 } },
                      [11385] = { name = 'Jailer_of_Fortitude', label = 'Jailer of Fortitude', level = 150, hpBoost = 56,
                                  cry = '"My guard has never broken. Yours already has."',
                                  mods = { [xi.mod.DEF] = 4537, [xi.mod.ATT] = 25200, [xi.mod.ACC] = 5760, [xi.mod.EVASION] = 1620, [xi.mod.MATT] = 2700, [xi.mod.MACC] = 2700, [xi.mod.MEVA] = 2160, [xi.mod.MDEF] = 2160, [xi.mod.INT] = 700, [xi.mod.MND] = 500, [xi.mod.HASTE_GEAR] = 350, [xi.mod.REGEN] = 1200 } },
                      [11386] = { name = 'Jailer_of_Temperance', label = 'Jailer of Temperance', level = 150, hpBoost = 54,
                                  cry = '"All things in measure -- including your last breath."',
                                  mods = { [xi.mod.DEF] = 5775, [xi.mod.ATT] = 26100, [xi.mod.ACC] = 5760, [xi.mod.EVASION] = 1260, [xi.mod.MATT] = 1800, [xi.mod.MACC] = 2160, [xi.mod.MEVA] = 2160, [xi.mod.MDEF] = 2340, [xi.mod.VIT] = 800, [xi.mod.STR] = 600, [xi.mod.DOUBLE_ATTACK] = 20, [xi.mod.HASTE_GEAR] = 250, [xi.mod.REGEN] = 1500 } },
                  },
              },
            },

            { minLevel = 30, mult = 1.00, name = 'The Voidwalker Lords',
              roster =
              {
                  order  = { 11387, 11388, 11389 },
                  bosses =
                  {
                      [11387] = { name = 'Kreutzet', label = 'Kreutzet, the Skydark', level = 150, hpBoost = 63,
                                  cry = '"I blot out the heavens. Die in my shadow."',
                                  mods = { [xi.mod.DEF] = 5912, [xi.mod.ATT] = 32400, [xi.mod.ACC] = 6840, [xi.mod.EVASION] = 1710, [xi.mod.MATT] = 2520, [xi.mod.MACC] = 2700, [xi.mod.MEVA] = 2340, [xi.mod.MDEF] = 2340, [xi.mod.STR] = 800, [xi.mod.VIT] = 700, [xi.mod.DOUBLE_ATTACK] = 28, [xi.mod.HASTE_GEAR] = 400, [xi.mod.REGEN] = 1500 } },
                      [11388] = { name = 'Raja', label = 'Raja, the Voidfang', level = 150, hpBoost = 63,
                                  cry = '"No cage has held me, and no flesh has survived me."',
                                  mods = { [xi.mod.DEF] = 5637, [xi.mod.ATT] = 31500, [xi.mod.ACC] = 7020, [xi.mod.EVASION] = 1890, [xi.mod.MATT] = 2880, [xi.mod.MACC] = 3060, [xi.mod.MEVA] = 1620, [xi.mod.MDEF] = 2520, [xi.mod.INT] = 800, [xi.mod.STR] = 700, [xi.mod.DOUBLE_ATTACK] = 30, [xi.mod.HASTE_GEAR] = 450, [xi.mod.REGEN] = 1400, [xi.mod.SILENCE_RES_RANK] = -11 } },  -- 2026-06-13: made silenceable -- MEVA 1400->900 eases the magic-accuracy gate; SILENCE_RES_RANK -11 removes Raja's silence-specific resistance so Silence lands at full duration (it was never hard-immune, just resisting via high MEVA + resist rank).
                      [11389] = { name = 'Maere', label = 'Maere, the Living Nightmare', level = 150, hpBoost = 65,
                                  cry = '"You will not wake from this one."',
                                  mods = { [xi.mod.DEF] = 5500, [xi.mod.ATT] = 30600, [xi.mod.ACC] = 7200, [xi.mod.EVASION] = 1980, [xi.mod.MATT] = 2700, [xi.mod.MACC] = 2880, [xi.mod.MEVA] = 2520, [xi.mod.MDEF] = 2340, [xi.mod.AGI] = 700, [xi.mod.INT] = 700, [xi.mod.DOUBLE_ATTACK] = 28, [xi.mod.TRIPLE_ATTACK] = 15, [xi.mod.HASTE_GEAR] = 450, [xi.mod.REGEN] = 1400 } },
                  },
              },
            },

            { minLevel = 40, mult = 1.00, name = "The World's End",
              roster =
              {
                  order  = { 11390, 11391, 11392 },
                  bosses =
                  {
                      [11390] = { name = 'Omega',  label = 'Omega, the Final Engine', level = 150, hpBoost = 72,
                                  cry = '"Directive: extinction. Target: all that draws breath."',
                                  mods = { [xi.mod.DEF] = 6600, [xi.mod.ATT] = 36900, [xi.mod.ACC] = 7920, [xi.mod.EVASION] = 2070, [xi.mod.MATT] = 3240, [xi.mod.MACC] = 3420, [xi.mod.MEVA] = 2880, [xi.mod.MDEF] = 2880, [xi.mod.STR] = 900, [xi.mod.INT] = 800, [xi.mod.DOUBLE_ATTACK] = 32, [xi.mod.TRIPLE_ATTACK] = 16, [xi.mod.HASTE_GEAR] = 450, [xi.mod.REGEN] = 1700 } },
                      [11391] = { name = 'Ultima', label = 'Ultima, the First Weapon', level = 150, hpBoost = 74,
                                  cry = '"I predate your gods. I will outlast your world."',
                                  mods = { [xi.mod.DEF] = 6737, [xi.mod.ATT] = 36000, [xi.mod.ACC] = 7920, [xi.mod.EVASION] = 2160, [xi.mod.MATT] = 3600, [xi.mod.MACC] = 3600, [xi.mod.MEVA] = 3060, [xi.mod.MDEF] = 3060, [xi.mod.INT] = 900, [xi.mod.MND] = 700, [xi.mod.DOUBLE_ATTACK] = 30, [xi.mod.HASTE_GEAR] = 500, [xi.mod.REGEN] = 1600 } },
                      [11392] = { name = 'Provenance_Watcher', label = 'The Provenance Watcher', level = 150, hpBoost = 75,
                                  cry = '"You stand in MY domain now. Provenance answers to me alone."',
                                  mods = { [xi.mod.DEF] = 6875, [xi.mod.ATT] = 37800, [xi.mod.ACC] = 8280, [xi.mod.EVASION] = 2340, [xi.mod.MATT] = 3600, [xi.mod.MACC] = 3780, [xi.mod.MEVA] = 3240, [xi.mod.MDEF] = 3240, [xi.mod.STR] = 900, [xi.mod.INT] = 900, [xi.mod.DOUBLE_ATTACK] = 32, [xi.mod.TRIPLE_ATTACK] = 18, [xi.mod.HASTE_GEAR] = 500, [xi.mod.REGEN] = 1800 } },
                  },
              },
            },

            -- ---- Tier 5 : The Celestial Wardens (P.Lv 60+) ---------------
            -- The sky-gods that governed Vana'diel at the height of their
            -- power.  Pools: Tiamat (3916), Kirin (2265), Absolute Virtue
            -- (21).  All three have retail FLAG_HIDE_MODEL; cleared in
            -- prestige_trial_mobs.sql so they render outside a battlefield.
            { minLevel = 60, mult = 1.00, name = 'The Celestial Wardens',
              roster =
              {
                  order  = { 11393, 11394, 11395 },
                  bosses =
                  {
                      [11393] = { name = 'Tiamat', label = 'Tiamat, the Planar Destroyer', level = 150, hpBoost = 80,
                                  cry = '"Five heads, five hungers. Which one finishes you is a matter of whim."',
                                  mods = { [xi.mod.DEF] = 7562, [xi.mod.ATT] = 43200, [xi.mod.ACC] = 9000, [xi.mod.EVASION] = 2520, [xi.mod.MATT] = 4320, [xi.mod.MACC] = 4500, [xi.mod.MEVA] = 3600, [xi.mod.MDEF] = 3600, [xi.mod.STR] = 1000, [xi.mod.VIT] = 800, [xi.mod.DOUBLE_ATTACK] = 32, [xi.mod.TRIPLE_ATTACK] = 16, [xi.mod.HASTE_GEAR] = 500, [xi.mod.REGEN] = 2000 } },
                      [11394] = { name = 'Kirin', label = 'Kirin, the Celestial Sovereign', level = 150, hpBoost = 83,
                                  cry = '"I am the balance of heaven made manifest.  Tipping those scales is your last act."',
                                  mods = { [xi.mod.DEF] = 7875, [xi.mod.ATT] = 45000, [xi.mod.ACC] = 9360, [xi.mod.EVASION] = 2700, [xi.mod.MATT] = 4500, [xi.mod.MACC] = 4680, [xi.mod.MEVA] = 3780, [xi.mod.MDEF] = 3780, [xi.mod.STR] = 900, [xi.mod.AGI] = 900, [xi.mod.INT] = 900, [xi.mod.DOUBLE_ATTACK] = 30, [xi.mod.TRIPLE_ATTACK] = 18, [xi.mod.HASTE_GEAR] = 550, [xi.mod.REGEN] = 2100 } },
                      [11395] = { name = 'Absolute_Virtue', label = 'Absolute Virtue, the Eternal Judge', level = 150, hpBoost = 87,
                                  cry = '"There is no passage beyond this point.  This is not a trial.  This is the end."',
                                  mods = { [xi.mod.DEF] = 8250, [xi.mod.ATT] = 47700, [xi.mod.ACC] = 9900, [xi.mod.EVASION] = 2880, [xi.mod.MATT] = 5040, [xi.mod.MACC] = 5220, [xi.mod.MEVA] = 4140, [xi.mod.MDEF] = 4140, [xi.mod.STR] = 1100, [xi.mod.INT] = 1100, [xi.mod.MND] = 900, [xi.mod.DOUBLE_ATTACK] = 35, [xi.mod.TRIPLE_ATTACK] = 20, [xi.mod.HASTE_GEAR] = 600, [xi.mod.REGEN] = 2400 } },
                  },
              },
            },
        },
    },

    -- =========================================================
    -- AP SPEND CATEGORIES  (Job-Points-style tree)
    -- =========================================================
    -- Each category buys a permanent stat mod applied via player:addMod
    -- and re-applied on every zone-in AND job change.
    --
    -- Single-mod categories:  mod  = xi.mod.*  (one constant)
    -- Multi-mod categories:   mods = { xi.mod.*, ... }  (array; each gets
    --   the same perLevel delta per purchased level)
    --
    -- Common fields:
    --   id       unique key; CharVar stored as 'Prestige_Cat_<job>_<id>'
    --   label    menu display (kept short for the 150-byte menu cap)
    --   perLevel raw delta added per level -- see scale notes below
    --   cap      max levels purchasable
    --   apCost   AP cost per level
    --   note     shown to player on purchase
    --
    -- SCALE REFERENCE (raw perLevel -> human %). VERIFIED against the engine.
    --   xi.mod.HASTE_GEAR / DMGPHYS      : /10000  (100 raw = 1%)
    --   xi.mod.SKILLCHAINBONUS           : /100    (  1 raw = 1%)
    --   FASTCAST / SPELLINTERRUPT / CURE_POTENCY / CRIT_DMG_INCREASE /
    --     ALL_WSDMG_ALL_HITS             : WHOLE-% (  1 raw = 1%)  <-- these were
    --     WRONGLY treated as "10-base", which over-granted them 10x. Corrected:
    --     each engine formula reads them as a plain percent ((100 +/- mod)/100,
    --     or a direct % for FASTCAST), so 1 raw = 1%.
    --   All other mods                   : flat    (  1 raw = 1 pt)
    categories =
    {
        -- ---- Base stats -----------------------------------------------
        { id = 'STR', label = 'Strength',     mod = xi.mod.STR, perLevel = 1, cap = 50, apCost = 1, note = '+1 STR / level (max +50) [1 AP]'  },
        { id = 'DEX', label = 'Dexterity',    mod = xi.mod.DEX, perLevel = 1, cap = 50, apCost = 1, note = '+1 DEX / level (max +50) [1 AP]'  },
        { id = 'VIT', label = 'Vitality',     mod = xi.mod.VIT, perLevel = 1, cap = 50, apCost = 1, note = '+1 VIT / level (max +50) [1 AP]'  },
        { id = 'AGI', label = 'Agility',      mod = xi.mod.AGI, perLevel = 1, cap = 50, apCost = 1, note = '+1 AGI / level (max +50) [1 AP]'  },
        { id = 'INT', label = 'Intelligence', mod = xi.mod.INT, perLevel = 1, cap = 50, apCost = 1, note = '+1 INT / level (max +50) [1 AP]'  },
        { id = 'MND', label = 'Mind',         mod = xi.mod.MND, perLevel = 1, cap = 50, apCost = 1, note = '+1 MND / level (max +50) [1 AP]'  },
        { id = 'CHR', label = 'Charisma',     mod = xi.mod.CHR, perLevel = 1, cap = 50, apCost = 1, note = '+1 CHR / level (max +50) [1 AP]'  },

        -- ---- Vitals ---------------------------------------------------
        -- HP: 20 pts/level × 50 levels = +1000 HP
        { id = 'HP',  label = 'Max HP', mod = xi.mod.HP, perLevel = 20, cap = 50, apCost = 1, note = '+20 HP / level (max +1000) [1 AP]'  },
        -- MP: 20 pts/level × 25 levels = +500 MP
        { id = 'MP',  label = 'Max MP', mod = xi.mod.MP, perLevel = 20, cap = 25, apCost = 1, note = '+20 MP / level (max +500) [1 AP]'   },

        -- ---- Melee offense / defense ----------------------------------
        -- ACC: 10 pts/level × 50 = +500; ATT: 20×50 = +1000
        { id = 'ACC',  label = 'Accuracy', mod = xi.mod.ACC, perLevel = 10, cap = 50, apCost = 1, note = '+10 Accuracy / level (max +500) [1 AP]'  },
        { id = 'ATT',  label = 'Attack',   mod = xi.mod.ATT, perLevel = 20, cap = 50, apCost = 1, note = '+20 Attack / level (max +1000) [1 AP]'   },
        { id = 'DEF',  label = 'Defense',  mod = xi.mod.DEF, perLevel =  5, cap = 50, apCost = 1, note = '+5 Defense / level (max +250) [1 AP]'    },
        { id = 'EVA',  label = 'Evasion',  mod = xi.mod.EVA, perLevel =  5, cap = 50, apCost = 1, note = '+5 Evasion / level (max +250) [1 AP]'    },

        -- ---- Magic offense -------------------------------------------
        -- MACC / MATT: 20×50 = +1000 each
        { id = 'MACC', label = 'Magic Acc', mod = xi.mod.MACC, perLevel = 20, cap = 50, apCost = 1, note = '+20 Mag.Acc / level (max +1000) [1 AP]' },
        { id = 'MATT', label = 'Magic Atk', mod = xi.mod.MATT, perLevel = 20, cap = 50, apCost = 1, note = '+20 Mag.Atk / level (max +1000) [1 AP]' },
        -- MAGIC_DAMAGE is flat (added directly to a spell's base damage). No hard cap.
        { id = 'MDMG', label = 'Magic Dmg', mod = xi.mod.MAGIC_DAMAGE, perLevel = 10, cap = 25, apCost = 2, note = '+10 Magic Dmg / level (max +250) [2 AP]' },

        -- ---- Ranged offense ------------------------------------------
        -- Mirrors melee ACC/ATT for RNG/COR. Flat, no hard cap.
        { id = 'RACC', label = 'Ranged Acc', mod = xi.mod.RACC, perLevel = 10, cap = 50, apCost = 1, note = '+10 R.Acc / level (max +500) [1 AP]'  },
        { id = 'RATT', label = 'Ranged Att', mod = xi.mod.RATT, perLevel = 20, cap = 50, apCost = 1, note = '+20 R.Att / level (max +1000) [1 AP]' },

        -- ---- Combat traits -------------------------------------------
        { id = 'STP',    label = 'Store TP',    mod = xi.mod.STORETP,            perLevel =  2, cap = 50, apCost = 2, note = '+2 Store TP / level (max +100) [2 AP]'     },
        { id = 'TPBON',  label = 'TP Bonus',    mod = xi.mod.TP_BONUS,           perLevel = 10, cap = 50, apCost = 2, note = '+10 TP Bonus / level (max +500) [2 AP]'    },
        { id = 'QA',     label = 'Quad Atk',    mod = xi.mod.QUAD_ATTACK,        perLevel =  1, cap = 50, apCost = 2, note = '+1% Quad.Atk / level (max 50%) [2 AP]'    },
        -- DUAL_WIELD is whole-% (1 raw = 1% delay reduction on the off-hand). No
        -- engine clamp, but it's practically capped by the attack-delay floor when
        -- stacked with Haste, so the perk is held to a sane +25%.
        { id = 'DW',     label = 'Dual Wield',  mod = xi.mod.DUAL_WIELD,         perLevel =  1, cap = 25, apCost = 2, note = '+1% Dual Wield / level (max 25%) [2 AP]'  },
        { id = 'CRIT',   label = 'Crit Rate',   mod = xi.mod.CRITHITRATE,        perLevel =  1, cap = 50, apCost = 2, note = '+1% Crit / level (max 50%) [2 AP]'         },
        -- CRIT_DMG_INCREASE is WHOLE-% (engine: pDif*(100+mod)/100, clamped 100):
        -- perLevel 2 = +2% crit damage; max +100% at 50 levels.
        { id = 'CRITDMG',label = 'Crit Dmg',    mod = xi.mod.CRIT_DMG_INCREASE,  perLevel = 2, cap = 50, apCost = 3, note = '+2% Crit Dmg / level (max 100%) [3 AP]'   },
        { id = 'CTR',    label = 'Counter',      mod = xi.mod.COUNTER,            perLevel =  1, cap = 50, apCost = 2, note = '+1 Counter / level (max +50) [2 AP]'       },
        { id = 'PARRY',  label = 'Parry Rate',   mod = xi.mod.PARRY,              perLevel =  1, cap = 25, apCost = 1, note = '+1% Parry / level (max 25%) [1 AP]'        },
        { id = 'SBL',    label = 'Subtle Blow',  mod = xi.mod.SUBTLE_BLOW,        perLevel =  1, cap = 50, apCost = 1, note = '+1 Subtle Blow / level (max +50) [1 AP]'   },
        -- ALL_WSDMG_ALL_HITS is WHOLE-% (engine: dmg*(100+mod)/100):
        -- perLevel 2 = +2% WS damage; max +100% at 50 levels.
        { id = 'WSDMG',  label = 'WS Dmg',       mod = xi.mod.ALL_WSDMG_ALL_HITS, perLevel = 2, cap = 50, apCost = 3, note = '+2% WS Dmg / level (max 100%) [3 AP]'     },
        -- SKILLCHAINBONUS 100:1 (engine: (100+mod)/100): perLevel 2 = +2% skillchain damage per level; max 100%
        { id = 'SCDMG',  label = 'SC Dmg',       mod = xi.mod.SKILLCHAINBONUS,    perLevel =  2, cap = 50, apCost = 3, note = '+2% Skillchain Dmg / level (max 100%) [3 AP]' },

        -- ---- Mitigation -----------------------------------------------
        -- 10000:1 scale: perLevel -100 = -1% PDT per level; cap 25 = -25% max
        { id = 'PDT',   label = 'Phys.DT-',  mod = xi.mod.DMGPHYS,    perLevel = -100, cap = 25, apCost = 3, note = '-1% Phys.DT / level (max -25%) [3 AP]'    },
        -- DMGMAGIC mirrors DMGPHYS (same 100:1 scale). Engine HARD-CAPS damage
        -- taken at -50%; perk maxes at -25%, leaving headroom for gear.
        { id = 'MDT',   label = 'Mag.DT-',   mod = xi.mod.DMGMAGIC,   perLevel = -100, cap = 25, apCost = 3, note = '-1% Mag.DT / level (max -25%) [3 AP]'     },
        -- 10000:1 scale: perLevel 100 = +1% haste per level; cap 25 = 25% max
        { id = 'HASTE', label = 'Haste',      mod = xi.mod.HASTE_GEAR, perLevel =  100, cap = 25, apCost = 3, note = '+1% Haste / level (max 25%) [3 AP]'        },

        -- ---- Magic support -------------------------------------------
        -- SPELLINTERRUPT is WHOLE-% (engine: (100 - mod)/100 interrupt chance):
        -- perLevel 1 = +1% SIRD; max +50% at 50 levels.
        { id = 'INTP',  label = 'Spell Intp',   mod = xi.mod.SPELLINTERRUPT,    perLevel = 1, cap = 50, apCost = 2, note = '+1% SIRD / level (max 50%) [2 AP]'          },
        -- FASTCAST is WHOLE-% (engine reads it as a direct percent, clamped 50/80):
        -- perLevel 1 = +1% fast cast; max +50% at 50 levels.
        { id = 'FCAST', label = 'Fast Cast',     mod = xi.mod.FASTCAST,          perLevel = 1, cap = 50, apCost = 2, note = '+1% Fast Cast / level (max 50%) [2 AP]'     },
        { id = 'ENSP',  label = 'Enspell Dmg',   mod = xi.mod.ENSPELL_DMG_BONUS, perLevel = 10, cap = 50, apCost = 2, note = '+10 Enspell Dmg / level (max +500) [2 AP]'  },
        -- CURE_POTENCY is WHOLE-% (engine: cure*(100+mod)/100). Cure Potency
        -- HARD-CAPS at +50%, so the perk is capped there (cap 25 = +50%) -- buying
        -- past it would be wasted AP.
        { id = 'CURE',  label = 'Cure Potency',  mod = xi.mod.CURE_POTENCY,      perLevel = 2, cap = 25, apCost = 2, note = '+2% Cure Pot. / level (max +50%) [2 AP]'    },
        -- REFRESH is flat (MP/tick). No hard cap; held to a sane +10 MP/tick.
        { id = 'RFSH',  label = 'Refresh',       mod = xi.mod.REFRESH,           perLevel = 1, cap = 10, apCost = 3, note = '+1 Refresh / level (max +10 MP/tick) [3 AP]' },

        -- ---- Utility --------------------------------------------------
        { id = 'TH',  label = 'Treas.Hunter', mod = xi.mod.TREASURE_HUNTER, perLevel = 1, cap = 50, apCost = 2, note = '+1 TH / level (max +50) [2 AP]'              },
        { id = 'GIL', label = 'Gilfinder',    mod = xi.mod.GILFINDER,        perLevel = 2, cap = 50, apCost = 1, note = '+2% Gilfinder / level (max +100%) [1 AP]'    },

        -- ---- Resistances ---------------------------------------------
        { id = 'STRES', label = 'Status Res', mod = xi.mod.STATUSRES, perLevel = 2, cap = 50, apCost = 1, note = '+2 Status Res. / level (max +100) [1 AP]'          },

        -- Eight elemental MEVA mods applied simultaneously.
        -- Prestige_System.lua iterates cat.mods when cat.mod is nil.
        { id = 'ELRES', label = 'Ele. Resist',
          mods =
          {
              xi.mod.FIRE_MEVA, xi.mod.ICE_MEVA,     xi.mod.WIND_MEVA,
              xi.mod.EARTH_MEVA, xi.mod.THUNDER_MEVA, xi.mod.WATER_MEVA,
              xi.mod.LIGHT_MEVA, xi.mod.DARK_MEVA,
          },
          perLevel = 10, cap = 50, apCost = 1, note = '+10 Ele.Resist / level (max +500 each) [1 AP]' },

        -- ---- Skills --------------------------------------------------
        -- Every weapon, ranged, defensive, and magic skill boosted at once.
        -- 2 pts/level × 50 levels = +100 to every skill.
        { id = 'SKILL', label = 'All Skills',
          mods =
          {
              -- Weapon skills
              xi.mod.HTH,    xi.mod.DAGGER,  xi.mod.SWORD,   xi.mod.GSWORD,
              xi.mod.AXE,    xi.mod.GAXE,    xi.mod.SCYTHE,  xi.mod.POLEARM,
              xi.mod.KATANA, xi.mod.GKATANA, xi.mod.CLUB,    xi.mod.STAFF,
              -- Ranged + defensive skills
              xi.mod.ARCHERY, xi.mod.MARKSMAN, xi.mod.THROW,
              xi.mod.GUARD,   xi.mod.EVASION,  xi.mod.SHIELD,  xi.mod.PARRY,
              -- Magic skills
              xi.mod.DIVINE,  xi.mod.HEALING,  xi.mod.ENHANCE,       xi.mod.ENFEEBLE,
              xi.mod.ELEM,    xi.mod.DARK,     xi.mod.SUMMONING,     xi.mod.NINJUTSU,
              xi.mod.SINGING, xi.mod.STRING,   xi.mod.WIND,          xi.mod.BLUE,
              xi.mod.GEOMANCY_SKILL, xi.mod.HANDBELL_SKILL,
          },
          perLevel = 2, cap = 50, apCost = 1, note = '+2 All Skills / level (max +100 each) [1 AP]' },
    },
}
