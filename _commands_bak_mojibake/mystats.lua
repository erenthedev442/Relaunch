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
--                     Fast Cast, Spell Interrupt, Quick Magic
--   * Recovery      : Regen, Refresh, Regain, Cure Potency, Conv Healing
--   * Misc / niche  : Subtle Blow I+II, Enmity, Treasure Hunter, TP Bonus,
--                     WS dmg modifiers, Skillchain dmg
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

-- Color channels for visual contrast. FFXI client renders each chat
-- channel in a distinct color, so we send headers and body to different
-- channels rather than trying to embed escape codes (no native bold).
--   SYSTEM_3   (29) = yellow      -- body lines, the default "system" color
--   LINKSHELL2 (27) = green       -- section headers, pops against yellow
local CH_BODY   = xi.msg.channel.SYSTEM_3
local CH_HEADER = xi.msg.channel.LINKSHELL2

local function line(player, fmt, ...)
    player:printToPlayer('  ' .. string.format(fmt, ...), CH_BODY)
end

local function header(player, title)
    -- Green chevrons + ALL CAPS + a blank-ish separator line above for
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
    HASTE_GEAR      = { cap = 2500, unit = '/100=%', note = '25%' },     -- battleutils:5991 clamp ±2500
    HASTE_MAGIC     = { cap = 4375, unit = '/100=%', note = '43.75%' },  -- battleutils:5990 clamp ±4375
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
    line(player, 'Dmg taken: All %d%%   Phys %d%%   Magic %d%%   Breath %d%%',
        player:getMod(xi.mod.DMG),
        player:getMod(xi.mod.DMGPHYS),
        player:getMod(xi.mod.DMGMAGIC),
        player:getMod(xi.mod.DMGBREATH))

    -- =========================================================
    header(player, 'Tempo / Haste / Casting')
    -- Haste mods are in 0.01% units, so the raw value 2500 = 25%. The
    -- caps shown here are engine clamps from battleutils.cpp:5990-5991.
    line(player, 'Haste-Gear %s   Haste-Magic %s   Haste-Ability %s   (1%% = 100)',
        vcap(player, 'HASTE_GEAR'),
        vcap(player, 'HASTE_MAGIC'),
        vcap(player, 'HASTE_ABILITY'))
    line(player, 'Dual Wield %d%%   Store TP %d   TP Bonus +%d',
        player:getMod(xi.mod.DUAL_WIELD),
        player:getMod(xi.mod.STORETP),
        player:getMod(xi.mod.TP_BONUS))
    line(player, 'Fast Cast %s%%   Quick Magic %d%%   Spell Interrupt %d%%',
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
    line(player, 'WS dmg (all hits) +%d%%   WS dmg (1st hit) +%d%%   Skillchain dmg +%d%%',
        player:getMod(xi.mod.ALL_WSDMG_ALL_HITS),
        player:getMod(xi.mod.ALL_WSDMG_FIRST_HIT),
        player:getMod(xi.mod.SKILLCHAINDMG))

    player:printToPlayer(' ', CH_BODY)                       -- trailing spacer
    player:printToPlayer('>>> END OF STATS <<<', CH_HEADER)  -- matched footer
end

return commandObj
