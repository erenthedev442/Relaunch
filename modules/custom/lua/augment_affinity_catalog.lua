-----------------------------------
-- augment_affinity_catalog.lua
-- Track 2 of the augment side-quest: per-category NM affinities.
--
-- Defeating a signature NM (proved by handing over its trophy at the
-- Augment Sage) permanently unlocks a bit in the Augment_Affinities
-- charvar. When the player augments an item whose `cat` matches an
-- affinity they hold, the Augment Moogle multiplies that augment's value
-- by `catalog.affinityMult` (1.5x by default).
--
-- Bitfield layout:
--   bit 0  = Strength / Attack          (cat 1)
--   bit 1  = Dexterity / Accuracy       (cat 2)
--   bit 2  = Vitality / Defense         (cat 3)
--   bit 3  = Agility / Evasion / Haste  (cat 4)
--   bit 4  = Intelligence / Magic       (cat 5)
--   bit 5  = Mind / Healing / Cure      (cat 6)
--   bit 6  = Charisma / Charm / Enmity  (cat 7)
--   bit 7  = HP / Regen                 (cat 8)
--   bit 8  = MP / Refresh               (cat 9)
--   bit 9  = Pet                        (cat 10)
--   bit 10 = Elemental resistance       (cat 11)
--   bit 11 = Skill+                     (cat 12)
--   bit 12 = Weaponskill DMG+           (cat 13)
--
-- Each `bit = N` here MUST match `cat = N+1` in augment_catalog.lua.
-- (Catalog uses 1-indexed cat, bitfield uses 0-indexed bit.)
--
-- ALL trophy IDs verified against sql/item_basic.sql. Each trophy is a
-- mob-drop item from the corresponding NM (or its closest LSB equivalent
-- on this server's database).
-----------------------------------
local catalog = {}

-----------------------------------
-- Affinity multiplier - applied multiplicatively on top of mastery mult.
-- 1.5 was chosen so that with rank-5 mastery (2.0x), a player who has
-- unlocked the relevant affinity is at 3.0x base, before crit. Crit then
-- doubles that to 6.0x - significant but not server-breaking.
-----------------------------------
catalog.affinityMult = 1.5

-----------------------------------
-- AFFINITY ROWS
--   cat    : category index (matches augment_catalog `cat` field)
--   bit    : bit position in Augment_Affinities charvar (cat - 1)
--   nm     : NM name shown to the player
--   trophy : { id, qty, name } - turn-in item that proves the NM kill
--   label  : friendly category name
-----------------------------------
catalog.affinities =
{
    {
        cat    = 1, bit = 0,
        label  = 'Strength / Attack',
        nm     = 'Behemoth',
        trophy = { id = 893,   qty = 1, name = 'Giant Femur'        },
    },
    {
        cat    = 2, bit = 1,
        label  = 'Dexterity / Accuracy',
        nm     = 'King Arthro',
        trophy = { id = 8983,  qty = 1, name = "Emperor Arthro's Shell" },
    },
    {
        cat    = 3, bit = 2,
        label  = 'Vitality / Defense',
        nm     = 'Adamantoise',
        trophy = { id = 908,   qty = 1, name = 'Adamantoise Shell'  },
    },
    {
        cat    = 4, bit = 3,
        label  = 'Agility / Evasion / Haste',
        nm     = 'Roc',
        trophy = { id = 843,   qty = 1, name = 'Giant Bird Plume'   },
    },
    {
        cat    = 5, bit = 4,
        label  = 'Intelligence / Magic offense',
        nm     = 'Ouryu (Guivre-tier wyrm)',
        trophy = { id = 909,   qty = 1, name = "Guivre's Skull"     },
    },
    {
        cat    = 6, bit = 5,
        label  = 'Mind / Healing / Cure',
        nm     = 'Phoenix',
        trophy = { id = 844,   qty = 1, name = 'Phoenix Feather'    },
    },
    {
        cat    = 7, bit = 6,
        label  = 'Charisma / Charm / Enmity',
        nm     = 'Lady Lilith (Khimaira-tier charmer)',
        trophy = { id = 2372,  qty = 1, name = 'Khimaira Mane'      },
    },
    {
        cat    = 8, bit = 7,
        label  = 'HP / Regen',
        nm     = 'Fafnir',
        trophy = { id = 1122,  qty = 1, name = 'Wyvern Skin'        },
    },
    {
        cat    = 9, bit = 8,
        label  = 'MP / Refresh',
        nm     = 'Vrtra',
        trophy = { id = 1133,  qty = 1, name = 'Vial of Dragon Blood' },
    },
    {
        cat    = 10, bit = 9,
        label  = 'Pet',
        nm     = 'King Vinegarroon',
        trophy = { id = 1015,  qty = 1, name = 'Sand Bat Fang'      },
    },
    {
        cat    = 11, bit = 10,
        label  = 'Elemental resistance',
        nm     = 'Khimaira',
        trophy = { id = 2371,  qty = 1, name = 'Khimaira Horn'      },
    },
    {
        cat    = 12, bit = 11,
        label  = 'Skill+',
        nm     = 'Maat (proxy: a king-tier predator)',
        trophy = { id = 2893,  qty = 1, name = 'Gargantuan Black Tiger Fang' },
    },
    {
        cat    = 13, bit = 12,
        label  = 'Weaponskill DMG+',
        nm     = 'Tiamat',
        trophy = { id = 1473,  qty = 1, name = 'High-Quality Scorpion Shell' },
    },
}

-----------------------------------
-- Helpers
-----------------------------------

-- Find the affinity row for a given category index (1..13).
function catalog.byCat(cat)
    for _, row in ipairs(catalog.affinities) do
        if row.cat == cat then return row end
    end
    return nil
end

-- Does the player hold the affinity bit for this category?
-- LSB lua uses LuaJIT - `bit.band` is available globally.
function catalog.hasAffinity(player, cat)
    local row = catalog.byCat(cat)
    if not row then return false end
    local field = player:getCharVar('Augment_Affinities') or 0
    return bit.band(field, bit.lshift(1, row.bit)) ~= 0
end

-- Set the affinity bit for this category. Idempotent.
function catalog.grantAffinity(player, cat)
    local row = catalog.byCat(cat)
    if not row then return end
    local field = player:getCharVar('Augment_Affinities') or 0
    player:setCharVar('Augment_Affinities', bit.bor(field, bit.lshift(1, row.bit)))
end

return catalog
