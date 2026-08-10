 -----------------------------------
-- func: mystats
-- desc: Self-targeted dump of EVERY stat the player has, with equipment
--       and buff contributions baked into the totals. Single command,
--       no arguments, no cursor-target needed.
--
-- Usage:   !mystats 
--
-- Output is a multi-section snapshot:
--   * Header        : name / jobs / levels / HP / MP / TP
--   * Attributes    : STR DEX VIT AGI INT MND CHR (gear + buffs included)
--   * Offensive     : ATT, RATT, MATT, ACC, RACC, MACC + weapon dmg
--   * Crit / multihit: crit rate/dmg, magic crit, DA / TA / QA
--   * Defensive     : DEF, EVA, MDEF, MEVA + damage-taken modifiers
--   * Tempo / haste : Haste (gear/magic/ability), Dual Wield, Store TP,
--                     Fast Cast, Spell Intp Down (SIRD), Quick Magic
--   * Recovery      : Regen, Refresh, Regain, Cure Potency, Conv Healing
--   * Misc / niche  : Subtle Blow I+II, Enmity, Treasure Hunter, TP Bonus,
--                     WS dmg modifiers, Skillchain dmg
--   * Augment stats : every OTHER obtainable augment/gear stat (GAP_AUG),
--                     non-zero entries only -- ported from Legendary
--                     2026-07-12 (player request: Lant). Regenerate the
--                     table with tools/gen_mystats_aug_gaps.py.
--
-- Ascension / Rebirth readouts live in !checkascend and !checkrebirth
-- (extracted from here to reduce clutter, matching Legendary).
--
-- Equipment contribution is automatically rolled in because:
--   * getStat(mod) returns the FULL stat after equipment + buffs + job
--     traits + merits + JP gifts are summed by the engine.
--   * getMod(mod) returns the modifier total (equipment + buffs).
-- If you want to see *just* the gear contribution, take the gear off,
-- re-run !mystats, and diff the two outputs.
--
-- Lives in modules/custom/commands/ so it survives upstream merges.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

-- Output channels. Everything goes on SYSTEM_3 (29) = clean yellow text.
-- WHY: the old body channel SYSTEM_1 (6) makes the FFXI client stamp a
-- "----== SystemMessage ==----" banner above EVERY message, spamming a
-- separator line between every single stat row. SYSTEM_3 has no banner.
-- Kept as two names so the body could later take a *different* clean channel
-- for colour contrast -- but avoid SYSTEM_1/2 (banner) and SAY/LINKSHELL
-- channels (say-filter can hide it / looks like LS chat).
local CH_HEADER = xi.msg.channel.SYSTEM_3
local CH_BODY   = xi.msg.channel.SYSTEM_3

-- 2H weapon skill types, mirroring battleentity.cpp isTwoHanded() (same
-- table as scripts/commands/delay.lua). Needed because Hasso / Last Resort
-- style JA haste lands on TWOHAND_HASTE_ABILITY (mod 217), which the engine
-- folds into ability haste only while one of these is the main weapon.
local TWOHANDED_SKILLS =
{
    [xi.skill.GREAT_SWORD]  = true,
    [xi.skill.GREAT_AXE]    = true,
    [xi.skill.SCYTHE]       = true,
    [xi.skill.POLEARM]      = true,
    [xi.skill.GREAT_KATANA] = true,
    [xi.skill.STAFF]        = true,
}

