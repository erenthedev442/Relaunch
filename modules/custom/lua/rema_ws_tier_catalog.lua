-----------------------------------
-- Legendary REMA native-weaponskill enhancement catalog
--
-- Only final 119 III Relic, Empyrean and Mythic weapons, plus final Aeonic
-- weapons, are listed here. Prime weapons are deliberately absent.
--
-- PRIME_EQUIVALENT_BONUS is a Legendary balancing benchmark, not a value read
-- from the separate Prime implementation. A value of 2.00 means +200% over the
-- ordinary weaponskill baseline before the family tier and per-WS tuning are
-- applied.
-----------------------------------

local catalog = {}

catalog.PRIME_EQUIVALENT_BONUS = 2.00

catalog.REMA_TIER_SCALE =
{
    RELIC    = 0.50,
    EMPYREAN = 0.60,
    MYTHIC   = 0.70,
    AEONIC   = 0.80,
}

-- Family-wide progression applied after each native WS's individual fTP
-- calibration below.  The ratios mirror the intended endgame bands on the
-- Visions training target: Relic 200-300k, Empyrean/Mythic 300-500k and
-- Aeonic 600-700k with an appropriately geared player.
--
-- fTP remains the primary tier multiplier so attributes, attack/MAB and
-- player WS-damage augments continue to scale the complete result. Physical
-- and ranged WSs also receive TP-scaled attack, accuracy and partial defense
-- relief for consistency against endgame defensive profiles. Magical WSs use
-- fTP, the existing family WS-damage bonus and a family magic-accuracy boost,
-- preserving their native MAB, attributes, affinity and resistance path.
catalog.REMA_FAMILY_TUNING =
{
    RELIC =
    {
        targetDamage   = { 200000, 300000 },
        ftpScale       = 2.00,
        attackScale    = { 1.10, 1.20, 1.30 },
        accuracyBonus  = { 100, 150, 200 },
        magicAccBonus  = 150,
        ignoredDefense = { 0.25, 0.40, 0.50 },
    },
    EMPYREAN =
    {
        targetDamage   = { 300000, 500000 },
        ftpScale       = 2.75,
        attackScale    = { 1.20, 1.35, 1.50 },
        accuracyBonus  = { 150, 200, 250 },
        magicAccBonus  = 225,
        ignoredDefense = { 0.35, 0.55, 0.70 },
    },
    MYTHIC =
    {
        targetDamage   = { 300000, 500000 },
        ftpScale       = 2.75,
        attackScale    = { 1.20, 1.35, 1.50 },
        accuracyBonus  = { 150, 200, 250 },
        magicAccBonus  = 225,
        ignoredDefense = { 0.35, 0.55, 0.70 },
    },
    AEONIC =
    {
        targetDamage   = { 600000, 700000 },
        ftpScale       = 4.00,
        attackScale    = { 1.35, 1.55, 1.75 },
        accuracyBonus  = { 200, 275, 350 },
        magicAccBonus  = 300,
        ignoredDefense = { 0.50, 0.70, 0.82 },
    },
}

