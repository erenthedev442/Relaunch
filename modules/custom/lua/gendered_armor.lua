-----------------------------------
-- Gender-locked armor IDs.
--
-- Retail Maxixi (DNC AF) is two item IDs per slot: lower = male, higher =
-- female. Horos / Maculele are unisex. Catalogs only stored one side, so
-- reforges handed males to everyone and the Armor shop handed females to
-- everyone. Resolve at grant / upgrade / shop time from player:getGender()
-- (0 female, 1 male).
-----------------------------------
local M = {}

-- { male, female } for every Maxixi tier. Either ID keys the same pair.
local PAIRS =
{
    -- NQ (ilvl 109)
    { 27681, 27682 }, -- Tiara
    { 27825, 27826 }, -- Casaque
    { 27961, 27962 }, -- Bangles
    { 28108, 28109 }, -- Tights
    { 28241, 28242 }, -- Toe Shoes
    -- +1
    { 27702, 27703 },
    { 27846, 27847 },
    { 27982, 27983 },
    { 28129, 28130 },
    { 28262, 28263 },
    -- +2
    { 23058, 23059 },
    { 23125, 23126 },
    { 23192, 23193 },
    { 23259, 23260 },
    { 23326, 23327 },
    -- +3
    { 23393, 23394 },
    { 23460, 23461 },
    { 23527, 23528 },
    { 23594, 23595 },
    { 23661, 23662 },
    -- +4
    { 23913, 23914 },
    { 23958, 23959 },
    { 24003, 24004 },
    { 24048, 24049 },
    { 24093, 24094 },
}

local byId = {}
for _, pair in ipairs(PAIRS) do
    local rec = { male = pair[1], female = pair[2] }
    byId[pair[1]] = rec
    byId[pair[2]] = rec
end

function M.pair(itemId)
    return byId[itemId]
end

function M.resolve(player, itemId)
    local rec = byId[itemId]
    if not rec then
        return itemId
    end

    if player:getGender() == 1 then
        return rec.male
    end

    return rec.female
end

function M.has(player, itemId)
    local rec = byId[itemId]
    if not rec then
        return player:hasItem(itemId)
    end

    return player:hasItem(rec.male) or player:hasItem(rec.female)
end

-- Item ID actually in the bag (prefer the gender-correct copy).
function M.ownedId(player, itemId)
    local rec = byId[itemId]
    if not rec then
        return player:hasItem(itemId) and itemId or nil
    end

    local want = M.resolve(player, itemId)
    if player:hasItem(want) then
        return want
    end

    local other = (want == rec.male) and rec.female or rec.male
    if player:hasItem(other) then
        return other
    end

    return nil
end

return M