-- Every obtainable-augment stat that NO section above already shows, so a player
-- can confirm EVERY augment they can get. Only NON-ZERO entries print (this keeps
-- it compact -- you see only the augment/gear extras you actually have). Each
-- pair is { modId, short label }. Generated from the relaunch augment catalog +
-- sql/augments.sql (+ modules/custom/sql augment rows) via
-- tools/gen_mystats_aug_gaps.py -- regenerate if the augment catalog changes.
-- Pet-only augment mods are omitted (the Pet section already totals those).
local GAP_AUG =
{
    { 48, 'WS Acc' },
    { 71, 'MPrecov.heal' },
    { 72, 'HPrecov.heal' },
    { 94, 'MeditateDur' },
    { 101, 'AutoMelee skl' },
    { 102, 'AutoRanged skl' },
    { 103, 'AutoMagic skl' },
    { 109, 'Shield skl' },
    { 110, 'Parry skl' },
    { 138, 'Barrage' },
    { 139, 'WaltzTP-' },
    { 166, 'EnemyCrit-' },
    { 173, 'Martial Arts' },
    { 250, 'Res.Slow' },
    { 252, 'Res.Charm' },
    { 273, 'CallBeast-' },
    { 292, 'Kick Atk' },
    { 296, 'ConserveMP' },
    { 305, 'Recycle' },
    { 306, 'Zanshin' },
    { 308, 'NinjaTool' },
    { 311, 'Magic Dmg' },
    { 315, 'Drain/Aspir' },
    { 346, 'AvatarPerp-' },
    { 357, 'BloodPact-' },
    { 359, 'Rapid Shot' },
    { 365, 'Snapshot' },
    { 391, 'Charm+' },
    { 452, 'AllSongs+' },
    { 455, 'SongCast-' },
    { 477, 'HelixDur' },
    { 485, 'ShieldMastery' },
    { 487, 'MBurst Dmg' },
    { 491, 'WaltzPot' },
    { 497, 'Waltz-' },
    { 518, 'BlockRate' },
    { 519, 'CureCast-' },
    { 540, 'ElemSiphon' },
    { 833, 'SongRecast-' },
    { 836, 'Rev.Flourish' },
    { 854, 'RepairPot' },
    { 880, 'Save TP' },
    { 890, 'EnhMagDur' },
    { 897, 'Gilfinder' },
    { 902, 'OccultAcumen' },
    { 911, 'Daken' },
    { 913, 'BloodBoon' },
    { 944, 'Conserve TP' },
    { 958, 'Occ.ResStatus' },
    { 960, 'IndiDur' },
    { 963, 'ParryRate' },
    { 989, 'RegenPot' },
    { 1052, 'Sic/Ready-' },
    { 1060, 'QuickDraw-' },
    { 1073, 'DarkSeal+' },
    { 1076, 'PhRoll-' },
    { 1146, 'ElemRecast-' },
    { 1182, 'PhalanxRcvd' },
    { 1183, 'CureRecast-' },
    { 1184, 'EnfbRecast-' },
    { 1185, 'EnhaRecast-' },
    { 1197, 'Immunobreak' },
}

local function line(player, fmt, ...)
    player:printToPlayer('  ' .. string.format(fmt, ...), CH_BODY)
end

local function header(player, title)
    -- Yellow chevrons + ALL CAPS + a blank-ish separator line above for
    -- visual breathing room. The leading newline-style spacer is sent as
    -- its own message so the client treats it as a separate row in the
    -- log -- printToPlayer collapses multi-line strings to one row.
    player:printToPlayer(' ', CH_BODY)                                  -- spacer
    player:printToPlayer('>>> ' .. title:upper() .. ' <<<', CH_HEADER)
end

-- Engine-enforced caps, sourced from src/map/utils/battleutils.cpp and
-- src/map/modifier.h. Format `cap` as the raw mod-units value that
-- getMod() returns (e.g. HASTE_GEAR returns 2500 at the 25% cap, where
-- 100 units = 1%). Where multiple sources of cap exist, the most-common
-- retail-style hard cap is listed.
local capped =
{
    HASTE_GEAR      = { cap = 2500, unit = '/100=%', note = '25%' },     -- battleutils:5991 clamp +/-2500
    HASTE_MAGIC     = { cap = 4375, unit = '/100=%', note = '43.75%' },  -- battleutils:5990 clamp +/-4375
    HASTE_ABILITY   = { cap = 2500, unit = '/100=%', note = '25%' },     -- typical retail ability cap
    FASTCAST        = { cap = 80,   unit = '%',      note = '80%' },     -- two-stage clamp, effective 80%
    CURE_POTENCY    = { cap = 50,   unit = '%',      note = '50%' },     -- modifier.h:890 gear cap
    CURE_POTENCY_II = { cap = 30,   unit = '%',      note = '30%' },     -- modifier.h:891 gear cap
    SUBTLE_BLOW     = { cap = 50,   unit = '%',      note = '50%' },     -- modifier.h:1114 cap 50%
    SUBTLE_BLOW_II  = { cap = 50,   unit = '%',      note = '50% / 75% combined w/ SB' },
}