-- Beta fTP tuning.  Every enabled native WS has an explicit, independently
-- adjustable scale.  The runtime applies this to a private copy of ftpMod,
-- preserving the native hit count, damage path, crit rules and utility.
catalog.REMA_WS_TUNING =
{
    -- Relic
    [xi.weaponskill.FINAL_HEAVEN]     = 12.10,
    [xi.weaponskill.MERCY_STROKE]     = 15.00,
    [xi.weaponskill.KNIGHTS_OF_ROUND] = 7.90,
    [xi.weaponskill.SCOURGE]          = 10.50,
    [xi.weaponskill.ONSLAUGHT]        = 14.40,
    [xi.weaponskill.METATRON_TORMENT] = 8.70,
    [xi.weaponskill.CATASTROPHE]      = 8.60,
    [xi.weaponskill.GEIRSKOGUL]       = 8.20,
    [xi.weaponskill.BLADE_METSU]      = 5.00,
    [xi.weaponskill.TACHI_KAITEN]     = 8.30,
    [xi.weaponskill.RANDGRITH]        = 11.60,
    [xi.weaponskill.GATE_OF_TARTARUS] = 8.60,
    [xi.weaponskill.NAMAS_ARROW]      = 3.10,
    [xi.weaponskill.CORONACH]         = 2.60,

    -- Empyrean
    [xi.weaponskill.VICTORY_SMITE]    = 7.20,
    [xi.weaponskill.RUDRAS_STORM]     = 3.50,
    [xi.weaponskill.CHANT_DU_CYGNE]   = 5.90,
    [xi.weaponskill.TORCLEAVER]       = 4.50,
    [xi.weaponskill.CLOUDSPLITTER]    = 5.40,
    [xi.weaponskill.UKKOS_FURY]       = 13.30,
    [xi.weaponskill.QUIETUS]          = 9.00,
    [xi.weaponskill.CAMLANNS_TORMENT] = 7.00,
    [xi.weaponskill.BLADE_HI]         = 5.70,
    [xi.weaponskill.TACHI_FUDO]       = 3.60,
    [xi.weaponskill.JISHNUS_RADIANCE] = 1.90,
    [xi.weaponskill.WILDFIRE]         = 2.40,

    -- Mythic
    [xi.weaponskill.ASCETICS_FURY]    = 24.00,
    [xi.weaponskill.STRINGING_PUMMEL] = 57.33,
    [xi.weaponskill.MANDALIC_STAB]    = 6.00,
    [xi.weaponskill.MORDANT_RIME]     = 9.90,
    [xi.weaponskill.PYRRHIC_KLEOS]    = 7.20,
    [xi.weaponskill.DEATH_BLOSSOM]    = 40.00,
    [xi.weaponskill.EXPIACION]        = 20.00,
    [xi.weaponskill.KINGS_JUSTICE]    = 19.33,
    [xi.weaponskill.PRIMAL_REND]      = 6.80,
    [xi.weaponskill.INSURGENCY]       = 27.60,
    [xi.weaponskill.DRAKESBANE]       = 30.00,
    [xi.weaponskill.BLADE_KAMU]       = 20.00,
    [xi.weaponskill.TACHI_RANA]       = 30.00,
    [xi.weaponskill.MYSTIC_BOON]      = 5.90,
    [xi.weaponskill.VIDOHUNIR]        = 19.20,
    [xi.weaponskill.GARLAND_OF_BLISS] = 14.90,
    [xi.weaponskill.OMNISCIENCE]      = 16.80,
    [xi.weaponskill.TRUEFLIGHT]        = 1.55,
    [xi.weaponskill.LEADEN_SALUTE]     = 1.50,

    -- Aeonic
    [xi.weaponskill.SHIJIN_SPIRAL] = 7.10,
    [xi.weaponskill.EXENTERATOR]   = 11.80,
    [xi.weaponskill.REQUIESCAT]    = 16.50,
    [xi.weaponskill.DIMIDIATION]   = 8.20,
    [xi.weaponskill.RUINATOR]      = 13.10,
    [xi.weaponskill.UPHEAVAL]      = 4.80,
    [xi.weaponskill.ENTROPY]       = 4.20,
    [xi.weaponskill.STARDIVER]     = 5.00,
    [xi.weaponskill.BLADE_SHUN]    = 3.50,
    [xi.weaponskill.TACHI_SHOHA]   = 9.30,
    [xi.weaponskill.BLACK_HALO]     = 8.30,
    [xi.weaponskill.SHATTERSOUL]    = 18.00,
    [xi.weaponskill.APEX_ARROW]    = 4.00,
    [xi.weaponskill.LAST_STAND]    = 2.05,
}

local function weapon(itemId, name, family, wsId, slot, options)
    options = options or {}

    return
    {
        itemId  = itemId,
        name    = name,
        family  = family,
        wsId    = wsId,
        slot    = slot,
        enabled = options.enabled ~= false,
        reason  = options.reason,
        magic   = options.magic == true,
    }
end

