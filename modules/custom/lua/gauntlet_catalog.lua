-----------------------------------
-- gauntlet_catalog.lua
--
-- Config constants for The Gauntlet (10-level challenge in Riverne Site A01).
-- NM HP + stats climb each level and each NM carries a hardcore mechanics kit
-- (mechCfg) so a maxed character must actually struggle. Defeating a level pays
-- a per-level reward; defeating level 10 grants a massive jackpot and enshrines
-- the champion as an NPC in the Hall of Champions (B01).
-----------------------------------
local C = {}

-- Zone IDs
C.GROUP_ZONE = 210  -- mob template zone (GM Home -- all Apex groups defined here)
C.ARENA_ZONE = 30   -- Riverne-Site_A01 (the 10-level combat zone)
C.HALL_ZONE  = 29   -- Riverne-Site_B01 (Hall of Champions, read-only display)

-- Spawn positions (verified from zone scripts)
C.WARP_IN  = { x = 732.55, y = -32.5, z = -506.544, rot = 90 }  -- Riverne A01 default spawn
C.HALL_IN  = { x = 729.749, y = -20.319, z = 407.153, rot = 90 } -- Riverne B01 default spawn
C.EXIT_POS = { x = 521.5, y = -3.0, z = 548.0, rot = 65, zoneId = 44 } -- back to Leafallia (relaunch hub)

-- NM pool by level (groupIds from zone 210; all confirmed in mob_groups)
C.NM_POOL = {
    [1]  = { groupId = 11360, name = 'Aquarius',           skillListId = 77  },
    [2]  = { groupId = 11361, name = 'Serket',             skillListId = 273 },
    [3]  = { groupId = 11363, name = 'Simurgh',            skillListId = 1004 },
    [4]  = { groupId = 11364, name = 'Nidhogg',            skillListId = 263 },
    [5]  = { groupId = 11365, name = 'King Behemoth',      skillListId = 479 },
    [6]  = { groupId = 11362, name = 'Vrtra',              skillListId = 391 },
    [7]  = { groupId = 11366, name = 'Kirin',              skillListId = 281 },
    [8]  = { groupId = 11367, name = 'Absolute Virtue',    skillListId = 329 },
    [9]  = { groupId = 11368, name = 'Pandemonium Warden', skillListId = 316 },
    [10] = { groupId = 11369, name = 'Shinryu',            skillListId = 475 },
}

-- HP: a steep exponential wall calibrated against this server's overflow-fixed
-- endgame DPS (pets/ranged/WS all ride near the 131k cap). 2026-06-24: pushed
-- the top end hard to force a long endurance fight THROUGH the mechCfg() kit --
-- L1 ≈ 3.5M (a real fight, never a faceroll) climbing to L10 ≈ 119M (a maxed
-- char must sustain many minutes of capped DPS while surviving the mechanics).
-- HP is the boss's int32 health, so this has huge headroom (no overflow); it's
-- the primary "harder" lever once the int16-capped mods below are maxed out.
C.NM_BASE_HP = 50000000
C.HP_GROWTH  = 1.166
function C.nmHp(level)
    return math.floor(C.NM_BASE_HP * (C.HP_GROWTH ^ (level - 1)))
end

-- Mob level: keep every Gauntlet NM in a stable endgame band so Riverne's
-- level correction does not floor player damage to zero. Difficulty comes from
-- HP, mods, and mechanics below rather than inflated mob level.
C.NM_LEVEL = 99
function C.nmLevel(level)
    return C.NM_LEVEL
end

