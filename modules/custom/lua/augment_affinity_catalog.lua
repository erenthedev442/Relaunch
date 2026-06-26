-----------------------------------
-- augment_affinity_catalog.lua
-- 24 NM affinities. Each is unlocked by killing the listed NM (no item drop
-- required). When the player augments an item whose cat matches an affinity
-- they hold, the Augment Moogle multiplies that augment's value by
-- catalog.affinityMult (1.5x by default).
--
-- Bitfield layout (Augment_Affinities charvar):
--   bit 0  = STR        cat 1   Behemoth         Batallia Downs
--   bit 1  = Attack     cat 2   King Behemoth    Behemoth's Dominion
--   bit 2  = DEX        cat 3   King Arthro      Kuftal Tunnel
--   bit 3  = Accuracy   cat 4   Simurgh          Rolanberry Fields
--   bit 4  = VIT        cat 5   Adamantoise      Valley of Sorrows
--   bit 5  = Defense    cat 6   Genbu            Hall of the Gods
--   bit 6  = AGI        cat 7   Roc              Sauromugue Champaign
--   bit 7  = Evasion    cat 8   Seiryu           Hall of the Gods
--   bit 8  = Haste      cat 9   Byakko           Shrine of Ru'Avitau
--   bit 9  = INT        cat 10  Aspidochelone    Cape Teriggan
--   bit 10 = Magic ATK  cat 11  Ouryu            Riverne Site B01
--   bit 11 = MND        cat 12  Bune             The Boyahda Tree
--   bit 12 = Healing    cat 13  Phoenix          Riverne Site A01
--   bit 13 = CHR        cat 14  Suzaku           Hall of the Gods
--   bit 14 = Enmity     cat 15  Kirin            Hall of the Gods
--   bit 15 = HP         cat 16  Fafnir           Dragon's Aery
--   bit 16 = Regen      cat 17  Nidhogg          Dragon's Aery
--   bit 17 = MP         cat 18  Vrtra            Ifrit's Cauldron
--   bit 18 = Refresh    cat 19  Tiamat           Uleguerand Range
--   bit 19 = Pet        cat 20  King Vinegarroon Western Altepa Desert
--   bit 20 = Ele Resist cat 21  Khimaira         King Ranperre's Tomb
--   bit 21 = Status     cat 22  Cerberus         King Ranperre's Tomb
--   bit 22 = Skills     cat 23  Absolute Virtue  Ru'Aun Gardens
--   bit 23 = WSD+       cat 24  Proto-Omega      Temenos
--
-- Each bit = cat - 1.  augment_catalog.lua uses cat 1..24 as the key.
-- grant_affinity fires from augment_affinity_grants.lua onMobDeath hooks.
-----------------------------------
local catalog = {}

catalog.affinityMult = 1.5

-----------------------------------
-- AFFINITY ROWS
--   cat    : category index (matches augment_catalog cat field, 1..24)
--   bit    : bit position in Augment_Affinities charvar (cat - 1)
--   label  : display name in the Augment Sage menu
--   nm     : NM name (must match mob:getName() exactly in the zone script)
--   nmZone : human-readable zone name for the Sage menu info screen
-----------------------------------
catalog.affinities =
{
    { cat=1,  bit=0,  label='STR',        nm='Behemoth',          nmZone='Batallia Downs'          },
    { cat=2,  bit=1,  label='Attack',     nm='King_Behemoth',     nmZone="Behemoth's Dominion"     },
    { cat=3,  bit=2,  label='DEX',        nm='King_Arthro',       nmZone='Kuftal Tunnel'           },
    { cat=4,  bit=3,  label='Accuracy',   nm='Simurgh',           nmZone='Rolanberry Fields'       },
    { cat=5,  bit=4,  label='VIT',        nm='Adamantoise',       nmZone='Valley of Sorrows'       },
    { cat=6,  bit=5,  label='Defense',    nm='Genbu',             nmZone='Hall of the Gods'        },
    { cat=7,  bit=6,  label='AGI',        nm='Roc',               nmZone='Sauromugue Champaign'    },
    { cat=8,  bit=7,  label='Evasion',    nm='Seiryu',            nmZone='Hall of the Gods'        },
    { cat=9,  bit=8,  label='Haste',      nm='Byakko',            nmZone="Shrine of Ru'Avitau"     },
    { cat=10, bit=9,  label='INT',        nm='Aspidochelone',     nmZone='Cape Teriggan'           },
    { cat=11, bit=10, label='Magic ATK',  nm='Ouryu',             nmZone='Riverne Site B01'        },
    { cat=12, bit=11, label='MND',        nm='Bune',              nmZone='The Boyahda Tree'        },
    { cat=13, bit=12, label='Healing',    nm='Phoenix',           nmZone='Riverne Site A01'        },
    { cat=14, bit=13, label='CHR',        nm='Suzaku',            nmZone='Hall of the Gods'        },
    { cat=15, bit=14, label='Enmity',     nm='Kirin',             nmZone='Hall of the Gods'        },
    { cat=16, bit=15, label='HP',         nm='Fafnir',            nmZone="Dragon's Aery"           },
    { cat=17, bit=16, label='Regen',      nm='Nidhogg',           nmZone="Dragon's Aery"           },
    { cat=18, bit=17, label='MP',         nm='Vrtra',             nmZone="Ifrit's Cauldron"        },
    { cat=19, bit=18, label='Refresh',    nm='Tiamat',            nmZone='Uleguerand Range'        },
    { cat=20, bit=19, label='Pet',        nm='King_Vinegarroon',  nmZone='Western Altepa Desert'   },
    { cat=21, bit=20, label='Ele Resist', nm='Khimaira',          nmZone="King Ranperre's Tomb"    },
    { cat=22, bit=21, label='Status',     nm='Cerberus',          nmZone="King Ranperre's Tomb"    },
    { cat=23, bit=22, label='Skills',     nm='Absolute_Virtue',   nmZone="Ru'Aun Gardens"          },
    { cat=24, bit=23, label='WSD+',       nm='Proto-Omega',       nmZone='Temenos'                 },
}

-----------------------------------
-- Helpers
-----------------------------------

function catalog.byCat(cat)
    for _, row in ipairs(catalog.affinities) do
        if row.cat == cat then return row end
    end
    return nil
end

function catalog.byNm(nmName)
    for _, row in ipairs(catalog.affinities) do
        if row.nm == nmName then return row end
    end
    return nil
end

function catalog.hasAffinity(player, cat)
    local row = catalog.byCat(cat)
    if not row then return false end
    local field = player:getCharVar('Augment_Affinities') or 0
    return bit.band(field, bit.lshift(1, row.bit)) ~= 0
end

function catalog.grantAffinity(player, cat)
    local row = catalog.byCat(cat)
    if not row then return end
    local field = player:getCharVar('Augment_Affinities') or 0
    player:setCharVar('Augment_Affinities', bit.bor(field, bit.lshift(1, row.bit)))
end

return catalog