catalog.WEAPONS =
{
    -- Relic 119 III
    weapon(20509, 'Spharai',       'RELIC', xi.weaponskill.FINAL_HEAVEN,     xi.slot.MAIN),
    weapon(20583, 'Mandau',        'RELIC', xi.weaponskill.MERCY_STROKE,     xi.slot.MAIN),
    weapon(20685, 'Excalibur',     'RELIC', xi.weaponskill.KNIGHTS_OF_ROUND, xi.slot.MAIN),
    weapon(21683, 'Ragnarok',      'RELIC', xi.weaponskill.SCOURGE,          xi.slot.MAIN),
    weapon(21750, 'Guttler',       'RELIC', xi.weaponskill.ONSLAUGHT,        xi.slot.MAIN),
    weapon(21756, 'Bravura',       'RELIC', xi.weaponskill.METATRON_TORMENT, xi.slot.MAIN),
    weapon(21808, 'Apocalypse',    'RELIC', xi.weaponskill.CATASTROPHE,      xi.slot.MAIN),
    weapon(21857, 'Gungnir',       'RELIC', xi.weaponskill.GEIRSKOGUL,       xi.slot.MAIN),
    weapon(21906, 'Kikoku',        'RELIC', xi.weaponskill.BLADE_METSU,      xi.slot.MAIN),
    weapon(21954, 'Amanomurakumo', 'RELIC', xi.weaponskill.TACHI_KAITEN,     xi.slot.MAIN),
    weapon(21077, 'Mjollnir',      'RELIC', xi.weaponskill.RANDGRITH,        xi.slot.MAIN),
    weapon(22060, 'Claustrum',     'RELIC', xi.weaponskill.GATE_OF_TARTARUS, xi.slot.MAIN),
    weapon(22129, 'Yoichinoyumi',  'RELIC', xi.weaponskill.NAMAS_ARROW,      xi.slot.RANGED),
    weapon(22140, 'Annihilator',   'RELIC', xi.weaponskill.CORONACH,         xi.slot.RANGED),

    -- Empyrean 119 III
    weapon(20512, 'Verethragna', 'EMPYREAN', xi.weaponskill.VICTORY_SMITE,    xi.slot.MAIN),
    weapon(20587, 'Twashtar',     'EMPYREAN', xi.weaponskill.RUDRAS_STORM,     xi.slot.MAIN),
    weapon(20689, 'Almace',       'EMPYREAN', xi.weaponskill.CHANT_DU_CYGNE,   xi.slot.MAIN),
    weapon(21684, 'Caladbolg',    'EMPYREAN', xi.weaponskill.TORCLEAVER,       xi.slot.MAIN),
    weapon(21752, 'Farsha',       'EMPYREAN', xi.weaponskill.CLOUDSPLITTER,    xi.slot.MAIN,
        { magic = true }),
    weapon(21758, 'Ukonvasara',   'EMPYREAN', xi.weaponskill.UKKOS_FURY,       xi.slot.MAIN),
    weapon(21810, 'Redemption',   'EMPYREAN', xi.weaponskill.QUIETUS,          xi.slot.MAIN),
    weapon(21859, 'Rhongomiant',  'EMPYREAN', xi.weaponskill.CAMLANNS_TORMENT, xi.slot.MAIN),
    weapon(21908, 'Kannagi',      'EMPYREAN', xi.weaponskill.BLADE_HI,         xi.slot.MAIN),
    weapon(21956, 'Masamune',     'EMPYREAN', xi.weaponskill.TACHI_FUDO,       xi.slot.MAIN),
    weapon(21079, 'Gambanteinn',  'EMPYREAN', xi.weaponskill.DAGAN,             xi.slot.MAIN,
        { enabled = false, reason = 'non-damage weaponskill' }),
    weapon(22064, 'Hvergelmir',   'EMPYREAN', xi.weaponskill.MYRKR,             xi.slot.MAIN,
        { enabled = false, reason = 'non-damage weaponskill' }),
    weapon(22130, 'Gandiva',      'EMPYREAN', xi.weaponskill.JISHNUS_RADIANCE,  xi.slot.RANGED),
    weapon(22142, 'Armageddon',   'EMPYREAN', xi.weaponskill.WILDFIRE,           xi.slot.RANGED,
        { magic = true }),

    -- Mythic 119 III
    weapon(20510, 'Glanzfaust',    'MYTHIC', xi.weaponskill.ASCETICS_FURY,    xi.slot.MAIN),
    weapon(20511, 'Kenkonken',     'MYTHIC', xi.weaponskill.STRINGING_PUMMEL, xi.slot.MAIN),
    weapon(20585, 'Vajra',         'MYTHIC', xi.weaponskill.MANDALIC_STAB,    xi.slot.MAIN),
    weapon(20586, 'Carnwenhan',    'MYTHIC', xi.weaponskill.MORDANT_RIME,     xi.slot.MAIN),
    weapon(20584, 'Terpsichore',   'MYTHIC', xi.weaponskill.PYRRHIC_KLEOS,    xi.slot.MAIN),
    weapon(20686, 'Murgleis',      'MYTHIC', xi.weaponskill.DEATH_BLOSSOM,    xi.slot.MAIN),
    weapon(20687, 'Burtgang',      'MYTHIC', xi.weaponskill.ATONEMENT,         xi.slot.MAIN,
        { enabled = false, reason = 'enmity-based damage is capped after WS damage modifiers' }),
    weapon(20688, 'Tizona',        'MYTHIC', xi.weaponskill.EXPIACION,         xi.slot.MAIN),
    weapon(21757, 'Conqueror',     'MYTHIC', xi.weaponskill.KINGS_JUSTICE,     xi.slot.MAIN),
    weapon(21751, 'Aymur',         'MYTHIC', xi.weaponskill.PRIMAL_REND,       xi.slot.MAIN,
        { magic = true }),
    weapon(21809, 'Liberator',     'MYTHIC', xi.weaponskill.INSURGENCY,        xi.slot.MAIN),
    weapon(21858, 'Ryunohige',     'MYTHIC', xi.weaponskill.DRAKESBANE,        xi.slot.MAIN),
    weapon(21907, 'Nagi',          'MYTHIC', xi.weaponskill.BLADE_KAMU,        xi.slot.MAIN),
    weapon(21955, 'Kogarasumaru',  'MYTHIC', xi.weaponskill.TACHI_RANA,        xi.slot.MAIN),
    weapon(21078, 'Yagrush',       'MYTHIC', xi.weaponskill.MYSTIC_BOON,       xi.slot.MAIN),
    weapon(22062, 'Laevateinn',    'MYTHIC', xi.weaponskill.VIDOHUNIR,         xi.slot.MAIN,
        { magic = true }),
    weapon(22063, 'Nirvana',       'MYTHIC', xi.weaponskill.GARLAND_OF_BLISS,  xi.slot.MAIN,
        { magic = true }),
    weapon(22061, 'Tupsimati',     'MYTHIC', xi.weaponskill.OMNISCIENCE,       xi.slot.MAIN,
        { magic = true }),
    weapon(22139, 'Gastraphetes',  'MYTHIC', xi.weaponskill.TRUEFLIGHT,        xi.slot.RANGED,
        { magic = true }),
    weapon(22141, 'Death Penalty', 'MYTHIC', xi.weaponskill.LEADEN_SALUTE,     xi.slot.RANGED,
        { magic = true }),

    -- Aeonic final
    weapon(20515, 'Godhands',           'AEONIC', xi.weaponskill.SHIJIN_SPIRAL, xi.slot.MAIN),
    weapon(20594, 'Aeneas',             'AEONIC', xi.weaponskill.EXENTERATOR,   xi.slot.MAIN),
    weapon(20695, 'Sequence',           'AEONIC', xi.weaponskill.REQUIESCAT,    xi.slot.MAIN),
    weapon(21694, 'Lionheart',          'AEONIC', xi.weaponskill.DIMIDIATION,   xi.slot.MAIN),
    weapon(21753, 'Tri-edge',           'AEONIC', xi.weaponskill.RUINATOR,      xi.slot.MAIN),
    weapon(20843, 'Chango',             'AEONIC', xi.weaponskill.UPHEAVAL,      xi.slot.MAIN),
    weapon(20890, 'Anguta',             'AEONIC', xi.weaponskill.ENTROPY,       xi.slot.MAIN),
    weapon(20935, 'Trishula',           'AEONIC', xi.weaponskill.STARDIVER,     xi.slot.MAIN),
    weapon(20977, 'Heishi Shorinken',   'AEONIC', xi.weaponskill.BLADE_SHUN,    xi.slot.MAIN),
    weapon(21025, 'Dojikiri Yasutsuna', 'AEONIC', xi.weaponskill.TACHI_SHOHA,   xi.slot.MAIN),
    weapon(21082, 'Tishtrya',           'AEONIC', xi.weaponskill.BLACK_HALO,     xi.slot.MAIN),
    weapon(21147, 'Khatvanga',          'AEONIC', xi.weaponskill.SHATTERSOUL,    xi.slot.MAIN),
    weapon(22117, 'Fail-not',           'AEONIC', xi.weaponskill.APEX_ARROW,    xi.slot.RANGED),
    weapon(21485, 'Fomalhaut',          'AEONIC', xi.weaponskill.LAST_STAND,    xi.slot.RANGED),
}

catalog.BY_ITEM_ID = {}
for _, entry in ipairs(catalog.WEAPONS) do
    assert(not catalog.BY_ITEM_ID[entry.itemId], string.format('Duplicate REMA item ID: %d', entry.itemId))
    catalog.BY_ITEM_ID[entry.itemId] = entry
end

catalog.getTuning = function(wsId)
    return catalog.REMA_WS_TUNING[wsId]
end

catalog.getFamilyTuning = function(family)
    return catalog.REMA_FAMILY_TUNING[family]
end

catalog.getEntry = function(itemId, wsId, slot)
    local entry = catalog.BY_ITEM_ID[itemId]
    if
        not entry or
        not entry.enabled or
        entry.wsId ~= wsId or
        entry.slot ~= slot
    then
        return nil
    end

    return entry
end

catalog.getBonusPercent = function(itemId, wsId, slot)
    local entry = catalog.getEntry(itemId, wsId, slot)
    if not entry then
        return 0
    end

    local tierScale = catalog.REMA_TIER_SCALE[entry.family]

    return math.floor(catalog.PRIME_EQUIVALENT_BONUS * tierScale * 100 + 0.5)
end

return catalog