-- Stat scaling: a BASE floor applied at EVERY level (so even L1 hits hard,
-- LANDS on evasion-stacked maxed chars, and is genuinely TANKY) PLUS a per-level
-- climb. Defenses are intentionally SUPER -- physical DEF + magical MDEF/MEVA
-- both scale to the top of (and past) the server's hardest existing content,
-- the Ascension/Prestige trial NMs (DEF ~8k, MDEF/MEVA ~4k). This makes the mob
-- shrug off damage so the fight lasts and the player must actually beat the
-- mechCfg() mechanics, not melt it in seconds.
--   * Magic stays RELEVANT: magic dmg ≈ (100+MATT)/(100+MDEF), so MDEF 6k-8k
--     scales magical output down smoothly (it does NOT zero it) -- and as a bonus
--     it suppresses the magical-BP overflow. MEVA makes player debuffs/nukes
--     resist more often.
--   * Physical stays KILLABLE: WS still ride the 131k cap once attack outscales
--     DEF, so the heavily-boosted setups (pets/ranged/augmented melee) punch
--     through; pure unboosted melee will feel the wall (that is the point).
-- 2026-06-24: hardened to the limit. CRITICAL: mob modifiers are int16, so every
-- value here MUST stay under 32,767 (the mechanics lib's safeAddMod also clamps at
-- 32,000). Exceeding it wraps to NEGATIVE -- e.g. an ATT mod that overflows makes
-- the boss hit for ZERO (the "underflow" failure). Keep direct ATT below the cap;
-- use mechanics/haste/HP for extra difficulty beyond that.
--   ATT  L10 31,000  -- direct ATT cannot safely reach 50,000 without C++ changes
--   ACC  L10 14,600  -- never misses, even evasion-stacked tanks
--   DEF  L10 10,000  -- lowered so physical players do not floor out as often
--   MEVA L10 4,500   -- moderated resist scaling
--   MDEF L10 8,000   -- heavy magic mitigation without the old spike
--   EVA  L10 4,000   -- moderated evasion scaling
C.BASE_ATT = 12000
C.ATT_PER_LEVEL = 19500 / 9 -- L1 = 12,000 ... L10 = 31,500 after rounding (int16-safe)
C.BASE_ACC = 3600
C.ACC_PER_LEVEL = 1700   -- L1 = 3,600 ... L10 = 18,900 (real melee never misses)
C.BASE_DEF = 10000
C.DEF_PER_LEVEL = 8000 / 9 -- L1 = 10,000 ... L10 = 18,000 after rounding
C.BASE_MDEF = 8000
C.MDEF_PER_LEVEL = 6000 / 9 -- L1 = 8,000 ... L10 = 14,000 after rounding
C.BASE_MEVA = 4000
C.MEVA_PER_LEVEL = 3000 / 9   -- L1 = 4,000 ... L10 = 7,000
C.BASE_EVA = 3500
C.EVA_PER_LEVEL = 2500 / 9 -- L1 = 3,500 ... L10 = 6,000 after rounding
C.BASE_REGAIN = 250
C.REGAIN_PER_LEVEL = 500 / 9 -- L1 = 250 ... L10 = 750 after rounding
C.BASE_MATT = 15000
C.MATT_PER_LEVEL = 1500 / 9 -- L1 = 15,000 ... L10 = 16,500 after rounding
C.BASE_MACC = 9000
C.MACC_PER_LEVEL = 3000 / 9 -- L1 = 9,000 ... L10 = 12,000 after rounding
C.BASE_INT = 500
C.INT_PER_LEVEL = 2500 / 9 -- L1 = 500 ... L10 = 3,000 after rounding
C.BASE_WEAPON_BONUS = 40
C.WEAPON_BONUS_PER_LEVEL = 110 / 9 -- L1 = 40 ... L10 = 150 after rounding
C.STR_PER_LEVEL = 450    -- L10 = 4,050
C.DEX_PER_LEVEL = 380    -- L10 = 3,420
C.VIT_PER_LEVEL = 420    -- L10 = 3,780
C.AGI_PER_LEVEL = 380    -- L10 = 3,420

