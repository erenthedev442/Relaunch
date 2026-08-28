-----------------------------------
-- accessory_catalog.lua
-- Endgame accessories for the Accessory NPC.
-- Covers Neck / Waist / Earring / Ring / Back.
--
-- Tiers (medal currencies, same trio as Armor / Weapons NPCs):
--   Bronze   = Beastmens Medal   (entry)
--   Silver   = Kindreds Medal    (mid)
--   Gold     = Demons Medal      (pre-Infamy mid-tier)
--
-- HOW THIS FILE IS MAINTAINED:
--   * Placement config (zoneId/zonePath/vendorPos/seals/goldExtraDrop) are
--     pinned constants near the top of tools/score_accessories.py; edit there
--     if you want the NPC somewhere else.
--   * Tier contents (the table.insert blocks below) are HAND-CURATED. They were
--     originally seeded from the live item DB, but this file is now the source
--     of truth and is edited in place -- auto-write is DISABLED (2026-07-10).
--   * tools/score_accessories.py is RECOMMENDATION-ONLY: it PRINTS scores and
--     will NOT overwrite this file. Same for tools/rebalance_all.bat.
--
-- 2026-07-19 (owner): Trimmed to CRAFTED + DELVE items only. The prior ~188
--   entries (Walk of Echoes / Voidwatch / Wildskeeper Reive / Meeble Burrows /
--   HTBF / etc.) were removed. NOTE: for 181 of those this vendor was the sole
--   TARGETED source on relaunch -- after removal they drop only from the random
--   Invasion catch-all pool. A follow-up task tracks giving them a real source.
-- 2026-08-28: Restocked starter rings/ears. Bronze gets the Assault stat
--   rings. Silver gets Adoulin-craft +1s (no coalition rings). Gold gets
--   homeless mid-tier ears/rings. Chirich/Stikini are NQ only. Null, Infamy,
--   Unity, HTBF, Geas Fete, and coalition rings stay off this vendor.
-----------------------------------
local catalog = {}

-----------------------------------
-- ZONE / NPC PLACEMENT
--   Single source of truth for:
--     - Accessory_NPC.lua : override registration + NPC position
--     - docgen            : gear-vendors.md location table + zone prose
--   Lines up with the Armor / Weapons NPCs and the Hunting League hub
--   on the Escha - Zi'Tah vendor row (z = -30), so all gear vendors are
--   in one place and players don't zone-hop.
-----------------------------------
catalog.zoneId    = xi.zone.ESCHA_ZITAH
catalog.zonePath  = 'xi.zones.Escha_ZiTah'
catalog.vendorPos = { x = -9.0000, y = -0.5000, z = -30.0000, rot = 128 }

-----------------------------------
-- SEAL CURRENCY DEFINITIONS (shared with Armor / Weapons NPCs)
-----------------------------------
catalog.seals =
{
    bronze = { id = 9539, name = 'Beastmens Medal' },
    silver = { id = 9541, name = 'Kindreds Medal'  },
    gold   = { id = 9543, name = 'Demons Medal'    },
}

-- Gold-tier extra requirement: disabled. Mirrors the Armor NPC's
-- pattern — set this to { id = X, qty = N, name = '...' } if you
-- want Gold accessories to require an additional drop on top of
-- the seal cost. With nil, Gold accessories cost only the medal.
catalog.goldExtraDrop = nil

-----------------------------------
-- Helper: empty slot tables for a tier
-----------------------------------
local function emptySlots()
    return { neck = {}, waist = {}, ear = {}, ring = {}, back = {}, ammo = {} }
end

-----------------------------------
-- BRONZE TIER  (15 medals/piece) -- Delve accessories + Assault starter rings
-----------------------------------
catalog.bronze = emptySlots()
local b = catalog.bronze

