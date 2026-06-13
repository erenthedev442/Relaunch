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
--   * Ascension     : EVERY Provenance Altar AP category (from
--                     prestige_catalog.lua) with this job's purchased
--                     levels/cap -- iterates the catalog, so a category
--                     added at the Altar shows up here automatically
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
-- BOTH are SYSTEM channels (never a LINKSHELL channel) so this output is
-- never mistaken for the server's [Legendary] linkshell chat.
--   SYSTEM_3 (29) = yellow   -- section headers
--   SYSTEM_1 (6)  = default  -- body lines
local CH_BODY   = xi.msg.channel.SYSTEM_1
local CH_HEADER = xi.msg.channel.SYSTEM_3

-- Ascension (Provenance) catalog -- pcall so !mystats keeps working even if
-- the prestige module is ever renamed/removed.
local prestigeOk, prestige = pcall(require, 'modules/custom/lua/prestige_catalog')

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
    line(player, 'Dmg taken: All %g%%   Phys %g%%   Magic %g%%   Breath %g%%',
        player:getMod(xi.mod.DMG)      / 100,
        player:getMod(xi.mod.DMGPHYS)  / 100,
        player:getMod(xi.mod.DMGMAGIC) / 100,
        player:getMod(xi.mod.DMGBREATH) / 100)

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
    -- ALL_WSDMG_* are whole-% (engine: (100 + mod) / 100), so raw = %.
    -- SKILLCHAINDMG is 0.01%-units (engine: (10000 + mod) / 10000), so /100 for
    -- the real percent -- same scale trap as the Dmg-taken line above.
    line(player, 'WS dmg (all hits) +%d%%   WS dmg (1st hit) +%d%%   Skillchain dmg +%g%%',
        player:getMod(xi.mod.ALL_WSDMG_ALL_HITS),
        player:getMod(xi.mod.ALL_WSDMG_FIRST_HIT),
        player:getMod(xi.mod.SKILLCHAINDMG) / 100)

    -- =========================================================
    -- Every AP spend category from the Provenance Altar, with THIS main
    -- job's purchased levels (Ascension is per-job, like Job Points).
    -- Values are levels/cap -- the same units as the Altar's own menu;
    -- the resulting stat bonuses are already baked into the sections
    -- above. Iterates prestige_catalog.categories so a category added
    -- there appears here automatically -- no drift.
    if prestigeOk and prestige and prestige.categories then
        header(player, 'Ascension (Provenance)')
        line(player, 'Prestige Lv %d   AP unspent %d   (current main job)',
            player:getCharVar(string.format('Prestige_Level_%d', mJob)) or 0,
            player:getCharVar(string.format('Prestige_AP_%d', mJob)) or 0)
        local buf = {}
        for _, cat in ipairs(prestige.categories) do
            local lv = player:getCharVar(string.format('Prestige_Cat_%d_%s', mJob, cat.id)) or 0
            table.insert(buf, string.format('%s %d/%d', cat.label, lv, cat.cap))
            if #buf == 3 then
                line(player, '%s', table.concat(buf, '   '))
                buf = {}
            end
        end
        if #buf > 0 then
            line(player, '%s', table.concat(buf, '   '))
        end
    end

    player:printToPlayer(' ', CH_BODY)                       -- trailing spacer
    player:printToPlayer('>>> END OF STATS <<<', CH_HEADER)  -- matched footer
end

return commandObj