-- Flat stat mod table for a given Gauntlet level (xi.mod.* resolved at call time)
function C.nmMods(level)
    local t = level - 1
    return {
        [xi.mod.ATT]  = math.floor(C.BASE_ATT + t * C.ATT_PER_LEVEL + 0.5),
        [xi.mod.ACC]  = C.BASE_ACC  + t * C.ACC_PER_LEVEL,
        [xi.mod.DEF]  = math.floor(C.BASE_DEF + t * C.DEF_PER_LEVEL + 0.5),
        [xi.mod.MDEF] = math.floor(C.BASE_MDEF + t * C.MDEF_PER_LEVEL + 0.5),
        [xi.mod.MEVA] = C.BASE_MEVA + t * C.MEVA_PER_LEVEL,
        [xi.mod.EVA]  = math.floor(C.BASE_EVA + t * C.EVA_PER_LEVEL + 0.5),
        [xi.mod.REGAIN] = math.floor(C.BASE_REGAIN + t * C.REGAIN_PER_LEVEL + 0.5),
        [xi.mod.MATT] = math.floor(C.BASE_MATT + t * C.MATT_PER_LEVEL + 0.5),
        [xi.mod.MACC] = math.floor(C.BASE_MACC + t * C.MACC_PER_LEVEL + 0.5),
        [xi.mod.INT]  = math.floor(C.BASE_INT + t * C.INT_PER_LEVEL + 0.5),
        [xi.mod.STR]  = t * C.STR_PER_LEVEL,
        [xi.mod.DEX]  = t * C.DEX_PER_LEVEL,
        [xi.mod.VIT]  = t * C.VIT_PER_LEVEL,
        [xi.mod.AGI]  = t * C.AGI_PER_LEVEL,
    }
end

-- MobMod tuning for a given Gauntlet level.
function C.nmMobMods(level)
    local t = level - 1
    return {
        [xi.mobMod.WEAPON_BONUS] = math.floor(C.BASE_WEAPON_BONUS + t * C.WEAPON_BONUS_PER_LEVEL + 0.5),
    }
end

-- Human-readable HP display (e.g. "12.8M")
function C.formatHp(hp)
    if hp >= 1000000 then
        return string.format('%.1fM', hp / 1000000)
    elseif hp >= 1000 then
        return string.format('%.0fk', hp / 1000)
    end
    return tostring(hp)
end

-- Per-level reward for DEFEATING a level's NM (levels 1-9; level 10 pays the
-- FINAL_REWARD jackpot below instead). Every fight pays out, so a run that ends
-- before level 10 is still rewarded for the levels actually cleared.
function C.LEVEL_REWARD(level)
    return {
        gil    = level * 50000,    -- L1 = 50k ... L9 = 450k
        infamy = level * 10,       -- L1 = 10 ... L9 = 90 (cut 90% 2026-06-25)
        pp     = level * 1,        -- L1 = 1 ... L9 = 9 (cut 90% 2026-06-25)
    }
end

-- Milestone bonuses keep partial runs worthwhile without making level farming
-- better than a full clear.
C.MILESTONE_REWARDS = {
    [3] = { gil = 250000,  pp = 25,  infamy = 25  },
    [6] = { gil = 750000,  pp = 75,  infamy = 75  },
    [9] = { gil = 1500000, pp = 150, infamy = 150 },
}

-- Final clear reward (level 10 NM kill)
C.FINAL_REWARD = {
    gil    = 5000000,    -- 5M gil
    pp     = 500,        -- Paragon Points
    infamy = 500,        -- Infamy
}

-- Champion NPC appearance in Hall of Champions
C.CHAMPION_LOOK = 2419  -- same heroic model as Rupture Sage

-- Data file for persistent champion list (io.write pattern from setbonus.lua)
C.CHAMPION_DATA_FILE = 'modules/custom/lua/gauntlet_champion_data.lua'

-- NPC / NM spawn offsets within zone 30 (relative to player warp-in position).
-- Lane 1 uses the old Safe Path position for Final Trial. Lane 2 is 40 yalms
-- west of that spot, with its NM 5 yalms south of its Final Trial moogle.
C.ARENA_LANES = {
    [1] = {
        challenge = { x = 5.0,   z = 0.0 },
        final     = { x = -5.0,  z = 0.0 },
        nm        = { x = -5.0,  z = 5.0 },
    },
    [2] = {
        challenge = { x = -35.0, z = 0.0 },
        final     = { x = -45.0, z = 0.0 },
        nm        = { x = -45.0, z = 5.0 },
    },
}

C.MAX_ACTIVE_PER_LANE = 3
C.LANE_SLOT_OFFSETS = {
    [1] = { x = 0.0, z = 0.0 },
    [2] = { x = 0.0, z = 22.0 },
    [3] = { x = 0.0, z = -22.0 },
}

