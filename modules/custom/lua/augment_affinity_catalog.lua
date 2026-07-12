-----------------------------------
-- augment_affinity_catalog.lua
-- 11 NM affinities (one per augment category). Each NM drops a unique
-- trophy (trophyId); the player takes that trophy to the Augment Sage and
-- registers the affinity, which requires a Hunting League rank
-- (affinityRankReq) and costs Hunt Marks (affinityMarkCost). When the player
-- augments an item whose cat matches an affinity they hold, the Augment
-- Moogle rolls that augment TWICE and keeps the better result (see
-- Augment_Moogle.lua; affinityMult below is legacy).
--
-- Bitfield layout (Augment_Affinities charvar):
--   bit 0  = Base stats                    cat 1   Behemoth          Batallia Downs
--   bit 1  = Melee                         cat 2   King Behemoth     Behemoth's Dominion
--   bit 2  = Magic                         cat 3   Ouryu             Riverne Site B01
--   bit 3  = Defense                       cat 4   Genbu             Ru'Aun Gardens
--   bit 4  = Delays                        cat 5   Byakko            Ru'Aun Gardens
--   bit 5  = Duration                      cat 6   Aspidochelone     Cape Teriggan
--   bit 6  = Pets                          cat 7   King Vinegarroon  Western Altepa Desert
--   bit 7  = Potency                       cat 8   Phoenix           Riverne Site A01
--   bit 8  = Skills                        cat 9   Absolute Virtue   Ru'Aun Gardens
--   bit 9  = Exp/Cap Points                cat 10  Proto-Omega       Ru'Aun Gardens
--   bit 10 = Job specific niche utilities  cat 11  Kirin             Shrine of Ru'Avitau
--
-- Each bit = cat - 1.  augment_catalog.lua uses cat 1..11 as the key.
-- (Reworked 2026-07-06 from the old 24-stat-family scheme to the 11
--  functional categories. Old players' registered affinities are remapped
--  on next login by augment_affinity_migrate11.lua.)
-----------------------------------
local catalog = {}

-- LEGACY: the live Moogle path uses roll-twice-keep-better, not a multiplier.
-- Still read by scripts/commands/augment.lua (GM command) exdata math.
catalog.affinityMult = 1.5

-----------------------------------
-- REGISTRATION GATE (relaunch)
--   Affinities are registered at the Augment Sage with an NM-drop trophy.
--     rankReq  : minimum Hunting League rank (charvar HL_Tier)
--     markCost : Hunt Marks (charvar HL_Points) spent per registration
-----------------------------------
catalog.affinityRankReq  = 3
catalog.affinityMarkCost = 1000

-----------------------------------
-- AFFINITY ROWS
--   cat    : category index (matches augment_catalog cat field, 1..11)
--   bit    : bit position in Augment_Affinities charvar (cat - 1)
--   label  : display name in the Augment Sage menu
--   nm     : NM name (must match mob:getName() exactly in the zone script)
--   trophy : { id, qty, name } unique NM-drop that registers this affinity
--   nmZone : human-readable zone name for the Sage menu info screen
-- Field order (cat, bit, label, nm, trophy, nmZone) is what the docgen
-- affinity-table regex expects -- keep trophy immediately after nm.
-----------------------------------
catalog.affinities =
{
    { cat=1,  bit=0,  label='Base stats',                   nm='Behemoth',         trophy={ id=860,   qty=1, name='Behemoth Hide'          }, nmZone='Batallia Downs'        },
    { cat=2,  bit=1,  label='Melee',                        nm='King_Behemoth',    trophy={ id=883,   qty=1, name='Behemoth Horn'          }, nmZone="Behemoth's Dominion"   },
    { cat=3,  bit=2,  label='Magic',                        nm='Ouryu',            trophy={ id=903,   qty=1, name='Dragon Talon'           }, nmZone='Riverne Site B01'      },
    { cat=4,  bit=3,  label='Defense',                      nm='Genbu',            trophy={ id=1404,  qty=1, name='Seal of Genbu'          }, nmZone="Ru'Aun Gardens"        },
    { cat=5,  bit=4,  label='Delays',                       nm='Byakko',           trophy={ id=1406,  qty=1, name='Seal of Byakko'         }, nmZone="Ru'Aun Gardens"        },
    { cat=6,  bit=5,  label='Duration',                     nm='Aspidochelone',    trophy={ id=2421,  qty=1, name='Spirit Turtle Shell'    }, nmZone='Cape Teriggan'         },
    { cat=7,  bit=6,  label='Pets',                         nm='King_Vinegarroon', trophy={ id=1017,  qty=1, name='Scorpion Stinger'       }, nmZone='Western Altepa Desert' },
    { cat=8,  bit=7,  label='Potency',                      nm='Phoenix',          trophy={ id=844,   qty=1, name='Phoenix Feather'        }, nmZone='Riverne Site A01'      },
    { cat=9,  bit=8,  label='Skills',                       nm='Absolute_Virtue',  trophy={ id=1567,  qty=1, name='Attestation of Virtue'  }, nmZone="Ru'Aun Gardens"        },
    { cat=10, bit=9,  label='Exp/Cap Points',               nm='Proto-Omega',      trophy={ id=15800, qty=1, name='Omega Ring'             }, nmZone="Ru'Aun Gardens"        },
    { cat=11, bit=10, label='Job specific niche utilities', nm='Kirin',            trophy={ id=10038, qty=1, name="Kirin's Mane"           }, nmZone="Shrine of Ru'Avitau"   },
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