-- Format a mod value as `current/cap` if the stat has a known cap,
-- otherwise just the bare value. Returns a plain string.
local function vcap(player, modName)
    local cur = player:getMod(xi.mod[modName])
    local c   = capped[modName]
    if c then
        return string.format('%d/%d', cur, c.cap)
    end
    return tostring(cur)
end

commandObj.onTrigger = function(player)
    -- Resolve job names instead of just numeric IDs. xi.job is a flat
    -- key->id table, so we invert it once for ID -> name lookup.
    local jobName = {}
    for k, v in pairs(xi.job) do
        jobName[v] = k
    end

    local mJob = player:getMainJob()
    local sJob = player:getSubJob()

    -- =========================================================
    header(player, string.format('%s\'s Stats', player:getName()))
    line(player, 'Job: %s%d / %s%d   HP: %d/%d   MP: %d/%d   TP: %d',
        jobName[mJob] or '?', player:getMainLvl(),
        jobName[sJob] or '?', player:getSubLvl(),
        player:getHP(), player:getMaxHP(),
        player:getMP(), player:getMaxMP(),
        player:getTP())

    -- =========================================================
    header(player, 'Attributes (incl. gear + buffs)')
    line(player, 'STR %3d   DEX %3d   VIT %3d   AGI %3d',
        player:getStat(xi.mod.STR), player:getStat(xi.mod.DEX),
        player:getStat(xi.mod.VIT), player:getStat(xi.mod.AGI))
    line(player, 'INT %3d   MND %3d   CHR %3d',
        player:getStat(xi.mod.INT), player:getStat(xi.mod.MND),
        player:getStat(xi.mod.CHR))

    -- =========================================================
    header(player, 'Offensive')
    line(player, 'Melee   ATT %4d   ACC %4d   Wpn dmg %d',
        player:getStat(xi.mod.ATT), player:getStat(xi.mod.ACC),
        player:getWeaponDmg())
    line(player, 'Ranged  ATT %4d   ACC %4d   Wpn dmg %d',
        player:getStat(xi.mod.RATT), player:getStat(xi.mod.RACC),
        player:getRangedDmg())
    line(player, 'Magic   MATT %3d   MACC %3d',
        player:getMod(xi.mod.MATT), player:getMod(xi.mod.MACC))
    -- Physical Damage Limit (PDL). DAMAGE_LIMITP (1081) is the retail "Physical
    -- damage limit +X%" gear/song/aftermath stat, stored AS the percent (Aria
    -- +20% = mod 20; aftermath +6/9/12% = mod 6/9/12; the engine uses 1 + mod/100
    -- in scripts/globals/combat/physical_utilities.lua:642) -- so show it RAW, do
    -- NOT /100 (the modifier.h header comment's /100 formula is stale for the Lua
    -- path). DAMAGE_LIMIT (1080) is the rarer FLAT max-pDIF add from traits (engine
    -- uses mod/100). Requested by phatdood.
    line(player, 'Phys. Dmg Limit (PDL) +%d%%   flat DL +%g',
        player:getMod(xi.mod.DAMAGE_LIMITP),
        player:getMod(xi.mod.DAMAGE_LIMIT) / 100)

    -- =========================================================
    header(player, 'Crit / Multihit')
    line(player, 'Crit hit rate %d%%   Crit dmg +%d%%',
        player:getMod(xi.mod.CRITHITRATE),
        player:getMod(xi.mod.CRIT_DMG_INCREASE))
    line(player, 'Magic crit rate %d%%   Magic crit dmg +%d%%',
        player:getMod(xi.mod.MAGIC_CRITHITRATE),
        player:getMod(xi.mod.MAGIC_CRIT_DMG_INCREASE))
    line(player, 'Dbl Atk %d%%   Trpl Atk %d%%   Quad Atk %d%%',
        player:getMod(xi.mod.DOUBLE_ATTACK),
        player:getMod(xi.mod.TRIPLE_ATTACK),
        player:getMod(xi.mod.QUAD_ATTACK))

    -- =========================================================
    header(player, 'Defensive')
    line(player, 'DEF %4d   EVA %4d   MDEF %3d   MEVA %3d',
        player:getStat(xi.mod.DEF), player:getStat(xi.mod.EVA),
        player:getMod(xi.mod.MDEF), player:getMod(xi.mod.MEVA))
    -- DT mods are in 0.01% units (raw 1500 = 15%), same scale as the haste mods
    -- below -- so divide by 100 for the real percent. (%g keeps it clean for
    -- whole and fractional values: -1500 -> -15%, -240 -> -2.4%.)
    -- Tier-I DT (matches the 'Phys DT' / 'Magic DT' augments) -- all share the
    -- single -50% Damage Taken cap.
    line(player, 'Dmg taken (cap -50%%): All %g%%   Phys %g%%   Magic %g%%   Breath %g%%',
        player:getMod(xi.mod.DMG)      / 100,
        player:getMod(xi.mod.DMGPHYS)  / 100,
        player:getMod(xi.mod.DMGMAGIC) / 100,
        player:getMod(xi.mod.DMGBREATH) / 100)

    -- "II" damage-taken (DMGPHYS_II 190 / DMGMAGIC_II 831 -- Aegis/Burtgang/relic gear):
    -- these BYPASS the -50% regular DT cap (combined II cap is -87.5%) and the engine
    -- DOES apply them (damage_multipliers.lua) -- they were just never read here,
    -- so they looked "not applied". Shown only when present (no clutter for everyone else).
    local physDtII  = player:getMod(xi.mod.DMGPHYS_II)
    local magicDtII = player:getMod(xi.mod.DMGMAGIC_II)
    if physDtII ~= 0 or magicDtII ~= 0 then
        line(player, 'Dmg taken II: Phys %g%%   Magic %g%%  (bypasses cap, to -87.5%%)',
            physDtII / 100, magicDtII / 100)
    end

    -- =========================================================
    -- Elemental resistances. Read by numeric mod id 15-22 (Fire, Ice, Wind,
    -- Earth, Lightning, Water, Light, Dark -- the standard FFXI element order).
    -- Confirmed against sql/augments.sql: "Fire resist" = mod 15 ... "Dark
    -- resist" = mod 22. These are the additive resist values from gear, augments
    -- (incl. the "All elemental resists +10" augment), and buffs -- higher means
    -- more resistant. Read by id because xi.mod has no stable Lua alias for these
    -- on this build, and the engine applies them by id regardless.
    header(player, 'Elemental Resists')
    line(player, 'Fire %3d   Ice %3d   Wind %3d   Earth %3d',
        player:getMod(15), player:getMod(16), player:getMod(17), player:getMod(18))
    line(player, 'Thunder %3d   Water %3d   Light %3d   Dark %3d',
        player:getMod(19), player:getMod(20), player:getMod(21), player:getMod(22))

    -- =========================================================
    -- Elemental affinities -- THREE flavors, ALL labelled "Fire/Wind Affinity"
    -- in-game but stored on different mods, so we list all three:
    --   * Magic Atk Bonus (FIRE_MAB 32 .. DARK_MAB 39) -- gear "Fire Affinity:
    --     Magic Atk. Bonus +X".
    --   * Affinity Dmg (FIRE_AFFINITY_DMG 347 .. DARK 354) -- +5% elemental
    --     magic dmg per level (what affinity-style augments grant).
    --   * Affinity M.Acc (FIRE_AFFINITY_ACC 544 .. DARK 551) -- +10 magic acc
    --     per level, granted alongside those augments.
    -- The Dmg/Acc mods have NO xi.mod alias on this build, so read by numeric id
    -- (like the resists section). Ported from Legendary 2026-07-12 -- only the
    -- MAB flavor was shown before, so affinity augments read as 0 here.
    header(player, 'Elemental Affinities')
    line(player, 'Magic Atk Bonus:  Fire %d  Ice %d  Wind %d  Earth %d  Thunder %d  Water %d  Light %d  Dark %d',
        player:getMod(xi.mod.FIRE_MAB),    player:getMod(xi.mod.ICE_MAB),
        player:getMod(xi.mod.WIND_MAB),    player:getMod(xi.mod.EARTH_MAB),
        player:getMod(xi.mod.THUNDER_MAB), player:getMod(xi.mod.WATER_MAB),
        player:getMod(xi.mod.LIGHT_MAB),   player:getMod(xi.mod.DARK_MAB))
    line(player, 'Affinity Dmg (+5%%/lvl):  Fire %d  Ice %d  Wind %d  Earth %d  Thunder %d  Water %d  Light %d  Dark %d',
        player:getMod(347), player:getMod(348), player:getMod(349), player:getMod(350),
        player:getMod(351), player:getMod(352), player:getMod(353), player:getMod(354))
    line(player, 'Affinity M.Acc (+10/lvl):  Fire %d  Ice %d  Wind %d  Earth %d  Thunder %d  Water %d  Light %d  Dark %d',
        player:getMod(544), player:getMod(545), player:getMod(546), player:getMod(547),
        player:getMod(548), player:getMod(549), player:getMod(550), player:getMod(551))

    -- BLU chain/burst affinity enhancers (job-specific but shown for BLU only)
    if mJob == xi.job.BLU then
        line(player, 'Burst Affinity WSC +%d%%   Chain Affinity base dmg +%d',
            player:getMod(xi.mod.ENHANCES_BURST_AFFINITY),
            player:getMod(xi.mod.ENHANCES_CHAIN_AFFINITY))
    end

    -- =========================================================
    header(player, 'Tempo / Haste / Casting')
    -- Haste mods are in 0.01% units, so the raw value 2500 = 25%. The
    -- caps shown here are engine clamps from battleutils.cpp:5990-5991.
    -- Hasso / Last Resort put their JA haste on TWOHAND_HASTE_ABILITY
    -- (mod 217), which battleentity.cpp folds into ability haste only while
    -- a 2H main weapon is equipped -- without this fold the line reads
    -- "Haste-Ability 0" on SAM with Hasso up (Legendary bugfix, ported).
    local jaHaste = player:getMod(xi.mod.HASTE_ABILITY)
    if TWOHANDED_SKILLS[player:getWeaponSkillType(xi.slot.MAIN)] then
        jaHaste = jaHaste + player:getMod(xi.mod.TWOHAND_HASTE_ABILITY)
    end
    line(player, 'Haste-Gear %s   Haste-Magic %s   Haste-Ability %d/%d   (1%% = 100)',
        vcap(player, 'HASTE_GEAR'),
        vcap(player, 'HASTE_MAGIC'),
        jaHaste,
        capped.HASTE_ABILITY.cap)
    line(player, 'Dual Wield %d%%   Store TP %d   TP Bonus +%d',
        player:getMod(xi.mod.DUAL_WIELD),
        player:getMod(xi.mod.STORETP),
        player:getMod(xi.mod.TP_BONUS))
    line(player, 'Fast Cast %s%%   Quick Magic %d%%   Spell Intp Down %d%%',
        vcap(player, 'FASTCAST'),
        player:getMod(xi.mod.QUICK_MAGIC),
        player:getMod(xi.mod.SPELLINTERRUPT))

    -- =========================================================
    header(player, 'Recovery')
    line(player, 'Regen %d   Refresh %d   Regain %d',
        player:getMod(xi.mod.REGEN),
        player:getMod(xi.mod.REFRESH),
        player:getMod(xi.mod.REGAIN))
    line(player, 'Cure Potency I %s%%   Cure Potency II %s%%   Cure Pot. Rcvd %d%%',
        vcap(player, 'CURE_POTENCY'),
        vcap(player, 'CURE_POTENCY_II'),
        player:getMod(xi.mod.CURE_POTENCY_RCVD))

    -- =========================================================
    header(player, 'Bonus EXP / Capacity from gear+buffs')
    -- EXP_BONUS (mod 382) and CAPACITY_BONUS (mod 915) are the engine's
    -- "extra rate" mods aggregated from gear, food, atmas, and buff effects.
    -- NOTE: the Augment Moogle's "Exp. Point +33%" (augId 73) writes to
    -- modId=0 (engine-special) and does NOT show up in EXP_BONUS. The
    -- "Cap. Point +33%" (augId 75) DOES show up here because it uses
    -- mod 915. See modules/custom/lua/augment_catalog.lua for the
    -- progression-augment entries we added.
    line(player, 'EXP Bonus +%d%%   Capacity Bonus +%d%%',
        player:getMod(xi.mod.EXP_BONUS),
        player:getMod(xi.mod.CAPACITY_BONUS))
    -- Dedication (EXP: Happy Hour / EXP rings) and Commitment (CP: Happy Hour /
    -- capacity rings) are status-effect PAYOUTS, not mods -- they never appear
    -- in the mod totals above, so read the effects directly. subPower = bonus
    -- points still to be paid before the effect expires. Requested by Lant.
    local dedication = player:getStatusEffect(xi.effect.DEDICATION)
    if dedication then
        line(player, 'Dedication (EXP buff) +%d%%   %d bonus pts left',
            dedication:getPower(), dedication:getSubPower())
    end
    local commitment = player:getStatusEffect(xi.effect.COMMITMENT)
    if commitment then
        line(player, 'Commitment (CP buff) +%d%%   %d bonus pts left',
            commitment:getPower(), commitment:getSubPower())
    end

    -- =========================================================
    header(player, 'Misc / Niche')
    line(player, 'Enmity %d   Subtle Blow %s   Subtle Blow II %s   Counter %d%%',
        player:getMod(xi.mod.ENMITY),
        vcap(player, 'SUBTLE_BLOW'),
        vcap(player, 'SUBTLE_BLOW_II'),
        player:getMod(xi.mod.COUNTER))
    -- No single "all combat skill" engine mod -- skill+ is per-skill in
    -- LSB (MOD_SWORD, MOD_DAGGER, etc.), so showing one number would be
    -- misleading. Treasure Hunter stands alone here.
    line(player, 'Treasure Hunter %d',
        player:getMod(xi.mod.TREASURE_HUNTER))
    -- ALL_WSDMG_* are whole-% (engine: (100 + mod) / 100), so raw = %.
    -- SKILLCHAINDMG is 0.01%-units (engine: (10000 + mod) / 10000), so /100 for
    -- the real percent -- same scale trap as the Dmg-taken line above.
    line(player, 'WS dmg (all hits) +%d%%   WS dmg (1st hit) +%d%%   Skillchain dmg +%g%%',
        player:getMod(xi.mod.ALL_WSDMG_ALL_HITS),
        player:getMod(xi.mod.ALL_WSDMG_FIRST_HIT),
        player:getMod(xi.mod.SKILLCHAINDMG) / 100)
    -- Enspell damage. ENSPELL_DMG (343) = base dmg of the ACTIVE enspell, set
    -- by the enspell effect itself, so it reads 0 with no enspell up; cast one
    -- (e.g. Enfire) and re-run to see it populate. ENSPELL_DMG_BONUS (432) =
    -- flat add to that base from gear/traits; ENSPELL_DMG_PCT (1195) = % mult
    -- applied to enspell dmg from gear/traits. Both bonus mods show regardless.
    line(player, 'Enspell: base dmg %d   +dmg %d   dmg mult +%d%%',
        player:getMod(xi.mod.ENSPELL_DMG),
        player:getMod(xi.mod.ENSPELL_DMG_BONUS),
        player:getMod(xi.mod.ENSPELL_DMG_PCT))
    -- Spikes damage. SPIKES_DMG (344) = flat base of the ACTIVE spike (the spell's
    -- own value + the 'Spikes Dmg' augment, which adds to this mod), so it reads 0
    -- with no spike up; cast Blaze/Ice/Shock Spikes to see it populate. SPIKES_DMG_BONUS
    -- (1079) = % bonus. Spikes ignore Magic Atk / elemental affinity -- these two
    -- mods are the ONLY things that move spike damage.
    line(player, 'Spikes: base dmg %d   dmg bonus +%d%%',
        player:getMod(xi.mod.SPIKES_DMG),
        player:getMod(xi.mod.SPIKES_DMG_BONUS))

    -- =========================================================
    -- Augment coverage: every obtainable-augment stat that ISN'T surfaced in a
    -- section above (status resists, weapon/magic skills, Martial Arts, Save TP,
    -- Conserve TP, Barrage, Blood Boon, etc.). Only non-zero values print, so
    -- this stays a few lines even though GAP_AUG is long -- you see only the
    -- augment/gear extras you actually have. (Skill rows show the gear/augment
    -- SKILL BONUS, not the total skill -- 0 if none.)
    header(player, 'Augment Stats (your non-zero augment/gear extras)')
    local abuf, anyAug = {}, false
    for _, e in ipairs(GAP_AUG) do
        local v = player:getMod(e[1])
        if v ~= 0 then
            anyAug = true
            abuf[#abuf + 1] = string.format('%s %d', e[2], v)
            if #abuf == 4 then
                line(player, '%s', table.concat(abuf, '   '))
                abuf = {}
            end
        end
    end
    if #abuf > 0 then
        line(player, '%s', table.concat(abuf, '   '))
    end
    if not anyAug then
        line(player, '(none active -- augment-only stats appear here once you have them)')
    end

    -- =========================================================
    -- Pet readout for ANY pet job: Automaton (PUP), Avatar (SMN), Jug/Charmed
    -- pet (BST), or Wyvern (DRG). The pet's level + combat stats live on the PET
    -- entity (not the master), so it must be out first. getStat(mod) = the full
    -- post-gear/buff value the engine fights with; getMainLvl() = the pet's REAL
    -- level (a BST jug's level can differ from your BST level; an avatar/wyvern
    -- matches your level). PUP also shows the 3 automaton combat skills; SMN
    -- shows your Summoning skill (drives blood-pact accuracy/potency).
    -- =========================================================
    local PET_JOBS =
    {
        [xi.job.PUP] = { label = 'Automaton (Pet)',   summon = 'Deploy (or !pup)'    },
        [xi.job.SMN] = { label = 'Avatar (Pet)',      summon = 'summon an avatar'    },
        [xi.job.BST] = { label = 'Jug / Charmed Pet', summon = 'Call Beast or Charm' },
        [xi.job.DRG] = { label = 'Wyvern (Pet)',      summon = 'Call Wyvern'         },
    }
    local petCfg = PET_JOBS[mJob]
    if petCfg then
        header(player, petCfg.label)
        local pet = player:getPet()
        if pet == nil then
            line(player, 'No pet out -- %s, then re-run !mystats.', petCfg.summon)
        else
            line(player, '%s   Lv %d   HP %d/%d   TP %d',
                pet:getName(), pet:getMainLvl(), pet:getHP(), pet:getMaxHP(), pet:getTP())
            -- Per-job "power source" line.
            if mJob == xi.job.PUP then
                line(player, 'Skills:   Melee %d   Ranged %d   Magic %d',
                    pet:getSkillLevel(xi.skill.AUTOMATON_MELEE),
                    pet:getSkillLevel(xi.skill.AUTOMATON_RANGED),
                    pet:getSkillLevel(xi.skill.AUTOMATON_MAGIC))
            elseif mJob == xi.job.SMN then
                line(player, 'Summoning skill: %d   (drives blood-pact acc/potency)',
                    player:getSkillLevel(xi.skill.SUMMONING_MAGIC))
                -- Perpetuation-cost reduction affinities (FIRE_AFFINITY_PERP 553..560)
                line(player, 'Perp cost: Fire %d  Ice %d  Wind %d  Earth %d  Thunder %d  Water %d  Light %d  Dark %d',
                    player:getMod(xi.mod.FIRE_AFFINITY_PERP),   player:getMod(xi.mod.ICE_AFFINITY_PERP),
                    player:getMod(xi.mod.WIND_AFFINITY_PERP),   player:getMod(xi.mod.EARTH_AFFINITY_PERP),
                    player:getMod(xi.mod.THUNDER_AFFINITY_PERP), player:getMod(xi.mod.WATER_AFFINITY_PERP),
                    player:getMod(xi.mod.LIGHT_AFFINITY_PERP),  player:getMod(xi.mod.DARK_AFFINITY_PERP))
            end
            line(player, 'Offense:  ATT %4d   ACC %4d   RATT %4d   RACC %4d',
                pet:getStat(xi.mod.ATT), pet:getStat(xi.mod.ACC),
                pet:getStat(xi.mod.RATT), pet:getStat(xi.mod.RACC))
            line(player, 'Magic:    MATT %3d   MACC %3d   Magic Haste %d',
                pet:getMod(xi.mod.MATT), pet:getMod(xi.mod.MACC),
                pet:getMod(xi.mod.HASTE_MAGIC))
            line(player, 'Defense:  DEF %4d   EVA %4d   MDEF %3d   MEVA %3d',
                pet:getStat(xi.mod.DEF), pet:getStat(xi.mod.EVA),
                pet:getMod(xi.mod.MDEF), pet:getMod(xi.mod.MEVA))
        end
    end

    player:printToPlayer(' ', CH_BODY)                       -- trailing spacer
    player:printToPlayer('>>> END OF STATS <<<', CH_HEADER)  -- matched footer
    -- Ascension/Rebirth readouts were extracted to their own commands
    -- 2026-07-12 (matching Legendary) to keep this dump focused on stats.
    player:printToPlayer('  Tip: !checkascend for Ascension boosts | !checkrebirth for Rebirth stats', CH_BODY)
end

return commandObj