C.RANGED_DAMAGE_REDUCTION = -5000 -- -50% ranged damage outside hold-fire weakness windows.
C.SILENCE_RES_DOWN =
{
    [7] = -75, -- Kirin: silence should land reliably without lowering MEVA.
    [9] = -75, -- Pandemonium Warden: same, silence-specific only.
}

function C.weakWindowMods(level)
    local t = level - 1
    local currentDef  = math.floor(6000 + t * (4000 / 9) + 0.5)
    local currentMdef = math.floor(6000 + t * (2000 / 9) + 0.5)
    local currentEva  = math.floor(2500 + t * (1500 / 9) + 0.5)
    local currentMeva = math.floor(2700 + t * 200 + 0.5)

    local mult = 1.0
    if level == 10 then
        mult = 1.35 -- Shinryu gets the largest weakness drop.
    elseif level == 9 then
        mult = 1.20 -- PW gets a meaningful but smaller drop.
    elseif level == 8 then
        mult = 1.10 -- AV gets the lightest of the endgame trio.
    elseif level == 1 then
        mult = 1.15 -- Aquarius should always feel weaker, never tougher.
    end

    return {
        defDown  = math.floor(math.max(0, math.floor(C.BASE_DEF + t * C.DEF_PER_LEVEL + 0.5) - currentDef) * mult + 0.5),
        mdefDown = math.floor(math.max(0, math.floor(C.BASE_MDEF + t * C.MDEF_PER_LEVEL + 0.5) - currentMdef) * mult + 0.5),
        evaDown  = math.floor(math.max(0, math.floor(C.BASE_EVA + t * C.EVA_PER_LEVEL + 0.5) - currentEva) * mult + 0.5),
        mevaDown = math.floor(math.max(0, math.floor(C.BASE_MEVA + t * C.MEVA_PER_LEVEL + 0.5) - currentMeva) * mult + 0.5),
    }
end

