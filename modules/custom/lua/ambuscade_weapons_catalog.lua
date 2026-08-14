-----------------------------------
-- ambuscade_weapons_catalog.lua
--
-- Retail-faithful Ambuscade weapon upgrade chain, wired into the Ambuscade
-- reward flow (Gorpa-Masorpa, scripts/globals/ambuscade.lua).
--
-- Each of the 13 weapon types + the grip is a 5-stage chain:
--   Tokko (base) -> Ajja -> Eletta -> Kaja -> Final
-- Base is redeemed for Hallmarks; each upgrade consumes 5 of an Abdhaljs
-- material (already sold in Gorpa's HM shop):
--   Tokko  -> Ajja   : 5x Abdhaljs Nugget (9782)
--   Ajja   -> Eletta : 5x Abdhaljs Gem    (9783)
--   Eletta -> Kaja   : 5x Abdhaljs Anima  (9784)
--   Kaja   -> Final  : 5x Abdhaljs Matter (9785)
--
-- NOTE: Ajja + Kaja item IDs are ALSO used by the Prime Weapon Forge as its
-- 119I/119II stages (weapon_forge_catalog.lua). Tokko, Eletta, and each
-- Ambuscade final remain exclusive to the Ambuscade route.
-----------------------------------
local M = {}

-- Abdhaljs upgrade materials (sold in Gorpa's HM shop).
M.MAT = { NUGGET = 9782, GEM = 9783, ANIMA = 9784, MATTER = 9785 }
M.MAT_NAME = { [9782] = 'Abdhaljs Nugget', [9783] = 'Abdhaljs Gem',
               [9784] = 'Abdhaljs Anima', [9785] = 'Abdhaljs Matter' }

-- Hallmark cost to redeem a BASE (Tokko) weapon of your choice.
M.BASE_HM_COST = 2000

-- Stage display names (index into a chain's `stages`).
M.STAGE_NAME = { 'Tokko', 'Ajja', 'Eletta', 'Kaja', 'Final' }

-- Per-step upgrade recipe, keyed by the FROM-stage index (1..4).
--   mat   = Abdhaljs material itemId, qty = amount consumed.
--   extra = optional additional item consumed (id/qty/name).
-- Retail's final step is "5 Abdhaljs Matter + 1 non-Ambuscade Pulse Weapon".
-- Pulse Weapons are Vagary content that isn't obtainable on relaunch, so we honor
-- the extra-gate with a Pulse CELL (パルス管, real in-DB Vagary "Pulse" material)
-- instead, sold in Gorpa's Gallantry shop (see ambuscade.lua GAL_SHOP) so it's
-- obtainable within Ambuscade and Gallantry finally has an endgame sink.
M.PULSE_CELL = 3840  -- pulse_cell_mx (representative Pulse component)
M.UPGRADE =
{
    [1] = { mat = 9782, qty = 5 },  -- Tokko  -> Ajja   : 5 Nugget
    [2] = { mat = 9783, qty = 5 },  -- Ajja   -> Eletta : 5 Gem
    [3] = { mat = 9784, qty = 5 },  -- Eletta -> Kaja   : 5 Anima
    [4] = { mat = 9785, qty = 5,    -- Kaja   -> Final  : 5 Matter + 1 Pulse Cell
            extra = { id = 3840, qty = 1, name = 'Pulse Cell' } },
}

-- 14 chains (13 weapons + grip). stages = { Tokko, Ajja, Eletta, Kaja, Final }.
-- `label` is the menu text (final weapon name in parens). Verified against
-- item_basic.sql 2026-07-09; bow's Final (Ullr 22107) is NON-contiguous.
M.CHAINS =
{
    { label = 'H2H (Karambit)',       stages = { 21515, 21516, 21517, 21518, 21519 } },
    { label = 'Dagger (Tauret)',      stages = { 21561, 21562, 21563, 21564, 21565 } },
    { label = 'Sword (Naegling)',     stages = { 21617, 21618, 21619, 21620, 21621 } },
    { label = 'GSword (Nandaka)',     stages = { 21670, 21671, 21672, 21673, 21674 } },
    { label = 'Axe (Dolichenus)',     stages = { 21718, 21719, 21720, 21721, 21722 } },
    { label = 'GAxe (Lycurgos)',      stages = { 21775, 21776, 21777, 21778, 21779 } },
    { label = 'Scythe (Drepanum)',    stages = { 21826, 21827, 21828, 21829, 21830 } },
    { label = 'Polearm (Shining One)',stages = { 21879, 21880, 21881, 21882, 21883 } },
    { label = 'Katana (Gokotai)',     stages = { 21918, 21919, 21920, 21921, 21922 } },
    { label = 'GKatana (Hachimonji)', stages = { 21971, 21972, 21973, 21974, 21975 } },
    { label = 'Club (Maxentius)',     stages = { 22027, 22028, 22029, 22030, 22031 } },
    { label = 'Staff (Xoanon)',       stages = { 22082, 22083, 22084, 22085, 22086 } },
    { label = 'Bow (Ullr)',           stages = { 22108, 22109, 22110, 22111, 22107 } },
    { label = 'Grip (Khonsu)',        stages = { 22214, 22215, 22216, 22217, 22218 } },
}

-- Reverse index: itemId -> { chain = chainIdx, stage = stageIdx } for O(1) lookup
-- when scanning a player's inventory for upgradeable Ambuscade weapons.
M.BY_ITEM = {}
for ci, chain in ipairs(M.CHAINS) do
    for si, id in ipairs(chain.stages) do
        M.BY_ITEM[id] = { chain = ci, stage = si }
    end
end

-- Flat set of every Ambuscade weapon itemId (all 5 stages). For reference.
M.ALL_IDS = {}
for _, chain in ipairs(M.CHAINS) do
    for _, id in ipairs(chain.stages) do
        M.ALL_IDS[id] = true
    end
end

-- Set used by the "Ambuscade-exclusive" scrubs (gear vendor / Domain Invasion):
-- ALL FIVE stages. Prime forge feedstock is EARNED FROM AMBUSCADE (redeem a
-- base Tokko for Hallmarks, then walk the
-- Tokko->Ajja->Eletta->Kaja->Final upgrade chain -- scripts/globals/ambuscade.lua),
-- NOT bought at the medal vendor, so the ENTIRE Ambuscade weapon family is now
-- vendor-exclusive. The Prime route can transform Ajja directly into Kaja, but
-- it cannot bypass Ambuscade because the Ajja feedstock still starts here.
M.EXCLUSIVE_IDS = {}
for _, chain in ipairs(M.CHAINS) do
    for si = 1, 5 do
        M.EXCLUSIVE_IDS[chain.stages[si]] = true
    end
end

return M
