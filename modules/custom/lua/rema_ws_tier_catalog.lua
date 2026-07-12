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

-- Optional outlier tuning. Unlisted weaponskills use 1.00.
catalog.WS_TUNING =
{
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
    weapon(21752, 'Farsha',       'EMPYREAN', xi.weaponskill.CLOUDSPLITTER,    xi.slot.MAIN),
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
    weapon(22142, 'Armageddon',   'EMPYREAN', xi.weaponskill.WILDFIRE,           xi.slot.RANGED),

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
    weapon(21751, 'Aymur',         'MYTHIC', xi.weaponskill.PRIMAL_REND,       xi.slot.MAIN),
    weapon(21809, 'Liberator',     'MYTHIC', xi.weaponskill.INSURGENCY,        xi.slot.MAIN),
    weapon(21858, 'Ryunohige',     'MYTHIC', xi.weaponskill.DRAKESBANE,        xi.slot.MAIN),
    weapon(21907, 'Nagi',          'MYTHIC', xi.weaponskill.BLADE_KAMU,        xi.slot.MAIN),
    weapon(21955, 'Kogarasumaru',  'MYTHIC', xi.weaponskill.TACHI_RANA,        xi.slot.MAIN),
    weapon(21078, 'Yagrush',       'MYTHIC', xi.weaponskill.MYSTIC_BOON,       xi.slot.MAIN),
    weapon(22062, 'Laevateinn',    'MYTHIC', xi.weaponskill.VIDOHUNIR,         xi.slot.MAIN),
    weapon(22063, 'Nirvana',       'MYTHIC', xi.weaponskill.GARLAND_OF_BLISS,  xi.slot.MAIN),
    weapon(22061, 'Tupsimati',     'MYTHIC', xi.weaponskill.OMNISCIENCE,       xi.slot.MAIN),
    weapon(22139, 'Gastraphetes',  'MYTHIC', xi.weaponskill.TRUEFLIGHT,        xi.slot.RANGED),
    weapon(22141, 'Death Penalty', 'MYTHIC', xi.weaponskill.LEADEN_SALUTE,     xi.slot.RANGED),

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
    weapon(22117, 'Fail-not',           'AEONIC', xi.weaponskill.APEX_ARROW,    xi.slot.RANGED),
    weapon(21485, 'Fomalhaut',          'AEONIC', xi.weaponskill.LAST_STAND,    xi.slot.RANGED),
}

-- These likely retail mappings are intentionally non-qualifying because this
-- repository does not clearly wire either final weapon to the stated WS.
catalog.UNRESOLVED =
{
    { itemId = 21082, name = 'Tishtrya',  proposedWsId = xi.weaponskill.BLACK_HALO },
    { itemId = 21147, name = 'Khatvanga', proposedWsId = xi.weaponskill.SHATTERSOUL },
}

catalog.BY_ITEM_ID = {}
for _, entry in ipairs(catalog.WEAPONS) do
    assert(not catalog.BY_ITEM_ID[entry.itemId], string.format('Duplicate REMA item ID: %d', entry.itemId))
    catalog.BY_ITEM_ID[entry.itemId] = entry
end

catalog.getTuning = function(wsId)
    return catalog.WS_TUNING[wsId] or 1.00
end

catalog.getBonusPercent = function(itemId, wsId, slot)
    local entry = catalog.BY_ITEM_ID[itemId]
    if
        not entry or
        not entry.enabled or
        entry.wsId ~= wsId or
        entry.slot ~= slot
    then
        return 0
    end

    local tierScale = catalog.REMA_TIER_SCALE[entry.family]
    local tuning    = catalog.getTuning(wsId)

    return math.floor(catalog.PRIME_EQUIVALENT_BONUS * tierScale * tuning * 100 + 0.5)
end

return catalog