-- ── Hardcore combat mechanics per level (mob_mechanics_library.lua) ──────────
-- This is what makes a maxed character STRUGGLE alongside the raw stat block.
-- 2026-06-24: ALL phantom damage removed (the periodic `aoe` pulse and `nuke`
-- phase action -- both dealt animation-less SPECIAL damage; disabled server-wide
-- in the library). Difficulty here is now 100% REAL combat: a massive-ATT,
-- high-ACC, hasted boss (enrage/fury ramp real melee), phys/magic stance RESIST
-- windows, CC, drain, dispels that strip your defensive buffs (so the real melee
-- hits even harder), and hold-fire punish windows. Banded by level.
--
-- DMGPHYS/DMGMAGIC = -5000 is the engine's -50% cap (heavy RESIST, not immunity)
-- so a solo player locked to one damage type is slowed, never hard-walled. The
-- drain is a fixed 15s self-heal tick, scaling 10k at L1 to 100k at L10.
-- xi.* is resolved at call time.
function C.holdFireCfg(level)
    local messages =
    {
        [1]  = {
            warning = 'Aquarius snaps its claws as the tide around it turns black...',
            fail    = 'The undertow takes what impatience offers.',
            pressure = { effect = xi.effect.POISON, power = 1 },
        },
        [2]  = {
            warning = 'Serket raises its tail as venom beads in the air...',
            fail    = 'The sting was waiting for movement.',
            pressure = { effect = xi.effect.POISON, power = 1 },
        },
        [3]  = {
            warning = 'Simurgh folds its wings and the wind goes still...',
            fail    = 'The silence breaks you first.',
            pressure = { effect = xi.effect.BLINDNESS, power = 256 },
        },
        [4]  = {
            warning = 'Nidhogg lowers its head as the earth trembles beneath you...',
            fail    = 'Ancient fury answers the challenge.',
            pressure = { effect = xi.effect.CURSE_I, power = 50 },
        },
        [5]  = {
            warning = 'King Behemoth draws thunder into its horns...',
            fail    = 'The storm chooses the reckless.',
            pressure = { effect = xi.effect.BLINDNESS, power = 256 },
        },
        [6]  = {
            warning = "Vrtra's eyes begin to glow with ancient malice...",
            fail    = 'You make it too easy.',
            pressure = { effect = xi.effect.CURSE_I, power = 50 },
        },
        [7]  = {
            warning = "The heavens answer Kirin's silent command...",
            fail    = 'Heaven does not forgive haste.',
            pressure = { effect = xi.effect.BLINDNESS, power = 256 },
        },
        [8]  = {
            warning = 'Absolute Virtue radiates overwhelming divine power...',
            fail    = 'The warning was not for decoration.',
            pressure = { effect = xi.effect.CURSE_I, power = 50 },
        },
        [9]  = {
            warning = 'Pandemonium Warden shifts through a dozen impossible forms...',
            fail    = 'Chaos finds the opening you gave it.',
            pressureOptions = {
                { effect = xi.effect.POISON, power = 1 },
                { effect = xi.effect.BLINDNESS, power = 256 },
                { effect = xi.effect.CURSE_I, power = 50 },
            },
        },
        [10] = {
            warning = 'Reality itself begins to distort around Shinryu...',
            fail    = 'Power answers recklessness.',
            pressure = { effect = xi.effect.CURSE_I, power = 50 },
        },
    }
    local msg = messages[level] or {
        warning = 'The monster draws in unstable energy...',
        fail    = 'The gathered power erupts through your mistake.',
    }

    return {
        initialSecMin       = 18,
        initialSecMax       = 34,
        periodSecMin        = math.max(24, 46 - level * 2),
        periodSecMax        = math.max(34, 68 - level * 2),
        warnSec             = 15,
        graceSec            = 3,
        mobNoTpSec          = 7,
        exhaustedSec        = 42,
        pressure            = msg.pressure,
        pressureOptions     = msg.pressureOptions,
        pressureTickSec     = 3,
        pressureDelaySec    = 2,
        pressureTickPct     = (level == 4 or level == 6) and 22 or 35,
        defDown             = C.weakWindowMods(level).defDown,
        mdefDown            = C.weakWindowMods(level).mdefDown,
        evaDown             = C.weakWindowMods(level).evaDown,
        mevaDown            = C.weakWindowMods(level).mevaDown,
        rangedRelief        = -C.RANGED_DAMAGE_REDUCTION,
        warningMsg          = msg.warning,
        failMsg             = msg.fail,
        successMsg          = 'The boss is exhausted and its defenses falter!',
        recoverMsg          = 'The boss recovers its strength.',
    }
end