-- neck
table.insert(b.neck, { id = 28402, name = 'Asperity Necklace'         , cost = 15, jobs = 'All' })  -- Delve
table.insert(b.neck, { id = 28401, name = 'Eddy Necklace'             , cost = 15, jobs = 'WHM/BLM/RDM/PLD/DRK/SMN/BLU/SCH/GEO/RUN' })  -- Delve
table.insert(b.neck, { id = 28381, name = 'Imbodla Necklace'          , cost = 15, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/SCH/GEO' })  -- Delve
table.insert(b.neck, { id = 28403, name = 'Inquisitor Bead Necklace'  , cost = 15, jobs = 'MNK/RDM/THF/BST/RNG/NIN/DRG/COR/PUP/DNC/RUN' })  -- Delve
table.insert(b.neck, { id = 28380, name = 'Iqabi Necklace'            , cost = 15, jobs = 'All' })  -- Delve

-- ring
table.insert(b.ring, { id = 15543, name = 'Rajas Ring'               , cost = 15, jobs = 'All' })  -- Assault DD
table.insert(b.ring, { id = 15545, name = 'Tamas Ring'               , cost = 15, jobs = 'All' })  -- Assault mage
table.insert(b.ring, { id = 15544, name = 'Sattva Ring'              , cost = 15, jobs = 'All' })  -- Assault tank
table.insert(b.ring, { id = 15808, name = "Ulthalam's Ring"          , cost = 15, jobs = 'All' })  -- Assault acc/att
table.insert(b.ring, { id = 15807, name = "Balrahn's Ring"           , cost = 15, jobs = 'All' })  -- Assault macc

-- waist
table.insert(b.waist, { id = 10829, name = 'Artful Belt'              , cost = 15, jobs = 'All' })  -- Craft (synergy)
table.insert(b.waist, { id = 28450, name = 'Chaac Belt'               , cost = 15, jobs = 'All' })  -- Delve
table.insert(b.waist, { id = 28452, name = 'Fucho-No-Obi'             , cost = 15, jobs = 'MNK/WHM/BLM/RDM/PLD/BRD/RNG/SMN/BLU/PUP/SCH/GEO/RUN' })  -- Delve
table.insert(b.waist, { id = 28453, name = 'Gevaudan Belt'            , cost = 15, jobs = 'WAR/PLD/DRK/BST/DRG' })  -- Delve
table.insert(b.waist, { id = 28462, name = 'Hurchlan Sash'            , cost = 15, jobs = 'MNK/THF/BST/RNG/NIN/BLU/COR/PUP/DNC/RUN' })  -- Delve
table.insert(b.waist, { id = 28451, name = 'Isa Belt'                 , cost = 15, jobs = 'All' })  -- Delve
table.insert(b.waist, { id = 28463, name = 'Zorans Belt'              , cost = 15, jobs = 'WAR/PLD/DRK/BST/DRG' })  -- Delve

-- back
table.insert(b.back, { id = 28603, name = 'Kumbira Cape'             , cost = 15, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO' })  -- Delve
table.insert(b.back, { id = 28604, name = 'Mubvumbamiri Mantle'      , cost = 15, jobs = 'WAR/MNK/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- Delve
table.insert(b.back, { id = 28643, name = 'Refraction Cape'          , cost = 15, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO' })  -- Delve


-----------------------------------
-- SILVER TIER  (32 medals/piece) -- Crafted HQ starter row
-----------------------------------
catalog.silver = emptySlots()
local s = catalog.silver

-- ear
table.insert(s.ear, { id = 11057, name = 'Ghillie Earring +1'       , cost = 32, jobs = 'All' })  -- Craft acc ear
table.insert(s.ear, { id = 11061, name = 'Evader Earring +1'        , cost = 32, jobs = 'All' })  -- Craft eva ear

-- ring
table.insert(s.ring, { id = 11059, name = 'Hajduk Ring +1'           , cost = 32, jobs = 'All' })  -- Craft ranged acc

-- waist
table.insert(s.waist, { id = 10830, name = 'Artful Belt +1'          , cost = 32, jobs = 'All' })  -- Craft (HQ synergy)
table.insert(s.waist, { id = 10837, name = 'Phos Belt +1'            , cost = 32, jobs = 'WAR/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- Craft haste

-- back
table.insert(s.back, { id = 11001, name = 'Swith Cape +1'            , cost = 32, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO' })  -- Craft FC
table.insert(s.back, { id = 10997, name = 'Testudo Mantle +1'        , cost = 32, jobs = 'WAR/MNK/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- Craft tank
table.insert(s.back, { id = 10999, name = 'Dauntless Mantle'         , cost = 32, jobs = 'WAR/MNK/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- Craft DD cape


-----------------------------------
-- GOLD TIER  (60 medals/piece) -- pre-Infamy mid-tier
-----------------------------------
catalog.gold = emptySlots()
local g = catalog.gold

-- neck
table.insert(g.neck, { id = 26016, name = 'Incanters Torque'         , cost = 60, jobs = 'All' })  -- Craft (synergy)

-- ear
table.insert(g.ear, { id = 28506, name = 'Andoaa Earring'           , cost = 60, jobs = 'All' })  -- Delve
table.insert(g.ear, { id = 26081, name = 'Mache Earring +1'         , cost = 60, jobs = 'All' })  -- Craft DA ear
table.insert(g.ear, { id = 28526, name = 'Tati Earring'             , cost = 60, jobs = 'All' })  -- Melee att ear
table.insert(g.ear, { id = 28475, name = 'Infused Earring'          , cost = 60, jobs = 'All' })  -- Eva/regen ear
table.insert(g.ear, { id = 11053, name = 'Choleric Earring'         , cost = 60, jobs = 'All' })  -- Magic crit ear
table.insert(g.ear, { id = 10297, name = 'Sortiarius Earring'       , cost = 60, jobs = 'All' })  -- MAtt ear

-- ring
table.insert(g.ring, { id = 26189, name = 'Moonbeam Ring'           , cost = 60, jobs = 'WAR/THF/PLD/DRK/BST/BRD/DRG/DNC/RUN' })  -- Craft
table.insert(g.ring, { id = 10767, name = 'Pernicious Ring'         , cost = 60, jobs = 'All' })  -- DA/STP melee
table.insert(g.ring, { id = 26181, name = 'Chirich Ring'            , cost = 60, jobs = 'All' })  -- NQ only; +1 stays off
table.insert(g.ring, { id = 26183, name = 'Stikini Ring'            , cost = 60, jobs = 'All' })  -- NQ only; +1 stays off
table.insert(g.ring, { id = 10798, name = 'Eihwaz Ring'             , cost = 60, jobs = 'All' })  -- Tank HP
table.insert(g.ring, { id = 26180, name = 'Varar Ring +1'           , cost = 60, jobs = 'All' })  -- Pet acc

-- waist
table.insert(g.waist, { id = 26340, name = 'Moonbow Belt'            , cost = 60, jobs = 'MNK/PUP' })  -- Craft
table.insert(g.waist, { id = 26356, name = 'Skrymir Cord'            , cost = 60, jobs = 'All' })  -- Craft
table.insert(g.waist, { id = 26360, name = 'Gerdr Belt'              , cost = 60, jobs = 'WAR/MNK/RDM/THF/PLD/DRK/BST/BRD/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- Craft

-- back
table.insert(g.back, { id = 26268, name = 'Moonbeam Cape'           , cost = 60, jobs = 'All' })  -- Craft
table.insert(g.back, { id = 28641, name = 'Vespid Mantle'           , cost = 60, jobs = 'WAR/MNK/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- Delve


-----------------------------------
-- INFAMY TIER  (top-5-per-slot BiS + Sortie JSE +2 earrings)
--   Not sold by the Accessory NPC. Promoted to the Dungeon Infamy
--   Vendor by tools/build_infamy_top_picks.py.
-----------------------------------
catalog.infamy = emptySlots()
local inf = catalog.infamy

-- neck (top 5 by score -> Infamy Vendor)
-- Do NOT add 26035 Moonlight Nodowa here: HQ1 craft (Smith 110 + Cloth 110).

-- waist (top 5 by score -> Infamy Vendor)

-- ear (top 5 by score -> Infamy Vendor)

-- ring (top 5 by score -> Infamy Vendor)
table.insert(inf.ring, { id =  10783, name = 'Veneficium Ring'                   , cost = 300, jobs = 'All' })  -- DPS score 96 [RARE]
table.insert(inf.ring, { id =  28537, name = 'Lunette Ring +1'                   , cost = 300, jobs = 'All' })  -- DPS score 96 [RARE]

-- back (top 5 by score -> Infamy Vendor)
table.insert(inf.back, { id =  28628, name = 'Takaha Mantle'                     , cost = 300, jobs = 'SAM' })  -- DPS score 112 [EX]

-- ear (Sortie +2, one per job)


return catalog