function C.mechCfg(level)
    if level >= 10 then
        -- Shinryu, the final trial -- full real-combat kit, merciless clock.
        return {
            name   = 'Shinryu',
            enrage = { sec = 80, att = 10000, haste = 300, msg = 'unleashes its final fury!' },
            stance = { startHpp = 95, periodSec = 6, stances = {
                { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'scales harden -- steel barely bites!' },
                { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'wards the arcane -- magic fizzles!' },
            } },
            cc     = { periodSec = 14, effect = xi.effect.SILENCE, dur = 8, msg = 'roars -- your voice is stolen!' },
            drain  = { periodSec = 15, heal = level * 10000 },
            holdFire = C.holdFireCfg(level),
            phases = {
                { hp = 75, action = 'dispel', count = 7, msg = 'tears your blessings away!' },
                { hp = 55, action = 'fury',   att = 7000,  haste = 200, msg = 'enters a killing frenzy!' },
                { hp = 38, action = 'dispel', count = 5, msg = 'strips you bare again!' },
                { hp = 22, action = 'fury',   att = 9000,  haste = 260, msg = 'goes utterly berserk!' },
                { hp = 10, action = 'enrage', att = 12000, haste = 320, msg = 'will not be denied -- final form!' },
            },
        }
    elseif level >= 9 then
        return {
            name   = 'Pandemonium Warden',
            enrage = { sec = 95, att = 8500, haste = 260, msg = 'shifts form and presses harder!' },
            stance = { startHpp = 88, periodSec = 7, stances = {
                { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'armors against weapons -- use magic!' },
                { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'deflects magic -- use steel!' },
            } },
            cc     = { periodSec = 16, effect = xi.effect.TERROR, dur = 8, msg = 'projects raw dread!' },
            drain  = { periodSec = 15, heal = level * 10000 },
            holdFire = C.holdFireCfg(level),
            phases = {
                { hp = 65, action = 'dispel', count = 6, msg = 'strips your enhancements!' },
                { hp = 42, action = 'fury',   att = 6000, haste = 180, msg = 'rages without restraint!' },
                { hp = 18, action = 'enrage', att = 9000, haste = 250, msg = 'enters its final fury!' },
            },
        }
    elseif level >= 7 then
        return {
            name   = (level == 8) and 'Absolute Virtue' or 'Kirin',
            enrage = { sec = 110, att = 7500, haste = 230, msg = 'reaches full battle-fury!' },
            stance = { startHpp = 82, periodSec = 8, stances = {
                { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'hardens against steel -- switch to magic!' },
                { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'turns magic aside -- cut it down!' },
            } },
            cc     = { periodSec = 18, effect = xi.effect.TERROR, dur = 7, msg = 'unleashes a wave of terror!' },
            drain  = { periodSec = 15, heal = level * 10000 },
            holdFire = C.holdFireCfg(level),
            phases = {
                { hp = 50, action = 'dispel', count = 5, msg = 'rips your buffs away!' },
                { hp = 26, action = 'fury',   att = 5500, haste = 160, msg = 'fights with renewed fury!' },
                { hp = 12, action = 'enrage', att = 7500, haste = 220, msg = 'goes berserk!' },
            },
        }
    elseif level >= 5 then
        return {
            name   = (level == 6) and 'Vrtra' or 'King Behemoth',
            enrage = { sec = 125, att = 6800, haste = 200, msg = 'intensifies its assault!' },
            stance = { startHpp = 75, periodSec = 10, stances = {
                { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'hide turns iron-hard -- try magic!' },
                { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'shrugs off magic -- use steel!' },
            } },
            cc     = { periodSec = 26, effect = xi.effect.TERROR, dur = 3, msg = 'looses a petrifying roar!' },
            drain  = { periodSec = 15, heal = level * 10000 },
            holdFire = C.holdFireCfg(level),
            phases = {
                { hp = 45, action = 'dispel', count = 4, msg = 'tears your buffs away!' },
                { hp = 18, action = 'fury',   att = 4500, haste = 150, msg = 'surges with sudden power!' },
            },
        }
    elseif level >= 3 then
        return {
            name   = (level == 4) and 'Nidhogg' or 'Simurgh',
            enrage = { sec = 140, att = 6000, haste = 180, msg = 'grows restless -- pressing harder!' },
            stance = { startHpp = 60, periodSec = 13, stances = {
                { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'scales over -- magic only!' },
                { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'wards itself -- steel only!' },
            } },
            cc     = { periodSec = (level == 4) and 35 or 20, effect = xi.effect.TERROR, dur = 5, msg = 'shrieks -- you freeze in fear!' },
            drain  = { periodSec = 15, heal = level * 10000 },
            holdFire = C.holdFireCfg(level),
            phases = {
                { hp = 40, action = 'dispel', count = 3, msg = 'strips your enhancements!' },
                { hp = 18, action = 'fury',   att = 4000, haste = 130, msg = 'enters a fury state!' },
            },
        }
    else
        -- Levels 1-2: entry pressure -- enrage, CC, dispel, and a fury phase.
        return {
            name   = (level == 2) and 'Serket' or 'Aquarius',
            enrage = { sec = 155, att = 5500, haste = 160, msg = 'grows impatient -- attacks quicken!' },
            cc     = { periodSec = 22, effect = xi.effect.TERROR, dur = 4, msg = 'looses a paralyzing screech!' },
            drain  = { periodSec = 15, heal = level * 10000 },
            holdFire = C.holdFireCfg(level),
            phases = {
                { hp = 45, action = 'dispel', count = 2, msg = 'tears at your buffs!' },
                { hp = 22, action = 'fury',   att = 3200, haste = 110, msg = 'thrashes in a frenzy!' },
            },
        }
    end
end

return C
